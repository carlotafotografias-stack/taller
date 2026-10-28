import 'package:flutter/material.dart';

import 'explorar.dart';
import 'inicio.dart';
import 'mis_reservas.dart';
import 'perfil.dart';

/// Pestaña activa de la barra inferior. Otras pantallas la cambian
/// (por ejemplo, "Ver mis reservas" después de confirmar).
final pestanaActiva = ValueNotifier<int>(0);

/// Categoría elegida desde Inicio para abrir Explorar ya filtrado.
final categoriaElegida = ValueNotifier<String?>(null);

void irAPestana(BuildContext context, int indice) {
  Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  pestanaActiva.value = indice;
}

class InicioShell extends StatelessWidget {
  const InicioShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: pestanaActiva,
      builder: (context, indice, _) => Scaffold(
        body: IndexedStack(
          index: indice,
          children: const [
            PantallaInicio(),
            PantallaExplorar(),
            PantallaMisReservas(),
            PantallaPerfil(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: indice,
          onDestinationSelected: (i) => pestanaActiva.value = i,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Explorar'),
            NavigationDestination(
                icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Reservas'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
