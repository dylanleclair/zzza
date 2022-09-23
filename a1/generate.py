
''' 
generate.py - a script to generate (horizontal) keyframes for a base character

TODO: 
    - add vertical support
    - clean up program output:
        1. spit out generated characters as constants (as opposed to loading into memory)
        2. boilerplate to automatically use output as a program stub
'''

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

output.append(base)

for i in range(4):
    temp = [] # character being generated
    for num in output[-1]:
        temp.append(num >> 2)
    output.append(temp)

output.append(base)

for i in range(4):
    temp = [] # character being generated
    for num in output[-1]:
        temp.append((num << 2) & 0xFC)
    output.append(temp)

print(" --- Starting code output ---")

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
            print("\tlda #${0:02x}".format(num))
            print("\tsta ${0:04x}".format(base_addr))
            base_addr +=1
        print()
            