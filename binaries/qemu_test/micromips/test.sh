#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/mips-linux-user/qemu-mips -cpu M14Kc ./ll.mips.fakeproc.stripped

