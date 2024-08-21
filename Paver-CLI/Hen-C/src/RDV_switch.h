


/* This is called from within the dop_VM_rdv instruction handler
   The purpose is to facilitate passing blocks of data between
   Hen and VM
*/

void
RDV_switch( void)  // Use L, R1 and E/RV   Chickbuf = (BLOCK)PUMP
{
		int i,j;
		cell p;

		switch (RV)
		{
			    case RDV_VM_Finished:
			    		VM_End = RV;
			    		break;

				case RDV_VM_NeedsStr16:
						if (! RDVCounter) {
							//printf( "[Waiting for input]\n");
							pc -= 1;
							VM_End = RDV_VM_NeedsStr16;
						}
						else {
							p = *ref(L);
							for (i=0; i < RDVCounter; i++) {
								if (i > *ref(R1)) break;
								ram_st( p++, RDVPtr[i], cfk >> 12);
							}
							RDVCounter = 0;
							RV = 0;
						}
						break;

				case RDV_VM_ReadsRDVBuf:
						p = *ref(L);
						for (i=0; i < *ref(R1); i++) {
							if (i>255) break;
							ram_st( p++, RDVBuf[i], cfk >> 12);
						}
						break;

				case RDV_VM_PullsBlock:
						p = *ref(L);
						*ref(R1) = (RDVCounter > 255) ? 256 : RDVCounter;
						for (i=0; i < *ref(R1); i++) {
								ram_st( p++, htons(*RDVPtr), cfk >>12);
								RDVCounter--;
								RDVPtr++;
						}
						RV = *ref(R1);
						break;

				case RDV_VM_PushesBlk:
						if (RDVCounter > 0) {
							i = *ref(L);  // gp_ramld buffer
							j = *ref(R1); // number of data cells
							//printf( "Got %d\n", j);
							for (int k=0; k < j; k++) {
							 	*(RDVPtr++) = ram_ld( i+k, cfk >>12);
								RDVCounter--;
							}
						}
						break;
		} 
}


