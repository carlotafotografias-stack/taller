import 'package:flutter/material.dart';

import '../datos.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import 'confirmacion.dart';

class PantallaReserva extends StatefulWidget {
  const PantallaReserva({super.key, required this.taller});
  final Taller taller;

  @override
  State<PantallaReserva> createState() => _PantallaReservaState();
}

class _PantallaReservaState extends State<PantallaReserva> {
  late final List<Fecha> _fechas = widget.taller.fechas.where((f) => f.cupoDisponible > 0).toList();
  int _indice = 0;
  int _cantidad = 1;
  bool _enviando = false;

  Fecha? get _fecha => _fechas.isEmpty ? null : _fechas[_indice];

  Future<void> _confirmar() async {
    final fecha = _fecha;
    if (fecha == null) return;
    setState(() => _enviando = true);
    try {
      final id = await Datos.reservar(fechaId: fecha.id, cantidad: _cantidad);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PantallaConfirmacion(reservaId: id)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensajeError(e))));
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fecha = _fecha;
    final total = widget.taller.precio * _cantidad;

    return Scaffold(
      appBar: AppBar(title: const Text('Reservá tu lugar')),
      body: fecha == null
          ? const Center(child: Text('No quedan fechas con cupo para este taller.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text(widget.taller.titulo, style: const TextStyle(fontSize: 15, color: AppColors.piedra)),
                const SizedBox(height: 20),
                const Text('Fecha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _fechas.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final f = _fechas[i];
                      final activa = i == _indice;
                      return Material(
                        color: activa ? AppColors.arcilla : AppColors.blanco,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: activa ? AppColors.arcilla : AppColors.borde, width: 1.5),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() {
                            _indice = i;
                            _cantidad = 1;
                          }),
                          child: SizedBox(
                            width: 82,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(diaSemana(f.inicio),
                                    style: TextStyle(
                                        fontSize: 12, color: activa ? AppColors.blanco : AppColors.piedra)),
                                Text('${f.inicio.day}',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: activa ? AppColors.blanco : AppColors.tinta)),
                                Text(hora(f.inicio),
                                    style: TextStyle(
                                        fontSize: 12, color: activa ? AppColors.blanco : AppColors.piedra)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(fechaLarga(fecha.inicio), style: const TextStyle(fontSize: 14, color: AppColors.piedra)),
                const SizedBox(height: 22),
                const Text('Lugares', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.blanco, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      IconButton.outlined(
                        tooltip: 'Quitar un lugar',
                        onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text('$_cantidad', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                            Text('quedan ${fecha.cupoDisponible}',
                                style: const TextStyle(fontSize: 12, color: AppColors.piedra)),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Sumar un lugar',
                        style: IconButton.styleFrom(backgroundColor: AppColors.tinta),
                        onPressed: _cantidad < fecha.cupoDisponible ? () => setState(() => _cantidad++) : null,
                        icon: const Icon(Icons.add, color: AppColors.crema),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.blanco, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _FilaResumen('${precio(widget.taller.precio)} × $_cantidad', precio(total)),
                      const Divider(height: 22, color: AppColors.borde),
                      _FilaResumen('Total', precio(total), destacado: true),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pago simulado para el prototipo: la reserva se confirma sin cobrar.',
                  style: TextStyle(fontSize: 12, color: AppColors.piedra),
                ),
              ],
            ),
      bottomNavigationBar: fecha == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton(
                  onPressed: _enviando ? null : _confirmar,
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.blanco),
                        )
                      : const Text('Confirmar reserva'),
                ),
              ),
            ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen(this.izquierda, this.derecha, {this.destacado = false});
  final String izquierda;
  final String derecha;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontSize: destacado ? 17 : 14,
      fontWeight: destacado ? FontWeight.w700 : FontWeight.w400,
      color: destacado ? AppColors.tinta : const Color(0xFF4A403A),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(izquierda, style: estilo), Text(derecha, style: estilo)],
    );
  }
}
