#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/arm-linux-user/qemu-arm ./ll.thumb.fakeproc.stripped
