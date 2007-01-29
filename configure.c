#include <stdio.h>

#include <string.h>      /* strncpy */
#include <sys/utsname.h> /* uname   */
#include <stdlib.h>      /* system  */

#include "arch.h"

char *arch_names[]={
       "Unknown",
         "alpha",
         "arm",
         "cris",
         "ia64",
         "ix86",
         "m68k",
         "mips",
         "parisc",
         "ppc",
         "s390",
         "sh3",
         "sparc",
         "vax"
};



int main(int argc, char **argv) {
 
    struct utsname buf;
    char temp_string[256],arch[65];
    int command_override=0;

    if (argc>1) {
       command_override=1;
    }
   
    uname(&buf);
   
    sprintf(temp_string,"rm -f ll.s");
    system(temp_string);


    strncpy(arch,arch_names[linux_detect_arch()],63);   
    printf("+ compiling for %s architecture\n",arch);
  
    sprintf(temp_string,"ln -n -s ll.%s.s ll.s",arch);
    system(temp_string);    
   
    return 0;
}
