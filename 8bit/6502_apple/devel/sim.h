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

extern unsigned char a,x,y;
extern unsigned char mem[65536];
extern unsigned char p;
extern unsigned short sp;

void adc(int type,unsigned short value);
void and(int type,unsigned short value);
void asl(int type,unsigned short value);
int bcc();
int bcs();
int beq();
void bit(int type,unsigned short value);
int bmi();
int bne();
int bpl();
void brk_6502();
void bvc();
void bvs();
void clc();
void cld();
void cli();
void clv();
void cmp(int type, unsigned short value);
void cpx(int type, unsigned short value);
void cpy();
void dec(int type,unsigned short value);
void dex();
void dey();
void eor(int type,unsigned short value);
void inc(int type,unsigned short value);
void inx();
void iny();
void jmp();
void jsr();
void lda(int type,unsigned short value);
void ldx(int type,unsigned short value);
void ldy(int type,unsigned short value);
void lsr(int type,unsigned short value);
void nop();
void ora(int type,unsigned short value);
void pha();
void php();
void pla();
void plp();
void rol();
void ror(int type,unsigned short value);
void rti();
void rts();
void sbc(int type,unsigned short value);
void sec();
void sed();
void sei();
void sta(int type,unsigned short value);
void stx(int type,unsigned short value);
void sty(int type,unsigned short value);
void tax();
void tay();
void tsa();
void txa();
void txs();
void tya();

unsigned char high(int value);
unsigned char low(int value);


void bload(char *filename,unsigned short addr,int size);
   
