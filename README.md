# ZZZA
Term project for CPSC 599.82: Retrogames.  Fall 2022.  Dr. John Aycock.

Written for the Commodore VIC-20 by Runtime Terror.

![title-screen](assets/title-screen.png)


## How To Play
Your goal is to get to the bottom of the level without falling off the bottom or getting pushed off the top of the screen.
Once you reach the bottom of the level, a door will appear where Eva will deliver the pizza and adcance to the next level!
Push and stomp blocks to get out of tricky spots and keep moving.

The game has 16 levels, with 4 different environments.
### Key Map
* **A**: Moves Eva left
    - if Eva is colliding with a block, will also try to push the block left if possible
    - Some blocks are heavier than others!  **Hold A** to make Eva push until the block moves
* **D**: Moves Eva right
    - if Eva is colliding with a block, will also try to push the block right if possible
    - Some blocks are heavier than others!  **Hold D** to make Eva push until the block moves

* **S**: Stomps a block out from under you (if possible)

* **K**: If you're stuck, press K to "kill" Eva and restart the level (but lose a life!)

* **M**: Mutes the music for the current level

If you get stuck, please refer to your copy of the game manual.

## Features


### Autoscroll
* The level automatically scrolls up, which pushes the player towards the top of the screen.  The player needs to fall down the level without falling off the bottom to stay alive.

* Levels are stored as an array of 34 bytes, each representing 8 screen locations that can either be empty (0) or have a block in them (1). The lowest two bytes of the array hold a line of data that is not yet onscreen, but is about to scroll in.
### Procedural Content Generation
* Levels are generated procedurally using a simple LFSR. The lower 4 bits of the LFSR are used as an index into a table of 16 different strips: patterns of data that make interesting levels. A single line of the screen is filled by indexing into the lookup table of strips and taking that strip and the one immediately above it. In this way, we're able to have some control over which patterns can and can't display together on a single line.

* After a section of levels (4 of them to be exact -- you'll notice the screen will change color) is completed, the [strips get shuffled](https://gitlab.cpsc.ucalgary.ca/emily.baird/cpsc-599-retrogames/-/blob/main/zzza/level-init.asm#L23). 
  * We intended to actually swap them randomly using the LFSR, but after playtesting decided not to: with the code as it is, sets of levels had a distinct feel / theme.

* If you've really starving for pain, you can checkout [difficulty-optim-2](https://gitlab.cpsc.ucalgary.ca/emily.baird/cpsc-599-retrogames/-/tree/difficulty-optim-2) which has a more convoluted shuffle and provides much more challenging levels. 

### Endless Mode

* Once you finish all 16 levels of the main game, your boss - Robini - will give you a code to unlock Endless Mode.  Type the code in on the title screen **before** the "Press Any Key" prompt appears and you the game will load a nearly endless level with a random seed to generate a unique level!  You can reuse the code to keep playing in Endless Mode.

<details>
  <summary>Click to show endless mode code:</summary>
  EVA
</details>

### Player Movement
* Eva moves around the screen by taking user input from the GETTIN kernal call.  The input is stored in zero page for use in player movement subroutines.  Collision checking is done by AND-ing the byte containing the level data with a byte representing the position Eva wants to move to.  A return value of >= 1 means that Eva is colliding with a piece of the level.  The same collision routines are used to check for block movements and landings for block that have been pushed.
### Hi-Res Animation

* Eva is smoothly animated in all directions through the high-resolution buffer.

* This works by having a 9 character buffer, with Eva always placed at the center to begin with. 

* She is then shifted into the appropriate position based on a number of factors. 
  * For example, Eva is rendered on top of blocks by shifting her the same amount as the block under her (conveniently, this is calculated by our `ANIMATION_FRAME`).

* This technique is also used to smoothly move her left and right, but all of her horizontal movement happens at the same time (right after another).
  * Originally, we implemented left and right movement to happen at the same rate as vertical movement and this felt ***awful***. We pivoted to giving Eva the ability to move several times either left or right (per vertical block movement), which had a much juicier feel.

* See [`custom_charset.asm`](https://gitlab.cpsc.ucalgary.ca/emily.baird/cpsc-599-retrogames/-/blob/main/zzza/custom_charset.asm) for a more detailed explanation of how this works!

### Block Manipulation
*  When Eva pushes or stomps a block, its byte of level data is identified and the byte is XORed with a mask, effeectively removing the block from the level. When a block lands, its coordinates are again used to target the byte of level data where it landed, and it is XORed back into the level.

* While in the air, the block is treated as a separate game entity like Eva, with an X,Y coordinate. Like Eva, it will fall through empty space until a collision is detected.

* There can only be one moving block at a time. If no block is in the air, the block X,Y are set to 0xFF

* Blocks can be stomped at any time, but can only be pushed on specific frames. This helps ensure that the moving block can be drawn cleanly without causing artifacting in surrounding spaces.t 

### Music

* The music is stored in a set of chunks, which are just a contiguous array of notes to be played. We created a soundtrack with [Bosca Ceoil](https://boscaceoil.net/) and manually translated the chunks into arrays of human-readable notes that are processed with [music-parser.py](https://gitlab.cpsc.ucalgary.ca/emily.baird/cpsc-599-retrogames/-/blob/main/zzza/tools/music-parser.py) which spits out the chunks as assembly constants to paste into the program. 
  * (This program was mostly to help change keys and manage adjustments in song data much easier).

* Our song plays on two channels at once, hence the `channel_a` and `channel_b` variables:

  ```python
  channel_a = [1,3,4,5,1,3,4,5,6,6,8,8,9,10,13,16]
  channel_b = [2,2,2,2,2,2,2,2,7,7,2,2,12,14,15,15]
  ```
* Chunks are only ever played in one channel. Once one chunk completes, a global chunk index gets incremented and the song continues. At one point we even experimented with playing the game as the "music" to save some space, but Jeremy's sick beats weren't about to be sacrificed & he squeezed ZX02 into the game to buy us some space.

* The function [next_note](https://gitlab.cpsc.ucalgary.ca/emily.baird/cpsc-599-retrogames/-/blob/main/zzza/sound.asm#L22) (which simply moves the next note of the chunk being played into the sound registers) is called once every iteration of the game loop, resulting in the music matching the pace of the game (each section of levels plays the music at a different speed)!

### HUD (Heads Up Display)
* The playfield is 16x16, which means the entire playfield is 256 bytes of screen data (allowing us to use a single counter to loop over the entire screen and know its done when it overflows).
* The HUD is a 16x3 area under the playfield.  It contains:
    - A progress bar telling you how far through the level you are
    - Pizza slice icons to incidcate how many lives the player has left