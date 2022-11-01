# DASM=/home/profs/aycock/599.82/bin/dasm
DASM=dasm

%.prg:
	$(DASM) $< -o$@ -l$*.lst

all: level-gen.prg

clean:
	rm *.prg *.lst

level-gen.prg: level-gen.asm

