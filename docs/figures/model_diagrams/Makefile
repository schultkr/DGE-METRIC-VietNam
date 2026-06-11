## Compile all TikZ diagrams to PDF and PNG.
## Requires: pdflatex, pdftoppm or ImageMagick convert.

SRCS = production_structure.tex energy_gdp_channels.tex
PDFS = $(SRCS:.tex=.pdf)
PNGS = $(SRCS:.tex=.png)

all: $(PNGS)

%.pdf: %.tex
	pdflatex -interaction=nonstopmode $<
	pdflatex -interaction=nonstopmode $<

%.png: %.pdf
	pdftoppm -r 200 -png $< $(basename $<) && mv $(basename $<)-1.png $@

clean:
	rm -f *.aux *.log *.synctex.gz *.fls *.fdb_latexmk

.PHONY: all clean
