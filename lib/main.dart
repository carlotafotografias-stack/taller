import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/bienvenida.dart';
import 'screens/inicio_shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const TallerApp());
}

class TallerApp extends StatelessWidget {
  const TallerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taller',
      debugShowCheckedModeBanner: false,
      theme: construirTema(),
      // En pantallas anchas (computadora) la app se muestra centrada
      // con el ancho de un celular, como en el diseño.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFE9E1D4),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
      home: const ControlDeSesion(),
    );
  }
}

/// Muestra la bienvenida si no hay sesión, o la app si el usuario ya ingresó.
class ControlDeSesion extends StatelessWidget {
  const ControlDeSesion({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        final haySesion = auth.currentSession != null;
        return haySesion ? const InicioShell() : const Bienvenida();
      },
    );
  }
}
