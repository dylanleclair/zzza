# Constants (these are the same as the vic colour codes btw)
BLACK = 0
WHITE = 1
RED = 2
CYAN = 3
PURPLE = 4
GREEN = 5
BLUE = 6
YELLOW = 7
ORANGE = 8
L_ORANGE = 9
PINK = 10
L_CYAN = 11
L_PURPLE = 12
L_GREEN = 13
L_BLUE = 14
L_YELLOW = 15

# desired screen setup
SCREEN = BLACK
BORDER = WHITE
CHAR = PURPLE
AUX = CYAN

colour_pattern = [
    # [BLACK, CYAN, CYAN, BLACK],
    # [CYAN, WHITE, WHITE, CYAN],
    # [CYAN, WHITE, WHITE, CYAN],
    # [WHITE, PURPLE, PURPLE, WHITE],
    # [BLACK, CYAN, CYAN, BLACK],
    # [PURPLE, BLACK, BLACK, PURPLE],
    # [WHITE, WHITE, WHITE, WHITE],
    # [CYAN, BLACK, BLACK, CYAN]
    [BLACK, CYAN, CYAN, BLACK],
    [BLACK, CYAN, WHITE, BLACK],
    [BLACK, CYAN, WHITE, BLACK],
    [WHITE, PURPLE, PURPLE, BLACK],
    [BLACK, CYAN, CYAN, WHITE],
    [PURPLE, BLACK, PURPLE, BLACK],
    [WHITE, WHITE, WHITE, WHITE],
    [CYAN, BLACK, BLACK, CYAN]

]

bit_data = ""

for line in colour_pattern:
    for colour in line:
        if colour == SCREEN:
            bit_data += "00"
        elif colour == BORDER:
            bit_data += "01"
        elif colour == CHAR:
            bit_data += "10"
        elif colour == AUX:
            bit_data += "11"

    print("    dc.b #%" + bit_data)
    bit_data = ""