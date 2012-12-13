#include <stdio.h>

#define VLIW  0
#define RISC  1
#define EBIT  2
#define CISC  3
#define EMBED 4

#define POINTS 24
#define COLORS 3
#define TYPES  5

char type_names[TYPES][32]={"VLIW","RISC","8/16-bit","CISC","embedded"};

struct point_type { 
   char name[64];
   int type;
   int value;
};

struct point_type points[POINTS]={
     {  "ia64",VLIW,2826},
     {  "alpha",RISC,1821},
     {  "RiSC",RISC,1418},
     {  "pa-risc",RISC,1400},
     {  "sparc",RISC,1397},   
     {  "microblaze",RISC,1298},      
     {  "mips",RISC,1276},
     {  "m88k",RISC,1240},   
     {  "arm.eabi",RISC,1186},      
     {  "PowerPC",RISC,1165},         
     {  "6502",EBIT,1130},
     {  "s390",CISC,1064},   
     {  "x86_64",CISC,1033},      
     {  "vax",CISC,1010},         
     {  "sh3",EMBED,994},         
     {  "m68k",CISC,982},            
     {  "i386",CISC,969},
     {  "THUMB",EMBED,937},                  
     {  "Thumb-2",EMBED,925},                     
     {  "avr32",EMBED,914},   
     {  "crisv32",EMBED,905},
     {  "z80",EBIT,891},
     {  "pdp-11",EBIT,890},         
     {  "8086",EBIT,780},   
};


char colors[TYPES][COLORS][16]={
     { "0.7 0.1 0.1", "0.8 0.1 0.1", "0.9 0.1 0.1" },
     { "0.3 0.7 0.3", "0.3 0.8 0.3", "0.3 0.9 0.3" },  
     { "0.7 0.25 0.7", "0.8 0.25 0.8", "0.9 0.25 0.9"},
     { "0.3 0.7 0.7",  "0.3 0.8 0.8",  "0.3 0.9 0.9"},
     { "0.25 0.25 0.7", "0.25 0.25 0.8", "0.25 0.25 0.9"},
};


int main(int argc, char **argv) {
   
   int i,j;
   
   fprintf(stdout,"newgraph\n\n");
   fprintf(stdout,"(* make background black *)\n");
   fprintf(stdout,"newcurve marktype box cfill 0 0 0 marksize 11 60 pts 1.3 5\n");
   fprintf(stdout,"copygraph\n");
   fprintf(stdout,"\n");
   fprintf(stdout,"clip\n");
   fprintf(stdout,"xaxis size 3 min 0 max 3000 hash 512 grid_lines grid_gray 0.8 color 1 1 1\n");
   fprintf(stdout,"label font Helvetica fontsize 12 : bytes\n");
   fprintf(stdout,"hash_labels font Helvetica fontsize 12\n\n");

   fprintf(stdout,"Y 7\n\n");
   
   fprintf(stdout,"yaxis size 6 min -1 max %d color 1 1 1\n",POINTS);
   fprintf(stdout,"no_draw_hash_marks no_auto_hash_labels\n");

   fprintf(stdout,"legend custom\n\n");



   fprintf(stdout,"newcurve marktype box marksize 1200 5.5 color 0 0 0\n");
   fprintf(stdout,"pts\n");
   fprintf(stdout,"2350 20\n\n");
     
   
   for(i=0;i<TYPES;i++) {
      fprintf(stdout,"newcurve marktype ybar marksize 100 0.9 color %s\n",colors[i][2]);
      fprintf(stdout,"label vjc hjl font Helvetica fontsize 14 lcolor 1 1 1 ");
      fprintf(stdout,"label x 2000 y %d : %s\n",22-i,type_names[i]);
      fprintf(stdout,"pts\n\n");
   }
   
#if 0     
     newcurve marktype xbar marksize 0.9 color 0.3 0.7 0.3
     label vjc hjl font Helvetica fontsize 12 label x 18 y 2368 : RISC
     pts
     
     newcurve marktype xbar marksize 0.9 color 0.3 0.9 0.9
     label vjc hjl font Helvetica fontsize 12 label x 18 y 2048 : CISC
     pts
     
     newcurve marktype xbar marksize 0.9 color 0.25 0.25 0.8
     label vjc hjl font Helvetica fontsize 12 label x 18 y 1728 : embedded
     pts
     
     newcurve marktype xbar marksize 0.9 color 0.8 0.25 0.8
     label vjc hjl font Helvetica fontsize 12 label x 18 y 1408 : 8/16-bit
     pts
#endif     
   
   for(i=0;i<POINTS;i++) {
      for(j=0;j<COLORS;j++) {
	 fprintf(stdout,"newcurve marktype ybar marksize 0.9 %.2f color %s\n",
		 1.0-(((double)(j+1)*0.1)),colors[points[i].type][j]);
	 fprintf(stdout,"pts\n");
         fprintf(stdout,"%d %d (* %s *)\n",points[i].value-10*j,i,points[i].name);	 
      }
      fprintf(stdout,"newcurve color 0.0 0.0 0.0 marktype text hjl vjc ");
      fprintf(stdout,"font Helvetica fontsize 14 : %s\n",points[i].name);
      fprintf(stdout,"pts\n");
      fprintf(stdout,"118 %d  (* %s *)\n",i,points[i].name);
      fprintf(stdout,"newcurve color 1.0 1.0 1.0 marktype text hjl vjc ");
      fprintf(stdout,"font Helvetica fontsize 14 : %s\n",points[i].name);
      fprintf(stdout,"pts\n");
      fprintf(stdout,"128 %d  (* %s *)\n",i,points[i].name);      
   }
   


       return 0;
}
