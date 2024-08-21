
cell
getTeaHead( void)
{
	cell head;
	cell bl;
		for (int i =0; i <RAM_MAX_ADDR -2; i++)
				if (ram_ld( i, 0) ==0xACED) {
 						head = ram_ld( i +1, 0);
 						break;
				}
	
	      // bl = ram_ld( head, 0);
	      // printf( "Last backlink: %04X\n", bl);
       	  // for (int i=head; i>head-10; i--)
          // printf( "%04X: %04X\n", i, ram_ld( i, 0));
        
        return head;
}



cell
findTeaFunc( char *nameStr, cell funcId)
{
		cell head = getTeaHead();
		cell entryType;
		cell backLink = head;
		
		if (!head) return 0;
		else head += ram_ld( head, 0); // Skip to first entry

		for (;;) {

				backLink = ram_ld( head, 0);
				if (!backLink) break;

				entryType = ram_ld( head + 1, 0);

				if (entryType == TEA_RUNNABLE)
						if (strEql16( head + 3, nameStr))
								return head + 2 + ram_ld( head + 2, 0);
				
				if (entryType == TEA_RDV)
						if (ram_ld( head + 3, 0) == funcId)
								return head + 2 + ram_ld( head + 2, 0);

				head += backLink;
		}
		return 0;
}




cell
tea( char *nameStr, cell funcID, cell par)
{
		cell r = 0;
		cell teaFunc = findTeaFunc( nameStr, funcID);
		if (!teaFunc) {
				printf( "No tea\n");
   		}
   		else {
   			pc = teaFunc;
   			RV = par;
   			run();
   			r = RV;
   		}
   		return r;
}


