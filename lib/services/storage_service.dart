import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/perfil_cuidador.dart';
import '../models/perfil_tutor.dart';
import '../models/cita.dart';
import '../models/resena.dart';
import '../models/notificacion.dart';
import 'security_service.dart';

/// Servicio de almacenamiento local usando SharedPreferences.
/// En producción se reemplazaría por un backend (Firebase, REST, etc.)
class StorageService {
  final SecurityService _security;
  StorageService(this._security);

  static const _kUsers = 'users';
  static const _kCurrentUserId = 'current_user_id';
  static const _kPerfilesCuidador = 'perfiles_cuidador';
  static const _kPerfilesTutor = 'perfiles_tutor';
  static const _kCitas = 'citas';
  static const _kResenas = 'resenas';
  static const _kNotificaciones = 'notificaciones';
  static const _kSeeded = 'seeded_v1';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _seedIfNeeded();
    await _ensureStaffAccounts();
  }

  /// Garantiza que existan las cuentas de Administrador y Supervisor (actores
  /// definidos en la especificación). Es idempotente: no toca a los demás
  /// usuarios y se ejecuta también sobre instalaciones ya sembradas.
  Future<void> _ensureStaffAccounts() async {
    final users = await getUsers();
    final now = DateTime.now();
    var changed = false;

    if (!users.any((u) => u.role == UserRole.administrador)) {
      users.add(AppUser(
        id: 'adm-001',
        email: 'admin@nanyscare.com',
        password: _security.hashPassword('123456'),
        name: 'Admin Nanys',
        role: UserRole.administrador,
        phone: '614-0000001',
        createdAt: now,
      ));
      changed = true;
    }
    if (!users.any((u) => u.role == UserRole.supervisor)) {
      users.add(AppUser(
        id: 'sup-001',
        email: 'supervisor@nanyscare.com',
        password: _security.hashPassword('123456'),
        name: 'Supervisor Nanys',
        role: UserRole.supervisor,
        phone: '614-0000002',
        createdAt: now,
      ));
      changed = true;
    }
    if (changed) await saveUsers(users);
  }

  // ==================== USUARIOS ====================
  Future<List<AppUser>> getUsers() async {
    final raw = _prefs.getString(_kUsers);
    if (raw == null) return [];
    final List list = jsonDecode(raw);
    return list.map((j) => AppUser.fromJson(j)).toList();
  }

  Future<void> saveUsers(List<AppUser> users) async {
    final raw = jsonEncode(users.map((u) => u.toJson()).toList());
    await _prefs.setString(_kUsers, raw);
  }

  Future<void> setCurrentUserId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kCurrentUserId);
    } else {
      await _prefs.setString(_kCurrentUserId, id);
    }
  }

  String? getCurrentUserId() => _prefs.getString(_kCurrentUserId);

  // ==================== PERFIL CUIDADOR ====================
  Future<List<PerfilCuidador>> getPerfilesCuidador() async {
    final raw = _prefs.getString(_kPerfilesCuidador);
    if (raw == null) return [];
    final List list = jsonDecode(raw);
    return list.map((j) => PerfilCuidador.fromJson(j)).toList();
  }

  Future<void> savePerfilesCuidador(List<PerfilCuidador> perfiles) async {
    final raw = jsonEncode(perfiles.map((p) => p.toJson()).toList());
    await _prefs.setString(_kPerfilesCuidador, raw);
  }

  Future<void> upsertPerfilCuidador(PerfilCuidador perfil) async {
    final perfiles = await getPerfilesCuidador();
    final idx = perfiles.indexWhere((p) => p.userId == perfil.userId);
    if (idx >= 0) {
      perfiles[idx] = perfil;
    } else {
      perfiles.add(perfil);
    }
    await savePerfilesCuidador(perfiles);
  }

  /// Verificación de antecedentes (caso de uso del Supervisor): marca o
  /// desmarca a un cuidador como verificado.
  Future<void> setVerificadoCuidador(String cuidadorId, bool value) async {
    final perfiles = await getPerfilesCuidador();
    final idx = perfiles.indexWhere((p) => p.userId == cuidadorId);
    if (idx < 0) return;
    perfiles[idx] = perfiles[idx].copyWith(verificado: value);
    await savePerfilesCuidador(perfiles);
  }

  // ==================== PERFIL TUTOR ====================
  Future<List<PerfilTutor>> getPerfilesTutor() async {
    final raw = _prefs.getString(_kPerfilesTutor);
    if (raw == null) return [];
    final List list = jsonDecode(raw);
    return list.map((j) => PerfilTutor.fromJson(j)).toList();
  }

  Future<void> savePerfilesTutor(List<PerfilTutor> perfiles) async {
    final raw = jsonEncode(perfiles.map((p) => p.toJson()).toList());
    await _prefs.setString(_kPerfilesTutor, raw);
  }

  Future<void> upsertPerfilTutor(PerfilTutor perfil) async {
    final perfiles = await getPerfilesTutor();
    final idx = perfiles.indexWhere((p) => p.userId == perfil.userId);
    if (idx >= 0) {
      perfiles[idx] = perfil;
    } else {
      perfiles.add(perfil);
    }
    await savePerfilesTutor(perfiles);
  }

  // ==================== CITAS ====================
  Future<List<Cita>> getCitas() async {
    final raw = _prefs.getString(_kCitas);
    if (raw == null) return [];
    final List list = jsonDecode(raw);
    return list.map((j) => Cita.fromJson(j)).toList();
  }

  Future<void> saveCitas(List<Cita> citas) async {
    final raw = jsonEncode(citas.map((c) => c.toJson()).toList());
    await _prefs.setString(_kCitas, raw);
  }

  Future<void> addCita(Cita cita) async {
    final citas = await getCitas();
    citas.add(cita);
    await saveCitas(citas);
  }

  Future<void> updateCita(Cita cita) async {
    final citas = await getCitas();
    final idx = citas.indexWhere((c) => c.id == cita.id);
    if (idx >= 0) {
      citas[idx] = cita;
      await saveCitas(citas);
    }
  }

  // ==================== RESEÑAS ====================
  Future<List<Resena>> getResenas() async {
    final raw = _prefs.getString(_kResenas);
    if (raw == null) return [];
    final List list = jsonDecode(raw);
    return list.map((j) => Resena.fromJson(j)).toList();
  }

  Future<void> addResena(Resena resena) async {
    final resenas = await getResenas();
    resenas.add(resena);
    final raw = jsonEncode(resenas.map((r) => r.toJson()).toList());
    await _prefs.setString(_kResenas, raw);
  }

  /// HU11: recalcula y persiste la calificación promedio de un cuidador
  /// a partir de sus reseñas públicas.
  Future<void> recalcularCalificacionCuidador(String cuidadorId) async {
    final resenas = await getResenas();
    final publicas = resenas
        .where((r) => r.destinatarioId == cuidadorId && !r.esPrivada)
        .toList();
    if (publicas.isEmpty) return;

    final promedio =
        publicas.fold<double>(0, (s, r) => s + r.calificacion) / publicas.length;

    final perfiles = await getPerfilesCuidador();
    final idx = perfiles.indexWhere((p) => p.userId == cuidadorId);
    if (idx < 0) return;

    perfiles[idx] = perfiles[idx].copyWith(
      calificacionPromedio: double.parse(promedio.toStringAsFixed(1)),
    );
    await savePerfilesCuidador(perfiles);
  }

  // ==================== NOTIFICACIONES ====================
  Future<List<Notificacion>> getNotificaciones() async {
    final raw = _prefs.getString(_kNotificaciones);
    if (raw == null) return [];
    final List list = jsonDecode(raw);
    return list.map((j) => Notificacion.fromJson(j)).toList();
  }

  Future<void> saveNotificaciones(List<Notificacion> notifs) async {
    final raw = jsonEncode(notifs.map((n) => n.toJson()).toList());
    await _prefs.setString(_kNotificaciones, raw);
  }

  Future<void> addNotificacion(Notificacion notif) async {
    final notifs = await getNotificaciones();
    notifs.add(notif);
    await saveNotificaciones(notifs);
  }

  // ==================== SEED DE DATOS DEMO ====================
  Future<void> _seedIfNeeded() async {
    if (_prefs.getBool(_kSeeded) == true) return;

    final now = DateTime.now();

    // Usuarios de demostración
    final demoUsers = [
      AppUser(
        id: 'cui-001',
        email: 'maria@nanyscare.com',
        password: _security.hashPassword('123456'),
        name: 'María González',
        role: UserRole.cuidador,
        phone: '614-1234567',
        createdAt: now,
      ),
      AppUser(
        id: 'cui-002',
        email: 'ana@nanyscare.com',
        password: _security.hashPassword('123456'),
        name: 'Ana Martínez',
        role: UserRole.cuidador,
        phone: '614-2345678',
        createdAt: now,
      ),
      AppUser(
        id: 'cui-003',
        email: 'lucia@nanyscare.com',
        password: _security.hashPassword('123456'),
        name: 'Lucía Hernández',
        role: UserRole.cuidador,
        phone: '614-3456789',
        createdAt: now,
      ),
      AppUser(
        id: 'tut-001',
        email: 'carlos@nanyscare.com',
        password: _security.hashPassword('123456'),
        name: 'Carlos Ramírez',
        role: UserRole.tutor,
        phone: '614-4567890',
        createdAt: now,
      ),
    ];
    await saveUsers(demoUsers);

    // Perfiles de cuidadores
    final demoCuidadores = [
      PerfilCuidador(
        userId: 'cui-001',
        descripcion:
            'Educadora con más de 8 años de experiencia en el cuidado infantil. Apasionada por crear ambientes seguros y divertidos.',
        nivelExperiencia: NivelExperiencia.experto,
        certificaciones: ['Primeros auxilios', 'RCP infantil', 'Educadora certificada'],
        capacidades: ['Inglés', 'Apoyo con tareas', 'Cocina infantil', 'Juegos educativos'],
        tarifaPorHora: 250.0,
        ubicacion: 'Chihuahua, Centro',
        diasDisponibles: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'],
        horarioDisponible: '08:00 - 18:00',
        calificacionPromedio: 4.9,
        totalServicios: 47,
        verificado: true,
      ),
      PerfilCuidador(
        userId: 'cui-002',
        descripcion:
            'Estudiante de pedagogía con experiencia cuidando niños de diversas edades. Responsable y cariñosa.',
        nivelExperiencia: NivelExperiencia.intermedio,
        certificaciones: ['Primeros auxilios básicos'],
        capacidades: ['Manualidades', 'Lectura', 'Apoyo con tareas'],
        tarifaPorHora: 130.0,
        ubicacion: 'Chihuahua, Norte',
        diasDisponibles: ['Sábado', 'Domingo', 'Viernes'],
        horarioDisponible: '14:00 - 22:00',
        calificacionPromedio: 4.6,
        totalServicios: 18,
        verificado: true,
      ),
      PerfilCuidador(
        userId: 'cui-003',
        descripcion:
            'Niñera profesional con especialidad en niños con necesidades especiales. 5 años de experiencia.',
        nivelExperiencia: NivelExperiencia.avanzado,
        certificaciones: ['RCP infantil', 'Atención a necesidades especiales'],
        capacidades: ['Lenguaje de señas básico', 'Inglés', 'Música'],
        tarifaPorHora: 200.0,
        ubicacion: 'Chihuahua, Sur',
        diasDisponibles: ['Lunes', 'Miércoles', 'Viernes'],
        horarioDisponible: '07:00 - 15:00',
        calificacionPromedio: 4.8,
        totalServicios: 32,
        verificado: true,
      ),
    ];
    await savePerfilesCuidador(demoCuidadores);

    // Perfil de tutor demo
    await savePerfilesTutor([
      PerfilTutor(
        userId: 'tut-001',
        direccion: 'Av. Tecnológico 1500, Chihuahua',
        hijos: [
          Hijo(nombre: 'Sofía', edad: 5),
          Hijo(nombre: 'Diego', edad: 8, necesidadesEspeciales: 'Alergia a frutos secos'),
        ],
        necesidadesGenerales:
            'Necesitamos apoyo con las tareas escolares y vigilancia durante actividades al aire libre.',
      ),
    ]);

    await _prefs.setBool(_kSeeded, true);
  }

  /// Resetear todos los datos (útil para desarrollo)
  Future<void> reset() async {
    await _prefs.clear();
    await _seedIfNeeded();
  }
}
