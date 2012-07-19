#!/bin/sh

# Get value for $QEMU
. ./test.include

echo "Testing Alpha..."
cd alpha && $QEMU/alpha-linux-user/qemu-alpha ./ll.alpha.fakeproc.stripped
cd ..
echo "Testing ARM..."
cd arm && $QEMU/arm-linux-user/qemu-arm ./ll.arm.fakeproc.stripped
cd ..
echo "Testing ARM Thumb..."
cd arm_thumb && $QEMU/arm-linux-user/qemu-arm ./ll.thumb.fakeproc.stripped
cd ..
echo "Testing CRIS..."
cd cris && $QEMU/cris-linux-user/qemu-cris ./ll.crisv32.fakeproc.stripped
cd ..
echo "Testing ix86..."
cd i386 && $QEMU/i386-linux-user/qemu-i386 ./ll.i386.fakeproc.stripped
cd ..
echo "Testing m68k..."
cd m68k && $QEMU/m68k-linux-user/qemu-m68k ./ll.m68k.fakeproc.stripped
cd ..
echo "Testing microblaze..."
cd microblaze && $QEMU/microblaze-linux-user/qemu-microblaze ./ll.microblaze.fakeproc.stripped
cd ..
echo "Testing MIPS..."
cd mips && $QEMU/mips-linux-user/qemu-mips ./ll.mips.fakeproc.stripped
cd ..
echo "Testing MIPS Little Endian..."
cd mipsel && $QEMU/mipsel-linux-user/qemu-mipsel ./ll.mipsel.fakeproc.stripped
cd ..
echo "Testing PowerPC..."
cd ppc && $QEMU/ppc-linux-user/qemu-ppc ./ll.ppc.fakeproc.stripped
cd ..
echo "Testing s390..."
cd s390 && $QEMU/s390-linux-user/qemu-s390 ./ll.s390.fakeproc.stripped
cd ..
echo "Testing SH4..."
cd sh4 && $QEMU/sh4-linux-user/qemu-sh4 ./ll.sh3.fakeproc.stripped
cd ..
echo "Testing SPARC..."
cd sparc && $QEMU/sparc32plus-linux-user/qemu-sparc32plus ./ll.sparc.fakeproc.stripped
cd ..
echo "Testing x86_64..."
cd x86_64 && $QEMU/x86_64-linux-user/qemu-x86_64 ./ll.x86_64.fakeproc.stripped

