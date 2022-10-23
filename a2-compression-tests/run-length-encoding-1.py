from dis import Instruction
from PIL import Image
from string import Template

###############################################################################
#
#   Python program to read an image and output a run length encoding of the
#   title screen
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

CHAR_CODE = {
                "0": 0,
                "E": 1,
                "2": 2,
                "I": 3,
                "M": 4,
                "N": 5,
                "R": 6,
                "T": 7,
                "U": 8,
                " ": 9,         # black square
                "PS": 10        # purple square
             }

TEXT_TO_ENCODE = ["RUNTIME TERR0R", "2022 "]
mode = "ENC_COL"                # flag used to decide if data is colour or text
file_name = "zzza.png"          # hardcoded image file name
data = []                       # the data array that we will fill with bytes

'''
Returns a number encoding length (7 bits) and char code.
High 4 bits are index into char lookup table, low 4 bits are length
'''
def encode(length: int, char: int):
    shift_char = char << 4
    print(length)
    print(char)
    print(shift_char)
    print()
    if length >= 16:
        raise ValueError("value encoded cannot exceed 15")
    # return length | 0x80 if color else length


'''
Take the array of encoded data (numbers representing bytes) and log it
'''
def write_data(data):
    print("; number chars encoded: " + str(sum(b & 0x7f for b in data)))
    print("; number bytes encoded: " + str(len(data)))
    print("; generated code begins !!!")
    # for b in data:
    #     print("\tdc.b #%{0:08b}".format(b))




# open the image in Pillow
img = Image.open(file_name)

text_enc_index = 0  # what is this
previous_char = 0   # The colour of the first block that changed
current_char = 0    # the colour of the block we're currently reading
length = 0          # setup the length variable

# loop over the image and read a pixel from each 8 pixel "byte" of the image
for i in range(SCREEN_WIDTH):
    for j in range(SCREEN_HEIGHT):

        # read the pixel
        r, g, b, a = img.getpixel((j*8, i*8))

        # set the colour
        if r + g + b == 0:      # if BLACK
            current_char = 0x09
        else:                   # otherwise assume purple
            current_char = 0x0a

        # correlates directly to VIC20 screen memory offsets
        position = ((i*SCREEN_WIDTH) + j)
        


write_data(data)

#save the output in a file named "output.txt"
text_file = open("output.txt", "w")
n = text_file.write(str(data))  # type: ignore
text_file.close()
