# rpi_i2c.dart

[![pub package](https://img.shields.io/pub/v/rpi_i2c.svg)](https://pub.dartlang.org/packages/rpi_ic2)
[![Build Status](https://travis-ci.org/danrubel/rpi_i2c.dart.svg?branch=master)](https://travis-ci.org/danrubel/rpi_i2c.dart)
[![Coverage Status](https://coveralls.io/repos/danrubel/rpi_i2c.dart/badge.svg?branch=master&service=github)](https://coveralls.io/github/danrubel/rpi_i2c.dart?branch=master)

rpi_i2c is a Dart package for using I2C on the Raspberry Pi.

## Overview

 * The [__I2C__](lib/i2c.dart) library provides the API for accessing devices
   using the [I2C protocol](https://en.wikipedia.org/wiki/I%C2%B2C)

 * The [__RpiI2C__](lib/rpi_i2c.dart) library provides implementation of
   the I2C protocol on the Raspberry Pi derived from the [WiringPi](http://wiringpi.com/) library.

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
    pub global run rpi_i2c:build_lib
```

[pub global activate](https://www.dartlang.org/tools/pub/cmd/pub-global.html#activating-a-package)
makes the Dart scripts in the rpi_i2c/bin directory runnable
from the command line.
[pub global run](https://www.dartlang.org/tools/pub/cmd/pub-global.html#running-a-script)
rpi_i2c:build_lib runs the [rpi_i2c/bin/build_lib.dart](bin/build_lib.dart)
program which in turn calls the [build_lib](lib/src/native/build_lib) script
to compile the native librpi_i2c_ext.so library for the rpi_i2c package.

## Example

 * A [Mpl3115a2 example](example/mpl3115a2.dart) demonstrates using the I2C protocol to read altitude,
   pressure, and temperature from a [Mpl3115a2](https://www.nxp.com/docs/en/data-sheet/MPL3115A2.pdf)
