import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/perfil_cuidador.dart';
import '../../models/resena.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class CuidadorPerfilScreen extends StatefulWidget {
  const CuidadorPerfilScreen({super.key});

  @override
  State<CuidadorPerfilScreen> createState() => _CuidadorPerfilScreenState();
}

class _CuidadorPerfilScreenState extends State<CuidadorPerfilScreen> {
  PerfilCuidador? _perfil;
  List<Resena> _notasPrivadas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    final data = context.read<DataService>();
    final storage = context.read<StorageService>();
    final perfil = await data.getPerfilCuidador(user.id);
    final todasResenas = await storage.getResenas();
    final notas = todasResenas
        .where((r) => r.esPrivada && r.autorId == user.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() {
      _perfil = perfil;
      _notasPrivadas = notas;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Editar perfil',
            icon: const Icon(Icons.edit),
            onPressed: _perfil == null
                ? null
                : () async {
                    final actualizado = await Navigator.push<PerfilCuidador>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            _EditarPerfilCuidadorScreen(perfil: _perfil!),
                      ),
                    );
                    if (actualizado != null) {
                      await context
                          .read<DataService>()
                          .guardarPerfilCuidador(actualizado);
                      _load();
                    }
                  },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: Text(
                          (user?.name ?? '?').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 36,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (_perfil != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Nivel: ${_perfil!.nivelExperiencia.label}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_perfil != null) ...[
                  _seccion(
                    icon: Icons.description,
                    titulo: 'Descripción',
                    contenido: Text(_perfil!.descripcion),
                  ),
                  _seccion(
                    icon: Icons.attach_money,
                    titulo: 'Tarifa por hora',
                    contenido:
                        Text('\$${_perfil!.tarifaPorHora.toStringAsFixed(0)} MXN'),
                  ),
                  _seccion(
                    icon: Icons.location_on,
                    titulo: 'Ubicación',
                    contenido: Text(_perfil!.ubicacion),
                  ),
                  _seccion(
                    icon: Icons.access_time,
                    titulo: 'Disponibilidad',
                    contenido: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Horario: ${_perfil!.horarioDisponible}'),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _perfil!.diasDisponibles
                              .map((d) => Chip(
                                    label: Text(d,
                                        style: const TextStyle(fontSize: 11)),
                                    backgroundColor: AppColors.secondary
                                        .withValues(alpha: 0.15),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  _seccion(
                    icon: Icons.verified,
                    titulo: 'Certificaciones',
                    contenido: _perfil!.certificaciones.isEmpty
                        ? const Text('— Sin certificaciones registradas')
                        : Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _perfil!.certificaciones
                                .map((c) => Chip(
                                      avatar: const Icon(Icons.check_circle,
                                          size: 14, color: AppColors.primary),
                                      label: Text(c,
                                          style: const TextStyle(fontSize: 11)),
                                    ))
                                .toList(),
                          ),
                  ),
                  _seccion(
                    icon: Icons.star,
                    titulo: 'Capacidades',
                    contenido: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _perfil!.capacidades
                          .map((c) => Chip(
                                label: Text(c,
                                    style: const TextStyle(fontSize: 11)),
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                              ))
                          .toList(),
                    ),
                  ),
                  _seccion(
                    icon: Icons.analytics,
                    titulo: 'Estadísticas',
                    contenido: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${_perfil!.calificacionPromedio.toStringAsFixed(1)} / 5.0',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                            'Servicios completados: ${_perfil!.totalServicios}'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _seccionNotasPrivadas(),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await context.read<AuthService>().logout();
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _seccion({
    required IconData icon,
    required String titulo,
    required Widget contenido,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            contenido,
          ],
        ),
      ),
    );
  }

  Widget _seccionNotasPrivadas() {
    return Card(
      color: AppColors.secondary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.lock, color: AppColors.secondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Mis Notas Privadas sobre Tutores',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Solo tú puedes ver estas notas (RF15)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            if (_notasPrivadas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Aún no has registrado notas privadas.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._notasPrivadas.map(
                (n) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < n.calificacion.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('dd/MM/yyyy').format(n.createdAt),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n.comentario),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditarPerfilCuidadorScreen extends StatefulWidget {
  final PerfilCuidador perfil;
  const _EditarPerfilCuidadorScreen({required this.perfil});

  @override
  State<_EditarPerfilCuidadorScreen> createState() =>
      _EditarPerfilCuidadorScreenState();
}

class _EditarPerfilCuidadorScreenState
    extends State<_EditarPerfilCuidadorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descripcionCtrl;
  late TextEditingController _ubicacionCtrl;
  late TextEditingController _horarioCtrl;
  late TextEditingController _tarifaCtrl;
  late TextEditingController _certCtrl;
  late TextEditingController _capCtrl;
  late NivelExperiencia _nivel;
  late List<String> _certificaciones;
  late List<String> _capacidades;
  late List<String> _diasDisponibles;

  static const _todosLosDias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.perfil;
    _descripcionCtrl = TextEditingController(text: p.descripcion);
    _ubicacionCtrl = TextEditingController(text: p.ubicacion);
    _horarioCtrl = TextEditingController(text: p.horarioDisponible);
    _tarifaCtrl =
        TextEditingController(text: p.tarifaPorHora.toStringAsFixed(0));
    _certCtrl = TextEditingController();
    _capCtrl = TextEditingController();
    _nivel = p.nivelExperiencia;
    _certificaciones = List.of(p.certificaciones);
    _capacidades = List.of(p.capacidades);
    _diasDisponibles = List.of(p.diasDisponibles);
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _ubicacionCtrl.dispose();
    _horarioCtrl.dispose();
    _tarifaCtrl.dispose();
    _certCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final actualizado = PerfilCuidador(
      userId: widget.perfil.userId,
      descripcion: _descripcionCtrl.text.trim(),
      nivelExperiencia: _nivel,
      certificaciones: _certificaciones,
      capacidades: _capacidades,
      tarifaPorHora:
          double.tryParse(_tarifaCtrl.text) ?? widget.perfil.tarifaPorHora,
      ubicacion: _ubicacionCtrl.text.trim(),
      diasDisponibles: _diasDisponibles,
      horarioDisponible: _horarioCtrl.text.trim(),
      calificacionPromedio: widget.perfil.calificacionPromedio,
      totalServicios: widget.perfil.totalServicios,
      verificado: widget.perfil.verificado,
    );
    Navigator.pop(context, actualizado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          TextButton(
            onPressed: _guardar,
            child: const Text('Guardar',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<NivelExperiencia>(
              initialValue: _nivel,
              decoration: const InputDecoration(
                labelText: 'Nivel de experiencia',
                prefixIcon: Icon(Icons.workspace_premium),
              ),
              items: NivelExperiencia.values
                  .map((n) => DropdownMenuItem(
                        value: n,
                        child: Text(
                            '${n.label} — sugerido \$${n.tarifaSugeridaPorHora.toStringAsFixed(0)}/h'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _nivel = v;
                    _tarifaCtrl.text = v.tarifaSugeridaPorHora.toStringAsFixed(0);
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tarifaCtrl,
              decoration: const InputDecoration(
                labelText: 'Tarifa por hora (MXN)',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ubicacionCtrl,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _horarioCtrl,
              decoration: const InputDecoration(
                labelText: 'Horario disponible (ej: 08:00 - 18:00)',
                prefixIcon: Icon(Icons.schedule),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 20),
            const Text('Días disponibles',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 6,
              children: _todosLosDias.map((d) {
                final activo = _diasDisponibles.contains(d);
                return FilterChip(
                  label: Text(d),
                  selected: activo,
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _diasDisponibles.add(d);
                      } else {
                        _diasDisponibles.remove(d);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Certificaciones',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 6,
              children: _certificaciones
                  .map((c) => Chip(
                        label: Text(c),
                        onDeleted: () =>
                            setState(() => _certificaciones.remove(c)),
                      ))
                  .toList(),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _certCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Agregar certificación'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () {
                    final t = _certCtrl.text.trim();
                    if (t.isNotEmpty) {
                      setState(() {
                        _certificaciones.add(t);
                        _certCtrl.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Capacidades',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 6,
              children: _capacidades
                  .map((c) => Chip(
                        label: Text(c),
                        onDeleted: () =>
                            setState(() => _capacidades.remove(c)),
                      ))
                  .toList(),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _capCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Agregar capacidad (ej: RCP)'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () {
                    final t = _capCtrl.text.trim();
                    if (t.isNotEmpty) {
                      setState(() {
                        _capacidades.add(t);
                        _capCtrl.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
