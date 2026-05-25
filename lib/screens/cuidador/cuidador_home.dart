import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../cuidador/cuidador_solicitudes_screen.dart';
import '../cuidador/cuidador_calendario_screen.dart';
import '../cuidador/cuidador_perfil_screen.dart';
import '../cuidador/cuidador_reglamento_screen.dart';
import '../common/notificaciones_screen.dart';

class CuidadorHome extends StatefulWidget {
  const CuidadorHome({super.key});

  @override
  State<CuidadorHome> createState() => _CuidadorHomeState();
}

class _CuidadorHomeState extends State<CuidadorHome> {
  int _index = 0;

  final _screens = const [
    CuidadorSolicitudesScreen(),
    CuidadorCalendarioScreen(),
    NotificacionesScreen(),
    CuidadorReglamentoScreen(),
    CuidadorPerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Avisos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Reglamento',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
