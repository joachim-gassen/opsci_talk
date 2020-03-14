TARGETS := data slides 

.phony: slides data all clean clean_slides_dir

all: $(TARGETS)

clean_slides_dir:
	rm -f -r slides/*_files slides/*_cache

clean: clean_slides_dir
	rm -f slides/*.pdf 
	rm -f data/*

data: data/restrans_data.csv data/restrans_data_def.csv 

slides: data slides/opsci_talk_slides.pdf clean_slides_dir

slides/opsci_talk_slides.pdf: slides/opsci_talk_slides.Rmd code/utils.R
	Rscript -e "rmarkdown::render('slides/opsci_talk_slides.Rmd')"
	rm slides/opsci_talk_slides.tex
	
data/restrans_data.csv: code/pull_data.R
	Rscript code/pull_data.R

data/restrans_data_def.csv: data/restrans_data.csv
