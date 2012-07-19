#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/mips-linux-user/qemu-mips ./ll.mips.fakeproc.stripped

