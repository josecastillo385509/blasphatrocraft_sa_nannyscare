import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../tutor/tutor_home.dart';
import '../cuidador/cuidador_home.dart';
import '../admin/admin_home.dart';
import '../supervisor/supervisor_home.dart';

/// Decide qué pantalla principal mostrar dependiendo del rol del usuario logueado.
class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    if (user == null) return const LoginScreen();

    switch (user.role) {
      case UserRole.tutor:
        return const TutorHome();
      case UserRole.cuidador:
        return const CuidadorHome();
      case UserRole.administrador:
        return const AdminHome();
      case UserRole.supervisor:
        return const SupervisorHome();
    }
  }
}
