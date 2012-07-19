#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/arm-linux-user/qemu-arm ./ll.arm.fakeproc.stripped
$QEMU/arm-linux-user/qemu-arm ./ll.arm.eabi.fakeproc.stripped
