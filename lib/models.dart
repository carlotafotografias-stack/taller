import 'package:flutter/material.dart';

import 'theme.dart';

/// Categorías de talleres, con su nombre visible y su color.
enum Categoria {
  ceramica('Cerámica', AppColors.arcilla, AppColors.blanco),
  pintura('Pintura', AppColors.mostaza, AppColors.tinta),
  yoga('Yoga', AppColors.salvia, AppColors.blanco),
  sonido('Sonido', AppColors.lavanda, AppColors.tinta),
  fotografia('Fotografía', AppColors.tinta, AppColors.blanco);

  const Categoria(this.nombre, this.color, this.colorTexto);

  final String nombre;
  final Color color;
  final Color colorTexto;

  static Categoria desde(String valor) =>
      Categoria.values.firstWhere((c) => c.name == valor, orElse: () => Categoria.ceramica);
}

class Fecha {
  final String id;
  final String tallerId;
  final DateTime inicio;
  final int cupoTotal;
  final int cupoDisponible;

  Fecha({
    required this.id,
    required this.tallerId,
    required this.inicio,
    required this.cupoTotal,
    required this.cupoDisponible,
  });

  factory Fecha.desdeMapa(Map<String, dynamic> m) => Fecha(
        id: m['id'] as String,
        tallerId: m['taller_id'] as String,
        inicio: DateTime.parse(m['inicio'] as String).toLocal(),
        cupoTotal: m['cupo_total'] as int,
        cupoDisponible: m['cupo_disponible'] as int,
      );
}

class Taller {
  final String id;
  final String titulo;
  final Categoria categoria;
  final String descripcion;
  final String lugar;
  final String zona;
  final int precio;
  final int duracionMin;
  final String nivel;
  final bool materialesIncluidos;
  final String docente;
  final bool destacado;
  final List<Fecha> fechas;

  Taller({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.descripcion,
    required this.lugar,
    required this.zona,
    required this.precio,
    required this.duracionMin,
    required this.nivel,
    required this.materialesIncluidos,
    required this.docente,
    required this.destacado,
    required this.fechas,
  });

  factory Taller.desdeMapa(Map<String, dynamic> m) {
    final fechas = ((m['fechas'] as List?) ?? [])
        .map((f) => Fecha.desdeMapa(Map<String, dynamic>.from(f as Map)))
        .where((f) => f.inicio.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    return Taller(
      id: m['id'] as String,
      titulo: m['titulo'] as String,
      categoria: Categoria.desde(m['categoria'] as String),
      descripcion: m['descripcion'] as String,
      lugar: m['lugar'] as String,
      zona: m['zona'] as String,
      precio: m['precio'] as int,
      duracionMin: m['duracion_min'] as int,
      nivel: m['nivel'] as String,
      materialesIncluidos: m['materiales_incluidos'] as bool,
      docente: m['docente'] as String,
      destacado: m['destacado'] as bool,
      fechas: fechas,
    );
  }

  /// La próxima fecha con cupo, si hay.
  Fecha? get proximaFecha {
    for (final f in fechas) {
      if (f.cupoDisponible > 0) return f;
    }
    return null;
  }
}

class Reserva {
  final String id;
  final int cantidad;
  final int total;
  final String codigo;
  final Taller taller;
  final Fecha fecha;

  Reserva({
    required this.id,
    required this.cantidad,
    required this.total,
    required this.codigo,
    required this.taller,
    required this.fecha,
  });

  /// Espera una fila de "reservas" con los datos del taller y la fecha incluidos.
  factory Reserva.desdeMapa(Map<String, dynamic> m) {
    final tallerMapa = Map<String, dynamic>.from(m['talleres'] as Map);
    tallerMapa['fechas'] = <dynamic>[];
    return Reserva(
      id: m['id'] as String,
      cantidad: m['cantidad'] as int,
      total: m['total'] as int,
      codigo: m['codigo'] as String,
      taller: Taller.desdeMapa(tallerMapa),
      fecha: Fecha.desdeMapa(Map<String, dynamic>.from(m['fechas'] as Map)),
    );
  }

  bool get esPasada => fecha.inicio.isBefore(DateTime.now());
}
