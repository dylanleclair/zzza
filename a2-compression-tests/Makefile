
DASM=/home/profs/aycock/599.82/bin/dasm
# DASM=dasm
ZX02_COMPRESS=./zx02				# precompiled zx02 binary for compression
EXOMIZER_COMPRESS=./exomizer		# precompiled exomizer binary for compression

%.prg:
	$(DASM) $< -o$@ -l$*.lst

all: screen_data.zx02 screen_colour.zx02 screen_data.exo screen_colour.exo runlength-decompress-1.prg runlength-decompress-2.prg zx02-dasm.prg exomizer-decompress.prg function-encoding.prg

# compressed: screen_data.zx02 screen_colour.zx02 screen_data.exo screen_colour.exo

clean:
	rm *.prg *.lst *.zx02 *.exo

# builds for DASM prg files
runlength-decompress-1.prg: runlength-decompress-1.asm
runlength-decompress-2.prg: runlength-decompress-2.asm
zx02-dasm.prg: zx02-dasm.asm
exomizer-decompress.prg: decrunch-wrapper.asm exomizer-decrunch.asm
function-encoding.prg: function-encoding.asm

# targets for compressing with zx02
screen_data.zx02: memory-dumps/zx02_char.bin
	$(ZX02_COMPRESS) -f $< $@
screen_colour.zx02: memory-dumps/zx02_color.bin
	$(ZX02_COMPRESS) -f $< $@

# targets for compressing exomizer data
screen_data.exo: memory-dumps/char.bin	
	$(EXOMIZER_COMPRESS) mem -l 0x1e00 -o $@ $<
screen_colour.exo: memory-dumps/color.bin
	$(EXOMIZER_COMPRESS) mem -l 0x9600 -o $@ $<
