import 'package:rpi_i2c/i2c.dart';
import '../example/ttp229.dart';
import 'package:rpi_i2c/rpi_i2c.dart';
import 'package:test/test.dart';

import 'test_util.dart';

main() {
  final i2c = new RpiI2C();
  runTests(i2c);
  test('dispose', () => i2c.dispose());
}

runTests(I2C i2c) {
  Ttp229 ttp229;

  test('instantiate once', () async {
    ttp229 = new Ttp229(i2c);
    await expectThrows(() => new Ttp229(i2c));
  });

  test('read bytes', () async {
    final values = new List<int>(2);
    final count = ttp229.device.readBytes(values);
    expect(count, 2);
    expect(values[0], 0);
    expect(values[1], 0);
  });
}
