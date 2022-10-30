DASM=dasm
EXOMIZER=/home/eb/exomizer/src/exomizer

%.prg:
	$(DASM) $< -o$@ -l$*.lst

all:				char-crunch.x color-crunch.x crunch.prg

clean:
	rm *.prg *.lst *.x

crunch.prg:			decrunch-wrapper.asm exomizer-decrunch.asm

char-crunch.x: uncompressed/char.bin	
	$(EXOMIZER) mem -l 0x1e00 -o $@ $<
color-crunch.x: uncompressed/color.bin
	$(EXOMIZER) mem -l 0x9600 -o $@ $<

