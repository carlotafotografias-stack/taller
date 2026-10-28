import 'package:flutter/material.dart';

import '../datos.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/arte_categoria.dart';
import '../widgets/tarjetas.dart';
import 'reserva.dart';

class PantallaDetalle extends StatefulWidget {
  const PantallaDetalle({super.key, required this.tallerId});
  final String tallerId;

  @override
  State<PantallaDetalle> createState() => _PantallaDetalleState();
}

class _PantallaDetalleState extends State<PantallaDetalle> {
  late Future<(Taller, (double, int))> _carga = _cargar();

  Future<(Taller, (double, int))> _cargar() async {
    final taller = await Datos.taller(widget.tallerId);
    final puntaje = await Datos.puntaje(widget.tallerId);
    return (taller, puntaje);
  }

  Future<void> _reservar(Taller t) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PantallaReserva(taller: t)));
    if (mounted) setState(() => _carga = _cargar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<(Taller, (double, int))>(
        future: _carga,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return SafeArea(
              child: Aviso(texto: mensajeError(snap.error!), alReintentar: () => setState(() => _carga = _cargar())),
            );
          }
          final (t, (promedio, cantidadResenas)) = snap.data!;
          final proxima = t.proximaFecha;
          final cuposTotales = t.fechas.fold<int>(0, (s, f) => s + f.cupoDisponible);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Stack(
                      children: [
                        ArteCategoria(categoria: t.categoria, alto: 290),
                        Positioned(
                          left: 16,
                          top: MediaQuery.of(context).padding.top + 12,
                          child: _BotonRedondo(
                            icono: Icons.arrow_back,
                            etiqueta: 'Volver',
                            alTocar: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.arcillaSuave,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(t.categoria.nombre,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.arcillaOscura)),
                          ),
                          const SizedBox(height: 8),
                          Text(t.titulo, style: titulo(26)),
                          const SizedBox(height: 6),
                          Text('${t.lugar} · ${t.zona}', style: const TextStyle(fontSize: 14, color: AppColors.piedra)),
                          if (cantidadResenas > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.mostaza, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '${promedio.toStringAsFixed(1).replaceAll('.', ',')} · '
                                  '${cantidadResenas == 1 ? '1 reseña' : '$cantidadResenas reseñas'}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _Dato(valor: duracion(t.duracionMin), etiqueta: 'Duración'),
                              const SizedBox(width: 8),
                              _Dato(valor: t.nivel, etiqueta: 'Nivel'),
                              const SizedBox(width: 8),
                              _Dato(valor: t.materialesIncluidos ? 'Incluidos' : 'Traer', etiqueta: 'Materiales'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(t.descripcion,
                              style: const TextStyle(fontSize: 15, height: 1.55, color: Color(0xFF4A403A))),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.salvia,
                                child: Text(t.docente[0],
                                    style: const TextStyle(color: AppColors.blanco, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.docente, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                  const Text('Dicta este taller',
                                      style: TextStyle(fontSize: 13, color: AppColors.piedra)),
                                ],
                              ),
                            ],
                          ),
                          if (proxima != null) ...[
                            const SizedBox(height: 18),
                            Text('Próxima fecha: ${fechaLarga(proxima.inicio)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.blanco,
                  border: Border(top: BorderSide(color: AppColors.borde)),
                ),
                padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(precio(t.precio), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        Text(
                          proxima == null ? 'Sin cupos por ahora' : 'por persona · $cuposTotales lugares',
                          style: const TextStyle(fontSize: 12, color: AppColors.piedra),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: proxima == null ? null : () => _reservar(t),
                        child: const Text('Reservar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.valor, required this.etiqueta});
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(color: AppColors.blanco, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Text(valor,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(etiqueta, style: const TextStyle(fontSize: 12, color: AppColors.piedra)),
            ],
          ),
        ),
      );
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({required this.icono, required this.etiqueta, required this.alTocar});
  final IconData icono;
  final String etiqueta;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.blanco,
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icono, color: AppColors.tinta),
          tooltip: etiqueta,
          onPressed: alTocar,
        ),
      );
}
