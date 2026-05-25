import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cita.dart';
import '../../models/perfil_cuidador.dart';
import '../../models/perfil_tutor.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _idx = 0;

  late final List<Widget> _tabs = const [
    _DashboardTab(),
    _UsuariosTab(),
    _PerfilesTab(),
    _CitasTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings,
                  color: AppColors.primary),
            ),
            onSelected: (v) async {
              if (v == 'logout') {
                await context.read<AuthService>().logout();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(user?.name ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _tabs[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Resumen'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(
              icon: Icon(Icons.badge), label: 'Perfiles'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_note), label: 'Citas'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  int _tutores = 0, _cuidadores = 0, _citas = 0, _pendientes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = context.read<StorageService>();
    final users = await storage.getUsers();
    final citas = await storage.getCitas();
    setState(() {
      _tutores = users.where((u) => u.role == UserRole.tutor).length;
      _cuidadores = users.where((u) => u.role == UserRole.cuidador).length;
      _citas = citas.length;
      _pendientes =
          citas.where((c) => c.estado == EstadoCita.pendiente).length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Resumen del sistema',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            children: [
              _statCard('Tutores', '$_tutores', Icons.family_restroom,
                  AppColors.primary),
              _statCard('Cuidadores', '$_cuidadores', Icons.child_care,
                  AppColors.secondary),
              _statCard(
                  'Citas totales', '$_citas', Icons.event, Colors.green),
              _statCard(
                  'Pendientes', '$_pendientes', Icons.pending, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.shield, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Funciones del Administrador',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                  _RowDot(text: 'Administración de catálogos de usuarios'),
                  _RowDot(text: 'Supervisión de perfiles de Tutores y Cuidadores'),
                  _RowDot(text: 'Consulta del histórico completo de citas'),
                  _RowDot(text: 'Control de altas, bajas y modificaciones'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Text(value,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class _RowDot extends StatelessWidget {
  final String text;
  const _RowDot({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle,
              color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _UsuariosTab extends StatefulWidget {
  const _UsuariosTab();
  @override
  State<_UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<_UsuariosTab> {
  List<AppUser> _users = [];
  bool _loading = true;
  UserRole? _filtroRol;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<StorageService>().getUsers();
    setState(() {
      _users = list;
      _loading = false;
    });
  }

  IconData _iconoRol(UserRole r) {
    switch (r) {
      case UserRole.tutor:
        return Icons.family_restroom;
      case UserRole.cuidador:
        return Icons.child_care;
      case UserRole.administrador:
        return Icons.admin_panel_settings;
      case UserRole.supervisor:
        return Icons.supervisor_account;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final filtrados = _filtroRol == null
        ? _users
        : _users.where((u) => u.role == _filtroRol).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _filtroRol == null,
                  onSelected: (_) => setState(() => _filtroRol = null),
                ),
                const SizedBox(width: 6),
                ...UserRole.values.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      avatar: Icon(_iconoRol(r), size: 16),
                      label: Text(r.name),
                      selected: _filtroRol == r,
                      onSelected: (_) => setState(() => _filtroRol = r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: filtrados.isEmpty
              ? const Center(child: Text('Sin usuarios para mostrar'))
              : ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, i) {
                    final u = filtrados[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          child: Icon(_iconoRol(u.role),
                              color: AppColors.primary),
                        ),
                        title: Text(u.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.email),
                            Text('Rol: ${u.role.name}',
                                style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          DateFormat('dd/MM/yyyy').format(u.createdAt),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PerfilesTab extends StatefulWidget {
  const _PerfilesTab();
  @override
  State<_PerfilesTab> createState() => _PerfilesTabState();
}

class _PerfilesTabState extends State<_PerfilesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<PerfilCuidador> _cuidadores = [];
  List<PerfilTutor> _tutores = [];
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final storage = context.read<StorageService>();
    final c = await storage.getPerfilesCuidador();
    final t = await storage.getPerfilesTutor();
    final u = await storage.getUsers();
    setState(() {
      _cuidadores = c;
      _tutores = t;
      _users = u;
      _loading = false;
    });
  }

  String _nombre(String id) =>
      _users.firstWhere((u) => u.id == id,
          orElse: () => AppUser(
                id: id,
                email: '',
                password: '',
                name: '(desconocido)',
                role: UserRole.tutor,
                createdAt: DateTime.now(),
              )).name;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Material(
          color: AppColors.primary.withValues(alpha: 0.05),
          child: TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            tabs: [
              Tab(text: 'Cuidadores (${_cuidadores.length})'),
              Tab(text: 'Tutores (${_tutores.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _cuidadores.isEmpty
                  ? const Center(child: Text('Sin perfiles de cuidador'))
                  : ListView.builder(
                      itemCount: _cuidadores.length,
                      itemBuilder: (context, i) {
                        final p = _cuidadores[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: const CircleAvatar(
                                child: Icon(Icons.child_care)),
                            title: Text(_nombre(p.userId)),
                            subtitle: Text(
                                '${p.nivelExperiencia.label} • \$${p.tarifaPorHora.toStringAsFixed(0)}/h\n${p.ubicacion}'),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 14),
                                    Text(p.calificacionPromedio
                                        .toStringAsFixed(1)),
                                  ],
                                ),
                                Text('${p.totalServicios} serv.',
                                    style: const TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              _tutores.isEmpty
                  ? const Center(child: Text('Sin perfiles de tutor'))
                  : ListView.builder(
                      itemCount: _tutores.length,
                      itemBuilder: (context, i) {
                        final p = _tutores[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: const CircleAvatar(
                                child: Icon(Icons.family_restroom)),
                            title: Text(_nombre(p.userId)),
                            subtitle: Text(
                                '${p.hijos.length} hijo(s) • ${p.direccion}'),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CitasTab extends StatefulWidget {
  const _CitasTab();
  @override
  State<_CitasTab> createState() => _CitasTabState();
}

class _CitasTabState extends State<_CitasTab> {
  List<Cita> _citas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<StorageService>().getCitas();
    list.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
    setState(() {
      _citas = list;
      _loading = false;
    });
  }

  Color _colorEstado(EstadoCita e) {
    switch (e) {
      case EstadoCita.pendiente:
        return Colors.orange;
      case EstadoCita.aceptada:
        return AppColors.primary;
      case EstadoCita.rechazada:
        return Colors.redAccent;
      case EstadoCita.completada:
        return Colors.green;
      case EstadoCita.cancelada:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_citas.isEmpty) {
      return const Center(child: Text('Sin citas registradas'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _citas.length,
        itemBuilder: (context, i) {
          final c = _citas[i];
          return Card(
            margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _colorEstado(c.estado).withValues(alpha: 0.15),
                child: Icon(Icons.event, color: _colorEstado(c.estado)),
              ),
              title: Text('${c.tutorNombre} ↔ ${c.cuidadorNombre}'),
              subtitle: Text(
                '${DateFormat('dd/MM/yyyy HH:mm', 'es_MX').format(c.fechaInicio)}\n'
                '\$${c.totalEstimado.toStringAsFixed(0)} MXN',
              ),
              isThreeLine: true,
              trailing: Chip(
                label: Text(c.estado.name,
                    style: const TextStyle(fontSize: 10)),
                backgroundColor: _colorEstado(c.estado).withValues(alpha: 0.15),
              ),
            ),
          );
        },
      ),
    );
  }
}
