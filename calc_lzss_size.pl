#!/usr/bin/env perl

while (<>){
  /^([0-9a-f]+) <([a-z_]+)>:$/ and $adr{$2}=hex $1;
}

$n = $adr{done_logo} - $adr{decompression_loop};
print "lzss code size = $n\n";
