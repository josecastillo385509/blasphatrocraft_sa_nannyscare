import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/cita_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';

/// RF10: agendar cita con un cuidador.
class AgendarCitaScreen extends StatefulWidget {
  final CuidadorConUsuario cuidador;
  const AgendarCitaScreen({super.key, required this.cuidador});

  @override
  State<AgendarCitaScreen> createState() => _AgendarCitaScreenState();
}

class _AgendarCitaScreenState extends State<AgendarCitaScreen> {
  final _direccionController = TextEditingController();
  final _notasController = TextEditingController();

  DateTime _fecha = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _horaInicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 13, minute: 0);

  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    // Prellenar con dirección del tutor si existe
    _cargarDireccion();
  }

  Future<void> _cargarDireccion() async {
    final auth = context.read<AuthService>();
    final data = context.read<DataService>();
    final user = auth.currentUser;
    if (user == null) return;
    final perfil = await data.getPerfilTutor(user.id);
    if (perfil != null && mounted) {
      _direccionController.text = perfil.direccion;
    }
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  double get _totalEstimado {
    final inicio = DateTime(_fecha.year, _fecha.month, _fecha.day,
        _horaInicio.hour, _horaInicio.minute);
    final fin = DateTime(_fecha.year, _fecha.month, _fecha.day, _horaFin.hour,
        _horaFin.minute);
    final horas = fin.difference(inicio).inMinutes / 60.0;
    return horas * widget.cuidador.perfil.tarifaPorHora;
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      locale: const Locale('es', 'MX'),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _seleccionarHoraInicio() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaInicio,
    );
    if (picked != null) setState(() => _horaInicio = picked);
  }

  Future<void> _seleccionarHoraFin() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaFin,
    );
    if (picked != null) setState(() => _horaFin = picked);
  }

  Future<void> _agendar() async {
    if (_direccionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una dirección')),
      );
      return;
    }

    final inicio = DateTime(_fecha.year, _fecha.month, _fecha.day,
        _horaInicio.hour, _horaInicio.minute);
    final fin = DateTime(_fecha.year, _fecha.month, _fecha.day, _horaFin.hour,
        _horaFin.minute);

    if (!fin.isAfter(inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora de fin debe ser posterior')),
      );
      return;
    }

    setState(() => _enviando = true);
    final auth = context.read<AuthService>();
    final citas = context.read<CitaService>();
    final user = auth.currentUser!;

    await citas.crearCita(
      tutorId: user.id,
      tutorNombre: user.name,
      cuidadorId: widget.cuidador.usuario.id,
      cuidadorNombre: widget.cuidador.usuario.name,
      fechaInicio: inicio,
      fechaFin: fin,
      direccion: _direccionController.text.trim(),
      notas: _notasController.text.trim(),
      tarifaHora: widget.cuidador.perfil.tarifaPorHora,
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 10),
            Text('¡Solicitud enviada!'),
          ],
        ),
        content: Text(
          'Tu solicitud fue enviada a ${widget.cuidador.usuario.name}. '
          'Recibirás un correo cuando responda.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context); // detalle
              Navigator.pop(context); // agendar
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEEE, d MMM yyyy', 'es_MX');

    return Scaffold(
      appBar: AppBar(title: const Text('Agendar Cita')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        widget.cuidador.usuario.name
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.cuidador.usuario.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '\$${widget.cuidador.perfil.tarifaPorHora.toInt()}/hora',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fecha',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _PickerTile(
              icon: Icons.calendar_today,
              text: df.format(_fecha),
              onTap: _seleccionarFecha,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hora inicio',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _PickerTile(
                        icon: Icons.access_time,
                        text: _horaInicio.format(context),
                        onTap: _seleccionarHoraInicio,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hora fin',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _PickerTile(
                        icon: Icons.access_time,
                        text: _horaFin.format(context),
                        onTap: _seleccionarHoraFin,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Dirección',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _direccionController,
              decoration: const InputDecoration(
                hintText: 'Ej: Av. Tecnológico 1500',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Notas para el cuidador (opcional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notasController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Información adicional, instrucciones, alergias...',
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        color: AppColors.primary),
                    const SizedBox(width: 10),
                    const Text(
                      'Total estimado:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '\$${_totalEstimado.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_enviando ? 'Enviando...' : 'Enviar Solicitud'),
              onPressed: _enviando ? null : _agendar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _PickerTile({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
