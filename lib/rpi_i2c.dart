import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart' as ffi;
import 'package:path/path.dart';
import 'package:rpi_i2c/i2c.dart';

/// The [I2C] interface used for accessing I2C devices on the Raspberry Pi.
class RpiI2C extends I2C {
  static bool _instantiatedI2C = false;

  final _devices = <RpiI2CDevice>[];
  final _dylib = _RpiI2CDynamicLibrary(_findDynamicLibrary());

  RpiI2C() {
    if (_instantiatedI2C) throw I2CException('RpiI2C already instantiated');
    _instantiatedI2C = true;
  }

  @override
  I2CDevice device(int address) {
    allocateAddress(address);
    var fd = _dylib.setupDevice(address);
    if (fd < 0) throw I2CException('device init failed: $fd');
    final device = RpiI2CDevice(address, fd, _dylib);
    _devices.add(device);
    return device;
  }

  @override
  void dispose() {
    while (_devices.isNotEmpty) {
      var result = _dylib.disposeDevice(_devices.removeLast()._fd);
      if (result != 0) throw I2CException('dispose failed: $result');
    }
  }
}

class RpiI2CDevice extends I2CDevice {
  final int _fd;
  final _RpiI2CDynamicLibrary _dylib;

  RpiI2CDevice(int address, this._fd, this._dylib) : super(address);

  @override
  int readByte(int register) =>
      _throwIfNegative(_dylib.readByte(_fd, register));

  @override
  int readWord(int register) =>
      _throwIfNegative(_dylib.readWord(_fd, register));

  @override
  int readBytes(List<int> values) {
    if (values.isEmpty || values.length > 32)
      throw I2CException('Expected values length between 1 and 32', address);
    var buf = _dylib.byteBufferOfLen34;
    var numBytesRead =
        _throwIfNegative(_dylib.readBytes(_fd, values.length, buf));
    for (var index = 0; index < numBytesRead; index++) {
      values[index] = buf.elementAt(index).value;
    }
    return numBytesRead;
  }

  @override
  void writeByte(int register, int value) {
    _throwIfNegative(_dylib.writeByte(_fd, register, value));
  }

  /// Throw an exception if [value] is less than zero, else return [value].
  int _throwIfNegative(int value) {
    if (value < 0)
      throw I2CException(
          'operation failed: $value', address, _dylib.lastError());
    return value;
  }
}

class _RpiI2CDynamicLibrary {
  final _SetupDevice setupDevice;
  final _DisposeDevice disposeDevice;

  final _LastError lastError;
  final _ReadByte readByte;
  final _ReadBytes readBytes;
  final _ReadWord readWord;
  final _WriteByte writeByte;

  final byteBufferOfLen34 = ffi.malloc.allocate<ffi.Uint8>(34);

  _RpiI2CDynamicLibrary(ffi.DynamicLibrary dylib)
      : setupDevice = dylib
            .lookup<
                ffi.NativeFunction< //
                    ffi.Int64 Function(ffi.Int64)>>('setupDevice')
            .asFunction<_SetupDevice>(),
        disposeDevice = dylib
            .lookup<
                ffi.NativeFunction< //
                    ffi.Int64 Function(ffi.Int64)>>('disposeDevice')
            .asFunction<_DisposeDevice>(),
        lastError = dylib
            .lookup<ffi.NativeFunction<ffi.Int64 Function()>>('lastError')
            .asFunction<_LastError>(),
        readByte = dylib
            .lookup<
                ffi.NativeFunction<
                    ffi.Int64 Function(ffi.Int64, ffi.Int64)>>('readByte')
            .asFunction<_ReadByte>(),
        readBytes = dylib
            .lookup<
                ffi.NativeFunction<
                    ffi.Int64 Function(ffi.Int64, ffi.Int64,
                        ffi.Pointer<ffi.Uint8>)>>('readBytes')
            .asFunction<_ReadBytes>(),
        readWord = dylib
            .lookup<
                ffi.NativeFunction<
                    ffi.Int64 Function(ffi.Int64, ffi.Int64)>>('readWord')
            .asFunction<_ReadWord>(),
        writeByte = dylib
            .lookup<
                ffi.NativeFunction<
                    ffi.Int64 Function(
                        ffi.Int64, ffi.Int64, ffi.Int64)>>('writeByte')
            .asFunction<_WriteByte>();
}

typedef _SetupDevice = int Function(int address);
typedef _DisposeDevice = int Function(int fd);

typedef _LastError = int Function();
typedef _ReadByte = int Function(int fd, int register);
typedef _ReadBytes = int Function(
    int fd, int numValuesToRead, ffi.Pointer<ffi.Uint8> values);
typedef _ReadWord = int Function(int fd, int register);
typedef _WriteByte = int Function(int fd, int register, int data);

const _pkgName = 'rpi_i2c';

ffi.DynamicLibrary _findDynamicLibrary() {
  String libName;
  if (Platform.isLinux) {
    libName = 'lib${_pkgName}_ext.so';
  } else {
    // Windows: Debug\${_pkgName}_ext.dll
    // MacOS:   lib${_pkgName}_ext.dylib
    throw 'Unsupported OS: ${Platform.operatingSystem}';
  }

  var pkgRootDir = findPkgRootDir(File.fromUri(Platform.script).parent);
  var libPath = join(pkgRootDir.path, 'lib', 'src', 'native', libName);
  if (!File(libPath).existsSync()) throw 'failed to find $libPath';
  return ffi.DynamicLibrary.open(libPath);
}

/// Find the package root directory
Directory findPkgRootDir(Directory appDir) {
  // Find the app root dir containing the pubspec.yaml
  while (true) {
    if (File(join(appDir.path, 'pubspec.yaml')).existsSync()) break;
    var parentDir = appDir.parent;
    if (parentDir.path == appDir.path)
      throw 'Failed to find application directory '
          'containing the pubspec.yaml file starting from ${Platform.script}';
    appDir = parentDir;
  }

  // Load the package configuration information
  var pkgConfigFile =
      File(join(appDir.path, '.dart_tool', 'package_config.json'));
  if (!pkgConfigFile.existsSync())
    throw 'Failed to find ${pkgConfigFile.path}'
        '\nPlease be sure to run pub get in ${appDir.path}';
  var pkgConfig =
      jsonDecode(pkgConfigFile.readAsStringSync()) as Map<String, dynamic>;
  var pkgList = pkgConfig['packages'] as List;

  // Determine the location of the package being used
  var pkgInfo = pkgList.firstWhere((info) => (info as Map)['name'] == _pkgName,
      orElse: () => throw 'Failed to find $_pkgName in ${pkgConfigFile.path}'
          '\nPlease be sure that the pubspec.yaml contains $_pkgName, then re-run pub get');
  var pkgPath = pkgInfo['rootUri'] as String;
  return Directory.fromUri(pkgConfigFile.uri.resolve(pkgPath));
}
