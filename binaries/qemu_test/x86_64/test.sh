#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/x86_64-linux-user/qemu-x86_64 ./ll.x86_64.fakeproc.stripped

