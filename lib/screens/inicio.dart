import 'package:flutter/material.dart';

import '../datos.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/tarjetas.dart';
import 'detalle.dart';
import 'inicio_shell.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  late Future<(List<Taller>, String)> _carga = _cargar();

  Future<(List<Taller>, String)> _cargar() async {
    final talleres = await Datos.talleres();
    final perfil = await Datos.miPerfil();
    final nombre = (perfil?['nombre'] as String?) ?? '';
    return (talleres, nombre.split(' ').first);
  }

  void _abrir(Taller t) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PantallaDetalle(tallerId: t.id)));

  void _explorar([String? categoria]) {
    categoriaElegida.value = categoria;
    pestanaActiva.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<(List<Taller>, String)>(
        future: _carga,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Aviso(texto: mensajeError(snap.error!), alReintentar: () => setState(() => _carga = _cargar()));
          }
          final (talleres, nombre) = snap.data!;
          final destacados = talleres.where((t) => t.destacado).toList();
          final proximos = talleres.where((t) => t.proximaFecha != null).toList()
            ..sort((a, b) => a.proximaFecha!.inicio.compareTo(b.proximaFecha!.inicio));

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _carga = _cargar());
              await _carga;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mendoza', style: TextStyle(fontSize: 14, color: AppColors.piedra)),
                          Text(nombre.isEmpty ? 'Hola' : 'Hola, $nombre', style: titulo(28)),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.mostaza,
                      child: Text(
                        nombre.isEmpty ? '·' : nombre[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Material(
                  color: AppColors.blanco,
                  shape: const StadiumBorder(side: BorderSide(color: AppColors.borde, width: 1.5)),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: _explorar,
                    child: const SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          SizedBox(width: 16),
                          Icon(Icons.search, color: AppColors.piedra, size: 20),
                          SizedBox(width: 10),
                          Text('Buscar talleres o lugares', style: TextStyle(fontSize: 15, color: AppColors.piedra)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: Categoria.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = Categoria.values[i];
                      return ChipFiltro(texto: c.nombre, activo: false, alTocar: () => _explorar(c.name));
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Destacados de la semana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    TextButton(onPressed: _explorar, child: const Text('Ver todo')),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 256,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: destacados.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => TarjetaTaller(taller: destacados[i], alTocar: () => _abrir(destacados[i])),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Próximamente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (proximos.isEmpty)
                  const Text('No hay fechas cargadas todavía.', style: TextStyle(color: AppColors.piedra)),
                for (final t in proximos.take(4)) ...[
                  FilaTaller(taller: t, alTocar: () => _abrir(t)),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
