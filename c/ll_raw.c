/* This code implements ll in C code using the c library */
/* Note!  This only will work on x86.  It has endianess  */
/*        dependencies, and makes assumptions about the  */
/*        layout of the /proc/cpuinfo file!              */

#include "../logo.lzss_new.h"

#define SYSCALL_EXIT               1
#define SYSCALL_READ               3
#define SYSCALL_WRITE              4
#define SYSCALL_OPEN               5
#define SYSCALL_CLOSE              6
#define SYSCALL_SYSINFO            116
#define SYSCALL_UNAME              122

long __res;

unsigned int r,shift_count,bit_set;
unsigned short out_count,pos;
unsigned char mask,out_byte;
unsigned char *logo_pointer,*out_pointer,*disk_pointer;
unsigned char out_buffer[16384],text_buf[(N+F)-1],disk_buffer[4096];

struct utsname {
           char sysname[65];
           char nodename[65];
           char release[65];
           char version[65];
           char machine[65];
           char domainname[65];
} uname_info;


int fd,cpu_count,temp;

struct sysinfo {
   long uptime;             /* Seconds since boot */
   unsigned long loads[3];  /* 1, 5, and 15 minute load averages */
   unsigned long totalram;  /* Total usable main memory size */
   unsigned long freeram;   /* Available memory size */
   unsigned long sharedram; /* Amount of shared memory */
   unsigned long bufferram; /* Memory used by buffers */
   unsigned long totalswap; /* Total swap space size */
   unsigned long freeswap;  /* swap space still available */
   unsigned short procs;    /* Number of current processes */
   unsigned long totalhigh; /* Total high memory size */
   unsigned long freehigh;  /* Available high memory size */
   unsigned int mem_unit;   /* Memory unit size in bytes */
   unsigned char _f[20-2*sizeof(long)-sizeof(int)]; /* Padding for libc5 */
} sysinfo_buff;



char ordinal[4][6]={"One","Two","Three","Four"};


static int vmw_strlen(char *string) {
   int size=0;
   while(string[size++]!=0) ;
   return size-1;
}

static void vmw_strcat(char *string) {
   
   while( (*out_pointer++=*string++)) ;
   out_pointer--;
}

   /* Write a string to stdout */
static void write_stdout(char *string) {
      int length;
   
      length=vmw_strlen(string);
   
      /* stdout is fd 1 */
   
      __asm__ volatile ("push %%ebx\t\n"
			"movl %2,%%ebx\t\n"
			"int $0x80\t\n"
			"pop %%ebx\t\n" 
                     : "=a" (__res) 
                     : "0" (SYSCALL_WRITE),
		       "ri" ((long)(1)),
		       "c" ((long)(string)), 
                       "d" ((long)(length))
                     : "memory"); 
}

     /* find the 4 ascii bytes in pattern.  Then skip to : then skip spaces */
     /* then copy the string found to the end of out_pointer, stopping at   */
     /* the stop character or \n                                            */
static void find_string(unsigned int pattern,unsigned char stop,int skip_spaces) {

   unsigned char ch;

   if (!skip_spaces) {
	 
      disk_pointer=disk_buffer;

         /* Find pattern */
      while(1) {
         temp=*((int *)(disk_pointer));
         if (temp==pattern) break;
         if (temp==0) return;
         disk_pointer++;
      }
   
         /* skip to after a colon */
      while(*disk_pointer++!=':') ;
    
         /* skip to after any spaces */
      while(*disk_pointer++==' ') ;
      disk_pointer--;
   }
   
        /* copy from the disk buffer to the output buffer */
   do {
      ch=*out_pointer++=*disk_pointer++;
   } while((ch!=stop) && (ch!='\n'));
   
        /* Null terminate the result */
   *--out_pointer=0;
   
}

char ascii_buff[8];
char *ascii_pointer;

   /* convert an integer to an ascii string */
static char *num_to_ascii(unsigned int num) {

   unsigned int q,r,temp;

   temp=num;
   ascii_pointer=ascii_buff+7;
   
   /* do loop so we print "0" properly */
   do {      
      q=temp/10;
      r=temp%10;
      
      *--ascii_pointer=r+0x30;      /* convert to ASCII */
      temp=q;
   } while(temp);

   return ascii_pointer;
}

   /* center and print a string */
static void center_and_print() {
   int length;
   
   length=vmw_strlen((char *)out_buffer);
   if (length<80) {
      write_stdout("\033[");
      write_stdout(num_to_ascii((80-length)/2));
      write_stdout("C");
   }
   write_stdout((char *)out_buffer);   
}


int _start() {
  
   /* do LZSS decryption */
   
   r=(N-F);
   logo_pointer=logo;
   out_pointer=out_buffer;
   
   while(logo_pointer<(logo+sizeof(logo)) ) {
            
      shift_count=0;
      mask=(*logo_pointer++);

      while(shift_count<8) {
      
	 if (logo_pointer>=(logo+sizeof(logo)) ) break;
	 
         bit_set=mask&1;
         mask>>=1;   
   
         if (bit_set) {
            out_byte=(*logo_pointer++);
            out_count=1;
         }
         else {
             /* Litle Endian assumption */   
            pos=* ((short *)logo_pointer);
            logo_pointer+=2;
	    out_count=(pos>>P_BITS)+(THRESHOLD+1);
         }
   
	 while(out_count) {
	    if (!bit_set) {
               pos&=((POSITION_MASK<<8)+0xff);
               out_byte=text_buf[pos++];
	    }

            (*out_pointer++)=out_byte;
            text_buf[r++]=out_byte;
            r&=(N-1);
            out_count--;
	 }
         shift_count++;
      }
   }
   
   write_stdout((char *)out_buffer);
      
   /* first line */
   //uname(&uname_info);
   __asm__ volatile ("push %%ebx ; movl %2,%%ebx ; int $0x80 ; pop %%ebx" 
			: "=a" (__res) 
			: "0" (SYSCALL_UNAME),"ri" ((long)(&uname_info)) 
		        : "memory");    
   
   out_pointer=out_buffer;
   vmw_strcat(uname_info.sysname);
   vmw_strcat(" Version ");
   vmw_strcat(uname_info.release);
   vmw_strcat(", Compiled ");
   vmw_strcat(uname_info.version);
   vmw_strcat("\n");
   
   center_and_print();
   
   /* middle line */
   //fd=open("/proc/cpuinfo",0,0);
   
   __asm__ volatile ("push %%ebx ; movl %2,%%ebx ; int $0x80 ; pop %%ebx" 
                     : "=a" (__res) 
                     : "0" (SYSCALL_OPEN),
		       "ri" ((long)("/proc/cpuinfo")),
		       "c" ((long)(0)), 
                       "d" ((long)(0))
                     : "memory"); 

   fd=__res;
   
   //read(fd,disk_buffer,4096);
   __asm__ volatile ("push %%ebx ; movl %2,%%ebx ; int $0x80 ; pop %%ebx" 
                     : "=a" (__res) 
                     : "0" (SYSCALL_READ),
		       "ri" ((long)(fd)),
		       "c" ((long)(disk_buffer)), 
                       "d" ((long)(4096))
                     : "memory"); 
   
   //   close(fd);
   __asm__ volatile ("push %%ebx ; movl %2,%%ebx ; int $0x80 ; pop %%ebx" 
			: "=a" (__res) 
			: "0" (SYSCALL_CLOSE),"ri" ((long)(fd)) 
		        : "memory");    

   out_pointer=out_buffer;
   
   /* count CPUs */
   cpu_count=0;
   disk_pointer=disk_buffer;
   do {
      temp=*((int *)(disk_pointer));
      if (temp==('o'<<24)+('g'<<16)+('o'<<8)+'b') cpu_count++;
      disk_pointer++;
   } while (temp!=0);
   vmw_strcat(ordinal[cpu_count-1]);
   vmw_strcat(" ");
   
   find_string(('z'<<24)+('H'<<16)+('M'<<8)+' ','.',0);
   vmw_strcat("MHz ");
   find_string(('e'<<24)+('m'<<16)+('a'<<8)+'n',' ',0);
   vmw_strcat(" ");
   find_string(('e'<<24)+('m'<<16)+('a'<<8)+'n',' ',1);
   vmw_strcat(" Processor");
   
   /* handle plural */
   if (cpu_count!=1) vmw_strcat("s"); 
   vmw_strcat(" ");
   

//   sysinfo(&sysinfo_buff);   
   __asm__ volatile ("push %%ebx ; movl %2,%%ebx ; int $0x80 ; pop %%ebx" 
			: "=a" (__res) 
			: "0" (SYSCALL_SYSINFO),"ri" ((long)(&sysinfo_buff)) 
		        : "memory"); 

   

   vmw_strcat(num_to_ascii(sysinfo_buff.totalram>>20));
   vmw_strcat("M RAM, ");
   find_string(('s'<<24)+('p'<<16)+('i'<<8)+'m','\n',0);
   vmw_strcat(" Bogomips Total\n");
   center_and_print();
   
   /* last line */
   out_pointer=out_buffer;
   vmw_strcat(uname_info.nodename);
   center_and_print();
   
   /* restore colors */
   write_stdout("\33[0m\n\n");
   
   __asm__ volatile ("push %%ebx ; movl %2,%%ebx ; int $0x80 ; pop %%ebx" 
			: "=a" (__res) 
			: "0" (SYSCALL_EXIT),"ri" ((long)(0)) 
		        : "memory"); 

   return 0;
}
