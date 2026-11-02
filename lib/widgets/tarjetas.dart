import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import 'arte_categoria.dart';

/// Tarjeta grande para el carrusel de destacados.
class TarjetaTaller extends StatelessWidget {
  const TarjetaTaller({super.key, required this.taller, required this.alTocar, this.ancho = 250});

  final Taller taller;
  final VoidCallback alTocar;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    final proxima = taller.proximaFecha;
    return SizedBox(
      width: ancho,
      child: Material(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: alTocar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ArteCategoria(categoria: taller.categoria, alto: 140),
                  if (proxima != null && proxima.cupoDisponible <= 3)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Etiqueta(texto: 'Quedan ${proxima.cupoDisponible}'),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(taller.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      proxima != null ? '${fechaCorta(proxima.inicio)} · ${taller.zona}' : 'Sin fechas por ahora',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.piedra),
                    ),
                    const SizedBox(height: 6),
                    Text(precio(taller.precio),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.arcillaOscura)),
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

/// Fila compacta para listas de resultados.
class FilaTaller extends StatelessWidget {
  const FilaTaller({super.key, required this.taller, required this.alTocar});

  final Taller taller;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final proxima = taller.proximaFecha;
    return Material(
      color: AppColors.blanco,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(width: 72, child: ArteCategoria(categoria: taller.categoria, alto: 72, radio: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(taller.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      proxima != null ? '${fechaCorta(proxima.inicio)} · ${taller.zona}' : taller.zona,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.piedra),
                    ),
                    const SizedBox(height: 2),
                    Text(precio(taller.precio),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.arcillaOscura)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.piedra),
            ],
          ),
        ),
      ),
    );
  }
}

/// Píldora blanca chica ("Quedan 3").
class Etiqueta extends StatelessWidget {
  const Etiqueta({super.key, required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.blanco, borderRadius: BorderRadius.circular(999)),
        child: Text(texto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

/// Chip seleccionable de categoría o filtro.
class ChipFiltro extends StatelessWidget {
  const ChipFiltro({super.key, required this.texto, required this.activo, required this.alTocar});

  final String texto;
  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: activo ? AppColors.tinta : AppColors.blanco,
      shape: StadiumBorder(side: BorderSide(color: activo ? AppColors.tinta : AppColors.borde, width: 1.5)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: alTocar,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // widthFactor: 1 hace que el chip ocupe solo el ancho de su texto.
          child: Center(
            widthFactor: 1,
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: activo ? AppColors.crema : AppColors.tinta,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mensaje centrado para errores o listas vacías, con botón de reintento opcional.
class Aviso extends StatelessWidget {
  const Aviso({super.key, required this.texto, this.alReintentar});
  final String texto;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.piedra)),
              if (alReintentar != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: alReintentar, child: const Text('Reintentar')),
              ],
            ],
          ),
        ),
      );
}
