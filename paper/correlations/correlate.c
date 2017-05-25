#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <errno.h>
#include <string.h>
#include <math.h>

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



#define CONFIG_VLIW		0
#define CONFIG_RISC		1
#define CONFIG_EMBEDDED		2
#define CONFIG_CISC		3
#define CONFIG_SIXTEENBIT	4
#define CONFIG_EIGHTBIT		5
#define CONFIG_YEAR		6
#define CONFIG_ENDIAN		7
#define CONFIG_BITS		8
#define CONFIG_MIN_INSTR	9
#define CONFIG_MAX_INSTR	10
#define CONFIG_NUM_ARGS		11
#define CONFIG_GPRS		12
#define CONFIG_ZERO_REG		13
#define CONFIG_UNALIGNED	14
#define CONFIG_AUTOINC		15
#define CONFIG_HWDIV		16
#define CONFIG_STATUSFLAG	17
#define CONFIG_BRANCHDELAY	18
#define CONFIG_PREDICATION	19
#define CONFIG_FIRST_ADDRESS	20
#define CONFIG_LOG_FIRST_ADDR	21
#define MAX_CONFIG		22

static char config_names[MAX_CONFIG][100]={
	"VLIW",
	"RISC",
	"Embedded",
	"CISC",
	"Sixteen-bit",
	"Eight-bit",
	"Year",
	"Endian",
	"Bits",
	"Min Instr",
	"Max Instr",
	"Num Args",
	"GP Regs",
	"Zero Reg",
	"Unaligned",
	"AutoInc",
	"HW Divide",
	"Status Flag",
	"Branch Delay Slot",
	"Predication",
	"First Address",
	"Log First Address",
};

#define SIZE_FINDSTRING	0
#define SIZE_LZSS		1
#define SIZE_NUMASCII		2
#define SIZE_STRCAT		3
#define SIZE_OVERALL		4
#define MAX_SIZE		5

static char size_names[MAX_SIZE][100]={
	"findstring",
	"lzss",
	"numascii",
	"strcat",
	"overall",
};

int main(int argc, char **argv) {

	FILE *fff;
	DIR *dir;
	struct dirent *dir_file;
	int arch=0,i;
	char filename[BUFSIZ];
	char *result,string[BUFSIZ];
	double xbar,ybar,sx,sy;
	double r;

	struct {
		char name[BUFSIZ];
		int config[MAX_CONFIG];
		int size[MAX_SIZE];
	} hw_info[MAX_ARCH];

	dir=opendir("../configs");
	if (dir==NULL) {
		fprintf(stderr,"Error opening ../configs\n");
		exit(1);
	}

	long long temp_long;
	double temp_double;

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
		sscanf(string,"%d",&hw_info[arch].config[CONFIG_VLIW]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"\n%d",&hw_info[arch].config[CONFIG_RISC]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"\n%d",&hw_info[arch].config[CONFIG_EMBEDDED]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"\n%d",&hw_info[arch].config[CONFIG_CISC]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"\n%d",&hw_info[arch].config[CONFIG_SIXTEENBIT]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"\n%d",&hw_info[arch].config[CONFIG_EIGHTBIT]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"\n%d",&hw_info[arch].config[CONFIG_YEAR]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].config[CONFIG_ENDIAN]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].config[CONFIG_BITS]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].config[CONFIG_MIN_INSTR]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].config[CONFIG_MAX_INSTR]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].config[CONFIG_NUM_ARGS]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].config[CONFIG_GPRS]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].config[CONFIG_ZERO_REG]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].config[CONFIG_UNALIGNED]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].config[CONFIG_AUTOINC]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%lf",&temp_double);
		hw_info[arch].config[CONFIG_HWDIV]=temp_double*10.0;
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].config[CONFIG_STATUSFLAG]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].config[CONFIG_BRANCHDELAY]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%d",&hw_info[arch].config[CONFIG_PREDICATION]);
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%lf",&temp_double);
		hw_info[arch].config[CONFIG_LOG_FIRST_ADDR]=(int)temp_double;
		result=fgets(string,BUFSIZ,fff);
		sscanf(string,"%llx",&temp_long);
		hw_info[arch].config[CONFIG_FIRST_ADDRESS]=temp_long;

		if (result==NULL) {
			fprintf(stderr,"Error in result!\n");
			exit(0);
		}

		hw_info[arch].size[SIZE_LZSS]=read_data("../data/data.lzss",
						hw_info[arch].name);

		hw_info[arch].size[SIZE_FINDSTRING]=read_data("../data/data.findstring",
						hw_info[arch].name);

		hw_info[arch].size[SIZE_NUMASCII]=read_data("../data/data.num_ascii",
						hw_info[arch].name);

		hw_info[arch].size[SIZE_STRCAT]=read_data("../data/data.strcat",
						hw_info[arch].name);

		hw_info[arch].size[SIZE_OVERALL]=read_data("../data/data.overall",
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

	int size,config;

	for(size=0;size<MAX_SIZE;size++) {
	printf("%s\n",size_names[size]);

	for(config=0;config<MAX_CONFIG;config++) {

	xbar=0.0; ybar=0.0;
	for(i=0;i<arch;i++) {
		xbar+=hw_info[i].config[config];
		ybar+=hw_info[i].size[size];
	}
	xbar/=arch;
	ybar/=arch;

	sx=0.0; sy=0.0;
	for(i=0;i<arch;i++) {
		sx+=(hw_info[i].config[config]-xbar)*
			(hw_info[i].config[config]-xbar);
		sy+=(hw_info[i].size[size]-ybar)*
			(hw_info[i].size[size]-ybar);
	}
	sx=sqrt(sx/arch);
	sy=sqrt(sy/arch);

	r=0.0;
	for(i=0;i<arch;i++) {
		 r+=((hw_info[i].config[config]-xbar)/sx) *
			((hw_info[i].size[size]-ybar)/sy);
	}
	r/=arch;

	printf("%20s\t%lf\n",config_names[config],r);

	}
	printf("\n\n");
	}

	return 0;

}
