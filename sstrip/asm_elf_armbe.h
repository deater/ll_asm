/*
 * These are used to set parameters in the core dumps.
 */
#define ELF_CLASS	ELFCLASS32
//#ifdef __ARMEB__
//#define ELF_DATA	ELFDATA2MSB
//#else
#define ELF_DATA	ELFDATA2LSB
//#endif
#define ELF_ARCH	EM_ARM
