


void execute( cell opcode )
{
	cell tmp;
	fetches++;
	
    switch (opcode)
    {
        // Half range instructions

        case op_ZOP: zop_switch(); // Zero operand
        pc++;
        break;

        case op_SOP: sop_switch(); // Single operand
        pc++;
        break;

        case op_ELS: if (*ref(L)==0) pc += sxt( SEVEN, 7 );
        else pc++;
        break;

        case op_THN: if (*ref(L)!=0) pc += sxt( SEVEN, 7 );
        else pc++;
        break;

        case op_REP: if (--(*ref(L))) pc += sxt( SEVEN, 7 );
        else pc++;
        break;

        case op_LTL: D = (*ref(L)<SEVEN) ? 1 : 0;
        pc++;
        break;

        case op_EQL: D = (*ref(L)==SEVEN) ? 1 : 0;
        pc++;
        break;

        case op_GTL: D = (*ref(L)>SEVEN) ? 1 : 0;
        pc++;
        break;

        case op_SET: *ref(L) = (R2_LOR<<4) + R1;
        pc++;
        break;

        case op_LTR: D = (*ref(L)<(SXOFFS)) ? 1 : 0;
        pc++;
        break;

        case op_EQR: D = (*ref(L)==(SXOFFS)) ? 1 : 0;
        pc++;
        break;

        case op_GTR: D = (*ref(L)>(SXOFFS)) ? 1 : 0;
        pc++;
        break;

        case op_LOD: *ref(L) = ram_ld( OFFS, cfk >> 12);
        pc++;
        break;

        case op_STO: ram_st( OFFS, *ref(L), cfk >> 12);
        pc++;
        break;

        case op_SHL: *ref(L) = (*ref(R1) << (R2_LOR+1));
        pc++;
        break;

        case op_SHR: *ref(L) = (*ref(R1) >> (R2_LOR+1));
        pc++;
        break;

        // Full range instructions

        case op_JSR:
        case op_JSR2:
        tmp = D; // Src has TOS GET D
        sfp += SFRAMESIZE;
        CFK = cfk;
        cfk &= 0xF000; //Zero all but overlay selector
        cfk |= (iw & 0x0FFF);
        R = pc + 2;
        pc = ram_ld( pc + 1, cfk >> 12);
        if (!pc) pc = tmp;
        break;

        case op_DOP:  // Dual operand
        case op_DOP2: dop_switch();
        pc++;
        break;

        case op_GET:
        case op_GET2: *ref(L) = *ref(R1) + sxt(R2,4);
        pc++;
        break;

        case op_AND:
        case op_AND2: *ref(L) = *ref(R2) & *ref(R1);
        pc++;
        break;

        case op_IOR:
        case op_IOR2: *ref(L) = *ref(R2) | *ref(R1);
        pc++;
        break;

        case op_EOR:
        case op_EOR2: *ref(L) = *ref(R2) ^ *ref(R1);
        pc++;
        break;

        case op_ADD:
        case op_ADD2: *ref(L) = *ref(R2) + *ref(R1);
        if (L != 8) D = carry(*ref(R2), *ref(R1));
        pc++;
        break;

        case op_SUB:
        case op_SUB2: tmp = (*ref(R1)^0xFFFF)+1;
        *ref(L) = *ref(R2) + tmp;
        if (L != 8) D = carry( *ref(R2), tmp );
        pc++;
        break;
    }
}



int run( void)  // VM_End can have values >FFFFh
{
    VM_End = 0;
    
    while (!VM_End)
    {
        iw = ram_ld( pc, cfk >> 12); // Fetch instruction cell

        // Decode instruction

        G = (iw & 0xF000) >> 12; // Slot 0 - Guide code
        L = (iw & 0xF00) >> 8;   // Slot 1 - Left operand
        R2 = (iw & 0xF0) >> 4;   // Slot 2 - First right operand
        R2_MSB = (R2 & 8) >> 3;  // Slot 2 - Most significant bit
        R2_LOR = R2 & 7;         // Slot 3 - Remaining three bits
        R1 = iw & 0xF;           // Slot 3 - Second right operand

        SEVEN = (R2_LOR<<4) + R1;
        OFFS = R2_LOR + *ref(R1);
        SXOFFS = sxt(R2_LOR,3) + *ref(R1);

        execute( opcode = (G<<1) | R2_MSB ); // Execute instruction
    
        if (fetches == MAX_CYCLES) VM_End = RDV_SIG_Timeout;
    }

    return VM_End;
}



