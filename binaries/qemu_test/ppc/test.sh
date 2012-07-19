#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/ppc-linux-user/qemu-ppc ./ll.ppc.fakeproc.stripped
