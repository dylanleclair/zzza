from notes import *

chunk1 = [
    HIGH["C"], MID["A#"], EMPTY, EMPTY,
    HIGH["C"], EMPTY, EMPTY, MID["A#"],
    HIGH["C"], EMPTY, EMPTY, HIGH["D#"],
    HIGH["C"], EMPTY, MID["A#"], MID["G#"],
    ]

chunk2 = [
    LOW["F"], EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, LOW["G#"], EMPTY,
    EMPTY, EMPTY, LOW["G#"], EMPTY,
    LOW["F"], EMPTY, LOW["G#"], EMPTY
]
chunk3 = [
    MID["A#"], MID["G#"], MID["F"], EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
]


chunk4 = [
    HIGH["C"],HIGH["D#"],EMPTY,HIGH["C"],
    HIGH["D#"], MID["G#"], HIGH["C"], EMPTY,
    EMPTY, HIGH["C"], HIGH["D#"], MID["G#"],
    HIGH["D#"], EMPTY, HIGH["C"], EMPTY,
]


chunk5 = [
    HIGH["F"],HIGH["F"],EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
]

chunk6 = [
    EMPTY, MID["F"], MID["A#"], EMPTY,
    MID["A#"], EMPTY, MID["G#"], MID["F"],
    MID["G#"], MID["A#"], EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
]

chunk7 = [
    LOW["A#"], EMPTY, EMPTY, EMPTY,
    LOW["A"], EMPTY, EMPTY, EMPTY,
    LOW["G#"], EMPTY, EMPTY, EMPTY,
    LOW["G"], EMPTY, EMPTY, EMPTY,
]

chunk8 = [
    MID["F"], HIGH["C"], EMPTY, MID["F"],
    MID["B"], EMPTY, MID["F"], MID["A#"],
    EMPTY, MID["F"], MID["G#"], EMPTY,
    MID["F"], EMPTY, EMPTY, EMPTY,
]

chunk9 = [
    HIGH["G"], HIGH["F"], HIGH["D#"], HIGH["G"],
    EMPTY, HIGH["F"], HIGH["D#"], HIGH["G"],
    EMPTY, HIGH["F"], HIGH["D#"], HIGH["G"],
    EMPTY, EMPTY, EMPTY, EMPTY,
]

chunk10 = [
    HIGH["G"], HIGH["F"], HIGH["D#"], HIGH["G"],
    EMPTY, HIGH["F"], HIGH["D#"], HIGH["G"],
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, MID["G#"], MID["A"], MID["A#"],
]

chunk11 = [
    LOW["G"], EMPTY, EMPTY, LOW["F"],
    EMPTY, EMPTY, LOW["E"], EMPTY,
    EMPTY, LOW["D"], EMPTY, EMPTY,
    EMPTY, LOW["D"], EMPTY, EMPTY
]

chunk12 = [
    LOW["G"], EMPTY, EMPTY, EMPTY,
    LOW["F"], EMPTY, EMPTY, EMPTY,
    LOW["E"], EMPTY, EMPTY, EMPTY,
    LOW["D"], EMPTY, EMPTY, EMPTY,
]

chunk13 = [
    MID["B"], MID["B"], MID["B"], MID["B"],
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
]

chunk14 = [
    LOW["G"], EMPTY, EMPTY, EMPTY,
    LOW["F"], EMPTY, EMPTY, EMPTY,
    LOW["E"], EMPTY, EMPTY, EMPTY,
    LOW["G"], EMPTY, EMPTY, EMPTY,
]

chunk15 = [
    LOW["A#"], EMPTY, EMPTY, EMPTY,
    LOW["A"], EMPTY, EMPTY, EMPTY,
    LOW["G#"], EMPTY, EMPTY, EMPTY,
    LOW["G"], EMPTY, EMPTY, EMPTY,
]
chunk16 = [
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
    EMPTY, EMPTY, EMPTY, EMPTY,
]

# plays on S2 register

# SONG_INDEX tracks which note in a sound is being played
# SONG_chunkINDEX tracks which chunk of song we are in

channel_a = [1,3,4,5,1,3,4,5,6,6,8,8,9,10,13,16]   # use as indexes on top of INDIRECT_SOUND_X

# plays on S1 register
channel_b = [2,2,2,2,2,2,2,2,7,7,2,2,12,14,15,15]   # use as indexes on top of INDIRECT_SOUND_X
