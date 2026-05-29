import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/notificacion.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/reminder_service.dart';
import '../../theme/app_theme.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<Notificacion> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    // HU9/HU14: regenera recordatorios de citas próximas al abrir/refrescar.
    await context.read<ReminderService>().generarRecordatoriosPendientes();
    if (!mounted) return;
    final svc = context.read<NotificationService>();
    final list = await svc.getNotificacionesUsuario(user.id);
    if (!mounted) return;
    setState(() {
      _notifs = list;
      _loading = false;
    });
  }

  IconData _iconoTipo(TipoNotificacion tipo) {
    switch (tipo) {
      case TipoNotificacion.reserva:
        return Icons.event_available;
      case TipoNotificacion.recordatorio:
        return Icons.alarm;
      case TipoNotificacion.mensaje:
        return Icons.chat_bubble_outline;
      case TipoNotificacion.pago:
        return Icons.payments;
      case TipoNotificacion.general:
        return Icons.notifications;
    }
  }

  Color _colorTipo(TipoNotificacion tipo) {
    switch (tipo) {
      case TipoNotificacion.reserva:
        return AppColors.primary;
      case TipoNotificacion.recordatorio:
        return Colors.orange;
      case TipoNotificacion.mensaje:
        return Colors.blueAccent;
      case TipoNotificacion.pago:
        return Colors.green;
      case TipoNotificacion.general:
        return AppColors.secondary;
    }
  }

  String _formatFecha(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return DateFormat('dd/MM/yyyy HH:mm', 'es_MX').format(d);
  }

  Future<void> _marcarTodasLeidas() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    await context.read<NotificationService>().marcarTodasLeidas(user.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final tieneNoLeidas = _notifs.any((n) => !n.leida);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos y Notificaciones'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (tieneNoLeidas)
            TextButton.icon(
              icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
              label: const Text(
                'Marcar leídas',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: _marcarTodasLeidas,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off,
                          size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No tienes notificaciones',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifs.length,
                    itemBuilder: (context, i) {
                      final n = _notifs[i];
                      final color = _colorTipo(n.tipo);
                      return Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.green,
                          child: const Icon(Icons.done, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          await context
                              .read<NotificationService>()
                              .marcarLeida(n.id);
                          await _load();
                          return false;
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          color: n.leida
                              ? null
                              : color.withValues(alpha: 0.08),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(_iconoTipo(n.tipo), color: color),
                            ),
                            title: Text(
                              n.titulo,
                              style: TextStyle(
                                fontWeight: n.leida
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(n.mensaje),
                                const SizedBox(height: 4),
                                Text(
                                  _formatFecha(n.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: n.leida
                                ? null
                                : Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onTap: () async {
                              if (!n.leida) {
                                await context
                                    .read<NotificationService>()
                                    .marcarLeida(n.id);
                                _load();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
