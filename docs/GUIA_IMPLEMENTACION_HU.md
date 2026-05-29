# Guía de implementación — HU9, HU11, HU12, HU14

Guía paso a paso para implementar las 4 historias de usuario pendientes en
**Nanys Care**, respetando la arquitectura actual (modelos + `*Service` con
`ChangeNotifier` + `StorageService` sobre `SharedPreferences` + pantallas por rol).

| HU | Título | Estado actual |
|----|--------|---------------|
| HU9  | Recordatorios automáticos | ❌ No existe el motor de recordatorios |
| HU11 | Calificar cuidadores | 🟡 Parcial: ya se crea la `Resena`, falta promedio/duplicados/mostrarlas |
| HU12 | Evaluar tutores | 🟡 Parcial: ya hay "nota privada", falta pantalla para verlas |
| HU14 | Recordatorios de citas | ❌ Depende de HU9 |

> Las HU9 y HU14 van juntas: HU9 es el **motor** (servicio que genera recordatorios)
> y HU14 es su **primer uso** (recordatorios de citas próximas).

---

## Orden recomendado

1. **HU11** (calificar cuidadores) — completa lo ya empezado, es la más rápida.
2. **HU12** (evaluar tutores) — reutiliza casi todo de HU11.
3. **HU9 + HU14** (recordatorios) — el motor nuevo.

---

## HU11 — Calificar cuidadores

Hoy `tutor_citas_screen.dart` (`_calificar`) ya guarda una `Resena`, pero:
- ❌ no actualiza `PerfilCuidador.calificacionPromedio`,
- ❌ permite calificar la misma cita varias veces,
- ❌ las reseñas no se muestran en ningún lado.

### Paso 1 — Crear un `ResenaService`

Centraliza la lógica para no repetir código entre tutor y cuidador.
Crea `lib/services/resena_service.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../models/resena.dart';
import 'storage_service.dart';

class ResenaService extends ChangeNotifier {
  final StorageService _storage;
  ResenaService(this._storage);

  /// Reseñas PÚBLICAS recibidas por un usuario (para mostrar en su perfil).
  Future<List<Resena>> getResenasPublicas(String destinatarioId) async {
    final all = await _storage.getResenas();
    final list = all
        .where((r) => r.destinatarioId == destinatarioId && !r.esPrivada)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Notas PRIVADAS escritas por un autor (HU12 / RF15).
  Future<List<Resena>> getNotasPrivadas(String autorId) async {
    final all = await _storage.getResenas();
    final list =
        all.where((r) => r.autorId == autorId && r.esPrivada).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// ¿Ya calificó este autor esta cita? (evita duplicados)
  Future<bool> yaCalifico(String citaId, String autorId) async {
    final all = await _storage.getResenas();
    return all.any((r) => r.citaId == citaId && r.autorId == autorId);
  }

  Future<void> crearResena(Resena resena) async {
    await _storage.addResena(resena);
    // Si es pública y va dirigida a un cuidador, recalcula su promedio.
    if (!resena.esPrivada) {
      await _storage.recalcularCalificacionCuidador(resena.destinatarioId);
    }
    notifyListeners();
  }

  Future<double> promedioDe(String destinatarioId) async {
    final list = await getResenasPublicas(destinatarioId);
    if (list.isEmpty) return 0;
    final suma = list.fold<double>(0, (s, r) => s + r.calificacion);
    return suma / list.length;
  }
}
```

### Paso 2 — Recalcular el promedio en `StorageService`

Añade este método en `lib/services/storage_service.dart` (sección RESEÑAS):

```dart
/// Recalcula y persiste calificacionPromedio del cuidador según sus reseñas públicas.
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

  final p = perfiles[idx];
  perfiles[idx] = PerfilCuidador(
    userId: p.userId,
    descripcion: p.descripcion,
    nivelExperiencia: p.nivelExperiencia,
    certificaciones: p.certificaciones,
    capacidades: p.capacidades,
    tarifaPorHora: p.tarifaPorHora,
    ubicacion: p.ubicacion,
    diasDisponibles: p.diasDisponibles,
    horarioDisponible: p.horarioDisponible,
    calificacionPromedio: double.parse(promedio.toStringAsFixed(1)),
    totalServicios: p.totalServicios,
    verificado: p.verificado,
  );
  await savePerfilesCuidador(perfiles);
}
```

> 💡 Más limpio: añade un `copyWith` a `PerfilCuidador` (como ya lo tiene `Cita`)
> y úsalo aquí. Recomendado pero opcional.

### Paso 3 — Registrar el servicio en `main.dart`

```dart
final resenas = ResenaService(storage);
// ...
runApp(NanysCareApp(/* ...existentes..., */ resenas: resenas));
```

Y en `MultiProvider`:
```dart
ChangeNotifierProvider<ResenaService>.value(value: resenas),
```
(Recuerda agregar el campo `final ResenaService resenas;` y el `required this.resenas`
en el constructor de `NanysCareApp`, igual que los otros servicios.)

### Paso 4 — Usar el servicio en `tutor_citas_screen.dart`

En `_calificar`, antes de abrir el diálogo valida duplicados, y al enviar usa
`ResenaService.crearResena` en vez de `storage.addResena`:

```dart
final resenaSvc = context.read<ResenaService>();
if (await resenaSvc.yaCalifico(cita.id, auth.currentUser!.id)) {
  // muestra SnackBar "Ya calificaste esta cita" y return
}
// ...al confirmar:
await resenaSvc.crearResena(resena); // recalcula promedio automáticamente
```

### Paso 5 — Mostrar las reseñas en el perfil del cuidador

En `cuidador_detalle_screen.dart`, agrega una sección "Reseñas" (al final, antes
del botón Agendar). Como esa pantalla es `StatelessWidget`, usa un `FutureBuilder`:

```dart
const SizedBox(height: 20),
_SectionTitle('Reseñas'),
FutureBuilder<List<Resena>>(
  future: context.read<ResenaService>().getResenasPublicas(user.id),
  builder: (context, snap) {
    if (!snap.hasData) return const SizedBox.shrink();
    final resenas = snap.data!;
    if (resenas.isEmpty) {
      return const Text('Aún no tiene reseñas',
          style: TextStyle(color: AppColors.textSecondary));
    }
    return Column(
      children: resenas.map((r) => ListTile(
        leading: const Icon(Icons.star, color: AppColors.warning),
        title: Text('${r.autorNombre} · ${r.calificacion.toStringAsFixed(1)} ★'),
        subtitle: Text(r.comentario),
      )).toList(),
    );
  },
),
```

**✅ HU11 lista** cuando: el tutor califica una cita completada, NO puede repetir,
el promedio en la tarjeta/detalle sube, y las reseñas aparecen en el perfil.

---

## HU12 — Evaluar tutores

`cuidador_solicitudes_screen.dart` (`_pedirNotaPrivada`) ya crea una `Resena` con
`esPrivada: true` cuando el cuidador marca una cita como completada. Falta:
- ❌ una pantalla donde el cuidador **vea** sus notas privadas,
- ❌ (opcional) usar `ResenaService` y evitar duplicados, igual que HU11.

### Decisión de diseño
- **Privada (RF15):** la evaluación del tutor solo la ve el cuidador que la escribió.
  Es lo que ya hace el código → mantenlo así.
- Si tu HU12 pide que el **administrador/supervisor** vea las evaluaciones de tutores,
  entonces NO la marques privada, o agrega un rol que pueda leerlas.

### Paso 1 — Reusar `ResenaService`
Cambia en `_pedirNotaPrivada` el `storage.addResena(...)` por:
```dart
await context.read<ResenaService>().crearResena(resena); // esPrivada:true → no toca promedios
```
Y valida duplicados con `yaCalifico(cita.id, autorId)` igual que en HU11.

### Paso 2 — Pantalla "Mis notas de tutores"
Crea `lib/screens/cuidador/cuidador_notas_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/resena.dart';
import '../../services/auth_service.dart';
import '../../services/resena_service.dart';
import '../../theme/app_theme.dart';

class CuidadorNotasScreen extends StatelessWidget {
  const CuidadorNotasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis notas de tutores')),
      body: FutureBuilder<List<Resena>>(
        future: context.read<ResenaService>().getNotasPrivadas(user.id),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notas = snap.data!;
          if (notas.isEmpty) {
            return const Center(child: Text('Aún no tienes notas privadas'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: notas.map((n) => Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                title: Text('${n.calificacion.toStringAsFixed(1)} ★'),
                subtitle: Text(n.comentario.isEmpty ? '(sin comentario)' : n.comentario),
              ),
            )).toList(),
          );
        },
      ),
    );
  }
}
```

### Paso 3 — Enlazar la pantalla
Agrega un acceso desde `cuidador_home.dart` o `cuidador_perfil_screen.dart`
(un `ListTile`/botón que haga `Navigator.push` a `CuidadorNotasScreen`).

**✅ HU12 lista** cuando: al completar una cita el cuidador evalúa al tutor, y puede
volver a ver esas evaluaciones en "Mis notas de tutores".

---

## HU9 + HU14 — Recordatorios automáticos / de citas

No hay backend ni cron, así que el patrón realista para esta app es:
**revisar las citas cada vez que la app arranca / se refresca el home, y generar
notificaciones de tipo `recordatorio` para las citas próximas que aún no tengan una.**

### Paso 1 — Crear `ReminderService`
Crea `lib/services/reminder_service.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../models/cita.dart';
import '../models/notificacion.dart';
import 'storage_service.dart';
import 'notification_service.dart';

/// HU9/HU14: genera recordatorios automáticos de citas próximas.
class ReminderService {
  final StorageService _storage;
  final NotificationService _notifications;
  ReminderService(this._storage, this._notifications);

  /// Llamar al iniciar sesión y/o al refrescar el home.
  Future<void> generarRecordatoriosPendientes() async {
    final ahora = DateTime.now();
    final citas = await _storage.getCitas();
    final existentes = await _storage.getNotificaciones();

    for (final c in citas) {
      if (c.estado != EstadoCita.aceptada) continue;     // solo citas confirmadas
      final faltan = c.fechaInicio.difference(ahora);
      if (faltan.isNegative) continue;                    // ya pasó
      if (faltan.inHours > 24) continue;                  // recordar dentro de 24h

      // Evita duplicar: una sola notificación de recordatorio por cita y usuario.
      bool yaTiene(String userId) => existentes.any((n) =>
          n.tipo == TipoNotificacion.recordatorio &&
          n.usuarioId == userId &&
          n.mensaje.contains(c.id));

      final cuando = _fmt(c.fechaInicio);
      if (!yaTiene(c.tutorId)) {
        await _notifications.enviarNotificacion(
          usuarioId: c.tutorId,
          titulo: 'Recordatorio de cita',
          mensaje: 'Tu cita con ${c.cuidadorNombre} es el $cuando. [${c.id}]',
          tipo: TipoNotificacion.recordatorio,
        );
      }
      if (!yaTiene(c.cuidadorId)) {
        await _notifications.enviarNotificacion(
          usuarioId: c.cuidadorId,
          titulo: 'Recordatorio de cita',
          mensaje: 'Tienes una cita con ${c.tutorNombre} el $cuando. [${c.id}]',
          tipo: TipoNotificacion.recordatorio,
        );
      }
    }
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
```

> El `[${c.id}]` dentro del mensaje sirve para detectar duplicados sin tocar el
> modelo `Notificacion`. Si prefieres algo más limpio, agrega un campo
> `citaId` opcional a `Notificacion` (acuérdate de actualizar `toJson`/`fromJson`).

### Paso 2 — Registrar y disparar
En `main.dart`:
```dart
final reminders = ReminderService(storage, notifications);
await reminders.generarRecordatoriosPendientes(); // al arrancar
```
Y vuelve a llamarlo cuando el usuario entra a su home o hace *pull-to-refresh*
en `notificaciones_screen.dart` (dentro de `_load`):
```dart
await context.read<ReminderService>().generarRecordatoriosPendientes();
```
(Regístralo como `Provider<ReminderService>.value(...)` si lo vas a leer desde widgets.)

### Paso 3 (opcional, HU9 más amplio)
HU9 ("automáticos") puede cubrir más recordatorios reutilizando el mismo servicio:
- recordar al tutor **calificar** una cita ya completada y sin reseña (enlaza con HU11),
- recordar al cuidador **completar** una cita aceptada cuya `fechaFin` ya pasó.

La UI ya está lista: `notificaciones_screen.dart` muestra el ícono ⏰ y color naranja
para `TipoNotificacion.recordatorio`.

**✅ HU9/HU14 listas** cuando: al abrir la app, las citas aceptadas dentro de las
próximas 24h generan una notificación de recordatorio (sin duplicarse) visible
para tutor y cuidador.

---

## Checklist final

- [ ] `ResenaService` creado y registrado en `main.dart`
- [ ] `StorageService.recalcularCalificacionCuidador` añadido
- [ ] HU11: validación de duplicado + promedio actualizado + reseñas visibles en perfil
- [ ] HU12: `crearResena` con `esPrivada:true` + pantalla "Mis notas" enlazada
- [ ] `ReminderService` creado y registrado
- [ ] HU9/HU14: recordatorios disparados al arrancar y al refrescar notificaciones
- [ ] `flutter analyze` sin errores y `flutter run` probado con los usuarios demo

## Cómo probar rápido (datos demo)
- Tutor: `carlos@nanyscare.com` / `123456`
- Cuidadora: `maria@nanyscare.com` / `123456`
- Flujo: tutor agenda cita → cuidadora acepta → cuidadora "marca completada"
  (evalúa tutor, HU12) → tutor califica (HU11) → reabrir app para ver recordatorios (HU9/HU14).
- Para reiniciar datos: `StorageService.reset()`.
