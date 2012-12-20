#include <stdio.h>   /* printf() */
#include <stdlib.h>  /* exit() */

#define IMM 0
#define MEM 1
#define INY 2
#define ACC 3
#define INX 4
#define PLX 5
#define ZX  6

#define C 0x01
#define Z 0x02
#define I 0x04
#define D 0x08
#define B 0x20
#define V 0x40
#define N 0x80

unsigned char a,x,y;
unsigned char mem[65536];
unsigned char p;
unsigned short sp=0x100;


static void update_zero(unsigned char val) {
   if (val==0) p|=Z;
   else p&=(~Z);
}

static void update_negative(unsigned char val) {
   if (val>=128) p|=N;
   else p&=(~N);
}

/* A+M+C->A,C*/
void adc(int type,unsigned short value) {
   
   unsigned int sum,carry,add1=0;
   
   carry=!!(p&C);
   
   if (type==MEM) {
      add1=mem[value];
   }
   if (type==IMM) {
      add1=value;
   }
   
   sum=a+add1+carry;
   
   if (sum>255) {
      p|=C;
      p|=V;
   }
   else {
      p&=~C;
      p&=~V;
   }
   
   a=sum&0xff;
   
   update_zero(a);
   update_negative(a);
}

/* A-M-!C->A,C*/
void sbc(int type,unsigned short value) {
   
   unsigned int difference,carry,sub1=0;
   
   carry=!!(p&C);
   
   if (type==MEM) {
      sub1=mem[value];
   }
   if (type==IMM) {
      sub1=value;
   }
   
   if (a<sub1) {
      p&=~C;  
   }
   else {
      p|=C;
   }
   
   difference=a-sub1;
   difference-=!carry;
   
   a=difference&0xff;
   
   update_zero(a);
   update_negative(a);
}

/* A&M->A*/
void and(int type,unsigned short value) {
      
   if (type==MEM) {
      a=a&mem[value];
   }
   if (type==IMM) {
      a=a&value;
   }
   update_zero(a);
   update_negative(a);
}

/* A|M->A*/
void ora(int type,unsigned short value) {
      
   if (type==MEM) {
      a=a|mem[value];
   }
   if (type==IMM) {
      a=a|value;
   }
   update_zero(a);
   update_negative(a);
}

/* A^M->A*/
void eor(int type,unsigned short value) {
      
   if (type==MEM) {
      a=a^mem[value];
   }
   if (type==IMM) {
      a=a^value;
   }
   update_zero(a);
   update_negative(a);
}



void bit(int type,unsigned short value) {
      
   unsigned char input=0,result;
   
   if (type==MEM) {
      input=mem[value];
   }
   if (type==IMM) {
      printf("ERROR!  IMM NOT SUPPORTED\n");
      exit(1);
   }
   if (input&0x80) {   
      p|=N;
   }
   else {
      p&=~N;
   }
   
   if (input&0x40) {
      p|=V;
   }
   else {
      p&=~V;
   }
   
   result=a&input;
   update_zero(result);
}

void lsr(int type,unsigned short value) {

   int low_bit=0;
   unsigned char result=0;
   
   if (type==ACC) {
      low_bit=a&0x1;
      a>>=1;
      result=a;
   }
   if (type==MEM) {
      low_bit=mem[value]&0x1;
      mem[value]>>=1;
      result=mem[value];
   }
   p&=~N;  /* N has to be zero */

   if (low_bit) {
      p|=C;
   }
   else {
      p&=~C;
   }
   update_zero(result);   
}

void ror(int type,unsigned short value) {

   int low_bit=0;
   unsigned char result=0;
   
   if (type==ACC) {
      low_bit=a&0x1;
      a>>=1;
      a|=(p&C)<<7;
      result=a;
   }
   if (type==MEM) {
      low_bit=mem[value]&0x1;
      mem[value]>>=1;
      mem[value]|=(p&C)<<7;
      result=mem[value];
   }
   
   if (low_bit) {
      p|=C;
   }
   else {
      p&=~C;
   }
   update_negative(result);
   update_zero(result);   
}

/* A-M */
void cmp(int type, unsigned short value) {
   
   unsigned char M=0;
   unsigned char result;
   
   if (type==IMM) {
      M=value;
   }
   if (type==MEM) {
      M=mem[value];
   }
   
//   printf("Comparing %02X with %02X ",a,M);
   result=a-M;
   
   update_zero(result);
   update_negative(result);
   

   
   if (a>=M) {
      p|=C;
   }
   else {
      p&=~C;
   }
//   printf("Results: z=%d n=%d c=%d\n",p&Z,p&N,p&C);   
}


/* X-M */
void cpx(int type, unsigned short value) {
   
   unsigned char M=0;
   unsigned char result;
   
   if (type==IMM) {
      M=value;
   }
   if (type==MEM) {
      M=mem[value];
   }
   
   result=x-M;
   
   update_zero(result);
   update_negative(result);
   

   
   if (x>=M) {
      p|=C;
   }
   else {
      p&=~C;
   }
//   printf("Results: z=%d n=%d c=%d\n",p&Z,p&N,p&C);   
}

/* A<<1, A7->c, 0 in bottom */
void asl(int type,unsigned short value) {

   int high_bit=0;
   unsigned char result=0;
   
   if (type==ACC) {
      high_bit=a>>7;
      a<<=1;
      result=a;
   }
   if (type==MEM) {
      high_bit=mem[value]>>7;
      mem[value]<<=1;
      result=mem[value];
   }

   if (high_bit) {
      p|=C;
   }
   else {
      p&=~C;
   }
   update_zero(result);
   update_negative(result);


}

void lda(int type,unsigned short value) {

   int addr;
   
   if (type==IMM) {
      a=value&0xff;
   }
   if (type==MEM) {
      a=mem[value];
   }
   if (type==INY) {
      addr=(mem[value+1]<<8)+mem[value];
      a=mem[addr];
   }
   
   if (type==PLX) {
      a=mem[value+x];
   }
   if (type==ZX) {
      a=mem[(value+x)&0xff];
   }
   
   update_zero(a);
   update_negative(a);
}


void ldy(int type,unsigned short value) {
   
   if (type==IMM) {
      y=value&0xff;
   }
   if (type==MEM) {
      y=mem[value];
   }
   
   update_zero(y);
   update_negative(y);
}

void inc(int type,unsigned short value) {
   
   int result=0;
   
   if (type==MEM) {
      mem[value]++;
      result=mem[value];
   }
   if (type==PLX) {
      mem[value+x]++;
      result=mem[value+x];
   }
   
   update_zero(result);
   update_negative(result);
}


void dec(int type,unsigned short value) {
   
   int result=0;
   
   if (type==MEM) {
      mem[value]--;
      result=mem[value];
   }
   
   update_zero(result);
   update_negative(result);
}

void dex() {
   

   x--;
   
   update_zero(x);
   update_negative(x);
}

void inx() {
  
   x++;
   
   update_zero(x);
   update_negative(x);
}

void ldx(int type,unsigned short value) {
   
   if (type==IMM) {
      x=value&0xff;
   }
   if (type==MEM) {
      x=mem[value];
   }
   
   update_zero(x);
   update_negative(x);
}


void sta(int type,unsigned short value) { 
 
   unsigned short addr;
   
   if (type==MEM) {
      mem[value]=a;
   }
   if (type==INY) {
      addr=(mem[value+1]<<8)+mem[value];        
      mem[addr]=a;
   }
   if (type==ZX) {
      addr=(value+x)&0xff;
//      printf("ZX: storing %x to %X\n",a,addr);
      mem[addr]=a;
   }
}

void stx(int type,unsigned short value) { 
    
   if (type==MEM) {
      mem[value]=x;
   }
}

void sty(int type,unsigned short value) { 
    
   if (type==MEM) {
      mem[value]=y;
   }
}

void clc() {
   p&=~C;
}

void sec() {
   p|=C;
}


/* pop a ,NZ */
void pla() {
   sp++;
   a=mem[sp];
}

/* push a */
void pha() {
   mem[sp]=a;
   sp--;
}

/* pop status reg */
void plp() {
   sp++;
   p=mem[sp];
}

/* push p */
void php() {
   mem[sp]=p;
   sp--;
}

void tay() {
   y=a;
   update_zero(y);
   update_negative(y);
}

void tya() {
   a=y;
   update_zero(a);
   update_negative(a);
}

void tax() {
   x=a;
   update_zero(x);
   update_negative(x);
}

void txa() {
   a=x;
   update_zero(a);
   update_negative(a);
}

int bcc() {
   if (!(p&C)) return 1;
   else return 0;
}

int bcs() {
   if (p&C) return 1;
   else return 0;
}

int beq() {
   if (p&Z) return 1;
   else return 0;
}

int bne() {
   if (!(p&Z)) return 1;
   else return 0;
}


int bmi() {
   if (p&N) return 1;
   else return 0;
}

int bpl() {
   if (!(p&N)) return 1;
   else return 0;
}


unsigned char high(int value) {
   return ((value>>8)&0xff);
}

unsigned char low(int value) {
   return (value&0xff);
}

void bload(char *filename,unsigned short addr,int size) {
   
      FILE *fff;
   
      fff=fopen(filename,"r");
      if (fff==NULL) {
	       printf("Couldn't open %s\n",filename);
	       return;
      }
      fread(mem+addr, size, 1, fff);
      fclose(fff);
}
