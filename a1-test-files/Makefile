%.prg:
	dasm $< -o$@ -l$*.lst

all: fillscreenwithcircles.prg customcharset.prg custom_animate.prg key_input.prg copy_char.prg
clean:
	rm *.prg *.lst

fillscreenwithcircles.prg: fillscreenwithcircles.asm
customcharset.prg: customcharset.asm
custom_animate.prg: custom_animate.asm
key_input.prg: key_input.asm
copy_char.prg: copy_char.asm
