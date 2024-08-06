###############################################################################
#   MUSIC GUIDE:
#   - The song is made up of individual notes
#   - Every 4 notes comprises a bar of music ("bar" is what is used in music)
#   - Every 4 bars of music is noted here as a "chunk"
#       - This is because Bosca Cielo (our music writing program) groups the
#         notes this way
#   - These chunks are then arranged to make the song
#       - "pattern_a" and "pattern_b" are the high and low bars of the music
#
#   - To create music:
#       1) Write the song in Bosca Cielo
#       2) Create a new file for the song that imports notes.py
#           - "from notes import *"
#       2) Translate the chunks from Bosca Cielo to the chunk notation here
#       3) Copy the chunk arrangement from Bosca Cielo to the pattern lists
#
#   Import the data (.py) into this file to have it translated into ASM, see
#   the "original.py" file for an example
###############################################################################
import blue_eva as song
# SONG_INDEX tracks which note in a sound is being played
# SONG_CHUNK_INDEX tracks which chunk of song we are in



def print_channel_asm(channel, chunkTitle):

    stub = f"{chunkTitle}\n\tdc.b "
    for entry in channel:
        stub += f"#{entry-1}, "

    print(stub)


def print_chunk_asm(channel,label):
    print(label)
    stub = "\tdc.b "
    for entry in channel:
        stub += f"#{entry}, "

    print(stub)


print_channel_asm(song.channel_a, "SONG_CHUNKS_A")

print_channel_asm(song.channel_b, "SONG_CHUNKS_B")
print("SONG_NOTES")

# quite possibly some orf the ugliest code ive ever written but it gets the job done (mostly)

def gather_chunks():
    print("; gathering chunks")
    print_chunk_asm(song.chunk1, "\t; chunk 1")
    print_chunk_asm(song.chunk2, "\t; chunk 2")
    print_chunk_asm(song.chunk3, "\t; chunk 3")
    print_chunk_asm(song.chunk4, "\t; chunk 4")
    # print_chunk_asm(song.chunk5, "; chunk 5")
    # print_chunk_asm(song.chunk6, "; chunk 6")
    # print_chunk_asm(song.chunk7, "; chunk 7")
    # print_chunk_asm(song.chunk8, "; chunk 8")
    # print_chunk_asm(song.chunk9, "; chunk 9")
    # print_chunk_asm(song.chunk10, "; chunk 10")
    # print_chunk_asm(song.chunk11, "; chunk 11")
    # print_chunk_asm(song.chunk12, "; chunk 12")
    # print_chunk_asm(song.chunk13, "; chunk 13")
    # print_chunk_asm(song.chunk14, "; chunk 14")
    # print_chunk_asm(song.chunk15, "; chunk 15")
    # print_chunk_asm(song.chunk16, "; chunk 16")


gather_chunks()
