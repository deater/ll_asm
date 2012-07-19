#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/mipsel-linux-user/qemu-mipsel ./ll.mipsel.fakeproc.stripped
