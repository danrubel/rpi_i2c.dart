import 'dart:async';

import 'package:rpi_i2c/rpi_i2c.dart';

import 'mpl3115a2.dart';

main() async {
  await readSensor(new Mpl3115a2(new RpiI2C()));
}

Future readSensor(Mpl3115a2 mpl3115a2) async {
  Mpl3115a2Data result;

  print('Pressure and temperature:');
  result = await mpl3115a2.read();
  print('  pressure: ${result.pressure} pascals');
  print('  temperature: ${result.temperature} celsius');

  print('Altitude and temperature:');
  result = await mpl3115a2.read(altitude: true);
  print('  altitude: ${result.altitude} meters');
  print('  temperature: ${result.temperature} celsius');
}
