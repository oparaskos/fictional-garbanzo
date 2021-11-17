/*---------------------------------------------------------------------------------


	Simple tile mode 1 with scrolling demo
	-- alekmaul


---------------------------------------------------------------------------------*/
#include <snes.h>

#include "soundbank.h"
#include "data/sprites.h"
#include "data/maps.h"
#include "data/fonts.h"

//---------------------------------------------------------------------------------
extern char SOUNDBANK__;
extern char jumpsnd,jumpsndend;

//---------------------------------------------------------------------------------

#define GRAVITY 48
#define JUMPVALUE (GRAVITY*20)

//---------------------------------------------------------------------------------
typedef struct
{
	unsigned int x, y;
	int jmpval;
	int anim_frame;
	int flipx;
} Player;

enum {PLAYER_DOWN = 0, PLAYER_JUMPING = 0, PLAYER_WALKING = 0, PLAYER_STANDING = 0};  // Player states
enum PlayerState {W_JUMP = 1, W_RIGHT = 2,  W_LEFT = 3};

u16 scrX;
Player mario;
brrsamples Jump;                    // The sound for jumping

u16 pad0, move, i;                  // loop & pad variable
const u16 MAP_START_Y = 240;
const int BG_1_ADDR = 0x6000;
const int BG_2_ADDR = 0x3000;
//---------------------------------------------------------------------------------
u16 getCollisionTile(u16 x, u16 y) {
	u16 *ptrMap = (u16 *) &col_1_1_map + (y>>3)*300 + (x>>3);
	
	return (*ptrMap);
}

//---------------------------------------------------------------------------------
void moveLevel(unsigned char direction) {
	u16 *ptrMap;
	u16 ptrVRAM; 
	unsigned short sx;
	
	REG_VMAIN = VRAM_INCHIGH | VRAM_ADRTR_0B | VRAM_ADRSTINC_1; // set address in VRam for read or write ($2116) + block size transfer ($2115)
	REG_VMADDLH = 0x1000;
	
	if (direction == W_RIGHT) {
		scrX++; 
		if ( (scrX &7) == 0) { // to avoid to bee too slow
		    //*(unsigned char *) 0x2115 = 0x80;
			sx = (scrX>>3) & 63;
			sx = (sx + 32);
			if (sx>63) 
				sx = sx - 64;
			else
				sx = (sx-32) + 32*32;
			ptrVRAM = 0x1000 + sx; // screen begin to 0x1000
			ptrMap  = (u16 *)  &map_1_1_map + (scrX >> 3) + 32; 
			// Copy the line in the background but need to wait VBL period
			WaitVBLFlag;
			for (i=0;i<16;i++) {
				u16 value = *ptrMap;
				REG_VMADDLH = ptrVRAM;
				REG_VMDATALH = value ;
				ptrVRAM += 32;
				ptrMap += 300;
			}
		}
	}
	// scroll to the left
	else {
		scrX--; 
		if ( (scrX &7) == 0) { // to avoid to bee too slow
			if (scrX) { // to avoid doing some for 1st tile 
				//*(unsigned char *) 0x2115 = 0x80;
				sx = (scrX>>3) & 63;
				sx = (sx - 1);
				if (sx<0) sx = sx + 64;
				if (sx>31) sx = (sx-32) + 32*32;
				ptrVRAM = 0x1000 + sx; // screen begin to 0x1000
				ptrMap  = (u16 *)  &map_1_1_map + (scrX >> 3) - 1; 
				// Copy the line in the background but need to wait VBL period
				WaitVBLFlag;
				for (i=0;i<16;i++) {
					u16 value = *ptrMap;
					REG_VMADDLH = ptrVRAM;
					REG_VMDATALH = value ;
					ptrVRAM += 32;
					ptrMap += 300;
				}
			}
		}
	}

	// now scroll with current value
	bgSetScroll(1,scrX,MAP_START_Y);
}

//---------------------------------------------------------------------------------
void moveMario() {
	// Update scrolling with current pad (left / right / jump can combine)
	if (pad0 & (KEY_RIGHT | KEY_LEFT | KEY_A) ) {
		if (pad0 & KEY_RIGHT) { 
      	// consoleNocashMessage("RIGHT");
			// if we can go right
			if (getCollisionTile(scrX+(mario.x>>8)+16, MAP_START_Y+(mario.y>>8)) == 0) {
				// if when are less than screen center, let's go
				if (mario.x<(128<<8)) { // If mario coord is not center
					mario.x+=256;
				}
				// else if screen can scroll (width minus one screen)
				else if (scrX<(300*8-32*8)) {
					moveLevel(W_RIGHT);
				}
				// else, can go if not on right of screen
				else  {
					if (mario.x<(255<<8)) mario.x+=256;
				}
				mario.flipx=0;
			}
		}
		// Else it's perhaps left :)
		else if (pad0 & KEY_LEFT)  {
      	// consoleNocashMessage("LEFT");
			// can we go left ?
			if ((scrX+(mario.x>>8)-1>0) && (getCollisionTile(scrX+(mario.x>>8)-1, (mario.y>>8)) == 0)) { 
				// if we are on the right of the screen, go to center
				if (mario.x>(128<<8)) {
					mario.x-=256;
				}
				// else if screen can scroll
				else if (scrX>0) {
					moveLevel(W_LEFT);
				}
				// else, can go if not on mleft of screen
				else if (mario.x>(0<<8)) {
					mario.x-=256;
				}
				mario.flipx=1;
			}
		}
		// Hum, no perhaps jumping \o/
		if (pad0 & KEY_A) {
			// can jump ??
			if (getCollisionTile(scrX+(mario.x>>8), (mario.y>>8)+16) != 0) {
				mario.jmpval = -JUMPVALUE;
				mario.anim_frame = PLAYER_JUMPING;
				spcPlaySound(0);
			}
		}

		// Update frame if not jumping
		if (mario.anim_frame != PLAYER_JUMPING) {
			if ((mario.anim_frame<PLAYER_WALKING) || (mario.anim_frame == PLAYER_STANDING)) {
				mario.anim_frame = PLAYER_WALKING;
			}
			else {
				mario.anim_frame++;
				if(mario.anim_frame >= PLAYER_STANDING) mario.anim_frame = PLAYER_WALKING;
			}
		}
	}
	// down to have small mario
	else if (pad0 & KEY_DOWN) {
      	// consoleNocashMessage("DOWN");
		mario.anim_frame = PLAYER_DOWN;
	}
	// well, no pad value, so just standing !
	else {
		if (mario.anim_frame != PLAYER_JUMPING) mario.anim_frame = PLAYER_STANDING;
	}

	// if can jump, just do it !
	if (getCollisionTile((scrX+(mario.x>>8)+8), ((mario.y>>8)+16)) == 0) {
		mario.jmpval += GRAVITY;
	}

	// Add jumping value if needed
	mario.y += mario.jmpval;
	
	// Again test collsion with ground
	if (getCollisionTile((scrX+(mario.x>>8)+8), ((mario.y>>8)+16)) != 0) {
		if (mario.jmpval) {
			mario.jmpval = 0;
			mario.anim_frame = PLAYER_STANDING;
		}
	}
	
	// To avoid being in floor
	while (getCollisionTile((scrX+(mario.x>>8)+8), ((mario.y>>8)+15))) {
		mario.y -= 128; 
		mario.jmpval = 0;
	}
}



//---------------------------------------------------------------------------------
int main(void) {
	// Initialize sound engine (take some time)
	spcBoot();
	
    // Initialize SNES 
	consoleInit();
    
	// Set give soundbank
	spcSetBank(&SOUNDBANK__);
	
	// allocate around 10K of sound ram (39 256-byte blocks)
	spcAllocateSoundRegion(39);

	// Load music
	spcLoad(MOD_OVERWORLD);
	
	// Load sample
	spcSetSoundEntry(15, 8, 6, &jumpsndend-&jumpsnd, &jumpsnd, &Jump);
	
	// Copy tiles to VRAM
	bgInitTileSet(1, &pic_1_1_map, &pal_1_1_map, 0, size_pic_1_1_map, 16*2, BG_16COLORS, 0x2000);
	bgInitTileSet(0, &pic_large_villain, &pal_1_1_map, 0, size_pic_large_villain, 16*2, BG_16COLORS, 0x0000);
	

	// Init Sprites gfx and palette with default size of 16x16
	oamInitGfxSet(
		&pic_spike_character_x32,
		size_pic_spike_character_x32,
		&pal_spike_character_x32,
		32*2, 0, 0x4000, OBJ_SIZE32_L64);

	// Init Map to address 0x1000 and Copy Map to VRAM
	
	bgSetMapPtr(1, BG_2_ADDR, SC_64x32);
	// For each of the rows on the (64 x 32) background.
	// for (i = 0; i < 31; i++) { // 128 pixel height -> 128/8 = 16 2400 / 8 = 300
	// 	u8 *ptrMap  = &map_1_1_map + i;
	// 	u16 ptrVRAM = BG_2_ADDR + i * 32;
	// 	dmaCopyVram(ptrMap, ptrVRAM, 32*2);
	// }
	



	// Init Map to address 0x1000 and Copy Map to VRAM
	bgSetMapPtr(1, BG_2_ADDR, SC_64x32);
	for (i = 0; i < 31; i++) { // 128 pixel height -> 128/8 = 16 2400 / 8 = 300
		u8 tilesPerWidth = dimensions_1_1_map_x / 8;
		u8 tilesPerHeight = dimensions_1_1_map_y / 8;

		u8 *ptrMap  = &map_1_1_map + tilesPerWidth * i * 2; // 300 = map size x *2 because each entry is 16bits length
		if (i >= tilesPerHeight) ptrMap  = &map_1_1_map + tilesPerWidth * 5 * 2; // Init anything else with white line
		
		u16 ptrVRAM = BG_2_ADDR + i * 32; // screen begin to 0x1000
		dmaCopyVram(ptrMap, ptrVRAM, 32 * 2); // copy row to VRAM 
		dmaCopyVram((ptrMap+32*2), (ptrVRAM+32*32), 32*2); // copy row to VRAM 
	}






	bgSetMapPtr(0, BG_1_ADDR, SC_32x32);
	u16 line_black[]  = {
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	};
	u16 line_title[]  = {
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 'M', 'A', 'D', 1, 'P', 'I', 'E', 'R', 'R', 'O', 'T', 1, 1, 1
	};
	u16 line_transp[] = {
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	};
	// For each row on the screen (32x32)
	for (i=0;i<32;i++) { // 128 pixel height -> 128/8 = 16 2400 / 8 = 300
		if(i < 2 || i ==3 || i > 19) {
			dmaCopyVram((u8*) line_black, BG_1_ADDR + i * 32, 32*2); // Copy the black line
		} else if(i == 2) {
			dmaCopyVram((u8*) line_title, BG_1_ADDR + i * 32, 32*2); // Copy the text line
		} else {
			dmaCopyVram((u8*) line_transp, BG_1_ADDR + i * 32, 32*2); // Copy the text line
		}
	}

	// Show Mario
	mario.x = 32<<8; mario.y = 96<<8; // 128-16-16 = 96, 16 because map ground is 16 pix height, in fixed point
	mario.anim_frame = PLAYER_STANDING; mario.flipx = 0; mario.jmpval = 0;
	oamSet(0,  (mario.x>>8), (mario.y>>8), 3, mario.flipx, 0, 0, 0);  // flip x and take 5th sprite
	oamSetEx(0, OBJ_SMALL, OBJ_SHOW);
	
	// Now Put in 16 color mode and disable BG3
	setMode(BG_MODE1,0);  bgSetDisable(2);
	
	// Put some text
	// consoleDrawText(0,0,"MAD PIERROT");
	
	// Put screen on
	setScreenOn();
	
	// Play file from the beginning
	spcPlay(0);spcSetModuleVolume(100);
	
	// Wait VBL 'and update sprites too ;-) )
	WaitForVBlank();
	
    // default scroll value
    scrX=0;
	bgSetScroll(1,0,MAP_START_Y);

	// Wait for nothing :P
	while(1) {
        // no move currently
        move = 0;
        
		// Get current #0 pad
		pad0 = padsCurrent(0);
		
		// update mario regarding pad value
		moveMario();
		
		// Now, display mario with current animation
		oamSet(0,  (mario.x>>8), (mario.y>>8), 3, mario.flipx, 0, 0, 0);
		// oamSetEx(0, OBJ_LARGE, OBJ_SHOW);

		// Update sound and wait VBL
		spcProcess(); 
		WaitForVBlank();
	}
	return 0;
}
