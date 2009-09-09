/* sstrip: Copyright (C) 1999-2001 by Brian Raiter, under the GNU
 * General Public License. No warranty. See COPYING for details.
 *  Various changes by Vince Weaver
 */

#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<errno.h>
#include	<unistd.h>
#include	<fcntl.h>
#include	<elf.h>
#include        <endian.h>
#include        <byteswap.h>
#include	ARCHITECTURE /* made local as new distros don't have it */

#if ELF_CLASS == ELFCLASS32
#define	Elf_Ehdr	Elf32_Ehdr
#define	Elf_Phdr	Elf32_Phdr
#else
#define	Elf_Ehdr	Elf64_Ehdr
#define	Elf_Phdr	Elf64_Phdr
#endif

/* Endianess of the host */
#if __BYTE_ORDER == __LITTLE_ENDIAN
static int little_endian=1;
#else
static int little_endian=0;
#endif

static int swap_bytes=0;

/* The name of the program.
 */
static char const      *progname;

/* The name of the current file.
 */
static char const      *filename;


/* A simple error-handling function. 0 is always returned for the
 * convenience of the caller.
 */
static int err(char const *errmsg)
{
    fprintf(stderr, "%s: %s: %s\n", progname, filename, errmsg);
    return 0;
}

/* A macro for I/O errors: The given error message is used only when
 * errno is not set.
 */
#define	ferr(msg)	(err(errno ? strerror(errno) : (msg)))

/* readelfheader() reads the ELF header into our global variable, and
 * checks to make sure that this is in fact a file that we should be
 * munging.
 */
static int readelfheader(int fd, Elf_Ehdr *ehdr) {
    errno = 0;
    if (read(fd, ehdr, sizeof *ehdr) != sizeof *ehdr) {
	return ferr("missing or incomplete ELF header.");
    }
   
    /* Check the ELF signature.
     */
    if (!(ehdr->e_ident[EI_MAG0] == ELFMAG0 &&
	  ehdr->e_ident[EI_MAG1] == ELFMAG1 &&
	  ehdr->e_ident[EI_MAG2] == ELFMAG2 &&
	  ehdr->e_ident[EI_MAG3] == ELFMAG3)) {
	printf("missing ELF signature.");
        exit(0);
    }

    /* Compare the file's class and endianness with the program's.
     */

   if (ELF_DATA == ELFDATA2LSB) {         /* 2's complement, little endian */
      if (!little_endian) {
         fprintf(stderr,"Warning!  Host and target endianess don't match!\n");
	 swap_bytes=1;
      }
   }
   else if (ELF_DATA == ELFDATA2MSB) {    /* 2's complement, big endian */
      if (little_endian) {
         fprintf(stderr,"Warning!  Host and target endianess don't match!\n");
	 swap_bytes=1;
      }
   }
   else {
      err("Unknown endianess type.");
   }
   
   if (ELF_CLASS == ELFCLASS64) {
      if (sizeof(void *)!=8) err("host!=elf word size not supported");
   }
   else if (ELF_CLASS == ELFCLASS32) {
      if (sizeof(void *)!=4) err("host!=elf word size not supported");
   }
   else {
      err("Unknown word size");
   }
   
    if (ehdr->e_ident[EI_DATA] != ELF_DATA) {
       err("ELF file has different endianness.");
    }

    if (ehdr->e_ident[EI_CLASS] != ELF_CLASS) {
       err("ELF file has different word size.");
    }

    /* Check the target architecture.
     */
     { unsigned short machine;
       machine=ehdr->e_machine;
       if (swap_bytes) machine=bswap_16(machine);
	
       if (machine != ELF_ARCH) {
          fprintf(stderr, "Warning!  "
	       "ELF file created for different architecture: %d\n",
	       ehdr->e_machine);
       }
     }

    /* Verify the sizes of the ELF header and the program segment
     * header table entries.
     */
     { short ehsize;
	ehsize=ehdr->e_ehsize;
	if (swap_bytes) ehsize=bswap_16(ehsize);
    
	if (ehsize != sizeof(Elf_Ehdr)) {
           fprintf(stderr,"Warning! "
	       "unrecognized ELF header size: %d != %ld\n",
	       ehdr->e_ehsize,(long)sizeof(Elf_Ehdr));
	}
     }
   
     {
	short phentsize;
	phentsize=ehdr->e_phentsize;
	if (swap_bytes) phentsize=bswap_16(phentsize);
	
        if (phentsize != sizeof(Elf_Phdr)) {
           fprintf(stderr,"Warning! "
	      "unrecognized program segment header size: %d != %ld\n",
	      ehdr->e_phentsize,(long)sizeof(Elf_Phdr));
	}
     }
   
    /* Finally, check the file type.
     */
     {short e_type;
      e_type=ehdr->e_type;
      if (swap_bytes) e_type=bswap_16(e_type);
	
      if (e_type != ET_EXEC && e_type != ET_DYN) {
	return err("not an executable or shared-object library.");
      }
     }
   
    return 1;
}

/* readphdrtable() loads the program segment header table into memory.
 */
static int readphdrtable(int fd, Elf_Ehdr const *ehdr, Elf_Phdr **phdrs) {

    size_t	size;
    
    short e_phnum;
   
    /* should be endian safe, as zero is the same in all endianesses */
    if (!ehdr->e_phoff || !ehdr->e_phnum) {
	return err("ELF file has no program header table.");
    }

    e_phnum=ehdr->e_phnum;
    if (swap_bytes) e_phnum=bswap_16(e_phnum);
   
    size = e_phnum * sizeof **phdrs;

    if (!(*phdrs = malloc(size))) {
	return err("Out of memory!");
    }

    errno = 0;

    if (read(fd, *phdrs, size) != (ssize_t)size) {
	return ferr("missing or incomplete program segment header table.");
    }

    return 1;
}

/* getmemorysize() determines the offset of the last byte of the file
 * that is referenced by an entry in the program segment header table.
 * (Anything in the file after that point is not used when the program
 * is executing, and thus can be safely discarded.)
 */
static int getmemorysize(Elf_Ehdr const *ehdr, Elf_Phdr *phdrs,
			 unsigned long *newsize)
{
    Elf_Phdr    *phdr;
    unsigned long	size, n ,end=0;
    int			i;

    unsigned long e_phoff;
    short e_phnum;

    unsigned long p_offset,p_filesz;
   
    e_phoff=ehdr->e_phoff;
   
#if (ELF_CLASS==ELFCLASS64)
    if (swap_bytes) e_phoff=bswap_64(e_phoff);
#else
    if (swap_bytes) e_phoff=bswap_32(e_phoff);
#endif
   
    e_phnum=ehdr->e_phnum;
    if (swap_bytes) e_phnum=bswap_16(e_phnum);
   
    /* Start by setting the size to include the ELF header and the
     * complete program segment header table.
     */
    size = e_phoff + e_phnum * sizeof *phdrs;

    if (size < sizeof *ehdr) {
	size = sizeof *ehdr;
        printf("-> Adjusting that to %ld\n",size);
    }

    /* Then keep extending the size to include whatever data the
     * program segment header table references.
     */
    for (i = 0, phdr = phdrs ; i < e_phnum ; ++i, ++phdr) {
           /* endian safe as PT_NULL is zero */
	if (phdr->p_type != PT_NULL) {
	   
	   p_offset=phdr->p_offset;
	   p_filesz=phdr->p_filesz;
#if (ELF_CLASS==ELFCLASS64)
    if (swap_bytes) {
       p_offset=bswap_64(p_offset);
       p_filesz=bswap_64(p_filesz);
    }
#else
    if (swap_bytes) {
       p_offset=bswap_32(p_offset);
       p_filesz=bswap_32(p_filesz);
    }
#endif
	   
	    n = p_offset + p_filesz;
	    if (n > size)
		size = n;
            end=size;
	}
    }

    *newsize = size;
    return 1;
}

/* truncatezeros() examines the bytes at the end of the file's
 * size-to-be, and reduces the size to exclude any trailing zero
 * bytes.
 */
static int truncatezeros(int fd, unsigned long *newsize)
{
    unsigned char	contents[1024];
    unsigned long	size, n;

    size = *newsize;
    do {
	n = sizeof contents;
	if (n > size)
	    n = size;
	if (lseek(fd, size - n, SEEK_SET) == (off_t)-1)
	    return ferr("cannot seek in file.");
	if (read(fd, contents, n) != (ssize_t)n)
	    return ferr("cannot read file contents");
	while (n && !contents[--n])
	    --size;
    } while (size && !n);

    /* Sanity check.
     */
    if (!size)
	return err("ELF file is completely blank!");

    *newsize = size;
    return 1;
}

/* modifyheaders() removes references to the section header table if
 * it was stripped, and reduces program header table entries that
 * included truncated bytes at the end of the file.
 */
static int modifyheaders(Elf_Ehdr *ehdr, Elf_Phdr *phdrs,
			 unsigned long newsize)
{
    Elf_Phdr *phdr;
    int		i;
   
    unsigned long e_shoff;
    short         e_phnum;
    unsigned long p_offset,p_filesz;
   
    e_shoff=ehdr->e_shoff;
#if (ELF_CLASS==ELFCLASS64)
    if (swap_bytes) {
       e_shoff=bswap_64(e_shoff);
    }
#else
    if (swap_bytes) {
       e_shoff=bswap_32(e_shoff);
    }
#endif   
   
    e_phnum=ehdr->e_phnum;
    if (swap_bytes) e_phnum=bswap_16(e_phnum);
   
   
    /* If the section header table is gone, then remove all references
     * to it in the ELF header.
     */
    if (e_shoff >= newsize) {
        ehdr->e_shoff = 0;        /* all OK because 0 is endian neutral */
	ehdr->e_shnum = 0;
	ehdr->e_shentsize = 0;
	ehdr->e_shstrndx = 0;
    }

    /* The program adjusts the file size of any segment that was
     * truncated. The case of a segment being completely stripped out
     * is handled separately.
     */
    for (i = 0, phdr = phdrs ; i < e_phnum ; ++i, ++phdr) {
       
        p_offset=phdr->p_offset;
	p_filesz=phdr->p_filesz;
#if (ELF_CLASS==ELFCLASS64)
        if (swap_bytes) {
           p_offset=bswap_64(p_offset);
           p_filesz=bswap_64(p_filesz);
        }
#else
        if (swap_bytes) {
           p_offset=bswap_32(p_offset);
           p_filesz=bswap_32(p_filesz);
        }
#endif       
       
	if (p_offset >= newsize) {
	    p_offset = newsize;
#if (ELF_CLASS==ELFCLASS64)
        if (swap_bytes) {
           phdr->p_offset=bswap_64(p_offset);
        }
#else
        if (swap_bytes) {
           phdr->p_offset=bswap_32(p_offset);
        }
#endif       	   	   
	    phdr->p_filesz = 0;
	} else if (p_offset + p_filesz > newsize) {
	    p_filesz = newsize - p_offset;
#if (ELF_CLASS==ELFCLASS64)
        if (swap_bytes) {
           phdr->p_filesz=bswap_64(p_filesz);
        }
#else
        if (swap_bytes) {
           phdr->p_filesz=bswap_32(p_filesz);
        }
#endif       	   
	    
	}
    }

    return 1;
}

/* commitchanges() writes the new headers back to the original file
 * and sets the file to its new size.
 */
static int commitchanges(int fd, Elf_Ehdr const *ehdr, Elf_Phdr *phdrs,
			 unsigned long newsize)
{
    size_t	n;
    unsigned long e_phoff;
    short e_phnum;
   
    e_phnum=ehdr->e_phnum;
    if (swap_bytes) e_phnum=bswap_16(e_phnum);
   
    e_phoff=ehdr->e_phoff;
#if (ELF_CLASS==ELFCLASS64)
        if (swap_bytes) {
           e_phoff=bswap_64(e_phoff);
        }
#else
        if (swap_bytes) {
           e_phoff=bswap_32(e_phoff);
        }
#endif       	   
   
   
    /* Save the changes to the ELF header, if any.
     */
    if (lseek(fd, 0, SEEK_SET))
	return ferr("could not rewind file");
    errno = 0;
    if (write(fd, ehdr, sizeof *ehdr) != sizeof *ehdr)
	return err("could not modify file");

    /* Save the changes to the program segment header table, if any.
     */
    if (lseek(fd, e_phoff, SEEK_SET) == (off_t)-1) {
	err("could not seek in file.");
	goto warning;
    }
    n = e_phnum * sizeof *phdrs;
    if (write(fd, phdrs, n) != (ssize_t)n) {
	err("could not write to file");
	goto warning;
    }

    /* Eleventh-hour sanity check: don't truncate before the end of
     * the program segment header table.
     */
    if (newsize < e_phoff + n)
	newsize = e_phoff + n;

    /* Chop off the end of the file.
     */
    if (ftruncate(fd, newsize)) {
	err("could not resize file");
	goto warning;
    }

    return 1;

  warning:
    return err("ELF file may have been corrupted!");
}

/* main() loops over the cmdline arguments, leaving all the real work
 * to the other functions.
 */
int main(int argc, char *argv[]) {

    int			fd;
    Elf_Ehdr		ehdr;
    Elf_Phdr	       *phdrs;
    unsigned long	newsize;
    char	      **arg;
    int			failures = 0;

    if (argc < 2 || argv[1][0] == '-') {
	printf("Usage: sstrip FILE...\n"
	       "sstrip discards all nonessential bytes from an executable.\n\n"
	       "Version 2.0 Copyright (C) 2000,2001 Brian Raiter.\n"
	       "This program is free software, licensed under the GNU\n"
	       "General Public License. There is absolutely no warranty.\n");
	return EXIT_SUCCESS;
    }

    progname = argv[0];

    for (arg = argv + 1 ; *arg != NULL ; ++arg) {

	filename = *arg;

	fd = open(*arg, O_RDWR);
	if (fd < 0) {
	    ferr("can't open");
	    ++failures;
	    continue;
	}

	if (!(readelfheader(fd, &ehdr)			&&
	      readphdrtable(fd, &ehdr, &phdrs)		&&
	      getmemorysize(&ehdr, phdrs, &newsize)	&&
	      truncatezeros(fd, &newsize)		&&
	      modifyheaders(&ehdr, phdrs, newsize)	&&
	      commitchanges(fd, &ehdr, phdrs, newsize)))
	    ++failures;

	close(fd);
    }

    return failures ? EXIT_FAILURE : EXIT_SUCCESS;
}
