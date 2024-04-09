# importing image object from PIL 
from PIL import Image, ImageDraw 
from lfsr import *
from collections import deque

TILE_RES = 20

WIDTH_TILES = 16

# THESE VALUES ARE IN TICKS
INITIAL_LEVEL_LENGTH = 10
LEVEL_LENGTH_INCREMENT = 2

# multiple the above values by this to get true # of rows
LEVEL_LENGTH_MULTIPLER = 8


def lfsr():
  return get_byte()


strips = [ 
        0b00000000, # 0
        0b00000000, # 1
        0b01100100, # 2
        0b00110000, # 3
        0b00011000, # 4
        0b00000011, # 5
        0b00000000, # 6
        0b11100001, # 7
        0b00001100, # 8
        0b10011100, # 9
        0b11000110, # 10
        0b00010011, # 11
        0b10010000, # 12
        0b11111100, # 13
        0b00110000, # 14
        0b00011011, # 15
      ]

def draw_level(seed, level):

  # initial strips (these are modified at runtime if level > 0)
  strips = [ 
          0b00000000, # 0
          0b00000000, # 1
          0b01100100, # 2
          0b00110000, # 3
          0b00011000, # 4
          0b00000011, # 5
          0b00000000, # 6
          0b11100001, # 7
          0b00001100, # 8
          0b10011100, # 9
          0b11000110, # 10
          0b00010011, # 11
          0b10010000, # 12
          0b11111100, # 13
          0b00110000, # 14
          0b00011011, # 15
        ]
  
  level_length = INITIAL_LEVEL_LENGTH

  # advance level by level times
  for i in range(level):
    simulate_advance_level()

  rows = level_length * 8





  # generate enough level data to fit an image
  level_data = []
  level_draw_buffer = []

  i = 0

  SCREEN_HEIGHT = 16
  LEVEL_HEIGHT = SCREEN_HEIGHT + 1
  for i in range((LEVEL_HEIGHT) * 2):
    level_data.append(0)
    level_draw_buffer.append(0)


  while (len(level_draw_buffer) < rows):
    # this is the very start of the actual game data!
    # the first thing we do whenever we get new data is call the LFSR
    lfsr_data = lfsr()
    advance_new(level_data, lfsr_data)

    # our goal is to just SIMULATE the level then draw it all at once.
    # therefore, we should copy the newly generated portion of the level
    # into the drawing buffer
    last_two = level_data[-2:]
    for slice in last_two:
      level_draw_buffer.append(slice)

  print(level_data)

  #region draw the output

  # now draw the actual level data
  width = WIDTH_TILES * TILE_RES
  height = rows * TILE_RES

  img = Image.new("RGB", (width, height)) 
  # create rectangle image 
  img1 = ImageDraw.Draw(img)
  

  index = 0
  while index < len(level_draw_buffer):
  # render it
    draw_row(level_draw_buffer[index:index+2], index // 2, img1)
    index += 2
  draw_tile(img1,0,0,"yellow")
  img.show() 
  #endregion

def draw_tile(image, x,y,color):
  shape = [(x * TILE_RES, y * TILE_RES), (x * TILE_RES + TILE_RES, y * TILE_RES + TILE_RES)]
  image.rectangle(shape, fill=color)

def simulate_advance_level(level_length, strips):
  strips.popleft()
  strips.popleft()
  strips.append(get_byte())
  strips.append(get_byte())

  level_length += LEVEL_LENGTH_INCREMENT

  strip_bump()

def draw_row(row_data, row_num, img):
  # row data is an array of two bytes
  for i in range(2):
    strip = row_data[i] # the level data should already be strips
    print("{0:b}".format(strip))
    for j in range(8):
      if (lsb(strip >> j) == 1):
        col = (i * 8) + (7 - j)
        draw_tile(img, col, row_num, "yellow")

def strip_bump(): 
  print("strip bump between levels - unimplemented")

# INTEGRATE THIS INTO THE MAIN CODE (PROBABLY TEST IT FIRST?)
def advance_new(level, lfsr_data):
  stack = []
  
  y = 33
  acc = lfsr_data
  acc = acc & 15
  x = acc
  stack.append(acc)

  advance_level_gen(acc,x,y,stack,lfsr_data,level)
  y -= 1
  x -= 1
  advance_level_gen(acc,x,y,stack,lfsr_data,level)

def advance_level_gen(acc,x,y,stack,lfsr_data,level):
  global strips
  acc = strips[x]  #  ; grab the strip located at strips[x]
  stack.append(acc) #  ; put that strip on the stack for later
  acc = lfsr_data # ; we'll use the hi two bits of the same LFSR value
  # if neither of the two hi bits r set, perform mixing operation
  bit_8 = acc & 0b10000000 
  bit_7 = acc & 0b01000000
  if ((not (bit_7 > 0)) and (not (bit_8 > 0))):
    acc = stack.pop()
    neg_index = y - 34 # index into end of array
    acc = acc ^ level[neg_index - 2] # shift up 2 (to get strip above it)
  else:
    # otherwise, continue as normal
    acc = stack.pop()

  level[y] = acc

  
# consider removing the x backup to stack in real code?


draw_level(0b00100101, 0)



# approaches to testing
# 1. create a sample assembly script with isolated function and see if output matches
# 2. base the expected output off the game !!

# we also need to sync up the new data generator thingy & the level
# data rendering I hooked up as an example.
# lets start with this lol