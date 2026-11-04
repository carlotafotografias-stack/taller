import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models.dart';

final _auth = FirebaseAuth.instance;
final _db = FirebaseFirestore.instance;

/// Todas las lecturas y escrituras en Firebase.
///
/// Colecciones de Firestore:
///   perfiles/{uid}         nombre, intereses, creadoEn
///   talleres/{id}          titulo, categoria, descripcion, lugar, zona, precio, ...
///   fechas/{id}            tallerId, inicio, cupoTotal, cupoDisponible
///   reservas/{id}          usuarioId, tallerId, fechaId, cantidad, total, estado, codigo, creadoEn
///   resenas/{uid_tallerId} usuarioId, tallerId, puntaje, comentario, creadoEn
class Datos {
  static String? get email => _auth.currentUser?.email;
  static String? get _uid => _auth.currentUser?.uid;

  // ---------- Cuenta ----------

  static Future<void> registrarse({
    required String nombre,
    required String email,
    required String contrasena,
    required List<String> intereses,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: contrasena);
    await cred.user!.updateDisplayName(nombre);
    await _db.collection('perfiles').doc(cred.user!.uid).set({
      'nombre': nombre,
      'intereses': intereses,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> ingresar({required String email, required String contrasena}) =>
      _auth.signInWithEmailAndPassword(email: email, password: contrasena);

  static Future<void> salir() => _auth.signOut();

  static Future<Map<String, dynamic>?> miPerfil() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _db.collection('perfiles').doc(uid).get();
    return doc.data() ?? {'nombre': _auth.currentUser?.displayName ?? '', 'intereses': <String>[]};
  }

  static Future<void> guardarIntereses(List<String> intereses) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('perfiles').doc(uid).set({'intereses': intereses}, SetOptions(merge: true));
  }

  // ---------- Talleres ----------

  static Future<List<Taller>> talleres() async {
    await _asegurarDatosDeEjemplo();
    final res = await Future.wait([
      _db.collection('talleres').get(),
      _db.collection('fechas').get(),
    ]);
    final fechasPorTaller = <String, List<Fecha>>{};
    for (final d in res[1].docs) {
      final f = Fecha.desdeDoc(d.id, d.data());
      fechasPorTaller.putIfAbsent(f.tallerId, () => []).add(f);
    }
    final lista = res[0]
        .docs
        .map((d) => Taller.desdeDoc(d.id, d.data(), fechasPorTaller[d.id] ?? const []))
        .toList()
      ..sort((a, b) => a.titulo.compareTo(b.titulo));
    return lista;
  }

  static Future<Taller> taller(String id) async {
    final res = await Future.wait([
      _db.collection('talleres').doc(id).get(),
      _db.collection('fechas').where('tallerId', isEqualTo: id).get(),
    ]);
    final doc = res[0] as DocumentSnapshot<Map<String, dynamic>>;
    final fechas = (res[1] as QuerySnapshot<Map<String, dynamic>>)
        .docs
        .map((d) => Fecha.desdeDoc(d.id, d.data()))
        .toList();
    return Taller.desdeDoc(doc.id, doc.data() ?? {}, fechas);
  }

  // ---------- Reservas ----------

  /// Reserva lugares en una fecha. Usa una transacción: revisa el cupo,
  /// lo descuenta y crea la reserva en un solo paso, así dos personas
  /// no pueden quedarse con el mismo lugar.
  static Future<String> reservar({required String fechaId, required int cantidad}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Tenés que iniciar sesión para reservar');
    final fechaRef = _db.collection('fechas').doc(fechaId);
    final reservaRef = _db.collection('reservas').doc();

    await _db.runTransaction((tx) async {
      final fechaDoc = await tx.get(fechaRef);
      if (!fechaDoc.exists) throw Exception('La fecha no existe');
      final fecha = Fecha.desdeDoc(fechaDoc.id, fechaDoc.data()!);
      if (fecha.inicio.isBefore(DateTime.now())) throw Exception('Esa fecha ya pasó');
      if (cantidad < 1 || cantidad > fecha.cupoDisponible) throw Exception('No hay cupos suficientes');
      final tallerDoc = await tx.get(_db.collection('talleres').doc(fecha.tallerId));
      final precio = (tallerDoc.data()?['precio'] as num?)?.toInt() ?? 0;

      tx.update(fechaRef, {'cupoDisponible': fecha.cupoDisponible - cantidad});
      tx.set(reservaRef, {
        'usuarioId': uid,
        'tallerId': fecha.tallerId,
        'fechaId': fechaId,
        'cantidad': cantidad,
        'total': precio * cantidad,
        'estado': 'confirmada',
        'codigo': _codigo(),
        'creadoEn': FieldValue.serverTimestamp(),
      });
    });
    return reservaRef.id;
  }

  static Future<Reserva> reserva(String id) async {
    final doc = await _db.collection('reservas').doc(id).get();
    final m = doc.data()!;
    final res = await Future.wait([
      taller(m['tallerId'] as String),
      _db.collection('fechas').doc(m['fechaId'] as String).get(),
    ]);
    final fechaDoc = res[1] as DocumentSnapshot<Map<String, dynamic>>;
    return Reserva.desdeDoc(doc.id, m, res[0] as Taller, Fecha.desdeDoc(fechaDoc.id, fechaDoc.data()!));
  }

  static Future<List<Reserva>> misReservas() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _db.collection('reservas').where('usuarioId', isEqualTo: uid).get();
    if (snap.docs.isEmpty) return [];

    // Traemos cada taller y cada fecha una sola vez.
    final tallerIds = {for (final d in snap.docs) d.data()['tallerId'] as String};
    final fechaIds = {for (final d in snap.docs) d.data()['fechaId'] as String};
    final talleresDocs = await Future.wait(tallerIds.map((id) => _db.collection('talleres').doc(id).get()));
    final fechasDocs = await Future.wait(fechaIds.map((id) => _db.collection('fechas').doc(id).get()));
    final talleres = {for (final d in talleresDocs) d.id: Taller.desdeDoc(d.id, d.data() ?? {})};
    final fechas = {for (final d in fechasDocs) if (d.exists) d.id: Fecha.desdeDoc(d.id, d.data()!)};

    final reservas = <Reserva>[];
    for (final d in snap.docs) {
      final m = d.data();
      final t = talleres[m['tallerId']];
      final f = fechas[m['fechaId']];
      if (t != null && f != null) reservas.add(Reserva.desdeDoc(d.id, m, t, f));
    }
    reservas.sort((a, b) => a.fecha.inicio.compareTo(b.fecha.inicio));
    return reservas;
  }

  // ---------- Reseñas ----------

  /// Devuelve el puntaje que el usuario le dio a cada taller.
  static Future<Map<String, int>> misResenas() async {
    final uid = _uid;
    if (uid == null) return {};
    final snap = await _db.collection('resenas').where('usuarioId', isEqualTo: uid).get();
    return {for (final d in snap.docs) d.data()['tallerId'] as String: (d.data()['puntaje'] as num).toInt()};
  }

  static Future<void> resenar({required String tallerId, required int puntaje}) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('resenas').doc('${uid}_$tallerId').set({
      'usuarioId': uid,
      'tallerId': tallerId,
      'puntaje': puntaje,
      'comentario': '',
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  /// Promedio de puntajes y cantidad de reseñas de un taller.
  static Future<(double, int)> puntaje(String tallerId) async {
    final snap = await _db.collection('resenas').where('tallerId', isEqualTo: tallerId).get();
    if (snap.docs.isEmpty) return (0.0, 0);
    final suma = snap.docs.fold<int>(0, (s, d) => s + (d.data()['puntaje'] as num).toInt());
    return (suma / snap.docs.length, snap.docs.length);
  }

  // ---------- Utilidades ----------

  static String _codigo() {
    const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(8, (_) => letras[r.nextInt(letras.length)]).join();
  }

  static bool _datosRevisados = false;

  /// La primera vez que alguien usa la app, carga los 6 talleres de ejemplo
  /// con 6 fechas semanales cada uno. Las reglas de Firestore solo permiten
  /// crear estos documentos puntuales, y nunca modificarlos después.
  static Future<void> _asegurarDatosDeEjemplo() async {
    if (_datosRevisados || _uid == null) return;
    _datosRevisados = true;
    final primero = await _db.collection('talleres').doc(_ejemplos.first['id'] as String).get();
    if (primero.exists) return;

    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final batch = _db.batch();
    for (final t in _ejemplos) {
      final id = t['id'] as String;
      final datos = Map<String, dynamic>.from(t)..remove('id');
      batch.set(_db.collection('talleres').doc(id), datos);
      final hora = switch (t['categoria']) { 'yoga' => 19, 'sonido' => 20, _ => 10 };
      for (var i = 1; i <= 6; i++) {
        final inicio = inicioHoy.add(Duration(days: 3 + (i - 1) * 7, hours: hora));
        batch.set(_db.collection('fechas').doc('$id-$i'), {
          'tallerId': id,
          'inicio': Timestamp.fromDate(inicio),
          'cupoTotal': 8,
          'cupoDisponible': 8,
        });
      }
    }
    try {
      await batch.commit();
    } catch (_) {
      // Si otra persona los cargó al mismo tiempo, no pasa nada.
    }
  }

  static const _ejemplos = <Map<String, Object>>[
    {
      'id': 'torno-principiantes',
      'titulo': 'Torno para principiantes',
      'categoria': 'ceramica',
      'descripcion':
          'Aprendé a centrar el barro y levantar tu primera pieza en el torno. Grupos chicos, mate y música. Tu pieza se hornea y la retirás a las dos semanas.',
      'lugar': 'Barro Estudio',
      'zona': 'Chacras de Coria',
      'precio': 18000,
      'duracionMin': 120,
      'nivel': 'Inicial',
      'materialesIncluidos': true,
      'docente': 'Lucía Ferrer',
      'destacado': true,
    },
    {
      'id': 'yoga-atardecer',
      'titulo': 'Yoga al atardecer',
      'categoria': 'yoga',
      'descripcion':
          'Una práctica suave de hatha yoga al aire libre para cerrar el día. Traé tu mat y abrigo liviano; terminamos con una relajación guiada.',
      'lugar': 'Parque General San Martín',
      'zona': 'Ciudad',
      'precio': 9000,
      'duracionMin': 75,
      'nivel': 'Todos los niveles',
      'materialesIncluidos': false,
      'docente': 'Martín Quiroga',
      'destacado': true,
    },
    {
      'id': 'acuarela-botanica',
      'titulo': 'Acuarela botánica',
      'categoria': 'pintura',
      'descripcion':
          'Observamos hojas y flores de estación y las pintamos con acuarela. Técnicas de capas, transparencias y mezcla de color.',
      'lugar': 'Casa Ocre',
      'zona': 'Ciudad',
      'precio': 14000,
      'duracionMin': 150,
      'nivel': 'Inicial',
      'materialesIncluidos': true,
      'docente': 'Valentina Sosa',
      'destacado': true,
    },
    {
      'id': 'bano-de-sonido',
      'titulo': 'Baño de sonido',
      'categoria': 'sonido',
      'descripcion':
          'Una experiencia de relajación profunda con cuencos tibetanos, gong y tambores oceánicos. Solo tenés que recostarte y escuchar.',
      'lugar': 'Espacio Lumbre',
      'zona': 'Godoy Cruz',
      'precio': 12000,
      'duracionMin': 60,
      'nivel': 'Todos los niveles',
      'materialesIncluidos': true,
      'docente': 'Julieta Arce',
      'destacado': false,
    },
    {
      'id': 'fotografia-analogica',
      'titulo': 'Fotografía analógica',
      'categoria': 'fotografia',
      'descripcion':
          'Salimos a recorrer la ciudad con cámaras de rollo. Aprendés exposición, encuadre y cómo cargar una cámara de 35 mm.',
      'lugar': 'Punto Foco',
      'zona': 'Ciudad',
      'precio': 16000,
      'duracionMin': 180,
      'nivel': 'Inicial',
      'materialesIncluidos': true,
      'docente': 'Tomás Gil',
      'destacado': false,
    },
    {
      'id': 'modelado-a-mano',
      'titulo': 'Modelado a mano',
      'categoria': 'ceramica',
      'descripcion':
          'Técnicas de pellizco, rollos y planchas para crear tazas y cuencos sin torno. Ideal si nunca tocaste arcilla.',
      'lugar': 'Barro Estudio',
      'zona': 'Chacras de Coria',
      'precio': 15000,
      'duracionMin': 120,
      'nivel': 'Inicial',
      'materialesIncluidos': true,
      'docente': 'Lucía Ferrer',
      'destacado': false,
    },
  ];
}
