all: simple.pdf

simple.pdf: simple.md
	pandoc -s -o simple.tex $<
	latexmk -lualatex -Werror simple

.PHONY: all
