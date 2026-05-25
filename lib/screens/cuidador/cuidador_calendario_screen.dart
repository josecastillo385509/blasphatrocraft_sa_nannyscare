import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/cita.dart';
import '../../services/auth_service.dart';
import '../../services/cita_service.dart';
import '../../theme/app_theme.dart';

class CuidadorCalendarioScreen extends StatefulWidget {
  const CuidadorCalendarioScreen({super.key});

  @override
  State<CuidadorCalendarioScreen> createState() =>
      _CuidadorCalendarioScreenState();
}

class _CuidadorCalendarioScreenState extends State<CuidadorCalendarioScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Cita> _citas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;
    final svc = context.read<CitaService>();
    final list = await svc.getCitasParaCuidador(user.id);
    if (!mounted) return;
    setState(() {
      _citas = list;
      _loading = false;
    });
  }

  List<Cita> _eventosDelDia(DateTime day) {
    return _citas.where((c) => isSameDay(c.fechaInicio, day)).toList();
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
    final eventosHoy = _selectedDay != null ? _eventosDelDia(_selectedDay!) : <Cita>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Agenda'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(12),
                  child: TableCalendar<Cita>(
                    locale: 'es_MX',
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                    eventLoader: _eventosDelDia,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Mes',
                      CalendarFormat.twoWeeks: '2 Semanas',
                      CalendarFormat.week: 'Semana',
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonShowsNext: false,
                      titleCentered: true,
                    ),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    onFormatChanged: (f) => setState(() => _calendarFormat = f),
                    onPageChanged: (f) => _focusedDay = f,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDay != null
                            ? DateFormat("EEEE d 'de' MMMM", 'es_MX')
                                .format(_selectedDay!)
                            : '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: eventosHoy.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'Sin citas para este día',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: eventosHoy.length,
                          itemBuilder: (context, i) {
                            final c = eventosHoy[i];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _colorEstado(c.estado).withValues(alpha: 0.15),
                                  child: Icon(Icons.child_care,
                                      color: _colorEstado(c.estado)),
                                ),
                                title: Text('Tutor: ${c.tutorNombre}'),
                                subtitle: Text(
                                  '${DateFormat('HH:mm').format(c.fechaInicio)} - '
                                  '${DateFormat('HH:mm').format(c.fechaFin)}\n'
                                  '${c.direccion}',
                                ),
                                isThreeLine: true,
                                trailing: Chip(
                                  label: Text(
                                    c.estado.name,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor:
                                      _colorEstado(c.estado).withValues(alpha: 0.15),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
