
''' 
generate.py - a script to generate (horizontal) keyframes for a base character

TODO: 
    - add vertical support
    - clean up program output:
        1. spit out generated characters as constants (as opposed to loading into memory)
        2. boilerplate to automatically use output as a program stub
'''

# this is a smiley face!

bitmap = [
    "00111100",    
    "01000010",    
    "10100101",    
    "10000001",    
    "10100101",    
    "10011001",    
    "01000010",    
    "00111100",      
]

def preview (character):
    # print each number
    print (';preview:')
    for num in character:
        print(";{0:08b}".format(num));

base = []

output = [] # each entry in this will be an array of ints representing a character

for item in bitmap:
    # calculate the number representing the row
    num = int(item.encode('ascii'),2)
    #output += str(byte_string) + "\n"
    base.append(num)


# HORIZONTAL KEYFRAMES

'''

shifts = [8,6,4,2]

for shift in shifts:
    character = []
    for num in base:
        character.append((num << shift) & 0xff) 
    output.append(character)
shifts = [0,2,4,6]

for shift in shifts:
    character = []
    for num in base:
        character.append(num >> shift)
    output.append(character)
'''

# VERTICAL KEYFRAMES

shifts = [8,6,4,2]

for shift in shifts:
    character = base[0:len(base)-shift]
    while(len(character) < 8):
        character.insert(0,0)
    output.append(character)

# down
shifts = [0,2,4,6]

for shift in shifts:
    character = base[shift:]
    while (len(character) < 8):
        character.append(0)
    output.append(character)



print(" --- Starting code output ---")


for character in output: 
    preview(character)
    print()


'''
# generate the code to stdout
base_addr = 7168 + 8
for character in output:
    zero = 0
    for num in character:
        zero |= num

    if not (character == base or zero == 0):
        preview(character)
        print("; character")
        # precalculate offset to avoid extra instructions

        for num in character:
            print("\tlda #%{0:08b}".format(num))
            print("\tsta ${0:04x}".format(base_addr))
            base_addr +=1
        print()
'''
count = 0
for character in output:
    print("\t; character " + str(count))
    for byte in character:
        print("\tdc.b #%{0:08b}".format(byte))
    count +=1


# transition table:

# 0 -> 1
# 1 -> 2
# 2 -> 3
# 3 -> 4
# 4 -> 5
# 5 -> 6
# 6 -> 7
# 7 -> 0


