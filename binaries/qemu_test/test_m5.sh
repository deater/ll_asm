#!/bin/sh

M5=/fusion/research4/vince/m5/m5/build/
CONFIG=/fusion/research4/vince/m5/m5//configs/example/se.py 

echo
echo "********************* Testing Alpha..."
echo
cd alpha && $M5/ALPHA_SE/m5.opt --outdir ../m5_output/alpha $CONFIG -c ./ll.alpha.fakeproc
cd ..
echo
echo "********************* Testing ARM..."
echo
cd arm && $M5/ARM_SE/m5.opt --outdir ../m5_output/arm $CONFIG -c ./ll.arm.fakeproc
cd ..
echo
echo "******************** Testing ARM Thumb..."
echo
cd arm_thumb && $M5/ARM_SE/m5.opt --outdir ../m5_output/thumb $CONFIG -c ./ll.thumb.fakeproc
cd ..
echo
echo "******************** Testing ix86..."
echo
cd i386 && $M5/X86_SE/m5.opt --outdir ../m5_output/x86 $CONFIG -c ./ll.i386.fakeproc
cd ..
echo
echo "******************** Testing MIPS Little Endian..."
echo
cd mipsel && $M5/MIPS_SE/m5.opt --outdir ../m5_output/mipsel $CONFIG -c ./ll.mipsel.fakeproc
cd ..
echo "Testing PowerPC..."
cd ppc && $M5/POWER_SE/m5.opt --outdir ../m5_output/ppc $CONFIG -c ./ll.ppc.fakeproc
cd ..
echo 
echo "******************* Testing SPARC..."
echo
cd sparc && $M5/SPARC_SE/m5.opt --outdir ../m5_output/sparc $CONFIG -c ./ll.sparc.fakeproc
cd ..
echo
echo "******************* Testing x86_64..."
echo
cd x86_64 && $M5/X86_SE/m5.opt --outdir ../m5_output/x86_64 $CONFIG -c  ./ll.x86_64.fakeproc

