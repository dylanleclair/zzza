from dis import Instruction
from PIL import Image
from string import Template

###############################################################################
#
#   Python program to read an image and output a (basic) run length encoding of the
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


ENCODING_COLOUR = {"BLACK": False,
                   "PURPLE": True}


'''
Returns a number encoding length (7 bits) and char code.
High 4 bits are index into char lookup table, low 4 bits are length

  char
  v v v v
 [ | | | | | | | ]
          ^ ^ ^ ^
          length 
'''


def encode(char: int, length: int):

    print([char, length])
    shift_char = char << 4
    if length >= 16:
        raise ValueError("value encoded cannot exceed 15")
    print(length | (char << 4))
    return (length | (char << 4))


#assert encode(10, 5) == 0xa5


'''
Take the array of encoded data (numbers representing bytes) and log it
'''
def write_data(data):
    print("; number chars encoded: " + str(sum(b & 0x7f for b in data)))
    print("; number bytes encoded: " + str(len(data)))
    print("; generated code begins !!!")
    for b in data:
        print("\tdc.b #%{0:08b}".format(b))




# open the image in Pillow
img = Image.open(file_name)

previous_char = CHAR_CODE[" "]  # The colour of the first block that changed
current_char = CHAR_CODE[" "] # the colour of the block we're currently reading (init to black)
length = 0  # setup the length variable

data = []

mode = "ENC_COL"

TEXT_TO_ENCODE = ["RUNTIME TERR0R", "2022"]

text_enc_index = 0


test_str = []
for item in TEXT_TO_ENCODE:
    for char in item:
        test_str.append(CHAR_CODE[char])

print(test_str)

# loop over the image and read a pixel from each 8 pixel "byte" of the image
for i in range(SCREEN_WIDTH):
    for j in range(SCREEN_HEIGHT):

        # read the pixel
        r, g, b, a = img.getpixel((j*8, i*8))

        # set the char
        if r + g + b == 0:  # if BLACK
            current_char = CHAR_CODE[" "]
        if r == 114 and g == 8 and b == 153:  # if PURPLE
            current_char = CHAR_CODE["PS"]

        position = ((i*SCREEN_WIDTH) + j)
        # if we're at the spot to place text
        if(position == 193 or position == 213):
            mode = "ENC_TEXT"
            print(length)
            val = encode(previous_char, length)
            data.append(val)
            length = 1
            previous_char = TEXT_TO_ENCODE[text_enc_index][0]
            #current_char = "R"

        if (mode == "ENC_COL"):

            # If this is a repeated block
            if previous_char == current_char and length != 15:
                length += 1
            else:
                val = encode(previous_char, length)
                data.append(val)
                length = 1
                previous_char = current_char

            if (i == SCREEN_WIDTH - 1) and (j == SCREEN_HEIGHT-1):
                val = encode(previous_char, length)
                data.append(val)
                data.append(0)  # end of the encoding (null byte)
                break

        elif (mode == "ENC_TEXT"):
            # encode next string in TEXT_TO_ENCODE

            # update previous / current_char
            diff = 193 if (text_enc_index == 0) else 213
            # advance
            text_index = (i * SCREEN_WIDTH + j) - diff
            # gives character to encode
            val = TEXT_TO_ENCODE[text_enc_index][text_index]

            current_char = val



            if (text_index == (len(TEXT_TO_ENCODE[text_enc_index]) - 1)):
                # entire string encoded, switch back to color mode (for next iteration)
                mode = "ENC_COL"
                text_enc_index += 1
                
                val = encode(CHAR_CODE[previous_char], length)
                data.append(val)
                length = 1
                previous_char = CHAR_CODE[" "]
                continue

            # encoding logic
            if previous_char == current_char:
                length += 1
            else:
                val = encode(CHAR_CODE[previous_char], length)
                data.append(val)
                length = 1
                previous_char = current_char


write_data(data)

count = 0

for item in data:
    count += (item & 0x0f) 

print("count: ")
print(count)

#save the output in a file named "output.txt"
text_file = open("output.txt", "w")
n = text_file.write(str(data))  # type: ignore
text_file.close()
