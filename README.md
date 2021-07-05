# rpi_i2c.dart

[![pub package](https://img.shields.io/pub/v/rpi_i2c.svg)](https://pub.dartlang.org/packages/rpi_i2c)

rpi_i2c is a Dart package for using I2C on the Raspberry Pi.

## Overview

 * The [__I2C__](lib/i2c.dart) library provides the API for accessing devices
   using the [I2C protocol](https://en.wikipedia.org/wiki/I%C2%B2C)

 * The [__RpiI2C__](lib/rpi_i2c.dart) library provides implementation of
   the I2C protocol on the Raspberry Pi derived from the WiringPi library.

## Setup

Be sure to enable I2C on the Raspberry Pi using
```
    sudo raspi-config
```

[__RpiI2C__](lib/rpi_i2c.dart) uses a native library written in C.
For security reasons, authors cannot publish binary content
to [pub.dartlang.org](https://pub.dartlang.org/), so there are some extra
steps necessary to compile the native library on the RPi before this package
can be used. These two steps must be performed when you install and each time
you upgrade the rpi_i2c package.

1) Activate the rpi_i2c package using the
[pub global](https://www.dartlang.org/tools/pub/cmd/pub-global.html) command.
```
    pub global activate rpi_i2c
```

2) From your application directory (the application that references
the rpi_i2c package) run the following command to build the native library
```
    pub global run rpi_i2c:build_native
```

[pub global activate](https://www.dartlang.org/tools/pub/cmd/pub-global.html#activating-a-package)
makes the Dart scripts in the rpi_i2c/bin directory runnable
from the command line.
[pub global run](https://www.dartlang.org/tools/pub/cmd/pub-global.html#running-a-script)
rpi_i2c:build_native runs the [rpi_i2c/bin/build_native.dart](bin/build_native.dart)
program which in turn calls the [build_native](lib/src/native/build_native) script
to compile the native librpi_i2c_ext.so library for the rpi_i2c package.

## Examples

 * [example.dart](example/example.dart) demonstrates instantiating and accessing an I2C device

 * [mpl3115a2.dart](example/mpl3115a2.dart) demonstrates how the I2C API is used
   to interact with a [Mpl3115a2](https://www.nxp.com/docs/en/data-sheet/MPL3115A2.pdf)

 * [example_ttp229.dart](example/example_ttp229.dart) demonstrates instantiating and accessing
   the TTP229 touchpad over I2C

 * [ttp229.dart](example/ttp229.dart) demonstrates how the I2C API is used
   to interact with a [TTP229](See https://www.tontek.com.tw/uploads/product/106/TTP229-LSF_V1.0_EN.pdf) touchpad

Both of these devices can be connected to the I2C bus at the same time.
Connect the following [pins on the Raspberry Pi](https://www.raspberrypi.org/documentation/usage/gpio/)
to pins on the [Adafruit MPL3115A2](https://www.adafruit.com/product/1893)
and pins on the [TTP229 Touchpad](https://robotdyn.com/16-keys-capacitive-touch-ttp229-i2c-module.html)

It is recommended to attach
[two 4.7K pullup resistors](https://learn.sparkfun.com/tutorials/i2c/i2c-at-the-hardware-level),
one to the SDA line and a second to the SDL line,
althrough with some device boards already have pullup resistors on them.
If you have many I2C devices and/or a long I2C bus, you many need a different value
as per [I2C pullup resistor recommendations](https://www.google.com/search?q=i2c+pullup+resistor).

| Rpi Pin              | MPL3115A2 | TTP229    | Pull-up Resistors       |
| -------------------- | --------- |---------- | ----------------------- |
| PIN #1 (3.3v)        | 3V        | 3V        |                         |
| PIN #3 (SDA1 / I2C)  | SDA       | SDA       | 4.7K resistor to 3.3V   |
| PIN #3 (SDL1 / I2C)  | SDL       | SDL       | 4.7K resistor to 3.3V   |
| PIN #6 (GND)         | GND       | GND       |                         |

With thanks to Pierre Henelle for the [RPi_MPL3115A2 library](https://github.com/phenelle/RPi_MPL3115A2)
for wiring and inspiration. In that library's readme, there's a good
[picture of the RPi connected to the MPL3115A2](https://github.com/phenelle/RPi_MPL3115A2#wiring-to-the-pi).
