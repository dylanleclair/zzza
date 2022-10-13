from dis import Instruction
from PIL import Image
from string import Template

###############################################################################
#
#   Python program to read an image and output a set of instructions to draw
#   that image on the VIC-20.
# 
#   Note: ZERO optimization!  In fact, this is probably written to make it as
#         long as is possible!
#
###############################################################################

# Global variables (sets the screen size)
IMAGE_WIDTH = 128  # pixels
IMAGE_HEIGHT = 128  # pixels
SCREEN_WIDTH = 16  # 1 byte blocks
SCREEN_HEIGHT = 16  # 1 byte block
BYTE_WIDTH = 8  # pixels per block
BYTE_HEIGHT = 8  # pixels per block

# Memory addresses in the VIC-20
COLOR_ADDR = "$9600"
SCREEN_ADDR = "$1e00"

# VIC-20 colour codes
COLOR_CODE = {"BLACK": 0,
              "WHITE": 1,
              "RED": 2,
              "CYAN": 3,
              "PURPLE": 4,
              "GREEN": 5,
              "BLUE": 6,
              "YELLOW": 7,
              "ORANGE": 8,
              "LIGHT ORANGE": 9,
              "PINK": 10,
              "LIGHT CYAN": 11,
              "LIGHT PURPLE": 12,
              "LIGHT GREEN": 13,
              "LIGHT BLUE": 14,
              "LIGHT YELLOW": 15}

# takes a desired colour, offset, and character, and returns a set of instructions
def get_instructions(color, offset, character):
    return f'''
    lda     #{color}                ; set the color
    sta     {COLOR_ADDR},x
    lda     #{character}            ; fill the space with a block
    sta     {SCREEN_ADDR},x
    inx
    '''

# hardcodes the image file
# file_name = input()
file_name = "zzza.png"

# open the image in Pillow
img = Image.open(file_name)

# the code that is going to be output
script = ""

# the character to fill the screen with
character = "224"  # fill the screen with solid blocks

# loop over the image and read a pixel from each 8 pixel "byte" of the image
for i in range(SCREEN_WIDTH):
    for j in range(SCREEN_HEIGHT):
        r, g, b, a = img.getpixel((j*8, i*8))
        offset = (i*64)+(j*8)
        if r + g + b == 0:
            color = COLOR_CODE["BLACK"]
        if r == 114 and g == 8 and b == 153:  # RGB for the purple
            color = COLOR_CODE["PURPLE"]
        script += get_instructions(color, offset, character)

# print the script out to the screen
print(script)

#save the output in a file named "output.txt"
text_file = open("output.txt", "w")
n = text_file.write(script)
text_file.close()
