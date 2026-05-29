import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/resena.dart';
import '../../services/data_service.dart';
import '../../services/resena_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'agendar_cita_screen.dart';

class CuidadorDetalleScreen extends StatelessWidget {
  final CuidadorConUsuario cuidador;
  const CuidadorDetalleScreen({super.key, required this.cuidador});

  @override
  Widget build(BuildContext context) {
    final perfil = cuidador.perfil;
    final user = cuidador.usuario;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      UserAvatar(
                        name: user.name,
                        photoUrl: user.photoUrl,
                        radius: 50,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (perfil.verificado) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        perfil.ubicacion,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.star,
                          label:
                              '${perfil.calificacionPromedio.toStringAsFixed(1)} ★',
                          subtitle: '${perfil.totalServicios} servicios',
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.attach_money,
                          label: '\$${perfil.tarifaPorHora.toInt()}/hr',
                          subtitle: 'Tarifa',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.workspace_premium,
                          label: perfil.nivelExperiencia.name,
                          subtitle: 'Nivel',
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('Sobre mí'),
                  Text(
                    perfil.descripcion,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle('Experiencia'),
                  Row(
                    children: [
                      const Icon(Icons.work_outline,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(perfil.nivelExperiencia.name),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle('Certificaciones'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: perfil.certificaciones
                        .map((c) => Chip(
                              label: Text(c),
                              avatar: const Icon(Icons.verified_user,
                                  size: 16, color: AppColors.success),
                              backgroundColor:
                                  AppColors.success.withValues(alpha: 0.1),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle('Capacidades'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: perfil.capacidades
                        .map((c) => Chip(
                              label: Text(c),
                              backgroundColor: AppColors.primaryLight,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle('Disponibilidad'),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(perfil.horarioDisponible),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: perfil.diasDisponibles
                        .map((d) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                d,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle('Reseñas'),
                  _ResenasCuidador(cuidadorId: user.id),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.event_available),
                          label: const Text('Agendar Cita'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AgendarCitaScreen(cuidador: cuidador),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _ResenasCuidador extends StatelessWidget {
  final String cuidadorId;
  const _ResenasCuidador({required this.cuidadorId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Resena>>(
      future: context.read<ResenaService>().getResenasPublicas(cuidadorId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }
        final resenas = snap.data!;
        if (resenas.isEmpty) {
          return const Text(
            'Aún no tiene reseñas',
            style: TextStyle(color: AppColors.textSecondary),
          );
        }
        final df = DateFormat('dd/MM/yyyy', 'es_MX');
        return Column(
          children: resenas.map((r) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < r.calificacion.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.warning,
                            size: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          df.format(r.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.autorNombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (r.comentario.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        r.comentario,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
