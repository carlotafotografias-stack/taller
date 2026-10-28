import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Ilustración abstracta de cada categoría (reemplaza a las fotos).
class ArteCategoria extends StatelessWidget {
  const ArteCategoria({super.key, required this.categoria, this.alto = 140, this.radio = 0});

  final Categoria categoria;
  final double alto;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: SizedBox(
        height: alto,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(child: ColoredBox(color: categoria.color)),
              ..._formas(c.maxWidth, alto),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _formas(double w, double h) {
    switch (categoria) {
      case Categoria.ceramica:
        return [
          _arco(left: w * 0.10, ancho: w * 0.32, alto: h * 0.70, color: AppColors.arcillaClara),
          _arco(left: w * 0.45, ancho: w * 0.30, alto: h * 0.52, color: AppColors.arcillaOscura),
          _circulo(right: -h * 0.25, top: h * 0.12, d: h * 0.65, color: const Color(0xFFE9A58E)),
        ];
      case Categoria.yoga:
        return [
          _circulo(left: w * 0.32, top: h * 0.12, d: h * 0.62, color: AppColors.mostaza),
          Positioned(
            left: -w * 0.1,
            right: -w * 0.1,
            bottom: -h * 0.25,
            child: Container(
              height: h * 0.55,
              decoration: const BoxDecoration(
                color: AppColors.salviaOscura,
                borderRadius: BorderRadius.vertical(top: Radius.elliptical(400, 120)),
              ),
            ),
          ),
        ];
      case Categoria.pintura:
        return [
          _circulo(left: w * 0.38, top: h * 0.15, d: h * 0.6, color: const Color(0xFFF2C46E)),
          _trazo(left: -w * 0.05, bottom: h * 0.18, ancho: w * 0.8, grosor: 14, color: AppColors.arcilla, angulo: -0.14),
          _trazo(left: w * 0.15, bottom: h * 0.36, ancho: w * 0.7, grosor: 10, color: AppColors.tinta, angulo: 0.1),
        ];
      case Categoria.sonido:
        return [
          for (final f in [0.95, 0.7, 0.45])
            Positioned(
              left: w / 2 - h * f / 2,
              top: h / 2 - h * f / 2,
              child: Container(
                width: h * f,
                height: h * f,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lavandaOscura, width: 2),
                ),
              ),
            ),
          _circulo(left: w / 2 - h * 0.08, top: h / 2 - h * 0.08, d: h * 0.16, color: AppColors.tinta),
        ];
      case Categoria.fotografia:
        return [
          Positioned(
            left: w / 2 - h * 0.45,
            top: h * 0.2,
            child: Container(
              width: h * 0.9,
              height: h * 0.6,
              decoration: BoxDecoration(color: const Color(0xFF4A403A), borderRadius: BorderRadius.circular(12)),
            ),
          ),
          _circulo(left: w / 2 - h * 0.2, top: h * 0.3, d: h * 0.4, color: AppColors.lavanda),
          _circulo(left: w / 2 - h * 0.1, top: h * 0.4, d: h * 0.2, color: AppColors.tinta),
          _circulo(left: w / 2 + h * 0.25, top: h * 0.25, d: h * 0.08, color: AppColors.mostaza),
        ];
    }
  }

  Widget _arco({required double left, required double ancho, required double alto, required Color color}) =>
      Positioned(
        left: left,
        bottom: 0,
        child: Container(
          width: ancho,
          height: alto,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.vertical(top: Radius.circular(ancho / 2)),
          ),
        ),
      );

  Widget _circulo({double? left, double? right, required double top, required double d, required Color color}) =>
      Positioned(
        left: left,
        right: right,
        top: top,
        child: Container(width: d, height: d, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      );

  Widget _trazo({
    required double left,
    required double bottom,
    required double ancho,
    required double grosor,
    required Color color,
    required double angulo,
  }) =>
      Positioned(
        left: left,
        bottom: bottom,
        child: Transform.rotate(
          angle: angulo,
          child: Container(
            width: ancho,
            height: grosor,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(grosor)),
          ),
        ),
      );
}
