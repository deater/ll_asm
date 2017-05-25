CC = gcc
LFLAGS =
CFLAGS = -Wall -O3

all:	ll_document.pdf \
	fancy_total_size.png \
	fancy_lzss.png \
	fancy_strcat.png

###

fancy_lzss.png:		fancy_lzss.eps
			convert -density 600 -antialias -sample 400 fancy_lzss.eps fancy_lzss.png

fancy_lzss.eps:		fancy_lzss.jgr
			jgraph < fancy_lzss.jgr > fancy_lzss.eps

fancy_lzss.jgr:		fancy_graph ../data/data.lzss
			./fancy_graph < ../data/data.lzss > fancy_lzss.jgr

###

fancy_strcat.png:		fancy_strcat.eps
			convert -density 600 -antialias -sample 400 fancy_strcat.eps fancy_strcat.png

fancy_strcat.eps:		fancy_strcat.jgr
			jgraph < fancy_strcat.jgr > fancy_strcat.eps

fancy_strcat.jgr:		fancy_graph ../data/data.strcat
			./fancy_graph < ../data/data.strcat > fancy_strcat.jgr

###

fancy_total_size.png:		fancy_total_size.eps
			convert -density 600 -antialias -sample 400 fancy_total_size.eps fancy_total_size.png

fancy_total_size.eps:		fancy_total_size.jgr
			jgraph < fancy_total_size.jgr > fancy_total_size.eps

fancy_total_size.jgr:		fancy_graph ../data/data.overall
			./fancy_graph < ../data/data.overall > fancy_total_size.jgr


fancy_graph:		fancy_graph.o
			$(CC) $(LFLAGS) -o fancy_graph fancy_graph.o

fancy_graph.o:		fancy_graph.c
			$(CC) $(CFLAGS) -c fancy_graph.c


ll_document.pdf:	ll_document.tex \
			architecture_table.tex \
			correlations_table.tex \
			ll_findstring_size.pdf ll_lzss_size.pdf  \
			ll_strcat_size.pdf ll_total_size.pdf \
			ll_num_ascii.pdf \
			cache_graph.pdf \
			time_graph.pdf \
			libc_sizes.pdf
			pdflatex ll_document.tex
			bibtex ll_document
			pdflatex ll_document.tex
			pdflatex ll_document.tex

###

libc_sizes.eps:		libc_sizes.jgr
	jgraph < libc_sizes.jgr > libc_sizes.eps

libc_sizes.pdf:		libc_sizes.eps
	epstopdf libc_sizes.eps

###

cache_graph.eps:	cache_graph.jgr
	jgraph < cache_graph.jgr > cache_graph.eps

cache_graph.pdf:	cache_graph.eps
	epstopdf cache_graph.eps

###

cpi_graph.eps:		cpi_graph.jgr
	jgraph < cpi_graph.jgr > cpi_graph.eps

cpi_graph.pdf:		cpi_graph.eps
	epstopdf cpi_graph.eps

###

sizes_normal.eps:	sizes_normal.jgr
	jgraph < sizes_normal.jgr > sizes_normal.eps

sizes_normal.pdf:	sizes_normal.eps
	epstopdf sizes_normal.eps

###

time_graph.eps:		time_graph.jgr
	jgraph < time_graph.jgr > time_graph.eps

time_graph.pdf:		time_graph.eps
	epstopdf time_graph.eps

###

tlb_graph.eps:		tlb_graph.jgr
	jgraph < tlb_graph.jgr > tlb_graph.eps

tlb_graph.pdf:		tlb_graph.eps
	epstopdf tlb_graph.pdf

###

uop_graph.eps:		uop_graph.jgr
	jgraph < uop_graph.jgr > uop_graph.eps

uop_graph.pdf:		uop_graph.eps
	epstopdf uop_graph.eps

####

regular_graph:		regular_graph.o
	$(CC) $(LFLAGS) -o regular_graph regular_graph.o

regular_graph.o:	regular_graph.c
	$(CC) $(CFLAGS) -c regular_graph.c


####

ll_total_size.jgr:	../data/data.overall regular_graph
	./regular_graph < ../data/data.overall > ll_total_size.jgr

ll_total_size.eps:	ll_total_size.jgr
	jgraph < ll_total_size.jgr > ll_total_size.eps

ll_total_size.pdf:	ll_total_size.eps
	epstopdf ll_total_size.eps

####

ll_lzss_size.jgr:	../data/data.lzss regular_graph
	./regular_graph < ../data/data.lzss > ll_lzss_size.jgr

ll_lzss_size.eps:	ll_lzss_size.jgr
	jgraph < ll_lzss_size.jgr > ll_lzss_size.eps

ll_lzss_size.pdf:	ll_lzss_size.eps
	epstopdf ll_lzss_size.eps

####

ll_strcat_size.jgr:	../data/data.strcat regular_graph
	./regular_graph < ../data/data.strcat > ll_strcat_size.jgr

ll_strcat_size.eps:	ll_strcat_size.jgr
	jgraph < ll_strcat_size.jgr > ll_strcat_size.eps

ll_strcat_size.pdf:	ll_strcat_size.eps
	epstopdf ll_strcat_size.eps

####

ll_findstring_size.jgr:	../data/data.findstring regular_graph
	./regular_graph < ../data/data.findstring > ll_findstring_size.jgr

ll_findstring_size.eps:	ll_findstring_size.jgr
	jgraph < ll_findstring_size.jgr > ll_findstring_size.eps

ll_findstring_size.pdf:	ll_findstring_size.eps
	epstopdf ll_findstring_size.eps

####

ll_num_ascii.jgr:	../data/data.num_ascii regular_graph
	./regular_graph < ../data/data.num_ascii > ll_num_ascii.jgr

ll_num_ascii.eps:	ll_num_ascii.jgr
	jgraph < ll_num_ascii.jgr > ll_num_ascii.eps

ll_num_ascii.pdf:	ll_num_ascii.eps
	epstopdf ll_num_ascii.eps

####


clean:
	rm -f ll_total_size.eps ll_lzss_size.eps ll_strcat_size.eps \
	cache_graph.eps cpi_graph.eps \
	sizes_graph.eps sizes_normal.eps time_graph.eps \
	tlb_graph.eps uop_graph.eps \
	libc_sizes.eps \
	regular_graph \
	ll_total_size.eps ll_total_size.jgr \
	ll_lzss_size.eps ll_lzss_size.jgr \
	ll_strcat_size.eps ll_strcat_size.jgr \
	ll_findstring_size.eps ll_findstring_size.jgr \
	ll_num_ascii.eps ll_num_ascii.jgr \
	fancy_total_size.jgr fancy_total_size.eps *.png \
	fancy_lzss.jgr fancy_lzss.eps \
	fancy_strcat.jgr fancy_strcat.eps \
	*.o fancy_graph \
	*.pdf *.aux *.dvi *.log *.bbl *.blg *~

install:
			       scp ll_document.pdf `cat ~/webserver`:public_html/papers/iccd09/ll_document.pdf

