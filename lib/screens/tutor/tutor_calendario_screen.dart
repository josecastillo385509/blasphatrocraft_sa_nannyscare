import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../models/cita.dart';
import '../../services/auth_service.dart';
import '../../services/cita_service.dart';
import '../../theme/app_theme.dart';

/// RF25: el tutor puede consultar su agenda.
class TutorCalendarioScreen extends StatefulWidget {
  const TutorCalendarioScreen({super.key});

  @override
  State<TutorCalendarioScreen> createState() => _TutorCalendarioScreenState();
}

class _TutorCalendarioScreenState extends State<TutorCalendarioScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Cita> _allCitas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = context.read<AuthService>().currentUser!;
    final svc = context.read<CitaService>();
    final list = await svc.getCitasDelTutor(user.id);
    setState(() {
      _allCitas = list;
      _loading = false;
    });
  }

  List<Cita> _eventosDelDia(DateTime day) {
    return _allCitas.where((c) {
      return c.fechaInicio.year == day.year &&
          c.fechaInicio.month == day.month &&
          c.fechaInicio.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Agenda')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  Card(
                    margin: const EdgeInsets.all(12),
                    child: TableCalendar<Cita>(
                      locale: 'es_MX',
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (d) =>
                          _selectedDay != null && isSameDay(_selectedDay!, d),
                      eventLoader: _eventosDelDia,
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      _selectedDay == null
                          ? 'Selecciona un día'
                          : 'Citas del ${DateFormat("d 'de' MMMM", 'es_MX').format(_selectedDay!)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  ...(_selectedDay == null
                      ? <Widget>[]
                      : _eventosDelDia(_selectedDay!).isEmpty
                          ? [
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    'Sin citas programadas',
                                    style: TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                              )
                            ]
                          : _eventosDelDia(_selectedDay!)
                              .map((c) => _EventTile(cita: c))
                              .toList()),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final Cita cita;
  const _EventTile({required this.cita});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('HH:mm');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                df.format(cita.fechaInicio),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
              Text(
                df.format(cita.fechaFin),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        title: Text(cita.cuidadorNombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(cita.direccion),
        trailing: Text(
          cita.estado.label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
