import 'package:rpi_i2c/i2c.dart';

/// TSL2561 Ambient Light Sensor
/// See https://ams.com/en/tsl2561
/// which is in the Grove Digital Light Sensor v1.1
class Tsl2561 {
  final I2CDevice device;

  /// The I2C device address depends upon the state of "address select" pin:
  /// GND    0101001  0x29
  /// Float  0111001  0x39
  /// VDD    1001001  0x49
  Tsl2561(I2C i2c) : device = i2c.device(/* I2C device address */ 0x29) {
    // After applying VDD, the device will initially be in the
    // power-down state. To operate the device,
    // issue a command to access the Control Register
    // followed by the data value 03h to power up the device.

    // Power up
    device.writeByte(0x80, 0x03);

    // At this point, both ADC channels will begin
    // a conversion at the default integration time of 400ms.
    // After 400ms, the conversion results will be available
    // in the DATA0 and DATA1 registers.

    // Sanity check the device
    final idRegValue = device.readByte(0x8A);
    final partNum = idRegValue >> 4;
    final revNum = idRegValue & 0xFF;
    if (partNum != 5) {
      throw I2CException(
        'Expected device identifier 5, but got $partNum ($idRegValue)',
        device.address,
      );
    }
    print('TSL 2651 at ${device.address} rev $revNum');
  }

  int readCh0() => device.readWord(0xAC);
  int readCh1() => device.readWord(0xAE);
}
