
#DASM=/home/profs/aycock/599.82/bin/dasm
DASM=dasm

%.prg:
	$(DASM) $< -o$@ -l$*.lst

all: sound-zzza.prg

clean:
	rm *.prg *.lst

sound-zzza.prg: sound-zzza.asm
