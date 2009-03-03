/* This code implements ll in C code using the c library */
/* Note!  This only will work on x86.  It has endianess  */
/*        dependencies, and makes assumptions about the  */
/*        layout of the /proc/cpuinfo file!              */

#include <stdio.h>
#include <sys/utsname.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/sysinfo.h>

#include "../logo.lzss_new.h"

unsigned int r,shift_count,bit_set;
unsigned short out_count,pos;
unsigned char mask,out_byte;
char *logo_pointer,*out_pointer,*disk_pointer;
char out_buffer[16384],text_buf[(N+F)-1],disk_buffer[4096];

struct utsname uname_info;
struct sysinfo sysinfo_buff;
int fd,cpu_count,temp;

char ordinal[4][6]={"One","Two","Three","Four"};

   /* Write a string to stdout */
static void write_stdout(char *string) {
   
      /* stdout is fd 1 */
   write(1,string,strlen(string));
}

     /* find the 4 ascii bytes in pattern.  Then skip to : then skip spaces */
     /* then copy the string found to the end of out_pointer, stopping at   */
     /* the stop character or \n                                            */
static void find_string(unsigned int pattern,unsigned char stop,int skip_spaces) {

   unsigned char ch;

   if (!skip_spaces) {
	 
      disk_pointer=disk_buffer;
      out_pointer=out_buffer+strlen(out_buffer);

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
      
      *--ascii_pointer=(unsigned char)(r+0x30);      /* convert to ASCII */
      temp=q;
   } while(temp);

   return ascii_pointer;
}

   /* center and print a string */
static void center_and_print() {
   int length;
   
   length=strlen(out_buffer);
   if (length<80) {
      write_stdout("\033[");
      write_stdout(num_to_ascii((80-length)/2));
      write_stdout("C");
   }
   write_stdout(out_buffer);   
}

int main(int argc, char **argv) {


   /* do LZSS decryption */
   
   r=(N-F);
   logo_pointer=(char *)logo;
   out_pointer=out_buffer;
   
   while(logo_pointer<((char *)logo+sizeof(logo)) ) {
            
      shift_count=0;
      mask=(*logo_pointer++);

      while(shift_count<8) {
      
	 if (logo_pointer>=((char *)logo+sizeof(logo)) ) break;
	 
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
	    out_count=(unsigned short)((pos>>P_BITS)+(THRESHOLD+1));
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
   
   write_stdout(out_buffer);
      
   /* first line */
   uname(&uname_info);
   out_buffer[0]=0;
   strcat(out_buffer,uname_info.sysname);
   strcat(out_buffer," Version ");
   strcat(out_buffer,uname_info.release);
   strcat(out_buffer,", Compiled ");
   strcat(out_buffer,uname_info.version);
   strcat(out_buffer,"\n");
   
   center_and_print();
   
   /* middle line */
   fd=open("/proc/cpuinfo",0,0);
   read(fd,disk_buffer,4096);
   close(fd);
   out_buffer[0]=0;
   
   /* count CPUs */
   cpu_count=0;
   disk_pointer=disk_buffer;
   do {
      temp=*((int *)(disk_pointer));
      if (temp==('o'<<24)+('g'<<16)+('o'<<8)+'b') cpu_count++;
      disk_pointer++;
   } while (temp!=0);
   strcat(out_buffer,ordinal[cpu_count-1]);
   strcat(out_buffer," ");
   
   find_string(('z'<<24)+('H'<<16)+('M'<<8)+' ','.',0);
   strcat(out_buffer,"MHz ");
   find_string(('e'<<24)+('m'<<16)+('a'<<8)+'n',' ',0);
   strcat(out_buffer," ");
   out_pointer++;
   find_string(('e'<<24)+('m'<<16)+('a'<<8)+'n',' ',1);
   strcat(out_buffer," Processor");
   
   /* handle plural */
   if (cpu_count!=1) strcat(out_buffer,"s"); 
   strcat(out_buffer," ");
   sysinfo(&sysinfo_buff);
   strcat(out_buffer,num_to_ascii(sysinfo_buff.totalram>>20));
   strcat(out_buffer,"M RAM, ");
   find_string(('s'<<24)+('p'<<16)+('i'<<8)+'m','\n',0);
   strcat(out_buffer," Bogomips Total\n");
   center_and_print();
   
   /* last line */
   out_buffer[0]=0;
   strcat(out_buffer,uname_info.nodename);
   center_and_print();
   
   /* restore colors */
   out_buffer[0]=0;
   strcat(out_buffer,"\33[0m\n\n");
   write_stdout(out_buffer);
   
   return 0;
}
