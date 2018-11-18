import 'package:rpi_i2c/i2c.dart';

/// TTP229-LSF - I2C touch pad detector.
/// See http://www.tontek.com.tw/uploads/product/106/TTP229-LSF_V1.0_EN.pdf
class Ttp229 {
  final I2CDevice device;

  Ttp229(I2C i2c) : device = i2c.device(/* I2C device address */ 0x57);

  Ttp229Keys get keysPressed {
    List<int> bytes = new List<int>(2);
    int count = device.readBytes(bytes);
    if (count != 2)
      throw I2CException(
          'Expected 2 bytes read, but was $count', device.address);
    return new Ttp229Keys(bytes);
  }
}

class Ttp229Keys {
  final List<int> bytes;

  Ttp229Keys(this.bytes);

  @override
  bool operator ==(other) {
    if (other is Ttp229Keys) {
      return bytes[0] == other.bytes[0] && bytes[1] == other.bytes[1];
    } else {
      return false;
    }
  }

  @override
  int get hashCode => bytes[1] << 8 + bytes[0];

  /// True if the key at the specified index is pressed,
  /// where key #1 is at index 0.
  bool key(int index) {
    if (index < 0 || 15 < index) throw 'index out of bounds: $index';
    int bits = bytes[index ~/ 8];
    return (bits & (1 << (7 - index % 8))) != 0;
  }
}
