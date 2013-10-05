#include <stdio.h>

int main(int argc, char **argv) {

	char *result;
	char string[BUFSIZ];
	FILE *fff;
	char filename[BUFSIZ];

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
	} hw_info;

	while(1) {

		result=fgets(string,BUFSIZ,stdin);
		if (result==NULL) break;

		sscanf(string,	"%s "
				"%*d %*d %*d %*d %*d "
				"%d %d %d %d %d "
				"%d %d %d %d %d "
				"%d %d %d %d %d"
				"%lf %d %d %d %lf %lld",
			hw_info.name,
			&hw_info.vliw,
			&hw_info.risc,
			&hw_info.embedded,
			&hw_info.cisc,
			&hw_info.eightbit,
			&hw_info.year,
			&hw_info.endian,
			&hw_info.bits,
			&hw_info.min_instr,
			&hw_info.max_instr,
			&hw_info.num_args,
			&hw_info.gprs,
			&hw_info.zero_reg,
			&hw_info.unaligned_mem,
			&hw_info.autoinc_addr,
			&hw_info.hw_div,
			&hw_info.status_flag,
			&hw_info.branch_delay,
			&hw_info.predication,
			&hw_info.log_first_address,
			&hw_info.first_address);

		sprintf(filename,"config.%s",hw_info.name);
		fff=fopen(filename,"w");

		fprintf(fff,"%s\n",hw_info.name);
		fprintf(fff,"%d\t# VLIW\n",hw_info.vliw);
		fprintf(fff,"%d\t# RISC\n",hw_info.risc);
		fprintf(fff,"%d\t# Embedded\n",hw_info.embedded);
		fprintf(fff,"%d\t# CISC\n",hw_info.cisc);
		fprintf(fff,"0\t# 16-bit\n");
		fprintf(fff,"%d\t# 8-bit\n",hw_info.eightbit);
		fprintf(fff,"%d\t# Year introduced\n",hw_info.year);
		fprintf(fff,"%d\t# Endian 0=little 1=big\n",hw_info.endian);
		fprintf(fff,"%d\t# Wordsize (bits)\n",hw_info.bits);
		fprintf(fff,"%d\t# size of smallest instruction (bytes)\n",hw_info.min_instr);
		fprintf(fff,"%d\t# size of largest instruction (bytes)\n",hw_info.max_instr);
		fprintf(fff,"%d\t# numer of arguments to typical opcode\n",hw_info.num_args);
		fprintf(fff,"%d\t# number of general purpose registers\n",hw_info.gprs);
		fprintf(fff,"%d\t# has a 0 register\n",hw_info.zero_reg);
		fprintf(fff,"%d\t# has unaligned memory access\n",hw_info.unaligned_mem);
		fprintf(fff,"%d\t# has auto-incrementing addressing mode\n",hw_info.autoinc_addr);
		fprintf(fff,"%lf\t# hardware divide 1.0=full 0.7=no remainder 0.3=pipelined\n",hw_info.hw_div);
		fprintf(fff,"%d\t# has status flag register\n",hw_info.status_flag);
		fprintf(fff,"%d\t# has branch delay slot\n",hw_info.branch_delay);
		fprintf(fff,"%d\t# has predication\n",hw_info.predication);
		fprintf(fff,"%lf\t# log2 of virt address of first instruction\n",hw_info.log_first_address);
		fprintf(fff,"0x%llx\t# virt address of first instruction\n",hw_info.first_address);
		fclose(fff);
	}


	return 0;

}
