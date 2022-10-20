# DASM=/home/profs/aycock/599.82/bin/dasm
DASM=dasm

%.prg:
	$(DASM) $< -o$@ -l$*.lst

all: runlength-decompression.prg

clean:
	rm *.prg *.lst

runlength-decompression.prg: runlength-decompression.asm

