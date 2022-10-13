
DASM=/home/profs/aycock/599.82/bin/dasm

%.prg:
	$(DASM) $< -o$@ -l$*.lst

all: copy_char.prg custom_animate.prg customcharset.prg fillscreenwithcircles.prg full_colour_fill.prg full_screen_patterns.prg key_input.prg movement_test.prg multicolour_sprite.prg print_char.prg screen_dim.prg scrollexample.prg sound.prg title_screen.prg 

clean:
	rm *.prg *.lst

copy_char.prg: copy_char.asm
custom_animate.prg: custom_animate.asm
customcharset.prg: customcharset.asm
fillscreenwithcircles.prg: fillscreenwithcircles.asm
full_colour_fill.prg: full_colour_fill.asm
full_screen_patterns.prg: full_screen_patterns.asm
key_input.prg: key_input.asm
movement_test.prg: movement_test.asm
multicolour_sprite.prg: multicolour_sprite.asm
print_char.prg: print_char.asm
screen_dim.prg: screen_dim.asm 
scrollexample.prg: scrollexample.asm
sound.prg: sound.asm 
title_screen.prg: title_screen.asm

