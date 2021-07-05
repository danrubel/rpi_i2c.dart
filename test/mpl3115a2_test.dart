import 'package:rpi_i2c/i2c.dart';
import '../example/example.dart' show readSensor;
import '../example/mpl3115a2.dart';
import 'package:rpi_i2c/rpi_i2c.dart';
import 'package:test/test.dart';

import 'test_util.dart';

void main() {
  final i2c = RpiI2C();
  runTests(i2c);
  test('dispose', () => i2c.dispose());
}

void runTests(I2C i2c) {
  late Mpl3115a2 mpl3115a2;
  late double lastTemperature;

  test('instantiate once', () async {
    mpl3115a2 = Mpl3115a2(i2c);
    await expectThrows(() => Mpl3115a2(i2c));
  });

  test('read altitude/temperature', () async {
    final result = await mpl3115a2.read(altitude: true);
    expect(result, isNotNull);
    printResult(result);
    expect(result.altitude! > 0.0, isTrue);
    expect(result.pressure, isNull);
    expect(result.temperature > 0.0, isTrue);
    lastTemperature = result.temperature;
  });

  test('read pressure/temperature', () async {
    final result = await mpl3115a2.read();
    expect(result, isNotNull);
    printResult(result);
    expect(result.altitude, isNull);
    expect(result.pressure! > 0.0, isTrue);
    expect(result.temperature > 0.0, isTrue);
    expect((result.temperature - lastTemperature).abs() < 0.5, isTrue);
  });

  test('example', () async {
    await readSensor(mpl3115a2);
  });
}

void printResult(Mpl3115a2Data result) {
  if (result.altitude != null) {
    print('  altitude: ${result.altitude} meters');
  }
  if (result.pressure != null) {
    print('  pressure: ${result.pressure} pascals');
  }
  print('  temperature: ${result.temperature} celsius');
}
