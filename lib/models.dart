import 'package:cloud_firestore/cloud_firestore.dart';
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

/// Firestore guarda las fechas como Timestamp.
DateTime _aFecha(dynamic valor) {
  if (valor is Timestamp) return valor.toDate();
  if (valor is DateTime) return valor;
  return DateTime.now();
}

int _aEntero(dynamic valor) => (valor as num?)?.toInt() ?? 0;

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

  factory Fecha.desdeDoc(String id, Map<String, dynamic> m) => Fecha(
        id: id,
        tallerId: m['tallerId'] as String,
        inicio: _aFecha(m['inicio']),
        cupoTotal: _aEntero(m['cupoTotal']),
        cupoDisponible: _aEntero(m['cupoDisponible']),
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

  /// Solo las fechas futuras, ordenadas de la más próxima a la más lejana.
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

  factory Taller.desdeDoc(String id, Map<String, dynamic> m, [List<Fecha> todasLasFechas = const []]) {
    final fechas = todasLasFechas.where((f) => f.inicio.isAfter(DateTime.now())).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    return Taller(
      id: id,
      titulo: m['titulo'] as String? ?? '',
      categoria: Categoria.desde(m['categoria'] as String? ?? ''),
      descripcion: m['descripcion'] as String? ?? '',
      lugar: m['lugar'] as String? ?? '',
      zona: m['zona'] as String? ?? '',
      precio: _aEntero(m['precio']),
      duracionMin: _aEntero(m['duracionMin']),
      nivel: m['nivel'] as String? ?? '',
      materialesIncluidos: m['materialesIncluidos'] as bool? ?? true,
      docente: m['docente'] as String? ?? '',
      destacado: m['destacado'] as bool? ?? false,
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

  factory Reserva.desdeDoc(String id, Map<String, dynamic> m, Taller taller, Fecha fecha) => Reserva(
        id: id,
        cantidad: _aEntero(m['cantidad']),
        total: _aEntero(m['total']),
        codigo: m['codigo'] as String? ?? '',
        taller: taller,
        fecha: fecha,
      );

  bool get esPasada => fecha.inicio.isBefore(DateTime.now());
}
