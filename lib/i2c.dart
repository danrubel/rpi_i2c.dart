/// Base I2C interface supported by all I2C implementations.
abstract class I2C {
  final _allocatedAddresses = <int>[];

  /// Check that the address can be used for I2C
  /// and that is has not already been allocated.
  /// This should be called by subclasses not clients.
  void allocateAddress(int address) {
    if (_allocatedAddresses.contains(address)) {
      throw new I2CException('Already allocated', address);
    }
    _allocatedAddresses.add(address);
  }

  /// Return the [I2CDevice] for communicating with the device at [address].
  I2CDevice device(int address);

  /// Call dispose before exiting your application to cleanup native resources.
  void dispose();
}

/// An I2C Device
abstract class I2CDevice {
  final int address;

  I2CDevice(this.address);

  /// Read a byte from register #[register].
  int readByte(int register);

  /// Read [values].length # of bytes from the device (no register)
  /// into [values] where the [values].length is between 1 and 32 inclusive.
  /// Return the # of bytes read.
  int readBytes(List<int> values);

  /// Write a byte to register #[register].
  void writeByte(int register, int value);
}

/// Exceptions thrown by I2C.
class I2CException {
  final String message;
  final int address;
  final int errorNumber;

  I2CException(this.message, [this.address, this.errorNumber]);

  @override
  String toString() {
    String msg = message;
    if (address != null) msg = '$msg, address: $address';
    if (errorNumber != null) msg = '$msg, error: $errorNumber';
    return 'I2CException: $msg';
  }
}
