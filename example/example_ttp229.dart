import 'dart:async';
import 'dart:io';

import 'package:rpi_i2c/rpi_i2c.dart';

import 'ttp229.dart';

main() async {
  final i2c = new RpiI2C();
  await readTouchPad(new Ttp229(i2c));
  i2c.dispose();
}

Future readTouchPad(Ttp229 touchpad) async {
  StreamSubscription<ProcessSignal> subscription;
  bool running = true;

  print('------ press ctrl-c to exit ------');
  subscription = ProcessSignal.sigint.watch().listen((_) {
    running = false;
    subscription.cancel();
  });

  // This example continually polls the touch pad.
  // A better approach would be to
  // 1) connect the TTP229 SDO pin to one of the RPi's GPIO pins,
  // 2) use the rpi_gpio package to watch that pin, and
  // 3) read the touchpad when that pin's state changes.

  Ttp229Keys lastKeys;
  while (running) {
    Ttp229Keys keys = touchpad.keysPressed;
    if (lastKeys != keys) {
      lastKeys = keys;
      printKeys(keys);
    }
    await new Future.delayed(new Duration(milliseconds: 500));
  }
}

void printKeys(Ttp229Keys keys) {
  final buf = new StringBuffer();
  for (int index = 0; index < 16; ++index) {
    if (keys.key(index)) {
      if (buf.isNotEmpty) buf.write(', ');
      buf.write('key ${index + 1}');
    }
  }
  print(buf.isEmpty ? 'no keys pressed' : buf.toString());
}
