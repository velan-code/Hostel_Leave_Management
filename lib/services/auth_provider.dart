import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

/// Riverpod provider for managing selected role in login/role screens
final selectedRoleProvider = StateProvider<String>((ref) => 'student');

/// Riverpod provider for managing current authenticated user
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

/// Riverpod provider for auth loading state
final authLoadingProvider = StateProvider<bool>((ref) => false);
