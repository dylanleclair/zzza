%.prg:
	dasm $< -o$@ -l$*.lst

all: scrollexample.prg boilerplate.prg
clean:
	rm *.prg *.lst

scrollexample.prg: scrollexample.asm
boilerplate.prg: boilerplate.asm
