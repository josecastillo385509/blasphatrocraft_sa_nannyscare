import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/perfil_tutor.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

/// RF05: Perfil del Tutor con información sobre sus hijos y necesidades.
class TutorPerfilScreen extends StatefulWidget {
  const TutorPerfilScreen({super.key});

  @override
  State<TutorPerfilScreen> createState() => _TutorPerfilScreenState();
}

class _TutorPerfilScreenState extends State<TutorPerfilScreen> {
  PerfilTutor? _perfil;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = context.read<AuthService>().currentUser!;
    final data = context.read<DataService>();
    final p = await data.getPerfilTutor(user.id);
    setState(() {
      _perfil = p;
      _loading = false;
    });
  }

  Future<void> _editar() async {
    final user = context.read<AuthService>().currentUser!;
    final data = context.read<DataService>();
    final result = await Navigator.push<PerfilTutor>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditarTutorScreen(perfilExistente: _perfil, userId: user.id),
      ),
    );
    if (result != null) {
      await data.guardarPerfilTutor(result);
      _load();
    }
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      user.email,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Información familiar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Editar'),
                                onPressed: _editar,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_perfil == null)
                            Column(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: AppColors.warning, size: 36),
                                const SizedBox(height: 8),
                                const Text(
                                  'Aún no has configurado tu perfil familiar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _editar,
                                  child: const Text('Configurar perfil'),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Row(
                                    icon: Icons.location_on_outlined,
                                    label: 'Dirección',
                                    value: _perfil!.direccion),
                                const SizedBox(height: 12),
                                Row(
                                  children: const [
                                    Icon(Icons.family_restroom,
                                        size: 18, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text('Hijos',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ..._perfil!.hijos.map(
                                  (h) => Padding(
                                    padding: const EdgeInsets.only(
                                        left: 26, bottom: 6),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.child_care,
                                            size: 16,
                                            color: AppColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${h.nombre} (${h.edad} años)',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        if (h.necesidadesEspeciales != null) ...[
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '• ${h.necesidadesEspeciales}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                if (_perfil!.necesidadesGenerales.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _Row(
                                    icon: Icons.notes,
                                    label: 'Notas adicionales',
                                    value: _perfil!.necesidadesGenerales,
                                  ),
                                ],
                              ],
                            ),
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

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditarTutorScreen extends StatefulWidget {
  final PerfilTutor? perfilExistente;
  final String userId;
  const _EditarTutorScreen({this.perfilExistente, required this.userId});

  @override
  State<_EditarTutorScreen> createState() => _EditarTutorScreenState();
}

class _EditarTutorScreenState extends State<_EditarTutorScreen> {
  late TextEditingController _direccion;
  late TextEditingController _necesidades;
  late List<Hijo> _hijos;

  @override
  void initState() {
    super.initState();
    _direccion =
        TextEditingController(text: widget.perfilExistente?.direccion ?? '');
    _necesidades = TextEditingController(
        text: widget.perfilExistente?.necesidadesGenerales ?? '');
    _hijos = List.from(widget.perfilExistente?.hijos ?? []);
  }

  @override
  void dispose() {
    _direccion.dispose();
    _necesidades.dispose();
    super.dispose();
  }

  void _agregarHijo() {
    showDialog(
      context: context,
      builder: (ctx) {
        final nombreCtrl = TextEditingController();
        final edadCtrl = TextEditingController();
        final necesCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Agregar hijo/a'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: edadCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Edad'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: necesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Necesidades especiales (opcional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final n = nombreCtrl.text.trim();
                final e = int.tryParse(edadCtrl.text) ?? 0;
                if (n.isEmpty) return;
                setState(() {
                  _hijos.add(Hijo(
                    nombre: n,
                    edad: e,
                    necesidadesEspeciales:
                        necesCtrl.text.trim().isEmpty ? null : necesCtrl.text.trim(),
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _guardar() {
    if (_direccion.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una dirección')),
      );
      return;
    }
    final p = PerfilTutor(
      userId: widget.userId,
      direccion: _direccion.text.trim(),
      hijos: _hijos,
      necesidadesGenerales: _necesidades.text.trim(),
    );
    Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [
          TextButton(
            onPressed: _guardar,
            child: const Text(
              'Guardar',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _direccion,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _necesidades,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Necesidades generales o instrucciones',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Hijos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  onPressed: _agregarHijo,
                ),
              ],
            ),
            ..._hijos.asMap().entries.map(
                  (e) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.child_care,
                          color: AppColors.primary),
                      title: Text(e.value.nombre),
                      subtitle: Text(
                        '${e.value.edad} años${e.value.necesidadesEspeciales != null ? ' • ${e.value.necesidadesEspeciales}' : ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        onPressed: () => setState(() => _hijos.removeAt(e.key)),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
