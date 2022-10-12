import random
import bitstring

# each two-byte number represents a 16-chunk pattern that can
# be displayed on screen: when read as binary, a 1 indicates a block,
# and a 0 indicates empty space
hex_patterns = [
    b"\x40\x08",
    b"\x30\x00",
    b"\x8c\x20",
    b"\xc1\x91",
    b"\x83\x42",
    b"\x08\x24",
    b"\x04\xc4",
    b"\x01\x03"
]

# assumes screen is 16 blocks tall and level is 6 full screens
def generate_level():
    level = []
    for _ in range(96):
        level.append(random.randint(0,7))
    
    return level

# display a level using ascii art
def print_level(level):
    print("----------------------------------")

    for i in level:
        print("|", end="")

        # grab the proper bytes representing this row
        row = hex_patterns[i]

        # convert the pattern to a string of 1s and 0s
        bit_row = bitstring.BitArray(row)

        # display ascii on screen corresponding to bits
        for b in bit_row:
            if b:
                print("\u2588\u2588", end="")
            else:
                print("  ", end="")
        
        print("|")
    print("----------------------------------")


if __name__ == "__main__":
    l = generate_level()
    print_level(l)

# # these are the same patterns as hex_patterns, but human readable
# patterns = [
#     [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
#     [0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#     [1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
#     [1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1],
#     [1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0],
#     [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0],
#     [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1],
#     [0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0]
# ]