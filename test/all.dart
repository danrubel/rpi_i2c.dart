import 'package:rpi_i2c/rpi_i2c.dart';
import 'package:test/test.dart';

import 'basic_test.dart' as basic;
import 'mpl3115a2_test.dart' as mpl3115a2;
import 'ttp229_test.dart' as ttp229;

main() {
  final i2c = new RpiI2C();
  group('basic', () => basic.runTests(i2c));
  group('mpl3115a2', () => mpl3115a2.runTests(i2c));
  group('ttp229', () => ttp229.runTests(i2c));
  test('dispose', () => i2c.dispose());
}
