#include <stdio.h>

#include <string.h>      /* strncpy */
#include <sys/utsname.h> /* uname   */
#include <stdlib.h>      /* system  */

#include "arch.h"

int linux_detect_arch(void) {
 
    /* Yes this is a bit messy, but it cleans up the makefile a bit *\
    \* The C-Preproccessor can be out friend ;)                     */

/*   return ARCH_SPARC;  */
      
#if defined(__alpha__)
   return ARCH_ALPHA;   
#elif defined(__arm__)
    return ARCH_ARM;
#elif defined(__cris__)
    return ARCH_CRIS;
#elif defined(__ia64__)
    return ARCH_IA64;
#elif defined(i386)
    return ARCH_IX86;
#elif (defined(mc68000) || #cpu(m68k))
    return ARCH_M68K;
#elif defined(__mips__)
    return ARCH_MIPS;
#elif defined(__parisc__)
    return ARCH_PARISC;
#elif defined(__PPC__)
    return ARCH_PPC;
#elif defined(__s390__)
    return ARCH_S390;
#elif defined(__sh3__) || defined(__sh2__) || defined(__sh4)
    return ARCH_SH3  
#elif defined(__sparc__)
    return ARCH_SPARC;
#elif defined(__vax__)
    return ARCH_VAX;
#else
    return ARCH_UNKNOWN;
#endif 

}

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
