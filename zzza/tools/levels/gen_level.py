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


def draw_level(seed, level):

  # initial strips (these are modified at runtime if level > 0)
  strips = [ 
          0b00000000,
          0b00000000,
          0b01100100,
          0b00110000,
          0b00011000,
          0b00000011,
          0b00000000,
          0b11100001,
          0b00001100,
          0b10011100,
          0b11000110,
          0b00010011,
          0b10010000,
          0b11111100,
          0b00110000,
          0b00011011,
        ]
  
  level_length = INITIAL_LEVEL_LENGTH

  # advance level by level times
  for i in range(level):
    simulate_advance_level()

  rows = level_length * 8

  # now draw the actual level data
  width = WIDTH_TILES * TILE_RES
  height = rows * TILE_RES

  img = Image.new("RGB", (width, height)) 
  # create rectangle image 
  img1 = ImageDraw.Draw(img)
  
  # generate enough level data to fit an image
  level_data = []

  i = 0

  while i < (rows * 2) - 1:
    # keep generating data
    if (level)


  for i in range(rows * 2):
    level_data.append((get_byte() & 0xf))

  print(level_data)

  index = 0
  while index < len(level_data):
  # render it
    draw_row(level_data[index:index+2], index // 2, img1, strips)
    index += 2
  draw_tile(img1,0,0,"yellow")
  img.show() 



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

def draw_row(row_data, row_num, img, strips):
  # row data is an array of two bytes
  print(row_data)
  for i in range(2):
    strip = strips[row_data[i]]
    print("{0:b}".format(strip))
    for j in range(8):
      if (lsb(strip >> j) == 1):
        col = (i * 8) + (7 - j)
        print("col: " + str(col))
        draw_tile(img, col, row_num, "yellow")

def strip_bump(): 
  print("strip bump between levels - unimplemented")

draw_level(0b10010001, 0)