#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>

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

extern "C" {
  // Return the errno from the last I2C command
  int64_t lastError() {
    return lastErrno;
  }

  // Setup the I2C device at the given address and return the file id.
  // Negative return values indicate an error.
  int64_t setupDevice(int64_t address) {
    //const char *device = "/dev/i2c-0"; // Raspberry Pi 1
    const char *device = "/dev/i2c-1"; // Raspberry Pi 2 + 3

    int fd;
    if ((fd = open(device, O_RDWR)) < 0) {
      lastErrno = errno;
      return -1;
    } else if (ioctl(fd, I2C_SLAVE, address) < 0) {
      close(fd);
      lastErrno = errno;
      return -2;
    }
    lastErrno = 0;
    return fd;
  }

  // Dispose of the I2C device and return 0 to indicate success.
  // Negative return values indicate an error.
  int64_t disposeDevice(int64_t fd) {
    if (close(fd) < 0) {
      lastErrno = errno;
      return -1;
    }
    lastErrno = 0;
    return 0;
  }

  // Read an 8 bit value from a register on the device.
  // Negative return values indicate an error.
  int64_t readByte(int64_t fd, int64_t reg) {
    union i2c_smbus_data data;
    if (i2c_smbus_access(fd, I2C_SMBUS_READ, reg, I2C_SMBUS_BYTE_DATA, &data)) {
      lastErrno = errno;
      return -1;
    }
    lastErrno = 0;
    return data.byte & 0xFF;
  }

  // Read 1 to 32 bytes from the device (not a register on the device).
  // Return the number of bytes read.
  // Negative return values indicate an error.
  int64_t readBytes(int64_t fd, int64_t length, uint8_t *listPtr) {
    return read(fd, listPtr, length);
  }

  // Read a 16 bit value from a register or two consecutive registers on the device.
  // Negative return values indicate an error.
  int64_t readWord(int64_t fd, int64_t reg) {
    union i2c_smbus_data data;
    if (i2c_smbus_access(fd, I2C_SMBUS_READ, reg, I2C_SMBUS_WORD_DATA, &data)) {
      lastErrno = errno;
      return -1;
    }
    lastErrno = 0;
    return data.word & 0xFFFF;
  }

  // Write a byte to the device.
  // Negative return values indicate an error.
  int64_t writeByte(int64_t fd, int64_t reg, int64_t value) {
    union i2c_smbus_data data;
    data.byte = value & 0xFF;
    if (i2c_smbus_access(fd, I2C_SMBUS_WRITE, reg, I2C_SMBUS_BYTE_DATA, &data)) {
      lastErrno = errno;
      return -1;
    }
    lastErrno = 0;
    return 0;
  }
}