#include <stdio.h>

   int offset=0;

   unsigned char font[3][8]={
      {0,0,0,0,0,0,0,0}, /* space */
      {2,2,7,2,2,7,2,2}, /* # */
      {2,5,5,5,5,5,5,2}, /* O */
   };

   unsigned char screen_byte[8][4]; /* four bit planes */

void putfont(unsigned char letter, int forecolor, int backcolor) {
   int fx,fy,plane,i;
   int symbol;

   if (letter=='#') symbol=1;
   else if (letter=='O') symbol=2;
   else symbol=0;

   //printf("; Symbol %c=%d\n",letter,symbol);

   for(fx=0;fx<3;fx++) {

      for(fy=0;fy<8;fy++) {
         for(plane=0;plane<4;plane++) {
            screen_byte[fy][plane]<<=1;
	    if (font[symbol][fy]&(1<<fx)) {
               /* foreground color */
               screen_byte[fy][plane]|=((forecolor>>plane)&1);
               printf("; fx=%d fy=%d fore=%d sb[%d]=%x\n",
                      fx,fy,(forecolor>>plane)&1,plane,screen_byte[fy][plane]);
            }
            else {
               /* background color */
               screen_byte[fy][plane]|=((backcolor>>plane)&1);
               printf("; fx=%d fy=%d back=%d sb[%d]=%x\n",
                      fx,fy,(backcolor>>plane)&1,plane,screen_byte[fy][plane]);

            }
         }
      }
      offset++;
      if (offset==8) {

         printf("\t; Planes 1 and 0\n");
         for(i=0;i<8;i++) {
            printf("\t.word $%02x%02x\n",screen_byte[i][1],screen_byte[i][0]);
         }
         printf("\t; Planes 3 and 2\n");
         for(i=0;i<8;i++) {
            printf("\t.word $%02x%02x\n",screen_byte[i][3],screen_byte[i][2]);
         }

         offset=0;
      }
   }

}


int main(int argc, char **argv) {

   char buffer[BUFSIZ];
   char *result;
   int i,color,newcolor=0;
   int fore,back;

   printf("tile_data:\n");

   while(1) {

      result=fgets(buffer,BUFSIZ,stdin);
      if (result<=0) break;

      i=0;
      while(1) {

         /* escape char */
         if (buffer[i]==27) {
            i++;
            if (buffer[i]=='[') {
               i++;
            }
            color=0;
            while(1) {
               if ((buffer[i]=='m') || (buffer[i]==';')) {
                  if (color==0) {
                     newcolor&=0xbf;
                  }
                  else if (color==1) {
                     newcolor|=0x40;
                  }
                  else if ((color>=30) && (color<=39)) {
                     newcolor&=0xc7;
                     newcolor|=((color-30)&0x7)<<3;
                  }
                  else if ((color>=40) && (color<=49)) {
                     newcolor&=0xf8;
                     newcolor|=((color-40)&0x7);
                  }

                  color=0;

                  if (buffer[i]=='m') {
                     printf("; Color=%02x\n",newcolor);
                     break;
                  }
                  i++;
                  continue;
               }

               color*=10;
               color+=buffer[i]-0x30;

               i++;
	    }
         }
	 else {
            printf("; Color=%x\n",newcolor);
	    if (newcolor==0x47) { fore=1; back=3;}
            else if (newcolor==0x4f) { fore=2; back=3;}
            else if (newcolor==0x5f) { fore=4; back=3;}
            else if (newcolor==0x7f) { fore=5; back=3;}
            else if (newcolor==0x7) { fore=0; back=3;}
            else if (newcolor==0x78) { fore=5; back=0;}
            else printf("; Unknown color %x!\n",newcolor);
            putfont(buffer[i],fore,back);
         }

         if (buffer[i]=='\n') break;
         i++;
      }

   }

   printf("tile_palette:\n");
   printf("\t.word $0        ; black    r=0 g=0 b=0\n");
   printf("\t.word $3def     ; d. grey  r=7d g=7d b=7d\n");
   printf("\t.word $3dff     ; red      r=ff g=7d b=7d\n");
   printf("\t.word $56b5     ; l. grey  r=aa g=aa b=aa\n");
   printf("\t.word $3ff      ; yellow   r=ff g=ff b=0\n");
   printf("\t.word $7fff     ; white    r=ff g=ff b=ff\n");

   return 0;
}
