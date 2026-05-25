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

class TutorCitasScreen extends StatefulWidget {
  const TutorCitasScreen({super.key});

  @override
  State<TutorCitasScreen> createState() => _TutorCitasScreenState();
}

class _TutorCitasScreenState extends State<TutorCitasScreen>
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
        title: const Text('Mis Citas'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Confirmadas'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: FutureBuilder<List<Cita>>(
        future: citaService.getCitasDelTutor(user.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final pendientes =
              all.where((c) => c.estado == EstadoCita.pendiente).toList();
          final confirmadas =
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
              _CitasList(citas: pendientes, esTutor: true),
              _CitasList(citas: confirmadas, esTutor: true),
              _CitasList(citas: historial, esTutor: true, esHistorial: true),
            ],
          );
        },
      ),
    );
  }
}

class _CitasList extends StatelessWidget {
  final List<Cita> citas;
  final bool esTutor;
  final bool esHistorial;
  const _CitasList({
    required this.citas,
    this.esTutor = false,
    this.esHistorial = false,
  });

  @override
  Widget build(BuildContext context) {
    if (citas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'No hay citas en esta sección',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: citas.length,
      itemBuilder: (_, i) => _CitaCard(
        cita: citas[i],
        esTutor: esTutor,
        esHistorial: esHistorial,
      ),
    );
  }
}

class _CitaCard extends StatelessWidget {
  final Cita cita;
  final bool esTutor;
  final bool esHistorial;
  const _CitaCard({
    required this.cita,
    required this.esTutor,
    required this.esHistorial,
  });

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

  Future<void> _calificar(BuildContext context) async {
    double rating = 5.0;
    final comentarioCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Calificar a ${cita.cuidadorNombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: rating,
                minRating: 1,
                itemSize: 36,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: AppColors.warning),
                onRatingUpdate: (v) => rating = v,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: comentarioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentario',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar'),
            ),
          ],
        );
      }),
    );

    if (ok == true) {
      final storage = context.read<StorageService>();
      final auth = context.read<AuthService>();
      final resena = Resena(
        id: 'r-${DateTime.now().millisecondsSinceEpoch}',
        citaId: cita.id,
        autorId: auth.currentUser!.id,
        autorNombre: auth.currentUser!.name,
        destinatarioId: cita.cuidadorId,
        calificacion: rating,
        comentario: comentarioCtrl.text.trim(),
        esPrivada: false, // RF14: pública
        createdAt: DateTime.now(),
      );
      await storage.addResena(resena);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Gracias por tu reseña!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat("EEE d 'de' MMM • HH:mm", 'es_MX');
    final estadoColor = _colorEstado(cita.estado);
    final otraPersona = esTutor ? cita.cuidadorNombre : cita.tutorNombre;

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
                    otraPersona.substring(0, 1).toUpperCase(),
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
                        otraPersona,
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
            _Info(icon: Icons.location_on_outlined, text: cita.direccion),
            const SizedBox(height: 6),
            _Info(
              icon: Icons.schedule,
              text:
                  '${cita.duracion.inHours}h ${cita.duracion.inMinutes % 60}min',
            ),
            const SizedBox(height: 6),
            _Info(
              icon: Icons.payments_outlined,
              text: '\$${cita.totalEstimado.toStringAsFixed(2)} MXN',
            ),
            if (cita.notas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cita.notas,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
            if (esHistorial &&
                esTutor &&
                cita.estado == EstadoCita.completada) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.star_outline, size: 18),
                label: const Text('Calificar'),
                onPressed: () => _calificar(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Info({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
