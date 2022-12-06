


OCTAVE_LOW = {
    "C": 135,
    "C#":143, 
    "D":147, 
    "D#":151, 
    "E":159, 
    "F":163, 
    "F#":167, 
    "G":175, 
    "G#":179, 
    "A":183, 
    "A#":187, 
    "B":191, 
    }

OCTAVE_MID = {
    "C": 195,
    "C#":199, 
    "D": 201, 
    "D#":203, 
    "E":207, 
    "F":209, 
    "F#":212, 
    "G":215, 
    "G#":217, 
    "A":219, 
    "A#":221, 
    "B":223, 
}


OCTAVE_HIGH = {
    "C": 225,
    "C#": 227, 
    "D": 228, 
    "D#":229, 
    "E":231, 
    "F":232, 
    "F#":233, 
    "G":235, 
    "G#":236, 
    "A":237, 
    "A#":238, 
    "B":239, 
}

EMPTY = 0;



# idea: indirect address into 16 element array telling u arrangement.
# keep a master array of the arrangement


chunk_1 = [ 
    OCTAVE_HIGH["C"], OCTAVE_MID["A#"], EMPTY, EMPTY, 
    OCTAVE_HIGH["C"], EMPTY, EMPTY, OCTAVE_MID["A#"],
    OCTAVE_HIGH["C"], EMPTY, EMPTY, OCTAVE_HIGH["D#"],
    OCTAVE_HIGH["C"], EMPTY, OCTAVE_MID["A#"], OCTAVE_MID["G#"],
    ]

chunk_2 = [
    OCTAVE_LOW["F"], EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, OCTAVE_LOW["G#"], EMPTY,
    EMPTY, EMPTY, OCTAVE_LOW["G#"], EMPTY,
    OCTAVE_LOW["F"], EMPTY, OCTAVE_LOW["G#"], EMPTY
] 
chunk_3 = [
    OCTAVE_MID["A#"], OCTAVE_MID["G#"], OCTAVE_MID["F"], EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
]


chunk_4 = [
    OCTAVE_HIGH["C"],OCTAVE_HIGH["D#"],EMPTY,OCTAVE_HIGH["C"],
    OCTAVE_HIGH["D#"], OCTAVE_MID["G#"], OCTAVE_HIGH["C"], EMPTY,
    EMPTY, OCTAVE_HIGH["C"], OCTAVE_HIGH["D#"], OCTAVE_MID["G#"],
    OCTAVE_HIGH["D#"], EMPTY, OCTAVE_HIGH["C"], EMPTY,
]


chunk_5 = [
    OCTAVE_HIGH["F"],OCTAVE_HIGH["F"],EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
]

chunk_6 = [
    EMPTY, OCTAVE_MID["F"], OCTAVE_MID["A#"], EMPTY,
    OCTAVE_MID["A#"], EMPTY, OCTAVE_MID["G#"], OCTAVE_MID["F"],
    OCTAVE_MID["G#"], OCTAVE_MID["A#"], EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
]

chunk_7 = [
    OCTAVE_LOW["A#"], EMPTY, EMPTY, EMPTY,
    OCTAVE_LOW["A"], EMPTY, EMPTY, EMPTY,
    OCTAVE_LOW["G#"], EMPTY, EMPTY, EMPTY,
    OCTAVE_LOW["G"], EMPTY, EMPTY, EMPTY,
]

chunk_8 = [
    OCTAVE_MID["F"], OCTAVE_HIGH["C"], EMPTY, OCTAVE_MID["F"],
    OCTAVE_MID["B"], EMPTY, OCTAVE_MID["F"], OCTAVE_MID["A#"],
    EMPTY, OCTAVE_MID["F"], OCTAVE_MID["G#"], EMPTY,
    OCTAVE_MID["F"], EMPTY, EMPTY, EMPTY,
]

chunk_9 = [
    OCTAVE_HIGH["G"], OCTAVE_HIGH["F"], OCTAVE_HIGH["D#"], OCTAVE_HIGH["G"],
    EMPTY, OCTAVE_HIGH["F"], OCTAVE_HIGH["D#"], OCTAVE_HIGH["G"],
    EMPTY, OCTAVE_HIGH["F"], OCTAVE_HIGH["D#"], OCTAVE_HIGH["G"],
    EMPTY, EMPTY, EMPTY, EMPTY,
]

chunk_10 = [
    OCTAVE_HIGH["G"], OCTAVE_HIGH["F"], OCTAVE_HIGH["D#"], OCTAVE_HIGH["G"],
    EMPTY, OCTAVE_HIGH["F"], OCTAVE_HIGH["D#"], OCTAVE_HIGH["G"],
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, OCTAVE_MID["G#"], OCTAVE_MID["A"], OCTAVE_MID["A#"],
]

chunk_11 = [
    OCTAVE_LOW["G"], EMPTY, EMPTY, OCTAVE_LOW["F"],
    EMPTY, EMPTY, OCTAVE_LOW["E"], EMPTY,
    EMPTY, OCTAVE_LOW["D"], EMPTY, EMPTY,
    EMPTY, OCTAVE_LOW["D"], EMPTY, EMPTY
]

chunk_12 = [
    OCTAVE_LOW["G"], EMPTY, EMPTY, EMPTY,
    OCTAVE_LOW["F"], EMPTY, EMPTY, EMPTY,
    OCTAVE_LOW["E"], EMPTY, EMPTY, EMPTY,
    OCTAVE_LOW["D"], EMPTY, EMPTY, EMPTY,
]

chunk_13 = [
    OCTAVE_MID["B"], OCTAVE_MID["B"], OCTAVE_MID["B"], OCTAVE_MID["B"],
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
]

chunk_14 = [
    OCTAVE_LOW["G"], EMPTY, EMPTY, EMPTY,
    OCTAVE_LOW["F"], EMPTY, EMPTY, EMPTY,
    OCTAVE_LOW["E"], EMPTY, EMPTY, EMPTY,
    OCTAVE_LOW["G"], EMPTY, EMPTY, EMPTY,
]

chunk_15 = [
    OCTAVE_LOW["A#"], EMPTY, EMPTY, EMPTY,
    OCTAVE_LOW["A"], EMPTY, EMPTY, EMPTY,
    OCTAVE_LOW["G#"], EMPTY, EMPTY, EMPTY,
    OCTAVE_LOW["G"], EMPTY, EMPTY, EMPTY,
]
chunk_16 = [
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
]


# plays on S2 register

# SONG_INDEX tracks which note in a sound is being played
# SONG_CHUNK_INDEX tracks which chunk of song we are in

channel_a = [1,3,4,5,1,3,4,5,6,6,8,8,9,10,13,16]   # use as indexes on top of INDIRECT_SOUND_X

# plays on S1 register
channel_b = [2,2,2,2,2,2,2,2,7,7,2,2,12,14,15,15]   # use as indexes on top of INDIRECT_SOUND_X

# we will then do some math with song_index and song_chunk_index to find the correct note in a huge 2d array of all the notes



def print_channel_asm(channel):
    stub = "dc.b "
    for entry in channel:
        stub += f"#{entry-1}, "

    print(stub)


def print_chunk_asm(channel,label):
    print(label)
    stub = "dc.b "
    for entry in channel:
        stub += f"#{entry}, "

    print(stub)


print_channel_asm(channel_a)

print_channel_asm(channel_b)

# quite possibly some orf the ugliest code ive ever written but it gets the job done (mostly)

def gather_chunks():
    print("; gathering chunks")
    print_chunk_asm(chunk_1, "; chunk 1")
    print_chunk_asm(chunk_2, "; chunk 2")
    print_chunk_asm(chunk_3, "; chunk 3")
    print_chunk_asm(chunk_4, "; chunk 4")
    print_chunk_asm(chunk_5, "; chunk 5")
    print_chunk_asm(chunk_6, "; chunk 6")
    print_chunk_asm(chunk_7, "; chunk 7")
    print_chunk_asm(chunk_8, "; chunk 8")
    print_chunk_asm(chunk_9, "; chunk 9")
    print_chunk_asm(chunk_10, "; chunk 10")
    print_chunk_asm(chunk_11, "; chunk 11")
    print_chunk_asm(chunk_12, "; chunk 12")
    print_chunk_asm(chunk_13, "; chunk 13")
    print_chunk_asm(chunk_14, "; chunk 14")
    print_chunk_asm(chunk_15, "; chunk 15")
    print_chunk_asm(chunk_16, "; chunk 16")


gather_chunks()