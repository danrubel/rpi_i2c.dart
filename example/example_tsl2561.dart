import 'dart:async';

import 'package:rpi_i2c/rpi_i2c.dart';

import 'tsl2561.dart';

main() async {
  final i2c = RpiI2C();
  var lightSensor = Tsl2561(i2c);

  // Wait for valid data after the TSL 2561 has powered up
  await Future.delayed(const Duration(milliseconds: 420));

  for (var count = 0; count < 10; ++count) {
    await readSensor(lightSensor);
    await Future.delayed(const Duration(milliseconds: 500));
  }
  i2c.dispose();
}

Future readSensor(Tsl2561 lightSensor) async {
  var ch0 = lightSensor.readCh0().toString().padLeft(5);
  var ch1 = lightSensor.readCh1().toString().padLeft(5);
  print('light sensor channel 0: $ch0, channel 1: $ch1');
}
