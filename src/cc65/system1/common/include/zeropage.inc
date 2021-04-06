.globalzp sp
.globalzp sreg
.globalzp regsave

.globalzp tmp1
.globalzp tmp2
.globalzp tmp3
.globalzp tmp4
.globalzp tmp5
.globalzp ptr1
.globalzp ptr2
.globalzp ptr3
.globalzp ptr4

.globalzp console_out_ptr
.globalzp lcd_out_ptr

.globalzp zp_sd_address
.globalzp zp_sd_currentsector
.globalzp fat32_fatstart
.globalzp fat32_datastart
.globalzp fat32_rootcluster
.globalzp fat32_sectorspercluster
.globalzp fat32_pendingsectors
.globalzp fat32_address
.globalzp fat32_nextcluster
.globalzp fat32_bytesremaining
.globalzp fat32_errorstage
.globalzp fat32_filenamepointer


.globalzp DPL
.globalzp DPH

.globalzp lcd_enable_pins
.globalzp lcd_row
.globalzp lcd_column

.globalzp controller1
.globalzp controller2

.globalzp spi_sr
.globalzp read_blkptr, write_blkptr
.globalzp sd_tmp

.globalzp __volatile_ptr



lba_addr 		= $0280		; 4 bytes
blocks			= $0284		; 3 bytes blocks to read, 3 bytes sufficient to address 4GB -> 4294967296 >> 9 = 8388608 ($800000) max blocks/file


;----------------------------------------------------------------------------
; last known timestamp with date set to 1970-01-01
rtc_systime_t = $0300




;----------------------------------------------------------------------------
; time struct with date set to 1970-01-01
.struct time_t
		  tm_sec	.byte		;0-59
		  tm_min	.byte		;0-59
		  tm_hour	.byte		;0-23
		  tm_mday	.byte		;1-31
		  tm_mon	.byte	;1	;0-11 0-jan, 11-dec
		  tm_year	.byte  ;70	;years since 1900
		  tm_wday	.byte		;
 ;		 tm_yday
  ;		tm_isdst
.endstruct
