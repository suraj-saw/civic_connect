import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../data/repositories/auth_reporsitory.dart';

class AuthMiddleware extends GetMiddleware {
  final AuthRepository authRepository;

  AuthMiddleware({required this.authRepository});

  @override
  int? get priority => 9;

  @override
  RouteSettings? redirect(String? route) {
    final isAuthenticated = authRepository.isUserLoggedIn();

    if (!isAuthenticated && route != '/login' && route != '/signup') {
      return const RouteSettings(name: '/login');
    }

    if (isAuthenticated && (route == '/login' || route == '/signup')) {
      return const RouteSettings(name: '/home-citizen');
    }

    return null;
  }
}

class RoleBasedMiddleware extends GetMiddleware {
  final AuthRepository authRepository;

  RoleBasedMiddleware({required this.authRepository});

  @override
  int? get priority => 8;

  @override
  RouteSettings? redirect(String? route) {
    final userRole = authRepository.getCurrentUserRole();

    if (route == '/categories' && userRole != 'admin') {
      return const RouteSettings(name: '/home-citizen');
    }

    return null;
  }
}