#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <errno.h>
#include <string.h>

#define MAX_ARCH	100

int read_data(char *filename, char *name) {

	int size=0,read_size=0;
	FILE *fff;
	char *result,string[BUFSIZ];
	char read_name[BUFSIZ];

	fff=fopen(filename,"r");
	if (fff==NULL) {
		fprintf(stderr,"Error opening %s\n",filename);
		exit(1);
	}

	while(1) {
		result=fgets(string,BUFSIZ,fff);
		if (result==NULL) break;

		sscanf(string,"%s %*s %d",read_name,&read_size);
		if (!strcmp(name,read_name)) {
			fclose(fff);
			return read_size;
		}
	}

	fprintf(stderr,"Error!  %s not found in %s\n",
			name,filename);

	fclose(fff);

	return size;

}

int main(int argc, char **argv) {

	FILE *fff;
	DIR *dir;
	struct dirent *dir_file;
	int arch=0,i;
	char filename[BUFSIZ];
	char *result,string[BUFSIZ];

	struct {
		char name[BUFSIZ];
		int vliw;
		int risc;
		int embedded;
		int cisc;
		int sixteenbit;
		int eightbit;
		int year;
		int endian;
		int bits;
		int min_instr;
		int max_instr;
		int num_args;
		int gprs;
		int zero_reg;
		int unaligned_mem;
		int autoinc_addr;
		double hw_div;
		int status_flag;
		int branch_delay;
		int predication;
		long long first_address;
		double log_first_address;
		int findstring_size;
		int lzss_size;
		int numascii_size;
		int strcat_size;
		int overall_size;
	} hw_info[MAX_ARCH];

	dir=opendir("../configs");
	if (dir==NULL) {
		fprintf(stderr,"Error opening ../configs\n");
		exit(1);
	}

	while(1) {
		dir_file=readdir(dir);
		if (dir_file==NULL) break;
		if (dir_file->d_name[0]=='.') continue;

		sprintf(filename,"../configs/%s",dir_file->d_name);

		fff=fopen(filename,"r");
		if (fff==NULL) {
			fprintf(stderr,"Error opening %s : %s\n",
				filename,strerror(errno));
			exit(1);
		}

		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%s",hw_info[arch].name);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].vliw);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"\n%d",&hw_info[arch].risc);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"\n%d",&hw_info[arch].embedded);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"\n%d",&hw_info[arch].cisc);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"\n%d",&hw_info[arch].sixteenbit);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"\n%d",&hw_info[arch].eightbit);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"\n%d",&hw_info[arch].year);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].endian);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].bits);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].min_instr);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].max_instr);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].num_args);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].gprs);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].zero_reg);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].unaligned_mem);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].autoinc_addr);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%lf",&hw_info[arch].hw_div);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].status_flag);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].branch_delay);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].predication);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%lf",&hw_info[arch].log_first_address);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%llx",&hw_info[arch].first_address);

		hw_info[arch].lzss_size=read_data("../data/data.lzss",
						hw_info[arch].name);

		hw_info[arch].findstring_size=read_data("../data/data.findstring",
						hw_info[arch].name);

		hw_info[arch].numascii_size=read_data("../data/data.num_ascii",
						hw_info[arch].name);

		hw_info[arch].strcat_size=read_data("../data/data.strcat",
						hw_info[arch].name);

		hw_info[arch].overall_size=read_data("../data/data.overall",
						hw_info[arch].name);


		fclose(fff);
		arch++;
		if (arch>=MAX_ARCH) {
			fprintf(stderr,"Too many arches %d >= %d\n",
				arch,MAX_ARCH);
			exit(1);
		}

	}

	closedir(dir);

	printf("newgraph\n");
	//printf("clip\n");
	printf("X 5\n");
	printf("Y 5\n");
	printf("\n");
	printf("(* legend defaults font Helvetica fontsize 14 *)\n");
	printf("\n");
	printf("(* title font Helvetica fontsize 14 y 2900 vjt : "
		"Total Size of Executable *)\n");
	printf("\n");
	printf("legend custom\n");
	printf("\n");
	printf("yaxis size 4 min 0\n");
		// max %d hash %d grid_lines grid_gray 0.8\n",ymax,yhash);
	printf("label font Helvetica fontsize 12 : bytes\n");
	printf("hash_labels font Helvetica fontsize 12\n");
	printf("\n");
	printf("xaxis size 4\n");// min -1 max %d\n",num_points);
	//printf("no_draw_hash_marks no_auto_hash_labels\n");
	//printf("hash_labels hjr vjc rotate 45 font Helvetica fontsize 12\n");

	printf("newcurve\n");
	printf("pts\n");
	for(i=0;i<arch;i++) {

		printf("%d %d (* %s *)\n",
			hw_info[i].min_instr,
			hw_info[i].overall_size,
			hw_info[i].name);
	}

	return 0;

}
