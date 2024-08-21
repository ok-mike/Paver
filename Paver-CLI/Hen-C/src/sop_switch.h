


// Use this to extend the instruction set with instructions that use
// one operand slot of the instruction cell (Single Operand)
void sop_switch( void )
{
    size_t large_n;
    int i;
    cell u;

    switch (SEVEN) { // 127 possible instructions here

        case sop_VM_gets:
                // *ref(L) = 0;
        break;

        case sop_VM_ready:
            VM_End = *ref(L);
        break;

        case sop_VM_exit:
	        printf ("Caught VM_exit L=%04X PC=%04X\n", *ref(L), pc);
    	    VM_End = RDV_VM_Finished;
            exit(0);
		break;

        case sop_VM_rdblk: // Block number in A1, buffer ptr in A2
        	*ref(L) = 0; // Signal back that VM handles this
			rd_blk_into_ram( *ref(4), *ref(5), cfk >> 12);
        	*ref(5)+=256;
        break;

        case sop_VM_wrblk: // Block number in A1, buffer ptr in A2
        	*ref(L) = 0;
        	wr_ram_into_blk( *ref(4), *ref(5), cfk >> 12);
        	*ref(5)+=256;
        break;

        case sop_PER:
        	ram_st( ram_ld( 1+(pc++), cfk >> 12), *ref(L), cfk >> 12);
        break;

        case
        	sop_W_get: *ref(L) = W;
        break;

        case
        	sop_SETL: *ref(L) = ram_ld( 1+(pc++), cfk >> 12);
        break;

       	case sop_CYCLES:
			*ref(L) = fetches & 0xFFFF;
			D = fetches >> 16;
		break;

        case
        	sop_PC_set: pc = *ref(L) - 1;
        break;

        case
        	sop_PC_get: *ref(L) = pc;
        break;

        case sop_ASR: // Arithmetic shift right
			i = *ref(L);
			*ref(L) >>=  1;
			if (i & 0x8000) *ref(L) |= 0x8000;
        break;

        case sop_PULL: // Caller frame overlay may be different
			*ref(L) = ram_ld( R++, CFK >> 12);
        break;

        case sop_DELAY:
        break;

        case sop_MSB:
        	D = *ref(L) & 0x8000;
        break;

        case sop_LSB:
        	D = *ref(L) & 1;
        break;

        case sop_NOT:
        	D = 0xFFFF ^ *ref(L);
        break;

        case sop_NEG:
        	D = (0xFFFF ^ *ref(L)) + 1;
        break;

        case sop_BYTE:
        	D = *ref(L) & 0xFF;
        break;

        case sop_NYBL:
        	D = *ref(L) & 0xF;
        break;

        case sop_OVERLAY:
			paver_set_overlay(L);
        break;

		case sop_POP:
			*ref(L) = TOS;
			fbp--;
		break;

		case sop_DROP:
			fbp -= L;
		break;

        case sop_CORE_id:
        	*ref(L) = 1;
        break;

        case sop_LODS:
        	RV = ram_ld( (*ref(L))++, cfk >> 12);
        break;

        case sop_STOS:
        	ram_st( (*ref(L))++, RV, cfk >> 12);
        break;


        case sop_VM_HTON:
        	D = htons(*ref(L));
        break;

        case sop_VM_NTOH:
        	D = ntohs(*ref(L));
        break;

        case sop_CPU_id:
			*ref(L) = 1;
			break; // 1=Hen, 2=Paver

        case sop_VM_putc:
        	u = *ref(L) & 0xFF;
            if (u == 0x0A) printf( "\n");
            else printf( "%c", u);
            *ref(L) = 0;
            fflush(stdout);
        break;
    
        case sop_VM_prn: 
        break;
    
        case sop_VM_puts:  
		break;


        default: // printf("Unhandled SOP %d\n", SEVEN);
        break;
    }
}


