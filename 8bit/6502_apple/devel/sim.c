#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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


void update_zero(unsigned char val) {
   if (val==0) p|=Z;
   else p&=(~Z);
}

void update_negative(unsigned char val) {
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


unsigned char logo[]=
	{255,27,91,48,59,49,59,51,55,
         159,59,52,55,109,35,204,247,192,7,51,
	 141,48,200,27,27,91,196,7,203,31,28,12,59,
	 15,52,48,109,10,192,247,1,96,26,56,44,156,
	 31,27,91,51,49,109,204,4,65,172,13,36,
	 2,28,16,79,13,32,16,65,147,152,131,52,28,52,204,16,
	 16,12,36,111,57,236,167,28,8,51,22,20,137,85,44,96,
	 0,43,97,214,113,226,200,203,8,212,9,211,16,43,89,245,209,
	 0,128,17,210,24,13,40,28,20,13,44,28,28,240,74,26,91,
	 0,13,80,95,101,135,101,43,85,245,205,205,40,205,20,137,65,
	 0,29,135,66,75,114,83,28,120,15,98,135,109,85,88,247,193,
	 0,232,43,244,151,73,120,61,176,27,95,151,176,18,43,171,202,
	 16,223,22,26,245,90,245,217,63,51,27,86,146,91,176,2,
	 0,12,29,211,200,172,57,23,102,50,246,110,109,236,68,96,94,
	 8,175,10,166,105,20,1,48,51,11,222,31,49,15,211,188,
	 0,175,79,25,86,170,69,82,219,40,82,70,127,8,83,219,35,
	 0,169,85,170,53,24,33,18,104,145,42,200,34,178,104,112,45,
	 0,198,80,178,121,145,74,112,49,248,81,243,40,221,23,255,23,
	 8,2,54,3,36,229,66,10,
	};

unsigned char version[]="Linux Version 2.6.22.6, Compiled 2007";
unsigned char one[]="One 1.02MHz ";
unsigned char nmos[]="6502";
unsigned char cmos[]="65C02";
unsigned char processor[]=" Processor, ";
unsigned char ram[]="kB RAM";
unsigned char apple[]="Apple II";



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



void copy_logo(unsigned char *ptr,int size,int location) {

   int i;
   
   for(i=0;i<size;i++) {
      mem[i+location]=*(ptr+i);  
   }
   
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

#define VERSION 0x0f00
#define ONE     0x0f30
#define NMOS    0x0f40
#define CMOS    0x0f50
#define PROCESSOR 0x0f60
#define RAM     0x0f70
#define APPLE   0x0f80

#define LOGO 0x1000
#define R 0x1a00

// hgr2, which we don't use
#define OUTPUT 0x4000   

// 5k = 0x1400

#define LOGOH     0xff
#define LOGOL     0xfe
#define OUTPUTH   0xfd
#define OUTPUTL   0xfc
#define STORERH   0xfb
#define STORERL   0xfa
#define LOADRH    0xf9
#define LOADRL    0xf8
#define EFFECTRH  0xf7
#define EFFECTRL  0xf6
#define MSELECT   0xf5
#define COUNT     0xf4
#define OUT_COUNT 0xf3


#define QUOTIENT  0xff
#define REMAINDER 0xfe
#define DIVISORH  0xfb
#define DIVISORL  0xfa
#define DIVIDENDH 0xf9
#define DIVIDENDL 0xf8
#define YADDRH    0xf7
#define YADDRL    0xf6
#define APPLEY    0xf5
// 0xf4 is COUNT
#define COLOR     0xf3
#define APPLEXH   0xf2
#define APPLEXL   0xf1
#define MASK      0xf0
#define BLOCK     0xef
#define OUTH      0xee
#define OUTL      0xed
#define HGRPNTH   0xec
#define HGRPNTL   0xeb

#define STRCATH   0xf9
#define STRCATL   0xf8
#define RAMSIZE   0xf7
#define NUM2      0xf3
#define NUM1      0xf2
#define NUM0      0xf1
#define TYPE      0xf0
#define CPU       0xef

void jsr_inc16() {
   inc(PLX,0);                // increment address
   if(bne()) goto no_carry;
   inx();
   inc(PLX,0);                // handle overflow
no_carry: ;
   // rts
}

void jsr_inc_pointer() {
   inc(MEM,OUTPUTL);                // increment address
   if(bne()) goto no_carry2;
   inc(MEM,OUTPUTH);                // handle overflow
no_carry2: ;
   // rts
}

void flush_line_text() {
 
   int i;
   
   printf("%c[4",27);
   if (mem[COLOR]==0) printf("0");
   else if (mem[COLOR]==1) printf("3");
   else printf("7");
   printf("m");
   
   for(i=0;i<mem[COUNT];i++) {
      printf(" ");
   }
}


int y_to_addr(int y) {

   int yline,yoff,totaly;
   
   yoff=(y&0x7)*0x400;

   if (y<64) {
      yline=(y>>3)*0x80;
   }
   else if (y<128) {
      yline=(((y-64)>>3)*0x80)+0x28;
   }
   else {
      yline=(((y-128)>>3)*0x80)+0x50;
   }
   totaly=yline+yoff+0x2000;
   
   return totaly;
}

void jsr_y_to_addr() {

//   printf("Appley=%d ",mem[APPLEY]);
      
//   printf("$%02X%02X -> total=",mem[YADDRH],mem[YADDRL]);
   
//   yoff=(mem[APPLEY]&0x7)*0x400;

   lda(MEM,APPLEY);
   and(IMM,0x7);       // y%8
   asl(ACC,1);
   asl(ACC,1);         // * 1024
   clc();
   adc(IMM,0x20);      // add 0x2000 which is where HGR starts
   sta(MEM,YADDRH);
   sty(MEM,YADDRL);

   
less_than_64:
   lda(MEM,APPLEY);
   cmp(IMM,64);
   if (bcs()) goto less_than_128;
   ldx(IMM,0);
//   yline=(mem[APPLEY]>>3)*0x80;
   goto ready_to_add;

less_than_128:   
   cmp(IMM,128);
   if (bcs()) goto more_than_128;
   ldx(IMM,0x28);
   sec();
   sbc(IMM,64);
//   yline=(((mem[APPLEY]-64)>>3)*0x80)+0x28;
   goto ready_to_add;
more_than_128:
   ldx(IMM,0x50);
   sec();
   sbc(IMM,128);
//   yline=(((mem[APPLEY]-128)>>3)*0x80)+0x50;
ready_to_add:   

   lsr(ACC,1);
   lsr(ACC,1);
   lsr(ACC,1);   // divide by 8
   
//   yline=(a<<7)+x;
  
   lsr(ACC,1);
   if (bcc()) goto no_bottom_add;

   pha();
   clc();
   lda(MEM,YADDRL);
   adc(IMM,0x80);
   sta(MEM,YADDRL);
   pla();
   
no_bottom_add:
   adc(MEM,YADDRH);
   sta(MEM,YADDRH);

   clc();
   txa();
   adc(MEM,YADDRL);  // we shifted by 0x80, and max X can be is 0x50
                     // so shouldn't ever carry
   sta(MEM,YADDRL);
   
//    printf("$%02X%02X\n",mem[YADDRH],mem[YADDRL]);  

}

void div7() {
   int debug=0;
//   if (mem[DIVIDENDH]) debug=1;
   
      sty(MEM,QUOTIENT);
      lda(IMM,1);
      sta(MEM,DIVISORH);
      lda(IMM,0xc0);
      sta(MEM,DIVISORL);    // set DIVISOR to 7<<6
div7_loop:   
//if (debug) printf("$%02x%02x\n",mem[DIVISORH],mem[DIVISORL]);
		 
      asl(MEM,QUOTIENT);
   
      lda(MEM,DIVIDENDH);  /* 1 111 =A  1 11 0 = M */
      cmp(MEM,DIVISORH);
      if (bcc()) goto less_than; //vmw
      if (bne()) goto subtract;  //vmw
      lda(MEM,DIVIDENDL);
      cmp(MEM,DIVISORL);
      if (bcc()) goto less_than; //vmw

subtract:
      if (debug) printf("%d-%d ($%02X%02X-$%02x%02X)=",
	              (mem[DIVIDENDH]<<8)+mem[DIVIDENDL],
	              (mem[DIVISORH]<<8)+mem[DIVISORL],
	              mem[DIVIDENDH],mem[DIVIDENDL],
	              mem[DIVISORH],mem[DIVISORL]);
      sec();
      lda(MEM,DIVIDENDL);
      sbc(MEM,DIVISORL);
      sta(MEM,DIVIDENDL);
   
      lda(MEM,DIVIDENDH);
      sbc(MEM,DIVISORH);
      sta(MEM,DIVIDENDH);
   
      if (debug) printf("%d ($%02X%02X)\n",(mem[DIVIDENDH]<<8)+mem[DIVIDENDL],
                                mem[DIVIDENDH],mem[DIVIDENDL]);

   
//      value=value-((mem[DIVISORH]<<8)+mem[DIVISORL]);
      lda(MEM,QUOTIENT);
      ora(IMM,1);
      sta(MEM,QUOTIENT);
less_than:
      clc();
      ror(MEM,DIVISORH);
      ror(MEM,DIVISORL);  // carry should make this 16 bit
      lda(MEM,DIVISORL);
      cmp(IMM,3);    
      if (bne()) goto div7_loop;
   
      lda(MEM,DIVIDENDL);
      sta(MEM,REMAINDER);
}

void div10() {
      sty(MEM,QUOTIENT);
      lda(IMM,0xa0);
      sta(MEM,DIVISORL);    // set DIVISOR to 10<<4
div10_loop:

      asl(MEM,QUOTIENT);
   
      lda(MEM,DIVIDENDL);
      cmp(MEM,DIVISORL);
      if (bcc()) goto less_than; //vmw

subtract:
      sec();
      lda(MEM,DIVIDENDL);
      sbc(MEM,DIVISORL);
      sta(MEM,DIVIDENDL);

      lda(MEM,QUOTIENT);
      ora(IMM,1);
      sta(MEM,QUOTIENT);
less_than:
      clc();

      ror(MEM,DIVISORL);  // carry should make this 16 bit
      lda(MEM,DIVISORL);
      cmp(IMM,0x5);    
      if (bne()) goto div10_loop;
   
      lda(MEM,DIVIDENDL);
      sta(MEM,REMAINDER);
}

/* x=0...280 */
/* y=0...192 */
/* color 0=black  1=green  2=purple 3=white */
/* color 4=black  5=orange 6=blue   7=white */
void hplot_good(int x,int y,int color) {
   
//   printf("hplot %d %d = %d\n",x,y,color);
   int yaddr,xaddr,xbit,odd;
   unsigned char blah1,mask;
   
   yaddr=y_to_addr(y);
   
   mem[DIVIDENDH]=high(x);
   mem[DIVIDENDL]=low(x);
   
//   printf("%d/7=",x);
   div7();
   
   xaddr=mem[QUOTIENT];
   xbit=mem[REMAINDER];
//   printf("%dR%d\n",xaddr,xbit);
   
   odd=x&1;
      
   mask=1<<xbit;
   
   blah1=mem[yaddr+xaddr];
   
   if (odd) {
      if (color&2) blah1|=mask;
      else blah1&=~mask;
   }
   else {
      if (color&1) blah1|=mask;
      else blah1&=~mask;
   }
   
   blah1|=0x80;  /* force blue/orange pal */
      
   mem[yaddr+xaddr]=blah1;
}

void jsr_hplot() {
   
   lda(MEM,APPLEXH);
   sta(MEM,DIVIDENDH);
   lda(MEM,APPLEXL);
   sta(MEM,DIVIDENDL);
   
//   printf("%d/7=",x);
   div7();
   
//   printf("%dR%d\n",xaddr,xbit);
   
   lda(IMM,1);
   ldx(MEM,REMAINDER);
make_mask:
   if (beq()) goto done_mask;
   asl(ACC,1);
   dex();
   goto make_mask;
done_mask:
   sta(MEM,MASK);
   
   lda(MEM,YADDRH);
   sta(MEM,HGRPNTH);
   lda(MEM,YADDRL);
   sta(MEM,HGRPNTL);
   
   clc();
   adc(MEM,QUOTIENT);
   sta(MEM,HGRPNTL);
   lda(MEM,HGRPNTH);
   adc(IMM,0);
   sta(MEM,HGRPNTH);

   lda(INY,HGRPNTL);
   sta(MEM,BLOCK);
   
   lda(IMM,1);
   bit(MEM,APPLEXL);
   if (beq()) goto even;
      
odd:
   lda(IMM,2);
   bit(MEM,COLOR);
   if (bne()) goto set_bit;
   goto clear_bit;

even:
   lda(IMM,1);
   bit(MEM,COLOR);
   if (beq()) goto clear_bit;
   
set_bit:   
   lda(MEM,MASK);
   ora(MEM,BLOCK);
   goto done_pset;
clear_bit:
   lda(MEM,MASK);
   eor(IMM,0xff);
   and(MEM,BLOCK);
      
done_pset:   
//   sta(MEM,BLOCK);   
   ora(IMM,0x80);  /* force blue/orange pal */
   sta(MEM,BLOCK);

   ldx(IMM,8);   
make_blocky:   

   sta(INY,HGRPNTL);
   
   pha();
   clc();
   lda(MEM,HGRPNTH);
   adc(IMM,0x04);        // the 8 consecutive lines are 1k apart
   sta(MEM,HGRPNTH);
   pla();
   
   dex();
   if (bne()) goto make_blocky;
   
}



void jsr_flush_line() {
//    int i;

//   printf("count=%d\n",mem[COUNT]);


      
flush_loop:
   lda(MEM,COUNT);
   if (beq()) goto end_flush;
   
   jsr_hplot();
   
   clc();
   lda(MEM,APPLEXL);
   adc(IMM,1);
   sta(MEM,APPLEXL);
   lda(MEM,APPLEXH);
   adc(IMM,0);
   sta(MEM,APPLEXH);

   dec(MEM,COUNT);
   goto flush_loop;

end_flush:;
//   sty(MEM,COUNT);       // set count to zero   
}

void pset(int color,int pal) {

   printf("%c[4",27);
   if (color==0) printf("0");
   if (color==3) printf("7");
   if (pal) {
      if (color==1) printf("4");
      if (color==2) printf("3");
   }
   else {
      if (color==1) printf("5");
      if (color==2) printf("2");      
   }
   printf("m ");
}


/* this is only approximate, you really need 560 across */
/* to get the actual color response of an apple II      */
/* and emulate what the NTSC monitor shows              */
void dump_hgr() {
 
   unsigned int x,y,yaddr,pal,color,oldcolor;
   unsigned char temp;
   
   /* only 160 as we care about the mode where the bottom 4 lines are text */
   /* up to 192 if we want the whole thing                                 */
   for(y=0;y<160;y++) {
      yaddr=y_to_addr(y);

      /* each byte has 1 bit for palette selection and 7 bits for colors */
      /* on b&w monitors it is simple bitmap, with LSB (bit 0) mappint to*/
      /* on screen pixel 0 (MSB)                                         */
      /* color is way more complicated.  2 consecutive bits on is white  */
      /* 2 consecutive bits off is black.  Alternating 01 and 10 give    */
      /* colors.  This is ripe for fringing and other weird effects      */
      
      for(x=0;x<40;x+=2) {
         temp=mem[yaddr+x];
         pal=!!(temp&0x80);
	 
         color=(temp)&0x3;
         pset(color,pal);        // bit 0
         color=(temp>>2)&0x3;
         pset(color,pal);        // bit 1
         color=(temp>>4)&0x3;
         pset(color,pal);        // bit 2
      
         oldcolor=((temp>>6)&1);
	 
         temp=mem[yaddr+x+1];
	 pal=!!(temp&0x80);
         color=(((temp&0x1)<<1)|(oldcolor))&0x3;
         pset(color,pal);        // bit 3
         color=(temp>>1)&0x3;
         pset(color,pal);        // bit 4
         color=(temp>>3)&0x3;
         pset(color,pal);        // bit 5
         color=(temp>>5)&0x3;
         pset(color,pal);        // bit 6
      }
      printf("\n");

//      printf("%d %x\n",y,yaddr);
   }
   
}

void jsr_strcat() {
   
strcat_loop:   
   lda(INY,STRCATL);
   sta(INY,OUTPUTL);
   if (beq()) goto strcat_done;   
   ldx(IMM,STRCATL);
   jsr_inc16();
   jsr_inc_pointer();
   goto strcat_loop;
   
strcat_done:;
}

void jsr_reset_output() {
   lda(IMM,low(OUTPUT));
   sta(MEM,OUTPUTL);
   lda(IMM,high(OUTPUT));
   sta(MEM,OUTPUTH);   
}


void jsr_strlen() {

   jsr_reset_output();
   
   sty(MEM,COUNT);   
strlen_loop:   
   lda(INY,OUTPUTL);
   if (beq()) goto strlen_done;
   inc(MEM,COUNT);
   jsr_inc_pointer();
   goto strlen_loop;
strlen_done:   ;
}

void jsr_prblnk() {
   
   int i;
   
   for(i=0;i<x;i++) {
      printf(" ");
   }   
}

void jsr_cout1() {
   printf("%c",a);
}

void jsr_crout() {
   printf("\n");
}

   
   

void jsr_center_and_print() {
   
   
   jsr_strlen();
   
   sec();
   lda(IMM,40);
   sbc(MEM,COUNT);
   if (bmi()) goto no_center;
   lsr(ACC,1);  // divide by 2
   tax();
       
   jsr_prblnk();
   
   jsr_reset_output();   

no_center:
   
   ldx(MEM,COUNT);
print_loop:   
   lda(INY,OUTPUTL);
   jsr_cout1();
   jsr_inc_pointer();
   dex();
   if(bne()) goto print_loop;

   jsr_crout();
}

void jsr_num_to_ascii() {

   
   ldx(IMM,NUM2);
   lda(MEM,RAMSIZE);
   sta(MEM,DIVIDENDL);
   
div_loop:
   div10();

   clc();
   lda(IMM,0x30);
   adc(MEM,REMAINDER);
   sta(ZX,0);
   dex();
   lda(MEM,QUOTIENT);
   sta(MEM,DIVIDENDL);
   if (bne()) goto div_loop;
  

store_loop:   
   inx();
   lda(ZX,0);
   sta(INY,OUTPUTL);
   cpx(IMM,(NUM2+1));
   if (beq()) goto done_ntoa;
   jsr_inc_pointer();
   goto store_loop;
done_ntoa:;

   
}

void jsr_get_sysinfo() {
   

   // set up some defaults
   lda(IMM,64);
   sta(MEM,RAMSIZE);
   lda(IMM,'e');
   sta(MEM,TYPE);
   lda(IMM,0);
   sta(MEM,CPU);
   
   lda(MEM,0xfbb3); // ident
   cmp(IMM,0x38);
   if (bne()) goto apple_iiplus;
apple_ii:
   lda(IMM,' ');
   sta(MEM,TYPE);
   goto done_detecting;   
   
apple_iiplus:
   cmp(IMM,0xea);
   if (bne()) goto apple_iie;
   
   lda(MEM,0xfb1e);
   cmp(IMM,0x8a);
   if (beq()) goto apple_iii;
   
   lda(IMM,48);
   sta(MEM,RAMSIZE);  // not always true
    
   lda(IMM,'+');
   sta(MEM,TYPE);
   goto done_detecting;
   
apple_iii:
   lda(IMM,'I');
   sta(MEM,TYPE);
   lda(IMM,48);
   sta(MEM,RAMSIZE);
   goto done_detecting;
   
apple_iie:
   lda(MEM,0xfbc0);
   if (beq()) goto apple_iic;
   
   cmp(IMM,0xe0);
   if (bne()) goto done_detecting;
      
apple_iie_enhanced:   
   lda(IMM,1);
   sta(MEM,CPU);
   lda(IMM,128);
   sta(MEM,RAMSIZE);
   
   goto done_detecting;
apple_iic:
   lda(IMM,'c');
   sta(MEM,TYPE);
   lda(IMM,128);
   sta(MEM,RAMSIZE);
   
done_detecting:;
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

int main(int argc, char **argv) {

   unsigned short pointer;
   
   copy_logo(logo,sizeof(logo),LOGO);
   
   lda(IMM,high(LOGO));
   sta(MEM,LOGOH);
   
   lda(IMM,low(LOGO));
   sta(MEM,LOGOL);          
   
   lda(IMM,high(OUTPUT));
   sta(MEM,OUTPUTH);
   
   lda(IMM,low(OUTPUT));
   sta(MEM,OUTPUTL);          
   
   lda(IMM,high(1024-64));
   sta(MEM,STORERH);
   
   lda(IMM,low(1024-64));
   sta(MEM,STORERL);          
      
   ldy(IMM,0);                   // setup Y for indirect addressing
   
decompression_loop:   


   lda(IMM,0x8);                  // set counter
   sta(MEM,COUNT);
     
   lda(INY,LOGOL);                // load byte

//   printf("Loaded %d\n",a);
   
   sta(MEM,MSELECT);              // store it

   ldx(IMM,LOGOL);
   jsr_inc16();  // jsr
      
//   printf("Logoptr= $%02x%02x\n",mem[LOGOH],mem[LOGOL]);
   
test_flags:
   lda(MEM,LOGOH);
   cmp(IMM,high(LOGO+sizeof(logo)));
   if (bcc()) goto not_match;
   
   lda(MEM,LOGOL);
   cmp(IMM,low(LOGO+sizeof(logo)));
   if (bcc()) goto not_match;
   
   goto done_logo;           /* jmp */

not_match:
   lsr(MEM,MSELECT);
   
   if (bcs()) goto discrete_char;

offset_length:   
   
   lda(INY,LOGOL);                // load byte

   ldx(IMM,LOGOL);                // 16-bit increrment
   jsr_inc16();
   
   sta(MEM,LOADRL);
   
   lda(INY,LOGOL);                // load byte

   ldx(IMM,LOGOL);                // 16 bit increment
   jsr_inc16();
   
   sta(MEM,LOADRH);
   
   lsr(ACC,0);
   lsr(ACC,0);                    // shift right by 10 (top by 2)
   clc();
   adc(IMM,3);                    // add threshold+1 (3)
   sta(MEM,OUT_COUNT);            // store to OUT_COUNT

//   printf("Count=%d\n",mem[OUT_COUNT]);
//   printf("Addy=%02X%02X\n",mem[LOADRH],mem[LOADRL]);
   
output_loop:   

   clc();                        // calculate R+LOADR
   lda(MEM,LOADRL);
   adc(IMM,low(R));
   sta(MEM,EFFECTRL);
   
   lda(MEM,LOADRH);
   and(IMM,(1024-1)>>8);
   sta(MEM,LOADRH);
   adc(IMM,high(R));
   sta(MEM,EFFECTRH);
   
   lda(INY,EFFECTRL);             // Load from there
  
//   printf("Loaded %d from $%02X%02X\n",a,mem[EFFECTRH],mem[EFFECTRL]);
   
   ldx(IMM,LOADRL);               // 16 bit increment
   jsr_inc16();   
   
store_byte:   

   sta(INY,OUTPUTL);              // store byte to output
   
//   printf("Writing %d to $%02X%02X\n",a,mem[OUTPUTH],mem[OUTPUTL]);
   
   ldx(IMM,OUTPUTL);              // 16-bit increment
   jsr_inc16();

   pha();                         // calculate R+STORER
   clc();
   lda(MEM,STORERL);
   adc(IMM,low(R));
   sta(MEM,EFFECTRL);
   
   lda(MEM,STORERH);
   and(IMM,(1024-1)>>8);
   sta(MEM,STORERH);
   adc(IMM,high(R));
   sta(MEM,EFFECTRH);

   pla();
   
   sta(INY,EFFECTRL);             // store A there too

//   printf("Also Writing %d to $%02X%02X\n",a,mem[EFFECTRH],mem[EFFECTRL]);   
   
   ldx(IMM,STORERL);               // 16 bit increment
   jsr_inc16();      
   
   dec(MEM,OUT_COUNT);            // count down the out counter
   if (bne()) goto output_loop;   // loop to output_loop
   
   dec(MEM,COUNT);                // count down the mask counter
   if (bne()) goto  test_flags;
   
   goto decompression_loop;
   
discrete_char:   

   lda(INY,LOGOL);                // load byte

   
   ldx(IMM,LOGOL);                // 16-bit increment
   jsr_inc16();
   
   ldx(IMM,1);                    // want to write a single byte
   stx(MEM,OUT_COUNT);
   
   goto store_byte;
   
done_logo:
//   bload("ll.bload",8192,8192);
   pointer=OUTPUT;   
   printf("Done, dumping\n");
   
   while(mem[pointer]) {
      printf("%c",mem[pointer]);
      pointer++;
   }

   printf("RLEing\n");

   lda(IMM,high(OUTPUT));
   sta(MEM,OUTPUTH);
   
   lda(IMM,low(OUTPUT));
   sta(MEM,OUTPUTL);             

   sty(MEM,COUNT);  // set count to zero
   sty(MEM,COLOR);  // set color to zero
   
   lda(IMM,64);
   sta(MEM,APPLEY);

   sty(MEM,APPLEXH);
   lda(IMM,20);
   sta(MEM,APPLEXL);
   
   jsr_y_to_addr();
   
rle_loop:   

   lda(INY,OUTPUTL);
   if (beq()) goto rle_done;
       
   cmp(IMM,27);
   if (bne()) goto not_escape;
   
escape:
   ldx(MEM,COUNT);       // don't display if COUNT==0
   if (beq()) goto dont_output;
   jsr_flush_line();         // display our RLE
//   sty(MEM,COUNT);       // set count to zero   
dont_output:   
   jsr_inc_pointer();    // point after escape
   
   lda(INY,OUTPUTL);     // load next byte (should be [ )
	 
find_m:   
   cmp(IMM,'m');
   if (beq()) goto found_m;

   cmp(IMM,'3');
   if (bne()) goto not_three;

   jsr_inc_pointer();
   lda(INY,OUTPUTL);          // can shift right
   and(IMM,7);                // mask      
   asl(ACC,1);
   cmp(IMM,8);
   if (bmi()) goto ok;        // make sure red maps to orange
   lsr(ACC,1);
ok:
   and(IMM,3);
   sta(MEM,COLOR);
	 
not_three:   
   jsr_inc_pointer();
   lda(INY,OUTPUTL);
   goto find_m;
found_m:   
   jsr_inc_pointer();
   goto rle_loop;
   
not_escape:   

   cmp(IMM,10);
   if (bne()) goto not_linefeed;
   
linefeed:   
   jsr_flush_line();
//   sty(MEM,COUNT);    // set count to zero
   jsr_inc_pointer();
   //printf("\n");
   sty(MEM,APPLEXH);
   lda(IMM,20);
   sta(MEM,APPLEXL);
   
   clc();
   lda(MEM,APPLEY);
   adc(IMM,8);
   sta(MEM,APPLEY);
   jsr_y_to_addr();
   
   goto rle_loop;
   
not_linefeed:   
   inc(MEM,COUNT);
   inc(MEM,COUNT);
   inc(MEM,COUNT);
     
   jsr_inc_pointer();
      
   goto rle_loop;

rle_done:   
   printf("It is finished...\n");

	    
//   bload("ll.bload",8192,8192);
   
//   dump_hgr();

   
   // point to output buffer

   copy_logo(version,strlen(version)+1,VERSION);  // +1 to copy null too
   copy_logo(one,strlen(one)+1,ONE);
   copy_logo(nmos,strlen(nmos)+1,NMOS);
   copy_logo(cmos,strlen(cmos)+1,CMOS);
   copy_logo(processor,strlen(processor)+1,PROCESSOR);
   copy_logo(ram,strlen(ram)+1,RAM);
   copy_logo(apple,strlen(apple)+1,APPLE);

   jsr_get_sysinfo();
   

      
   // print version info
   jsr_reset_output();
   lda(IMM,high(VERSION));
   sta(MEM,STRCATH);
   lda(IMM,low(VERSION));
   sta(MEM,STRCATL);
   jsr_strcat();

   jsr_center_and_print();

   // print middle line
   jsr_reset_output();
   lda(IMM,high(ONE));
   sta(MEM,STRCATH);
   lda(IMM,low(ONE));
   sta(MEM,STRCATL);
   jsr_strcat();
   
   lda(MEM,CPU);
   if(bne()) goto cmos;
nmos:
   lda(IMM,high(NMOS));
   sta(MEM,STRCATH);
   lda(IMM,low(NMOS));
   sta(MEM,STRCATL);
   goto done_cpu;
cmos:   
   lda(IMM,high(CMOS));
   sta(MEM,STRCATH);
   lda(IMM,low(CMOS));
   sta(MEM,STRCATL);
done_cpu:   
   jsr_strcat();
   lda(IMM,high(PROCESSOR));
   sta(MEM,STRCATH);
   lda(IMM,low(PROCESSOR));
   sta(MEM,STRCATL);   
   jsr_strcat();

   jsr_num_to_ascii();

   lda(IMM,high(RAM));
   sta(MEM,STRCATH);
   lda(IMM,low(RAM));
   sta(MEM,STRCATL);   
   jsr_strcat();   

   jsr_center_and_print();   

   // print last line
   jsr_reset_output();
   lda(IMM,high(APPLE));
   sta(MEM,STRCATH);
   lda(IMM,low(APPLE));
   sta(MEM,STRCATL);
   jsr_strcat();

   lda(MEM,TYPE);
   sta(INY,OUTPUTL);
   jsr_inc_pointer();
   tya();
   sta(INY,OUTPUTL);
   
   jsr_center_and_print();      

   
//unsigned char one[]="One 1.02MHz ";
//unsigned char nmos[]="6502";
//unsigned char cmos[]="65C02";
//unsigned char processor[]=" Processor, ";
//unsigned char ram[]="kB RAM";
//unsigned char apple[]="Apple II";
//unsigned char types[]=" +ec";
   
//         0         1         2         3         4
//         01234567890123456789012345678901234567890
//   printf("Linux Version 2.6.22.6, Compiled 2007\n");
//   printf("One 1.02MHz 6502 Processor, 128kB RAM\n");
//   printf("Apple IIe\n");   
   /* no inc accumulator instruction */

   return 0;
}
