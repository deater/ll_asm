#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/cris-linux-user/qemu-cris ./ll.crisv32.fakeproc.stripped


