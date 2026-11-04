const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _diasLargos = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
const _mesesLargos = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// 18000 → "$ 18.000"
String precio(int valor) {
  final texto = valor.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
  return '\$ $texto';
}

String _dosDigitos(int n) => n.toString().padLeft(2, '0');

String hora(DateTime f) => '${_dosDigitos(f.hour)}:${_dosDigitos(f.minute)}';

/// "Sáb 15 nov · 10:00"
String fechaCorta(DateTime f) => '${_dias[f.weekday - 1]} ${f.day} ${_meses[f.month - 1]} · ${hora(f)}';

/// "Sábado 15 de noviembre · 10:00"
String fechaLarga(DateTime f) =>
    '${_diasLargos[f.weekday - 1]} ${f.day} de ${_mesesLargos[f.month - 1]} · ${hora(f)}';

String diaSemana(DateTime f) => _dias[f.weekday - 1].toUpperCase();

String duracion(int minutos) {
  final h = minutos ~/ 60;
  final m = minutos % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h $m';
}

bool esEsteFinde(DateTime f) {
  final hoy = DateTime.now();
  final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
  late final DateTime desde;
  late final DateTime hasta;
  if (hoy.weekday == DateTime.sunday) {
    desde = inicioHoy;
    hasta = inicioHoy.add(const Duration(days: 1));
  } else {
    desde = inicioHoy.add(Duration(days: DateTime.saturday - hoy.weekday));
    hasta = desde.add(const Duration(days: 2));
  }
  return !f.isBefore(desde) && f.isBefore(hasta);
}

/// Traduce los errores más comunes de Firebase a mensajes claros.
String mensajeError(Object e) {
  final t = e.toString();
  // Códigos de error de Firebase Authentication y Firestore.
  if (t.contains('invalid-credential') || t.contains('wrong-password') || t.contains('user-not-found')) {
    return 'El email o la contraseña no son correctos.';
  }
  if (t.contains('email-already-in-use')) return 'Ya existe una cuenta con ese email.';
  if (t.contains('weak-password')) return 'La contraseña tiene que tener al menos 6 caracteres.';
  if (t.contains('invalid-email')) return 'El email no es válido.';
  if (t.contains('too-many-requests')) return 'Demasiados intentos. Esperá unos minutos e intentá de nuevo.';
  if (t.contains('operation-not-allowed')) {
    return 'El inicio de sesión con email no está activado en Firebase (Authentication › Sign-in method).';
  }
  if (t.contains('unauthorized-domain')) {
    return 'Este sitio no está autorizado en Firebase (Authentication › Configuración › Dominios autorizados).';
  }
  if (t.contains('No hay cupos')) return 'No quedan cupos suficientes para esa fecha.';
  if (t.contains('Esa fecha ya pasó')) return 'Esa fecha ya pasó. Elegí otra.';
  // Para errores de red o desconocidos mostramos también el detalle técnico,
  // así es posible saber qué falló.
  final detalle = t.length > 160 ? '${t.substring(0, 160)}…' : t;
  if (t.contains('network-request-failed') || t.contains('unavailable')) {
    return 'No se pudo conectar con el servidor. Revisá internet.\nDetalle: $detalle';
  }
  if (t.contains('permission-denied')) {
    return 'Firebase no permitió esta acción (revisá las reglas de Firestore).\nDetalle: $detalle';
  }
  return 'Algo salió mal.\nDetalle: $detalle';
}
