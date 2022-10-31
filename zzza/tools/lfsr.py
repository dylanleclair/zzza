import random
import bitstring

# each one-byte number represents an 8x1 strip of characters to display on screen
bit_patterns = [
    "01010101",
    "00011110",
    "00110011",
    "00000000",
    "10001100",
    "00011100",
    "11000001",
    "10011001",
    "10000011",
    "01000010",
    "00001000",
    "00100100",
    "11001100",
    "11000100",
    "11110001",
    "11011100"
]

# an lfsr generator that takes a 1-byte seed and generates 1-byte outputs
# uses a left shift, and fills the low bit with taps from positions 0 and 3
def lfsr(seed):
    # convert to a string of 1s and 0s, we only want the least significant 8 bits
    bits = bitstring.BitArray(seed.to_bytes(2, "big"))[-9:-1]

    # resumes here every time lfsr is called again
    while True:
        # save the taps before shifting
        tap1 = bits[0]
        tap2 = bits[3]

        # shift the pattern left by 1
        bits <<= 1

        # fill in the low bit with the xor results
        bits.set(tap1^tap2,7)

        # yield the result 
        yield bits.int


if __name__ == "__main__":
    rand_gen = lfsr(0x9f)
    for i in range(10):
        print(next(rand_gen))

