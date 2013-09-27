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
	int divide;
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

	int i,num_points=0;
	char string[BUFSIZ],*result=NULL;
	char temp_type[BUFSIZ];
	int max_size=0,ymax,yhash;
	char xlabel[BUFSIZ];
	int clip_axis=0,stripey_divides=0;

	/* read the xlabel */
	result=fgets(xlabel,BUFSIZ,stdin);

	/* read the clip_axis */
	result=fgets(string,BUFSIZ,stdin);
	sscanf(string,"%d",&clip_axis);

	/* read stripey_divides */
	result=fgets(string,BUFSIZ,stdin);
	sscanf(string,"%d",&stripey_divides);

	/* read the data */
	while(1) {
		result=fgets(string,BUFSIZ,stdin);
		if (result==NULL) break;
		sscanf(string,"%s %s %d %d",
			points[num_points].name,
			temp_type,
			&points[num_points].value,
			&points[num_points].divide);

		if (!strcmp(temp_type,"VLIW")) points[num_points].type=VLIW;
		if (!strcmp(temp_type,"RISC")) points[num_points].type=RISC;
		if (!strcmp(temp_type,"EBIT")) points[num_points].type=EBIT;
		if (!strcmp(temp_type,"CISC")) points[num_points].type=CISC;
		if (!strcmp(temp_type,"EMBED")) points[num_points].type=EMBED;

		if (points[num_points].value > max_size) {
			max_size=points[num_points].value;
		}

		num_points++;
	}

	if (clip_axis) max_size=clip_axis;

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
	//printf("clip\n");
	printf("X 10\n");
	printf("Y 2.5\n");
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
			(num_points-4),
			ymax-((0+i)*ymax/8),
			type_names[i]);
		printf("pts\n");
		printf("\n");
	}
	if (stripey_divides) {
		printf("newcurve marktype xbar marksize 0.9 "
			"pattern stripe 45 color 0.0 0.0 0.0\n");
		printf("label vjc hjl font Helvetica fontsize 12 "
			"label x %d y %d : No HW divide\n",
			(num_points-4),ymax-((0+i)*ymax/8));
		printf("pts\n");
		printf("\n");
	}

	printf("\n");


	/* Plot the points */

	for(i=0;i<num_points;i++) {

		if (points[i].value==0) {
			printf("newcurve marktype text fontsize 12 rotate 90 "
				": N/A\n");
			printf("pts\n");
			printf("%d %d (* %s *)\n",
				i,
				yhash,
				points[i].name);
			printf("\n");

		}

		else {

			printf("newcurve marktype xbar marksize 0.9 "
				"%s color %s\n",
				(stripey_divides&&points[i].divide)?
					"pattern stripe 45":" ",
				colors[points[i].type][0]);
			printf("pts\n");
			printf("%d %d (* %s *)\n",
				i,
				points[i].value>ymax?ymax:points[i].value,
				points[i].name);
			printf("\n");
		}
	}


	/* Put the clipped labels */
	for(i=0;i<num_points;i++) {
		if (points[i].value>ymax) {
			printf("newcurve "
			"marktype text fontsize 12 : %d\n",
			points[i].value);
			printf("pts\n");
			printf("%d %d (* %s *)\n",i,ymax,points[i].name);
			printf("\n");

		}
	}


	return 0;
}


