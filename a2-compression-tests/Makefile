# DASM=/home/profs/aycock/599.82/bin/dasm
DASM=dasm

%.prg:
	$(DASM) $< -o$@ -l$*.lst

all: runlength-decompression.prg decode-1.prg

clean:
	rm *.prg *.lst

runlength-decompression.prg: runlength-decompression.asm
decode-1.prg: decode-1.asm

