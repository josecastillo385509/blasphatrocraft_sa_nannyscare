import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cita.dart';
import '../../models/notificacion.dart';
import '../../models/perfil_cuidador.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class SupervisorHome extends StatefulWidget {
  const SupervisorHome({super.key});

  @override
  State<SupervisorHome> createState() => _SupervisorHomeState();
}

class _SupervisorHomeState extends State<SupervisorHome>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Cita> _citas = [];
  List<Notificacion> _notifs = [];
  List<PerfilCuidador> _cuidadores = [];
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final storage = context.read<StorageService>();
    final c = await storage.getCitas();
    final n = await storage.getNotificaciones();
    final p = await storage.getPerfilesCuidador();
    final u = await storage.getUsers();
    c.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
    n.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() {
      _citas = c;
      _notifs = n;
      _cuidadores = p;
      _users = u;
      _loading = false;
    });
  }

  String _nombreUsuario(String id) => _users
      .firstWhere(
        (u) => u.id == id,
        orElse: () => AppUser(
          id: id,
          email: '',
          password: '',
          name: '(desconocido)',
          role: UserRole.cuidador,
          createdAt: DateTime.now(),
        ),
      )
      .name;

  String? _fotoUsuario(String id) {
    for (final u in _users) {
      if (u.id == id) return u.photoUrl;
    }
    return null;
  }

  Future<void> _toggleVerificado(PerfilCuidador p, bool value) async {
    await context.read<StorageService>().setVerificadoCuidador(p.userId, value);
    await _load();
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
    final user = context.watch<AuthService>().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Supervisor'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Monitor'),
            Tab(icon: Icon(Icons.event_note), text: 'Citas'),
            Tab(icon: Icon(Icons.verified_user), text: 'Verificación'),
            Tab(icon: Icon(Icons.email), text: 'Comunicación'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.supervisor_account,
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildMonitor(),
                _buildCitas(),
                _buildVerificacion(),
                _buildComunicacion(),
              ],
            ),
    );
  }

  Widget _buildMonitor() {
    final hoy = DateTime.now();
    final esHoy = (DateTime d) =>
        d.year == hoy.year && d.month == hoy.month && d.day == hoy.day;
    final citasHoy = _citas.where((c) => esHoy(c.fechaInicio)).length;
    final pendientes =
        _citas.where((c) => c.estado == EstadoCita.pendiente).length;
    final activas =
        _citas.where((c) => c.estado == EstadoCita.aceptada).length;
    final completadas =
        _citas.where((c) => c.estado == EstadoCita.completada).length;
    final rechazadas =
        _citas.where((c) => c.estado == EstadoCita.rechazada).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights, color: Colors.white, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Operatividad del día',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$citasHoy citas programadas hoy',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            children: [
              _stat('Pendientes', pendientes, Icons.hourglass_top,
                  Colors.orange),
              _stat('Activas', activas, Icons.check_circle_outline,
                  AppColors.primary),
              _stat('Completadas', completadas, Icons.verified,
                  Colors.green),
              _stat('Rechazadas', rechazadas, Icons.cancel,
                  Colors.redAccent),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.shield_moon, color: AppColors.secondary),
                      SizedBox(width: 8),
                      Text(
                        'Funciones del Supervisor',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.secondary, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'Velar por la operatividad del negocio')),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.secondary, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'Asegurar el correcto flujo de comunicación entre Tutor y Cuidador')),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.secondary, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'Monitorear el ciclo de vida de citas y servicios')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Text('$value',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildCitas() {
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
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _colorEstado(c.estado).withValues(alpha: 0.15),
                child:
                    Icon(Icons.event, color: _colorEstado(c.estado)),
              ),
              title: Text('${c.tutorNombre} → ${c.cuidadorNombre}'),
              subtitle: Text(
                DateFormat('dd MMM yyyy, HH:mm', 'es_MX')
                    .format(c.fechaInicio),
              ),
              trailing: Chip(
                label: Text(c.estado.name,
                    style: const TextStyle(fontSize: 10)),
                backgroundColor:
                    _colorEstado(c.estado).withValues(alpha: 0.15),
              ),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                _kv('Inicio',
                    DateFormat('dd/MM/yyyy HH:mm').format(c.fechaInicio)),
                _kv('Fin',
                    DateFormat('dd/MM/yyyy HH:mm').format(c.fechaFin)),
                _kv('Duración',
                    '${c.duracion.inHours}h ${c.duracion.inMinutes % 60}min'),
                _kv('Dirección', c.direccion),
                _kv('Total',
                    '\$${c.totalEstimado.toStringAsFixed(0)} MXN'),
                if (c.notas.isNotEmpty)
                  _kv('Notas del tutor', c.notas),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(k,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildVerificacion() {
    if (_cuidadores.isEmpty) {
      return const Center(child: Text('No hay cuidadores registrados'));
    }
    final verificados = _cuidadores.where((c) => c.verificado).length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: AppColors.info.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: AppColors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Verificación de antecedentes\n'
                      '$verificados de ${_cuidadores.length} cuidadores verificados',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          ..._cuidadores.map((p) {
            final nombre = _nombreUsuario(p.userId);
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: SwitchListTile(
                secondary: UserAvatar(
                  name: nombre,
                  photoUrl: _fotoUsuario(p.userId),
                  radius: 22,
                ),
                title: Row(
                  children: [
                    Flexible(child: Text(nombre)),
                    if (p.verificado) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified,
                          color: AppColors.info, size: 16),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${p.nivelExperiencia.label}\n${p.ubicacion.isEmpty ? 'Sin ubicación' : p.ubicacion}',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
                value: p.verificado,
                activeThumbColor: AppColors.info,
                onChanged: (v) => _toggleVerificado(p, v),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildComunicacion() {
    if (_notifs.isEmpty) {
      return const Center(
          child: Text('No hay comunicaciones registradas'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _notifs.length,
        itemBuilder: (context, i) {
          final n = _notifs[i];
          return Card(
            margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.email, color: Colors.white, size: 18),
              ),
              title: Text(n.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.mensaje, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    'Para usuario: ${n.usuarioId} • '
                    '${DateFormat('dd/MM HH:mm').format(n.createdAt)}',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: n.leida
                  ? const Icon(Icons.done_all,
                      color: Colors.green, size: 18)
                  : const Icon(Icons.mark_email_unread,
                      color: Colors.orange, size: 18),
            ),
          );
        },
      ),
    );
  }
}
