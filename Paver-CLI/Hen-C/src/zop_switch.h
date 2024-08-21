




// Use this to extend the instruction set with instructions that do not
// use any operand slot of the instruction cell (Zero Operand)
void zop_switch( void )
{
    cell u;

    switch ((L<<4)+R1) // 127*16 possible instructions here
    {
        case zop_INIT:
		//	sfp = FRAMES_MAX_ADDR - SFRAMESIZE;
		//	cfk = 0;
		//	pc = 0;
        break;

		case zop_NOP:  break;

		case zop_LIT:
			fbp++;
			TOS = ram_ld(1 + (pc++), cfk >> 12);
		break;

        case zop_NEXT:
        W = ram_ld( R++, cfk >> 12);
        pc = W - 1;
        break;

        case zop_JUMP:
        pc = ram_ld( pc+1, cfk >> 12) - 1;
        break;

		case zop_SOFT:
			// sfp = FRAMES_MAX_ADDR - SFRAMESIZE;
			break;

        case zop_VM_IDLE:
        break;

        default: // printf("Unhandled ZOP %04X\n", (L<<4)+R1);
        break;
    }
}


