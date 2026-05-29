import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../models/perfil_cuidador.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'cuidador_detalle_screen.dart';

/// RF06: búsqueda de cuidadores por ubicación, disponibilidad, precio, etc.
class TutorBuscarScreen extends StatefulWidget {
  const TutorBuscarScreen({super.key});

  @override
  State<TutorBuscarScreen> createState() => _TutorBuscarScreenState();
}

class _TutorBuscarScreenState extends State<TutorBuscarScreen> {
  final _searchController = TextEditingController();
  String _ubicacion = '';
  double _precioMax = 300;
  NivelExperiencia? _nivelMin;
  double _calificacionMin = 0;
  String? _diaDisponible;

  List<CuidadorConUsuario> _resultados = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() => _loading = true);
    final data = context.read<DataService>();
    final results = await data.buscarCuidadores(
      textoBusqueda: _searchController.text.trim(),
      ubicacion: _ubicacion.isEmpty ? null : _ubicacion,
      precioMax: _precioMax,
      nivelMinimo: _nivelMin,
      calificacionMinima: _calificacionMin > 0 ? _calificacionMin : null,
      diaDisponible: _diaDisponible,
    );
    setState(() {
      _resultados = results;
      _loading = false;
    });
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtros de búsqueda',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    controller: TextEditingController(text: _ubicacion),
                    onChanged: (v) => _ubicacion = v,
                  ),
                  const SizedBox(height: 16),
                  Text('Precio máximo por hora: \$${_precioMax.toInt()}'),
                  Slider(
                    min: 50,
                    max: 400,
                    divisions: 35,
                    value: _precioMax,
                    activeColor: AppColors.primary,
                    label: '\$${_precioMax.toInt()}',
                    onChanged: (v) => setSheet(() => _precioMax = v),
                  ),
                  const SizedBox(height: 8),
                  const Text('Nivel mínimo de experiencia'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Cualquiera'),
                        selected: _nivelMin == null,
                        onSelected: (_) => setSheet(() => _nivelMin = null),
                      ),
                      ...NivelExperiencia.values.map(
                        (n) => ChoiceChip(
                          label: Text(n.name),
                          selected: _nivelMin == n,
                          onSelected: (_) => setSheet(() => _nivelMin = n),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Calificación mínima: ${_calificacionMin.toStringAsFixed(1)}'),
                  Slider(
                    min: 0,
                    max: 5,
                    divisions: 10,
                    value: _calificacionMin,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setSheet(() => _calificacionMin = v),
                  ),
                  const SizedBox(height: 8),
                  const Text('Día disponible'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      ChoiceChip(
                        label: const Text('Cualquiera'),
                        selected: _diaDisponible == null,
                        onSelected: (_) =>
                            setSheet(() => _diaDisponible = null),
                      ),
                      for (final d in const [
                        'Lunes',
                        'Martes',
                        'Miércoles',
                        'Jueves',
                        'Viernes',
                        'Sábado',
                        'Domingo'
                      ])
                        ChoiceChip(
                          label: Text(d),
                          selected: _diaDisponible == d,
                          onSelected: (_) =>
                              setSheet(() => _diaDisponible = d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _buscar();
                      },
                      child: const Text('Aplicar filtros'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${user.name.split(' ').first} 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Encuentra el cuidador perfecto para tu familia',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Buscar por nombre o habilidad...',
                            prefixIcon: Icon(Icons.search),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _buscar(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune, color: Colors.white),
                          onPressed: _abrirFiltros,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _resultados.isEmpty
                      ? const _EmptyState()
                      : RefreshIndicator(
                          onRefresh: _buscar,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _resultados.length,
                            itemBuilder: (_, i) {
                              final c = _resultados[i];
                              return _CuidadorCard(
                                cuidador: c,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CuidadorDetalleScreen(cuidador: c),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CuidadorCard extends StatelessWidget {
  final CuidadorConUsuario cuidador;
  final VoidCallback onTap;
  const _CuidadorCard({required this.cuidador, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final perfil = cuidador.perfil;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                name: cuidador.usuario.name,
                photoUrl: cuidador.usuario.photoUrl,
                radius: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cuidador.usuario.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (perfil.verificado)
                          const Icon(
                            Icons.verified,
                            color: AppColors.info,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            perfil.ubicacion,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: perfil.calificacionPromedio,
                          itemSize: 14,
                          itemBuilder: (_, __) => const Icon(
                            Icons.star,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${perfil.calificacionPromedio.toStringAsFixed(1)} (${perfil.totalServicios})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '\$${perfil.tarifaPorHora.toInt()}/hr',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            perfil.nivelExperiencia.name,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No se encontraron cuidadores',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prueba con otros filtros',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
