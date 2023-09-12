# DASM=/home/profs/aycock/599.82/bin/dasm
DASM=dasm

%.prg:
	$(DASM) $< -o$@ -l$*.lst

all: movement-hi-res.prg movement-bad.prg

clean:
	rm *.prg *.lst

movement-hi-res.prg: movement-hi-res.asm
movement-bad.prg: movement-bad.asm

