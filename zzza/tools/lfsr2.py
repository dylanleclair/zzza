seed = 0b10010001

state = seed

for i in range (500):
    # get bits at position 7 and 6
    bitSeven = (state >> 7) & 0b1
    bitSix = (state >> 6) & 0b1

    # OR the 7th and 6th bits together to get the output bit
    outputBit = bitSeven ^ bitSix
    print(outputBit, end='')

    # left shift the state & mask out the 8th bit to keep it an 8 bit number
    newState = (state << 1) & 0b11111111

    # add the output bit into the 0th position on the state
    newState = newState | outputBit

    # set the state to the newState
    state = newState

    # check what the period of the current implementation is
    if state == seed:
        print("")
        print("Period is: " + str(i))
        break
