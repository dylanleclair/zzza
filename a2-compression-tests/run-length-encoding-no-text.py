from dis import Instruction
from PIL import Image
from string import Template

###############################################################################
#
#   Python program to read an image and output a run length encoding of the
#   title screen
# 
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

CHAR_CODE = {"0": 0,
             "E": 1,
             "2": 2,
             "I": 3,
             "M": 4,
             "N": 5,
             "R": 6,
             "T": 7,
             "U": 8,
             " ": 9}

ENCODING_COLOUR = {"BLACK": False,
                  "PURPLE": True}

'''
Returns a number encoding length (7 bits) and color bit.

color bit
 v
[ | | | | | | | ]
   ^ ^ ^ ^ ^ ^ ^    
    length bits
'''
def encode(length: int, character: int):
    if length >= 128:
        raise ValueError("value encoded cannot exceed 127")
    return length | (character << 4)


###############################################################################
#
#   Python program to read an image and output a run length encoding of the
#   title screen
#
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

ENCODING_COLOUR = {"BLACK": False,
                   "PURPLE": True}




'''
Take the array of encoded data (numbers representing bytes) and log it
'''
def write_data(data):
    print("; number chars encoded: " + str(sum(b & 0x7f for b in data)))
    print("; number bytes encoded: " + str(len(data)))
    print("; generated code begins !!!")
    for b in data:
        print("\tdc.b #%{0:08b}".format(b))


# hardcodes the image file
file_name = "zzza.png"

# open the image in Pillow
img = Image.open(file_name)

previous_colour = False  # The colour of the first block that changed
current_colour = False  # the colour of the block we're currently reading
length = 0  # setup the length variable

data = []

# loop over the image and read a pixel from each 8 pixel "byte" of the image
for i in range(SCREEN_WIDTH):
    for j in range(SCREEN_HEIGHT):
        # read the pixel
        r, g, b, a = img.getpixel((j*8, i*8))

        # set the colour
        if r + g + b == 0:  # if BLACK
            current_colour = ENCODING_COLOUR["BLACK"]
        if r == 114 and g == 8 and b == 153:  # if PURPLE
            current_colour = ENCODING_COLOUR["PURPLE"]

        # If this is a repeated block
        if current_colour == previous_colour:
            length += 1
        else:
            val = encode(length, previous_colour)
            data.append(val)
            length = 1
            previous_colour = current_colour

        if (i == SCREEN_WIDTH - 1) and (j == SCREEN_HEIGHT-1):
            data.append(encode(length, previous_colour))  # last encoding
            data.append(0)  # end of the encoding (null byte)
            break


write_data(data)

for i in range(len(data)):
    data[i] = data[i] & 0x7f

assert sum(data) == 16 * 16


#save the output in a file named "output.txt"
text_file = open("output.txt", "w")
n = text_file.write(str(data))  # type: ignore
text_file.close()
