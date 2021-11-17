.include hdr.asm

.section .rodata1 superfree

pic_spike_character_x32: .incbin "sprites/spike_character_x32.pic"
pic_spike_character_x32_end:
pal_spike_character_x32: .incbin "sprites/spike_character_x32.pal"
pal_spike_character_x32_end:

map_1_1_map: .incbin "maps/1_1_map.map"
map_1_1_map_end:
pal_1_1_map: .incbin "maps/1_1_map.pal"
pal_1_1_map_end:
pic_1_1_map: .incbin "maps/1_1_map.pic"
pic_1_1_map_end:

pic_large_villain: .incbin "fonts/large_villain.pic"
pic_large_villain_end:
.ends

.section .rodata2 superfree
jumpsnd: .incbin mariojump.brr
jumpsndend:

col_1_1_map: .incbin "maps/1_1_map_col.clm"
col_1_1_map_end:
.ends

