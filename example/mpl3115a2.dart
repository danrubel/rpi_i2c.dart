import 'dart:async';

import 'package:rpi_i2c/i2c.dart';

/// MPL3115A2 - I2C precision pressure sensor with altimetry.
/// See https://www.nxp.com/docs/en/data-sheet/MPL3115A2.pdf
class Mpl3115a2 {
  final I2CDevice device;

  Mpl3115a2(I2C i2c) : device = i2c.device(/* I2C device address */ 0x60) {
    // Sanity check the device
    final whoAmI = device.readByte(0x0C);
    if (whoAmI != 0xC4) {
      throw new I2CException(
          'Expected device identifier 196, but got $whoAmI', device.address);
    }
  }

  /// Take a one-time altitude / pressure / temperature reading
  /// and return a structure containing the resulting values
  /// or `null` if the operation was unsuccessful.
  ///
  /// Either altitude or pressure can be read,
  /// depending upon the altitude parameter, but not both.
  Future<Mpl3115a2Data> read({bool altitude}) async {
    altitude ??= false;

    // Turn on events when new data is ready.
    device.writeByte(/* PT_DATA_CFG */ 0x13, 0x07);

    // Initiate an immediate measurement (OST).
    int ctrlValue = /* OST */ 0x02;
    if (altitude) ctrlValue |= /* ALT */ 0x80;
    device.writeByte(/* CTRL_REG1 */ 0x26, ctrlValue);

    // Collect the data and return the result
    // Set the output mode.
    device.writeByte(/* STATUS */ 0x00, 0x00);

    // Wait for the device to capture current values in the registers.
    int wait = 0;
    while (device.readByte(/* CTRL_REG1 */ 0x26) & /* OST */ 0x02 != 0) {
      if (++wait > 500) {
        return null;
      }
      await new Future.delayed(const Duration(milliseconds: 1));
    }

    return new Mpl3115a2Data._(
      altitude,
      device.readByte(/* OUT_P_MSB */ 0x01),
      device.readByte(/* OUT_P_CSB */ 0x02),
      device.readByte(/* OUT_P_LSB */ 0x03),
      device.readByte(/* OUT_T_MSB */ 0x04),
      device.readByte(/* OUT_T_LSB */ 0x05),
    );
  }
}

/// The data read from [Mpl3115a2] containing temperature
/// and either altitude or pressure but not both.
class Mpl3115a2Data {
  /// The altitude in meters or `null` if the [pressure] was read instead.
  final double altitude;

  /// The pressure in Pascals or `null` if the [altitude] was read instead.
  final double pressure;

  /// The temperature in degrees C.
  final double temperature;

  Mpl3115a2Data._(bool altitudeMode, int outPmsb, int outPcsb, int outPlsb,
      int outTmsb, int outTlsb)
      : altitude = altitudeMode
            ? outPmsb * 256 + outPcsb + (outPlsb >> 4) / 16
            : null /* altitude not read */,
        pressure = altitudeMode
            ? null /* pressure not read */
            : outPmsb * 1024 + outPcsb * 4 + (outPlsb >> 4) / 4,
        temperature = outTmsb + (outTlsb >> 4) / 16;
}
