%.prg:
	dasm $< -o$@ -l$*.lst

all: fillscreenwithcircles.prg screensize.prg customcharset.prg custom_animate.prg key_input.prg
clean:
	rm *.prg *.lst

fillscreenwithcircles.prg: fillscreenwithcircles.s
customcharset.prg: customcharset.s
screensize.prg: screensize.s
custom_animate.prg: custom_animate.s
key_input.prg: key_input.asm
