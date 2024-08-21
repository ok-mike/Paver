

/*
* Read n contiguous 512-byte-blocks from sdcard image into a buffer
* Each block 256 cells, network byte order
*/
int
rd_blk_range( int bstart, int blocks, cell *buffer)
{
	cell w;
	fseek( volFP, 512 * bstart, SEEK_SET);
	for (size_t i = 0; i < 256 * blocks; i++) {
		fread( &w, 2, 1, volFP);
		buffer[ i] = ntohs( w);
	}
	return 0;
}




/*
* Write n contiguous 512-byte-blocks from a buffer to the sdcard image
* Each block 256 cells, network byte order
*/
int
wr_blk_range( int bstart, int blocks, cell *buffer)
{
	cell w;
	fseek( volFP, 512 * bstart, SEEK_SET);
	for (size_t i = 0; i < 256 * blocks; i++) {
		w = htons( buffer[ i]);
		fwrite( &w, 2, 1, volFP);
	}
	fflush( volFP);
	return 0;
}




/*
* Read a block from sdcard into a buffer, then transfer to gp_ram
* Address is 16-bit only, bank switching
*/
void
rd_blk_into_ram( int srcblk, cell dstaddr, int ovl)
{
	srcblk += VOL_PHYS_BLOCK;
	
	ovl &= 0b1111;
	if (srcblk > 65535) {
		printf( "VM tries to read file block >64k\n");
		exit(0);
	}
	cell buffer[256];
	rd_blk_range( srcblk, 1, buffer);
	for (int i = 0; i < 256; i++)
		ram_st( (cell) (dstaddr + i), buffer[i], ovl);
}




/*
* Write a block from gp_ram to sdcard
* Address is 16-bit only, bank switching
*/
void
wr_ram_into_blk( int dstblk, cell srcaddr, int ovl)
{
  	dstblk += VOL_PHYS_BLOCK;

	ovl &= 0b1111;
	if (dstblk > 65535) {
		printf( "VM tries to read file block >64k\n");
		exit(0);
	}
	cell buffer[256];
	for (int i = 0; i < 256; i++)
		buffer[i] = ram_ld( (cell) (srcaddr + i), ovl);
	wr_blk_range( dstblk, 1, buffer);
}