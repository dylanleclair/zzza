%.prg:
	dasm $< -o$@ -l$*.lst

all: scrollexample.prg
clean:
	rm *.prg *.lst

scrollexample.prg: scrollexample.asm
