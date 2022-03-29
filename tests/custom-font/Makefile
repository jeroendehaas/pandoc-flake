all: custom-font.pdf

custom-font.pdf: custom-font.md
	pandoc -s -o custom-font.tex $<
	latexmk -lualatex -Werror custom-font

.PHONY: all
