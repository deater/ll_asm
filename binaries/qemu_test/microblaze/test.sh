#!/bin/sh

# Get value for $QEMU
. ../test.include

$QEMU/microblaze-linux-user/qemu-microblaze ./ll.microblaze.fakeproc.stripped
