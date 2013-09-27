#include <stdio.h>
#include <string.h>

#define VLIW  0
#define RISC  1
#define CISC  2
#define EMBED 3
#define EBIT  4

#define MAX_POINTS 50
#define COLORS 3

#define NUM_TYPES  5

char type_names[NUM_TYPES][32]={
	"VLIW",
	"RISC",
	"CISC",
	"embedded",
	"8/16-bit",
};

struct point_type {
	char name[64];
	int type;
	int value;
};

struct point_type points[MAX_POINTS];

char colors[NUM_TYPES][COLORS][16]={
	{ "0.7 0.1 0.1", "0.8 0.1 0.1", "0.9 0.1 0.1" },	/* VLIW */
	{ "0.3 0.7 0.3", "0.3 0.8 0.3", "0.3 0.9 0.3" },	/* RISC */
	{ "0.3 0.7 0.7",  "0.3 0.8 0.8",  "0.3 0.9 0.9"},	/* CISC */
	{ "0.25 0.25 0.7", "0.25 0.25 0.8", "0.25 0.25 0.9"},	/* embed */
	{ "0.7 0.25 0.7", "0.8 0.25 0.8", "0.9 0.25 0.9"},	/* 8-bit */
};


int main(int argc, char **argv) {

	int i,j,num_points=0;
	char string[BUFSIZ],*result=NULL;
	char temp_type[BUFSIZ];
	int max_size=0,ymax,yhash;
	char xlabel[BUFSIZ];

	result=fgets(xlabel,BUFSIZ,stdin);

	while(1) {
		result=fgets(string,BUFSIZ,stdin);
		if (result==NULL) break;
		sscanf(string,"%s %s %d",
			points[num_points].name,
			temp_type,
			&points[num_points].value);

		if (!strcmp(temp_type,"VLIW")) points[num_points].type=VLIW;
		if (!strcmp(temp_type,"RISC")) points[num_points].type=RISC;
		if (!strcmp(temp_type,"EBIT")) points[num_points].type=EBIT;
		if (!strcmp(temp_type,"CISC")) points[num_points].type=CISC;
		if (!strcmp(temp_type,"EMBED")) points[num_points].type=EMBED;
		if (!strcmp(temp_type,"EMBED")) points[num_points].type=EMBED;

		if (points[num_points].value > max_size) {
			max_size=points[num_points].value;
		}

		num_points++;
	}

	/* Calculate offsets */
	if (max_size>1024) {
		ymax=((max_size/1024)+1)*1024;
		yhash=512;
	} else if (max_size>128) {
		ymax=((max_size/128)+1)*128;
		yhash=64;
	} else {
		ymax=((max_size/32)+1)*32;
		yhash=16;
	}

	/* New Graph */
	printf("newgraph\n");
	printf("clip\n");
	printf("\n");
	printf("(* legend defaults font Helvetica fontsize 14 *)\n");
	printf("\n");
	printf("(* title font Helvetica fontsize 14 y 2900 vjt : "
		"Total Size of Executable *)\n");
	printf("\n");
	printf("legend custom\n");
	printf("\n");
	printf("yaxis size 1.25 min 0 max %d hash %d "
		"grid_lines grid_gray 0.8\n",
		ymax,yhash);
	printf("label font Helvetica fontsize 12 : bytes\n");
	printf("hash_labels font Helvetica fontsize 12\n");
	printf("\n");
	printf("xaxis size 9 min -1 max %d\n",num_points);
	printf("no_draw_hash_marks no_auto_hash_labels\n");
	printf("hash_labels hjr vjc rotate 45 font Helvetica fontsize 12\n");
	for(i=0;i<num_points;i++) {
		printf("hash_label at %d : %s\n",i,points[i].name);
	}
	printf("\n");

	/* make the legend */
	for(i=0;i<NUM_TYPES;i++) {
		printf("newcurve marktype xbar marksize 0.9 "
			"color %s\n",colors[i][0]);
		printf("label vjc hjl font Helvetica fontsize 12 "
			"label x %d y %d : %s\n",
			(num_points/5)*4,
			ymax-((1+i)*ymax/10),
			type_names[i]);
		printf("pts\n");
		printf("\n");
	}
#if 0
	printf("newcurve marktype xbar marksize 0.9 color 0.3 0.7 0.3\n");
	printf("label vjc hjl font Helvetica fontsize 12 label x 20 y 2368 : RISC\n");
	printf("pts\n");
	printf("\n");
	printf("newcurve marktype xbar marksize 0.9 color 0.3 0.9 0.9\n");
	printf("label vjc hjl font Helvetica fontsize 12 label x 20 y 2048 : CISC\n");
	printf("pts\n");
	printf("\n");
	printf("newcurve marktype xbar marksize 0.9 color 0.25 0.25 0.8\n");
	printf("label vjc hjl font Helvetica fontsize 12 label x 20 y 1728 : embedded\n");
	printf("pts\n");
	printf("\n");
	printf("newcurve marktype xbar marksize 0.9 color 0.8 0.25 0.8\n");
	printf("label vjc hjl font Helvetica fontsize 12 label x 20 y 1408 : 8/16-bit\n");
	printf("pts\n");
#endif

	printf("\n");

	/* Plot the points */

	for(i=0;i<num_points;i++) {
		printf("newcurve marktype xbar marksize 0.9 "
			"color %s\n",colors[points[i].type][0]);
		printf("pts\n");
		printf("%d %d (* %s *)\n",i,points[i].value,points[i].name);
		printf("\n");
	}

	return 0;
}
