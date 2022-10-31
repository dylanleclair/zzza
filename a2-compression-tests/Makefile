
#DASM=/home/profs/aycock/599.82/bin/dasm
DASM=dasm
ZX02_COMPRESS=./zx02

%.prg:
	$(DASM) $< -o$@ -l$*.lst

all: runlength-decompress-1.prg runlength-decompress-2.prg zx02-dasm.asm  screen_data.zx02 screen_colour.zx02

clean:
	rm *.prg *.lst

runlength-decompress-1.prg: runlength-decompress-1.asm
runlength-decompress-2.prg: runlength-decompress-2.asm
zx02-dasm.prg: zx02-dasm.asm

screen_data.zx02: uncompress/char.bin
	$(zx02) -f $@ $<
screen_colour.zx02: uncompress/color.bin
	$(zx02) -f $@ $<