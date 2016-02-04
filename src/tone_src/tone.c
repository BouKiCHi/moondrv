#include <stdio.h>

#include "yrw801.c"

typedef struct 
{
	const int len;
	const opl4_region_t *region;
} opl4_regmap_t;

const opl4_regmap_t tonemap[]=
{
 #include "map.h"
 {sizeof(regions_drums)/sizeof(opl4_region_t) , regions_drums} 
};



int main(int argc,char *argv[])
{
	int i;
	int tone;

	if (argc < 2)
	{
	printf("Usage : tone <tone number>\n");
	printf("Max tone number = %d\n",(sizeof(tonemap)/sizeof(opl4_regmap_t))-1);
	printf("128 is drum kit\n");
	return 0;
	}

	sscanf(argv[1],"%d",&tone);
	if (tone >= sizeof(tonemap)/sizeof(opl4_regmap_t))
	{
		printf("Error : too big tone number\n");
	}


	printf("; tone=%d\n",tone);
	
	printf("; len = %d\n",tonemap[tone].len);

	
	for(i=0; i < tonemap[tone].len; i++)
	{
		printf(" $%02x,$%02x,$%04x,%d,   $%02x,$%02x,$%02x,$%02x,$%02x \n",
			tonemap[tone].region[i].key_min,
			tonemap[tone].region[i].key_max,
			tonemap[tone].region[i].sound.tone,
			tonemap[tone].region[i].sound.pitch_offset,
			
			tonemap[tone].region[i].sound.reg_lfo_vibrato,
			tonemap[tone].region[i].sound.reg_attack_decay1,
			tonemap[tone].region[i].sound.reg_level_decay2,
			tonemap[tone].region[i].sound.reg_release_correction,
			tonemap[tone].region[i].sound.reg_tremolo
		);
	}
	
	return 0;
}
