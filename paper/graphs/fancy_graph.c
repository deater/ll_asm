#include <stdio.h>
#include <string.h>

#define VLIW  0
#define RISC  1
#define EBIT  2
#define CISC  3
#define EMBED 4

#define MAX_POINTS 50
#define COLORS 3
#define TYPES  5

char type_names[TYPES][32]={"VLIW","RISC","8/16-bit","CISC","embedded"};

struct point_type {
   char name[64];
   int type;
   int value;
};

struct point_type points[MAX_POINTS];

char colors[TYPES][COLORS][16]={
     { "0.7 0.1 0.1", "0.8 0.1 0.1", "0.9 0.1 0.1" },
     { "0.3 0.7 0.3", "0.3 0.8 0.3", "0.3 0.9 0.3" },
     { "0.7 0.25 0.7", "0.8 0.25 0.8", "0.9 0.25 0.9"},
     { "0.3 0.7 0.7",  "0.3 0.8 0.8",  "0.3 0.9 0.9"},
     { "0.25 0.25 0.7", "0.25 0.25 0.8", "0.25 0.25 0.9"},
};


int main(int argc, char **argv) {

	int i,j,num_points=0;
	char string[BUFSIZ],*result=NULL;
	char temp_type[BUFSIZ];
	int max_size=0,xmax,xhash;
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
		sscanf(string,"%s %s %d",
			points[num_points].name,
			temp_type,
			&points[num_points].value);

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


	/* Calculate offsets */
	if (max_size>1024) {
		xmax=((max_size/1024)+1)*1024;
		xhash=512;
	} else if (max_size>128) {
		xmax=((max_size/128)+1)*128;
		xhash=64;
	} else {
		xmax=((max_size/32)+1)*32;
		xhash=16;
	}

	/* New Graph */
	fprintf(stdout,"newgraph\n\n");

	/* Make background black */
	fprintf(stdout,"(* make background black *)\n");
	fprintf(stdout,"newcurve marktype box cfill 0 0 0 "
			"marksize 11 60 pts 1.3 5\n");
	fprintf(stdout,"copygraph\n");
	fprintf(stdout,"\n");
	fprintf(stdout,"clip\n");

	/* Setup Axes */
	fprintf(stdout,"xaxis size 3 min 0 max %d "
			"hash %d grid_lines grid_gray 0.8 color 1 1 1\n",
			xmax,xhash);
	fprintf(stdout,"label font Helvetica fontsize 12 : %s",xlabel);
	fprintf(stdout,"hash_labels font Helvetica fontsize 12\n\n");

	fprintf(stdout,"Y 7\n\n");

	fprintf(stdout,"yaxis size 6 min -1 max %d color 1 1 1\n",num_points);
	fprintf(stdout,"no_draw_hash_marks no_auto_hash_labels\n");

	/* Setup Legend */
	fprintf(stdout,"legend custom\n\n");

	/* Black background for legend */
	fprintf(stdout,"newcurve marktype box marksize %d %lf color 0 0 0.3\n",
			xmax/2,5.5);
	fprintf(stdout,"pts\n");
	fprintf(stdout,"%d %d\n\n",
			(xmax/3)*2,(num_points-4));

	/* Print all legend types */
	for(i=0;i<TYPES;i++) {
		fprintf(stdout,"newcurve marktype ybar "
				"marksize %d 0.9 color %s\n",
				xmax/30,colors[i][2]);
		fprintf(stdout,"label vjc hjl font Helvetica "
				"fontsize 14 lcolor 1 1 1 ");
		fprintf(stdout,"label x %d y %d : %s\n",
				xmax/2,(num_points-2)-i,type_names[i]);
		fprintf(stdout,"pts\n\n");
	}


	/* Plot the points */

	for(i=0;i<num_points;i++) {
		for(j=0;j<COLORS;j++) {
			fprintf(stdout,"newcurve marktype ybar "
					"marksize 0.9 %.2f color %s\n",
					1.0-(((double)(j+1)*0.1)),
					colors[points[i].type][j]);
			fprintf(stdout,"pts\n");
			fprintf(stdout,"%d %d (* %s *)\n",
				points[i].value-(xmax/300)*j,i,points[i].name);
		}

		fprintf(stdout,"newcurve color 0.0 0.0 0.0 "
				"marktype text hjl vjc ");
		fprintf(stdout,"font Helvetica fontsize 14 : %s\n",
				points[i].name);
		fprintf(stdout,"pts\n");
		fprintf(stdout,"%d %d  (* %s *)\n",
				xmax/30,i,points[i].name);
		fprintf(stdout,"newcurve color 1.0 1.0 1.0 "
				"marktype text hjl vjc ");
		fprintf(stdout,"font Helvetica fontsize 14 : %s\n",
				points[i].name);
		fprintf(stdout,"pts\n");
		fprintf(stdout,"%d %d  (* %s *)\n",
				(xmax/30)+(xmax/300),i,points[i].name);
	}

	return 0;
}
