import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../datos.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/tarjetas.dart';
import 'inicio_shell.dart';

class PantallaConfirmacion extends StatelessWidget {
  const PantallaConfirmacion({super.key, required this.reservaId, this.esNueva = true});
  final String reservaId;
  final bool esNueva;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: esNueva ? null : AppBar(title: const Text('Tu reserva')),
      body: SafeArea(
        child: FutureBuilder<Reserva>(
          future: Datos.reserva(reservaId),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) return Aviso(texto: mensajeError(snap.error!));
            final r = snap.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              children: [
                if (esNueva) ...[
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(color: AppColors.salvia, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: AppColors.blanco, size: 44),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('¡Listo!', textAlign: TextAlign.center, style: titulo(30)),
                  const SizedBox(height: 8),
                ],
                const Text(
                  'Tu lugar está reservado. Mostrá este código al llegar al taller.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF4A403A)),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: AppColors.blanco, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      children: [
                        QrImageView(
                          data: 'TALLER-${r.codigo}',
                          size: 180,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.tinta),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.tinta,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(r.codigo,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 3)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.blanco, borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.taller.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(fechaLarga(r.fecha.inicio), style: const TextStyle(fontSize: 14)),
                      Text('${r.taller.lugar} · ${r.taller.zona}', style: const TextStyle(fontSize: 14)),
                      Text(
                        '${r.cantidad == 1 ? '1 lugar' : '${r.cantidad} lugares'} · ${precio(r.total)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (esNueva) ...[
                  const SizedBox(height: 28),
                  FilledButton(onPressed: () => irAPestana(context, 2), child: const Text('Ver mis reservas')),
                  const SizedBox(height: 4),
                  TextButton(onPressed: () => irAPestana(context, 0), child: const Text('Volver al inicio')),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
