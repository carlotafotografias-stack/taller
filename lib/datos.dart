import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

SupabaseClient get supabase => Supabase.instance.client;

/// Todas las consultas a la base de datos de Supabase.
class Datos {
  // ---------- Cuenta ----------

  static Future<void> registrarse({
    required String nombre,
    required String email,
    required String contrasena,
    required List<String> intereses,
  }) async {
    await supabase.auth.signUp(
      email: email,
      password: contrasena,
      data: {'nombre': nombre, 'intereses': intereses},
    );
  }

  static Future<void> ingresar({required String email, required String contrasena}) async {
    await supabase.auth.signInWithPassword(email: email, password: contrasena);
  }

  static Future<void> salir() => supabase.auth.signOut();

  static Future<Map<String, dynamic>?> miPerfil() async {
    final usuario = supabase.auth.currentUser;
    if (usuario == null) return null;
    return await supabase.from('perfiles').select().eq('id', usuario.id).maybeSingle();
  }

  static Future<void> guardarIntereses(List<String> intereses) async {
    final usuario = supabase.auth.currentUser;
    if (usuario == null) return;
    await supabase.from('perfiles').update({'intereses': intereses}).eq('id', usuario.id);
  }

  // ---------- Talleres ----------

  static Future<List<Taller>> talleres() async {
    final filas = await supabase.from('talleres').select('*, fechas(*)').order('titulo');
    return filas.map(Taller.desdeMapa).toList();
  }

  static Future<Taller> taller(String id) async {
    final fila = await supabase.from('talleres').select('*, fechas(*)').eq('id', id).single();
    return Taller.desdeMapa(fila);
  }

  // ---------- Reservas ----------

  /// Llama a la función "reservar" de la base, que descuenta los cupos.
  static Future<String> reservar({required String fechaId, required int cantidad}) async {
    final resultado = await supabase.rpc(
      'reservar',
      params: {'p_fecha_id': fechaId, 'p_cantidad': cantidad},
    );
    return Map<String, dynamic>.from(resultado as Map)['id'] as String;
  }

  static Future<Reserva> reserva(String id) async {
    final fila = await supabase
        .from('reservas')
        .select('*, talleres(*), fechas(*)')
        .eq('id', id)
        .single();
    return Reserva.desdeMapa(fila);
  }

  static Future<List<Reserva>> misReservas() async {
    final usuario = supabase.auth.currentUser;
    if (usuario == null) return [];
    final filas = await supabase
        .from('reservas')
        .select('*, talleres(*), fechas(*)')
        .eq('usuario_id', usuario.id)
        .order('creado_en', ascending: false);
    final reservas = filas.map(Reserva.desdeMapa).toList()
      ..sort((a, b) => a.fecha.inicio.compareTo(b.fecha.inicio));
    return reservas;
  }

  // ---------- Reseñas ----------

  /// Devuelve el puntaje que el usuario le dio a cada taller.
  static Future<Map<String, int>> misResenas() async {
    final usuario = supabase.auth.currentUser;
    if (usuario == null) return {};
    final filas = await supabase.from('resenas').select('taller_id, puntaje').eq('usuario_id', usuario.id);
    return {for (final f in filas) f['taller_id'] as String: f['puntaje'] as int};
  }

  static Future<void> resenar({required String tallerId, required int puntaje}) async {
    final usuario = supabase.auth.currentUser;
    if (usuario == null) return;
    await supabase.from('resenas').upsert(
      {'usuario_id': usuario.id, 'taller_id': tallerId, 'puntaje': puntaje},
      onConflict: 'usuario_id,taller_id',
    );
  }

  /// Promedio de puntajes y cantidad de reseñas de un taller.
  static Future<(double, int)> puntaje(String tallerId) async {
    final filas = await supabase.from('resenas').select('puntaje').eq('taller_id', tallerId);
    if (filas.isEmpty) return (0.0, 0);
    final suma = filas.fold<int>(0, (s, f) => s + (f['puntaje'] as int));
    return (suma / filas.length, filas.length);
  }
}
