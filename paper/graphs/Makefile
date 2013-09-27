CC = gcc
LFLAGS =
CFLAGS = -Wall -O3

all:	ll_document.pdf \
	fancy_total_size.png \
	fancy_lzss.png


fancy_lzss.png:		fancy_lzss.eps
			convert -density 600 -antialias -sample 400 fancy_lzss.eps fancy_lzss.png

fancy_lzss.eps:		fancy_lzss.jgr
			jgraph < fancy_lzss.jgr > fancy_lzss.eps
			
fancy_lzss.jgr:		fancy_graph data.lzss
			./fancy_graph < data.lzss > fancy_lzss.jgr


fancy_total_size.png:		fancy_total_size.eps
			convert -density 600 -antialias -sample 400 fancy_total_size.eps fancy_total_size.png

fancy_total_size.eps:		fancy_total_size.jgr
			jgraph < fancy_total_size.jgr > fancy_total_size.eps
			
fancy_total_size.jgr:		fancy_graph data.overall
			./fancy_graph < data.overall > fancy_total_size.jgr
			

fancy_graph:		fancy_graph.o
			$(CC) $(LFLAGS) -o fancy_graph fancy_graph.o
			
fancy_graph.o:		fancy_graph.c
			$(CC) $(CFLAGS) -c fancy_graph.c


ll_document.pdf:       ll_document.dvi
		       dvipdf ll_document.dvi

ll_document.dvi:       ll_document.tex \
		       architecture_table.tex \
		       correlations_table.tex \
		       ll_findstring_size.eps  ll_lzss_size.eps  \
		       ll_strcat_size.eps ll_total_size.eps \
		       ll_num_ascii.eps \
		       cache_graph.eps \
		       time_graph.eps \
		       libc_sizes.eps
			latex ll_document.tex
			bibtex ll_document
			latex ll_document.tex
			latex ll_document.tex

libc_sizes.eps:	      libc_sizes.jgr
		      jgraph < libc_sizes.jgr > libc_sizes.eps

cache_graph.eps:	   cache_graph.jgr
			   jgraph < cache_graph.jgr > cache_graph.eps

cpi_graph.eps:	   cpi_graph.jgr
			   jgraph < cpi_graph.jgr > cpi_graph.eps
			   
sizes_normal.eps:	   sizes_normal.jgr
			   jgraph < sizes_normal.jgr > sizes_normal.eps
			   
time_graph.eps:	   time_graph.jgr
			   jgraph < time_graph.jgr > time_graph.eps
			   
tlb_graph.eps:	   tlb_graph.jgr
			   jgraph < tlb_graph.jgr > tlb_graph.eps

uop_graph.eps:	   uop_graph.jgr
			   jgraph < uop_graph.jgr > uop_graph.eps

####

regular_graph:		regular_graph.o
	$(CC) $(LFLAGS) -o regular_graph regular_graph.o

regular_graph.o:	regular_graph.c
	$(CC) $(CFLAGS) -c regular_graph.c

			   
####			   

ll_total_size.jgr:	data.overall regular_graph
	./regular_graph < data.overall > ll_total_size.jgr

ll_total_size.eps:	ll_total_size.jgr
	jgraph < ll_total_size.jgr > ll_total_size.eps

####

ll_lzss_size.jgr:	data.lzss regular_graph
	./regular_graph < data.lzss > ll_lzss_size.jgr

ll_lzss_size.eps:	ll_lzss_size.jgr
	jgraph < ll_lzss_size.jgr > ll_lzss_size.eps

####

ll_strcat_size.jgr:	data.strcat regular_graph
	./regular_graph < data.strcat > ll_strcat_size.jgr

ll_strcat_size.eps:	ll_strcat_size.jgr
	jgraph < ll_strcat_size.jgr > ll_strcat_size.eps

####


ll_num_ascii.eps:	   ll_num_ascii.jgr
			   jgraph < ll_num_ascii.jgr > ll_num_ascii.eps

			 
ll_findstring_size.eps:	   ll_findstring_size.jgr
			   jgraph < ll_findstring_size.jgr > ll_findstring_size.eps
			   

clean:	
	rm -f ll_total_size.eps ll_lzss_size.eps ll_strcat_size.eps \
	cache_graph.eps cpi_graph.eps ll_num_ascii.eps \
	sizes_graph.eps sizes_normal.eps time_graph.eps \
	tlb_graph.eps uop_graph.eps \
	ll_findstring_size.eps libc_sizes.eps \
	regular_graph \
	ll_total_size.eps ll_total_size.jgr \
	ll_lzss_size.eps ll_lzss_size.jgr \
	ll_strcat_size.eps ll_strcat_size.jgr \
	fancy_total_size.jgr fancy_total_size.eps *.png \
	fancy_lzss.jgr fancy_lzss.eps \
	*.o fancy_graph \
	*.pdf *.aux *.dvi *.log *~
	
install:		       
			       scp ll_document.pdf vince@cluizel:public_html
