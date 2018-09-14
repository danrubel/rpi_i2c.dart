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

  /// Write a byte to register #[register].
  int writeByte(int register, int data);
}

/// Exceptions thrown by I2C.
class I2CException {
  final String message;
  final int address;

  I2CException(this.message, [this.address]);

  @override
  String toString() => address != null ? '$message address: $address' : message;
}
