#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

#include "sim.h"

/* I/O Control Block */
char iob[]=
{
  0x01, /* Table type (always 1) */
  0x60, /* Slot * 16 (slot 6)    */
  0x01, /* Drive Number */
  0x00, /* Volume ID.  00 means any */
  0x11, /* Track Number (0-0x22) */
  0x00, /* Sector Number (0-0x0f) */
  0x20,0x07, /* address of device characteristics table (little-endian) */
  0x00,0x06, /* address to load 256 byte block, little endian */
  0x00, /* Not used */
  0x00, /* Amount to read (0 = whole sector) */
  0x01, /* 0=seek, 1=read, 2=write, 4=format */
  0x00, /* space for return value (carry set on error) */
        /* 00 = no, 08=init 10 = write protect 20=vol mis 40=drive error 80=read */
  0x00, /* last volume read */
  0x00, /* last slot read */
  0x00, /* last drive read */
};

/* Device Characteristic Table */
char dct[]=
{
   0x00, /* device type.  00 = Disk ][ */
   0x01, /* phases per track.  Always 1 */
   0xef,0xd8 /* motor on time.  Always this for Disk ][ */
};

#define TRACKS_PER_DISK 0x23
#define SECTORS_PER_TRACK 0x10
#define BYTES_PER_SECTOR 0x100

#define TS_TO_INT(__x,__y) ((((int)__x)<<8)+__y)
#define DISK_OFFSET(__track,__sector) ((((__track)*SECTORS_PER_TRACK)+(__sector))*BYTES_PER_SECTOR)
       

/* RWTS routine */
/* Y is iocb-low and A is iocb-high */
void jsr_3d9() {

   int address;
   unsigned char table_type,slot,drive;
   unsigned char volume,track,sector;
   unsigned char read_size,op_type;
   unsigned char error=0;
   int dct_address,block_address;
   
   address=(a<<8)+y;
   
   table_type=mem[address];
   if (table_type!=1) printf("Error!  Table type not 1!\n");
   
   slot=mem[address+1];
   if (slot!=0x60) printf("Warning!  Slot %d\n",slot>>8);
   
   drive=mem[address+2];
   if (drive!=1) printf("Warning!  Drive: %d\n",drive);
   
   volume=mem[address+3];
   track=mem[address+4];
   sector=mem[address+5];
   
   dct_address=( (mem[address+7]<<8)+mem[address+6]);
   
   /* check dct */

   if (mem[dct_address]!=0) printf("Invalid Device Type!\n");
   if (mem[dct_address+1]!=1) printf("Invalid Phases per Track!\n");
   if ((mem[dct_address+2]!=0xef) && (mem[dct_address+3]!=0xd8)) 
     printf("Invalid Motor On Time!\n");
      
   block_address=( (mem[address+9]<<8) + mem[address+8]);
   
   read_size=mem[address+11];
   op_type=mem[address+12];
   
   if (op_type==0) printf("Warning!  Seek unsupported!\n");
   else if (op_type==1) {
      int our_size,fd;
      
      fd=open("disk1.dsk",O_RDONLY);
      if (fd<0) {
	 error=0x08;
	 goto early_out;
      }
      
      if (read_size==0) our_size=256;
      else our_size=read_size;

      lseek(fd,DISK_OFFSET(track,sector),SEEK_SET);
      read(fd,&mem[block_address],our_size);

//      for(i=0;i<our_size;i++) {
//	 mem[block_address+i]=0x78;	 
  //    }      
      close(fd);
   }
   else if (op_type==2) printf("Warning!  Write unsupported!\n");
   else if (op_type==4) printf("Warning!  Format unsupported!\n");
   else printf("Error!  Unknown op-type %d\n",op_type);

early_out:   
   /* space for return value (carry set on error) */
   /* 00 = no, 08=init 10 = write protect 20=vol mis 40=drive error 80=read */
   mem[address+13]=error;   
   if (error) {
      sec();
   }

   if (op_type==1) {
      mem[address+14]=volume;
      mem[address+15]=slot;
      mem[address+16]=drive;
   }
}


void copy_mem(char *ptr,int size,int location) {

   int i;
   
   for(i=0;i<size;i++) {
      mem[i+location]=*(ptr+i);  
   }
   
}
 
void dump_mem(int offset, int size) {

   int line,i;
   
   line=offset&0xfff0;
   
   while(1) {
      printf("%04x : ",line);
      for(i=0;i<16;i++) {
         printf(" %02x",mem[line+i]);	 
      }
      
      line+=16;
      if (line>=offset+size) break;
      printf("\n");
   }
   printf("\n");   
}

int main(int argc, char **argv) {


   copy_mem(iob,17,0x700);
   copy_mem(dct,4,0x720);

   ldy(IMM,0x00);
   lda(IMM,0x07);
   
   jsr_3d9();

//   printf("VTOC:\n");
//   dump_mem(0x600,256);
   
      lda(MEM,0x601);
      sta(MEM,0x704);
      lda(MEM,0x602);
      sta(MEM,0x705);
   
   while(1) {
      int next_track,next_sector;
      
      int file_track,file_sector,file_type,file_size,i,j;
      
      lda(IMM,0x07);
      jsr_3d9();      

//      printf("Catalog Sector:\n");
//      dump_mem(0x600,256);      
      
        /* save next track/sector */
      lda(MEM,0x601);
      next_track=a;
      sta(MEM,0x704);
      lda(MEM,0x602);
      next_sector=a;
      sta(MEM,0x705);

      for(j=0;j<7;j++) {
      if ((mem[0x60e +35*j]!=0x0) && (mem[0x60e +35*j]!=0xff)) {
         file_track=mem[0x60b +35*j];
         file_sector=mem[0x60c +35*j];
         file_type=mem[0x60d +35*j];
	 file_size=((mem[0x62d +35*j]<<8)+mem[0x62c +35*j]);	 
         for(i=0;i<30;i++) {
	    char c;
	    c=(mem[0x60e + i + 35*j])&0x7f;
	    if (c!=0) putchar(c);
	 }
	 printf(": t=%d s=%d type=%d size=%d\n",file_track,
		file_sector,file_type,file_size);
	 printf("\n");
      }
      }
      
      if ((next_track==0)) break;   
   }
      
   return 0;
}
