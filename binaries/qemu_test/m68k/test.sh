#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/m68k-linux-user/qemu-m68k ./ll.m68k.fakeproc.stripped
