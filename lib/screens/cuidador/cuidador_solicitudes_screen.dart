import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../models/cita.dart';
import '../../models/resena.dart';
import '../../services/auth_service.dart';
import '../../services/cita_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

/// RF07: el cuidador recibe solicitudes. RF12: las acepta o rechaza.
class CuidadorSolicitudesScreen extends StatefulWidget {
  const CuidadorSolicitudesScreen({super.key});

  @override
  State<CuidadorSolicitudesScreen> createState() =>
      _CuidadorSolicitudesScreenState();
}

class _CuidadorSolicitudesScreenState extends State<CuidadorSolicitudesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser!;
    final citaService = context.watch<CitaService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Nuevas'),
            Tab(text: 'Aceptadas'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: FutureBuilder<List<Cita>>(
        future: citaService.getCitasParaCuidador(user.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final pendientes =
              all.where((c) => c.estado == EstadoCita.pendiente).toList();
          final aceptadas =
              all.where((c) => c.estado == EstadoCita.aceptada).toList();
          final historial = all
              .where((c) =>
                  c.estado == EstadoCita.completada ||
                  c.estado == EstadoCita.rechazada ||
                  c.estado == EstadoCita.cancelada)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _CitasList(citas: pendientes, mostrarAcciones: true),
              _CitasList(citas: aceptadas, mostrarCompletar: true),
              _CitasList(citas: historial, esHistorial: true),
            ],
          );
        },
      ),
    );
  }
}

class _CitasList extends StatelessWidget {
  final List<Cita> citas;
  final bool mostrarAcciones;
  final bool mostrarCompletar;
  final bool esHistorial;
  const _CitasList({
    required this.citas,
    this.mostrarAcciones = false,
    this.mostrarCompletar = false,
    this.esHistorial = false,
  });

  @override
  Widget build(BuildContext context) {
    if (citas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Sin solicitudes en esta sección',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: citas.length,
      itemBuilder: (_, i) => _SolicitudCard(
        cita: citas[i],
        mostrarAcciones: mostrarAcciones,
        mostrarCompletar: mostrarCompletar,
        esHistorial: esHistorial,
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final Cita cita;
  final bool mostrarAcciones;
  final bool mostrarCompletar;
  final bool esHistorial;
  const _SolicitudCard({
    required this.cita,
    required this.mostrarAcciones,
    required this.mostrarCompletar,
    required this.esHistorial,
  });

  Future<void> _responder(BuildContext context, bool aceptar) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(aceptar ? 'Aceptar solicitud' : 'Rechazar solicitud'),
        content: Text(
          aceptar
              ? '¿Confirmas que aceptas atender a ${cita.tutorNombre}?'
              : '¿Estás seguro de rechazar esta solicitud?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: aceptar ? AppColors.success : AppColors.error,
            ),
            child: Text(aceptar ? 'Aceptar' : 'Rechazar'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (!context.mounted) return;
    final svc = context.read<CitaService>();
    await svc.responderCita(cita.id, aceptar);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aceptar ? 'Solicitud aceptada' : 'Solicitud rechazada'),
          backgroundColor: aceptar ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _completar(BuildContext context) async {
    final svc = context.read<CitaService>();
    await svc.marcarCompletada(cita.id);
    if (context.mounted) {
      _pedirNotaPrivada(context);
    }
  }

  /// RF15: el cuidador deja una nota privada sobre el tutor
  Future<void> _pedirNotaPrivada(BuildContext context) async {
    double rating = 5.0;
    final notaCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nota privada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Esta calificación y nota son privadas. Solo tú las verás en tus notas personales.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              RatingBar.builder(
                initialRating: rating,
                minRating: 1,
                itemSize: 30,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: AppColors.warning),
                onRatingUpdate: (v) => rating = v,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notaCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Nota privada',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Más tarde'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        );
      }),
    );

    if (ok == true && context.mounted) {
      final storage = context.read<StorageService>();
      final auth = context.read<AuthService>();
      await storage.addResena(Resena(
        id: 'rp-${DateTime.now().millisecondsSinceEpoch}',
        citaId: cita.id,
        autorId: auth.currentUser!.id,
        autorNombre: auth.currentUser!.name,
        destinatarioId: cita.tutorId,
        calificacion: rating,
        comentario: notaCtrl.text.trim(),
        esPrivada: true,
        createdAt: DateTime.now(),
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota privada guardada')),
        );
      }
    }
  }

  Color _colorEstado(EstadoCita e) {
    switch (e) {
      case EstadoCita.pendiente:
        return AppColors.warning;
      case EstadoCita.aceptada:
        return AppColors.success;
      case EstadoCita.rechazada:
      case EstadoCita.cancelada:
        return AppColors.error;
      case EstadoCita.completada:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat("EEE d 'de' MMM • HH:mm", 'es_MX');
    final estadoColor = _colorEstado(cita.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    cita.tutorNombre.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cita.tutorNombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        df.format(cita.fechaInicio),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cita.estado.label,
                    style: TextStyle(
                      color: estadoColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cita.direccion,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${cita.duracion.inHours}h ${cita.duracion.inMinutes % 60}min',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.payments_outlined,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  '\$${cita.totalEstimado.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (cita.notas.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cita.notas,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (mostrarAcciones) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rechazar'),
                      onPressed: () => _responder(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Aceptar'),
                      onPressed: () => _responder(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (mostrarCompletar) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.task_alt, size: 16),
                  label: const Text('Marcar como completada'),
                  onPressed: () => _completar(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
