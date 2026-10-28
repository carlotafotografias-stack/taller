import 'package:flutter/material.dart';

import '../datos.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/tarjetas.dart';
import 'detalle.dart';
import 'inicio_shell.dart';

enum _Cuando { todas, finde, semana }

class PantallaExplorar extends StatefulWidget {
  const PantallaExplorar({super.key});

  @override
  State<PantallaExplorar> createState() => _PantallaExplorarState();
}

class _PantallaExplorarState extends State<PantallaExplorar> {
  late Future<List<Taller>> _carga = Datos.talleres();
  final _busqueda = TextEditingController();
  String? _categoria;
  _Cuando _cuando = _Cuando.todas;
  bool _soloEconomicos = false;

  @override
  void initState() {
    super.initState();
    _categoria = categoriaElegida.value;
    categoriaElegida.addListener(_alElegirCategoria);
  }

  @override
  void dispose() {
    categoriaElegida.removeListener(_alElegirCategoria);
    _busqueda.dispose();
    super.dispose();
  }

  void _alElegirCategoria() => setState(() => _categoria = categoriaElegida.value);

  List<Taller> _filtrar(List<Taller> todos) {
    final texto = _busqueda.text.trim().toLowerCase();
    final enUnaSemana = DateTime.now().add(const Duration(days: 7));
    return todos.where((t) {
      if (_categoria != null && t.categoria.name != _categoria) return false;
      if (_soloEconomicos && t.precio > 12000) return false;
      if (texto.isNotEmpty &&
          !'${t.titulo} ${t.lugar} ${t.zona} ${t.docente}'.toLowerCase().contains(texto)) {
        return false;
      }
      switch (_cuando) {
        case _Cuando.todas:
          return true;
        case _Cuando.finde:
          return t.fechas.any((f) => esEsteFinde(f.inicio));
        case _Cuando.semana:
          return t.fechas.any((f) => f.inicio.isBefore(enUnaSemana));
      }
    }).toList();
  }

  void _abrir(Taller t) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PantallaDetalle(tallerId: t.id)));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Taller>>(
        future: _carga,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Aviso(
              texto: mensajeError(snap.error!),
              alReintentar: () => setState(() => _carga = Datos.talleres()),
            );
          }
          final resultados = _filtrar(snap.data!);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text('Explorar', style: titulo(28)),
              const SizedBox(height: 14),
              TextField(
                controller: _busqueda,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, lugar o docente',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChipFiltro(
                    texto: 'Todas',
                    activo: _categoria == null,
                    alTocar: () => setState(() => _categoria = null),
                  ),
                  for (final c in Categoria.values)
                    ChipFiltro(
                      texto: c.nombre,
                      activo: _categoria == c.name,
                      alTocar: () => setState(() => _categoria = _categoria == c.name ? null : c.name),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SegmentedButton<_Cuando>(
                segments: const [
                  ButtonSegment(value: _Cuando.todas, label: Text('Todas')),
                  ButtonSegment(value: _Cuando.finde, label: Text('Este finde')),
                  ButtonSegment(value: _Cuando.semana, label: Text('7 días')),
                ],
                selected: {_cuando},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _cuando = s.first),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hasta \$ 12.000', style: TextStyle(fontSize: 15)),
                value: _soloEconomicos,
                onChanged: (v) => setState(() => _soloEconomicos = v),
              ),
              Text(
                resultados.length == 1 ? '1 taller' : '${resultados.length} talleres',
                style: const TextStyle(fontSize: 14, color: AppColors.piedra),
              ),
              const SizedBox(height: 10),
              if (resultados.isEmpty)
                const Aviso(texto: 'No encontramos talleres con esos filtros. Probá con otros.'),
              for (final t in resultados) ...[
                FilaTaller(taller: t, alTocar: () => _abrir(t)),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}
