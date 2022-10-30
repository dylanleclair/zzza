
#DASM=/home/profs/aycock/599.82/bin/dasm
DASM=dasm
%.prg:
	$(DASM) $< -o$@ -l$*.lst

all: runlength-decompress-1.prg runlength-decompress-2.prg zx02-dasm.asm

clean:
	rm *.prg *.lst

runlength-decompress-1.prg: runlength-decompress-1.asm
runlength-decompress-2.prg: runlength-decompress-2.asm
zx02-dasm.prg: zx02-dasm.asm

