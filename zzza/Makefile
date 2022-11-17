# DASM=/home/profs/aycock/599.82/bin/dasm
DASM=dasm

%.prg:
	$(DASM) main.asm -omain.prg -lmain.lst

all: main.prg

clean:
	rm *.prg *.lst

main.prg: *.asm

