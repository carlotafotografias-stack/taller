import 'package:flutter/material.dart';

import '../datos.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/arte_categoria.dart';
import '../widgets/tarjetas.dart';
import 'confirmacion.dart';
import 'detalle.dart';
import 'inicio_shell.dart';

class PantallaMisReservas extends StatefulWidget {
  const PantallaMisReservas({super.key});

  @override
  State<PantallaMisReservas> createState() => _PantallaMisReservasState();
}

class _PantallaMisReservasState extends State<PantallaMisReservas> {
  late Future<(List<Reserva>, Map<String, int>)> _carga = _cargar();
  bool _verPasadas = false;

  Future<(List<Reserva>, Map<String, int>)> _cargar() async {
    final reservas = await Datos.misReservas();
    final resenas = await Datos.misResenas();
    return (reservas, resenas);
  }

  @override
  void initState() {
    super.initState();
    pestanaActiva.addListener(_alCambiarPestana);
  }

  @override
  void dispose() {
    pestanaActiva.removeListener(_alCambiarPestana);
    super.dispose();
  }

  // Recarga cada vez que se abre la pestaña, para mostrar reservas nuevas.
  void _alCambiarPestana() {
    if (pestanaActiva.value == 2) setState(() => _carga = _cargar());
  }

  Future<void> _resenar(Reserva r, int puntaje) async {
    try {
      await Datos.resenar(tallerId: r.taller.id, puntaje: puntaje);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias! Tu reseña ayuda a otras personas a elegir.')),
      );
      setState(() => _carga = _cargar());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensajeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<(List<Reserva>, Map<String, int>)>(
        future: _carga,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Aviso(texto: mensajeError(snap.error!), alReintentar: () => setState(() => _carga = _cargar()));
          }
          final (reservas, resenas) = snap.data!;
          final lista = reservas.where((r) => r.esPasada == _verPasadas).toList();
          if (_verPasadas) lista.sort((a, b) => b.fecha.inicio.compareTo(a.fecha.inicio));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text('Mis reservas', style: titulo(28)),
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Próximas')),
                  ButtonSegment(value: true, label: Text('Pasadas')),
                ],
                selected: {_verPasadas},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _verPasadas = s.first),
              ),
              const SizedBox(height: 16),
              if (lista.isEmpty)
                Aviso(
                  texto: _verPasadas
                      ? 'Todavía no fuiste a ningún taller.'
                      : 'No tenés reservas próximas. ¡Buscá tu próximo plan!',
                ),
              if (lista.isEmpty && !_verPasadas)
                Center(
                  child: OutlinedButton(
                    onPressed: () => pestanaActiva.value = 1,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Explorar talleres'),
                    ),
                  ),
                ),
              for (final r in lista) ...[
                _verPasadas
                    ? _TarjetaPasada(reserva: r, puntaje: resenas[r.taller.id] ?? 0, alPuntuar: (p) => _resenar(r, p))
                    : _TarjetaProxima(reserva: r),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaProxima extends StatelessWidget {
  const _TarjetaProxima({required this.reserva});
  final Reserva reserva;

  @override
  Widget build(BuildContext context) {
    final r = reserva;
    final dias = r.fecha.inicio.difference(DateTime.now()).inHours ~/ 24;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.blanco, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ArteCategoria(categoria: r.taller.categoria, alto: 110),
              Positioned(
                right: 12,
                top: 12,
                child: Etiqueta(texto: dias <= 0 ? 'Hoy' : (dias == 1 ? 'Mañana' : 'En $dias días')),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.taller.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${fechaCorta(r.fecha.inicio)} · ${r.taller.lugar}',
                    style: const TextStyle(fontSize: 13, color: AppColors.piedra)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.tinta,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PantallaConfirmacion(reservaId: r.id, esNueva: false),
                        )),
                        child: const Text('Ver código QR', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PantallaDetalle(tallerId: r.taller.id),
                        )),
                        child: const Text('Ver taller', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPasada extends StatelessWidget {
  const _TarjetaPasada({required this.reserva, required this.puntaje, required this.alPuntuar});
  final Reserva reserva;
  final int puntaje;
  final ValueChanged<int> alPuntuar;

  @override
  Widget build(BuildContext context) {
    final r = reserva;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.blanco, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 64, child: ArteCategoria(categoria: r.taller.categoria, alto: 64, radio: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.taller.titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(fechaCorta(r.fecha.inicio), style: const TextStyle(fontSize: 13, color: AppColors.piedra)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(puntaje == 0 ? '¿Cómo estuvo?' : 'Tu reseña',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i de 5 estrellas',
                  onPressed: () => alPuntuar(i),
                  icon: Icon(
                    i <= puntaje ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.mostaza,
                    size: 32,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
