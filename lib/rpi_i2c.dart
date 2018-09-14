import 'package:rpi_i2c/i2c.dart';

import 'dart-ext:rpi_i2c_ext';

/// The [I2C] interface used for accessing I2C devices on the Raspberry Pi.
class RpiI2C extends I2C {
  static bool _instantiatedI2C = false;

  final _devices = <RpiI2CDevice>[];

  RpiI2C() {
    if (_instantiatedI2C) throw new I2CException('RpiI2C already instantiated');
    _instantiatedI2C = true;
  }

  @override
  I2CDevice device(int address) {
    allocateAddress(address);
    int fd = _setupDevice(address);
    if (fd < 0) throw new I2CException('device init failed: $fd');
    final device = new RpiI2CDevice(address, fd);
    _devices.add(device);
    return device;
  }

  @override
  void dispose() {
    while (_devices.isNotEmpty) {
      int result = _disposeDevice(_devices.removeLast()._fd);
      if (result != 0) throw new I2CException('dispose failed: $result');
    }
  }

  int _setupDevice(int address) native "setupDevice";
  int _disposeDevice(int fd) native "disposeDevice";
}

class RpiI2CDevice extends I2CDevice {
  final int _fd;

  RpiI2CDevice(int address, this._fd) : super(address);

  @override
  int readByte(int register) => _throwIfNegative(_readByte(_fd, register));

  @override
  int writeByte(int register, int data) =>
      _throwIfNegative(_writeByte(_fd, register, data));

  /// Throw an exception if [value] is less than zero, else return [value].
  int _throwIfNegative(int value) {
    if (value < 0) throw new I2CException('operation failed: $value', address);
    return value;
  }

  int _readByte(int fd, int register) native "readByte";
  int _writeByte(int fd, int register, int data) native "writeByte";
}
