#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/i386-linux-user/qemu-i386 ./ll.i386.fakeproc.stripped
