import 'dart:async';

import 'package:rpi_i2c/rpi_i2c.dart';

import 'mpl3115a2.dart';

main() async {
  final i2c = RpiI2C();
  await readSensor(Mpl3115a2(i2c));
  i2c.dispose();
}

Future readSensor(Mpl3115a2 mpl3115a2) async {

  print('Pressure and temperature:');
  var result = await mpl3115a2.read();
  print('  pressure: ${result.pressure} pascals');
  print('  temperature: ${result.temperature} celsius');

  print('Altitude and temperature:');
  result = await mpl3115a2.read(altitude: true);
  print('  altitude: ${result.altitude} meters');
  print('  temperature: ${result.temperature} celsius');
}
