import 'package:flutter_test/flutter_test.dart';
import 'package:taller/utils.dart';

void main() {
  test('formatea precios con punto de miles', () {
    expect(precio(18000), '\$ 18.000');
    expect(precio(900), '\$ 900');
  });

  test('formatea duraciones', () {
    expect(duracion(120), '2 h');
    expect(duracion(75), '1 h 15');
    expect(duracion(45), '45 min');
  });
}
