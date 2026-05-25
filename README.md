# Nanys Care - Sistema de Gestión

Aplicación móvil desarrollada en Flutter para conectar tutores (padres) con cuidadores (niñeras) de manera segura y confiable.

## Descripción

El propósito principal de la aplicación es facilitar la búsqueda, calendarización y contratación de niñeras, asegurando que los niños reciban el mejor cuidado posible mientras los padres tienen tranquilidad y confianza en su elección.

## Funcionalidades Implementadas

### Registro y Autenticación
- RF01: Registro con correo electrónico para Tutores y Cuidadores
- RF02: Inicio de sesión seguro

### Perfiles de Usuario
- RF03: Perfil de Cuidador con foto, experiencia, certificaciones, disponibilidad y tarifas
- RF04: Tarifas asociadas al nivel de experiencia
- RF05: Perfil de Tutor con información sobre hijos y necesidades específicas

### Búsqueda y Filtrado
- RF06: Búsqueda de cuidadores por ubicación, disponibilidad, precio, experiencia y calificaciones
- RF07: Recepción de solicitudes para cuidadores

### Sistema de Reservas
- RF10: Agendar citas según disponibilidad
- RF11: Recordatorios automáticos por correo
- RF12: Aceptar o rechazar citas

### Calificaciones y Reseñas
- RF14: Calificaciones del Tutor al Cuidador
- RF15: Notas privadas del Cuidador sobre el Tutor

### Notificaciones
- RF21, RF22: Notificaciones por correo electrónico

### Calendarios
- RF25: Consulta de agenda para ambos usuarios

### Reglamento
- RF26: Consulta del reglamento por parte del Cuidador

## Estructura del Proyecto

```
lib/
├── main.dart                  # Punto de entrada
├── theme/                     # Configuración del tema
├── models/                    # Modelos de datos
├── services/                  # Servicios (auth, storage, datos)
├── screens/                   # Pantallas de la app
├── widgets/                   # Componentes reutilizables
└── utils/                     # Utilidades y constantes
```

## Cómo Ejecutar

1. Asegúrate de tener Flutter instalado (versión 3.10 o superior)
2. Clona/descomprime el proyecto
3. Ejecuta los siguientes comandos:

```bash
flutter pub get
flutter run
```

## Compatibilidad

- iOS y Android (RNF Compatibilidad)
- Diseño optimizado para móviles (RNF UI/UX)

## Actores del Sistema

- **Cuidador**: Persona que realiza el servicio de cuidado infantil
- **Tutor**: Padre o madre que solicita el servicio
- **Administrador**: Gestiona catálogos de la aplicación
- **Supervisor**: Encargado de la operatividad del negocio

## Notas

Esta es una versión prototipo/MVP que demuestra el flujo completo de la aplicación. Los datos se almacenan localmente con `shared_preferences` para fines de demostración. En producción, se debería integrar con un backend (Firebase, REST API, etc.) para persistencia real, autenticación segura y notificaciones push/email.
