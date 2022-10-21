


%.prg:
	DASM $< -o$@ -l$*.lst

all:	movement.prg scroll_eva.prg

clean:
	rm *.prg *.lst

movement.prg: movement.asm
scroll_eva.prg: scroll_eva.asm




