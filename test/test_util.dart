import 'package:rpi_i2c/i2c.dart';
import 'package:test/test.dart';

expectThrows(f()) async {
  try {
    await f();
    fail('expected exception');
  } on I2CException {
    // Expected... fall through
  }
}
