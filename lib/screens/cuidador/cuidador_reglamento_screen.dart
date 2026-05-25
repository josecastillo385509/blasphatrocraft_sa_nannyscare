import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CuidadorReglamentoScreen extends StatelessWidget {
  const CuidadorReglamentoScreen({super.key});

  static const _normas = <_Norma>[
    _Norma(
      icono: Icons.access_time,
      titulo: '1. Puntualidad y Asistencia',
      contenido:
          'Llega a cada servicio con al menos 5 minutos de anticipación. Si por causa de fuerza mayor no puedes presentarte, debes notificar al tutor y al supervisor con al menos 4 horas de anticipación a través de la app.',
    ),
    _Norma(
      icono: Icons.shield,
      titulo: '2. Seguridad Infantil',
      contenido:
          'La seguridad física y emocional de los niños es la prioridad absoluta. Mantén a los menores siempre bajo supervisión visual. Evita zonas de riesgo, no permitas el acceso a productos químicos, medicamentos o utensilios filosos. Verifica que ventanas, puertas y enchufes estén en condiciones seguras.',
    ),
    _Norma(
      icono: Icons.medical_services,
      titulo: '3. Primeros Auxilios',
      contenido:
          'Debes contar con conocimientos básicos de primeros auxilios y RCP infantil. Ante una emergencia médica, llama de inmediato al 911, contacta al tutor y notifica a la plataforma. Lleva siempre contigo los datos de contacto de los padres y los números de emergencia.',
    ),
    _Norma(
      icono: Icons.chat_bubble_outline,
      titulo: '4. Comunicación con Tutores',
      contenido:
          'Mantén una comunicación clara, respetuosa y profesional con los tutores. Reporta cualquier incidente, accidente o comportamiento inusual del menor. Comparte actualizaciones del día cuando sea solicitado.',
    ),
    _Norma(
      icono: Icons.lock_outline,
      titulo: '5. Confidencialidad y Privacidad',
      contenido:
          'Toda la información personal del tutor, del menor y del hogar es estrictamente confidencial. No tomes fotografías ni videos sin autorización expresa del tutor. No compartas información del servicio en redes sociales.',
    ),
    _Norma(
      icono: Icons.no_drinks,
      titulo: '6. Conducta Personal',
      contenido:
          'Está prohibido fumar, consumir alcohol o cualquier sustancia psicoactiva antes o durante el servicio. Presenta una imagen aseada y profesional. No invites a terceras personas al domicilio del tutor.',
    ),
    _Norma(
      icono: Icons.family_restroom,
      titulo: '7. Respeto a las Reglas del Hogar',
      contenido:
          'Respeta las normas, horarios, alimentación y rutinas establecidas por los tutores (horas de sueño, dieta, pantallas, etc.). No tomes decisiones que contradigan las indicaciones de los padres.',
    ),
    _Norma(
      icono: Icons.phone_disabled,
      titulo: '8. Uso de Dispositivos Personales',
      contenido:
          'Limita el uso de tu teléfono celular y redes sociales durante el servicio. Utilízalo únicamente para comunicarte con el tutor, la plataforma o ante emergencias.',
    ),
    _Norma(
      icono: Icons.payments,
      titulo: '9. Tarifas y Pagos',
      contenido:
          'Las tarifas se establecen previamente a través de la plataforma. No solicites ni aceptes pagos en efectivo fuera del sistema. Cualquier desacuerdo sobre el pago debe canalizarse a través de soporte.',
    ),
    _Norma(
      icono: Icons.report,
      titulo: '10. Reporte de Incidentes',
      contenido:
          'Reporta cualquier incidente, sospecha de maltrato o situación irregular tanto al tutor como al supervisor. La omisión puede acarrear suspensión o baja de la plataforma.',
    ),
    _Norma(
      icono: Icons.gavel,
      titulo: '11. Faltas y Sanciones',
      contenido:
          'El incumplimiento del presente reglamento podrá resultar en advertencias, suspensión temporal o baja definitiva de la plataforma Nanys Care, según la gravedad y reincidencia de la falta.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reglamento'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                Icon(Icons.menu_book, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Normas de Conducta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Lineamientos para el correcto desempeño como cuidador en Nanys Care',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._normas.map(
            (n) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Icon(n.icono, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  n.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                childrenPadding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      n.contenido,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: AppColors.secondary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Al aceptar servicios a través de la plataforma, confirmas que has leído y aceptas este reglamento.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _Norma {
  final IconData icono;
  final String titulo;
  final String contenido;
  const _Norma({
    required this.icono,
    required this.titulo,
    required this.contenido,
  });
}
