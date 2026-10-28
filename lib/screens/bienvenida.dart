import 'package:flutter/material.dart';

import '../datos.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/tarjetas.dart';

class Bienvenida extends StatefulWidget {
  const Bienvenida({super.key});

  @override
  State<Bienvenida> createState() => _BienvenidaState();
}

class _BienvenidaState extends State<Bienvenida> {
  bool _esRegistro = true;
  bool _cargando = false;
  final _intereses = <String>{'ceramica', 'yoga'};
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _contrasena = TextEditingController();

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      if (_esRegistro) {
        await Datos.registrarse(
          nombre: _nombre.text.trim(),
          email: _email.text.trim(),
          contrasena: _contrasena.text,
          intereses: _intereses.toList(),
        );
        if (mounted && supabase.auth.currentSession == null) {
          _mostrar('Te enviamos un email para confirmar la cuenta. Después ingresá desde acá.');
          setState(() => _esRegistro = false);
        }
      } else {
        await Datos.ingresar(email: _email.text.trim(), contrasena: _contrasena.text);
      }
    } catch (e) {
      _mostrar(mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrar(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Ilustracion(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Taller', style: titulo(40)),
                    const SizedBox(height: 10),
                    const Text(
                      'Descubrí experiencias creativas cerca tuyo y reservá tu lugar en segundos.',
                      style: TextStyle(fontSize: 17, height: 1.45, color: Color(0xFF4A403A)),
                    ),
                    const SizedBox(height: 24),
                    if (_esRegistro) ...[
                      const Text('¿Qué te interesa?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in Categoria.values)
                            ChipFiltro(
                              texto: c.nombre,
                              activo: _intereses.contains(c.name),
                              alTocar: () => setState(() {
                                _intereses.contains(c.name) ? _intereses.remove(c.name) : _intereses.add(c.name);
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nombre,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá tu nombre' : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Ingresá un email válido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contrasena,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Contraseña'),
                      validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                      onFieldSubmitted: (_) => _enviar(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _cargando ? null : _enviar,
                      child: _cargando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.blanco),
                            )
                          : Text(_esRegistro ? 'Crear cuenta' : 'Ingresar'),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        onPressed: _cargando ? null : () => setState(() => _esRegistro = !_esRegistro),
                        child: Text(_esRegistro ? 'Ya tengo cuenta' : 'Quiero crear una cuenta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ilustracion extends StatelessWidget {
  const _Ilustracion();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(right: -60, top: -80, child: _forma(280, 280, AppColors.arcilla, circulo: true)),
          Positioned(left: 30, bottom: 0, child: _forma(120, 160, AppColors.salvia)),
          Positioned(left: 160, bottom: 0, child: _forma(100, 115, AppColors.mostaza)),
          Positioned(left: 60, top: 60, child: _forma(70, 70, AppColors.lavanda, circulo: true)),
          Positioned(right: 30, bottom: 24, child: _forma(84, 84, AppColors.tinta, circulo: true)),
        ],
      ),
    );
  }

  Widget _forma(double ancho, double alto, Color color, {bool circulo = false}) => Container(
        width: ancho,
        height: alto,
        decoration: BoxDecoration(
          color: color,
          shape: circulo ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circulo ? null : BorderRadius.vertical(top: Radius.circular(ancho / 2)),
        ),
      );
}
