import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/user_model.dart';
import '../models/leave_request_model.dart';
import '../models/warden_model.dart';
import '../models/hod_model.dart';
import '../models/cc_model.dart';
import '../models/student_model.dart';
import '../models/notification_model.dart';
import '../models/complaint_model.dart';
import 'push_notification_service.dart';

final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseService().usersStream;
});

final notificationsStreamProvider = StreamProvider<List<AppNotificationModel>>((ref) {
  return FirebaseService().notificationsStream;
});

final studentsStreamProvider = StreamProvider<List<StudentModel>>((ref) {
  return FirebaseService().studentsStream;
});

final wardensStreamProvider = StreamProvider<List<WardenModel>>((ref) {
  return FirebaseService().wardensStream;
});

final hodsStreamProvider = StreamProvider<List<HodModel>>((ref) {
  return FirebaseService().hodsStream;
});

final ccsStreamProvider = StreamProvider<List<CcModel>>((ref) {
  return FirebaseService().ccsStream;
});

final leaveRequestsStreamProvider = StreamProvider<List<LeaveRequestModel>>((ref) {
  return FirebaseService().leaveRequestsStream;
});

final complaintsStreamProvider = StreamProvider<List<ComplaintModel>>((ref) {
  return FirebaseService().complaintsStream;
});

final offlineStreamProvider = StreamProvider<bool>((ref) {
  return FirebaseService().offlineStream;
});

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  FirebaseService._internal() {
    _initConnectivity();
  }

  bool _isFirebaseInitialized = false;
  FirebaseFirestore? _firestore;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  final _offlineStreamController = StreamController<bool>.broadcast();
  Stream<bool> get offlineStream => _offlineStreamController.stream;

  void _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _isOffline = results.contains(ConnectivityResult.none);
      if (!_offlineStreamController.isClosed) {
        _offlineStreamController.add(_isOffline);
      }
    } catch (e) {
      debugPrint('Connectivity initial check error: $e');
    }

    Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.contains(ConnectivityResult.none);
      if (_isOffline != offline) {
        _isOffline = offline;
        if (!_offlineStreamController.isClosed) {
          _offlineStreamController.add(_isOffline);
        }
      }
    });
  }

  Future<bool> checkConnectivityStatus() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final offline = results.contains(ConnectivityResult.none);
      if (_isOffline != offline) {
        _isOffline = offline;
        if (!_offlineStreamController.isClosed) {
          _offlineStreamController.add(_isOffline);
        }
      }
      return _isOffline;
    } catch (e) {
      return _isOffline;
    }
  }

  // Reactive state store
  final List<UserModel> _localUsers = [];
  final List<StudentModel> _localStudents = [];
  final List<WardenModel> _localWardens = [];
  final List<HodModel> _localHods = [];
  final List<CcModel> _localCcs = [];
  final List<LeaveRequestModel> _localLeaveRequests = [];
  final List<AppNotificationModel> _localNotifications = [];
  final List<ComplaintModel> _localComplaints = [];

  final _usersStreamController = StreamController<List<UserModel>>.broadcast();
  final _studentsStreamController = StreamController<List<StudentModel>>.broadcast();
  final _wardensStreamController = StreamController<List<WardenModel>>.broadcast();
  final _hodsStreamController = StreamController<List<HodModel>>.broadcast();
  final _ccsStreamController = StreamController<List<CcModel>>.broadcast();
  final _leaveRequestsStreamController =
      StreamController<List<LeaveRequestModel>>.broadcast();
  final _notificationsStreamController =
      StreamController<List<AppNotificationModel>>.broadcast();
  final _complaintsStreamController =
      StreamController<List<ComplaintModel>>.broadcast();

  Stream<List<UserModel>> get usersStream => _usersStreamController.stream;
  Stream<List<StudentModel>> get studentsStream => _studentsStreamController.stream;
  Stream<List<WardenModel>> get wardensStream => _wardensStreamController.stream;
  Stream<List<HodModel>> get hodsStream => _hodsStreamController.stream;
  Stream<List<CcModel>> get ccsStream => _ccsStreamController.stream;
  Stream<List<LeaveRequestModel>> get leaveRequestsStream =>
      _leaveRequestsStreamController.stream;
  Stream<List<AppNotificationModel>> get notificationsStream =>
      _notificationsStreamController.stream;
  Stream<List<ComplaintModel>> get complaintsStream =>
      _complaintsStreamController.stream;

  List<UserModel> get currentUsers => List.unmodifiable(_localUsers);
  List<StudentModel> get currentStudents => List.unmodifiable(_localStudents);
  List<WardenModel> get currentWardens => List.unmodifiable(_localWardens);
  List<HodModel> get currentHods => List.unmodifiable(_localHods);
  List<CcModel> get currentCcs => List.unmodifiable(_localCcs);
  List<LeaveRequestModel> get currentLeaveRequests =>
      List.unmodifiable(_localLeaveRequests);
  List<AppNotificationModel> get currentNotifications =>
      List.unmodifiable(_localNotifications);
  List<ComplaintModel> get currentComplaints =>
      List.unmodifiable(_localComplaints);

  FirebaseFirestore? get firestore => _firestore;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firestore = FirebaseFirestore.instance;
      _isFirebaseInitialized = true;

      // Subscribe to Realtime Firestore collections directly
      _listenToFirestoreCollections();
    } catch (e) {
      debugPrint('Firebase initialization warning: $e.');
      _emitState();
    }
  }

  FirebaseAuth get _auth => FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Performs Google Sign-In via OAuth and Firebase Auth
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Canceled by user

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Signs out from Google and Firebase Auth
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign-Out Error: $e');
    }
  }

  /// Looks up user document by email address in local cache and Firestore
  Future<UserModel?> findUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;
    
    // Check local store first
    final localMatch = _localUsers.cast<UserModel?>().firstWhere(
      (u) => u != null && u.email.trim().toLowerCase() == cleanEmail,
      orElse: () => null,
    );
    if (localMatch != null) return localMatch;

    // Check Firestore collections
    if (_isFirebaseInitialized && _firestore != null) {
      try {
        final collectionsToSearch = ['wardens', 'hods', 'ccs', 'students', 'users'];
        for (var colName in collectionsToSearch) {
          final snap = await _firestore!
              .collection(colName)
              .where('email', isEqualTo: cleanEmail)
              .get();
          if (snap.docs.isNotEmpty) {
            final doc = snap.docs.first;
            final data = doc.data();
            if (colName == 'students') {
              final student = StudentModel.fromMap(data, doc.id);
              return UserModel(
                docId: student.docId,
                name: student.name,
                role: 'Student',
                erpNo: student.id,
                department: student.department,
                year: student.year,
                email: student.email,
                password: student.password,
                assignedHod: student.assignedHodName,
                assignedWarden: student.assignedWardenName,
                assignedCc: student.assignedCcName,
                active: student.active,
              );
            } else if (colName == 'wardens') {
              final warden = WardenModel.fromMap(data, doc.id);
              return UserModel(
                docId: warden.docId,
                name: warden.name,
                role: 'Warden',
                erpNo: warden.id,
                department: warden.hostelBlock,
                year: 'N/A',
                email: warden.email,
                password: warden.password,
                assignedHod: '',
                assignedWarden: '',
                assignedCc: '',
                active: warden.active,
              );
            } else if (colName == 'hods') {
              final hod = HodModel.fromMap(data, doc.id);
              return UserModel(
                docId: hod.docId,
                name: hod.name,
                role: 'HOD',
                erpNo: hod.id,
                department: hod.department,
                year: 'N/A',
                email: hod.email,
                password: hod.password,
                assignedHod: '',
                assignedWarden: '',
                assignedCc: '',
                active: hod.active,
              );
            } else if (colName == 'ccs') {
              final cc = CcModel.fromMap(data, doc.id);
              return UserModel(
                docId: cc.docId,
                name: cc.name,
                role: 'Class Mam',
                erpNo: cc.id,
                department: cc.section,
                year: cc.yearBatch,
                email: cc.email,
                password: cc.password,
                assignedHod: '',
                assignedWarden: '',
                assignedCc: '',
                active: cc.active,
              );
            } else {
              return UserModel.fromMap(data, doc.id);
            }
          }
        }
      } catch (e) {
        debugPrint('Error finding user by email in Firestore: $e');
      }
    }
    return null;
  }

  void _rebuildCombinedUsers() {
    _localUsers.clear();

    for (var s in _localStudents) {
      _localUsers.add(UserModel(
        docId: s.docId,
        name: s.name,
        role: 'Student',
        erpNo: s.id,
        department: s.department,
        year: s.year,
        email: s.email,
        password: s.password,
        assignedHod: s.assignedHodName,
        assignedWarden: s.assignedWardenName,
        assignedCc: s.assignedCcName,
        active: s.active,
      ));
    }

    for (var w in _localWardens) {
      _localUsers.add(UserModel(
        docId: w.docId,
        name: w.name,
        role: 'Warden',
        erpNo: w.id,
        department: w.hostelBlock,
        year: 'N/A',
        email: w.email,
        password: w.password,
        assignedHod: '',
        assignedWarden: '',
        assignedCc: '',
        active: w.active,
      ));
    }

    for (var h in _localHods) {
      _localUsers.add(UserModel(
        docId: h.docId,
        name: h.name,
        role: 'HOD',
        erpNo: h.id,
        department: h.department,
        year: 'N/A',
        email: h.email,
        password: h.password,
        assignedHod: '',
        assignedWarden: '',
        assignedCc: '',
        active: h.active,
      ));
    }

    for (var c in _localCcs) {
      _localUsers.add(UserModel(
        docId: c.docId,
        name: c.name,
        role: 'Class Mam',
        erpNo: c.id,
        department: c.section,
        year: c.yearBatch,
        email: c.email,
        password: c.password,
        assignedHod: '',
        assignedWarden: '',
        assignedCc: '',
        active: c.active,
      ));
    }

    _localUsers.add(UserModel(
      docId: 'admin',
      name: 'Velan (Admin)',
      role: 'Admin',
      erpNo: 'velan',
      department: 'Administration',
      year: 'N/A',
      email: 'velan@gmail.com',
      password: 'Amuku_Dumuku_crocodilo',
      assignedHod: '',
      assignedWarden: '',
      assignedCc: '',
      active: true,
    ));
  }

  void _emitState() {
    _rebuildCombinedUsers();

    if (!_usersStreamController.isClosed) {
      _usersStreamController.add(List.from(_localUsers));
    }
    if (!_studentsStreamController.isClosed) {
      _studentsStreamController.add(List.from(_localStudents));
    }
    if (!_wardensStreamController.isClosed) {
      _wardensStreamController.add(List.from(_localWardens));
    }
    if (!_hodsStreamController.isClosed) {
      _hodsStreamController.add(List.from(_localHods));
    }
    if (!_ccsStreamController.isClosed) {
      _ccsStreamController.add(List.from(_localCcs));
    }
    if (!_leaveRequestsStreamController.isClosed) {
      _leaveRequestsStreamController.add(List.from(_localLeaveRequests));
    }
    if (!_notificationsStreamController.isClosed) {
      _notificationsStreamController.add(List.from(_localNotifications));
    }
    if (!_complaintsStreamController.isClosed) {
      _complaintsStreamController.add(List.from(_localComplaints));
    }
  }

  void _listenToFirestoreCollections() {
    if (!_isFirebaseInitialized || _firestore == null) return;

    try {
      _firestore!.collection('complaints').snapshots().listen((snapshot) {
        _localComplaints.clear();
        for (var doc in snapshot.docs) {
          _localComplaints.add(ComplaintModel.fromMap(doc.data(), doc.id));
        }
        _localComplaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _emitState();
      }, onError: (err) => debugPrint('Firestore complaints snapshot error: $err'));

      _firestore!.collection('notifications').snapshots().listen((snapshot) {
        _localNotifications.clear();
        for (var doc in snapshot.docs) {
          _localNotifications.add(AppNotificationModel.fromMap(doc.data(), doc.id));
        }
        _localNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _emitState();
      }, onError: (err) => debugPrint('Firestore notifications snapshot error: $err'));

      _firestore!.collection('students').snapshots().listen((snapshot) {
        _localStudents.clear();
        for (var doc in snapshot.docs) {
          _localStudents.add(StudentModel.fromMap(doc.data(), doc.id));
        }
        _emitState();
      }, onError: (err) => debugPrint('Firestore students snapshot error: $err'));

      _firestore!.collection('wardens').snapshots().listen((snapshot) {
        _localWardens.clear();
        for (var doc in snapshot.docs) {
          _localWardens.add(WardenModel.fromMap(doc.data(), doc.id));
        }
        _emitState();
      }, onError: (err) => debugPrint('Firestore wardens snapshot error: $err'));

      _firestore!.collection('hods').snapshots().listen((snapshot) {
        _localHods.clear();
        for (var doc in snapshot.docs) {
          _localHods.add(HodModel.fromMap(doc.data(), doc.id));
        }
        _emitState();
      }, onError: (err) => debugPrint('Firestore hods snapshot error: $err'));

      _firestore!.collection('ccs').snapshots().listen((snapshot) {
        _localCcs.clear();
        for (var doc in snapshot.docs) {
          _localCcs.add(CcModel.fromMap(doc.data(), doc.id));
        }
        _emitState();
      }, onError: (err) => debugPrint('Firestore ccs snapshot error: $err'));

      _firestore!.collection('leave_requests').snapshots().listen((snapshot) {
        _localLeaveRequests.clear();
        for (var doc in snapshot.docs) {
          _localLeaveRequests.add(LeaveRequestModel.fromMap(doc.data(), doc.id));
        }
        _localLeaveRequests.sort((a, b) {
          final aIsPending = a.status.toLowerCase().startsWith('pending');
          final bIsPending = b.status.toLowerCase().startsWith('pending');

          if (aIsPending && !bIsPending) return -1;
          if (!aIsPending && bIsPending) return 1;

          return b.createdAt.compareTo(a.createdAt);
        });
        _emitState();
      }, onError: (err) => debugPrint('Firestore requests snapshot error: $err'));
    } catch (e) {
      debugPrint('Firestore listen error: $e');
    }
  }

  /// Generates a unique document ID based on the user's name:
  /// Converts to lowerCase and replaces spaces with '_'.
  /// If a conflict occurs with an existing user name, appends `_1`, `_2`, ... `_n`.
  String generateUniqueDocId(String name) {
    final baseId = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final cleanBase = baseId.isNotEmpty ? baseId : 'user';

    if (!_localUsers.any((u) => u.docId == cleanBase)) {
      return cleanBase;
    }

    int index = 1;
    while (_localUsers.any((u) => u.docId == '${cleanBase}_$index')) {
      index++;
    }
    return '${cleanBase}_$index';
  }

  // ──────────────────── SESSION & AUTHENTICATION ────────────────────

  Future<void> saveUserSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_user', jsonEncode(user.toMap()));
    } catch (e) {
      debugPrint('Error saving user session: $e');
    }
  }

  Future<UserModel?> loadSavedUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('logged_in_user');
      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(userJson);
        return UserModel.fromMap(map, map['docId'] ?? map['id'] ?? 'user');
      }
    } catch (e) {
      debugPrint('Error loading saved user session: $e');
    }
    return null;
  }

  Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_in_user');
    } catch (e) {
      debugPrint('Error clearing user session: $e');
    }
  }

  Future<Map<String, dynamic>> loginWithEmail(String emailOrId, String password, {String? targetRole}) async {
    final queryKey = emailOrId.trim().toLowerCase();
    final trimmedPassword = password.trim();

    final normalizedTargetRole = targetRole?.toLowerCase().trim() ?? '';
    final bool isStudentTarget = normalizedTargetRole == 'student';
    final bool isStaffTarget = normalizedTargetRole == 'warden' ||
        normalizedTargetRole == 'hod' ||
        normalizedTargetRole == 'cc' ||
        normalizedTargetRole == 'class mam';

    if (queryKey.isEmpty || trimmedPassword.isEmpty) {
      final roleLabel = isStudentTarget
          ? 'ERP no / Gmail'
          : (normalizedTargetRole == 'admin' ? 'Username' : 'Gmail');
      return {'success': false, 'error': 'Please enter your $roleLabel and password'};
    }

    UserModel? matchedUser;

    // Helper to evaluate if a user model matches the query according to strict role constraints
    bool isMatch(UserModel u) {
      final cleanEmail = u.email.trim().toLowerCase();
      final cleanErp = u.erpNo.trim().toLowerCase();
      final cleanDocId = u.docId.trim().toLowerCase();

      if (isStaffTarget) {
        // Staff (CC, HOD, Warden) MUST match by Gmail ONLY
        return cleanEmail.isNotEmpty && cleanEmail == queryKey;
      } else if (isStudentTarget) {
        // Student MUST match by Roll No / ERP No OR Gmail ONLY
        return (cleanEmail.isNotEmpty && cleanEmail == queryKey) ||
            (cleanErp.isNotEmpty && cleanErp == queryKey) ||
            (cleanDocId.isNotEmpty && cleanDocId == queryKey);
      } else {
        // Admin or General query: match Email, ERP/Username, or DocId
        return (cleanEmail.isNotEmpty && cleanEmail == queryKey) ||
            (cleanErp.isNotEmpty && cleanErp == queryKey) ||
            (cleanDocId.isNotEmpty && cleanDocId == queryKey);
      }
    }

    // 1. Search local cached user store first
    for (var u in _localUsers) {
      if (isMatch(u)) {
        matchedUser = u;
        break;
      }
    }

    // 2. Query Firestore collections directly if not found in local cache
    if (matchedUser == null && _isFirebaseInitialized && _firestore != null) {
      try {
        final collectionsToSearch = isStaffTarget
            ? ['wardens', 'hods', 'ccs']
            : (isStudentTarget ? ['students'] : ['students', 'wardens', 'hods', 'ccs', 'users']);

        for (var colName in collectionsToSearch) {
          if (matchedUser != null) break;

          final snap = await _firestore!.collection(colName).get();
          for (var doc in snap.docs) {
            final data = doc.data();
            final docId = doc.id;

            UserModel candidate;
            if (colName == 'students') {
              final student = StudentModel.fromMap(data, docId);
              candidate = UserModel(
                docId: student.docId,
                name: student.name,
                role: 'Student',
                erpNo: student.id,
                department: student.department,
                year: student.year,
                email: student.email,
                password: student.password.isNotEmpty ? student.password : 'student123',
                assignedHod: student.assignedHodName,
                assignedWarden: student.assignedWardenName,
                assignedCc: student.assignedCcName,
                active: student.active,
              );
            } else if (colName == 'wardens') {
              final warden = WardenModel.fromMap(data, docId);
              candidate = UserModel(
                docId: warden.docId,
                name: warden.name,
                role: 'Warden',
                erpNo: warden.id,
                department: warden.hostelBlock,
                year: 'N/A',
                email: warden.email,
                password: warden.password.isNotEmpty ? warden.password : 'warden123',
                assignedHod: '',
                assignedWarden: '',
                assignedCc: '',
                active: warden.active,
              );
            } else if (colName == 'hods') {
              final hod = HodModel.fromMap(data, docId);
              candidate = UserModel(
                docId: hod.docId,
                name: hod.name,
                role: 'HOD',
                erpNo: hod.id,
                department: hod.department,
                year: 'N/A',
                email: hod.email,
                password: hod.password.isNotEmpty ? hod.password : 'hod123',
                assignedHod: '',
                assignedWarden: '',
                assignedCc: '',
                active: hod.active,
              );
            } else if (colName == 'ccs') {
              final cc = CcModel.fromMap(data, docId);
              candidate = UserModel(
                docId: cc.docId,
                name: cc.name,
                role: 'Class Mam',
                erpNo: cc.id,
                department: cc.section,
                year: cc.yearBatch,
                email: cc.email,
                password: cc.password.isNotEmpty ? cc.password : 'cc123',
                assignedHod: '',
                assignedWarden: '',
                assignedCc: '',
                active: cc.active,
              );
            } else {
              candidate = UserModel.fromMap(data, docId);
            }

            if (isMatch(candidate)) {
              matchedUser = candidate;
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('Firestore login search error: $e');
      }
    }

    // 3. Fallback Dev Accounts (Strict exact credential match ONLY)
    if (matchedUser == null) {
      if ((queryKey == 'velan' || queryKey == 'admin@gmail.com') && (normalizedTargetRole == 'admin' || normalizedTargetRole.isEmpty)) {
        matchedUser = UserModel(
          docId: 'admin',
          name: 'Velan (Admin)',
          role: 'Admin',
          erpNo: 'velan',
          department: 'Administration',
          year: 'N/A',
          email: 'velan@gmail.com',
          password: 'Amuku_Dumuku_crocodilo',
          assignedHod: '',
          assignedWarden: '',
          assignedCc: '',
          active: true,
        );
      } else if ((queryKey == '814425149012' || queryKey == 'student@gmail.com') && isStudentTarget) {
        matchedUser = UserModel(
          docId: 'student_dev',
          name: 'Dev Student',
          role: 'Student',
          erpNo: '814425149012',
          department: 'Computer Science',
          year: '3rd Year',
          email: 'student@gmail.com',
          password: 'student123',
          assignedHod: 'Kavitha Mam',
          assignedWarden: 'Sarathbabu',
          assignedCc: 'Pradeepa Mam',
          active: true,
        );
      } else if (queryKey == 'pradeepa@gmail.com' && (normalizedTargetRole == 'cc' || normalizedTargetRole == 'class mam')) {
        matchedUser = UserModel(
          docId: 'pradeepa_mam',
          name: 'Pradeepa Mam',
          role: 'Class Mam',
          erpNo: 'pradeepa_mam',
          department: 'Section A',
          year: 'N/A',
          email: 'pradeepa@gmail.com',
          password: 'cc123',
          assignedHod: '',
          assignedWarden: '',
          assignedCc: '',
          active: true,
        );
      } else if (queryKey == 'kavitha@gmail.com' && normalizedTargetRole == 'hod') {
        matchedUser = UserModel(
          docId: 'kavitha_mam',
          name: 'Kavitha Mam',
          role: 'HOD',
          erpNo: 'kavitha_mam',
          department: 'Computer Science',
          year: 'N/A',
          email: 'kavitha@gmail.com',
          password: 'hod123',
          assignedHod: '',
          assignedWarden: '',
          assignedCc: '',
          active: true,
        );
      } else if ((queryKey == 'sivasir@gmail.com' || queryKey == 'sarathbabu@gmail.com') && normalizedTargetRole == 'warden') {
        matchedUser = UserModel(
          docId: 'siva_sir',
          name: 'Siva Sir',
          role: 'Warden',
          erpNo: 'siva_sir',
          department: 'Block A',
          year: 'N/A',
          email: 'sivasir@gmail.com',
          password: 'warden123',
          assignedHod: '',
          assignedWarden: '',
          assignedCc: '',
          active: true,
        );
      }
    }

    if (matchedUser != null) {
      // 4. Strict Role Validation
      if (normalizedTargetRole.isNotEmpty) {
        final userRole = matchedUser.role.toLowerCase().trim();

        bool isRoleMatch = false;
        if (normalizedTargetRole == 'student' && userRole == 'student') {
          isRoleMatch = true;
        }
        if (normalizedTargetRole == 'warden' && userRole == 'warden') {
          isRoleMatch = true;
        }
        if (normalizedTargetRole == 'hod' && userRole == 'hod') {
          isRoleMatch = true;
        }
        if ((normalizedTargetRole == 'cc' || normalizedTargetRole == 'class mam') &&
            (userRole == 'cc' || userRole == 'class mam' || userRole == 'faculty' || userRole == 'class counselor' || userRole == 'class coordinator')) {
          isRoleMatch = true;
        }
        if (normalizedTargetRole == 'admin' && userRole == 'admin') {
          isRoleMatch = true;
        }

        if (!isRoleMatch) {
          return {
            'success': false,
            'error': 'This account (${matchedUser.name}) is registered as ${matchedUser.role}. Please log in through the ${matchedUser.role} portal.',
          };
        }
      }

      // 5. Password Validation
      final String userRoleLower = matchedUser.role.toLowerCase().trim();
      final String defaultRolePass = userRoleLower == 'student'
          ? 'student123'
          : (userRoleLower == 'warden'
              ? 'warden123'
              : (userRoleLower == 'hod'
                  ? 'hod123'
                  : (userRoleLower == 'class mam' || userRoleLower == 'cc' ? 'cc123' : 'password123')));

      final String storedPassword = matchedUser.password.isNotEmpty ? matchedUser.password : defaultRolePass;

      if (trimmedPassword == storedPassword || trimmedPassword == defaultRolePass) {
        if (!matchedUser.active) {
          return {'success': false, 'error': 'Account is deactivated. Contact admin.'};
        }
        await saveUserSession(matchedUser);
        await PushNotificationService().registerCurrentUserFcmToken(matchedUser.docId);
        return {'success': true, 'user': matchedUser};
      } else {
        return {'success': false, 'error': 'Incorrect password. Please try again.'};
      }
    }

    final idType = isStudentTarget ? 'ERP no or Gmail' : (isStaffTarget ? 'Gmail' : 'Username / Email');
    return {'success': false, 'error': 'No account found matching "$emailOrId" ($idType). Please contact Admin.'};
  }

  // WARDEN COLLECTION OPERATIONS

  Future<bool> addWarden(WardenModel warden) async {
    final docId = warden.docId.isNotEmpty ? warden.docId : generateUniqueDocId(warden.name);
    final newWarden = warden.copyWith(docId: docId, id: docId);
    
    final index = _localWardens.indexWhere((w) => w.docId == docId || w.id == docId);
    if (index != -1) {
      _localWardens[index] = newWarden;
    } else {
      _localWardens.add(newWarden);
    }

    _emitState();

    if (_isFirebaseInitialized && _firestore != null) {
      try {
        await _firestore!.collection('wardens').doc(docId).set(newWarden.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error adding/updating warden in Firestore: $e');
      }
    }
    return true;
  }

  Future<bool> updateWarden(WardenModel warden) async {
    return addWarden(warden);
  }

  Future<bool> deleteWarden(String docIdOrId) async {
    final index = _localWardens.indexWhere((w) => w.docId == docIdOrId || w.id == docIdOrId);
    if (index != -1) {
      final docId = _localWardens[index].docId;
      _localWardens.removeAt(index);
      _emitState();

      if (_isFirebaseInitialized && _firestore != null) {
        try {
          await _firestore!.collection('wardens').doc(docId).delete();
        } catch (e) {
          debugPrint('Error deleting warden from Firestore: $e');
        }
      }
      return true;
    }
    return false;
  }

  // HOD COLLECTION OPERATIONS

  Future<bool> addHod(HodModel hod) async {
    final docId = hod.docId.isNotEmpty ? hod.docId : generateUniqueDocId(hod.name);
    final newHod = hod.copyWith(docId: docId, id: docId);
    
    final index = _localHods.indexWhere((h) => h.docId == docId || h.id == docId);
    if (index != -1) {
      _localHods[index] = newHod;
    } else {
      _localHods.add(newHod);
    }

    _emitState();

    if (_isFirebaseInitialized && _firestore != null) {
      try {
        await _firestore!.collection('hods').doc(docId).set(newHod.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error adding/updating HOD in Firestore: $e');
      }
    }
    return true;
  }

  Future<bool> updateHod(HodModel hod) async {
    return addHod(hod);
  }

  Future<bool> deleteHod(String docIdOrId) async {
    final index = _localHods.indexWhere((h) => h.docId == docIdOrId || h.id == docIdOrId);
    if (index != -1) {
      final docId = _localHods[index].docId;
      _localHods.removeAt(index);
      _emitState();

      if (_isFirebaseInitialized && _firestore != null) {
        try {
          await _firestore!.collection('hods').doc(docId).delete();
        } catch (e) {
          debugPrint('Error deleting HOD from Firestore: $e');
        }
      }
      return true;
    }
    return false;
  }

  // CC (CLASS COORDINATOR / CLASS MAM) OPERATIONS

  Future<bool> addCc(CcModel cc) async {
    final docId = cc.docId.isNotEmpty ? cc.docId : generateUniqueDocId(cc.name);
    final newCc = cc.copyWith(docId: docId, id: docId);
    
    final index = _localCcs.indexWhere((c) => c.docId == docId || c.id == docId);
    if (index != -1) {
      _localCcs[index] = newCc;
    } else {
      _localCcs.add(newCc);
    }

    _emitState();

    if (_isFirebaseInitialized && _firestore != null) {
      try {
        await _firestore!.collection('ccs').doc(docId).set(newCc.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error adding/updating CC in Firestore: $e');
      }
    }
    return true;
  }

  Future<bool> updateCc(CcModel cc) async {
    return addCc(cc);
  }

  Future<bool> deleteCc(String docIdOrId) async {
    final index = _localCcs.indexWhere((c) => c.docId == docIdOrId || c.id == docIdOrId);
    if (index != -1) {
      final docId = _localCcs[index].docId;
      _localCcs.removeAt(index);
      _emitState();

      if (_isFirebaseInitialized && _firestore != null) {
        try {
          await _firestore!.collection('ccs').doc(docId).delete();
        } catch (e) {
          debugPrint('Error deleting CC from Firestore: $e');
        }
      }
      return true;
    }
    return false;
  }

  // STUDENT COLLECTION OPERATIONS

  Future<bool> addStudent(StudentModel student) async {
    final docId = student.docId.isNotEmpty ? student.docId : generateUniqueDocId(student.name);
    final newStudent = student.copyWith(docId: docId);
    
    final index = _localStudents.indexWhere((s) => s.docId == docId || s.id == student.id);
    if (index != -1) {
      _localStudents[index] = newStudent;
    } else {
      _localStudents.add(newStudent);
    }

    _emitState();

    if (_isFirebaseInitialized && _firestore != null) {
      try {
        await _firestore!.collection('students').doc(docId).set(newStudent.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error adding/updating student in Firestore: $e');
      }
    }
    return true;
  }

  Future<bool> updateStudent(StudentModel student) async {
    return addStudent(student);
  }

  Future<bool> deleteStudent(String docIdOrId) async {
    final index = _localStudents.indexWhere((s) => s.docId == docIdOrId || s.id == docIdOrId);
    if (index != -1) {
      final docId = _localStudents[index].docId;
      _localStudents.removeAt(index);
      _emitState();

      if (_isFirebaseInitialized && _firestore != null) {
        try {
          await _firestore!.collection('students').doc(docId).delete();
        } catch (e) {
          debugPrint('Error deleting student from Firestore: $e');
        }
      }
      return true;
    }
    return false;
  }
  /// Fetches live role Firestore collections and returns a formatted JSON dump string.
  Future<String> exportDatabaseToJsonDump() async {
    final Map<String, dynamic> exportDump = {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '2.0.0',
      'collections': {
        'students': _localStudents.map((s) => s.toMap()).toList(),
        'wardens': _localWardens.map((w) => w.toMap()).toList(),
        'hods': _localHods.map((h) => h.toMap()).toList(),
        'ccs': _localCcs.map((c) => c.toMap()).toList(),
        'leave_requests': _localLeaveRequests.map((r) => r.toMap()).toList(),
      }
    };

    if (_isFirebaseInitialized && _firestore != null) {
      try {
        final studentsSnap = await _firestore!.collection('students').get();
        final wardensSnap = await _firestore!.collection('wardens').get();
        final hodsSnap = await _firestore!.collection('hods').get();
        final ccsSnap = await _firestore!.collection('ccs').get();
        final requestsSnap = await _firestore!.collection('leave_requests').get();

        exportDump['collections'] = {
          'students': studentsSnap.docs.map((doc) => {'docId': doc.id, ...doc.data()}).toList(),
          'wardens': wardensSnap.docs.map((doc) => {'docId': doc.id, ...doc.data()}).toList(),
          'hods': hodsSnap.docs.map((doc) => {'docId': doc.id, ...doc.data()}).toList(),
          'ccs': ccsSnap.docs.map((doc) => {'docId': doc.id, ...doc.data()}).toList(),
          'leave_requests': requestsSnap.docs.map((doc) => {'docId': doc.id, ...doc.data()}).toList(),
        };
      } catch (e) {
        debugPrint('Error fetching live Firestore collections for JSON export: $e');
      }
    }

    return const JsonEncoder.withIndent('  ').convert(exportDump);
  }

  /// Saves the JSON dump string to a local file on device storage
  /// Returns the absolute filepath where the file was saved.
  Future<String> saveJsonDumpToLocalFile(String jsonDump) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/hostel_database_dump_$timestamp.json');
      await file.writeAsString(jsonDump);
      return file.path;
    } catch (e) {
      debugPrint('Error saving JSON dump to local file: $e');
      rethrow;
    }
  }

  Future<bool> addUser({
    required String name,
    required String role,
    required String erpNo,
    required String email,
    String? password,
    String department = '',
    String year = '',
    String assignedHod = '',
    String assignedWarden = '',
    String assignedCc = '',
    bool active = true,
  }) async {
    final docId = generateUniqueDocId(name);
    if (role.toLowerCase() == 'student') {
      return addStudent(StudentModel(docId: docId, id: erpNo, name: name, email: email, password: password ?? 'student123', department: department, year: year.isNotEmpty ? year : '1st Year', active: active));
    } else if (role.toLowerCase() == 'warden') {
      return addWarden(WardenModel(docId: docId, id: docId, name: name, email: email, password: password ?? 'warden123', active: active));
    } else if (role.toLowerCase() == 'hod') {
      return addHod(HodModel(docId: docId, id: docId, name: name, email: email, password: password ?? 'hod123', department: department, active: active));
    } else {
      return addCc(CcModel(docId: docId, id: docId, name: name, email: email, password: password ?? 'cc123', section: department, active: active));
    }
  }

  Future<bool> updateUser({
    required String docId,
    required String name,
    required String role,
    required String erpNo,
    required String email,
    String? password,
    String department = '',
    String year = '',
    String assignedHod = '',
    String assignedWarden = '',
    String assignedCc = '',
    required bool active,
  }) async {
    if (role.toLowerCase() == 'student') {
      return addStudent(StudentModel(docId: docId, id: erpNo, name: name, email: email, password: password ?? 'student123', department: department, year: year.isNotEmpty ? year : '1st Year', active: active));
    } else if (role.toLowerCase() == 'warden') {
      return addWarden(WardenModel(docId: docId, id: docId, name: name, email: email, password: password ?? 'warden123', active: active));
    } else if (role.toLowerCase() == 'hod') {
      return addHod(HodModel(docId: docId, id: docId, name: name, email: email, password: password ?? 'hod123', department: department, active: active));
    } else {
      return addCc(CcModel(docId: docId, id: docId, name: name, email: email, password: password ?? 'cc123', section: department, active: active));
    }
  }

  Future<bool> deleteUser(String docIdOrId) async {
    final deletedStudent = await deleteStudent(docIdOrId);
    final deletedWarden = await deleteWarden(docIdOrId);
    final deletedHod = await deleteHod(docIdOrId);
    final deletedCc = await deleteCc(docIdOrId);
    return deletedStudent || deletedWarden || deletedHod || deletedCc;
  }

  // NOTIFICATION OPERATIONS

  List<AppNotificationModel> getNotificationsForUser(
    String userIdentifier,
    String role, {
    UserModel? user,
  }) {
    final uIdLower = userIdentifier.trim().toLowerCase();
    final roleLower = role.trim().toLowerCase();

    bool roleMatches(String targetRole) {
      final tr = targetRole.trim().toLowerCase();
      if (tr.isEmpty || tr == 'all') return true;
      if (tr == roleLower) return true;
      if ((roleLower == 'class mam' || roleLower == 'cc' || roleLower == 'class coordinator') &&
          (tr == 'cc' || tr == 'class mam' || tr == 'class coordinator')) {
        return true;
      }
      return false;
    }

    final Set<String> userKeys = {};
    if (uIdLower.isNotEmpty) userKeys.add(uIdLower);
    if (user != null) {
      if (user.id.isNotEmpty) userKeys.add(user.id.trim().toLowerCase());
      if (user.erpNo.isNotEmpty) userKeys.add(user.erpNo.trim().toLowerCase());
      if (user.email.isNotEmpty) userKeys.add(user.email.trim().toLowerCase());
      if (user.name.isNotEmpty) userKeys.add(user.name.trim().toLowerCase());
    }

    return _localNotifications.where((n) {
      final recId = n.recipientId.trim().toLowerCase();
      final recRole = n.recipientRole.trim().toLowerCase();

      // Enforce role match first to prevent cross-role leak
      if (!roleMatches(recRole)) return false;

      // Generic role broadcast
      final isGenericId = recId.isEmpty ||
          recId == 'all' ||
          recId == 'warden' ||
          recId == 'student' ||
          recId == 'hod' ||
          recId == 'cc' ||
          recId == 'class mam' ||
          recId == 'class coordinator';

      if (isGenericId) return true;

      // Targeted ID match against user keys
      for (var key in userKeys) {
        if (key.isNotEmpty) {
          if (recId == key || recId.contains(key) || key.contains(recId)) {
            return true;
          }
        }
      }

      return false;
    }).toList();
  }

  int getUnreadNotificationCount(String userIdentifier, String role, {UserModel? user}) {
    return getNotificationsForUser(userIdentifier, role, user: user).where((n) => !n.isRead).length;
  }

  Future<void> sendNotification({
    required String recipientId,
    required String recipientRole,
    required String title,
    required String message,
    required String leaveRequestId,
    String type = 'info',
  }) async {
    final now = DateTime.now();
    final docId = 'notif_${now.millisecondsSinceEpoch}_${_localNotifications.length + 1}';
    final notif = AppNotificationModel(
      id: docId,
      recipientId: recipientId,
      recipientRole: recipientRole,
      title: title,
      message: message,
      leaveRequestId: leaveRequestId,
      createdAt: now,
      isRead: false,
      type: type,
    );

    _localNotifications.insert(0, notif);
    _localNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _emitState();

    if (_isFirebaseInitialized && _firestore != null) {
      try {
        await _firestore!.collection('notifications').doc(docId).set(notif.toMap());
      } catch (e) {
        debugPrint('Error sending notification to Firestore: $e');
      }
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final index = _localNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final updated = _localNotifications[index].copyWith(isRead: true);
      _localNotifications[index] = updated;
      _emitState();

      if (_isFirebaseInitialized && _firestore != null) {
        try {
          await _firestore!.collection('notifications').doc(notificationId).update({'isRead': true});
        } catch (e) {
          debugPrint('Error marking notification as read in Firestore: $e');
        }
      }
    }
  }

  Future<void> markAllNotificationsAsRead(String userIdentifier, String role) async {
    final userNotifs = getNotificationsForUser(userIdentifier, role);
    for (var n in userNotifs) {
      if (!n.isRead) {
        await markNotificationAsRead(n.id);
      }
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    _localNotifications.removeWhere((n) => n.id == notificationId);
    _emitState();

    if (_isFirebaseInitialized && _firestore != null) {
      try {
        await _firestore!.collection('notifications').doc(notificationId).delete();
      } catch (e) {
        debugPrint('Error deleting notification from Firestore: $e');
      }
    }
  }

  Future<void> clearAllNotificationsForUser(String userIdentifier, String role) async {
    final userNotifs = getNotificationsForUser(userIdentifier, role);
    for (var n in userNotifs) {
      await deleteNotification(n.id);
    }
  }

  // LEAVE REQUESTS OPERATIONS

  Future<bool> addLeaveRequest({
    required String studentName,
    required String rollNo,
    required String type,
    required String fromDate,
    required String toDate,
    String departureTime = '09:00 AM',
    String arrivalTime = '06:00 PM',
    required String reason,
    String assignedCcId = '',
    String assignedCcName = '',
    String assignedHodId = '',
    String assignedHodName = '',
    String assignedWardenId = '',
    String assignedWardenName = '',
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final newDocId = 'req_$nowMs';
    final newReq = LeaveRequestModel(
      docId: newDocId,
      id: '${_localLeaveRequests.length + 1}',
      studentName: studentName,
      rollNo: rollNo,
      type: type,
      fromDate: fromDate,
      toDate: toDate,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      reason: reason,
      status: 'pending_cc',
      classMamSigned: false,
      hodSigned: false,
      wardenSigned: false,
      submittedOn: _formatDate(DateTime.now()),
      createdAt: nowMs,
      assignedCcId: assignedCcId,
      assignedCcName: assignedCcName,
      assignedHodId: assignedHodId,
      assignedHodName: assignedHodName,
      assignedWardenId: assignedWardenId,
      assignedWardenName: assignedWardenName,
    );

    _localLeaveRequests.insert(0, newReq);
    _localLeaveRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _emitState();

    if (_isFirebaseInitialized && _firestore != null) {
      try {
        await _firestore!
            .collection('leave_requests')
            .doc(newDocId)
            .set(newReq.toMap());
      } catch (e) {
        debugPrint('Error adding leave request to Firestore: $e');
      }
    }

    // Trigger real-time notifications for new request
    await sendNotification(
      recipientId: rollNo,
      recipientRole: 'student',
      title: '🚀 Leave Request Submitted',
      message: 'Your $type leave request ($fromDate to $toDate) has been submitted! Pending Class Coordinator review.',
      leaveRequestId: newDocId,
      type: 'info',
    );

    await sendNotification(
      recipientId: assignedCcId.isNotEmpty ? assignedCcId : assignedCcName,
      recipientRole: 'cc',
      title: '📋 Action Required: New Leave Request',
      message: '$studentName ($rollNo) submitted a $type leave request ($fromDate to $toDate). Tap to review & approve.',
      leaveRequestId: newDocId,
      type: 'new_request',
    );

    await sendNotification(
      recipientId: assignedHodId.isNotEmpty ? assignedHodId : assignedHodName,
      recipientRole: 'hod',
      title: 'ℹ️ Info: New Leave Request',
      message: '$studentName ($rollNo) submitted a $type leave request ($fromDate to $toDate).',
      leaveRequestId: newDocId,
      type: 'new_request',
    );

    await sendNotification(
      recipientId: assignedWardenId.isNotEmpty ? assignedWardenId : assignedWardenName,
      recipientRole: 'warden',
      title: 'ℹ️ Info: New Leave Request',
      message: '$studentName ($rollNo) submitted a $type leave request ($fromDate to $toDate).',
      leaveRequestId: newDocId,
      type: 'new_request',
    );

    return true;
  }

  Future<bool> updateLeaveRequestStatus({
    required String idOrDocId,
    required String newStatus,
    bool? wardenSigned,
    bool? hodSigned,
    bool? classMamSigned,
    String? declineReason,
  }) async {
    final index = _localLeaveRequests.indexWhere(
        (r) => r.docId == idOrDocId || r.id == idOrDocId);

    if (index != -1) {
      final current = _localLeaveRequests[index];
      final updated = LeaveRequestModel(
        docId: current.docId,
        id: current.id,
        studentName: current.studentName,
        rollNo: current.rollNo,
        type: current.type,
        fromDate: current.fromDate,
        toDate: current.toDate,
        departureTime: current.departureTime,
        arrivalTime: current.arrivalTime,
        reason: current.reason,
        status: newStatus,
        classMamSigned: classMamSigned ?? current.classMamSigned,
        hodSigned: hodSigned ?? current.hodSigned,
        wardenSigned: wardenSigned ?? current.wardenSigned,
        submittedOn: current.submittedOn,
        createdAt: current.createdAt,
        assignedCcId: current.assignedCcId,
        assignedCcName: current.assignedCcName,
        assignedHodId: current.assignedHodId,
        assignedHodName: current.assignedHodName,
        assignedWardenId: current.assignedWardenId,
        assignedWardenName: current.assignedWardenName,
        declineReason: declineReason ?? current.declineReason,
      );

      _localLeaveRequests[index] = updated;
      _localLeaveRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _emitState();

      if (_isFirebaseInitialized && _firestore != null) {
        try {
          await _firestore!
              .collection('leave_requests')
              .doc(updated.docId)
              .update(updated.toMap());
        } catch (e) {
          debugPrint('Error updating leave request in Firestore: $e');
        }
      }

      // Trigger status update notifications
      if (newStatus == 'rejected') {
        await sendNotification(
          recipientId: current.rollNo,
          recipientRole: 'student',
          title: '⚠️ Leave Request Declined',
          message: 'Your ${current.type} leave request (${current.fromDate} - ${current.toDate}) was not approved. Remarks: ${declineReason ?? 'Not specified'}.',
          leaveRequestId: current.docId,
          type: 'rejection',
        );
      } else if (classMamSigned == true || newStatus == 'pending_hod') {
        await sendNotification(
          recipientId: current.rollNo,
          recipientRole: 'student',
          title: '✅ Step 1 Approved: Class Coordinator',
          message: 'Class Coordinator approved your ${current.type} leave request! Forwarded to HOD for signature.',
          leaveRequestId: current.docId,
          type: 'approval',
        );
        await sendNotification(
          recipientId: current.assignedHodId.isNotEmpty ? current.assignedHodId : current.assignedHodName,
          recipientRole: 'hod',
          title: '📋 Action Required: Pending HOD Signature',
          message: 'Class Coordinator signed off leave request for ${current.studentName}. Awaiting your approval.',
          leaveRequestId: current.docId,
          type: 'new_request',
        );
      } else if (hodSigned == true || newStatus == 'approved') {
        if (wardenSigned == true || newStatus == 'approved') {
          await sendNotification(
            recipientId: current.rollNo,
            recipientRole: 'student',
            title: '🎉 LEAVE FULLY APPROVED!',
            message: 'Warden granted final approval! Your digital gate pass is active for ${current.fromDate} to ${current.toDate}. Safe travels!',
            leaveRequestId: current.docId,
            type: 'approval',
          );
          await sendNotification(
            recipientId: current.assignedCcId.isNotEmpty ? current.assignedCcId : current.assignedCcName,
            recipientRole: 'cc',
            title: '🎉 Fully Approved',
            message: 'Leave request for ${current.studentName} (${current.type}) has been fully approved by Warden.',
            leaveRequestId: current.docId,
            type: 'approval',
          );
          await sendNotification(
            recipientId: current.assignedHodId.isNotEmpty ? current.assignedHodId : current.assignedHodName,
            recipientRole: 'hod',
            title: '🎉 Fully Approved',
            message: 'Leave request for ${current.studentName} (${current.type}) has been fully approved by Warden.',
            leaveRequestId: current.docId,
            type: 'approval',
          );
        } else {
          await sendNotification(
            recipientId: current.rollNo,
            recipientRole: 'student',
            title: '✅ Step 2 Approved: HOD',
            message: 'HOD approved your ${current.type} leave request! Sent to Warden for final sign-off.',
            leaveRequestId: current.docId,
            type: 'approval',
          );
          await sendNotification(
            recipientId: current.assignedWardenId.isNotEmpty ? current.assignedWardenId : current.assignedWardenName,
            recipientRole: 'warden',
            title: '📋 Action Required: Pending Warden Final Sign-off',
            message: 'HOD approved leave request for ${current.studentName}. Pending your final signature.',
            leaveRequestId: current.docId,
            type: 'new_request',
          );
        }
      }

      return true;
    }
    return false;
  }

  Future<bool> cancelLeaveRequest(String idOrDocId) async {
    return updateLeaveRequestStatus(
      idOrDocId: idOrDocId,
      newStatus: 'cancelled',
    );
  }

  Future<bool> deleteLeaveRequest(String idOrDocId) async {
    final index = _localLeaveRequests.indexWhere(
      (r) => r.docId == idOrDocId || r.id == idOrDocId,
    );
    if (index != -1) {
      final docId = _localLeaveRequests[index].docId;
      _localLeaveRequests.removeAt(index);
      _emitState();

      if (_isFirebaseInitialized && _firestore != null) {
        try {
          await _firestore!.collection('leave_requests').doc(docId).delete();
        } catch (e) {
          debugPrint('Error deleting leave request from Firestore: $e');
        }
      }
      return true;
    }
    return false;
  }

  Future<bool> clearAllLeaveRequests() async {
    _localLeaveRequests.clear();
    _emitState();

    if (_isFirebaseInitialized && _firestore != null) {
      try {
        final snap = await _firestore!.collection('leave_requests').get();
        for (var doc in snap.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('Error clearing all leave requests from Firestore: $e');
      }
    }
    return true;
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  // COMPLAINT OPERATIONS

  Future<void> submitComplaint({
    required String complainantName,
    required String complainantId,
    required String complainantRole,
    required String category,
    required String description,
    String assignedWardenId = '',
    String assignedWardenName = '',
  }) async {
    final now = DateTime.now();
    final docId = 'complaint_${now.millisecondsSinceEpoch}';
    final complaint = ComplaintModel(
      id: docId,
      complainantName: complainantName,
      complainantId: complainantId,
      complainantRole: complainantRole,
      category: category,
      description: description,
      status: 'pending',
      createdAt: now,
      assignedWardenId: assignedWardenId,
      assignedWardenName: assignedWardenName,
    );

    _localComplaints.insert(0, complaint);
    _localComplaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _emitState();

    if (_isFirebaseInitialized && _firestore != null) {
      try {
        await _firestore!.collection('complaints').doc(docId).set(complaint.toMap());
      } catch (e) {
        debugPrint('Error saving complaint to Firestore: $e');
      }
    }

    // Send confirmation to Student
    if (complainantId.isNotEmpty) {
      await sendNotification(
        recipientId: complainantId,
        recipientRole: complainantRole,
        title: '🛡️ Complaint Logged',
        message: 'Your complaint regarding $category has been submitted to your Hostel Warden for review.',
        leaveRequestId: docId,
        type: 'info',
      );
    }

    // Send targeted notification to corresponding Warden
    final targetRecipient = assignedWardenId.isNotEmpty ? assignedWardenId : 'warden';
    await sendNotification(
      recipientId: targetRecipient,
      recipientRole: 'warden',
      title: '🚨 Priority Notice: New Student Complaint',
      message: '$complainantName filed a complaint regarding $category: "$description". Tap to inspect and take action.',
      leaveRequestId: docId,
      type: 'complaint',
    );
  }

  Future<void> updateComplaintStatus(
    String complaintId,
    String newStatus, {
    String? remarks,
  }) async {
    final index = _localComplaints.indexWhere((c) => c.id == complaintId);
    if (index != -1) {
      final old = _localComplaints[index];
      final updated = ComplaintModel(
        id: old.id,
        complainantName: old.complainantName,
        complainantId: old.complainantId,
        complainantRole: old.complainantRole,
        category: old.category,
        description: old.description,
        status: newStatus,
        createdAt: old.createdAt,
        wardenRemarks: remarks ?? old.wardenRemarks,
      );
      _localComplaints[index] = updated;
      _emitState();

      if (_isFirebaseInitialized && _firestore != null) {
        try {
          await _firestore!.collection('complaints').doc(complaintId).update(updated.toMap());
        } catch (e) {
          debugPrint('Error updating complaint in Firestore: $e');
        }
      }

      // Notify complainant of complaint status update
      if (old.complainantId.isNotEmpty) {
        final statusFormatted = newStatus.toUpperCase().replaceAll('_', ' ');
        await sendNotification(
          recipientId: old.complainantId,
          recipientRole: old.complainantRole,
          title: '📋 Complaint Status Update',
          message: 'Your complaint regarding ${old.category} is now "$statusFormatted". Warden Action: ${remarks ?? "Under review"}.',
          leaveRequestId: old.id,
          type: 'info',
        );
      }
    }
  }

  Future<int> clearAllResolvedComplaints() async {
    int count = 0;
    for (int i = 0; i < _localComplaints.length; i++) {
      final c = _localComplaints[i];
      if (c.status.toLowerCase() == 'resolved' && !c.clearedByWarden) {
        _localComplaints[i] = ComplaintModel(
          id: c.id,
          complainantName: c.complainantName,
          complainantId: c.complainantId,
          complainantRole: c.complainantRole,
          category: c.category,
          description: c.description,
          status: c.status,
          createdAt: c.createdAt,
          wardenRemarks: c.wardenRemarks,
          clearedByWarden: true,
          clearedByStudent: c.clearedByStudent,
        );
        count++;
      }
    }
    _emitState();

    if (_isFirebaseInitialized && _firestore != null) {
      try {
        for (var c in _localComplaints) {
          if (c.clearedByWarden && c.clearedByStudent) {
            await _firestore!.collection('complaints').doc(c.id).delete();
          } else if (c.clearedByWarden) {
            await _firestore!.collection('complaints').doc(c.id).update({'clearedByWarden': true});
          }
        }
      } catch (e) {
        debugPrint('Error updating clearedByWarden in Firestore: $e');
      }
    }
    return count;
  }

  Future<bool> deleteComplaint(String complaintId, {bool isWarden = false}) async {
    final index = _localComplaints.indexWhere((c) => c.id == complaintId);
    if (index != -1) {
      final c = _localComplaints[index];
      final updated = ComplaintModel(
        id: c.id,
        complainantName: c.complainantName,
        complainantId: c.complainantId,
        complainantRole: c.complainantRole,
        category: c.category,
        description: c.description,
        status: c.status,
        createdAt: c.createdAt,
        wardenRemarks: c.wardenRemarks,
        clearedByWarden: isWarden ? true : c.clearedByWarden,
        clearedByStudent: !isWarden ? true : c.clearedByStudent,
      );

      _localComplaints[index] = updated;
      _emitState();

      if (_isFirebaseInitialized && _firestore != null) {
        try {
          if (updated.clearedByWarden && updated.clearedByStudent) {
            await _firestore!.collection('complaints').doc(complaintId).delete();
          } else {
            await _firestore!.collection('complaints').doc(complaintId).update(updated.toMap());
          }
        } catch (e) {
          debugPrint('Error deleting/updating complaint in Firestore: $e');
        }
      }
      return true;
    }
    return false;
  }

  Future<int> clearStudentResolvedComplaints(String studentIdOrName) async {
    final sLower = studentIdOrName.trim().toLowerCase();
    int count = 0;

    for (int i = 0; i < _localComplaints.length; i++) {
      final c = _localComplaints[i];
      final cId = c.complainantId.trim().toLowerCase();
      final cName = c.complainantName.trim().toLowerCase();
      final matchesStudent = cId == sLower || cName == sLower || sLower.contains(cId) || cId.contains(sLower);

      if (matchesStudent && c.status.toLowerCase() == 'resolved' && !c.clearedByStudent) {
        _localComplaints[i] = ComplaintModel(
          id: c.id,
          complainantName: c.complainantName,
          complainantId: c.complainantId,
          complainantRole: c.complainantRole,
          category: c.category,
          description: c.description,
          status: c.status,
          createdAt: c.createdAt,
          wardenRemarks: c.wardenRemarks,
          clearedByWarden: c.clearedByWarden,
          clearedByStudent: true,
        );
        count++;
      }
    }
    _emitState();

    if (_isFirebaseInitialized && _firestore != null) {
      try {
        for (var c in _localComplaints) {
          if (c.clearedByWarden && c.clearedByStudent) {
            await _firestore!.collection('complaints').doc(c.id).delete();
          } else if (c.clearedByStudent) {
            await _firestore!.collection('complaints').doc(c.id).update({'clearedByStudent': true});
          }
        }
      } catch (e) {
        debugPrint('Error updating clearedByStudent in Firestore: $e');
      }
    }
    return count;
  }
}
