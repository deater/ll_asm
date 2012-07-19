#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/sh4-linux-user/qemu-sh4 ./ll.sh3.fakeproc.stripped
