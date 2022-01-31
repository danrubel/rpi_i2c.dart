#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "include/dart_api.h"
#include "include/dart_native_api.h"

Dart_Handle HandleError(Dart_Handle handle) {
  if (Dart_IsError(handle)) {
    Dart_PropagateError(handle);
  }
  return handle;
}

// === from wiringPiI2C.c ===

// I2C definitions

#define I2C_SLAVE       0x0703
#define I2C_SMBUS       0x0720 /* SMBus-level access */

#define I2C_SMBUS_READ  1
#define I2C_SMBUS_WRITE 0

// SMBus transaction types

#define I2C_SMBUS_QUICK             0
#define I2C_SMBUS_BYTE              1
#define I2C_SMBUS_BYTE_DATA         2
#define I2C_SMBUS_WORD_DATA         3
#define I2C_SMBUS_PROC_CALL         4
#define I2C_SMBUS_BLOCK_DATA        5
#define I2C_SMBUS_I2C_BLOCK_BROKEN  6
#define I2C_SMBUS_BLOCK_PROC_CALL   7  /* SMBus 2.0 */
#define I2C_SMBUS_I2C_BLOCK_DATA    8

// SMBus messages

#define I2C_SMBUS_BLOCK_MAX     32 /* As specified in SMBus standard */
#define I2C_SMBUS_I2C_BLOCK_MAX 32 /* Not specified but we use same structure */

// Structures used in the ioctl() calls

union i2c_smbus_data
{
  uint8_t  byte;
  uint16_t word;
  uint8_t  block[I2C_SMBUS_BLOCK_MAX + 2]; // block [0] is used for length + one more for PEC
};

struct i2c_smbus_ioctl_data
{
  char    read_write;
  uint8_t command;
  int     size;
  union   i2c_smbus_data *data;
};

static inline int i2c_smbus_access(int fd, char rw, uint8_t command, int size, union i2c_smbus_data *data)
{
  struct i2c_smbus_ioctl_data args;

  args.read_write = rw;
  args.command    = command;
  args.size       = size;
  args.data       = data;
  return ioctl(fd, I2C_SMBUS, &args);
}

// === end from wiringPiI2C.c ===

// I2C Notes:
// * https://github.com/rm-hull/wiringPi/blob/master/wiringPi/wiringPiI2C.c
// * https://www.kernel.org/doc/Documentation/i2c/dev-interface
// * https://www.kernel.org/doc/Documentation/i2c/smbus-protocol

// The errno from the last I2C command
static volatile int64_t lastErrno = 0;

// Return the errno from the last I2C command
//int _lastError() native "lastError";
void lastError(Dart_NativeArguments arguments) {
  Dart_EnterScope();

  Dart_SetIntegerReturnValue(arguments, lastErrno);
  Dart_ExitScope();
}

// Setup the I2C device at the given address and return the file id.
// Negative return values indicate an error.
//int _setupDevice(int address) native "setupDevice";
void setupDevice(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle arg1 = HandleError(Dart_GetNativeArgument(arguments, 1));

  int64_t address;
  HandleError(Dart_IntegerToInt64(arg1, &address));

  //const char *device = "/dev/i2c-0"; // Raspberry Pi 1
  const char *device = "/dev/i2c-1"; // Raspberry Pi 2 + 3

  int fd;
  int64_t result;

  if ((fd = open(device, O_RDWR)) < 0) {
    result = -1;
    lastErrno = errno;
  } else if (ioctl(fd, I2C_SLAVE, address) < 0) {
    close(fd);
    result = -2;
    lastErrno = errno;
  } else {
    result = fd;
    lastErrno = 0;
  }

  Dart_SetIntegerReturnValue(arguments, result);
  Dart_ExitScope();
}

// Dispose of the I2C device and return 0 to indicate success.
// Negative return values indicate an error.
//int _disposeDevice(int fd) native "disposeDevice";
void disposeDevice(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle arg1 = HandleError(Dart_GetNativeArgument(arguments, 1));

  int64_t fd;
  HandleError(Dart_IntegerToInt64(arg1, &fd));

  int64_t result;
  if (close(fd) < 0) {
    result = -1;
    lastErrno = errno;
  } else {
    result = 0;
    lastErrno = 0;
  }

  Dart_SetIntegerReturnValue(arguments, result);
  Dart_ExitScope();
}

// Read an 8 bit value from a register on the device.
// Negative return values indicate an error.
//int _readByte(int fd, int register) native "readByte";
void readByte(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle arg1 = HandleError(Dart_GetNativeArgument(arguments, 1));
  Dart_Handle arg2 = HandleError(Dart_GetNativeArgument(arguments, 2));

  int64_t fd;
  int64_t reg;
  HandleError(Dart_IntegerToInt64(arg1, &fd));
  HandleError(Dart_IntegerToInt64(arg2, &reg));

  int64_t result = 0;
  union i2c_smbus_data data;
  if (i2c_smbus_access(fd, I2C_SMBUS_READ, reg, I2C_SMBUS_BYTE_DATA, &data)) {
    result = -1;
    lastErrno = errno;
  } else {
    result = data.byte & 0xFF;
    lastErrno = 0;
  }

  Dart_SetIntegerReturnValue(arguments, result);
  Dart_ExitScope();
}

// Read 1 to 32 bytes from the device (not a register on the device).
// Return the number of bytes read.
// Negative return values indicate an error.
//int _readBytes(int fd, List<int> values) native "readBytes";
void readBytes(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle arg1 = HandleError(Dart_GetNativeArgument(arguments, 1));
  Dart_Handle dartList = HandleError(Dart_GetNativeArgument(arguments, 2));

  int64_t fd;
  HandleError(Dart_IntegerToInt64(arg1, &fd));

  int length;
  HandleError(Dart_ListLength(dartList, &length));

  char buf[34];
  int64_t result = read(fd, buf, length);
  for (int index = 0; index < length; ++index) {
    HandleError(Dart_ListSetAt(
      dartList, index, HandleError(Dart_NewInteger(buf[index]))));
  }

  Dart_SetIntegerReturnValue(arguments, result);
  Dart_ExitScope();
}

// Read a 16 bit value from a register or two consecutive registers on the device.
// Negative return values indicate an error.
//int _readWord(int fd, int register) native "readWord";
void readWord(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle arg1 = HandleError(Dart_GetNativeArgument(arguments, 1));
  Dart_Handle arg2 = HandleError(Dart_GetNativeArgument(arguments, 2));

  int64_t fd;
  int64_t reg;
  HandleError(Dart_IntegerToInt64(arg1, &fd));
  HandleError(Dart_IntegerToInt64(arg2, &reg));

  int64_t result = 0;
  union i2c_smbus_data data;
  if (i2c_smbus_access(fd, I2C_SMBUS_READ, reg, I2C_SMBUS_WORD_DATA, &data)) {
    result = -1;
    lastErrno = errno;
  } else {
    result = data.word & 0xFFFF;
    lastErrno = 0;
  }

  Dart_SetIntegerReturnValue(arguments, result);
  Dart_ExitScope();
}

// Write a byte to the device.
// Negative return values indicate an error.
//int _writeByte(int fd, int register, int data) native "writeByte";
void writeByte(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle arg1 = HandleError(Dart_GetNativeArgument(arguments, 1));
  Dart_Handle arg2 = HandleError(Dart_GetNativeArgument(arguments, 2));
  Dart_Handle arg3 = HandleError(Dart_GetNativeArgument(arguments, 3));

  int64_t fd;
  int64_t reg;
  int64_t value;
  HandleError(Dart_IntegerToInt64(arg1, &fd));
  HandleError(Dart_IntegerToInt64(arg2, &reg));
  HandleError(Dart_IntegerToInt64(arg3, &value));

  int64_t result = 0;
  union i2c_smbus_data data;
  data.byte = value & 0xFF;
  if (i2c_smbus_access(fd, I2C_SMBUS_WRITE, reg, I2C_SMBUS_BYTE_DATA, &data)) {
    result = -1;
    lastErrno = errno;
  } else {
    lastErrno = 0;
  }

  Dart_SetIntegerReturnValue(arguments, result);
  Dart_ExitScope();
}

// ===== Infrastructure methods ===============================================

struct FunctionLookup {
  const char* name;
  Dart_NativeFunction function;
};

FunctionLookup function_list[] = {
  {"disposeDevice", disposeDevice},
  {"lastError", lastError},
  {"readByte", readByte},
  {"readBytes", readBytes},
  {"readWord", readWord},
  {"setupDevice", setupDevice},
  {"writeByte", writeByte},
  {NULL, NULL}
};

FunctionLookup no_scope_function_list[] = {
  {NULL, NULL}
};

// Resolve the Dart name of the native function into a C function pointer.
// This is called once per native method.
Dart_NativeFunction ResolveName(Dart_Handle name,
                                int argc,
                                bool* auto_setup_scope) {
  if (!Dart_IsString(name)) {
    return NULL;
  }
  Dart_NativeFunction result = NULL;
  if (auto_setup_scope == NULL) {
    return NULL;
  }

  Dart_EnterScope();
  const char* cname;
  HandleError(Dart_StringToCString(name, &cname));

  for (int i=0; function_list[i].name != NULL; ++i) {
    if (strcmp(function_list[i].name, cname) == 0) {
      *auto_setup_scope = true;
      result = function_list[i].function;
      break;
    }
  }

  if (result != NULL) {
    Dart_ExitScope();
    return result;
  }

  for (int i=0; no_scope_function_list[i].name != NULL; ++i) {
    if (strcmp(no_scope_function_list[i].name, cname) == 0) {
      *auto_setup_scope = false;
      result = no_scope_function_list[i].function;
      break;
    }
  }

  Dart_ExitScope();
  return result;
}

// Initialize the native library.
// This is called once when the native library is loaded.
DART_EXPORT Dart_Handle rpi_i2c_ext_Init(Dart_Handle parent_library) {
  if (Dart_IsError(parent_library)) {
    return parent_library;
  }
  Dart_Handle result_code =
      Dart_SetNativeResolver(parent_library, ResolveName, NULL);
  if (Dart_IsError(result_code)) {
    return result_code;
  }
  return Dart_Null();
}
