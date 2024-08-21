


// Use this to extend the instruction set with instructions that use
// two operand slots of the instruction cell (Dual Operand)
void dop_switch( void )
{
    int w;

    switch (R2) { // 16 possible instructions here

        case dop_REF:
        w = ram_ld( 1+(pc++), cfk >> 12);
        *ref(R1) = w;
        *ref(L) = ram_ld( w, cfk >> 12);
        break;

        case dop_BRA:
        pc += sxt( (L<<4)+R1, 8 ) - 1;
        break;

        case dop_SETD:
        *ref(L) = ram_ld( pc+1, cfk >> 12);
        *ref(R1) = ram_ld( pc+2, cfk >> 12);
        pc = pc + 2;
        break;

        
        case dop_PAR:
        Frames[( sfp + SFRAMESIZE + L ) & 0xFFFF] = *ref(R1);
            printf("PAR\n");
        break;

		case dop_PUSH:
			fbp++;
			TOS = *ref(L) + sxt(R1, 4);
		break;

		case dop_RET:
            RV = *ref(L) + sxt(R1, 4);
            pc = R - 1;
            cfk = CFK;
            sfp -= SFRAMESIZE;
		break;

        case dop_VM_rdv:
            RDV_switch();
        break;


        default: // printf("Unhandled DOP %04X\n", R2);
        break;
    }
}
