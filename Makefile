ifeq ($(strip $(PVSNESLIB_HOME)),)
$(error "Please create an environment variable PVSNESLIB_HOME with path to its folder and restart application. (you can do it on windows with <setx PVSNESLIB_HOME "/c/snesdev">)")
endif

# BEFORE including snes_rules :
# list in AUDIOFILES all your .it files in the right order. It will build to generate soundbank file
AUDIOFILES := overworld.it
# then define the path to generate soundbank data. The name can be different but do not forget to update your include in .c file !
export SOUNDBANK := soundbank

include ${PVSNESLIB_HOME}/devkitsnes/snes_rules

.PHONY: all
 
#---------------------------------------------------------------------------------
# ROMNAME is used in snes_rules file
export ROMNAME := bebop

# to build musics, define SMCONVFLAGS with parameters you want
SMCONVFLAGS	:= -s -o $(SOUNDBANK) -v -b 5
musics: $(SOUNDBANK).obj

png_sprites_x32 := $(wildcard sprites/*_x32.png)
pic_sprites_x32 := $(patsubst %.png,%.pic,$(wildcard sprites/*_x32.png))
asm_sprites_x32 := $(patsubst %.png,bin/%.asm.tmp,$(wildcard sprites/*_x32.png))
base_sprites_x32 := $(basename $(wildcard sprites/*_x32.png))

png_maps := $(wildcard maps/*_map.png)
clm_maps := $(patsubst %.png,%_col.clm,$(png_maps))
map_maps := $(patsubst %.png,%.map,$(png_maps))
asm_maps := $(patsubst %.png,bin/%.asm.tmp,$(png_maps))
pic_maps := $(patsubst %.png,%.pic,$(png_maps))
base_maps := $(basename $(png_maps))

png_fonts := $(wildcard fonts/*.png)
pic_fonts :=  $(patsubst %.png,%.pic,$(png_fonts))
asm_fonts := $(patsubst %.png,bin/%.asm.tmp,$(png_fonts))

all: data.asm musics mariojump.brr bitmaps $(ROMNAME).sfc

clean: cleanBuildRes cleanRom cleanGfx cleanAudio
	rm -f *.clm mariojump.brr
	rm -f sprites/*.pic sprites/*.pal sprites/*.asm sprites/*.tmp
	rm -f maps/*.pic maps/*.pal maps/*.clm maps/*.asm maps/*.tmp
	rm -f fonts/*.pic fonts/*.pal fonts/*.map fonts/*.asm fonts/*.tmp
	rm -f data.asm data/*.tmp *.tmp
	rm -f *.sfc
	rm -f *.sym
	rm -f .wla*
	rm -f .wla*
	rm -rf bin/
		
#---------------------------------------------------------------------------------

# Build bitmaps
bin/_pre_sprites.tmp: 
	mkdir -p bin/data/
	echo "" > bin/data/sprites.asm.tmp
	echo "#ifndef SPRITES_H" > data/sprites.h
	echo "#define SPRITES_H" >> data/sprites.h
	touch $@
bin/_post_sprites.tmp: 
	mkdir -p bin/
	echo "#endif // SPRITES_H" >> data/sprites.h
	touch $@
bin/data/sprites.asm.tmp: bin/_pre_sprites.tmp $(asm_sprites_x32) bin/_post_sprites.tmp
	mkdir -p bin/data/
	touch $@
bin/sprites/%_x32.asm.tmp:
	mkdir -p bin/sprites/
	mkdir -p bin/data/
	echo "pic_$(notdir $(basename $(basename $@))): .incbin \"$(patsubst bin/%,%,$(basename $(basename $@))).pic\"" >> bin/data/sprites.asm.tmp
	echo "pic_$(notdir $(basename $(basename $@)))_end:" >> bin/data/sprites.asm.tmp
	echo "pal_$(notdir $(basename $(basename $@))): .incbin \"$(patsubst bin/%,%,$(basename $(basename $@))).pal\"" >> bin/data/sprites.asm.tmp
	echo "pal_$(notdir $(basename $(basename $@)))_end:" >> bin/data/sprites.asm.tmp

	echo "extern char pic_$(notdir $(basename $(basename $@))), pic_$(notdir $(basename $(basename $@)))_end;" >> data/sprites.h
	echo "extern char pal_$(notdir $(basename $(basename $@))), pal_$(notdir $(basename $(basename $@)))_end;" >> data/sprites.h
	echo "#define size_pic_$(notdir $(basename $(basename $@))) (&pic_$(notdir $(basename $(basename $@)))_end-&pic_$(notdir $(basename $(basename $@))))" >> data/sprites.h
	echo "#define size_pal_$(notdir $(basename $(basename $@))) (&pal_$(notdir $(basename $(basename $@)))_end-&pal_$(notdir $(basename $(basename $@))))" >> data/sprites.h
	file $(patsubst bin/%,%,$(basename $(basename $@))).png | awk 'match($$0, /([0-9]+) x ([0-9]+)/, a) { print "#define dimensions_$(notdir $(basename $(basename $@)))_x " a[1] }' >> data/sprites.h
	file $(patsubst bin/%,%,$(basename $(basename $@))).png | awk 'match($$0, /([0-9]+) x ([0-9]+)/, a) { print "#define dimensions_$(notdir $(basename $(basename $@)))_y " a[2] }' >> data/sprites.h
	touch $@

sprites: $(pic_sprites_x32) data.asm
%_x32.pic: $(wildcard sprites/*_x32.png)
	@echo convert sprites ... $(notdir $@)
	$(GFXCONV) -gs32 -pc32 -po32 -fpng -n $(basename $(basename $@)).png

# Build Maps
bin/_pre_maps.tmp: 
	mkdir -p bin/data/
	echo "" > bin/data/maps.asm.tmp
	echo "" > bin/data/maps_clm.asm.tmp
	echo "#ifndef MAPS_H" > data/maps.h
	echo "#define MAPS_H" >> data/maps.h
	touch $@
bin/_post_maps.tmp: 
	mkdir -p bin/
	echo "#endif // MAPS_H" >> data/maps.h
	touch $@
bin/data/maps.asm.tmp: bin/_pre_maps.tmp $(asm_maps) bin/_post_maps.tmp
	mkdir -p bin/data/
	touch $@
bin/maps/%_map.asm.tmp:
	mkdir -p bin/maps/
	mkdir -p bin/data/
	echo "map_$(notdir $(basename $(basename $@))): .incbin \"$(patsubst bin/%,%,$(basename $(basename $@))).map\"" >> bin/data/maps.asm.tmp
	echo "map_$(notdir $(basename $(basename $@)))_end:" >> bin/data/maps.asm.tmp
	echo "pal_$(notdir $(basename $(basename $@))): .incbin \"$(patsubst bin/%,%,$(basename $(basename $@))).pal\"" >> bin/data/maps.asm.tmp
	echo "pal_$(notdir $(basename $(basename $@)))_end:" >> bin/data/maps.asm.tmp
	echo "pic_$(notdir $(basename $(basename $@))): .incbin \"$(patsubst bin/%,%,$(basename $(basename $@))).pic\"" >> bin/data/maps.asm.tmp
	echo "pic_$(notdir $(basename $(basename $@)))_end:" >> bin/data/maps.asm.tmp

	echo "col_$(notdir $(basename $(basename $@))): .incbin \"$(patsubst bin/%,%,$(basename $(basename $@)))_col.clm\"" >> bin/data/maps_clm.asm.tmp
	echo "col_$(notdir $(basename $(basename $@)))_end:" >> bin/data/maps_clm.asm.tmp

	echo "extern char map_$(notdir $(basename $(basename $@))), map_$(notdir $(basename $(basename $@)))_end;" >> data/maps.h
	echo "extern char pic_$(notdir $(basename $(basename $@))), pic_$(notdir $(basename $(basename $@)))_end;" >> data/maps.h
	echo "extern char pal_$(notdir $(basename $(basename $@))), pal_$(notdir $(basename $(basename $@)))_end;" >> data/maps.h
	echo "extern char col_$(notdir $(basename $(basename $@))), col_$(notdir $(basename $(basename $@)))_end;" >> data/maps.h

	echo "#define size_pic_$(notdir $(basename $(basename $@))) (&pic_$(notdir $(basename $(basename $@)))_end-&pic_$(notdir $(basename $(basename $@))))" >> data/maps.h
	echo "#define size_pal_$(notdir $(basename $(basename $@))) (&pal_$(notdir $(basename $(basename $@)))_end-&pal_$(notdir $(basename $(basename $@))))" >> data/maps.h
	echo "#define size_map_$(notdir $(basename $(basename $@))) (&map_$(notdir $(basename $(basename $@)))_end-&map_$(notdir $(basename $(basename $@))))" >> data/maps.h
	echo "#define size_col_$(notdir $(basename $(basename $@))) (&col_$(notdir $(basename $(basename $@)))_end-&col_$(notdir $(basename $(basename $@))))" >> data/maps.h
	file $(patsubst bin/%,%,$(basename $(basename $@))).png | awk 'match($$0, /([0-9]+) x ([0-9]+)/, a) { print "#define dimensions_$(notdir $(basename $(basename $@)))_x " a[1] }' >> data/maps.h
	file $(patsubst bin/%,%,$(basename $(basename $@))).png | awk 'match($$0, /([0-9]+) x ([0-9]+)/, a) { print "#define dimensions_$(notdir $(basename $(basename $@)))_y " a[2] }' >> data/maps.h
	touch $@

maps: $(clm_maps) $(pic_maps) data.asm
%_map.pic: $(png_maps)
	@echo convert png map ... $(notdir $<)
	$(GFXCONV) -pr -pc16 -n -gs8 -pe0 -fpng -m $(basename $(basename $@)).png
%_map_col.clm: $(png_maps)
	@echo convert collision map ... $(notdir $@)
	$(GFXCONV) -pr -pc16 -n -gs8 -fpng -mc $(basename $(basename $@)).png

# Build Fonts
bin/_pre_fonts.tmp: 
	mkdir -p bin/data/
	echo "" > bin/data/fonts.asm.tmp
	echo "#ifndef FONTS_H" > data/fonts.h
	echo "#define FONTS_H" >> data/fonts.h
	touch $@
bin/_post_fonts.tmp: 
	mkdir -p bin/
	echo "#endif // FONTS_H" >> data/fonts.h
	touch $@
bin/data/fonts.asm.tmp: bin/_pre_fonts.tmp $(asm_fonts) bin/_post_fonts.tmp
	mkdir -p bin/data/
	touch $@
bin/fonts/%.asm.tmp:
	mkdir -p bin/fonts/
	mkdir -p bin/data/
	echo "pic_$(notdir $(basename $(basename $@))): .incbin \"$(patsubst bin/%,%,$(basename $(basename $@))).pic\"" >> bin/data/fonts.asm.tmp
	echo "pic_$(notdir $(basename $(basename $@)))_end:" >> bin/data/fonts.asm.tmp

	echo "extern char pic_$(notdir $(basename $(basename $@))), pic_$(notdir $(basename $(basename $@)))_end;" >> data/fonts.h

	echo "#define size_pic_$(notdir $(basename $(basename $@))) (&pic_$(notdir $(basename $(basename $@)))_end-&pic_$(notdir $(basename $(basename $@))))" >> data/fonts.h
	file $(patsubst bin/%,%,$(basename $(basename $@))).png | awk 'match($$0, /([0-9]+) x ([0-9]+)/, a) { print "#define dimensions_$(notdir $(basename $(basename $@)))_x " a[1] }' >> data/fonts.h
	file $(patsubst bin/%,%,$(basename $(basename $@))).png | awk 'match($$0, /([0-9]+) x ([0-9]+)/, a) { print "#define dimensions_$(notdir $(basename $(basename $@)))_y " a[2] }' >> data/fonts.h

	touch $@
fonts: $(pic_fonts) data.asm
fonts/%.pic: fonts/%.png
	@echo convert font with no tile reduction ... $(notdir $@)
	$(GFXCONV) -pc16 -n -gs8 -po2 -pe1 -fpng -mR! -m $<

# Combine all the data.
data.asm: bin/data/sprites.asm.tmp bin/data/maps.asm.tmp bin/data/fonts.asm.tmp
	echo .include "hdr.asm" > data.asm
	echo >> data.asm
	echo .section ".rodata1" superfree >> data.asm
	cat bin/data/sprites.asm.tmp >> data.asm
	cat bin/data/maps.asm.tmp >> data.asm
	cat bin/data/fonts.asm.tmp >> data.asm

	echo .ends >> data.asm
	echo >> data.asm
	echo .section ".rodata2" superfree >> data.asm
	echo jumpsnd: .incbin "mariojump.brr" >> data.asm
	echo jumpsndend: >> data.asm
	cat bin/data/maps_clm.asm.tmp >> data.asm
	echo .ends >> data.asm
	echo >> data.asm

	
bitmaps: sprites maps fonts data.asm

run: musics mariojump.brr bitmaps $(ROMNAME).sfc
	../../../emulators/bsnesplus/bsnes.exe $(ROMNAME).sfc
