


int
hTea( char *a1, char *a2)
{
	xferKernel();
	tea( a1, 0, 0);
	return 0;
}



int
hVerbose( char *a1, char *a2)
{
	mute_threshold = -10;
	return 0;
}



int
hForce( char *a1, char *a2)
{
	force = 1;
	return 0;
}



int
hExport( char *localpath, char *pfspath)
{
		cell *fdata;
		cell word;
		int fsize, count;

  		xferKernel();

	    fdata = calloc( 0x4FFFF, 2);
		readPFSFile( pfspath, fdata, 0x4FFFF);

	    FILE *flocal = fopen( localpath, "w+");
	    if (!flocal) printf("NULL\n");

	    fsize = 0x4FFFF - RDVCounter;
	    printf( "Exporting '%s': %d cells\n", localpath, fsize);

	    for (int i=0; i<fsize; i++) {
	    		word = htons( fdata[i]);
	    		fwrite( &word, 1, 2, flocal);
	    }
		fclose( flocal);
		return 0;
}



int
hImport( char *localpath, char *pfspath)
{
		// basename(fName)

		cell *fdata;
		cell word;
		int fsize, count;

  		xferKernel();

	    FILE *flocal = fopen( localpath, "r+");
	    if (!flocal) printf("NULL\n");
	    fdata = calloc( 0x4FFFF, 2);
	    
	    fsize = 0;
	    for (;;) {
			    count = fread( &word, 1, 2, flocal);
		    	if (!count) break;
		    	fdata[fsize++] = word; 
		}

	    printf( "Importing '%s': %d cells\n", localpath, fsize);

		writePFSFile( pfspath, fdata, fsize);
		
		fclose ( flocal);
		return 0;
}



int
hNew( char *arg1, char *arg2)
{
		int i;

        for (i=0; i < RAM_MAX_ADDR; i++) Ram[ i] = 0;
        for (i=0; i < FRAMES_MAX_ADDR; i++) Frames[ i] = 0;

        pc = 0;
        sfp = SFRAMESIZE;
        fbp = 6;
        cfk = 0;
        
        xferKernel();
        night();

        return 0;
}



struct {
	char *mnemonic;
	cell value;
} dotcode[] = {
	
	{".SP", 32},      // Space
	{".AT", 64},      // @ sign
	{".AMP", 38},     // & sign
	{".TAB", 9},      // TAB

	{".NULL", 0},     // NULL
	{".STAR", 42},    // Asterisk
	{".STAR", 43},    // Plus	
	{".BANG", 33},    // Exclamation mark

	{".FSL", 47},     // Forward slash
	{".BSL", 92},     // Backward slash

	{".LT", 60},      // Less-than sign
	{".EQ", 61},      // Equal sign
	{".GT", 62},      // Greater-than sign

	{".COLON", 58},   // Colon
	{".SEMI", 59},    // Semicolon

	{".SQ", 39},      // Single quote
	{".DQ", 34},      // Double quote

	{".ESC", 27},     // Escape
	{".PIPE", 124},   // Pipe	
	{".TILDE", 126},  // Tilde
	{".PERC", 37},    // Percent sign	
	{".DOLLAR", 36},  // Dollar sign

	{".FT", 44},      // Forward tick
	{".BT", 96},      // Backward tick
	{".US", 95},      // Underscore
	{".CT", 94},      // Caret
	{".QM", 63},      // Question mark

	{".SO", 91}, {".SC", 93},
	{".CO", 123}, {".CC", 125},
	{".RO", 40}, {".RC", 41},

	{"", 0}
};



void
substDotCodes( int k)
{
		int i=0, idot=0, j, l, ch;
		char *s;
		
		for (;;)
		{
				if (idot >= CSTRBUFSIZE) break;

				ch = cStrBuffer[ i];
				if (ch == '.')
				{		
						j = 0;
						for (;;) {
								s = dotcode[ j].mnemonic;
								l = strlen( s);
								if (l == 0) break;
								if (!strncmp( s, &cStrBuffer[i], l)) {
										ch = dotcode[j].value;
										i += l-1;
										break;
								}
								j++;
						}
				}

				RDVBuf[ idot] = ch;
				i++;
				idot++;
		}

		RDVCounter = idot;
		RDVPtr = RDVBuf;
}



void
greet( void)
{
		snprintf( cStrBuffer, CSTRBUFSIZE,
		 		"Paver Hen / Sonne-16 emulation tool\n" 		\
				"Copyright 2015-2020 by Michael Mangelsdorf"	\
				" (mim@ok-schalter.de)\n"						\
				"CC0 Public Domain -"							\
				" Use for any purpose, no warranties");
		cluck( 10);
}



struct
{
	char *name;
	int requargs;
	int (*handler)( char*, char*);
	char *desc;
	char *format;
	int contflag;

} Options[] = {

	{"-export", 2, hExport,
	 "Export a file from PFS volume",
	 "[path/fname] [pfspath/pfsfname]", 0},

	{"-import", 2, hImport,
	 "Import a file to PFS volume",
	 "[path/fname] [pfspath/pfsfname]", 0},
	
	{"-new", 0, hNew,
	 "Reset Life to PFS kernel",
	 "", 0},
	
	{"-verbose", 0, hVerbose,
	 "Enable verbose comments",
	 "", 1},
	
	{"-f", 0, hForce,
	 "Continue on timeout",
	 "", 1},
	
	{"-tea", 1, hTea,
	 "Try forcing Life to execute a tea",
	 "[tea name]", 0},
	
	{"", 0, NULL, ""}
};



void
showUsage( void)
{
		for (int i=0;;i++) {
				if (Options[ i].handler == NULL) break;
				printf( "%s:\n", Options[ i].desc);
				printf( "\then %s", Options[ i].name);
				printf( " %s\n\n", Options[ i].format);
		}
		printf( "Run/continue Life:\n");		
		printf( "\then [any text input, or hyphen only for no text]\n\n");
}


int
main( int argc, char* argv[])
{
		int i, j, k, pos, r;
		char *a1, *a2;

		volFP = openVolumeFileOrDie();
        
		if (argc < 2) {
				greet();
				showUsage();
				exit( 0);
		}

		pos = 0;
		for (;;)
		{
				if (++pos == argc) break;
				if (strlen( argv[ pos]) == 0) continue; 

				if (argv[ pos][ 0] == '-')
				{
					if (strlen( argv[ pos]) == 1) goto TEA; 
					for (int j=0;;j++)
						{
						
						if (Options[ j].handler == NULL) {
								snprintf( cStrBuffer, CSTRBUFSIZE,
										"Unknown command '%s'", argv[ pos]);
								cluck( 100);
								break;
						}
						else
						if (!strcmp( Options[ j].name, argv[ pos]))
						{
								if (pos + Options[ j].requargs < argc) { 
										
					a1 = (Options[ j].requargs > 0) ? argv[ pos + 1] : NULL;
					a2 = (Options[ j].requargs > 1) ? argv[ pos + 2] : NULL;

										r = (*Options[ j].handler)( a1, a2);
										pos += Options[ j].requargs + 1; 
										if (!Options[ j].contflag) exit(0);
										else goto TEA;
								}
								else {
									snprintf( cStrBuffer, CSTRBUFSIZE,
											"Missing argument(s) " \
											"for option %s", Options[ j].name);
									cluck(10);
									break;
								}
						}
					}
				}
				else break;
		}

	TEA:

        /* Remaining parameters are Tea parameters for VM
		   Create a single string out of them
		*/

		k = 0;
		for (i=pos; i<argc; i++)
		{
				for(j=0; j < strlen( argv[i]); j++) {
						if (k == BYTES_PER_BLOCK) break;
						cStrBuffer[ k++] = argv[ i][ j];
				}
				cStrBuffer[ k++] = 32;
		}
		if (k) cStrBuffer[ k - 1] = 0;	
		
		substDotCodes( k); // Number of cells, not max index

		//for (i=0;i<k;i++) printf( "%04X ",cStrBuffer[i]);
		//printf("  k=%d\n",k);

		day();
		for (;;) {
				r = run();
				if (!force) {
						if (r == RDV_SIG_Timeout) {
							snprintf( cStrBuffer, CSTRBUFSIZE, 
									"Life elapsed after 83M cycles\n" \
									"Re-run to continue or use -f option");
							cluck( 10);
						}
						break;
				}
				else if (r != RDV_SIG_Timeout) break;
		}

   		snprintf( cStrBuffer, CSTRBUFSIZE,
	    		"Fetched %d", fetches);
   		cluck( -10);


		night();
		fclose( volFP);
}



