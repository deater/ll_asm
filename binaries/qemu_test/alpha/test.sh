#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/alpha-linux-user/qemu-alpha ./ll.alpha.fakeproc.stripped

