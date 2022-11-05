# DASM=/home/profs/aycock/599.82/bin/dasm
DASM=dasm

%.prg:
	$(DASM) $< -o$@ -l$*.lst

all: main.prg

clean:
	rm *.prg *.lst

main.prg: main.asm

