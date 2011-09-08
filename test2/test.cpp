// test.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "conio.h"

//http://groups.google.com/group/microsoft.public.dotnet.languages.vc/browse_thread/thread/da84804aa3f0eb71/1c3f225d1b494709?lnk=st&q=vc7+try+catch&rnum=2&hl=en#1c3f225d1b494709

void crash(void){
	_asm{
		mov eax, 0
		mov [eax],eax 
	}
}

int _tmain(int argc, char* argv[])
{
	
	char buf[10];
	int i = 0;

	for(i=0;i<3;i++){
		printf("I is now: %d\n", i);
	}

	__try{
		crash();
	}
	__except(1){
		printf("Caught crash internally\n");
	}
	
	if(argc>1){
		printf("At exploitable call\n");
		strcpy(buf,argv[1]);
		printf("Press any key to continue...");	
		getch();
	}

	return 0;
}

