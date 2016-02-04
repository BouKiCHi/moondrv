#include <stdio.h>

int main(int argc,char *argv[])
{
	int i;
	for(i=0; i < 0x80; i++) 
		printf(
"{sizeof(regions_%02x)/sizeof(opl4_region_t) , regions_%02x} ,\n",i,i);

	return 0;
}

