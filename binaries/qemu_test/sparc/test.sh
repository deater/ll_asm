#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/sparc32plus-linux-user/qemu-sparc32plus ./ll.sparc.fakeproc.stripped
