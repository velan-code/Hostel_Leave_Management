import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_provider.dart';
import '../../services/sound_service.dart';
import '../../models/student_model.dart';

class ComplaintScreen extends ConsumerStatefulWidget {
  const ComplaintScreen({super.key});

  @override
  ConsumerState<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends ConsumerState<ComplaintScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _descriptionController;

  String _selectedCategory = 'Food';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'label': 'Food Quality 🍲', 'icon': Icons.restaurant_rounded},
    {'name': 'Water Facility', 'label': 'Water Facility 🚰', 'icon': Icons.water_drop_rounded},
    {'name': 'Room', 'label': 'Room Maintenance 🛏️', 'icon': Icons.bed_rounded},
    {'name': 'Abnormal Smell', 'label': 'Abnormal Smell ⚠️', 'icon': Icons.warning_amber_rounded},
    {'name': 'Other', 'label': 'Other Issues 🔧', 'icon': Icons.build_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(currentUserProvider);
    final students = FirebaseService().currentStudents;
    final matchedStudent = students.firstWhere(
      (s) =>
          (currentUser != null && s.email.toLowerCase() == currentUser.email.toLowerCase()) ||
          (currentUser != null && s.id.toLowerCase() == currentUser.id.toLowerCase()) ||
          (currentUser != null && s.rollNo.toLowerCase() == currentUser.id.toLowerCase()),
      orElse: () => StudentModel(
        docId: '',
        id: currentUser?.id ?? '',
        name: currentUser?.name ?? '',
        email: currentUser?.email ?? '',
      ),
    );

    final initialName = matchedStudent.name.isNotEmpty
        ? matchedStudent.name
        : (currentUser?.name.isNotEmpty == true ? currentUser!.name : '');

    final initialId = matchedStudent.rollNo.isNotEmpty
        ? matchedStudent.rollNo
        : (currentUser?.erpNo.isNotEmpty == true
            ? currentUser!.erpNo
            : (currentUser?.id.isNotEmpty == true ? currentUser!.id : ''));

    _nameController = TextEditingController(text: initialName);
    _idController = TextEditingController(text: initialId);
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      final students = FirebaseService().currentStudents;
      final matchedStudent = students.firstWhere(
        (s) =>
            (currentUser != null && s.email.toLowerCase() == currentUser.email.toLowerCase()) ||
            (currentUser != null && s.id.toLowerCase() == currentUser.id.toLowerCase()) ||
            (currentUser != null && s.rollNo.toLowerCase() == currentUser.id.toLowerCase()),
        orElse: () => StudentModel(docId: '', id: '', name: '', email: '', assignedWardenId: 'siva_sir', assignedWardenName: 'Siva Sir'),
      );

      final complainantName = _nameController.text.trim();
      final complainantId = _idController.text.trim();
      final complainantRole = currentUser?.role ?? 'Member / Student';

      await FirebaseService().submitComplaint(
        complainantName: complainantName.isNotEmpty ? complainantName : 'Hostel Resident',
        complainantId: complainantId.isNotEmpty ? complainantId : 'Anonymous',
        complainantRole: complainantRole,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        assignedWardenId: matchedStudent.assignedWardenId.isNotEmpty ? matchedStudent.assignedWardenId : 'siva_sir',
        assignedWardenName: matchedStudent.assignedWardenName.isNotEmpty ? matchedStudent.assignedWardenName : 'Siva Sir',
      );

      SoundService().playSuccess();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Complaint submitted! The Hostel Warden will review your issue.',
                    style: GoogleFonts.dmSans(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit complaint: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B26),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1C42),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Hostel Complaint Portal',
          style: GoogleFonts.outfit(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF060B26),
              Color(0xFF0B1536),
              Color(0xFF0F1B40),
              Color(0xFF060B26),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warden Review Notice Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2A748).withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2A748).withAlpha(160),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE2A748).withAlpha(20),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2A748).withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: Color(0xFFE2A748),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DIRECT WARDEN REVIEW',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFE2A748),
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your submitted complaint will be reviewed & resolved directly by the Hostel Warden.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 8.5.sp,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Who is Complaining Section
                  Text(
                    'Complainant Information',
                    style: GoogleFonts.outfit(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 1.2.h),

                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.dmSans(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Your Full Name / Member Name',
                      labelStyle: GoogleFonts.dmSans(color: Colors.white60),
                      prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFFE2A748)),
                      filled: true,
                      fillColor: const Color(0xFF0F1C42).withAlpha(200),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withAlpha(30)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2A748)),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                  ),

                  SizedBox(height: 1.5.h),

                  TextFormField(
                    controller: _idController,
                    style: GoogleFonts.dmSans(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'ERP No / Roll No / Email / Contact',
                      labelStyle: GoogleFonts.dmSans(color: Colors.white60),
                      prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFFE2A748)),
                      filled: true,
                      fillColor: const Color(0xFF0F1C42).withAlpha(200),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withAlpha(30)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2A748)),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter ERP No / Email' : null,
                  ),

                  SizedBox(height: 3.h),

                  // Category Selection
                  Text(
                    'Select Complaint Category',
                    style: GoogleFonts.outfit(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 1.2.h),

                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['name'];
                      return ChoiceChip(
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat['name']);
                          }
                        },
                        avatar: Icon(
                          cat['icon'] as IconData,
                          size: 16,
                          color: isSelected ? const Color(0xFF0F2440) : const Color(0xFFE2A748),
                        ),
                        label: Text(
                          cat['label'] as String,
                          style: GoogleFonts.dmSans(
                            fontSize: 9.5.sp,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? const Color(0xFF0F2440) : Colors.white,
                          ),
                        ),
                        selectedColor: const Color(0xFFE2A748),
                        backgroundColor: const Color(0xFF0F1C42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFE2A748)
                                : Colors.white.withAlpha(40),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 3.h),

                  // Complaint Description Box
                  Text(
                    'Complaint Description',
                    style: GoogleFonts.outfit(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 1.2.h),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    style: GoogleFonts.dmSans(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Provide detailed information about the issue (e.g. food quality, water timing, room number, or abnormal smell)...',
                      hintStyle: GoogleFonts.dmSans(color: Colors.white38, fontSize: 10.sp),
                      filled: true,
                      fillColor: const Color(0xFF0F1C42).withAlpha(200),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withAlpha(30)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2A748)),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please describe your complaint' : null,
                  ),

                  SizedBox(height: 4.h),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2A748),
                        foregroundColor: const Color(0xFF0F2440),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFF0F2440),
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send_rounded, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Submit Complaint to Warden',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
