import 'package:flutter/material.dart';

import '../datos.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/tarjetas.dart';
import 'inicio_shell.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  late Future<Map<String, dynamic>?> _carga = Datos.miPerfil();
  Set<String>? _intereses;

  Future<void> _alternar(String categoria) async {
    final nuevos = {...?_intereses};
    nuevos.contains(categoria) ? nuevos.remove(categoria) : nuevos.add(categoria);
    setState(() => _intereses = nuevos);
    try {
      await Datos.guardarIntereses(nuevos.toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensajeError(e))));
    }
  }

  Future<void> _salir() async {
    pestanaActiva.value = 0;
    await Datos.salir();
  }

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? '';
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _carga,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Aviso(texto: mensajeError(snap.error!), alReintentar: () => setState(() => _carga = Datos.miPerfil()));
          }
          final perfil = snap.data;
          final nombre = (perfil?['nombre'] as String?) ?? '';
          _intereses ??= {...((perfil?['intereses'] as List?) ?? []).cast<String>()};

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text('Perfil', style: titulo(28)),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.mostaza,
                    child: Text(nombre.isEmpty ? '·' : nombre[0].toUpperCase(),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.tinta)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre.isEmpty ? 'Sin nombre' : nombre,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(email, style: const TextStyle(fontSize: 14, color: AppColors.piedra)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text('Mis intereses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in Categoria.values)
                    ChipFiltro(
                      texto: c.nombre,
                      activo: _intereses!.contains(c.name),
                      alTocar: () => _alternar(c.name),
                    ),
                ],
              ),
              const SizedBox(height: 36),
              OutlinedButton(onPressed: _salir, child: const Text('Cerrar sesión')),
            ],
          );
        },
      ),
    );
  }
}
