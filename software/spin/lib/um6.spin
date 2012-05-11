{{

--------------------------------------------------------------------------------
Anzhelka Project
(c) 2012

For the latest code and support, please visit:
http://code.anzhelka.com
--------------------------------------------------------------------------------

Title: CHR UM6 IMU
Author: Cody Lewis
Date: May 5, 2012

Notes: 
--- Works with the CH Robotics UM6 9DOF IMU over a serial interface.
--- Derived from FullDuplexSerialPlus, Version 1.1

CHR_UM6 Checksum is calculated by the following:
"The checksum is computed by summing the each unsigned character in the packet
and storing the result in an unsigned 16-bit integer. If your sum treats the
characters as signed, then that could generate inconsistent problems (ie.
sometimes it works, sometimes it doesn't). I don't know if this is the problem,
but it is something worth checking."



The IMU transmits the MSB first. That means that the first data byte received is B3, then B2, B1, and B0.

Note: the variables will be updated in the hub as single longs. This could be a problem for things like the quats
	where the "single" number is broken into two packets. If half is new and half is old...
	POSSIBLE SOLUTION -- Use the GET_DATA command  to retrieve the desired addresses, instead of the auto updating.
	
Note: For now, it will receive the bytes in a batch. But it really ignores them (because do I really want them?)

}}

''------------------------------------------------------------------
''--------------------[BEGIN DEBUGGER]------------------------------
''------------------------------------------------------------------

VAR
	long command
	long readptr
	long readbuf[256/4]

	long	gyro_proc_xy
	long	accel_proc_xy
	long	mag_proc_xy
	long	euler_phi_theta

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

'IO Pins
	IMU_RX_PIN = 0 'Note: direction is from Propeller IO port
	IMU_TX_PIN = 1 'Note: direction is form Propeller IO port

OBJ
	bu	: "BMAutility"
	s : "FullDuplexSingleton"
PUB main_debug
{{ Should be run when this object is being debugged. Otherwise, don't call!
}}

	waitcnt(clkfreq*1+cnt)        ' wait a second for user to start terminal
	s.start(31,30,0,230400)       ' start the default serial interface

	'Setup parameters
	add_register($5C, @gyro_proc_xy)
	add_register($5E, @accel_proc_xy)
	add_register($60, @mag_proc_xy)
	add_register($62, @euler_phi_theta)





	readptr := @readbuf

	bu.taskstart(@entry, start_debug(IMU_RX_PIN, IMU_TX_PIN, 0, 115200), string("Main Task"))
	bu.start                      ' start multi cog task debugger
	repeat


PUB start_debug(rxpin, txpin, mode, baudrate) : okay
  {{
  DEBUG VERSION - Identical, except it doesnt't start a cog, and instead returns parameter address
  
  Starts serial driver in a new cog


    rxpin - input receives signals from peripheral's TX pin
    txpin - output sends signals to peripheral's RX pin
    mode  - bits in this variable configure signaling
               bit 0 inverts rx
               bit 1 inverts tx
               bit 2 open drain/source tx
               bit 3 ignor tx echo on rx

    baudrate - bits per second
            
    okay - returns false if no cog is available.
  }}

	stop
	longfill(@rx_head, 0, 4)
	longmove(@rx_pin, @rxpin, 3)
	bit_ticks := clkfreq / baudrate
	buffer_ptr := @rx_buffer
	
'	okay := cog := cognew(@entry, @rx_head) + 1
	okay := @rx_head 'For Debugger

''------------------------------------------------------------------
''--------------------[END DEBUGGER]--------------------------------
''------------------------------------------------------------------






  
CON                                          ''
''Parallax Serial Terminal Control Character Constants
''────────────────────────────────────────────────────
  HOME     =   1                             ''HOME     =   1          
  CRSRXY   =   2                             ''CRSRXY   =   2          
  CRSRLF   =   3                             ''CRSRLF   =   3          
  CRSRRT   =   4                             ''CRSRRT   =   4          
  CRSRUP   =   5                             ''CRSRUP   =   5          
  CRSRDN   =   6                             ''CRSRDN   =   6          
  BELL     =   7                             ''BELL     =   7          
  BKSP     =   8                             ''BKSP     =   8          
  TAB      =   9                             ''TAB      =   9          
  LF       =   10                            ''LF       =   10         
  CLREOL   =   11                            ''CLREOL   =   11         
  CLRDN    =   12                            ''CLRDN    =   12         
  CR       =   13                            ''CR       =   13         
  CRSRX    =   14                            ''CRSRX    =   14         
  CRSRY    =   15                            ''CRSRY    =   15         
  CLS      =   16                            ''CLS      =   16          


VAR

	long  cog                     'cog flag/id

	long  rx_head                 '9 contiguous longs
	long  rx_tail
	long  tx_head
	long  tx_tail
	long  rx_pin
	long  tx_pin
	long  rxtx_mode
	long  bit_ticks
	long  buffer_ptr
		             
	byte  rx_buffer[16]           'transmit and receive buffers
	byte  tx_buffer[16]  


PUB add_register(register, hub_address_a)
{{ Adds a register to watch for to the current count.
	Must be called before start method.
	
	The _a subscript is to prevent name errors with the long in the PASM cog of the same name...
	
	Note: if you plan on using batch mode, you need to call this function for each address.
	You can do this with a for loop, like follows:
	TODO: insert example code
	
	
	 }}
'	return hub_address_a
	
	long[@data_register][data_count] := register
	long[@data_address][data_count] := hub_address_a
	data_count ++
	
PUB get_data_count
	return data_count
PUB get_data_address_address
	return @data_address
PUB start(rxpin, txpin, mode, baudrate) : okay
  {{
  Starts serial driver in a new cog

    rxpin - input receives signals from peripheral's TX pin
    txpin - output sends signals to peripheral's RX pin
    mode  - bits in this variable configure signaling
               bit 0 inverts rx
               bit 1 inverts tx
               bit 2 open drain/source tx
               bit 3 ignor tx echo on rx
    baudrate - bits per second
            
    okay - returns false if no cog is available.
  }}

	stop
	longfill(@rx_head, 0, 4)
	longmove(@rx_pin, @rxpin, 3)
	bit_ticks := clkfreq / baudrate
	buffer_ptr := @rx_buffer
	okay := cog := cognew(@entry, @rx_head) + 1


PUB stop

  '' Stops serial driver - frees a cog

	if cog
		cogstop(cog~ - 1)
	longfill(@rx_head, 0, 9)


PUB tx(txbyte)

  '' Sends byte (may wait for room in buffer)

	repeat until (tx_tail <> (tx_head + 1) & $F)
	tx_buffer[tx_head] := txbyte
	tx_head := (tx_head + 1) & $F

	if rxtx_mode & %1000
		rx

PUB rx : rxbyte

  '' Receives byte (may wait for byte)
  '' rxbyte returns $00..$FF

	repeat while (rxbyte := rxcheck) < 0

PUB rxflush

  '' Flush receive buffer

	repeat while rxcheck => 0
    
PUB rxcheck : rxbyte

  '' Check if byte received (never waits)
  '' rxbyte returns -1 if no byte received, $00..$FF if byte

	rxbyte--
	if rx_tail <> rx_head
		rxbyte := rx_buffer[rx_tail]
		rx_tail := (rx_tail + 1) & $F

PUB rxtime(ms) : rxbyte | t

  '' Wait ms milliseconds for a byte to be received
  '' returns -1 if no byte received, $00..$FF if byte

	t := cnt
	repeat until (rxbyte := rxcheck) => 0 or (cnt - t) / (clkfreq / 1000) > ms

PUB str(stringptr)

  '' Send zero terminated string that starts at the stringptr memory address

	repeat strsize(stringptr)
		tx(byte[stringptr++])

PUB getstr(stringptr) | index
    '' Gets zero terminated string and stores it, starting at the stringptr memory address
	index~
	repeat until ((byte[stringptr][index++] := rx) == 13)
	byte[stringptr][--index]~

PUB dec(value) | i

'' Prints a decimal number

	if value < 0
		-value
		tx("-")

	i := 1_000_000_000

	repeat 10
		if value => i
			tx(value / i + "0")
			value //= i
			result~~
		elseif result or i == 1
			tx("0")
	i /= 10


PUB GetDec : value | tempstr[11]

    '' Gets decimal character representation of a number from the terminal
    '' Returns the corresponding value

	GetStr(@tempstr)
	value := StrToDec(@tempstr)    

PUB StrToDec(stringptr) : value | char, index, multiply

    '' Converts a zero terminated string representation of a decimal number to a value

	value := index := 0
	repeat until ((char := byte[stringptr][index++]) == 0)
		if char => "0" and char =< "9"
			value := value * 10 + (char - "0")
	if byte[stringptr] == "-"
		value := - value
       
PUB bin(value, digits)

  '' Sends the character representation of a binary number to the terminal.

	value <<= 32 - digits
	repeat digits
		tx((value <-= 1) & 1 + "0")

PUB GetBin : value | tempstr[11]

  '' Gets binary character representation of a number from the terminal
  '' Returns the corresponding value
   
	GetStr(@tempstr)
	value := StrToBin(@tempstr)    
   
PUB StrToBin(stringptr) : value | char, index

  '' Converts a zero terminated string representaton of a binary number to a value
   
	value := index := 0
	repeat until ((char := byte[stringptr][index++]) == 0)
		if char => "0" and char =< "1"
			value := value * 2 + (char - "0")
	if byte[stringptr] == "-"
		value := - value
   
PUB hex(value, digits)

  '' Print a hexadecimal number

	value <<= (8 - digits) << 2
	repeat digits
		tx(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))

PUB GetHex : value | tempstr[11]

    '' Gets hexadecimal character representation of a number from the terminal
    '' Returns the corresponding value

	GetStr(@tempstr)
	value := StrToHex(@tempstr)    

PUB StrToHex(stringptr) : value | char, index

    '' Converts a zero terminated string representaton of a hexadecimal number to a value

	value := index := 0
	repeat until ((char := byte[stringptr][index++]) == 0)
		if (char => "0" and char =< "9")
			value := value * 16 + (char - "0")
		elseif (char => "A" and char =< "F")
			value := value * 16 + (10 + char - "A")
		elseif(char => "a" and char =< "f")   
			value := value * 16 + (10 + char - "a")
	if byte[stringptr] == "-"
		value := - value

DAT

'***********************************
'* Assembly language serial driver *
'***********************************

				org 0
'
'
' Entry
'
entry			
				long 0 [8]     ' debugger stub space ... if no debugger, these are nops


				mov		dira, mask 'DEBUG: Allow for LED output
				

				mov		t1,par				'get structure address
				add		t1,#4 << 2			'skip past heads and tails

				rdlong	t2,t1				'get rx_pin
				mov		rxmask,#1
				shl		rxmask,t2

				add		t1,#4				'get tx_pin
				rdlong	t2,t1
				mov		txmask,#1
				shl		txmask,t2

				add		t1,#4				'get rxtx_mode
				rdlong	rxtxmode,t1

				add		t1,#4				'get bit_ticks
				rdlong	bitticks,t1

				add		t1,#4				'get buffer_ptr
				rdlong	rxbuff,t1
				mov		txbuff,rxbuff
				add		txbuff,#16

				test	rxtxmode,#%100	wz	'init tx pin according to mode
				test	rxtxmode,#%010	wc
	if_z_ne_c	or		outa,txmask
	if_z		or		dira,txmask

				mov		txcode,#transmit	'initialize ping-pong multitasking
'
'
' Receive
'				
				
				
receive			jmpret	rxcode,txcode		'run chunk of tx code, then return

				test	rxtxmode,#%001	wz	'wait for start bit on rx pin
				test	rxmask,ina		wc
	if_z_eq_c	jmp		#receive

				mov		rxbits,#9			'ready to receive byte
				mov		rxcnt,bitticks
				shr		rxcnt,#1
				add		rxcnt,cnt						  

:bit			add		rxcnt,bitticks		'ready next bit period

:wait			jmpret	rxcode,txcode		'run chunk of tx code, then return

				mov		t1,rxcnt			'check if bit receive period done
				sub		t1,cnt
				cmps	t1,#0			wc
	if_nc		jmp		#:wait

				test	rxmask,ina		wc	'receive bit on rx pin
				rcr		rxdata,#1
				djnz	rxbits,#:bit

				shr		rxdata,#32-9		'justify and trim received byte
				and		rxdata,#$FF
				test	rxtxmode,#%001	wz	'if rx inverted, invert byte
	if_nz		xor		rxdata,#$FF

				

write_packet	'Checks to see if the packet should be written to the hub, based on the save_packet flag
				cmp		save_packet, #1	wz	
'	if_nz		jmp		#state_machine		'skip to rest of code
				
	if_z		rdlong	t2,par				'save received byte and inc head
	if_z		add		t2,rxbuff
	if_z		wrbyte	rxdata,t2
	if_z		sub		t2,rxbuff
	if_z		add		t2,#1
	if_z		and		t2,#$0F
	if_z		wrlong	t2,par

				

state_machine	
:switch			jmp		#:state_0			'Will be overwritten as appropriate
				
				
'-------------------------------------------
	
:state_0 'Compare to s
				cmp		rxdata, #"s"	wz	'Compare to ASCII 's'
	if_z		movs	:switch, #:state_1	'transition to next state (1)
				jmp		#receive
				
				
'-------------------------------------------
:state_1 'Compare to n
				cmp		rxdata, #"n"	wz	'Compare to ASCII 'n'
	if_z		movs	:switch, #:state_2	'transition to next state (2)
	if_nz		cmp		rxdata, #"s"	wz	'Compare to ASCII 's'
	if_nz		movs	:switch, #:state_0	'character was neither s nor n, so back to state 0
				jmp		#receive			'	otherwise, stay in state 1 (ie, if it's an 's')
	
'-------------------------------------------
:state_2 'Compare to p
				movs	:switch, #:state_0	'Default back to state 0
				cmp		rxdata, #"s"	wz	'Compare to ASCII 's'
	if_z		movs	:switch, #:state_1	'transition to previous state (1) (ie, string of form ...sns_
				cmp		rxdata, #"p"	wz	'Compare to ASCII 'p'
	if_z		movs	:switch, #:state_3	'if it is a p, then next state goes to pt

				jmp		#receive			'byte done, receive next byte

'-------------------------------------------				
:state_3 ' parse the pt byte				
				
'				mov		batch_length_debug, rxdata 'make copy
				mov		checksum_calc, rxdata
				add		checksum_calc, snp_sum
				
				and		rxdata, #$80	wz,nr	'test pt data bit
'				shr		rxdata, #7		wz,nr	'test pt data bit
	if_z		mov		has_data, #0			'Packet has no data
	if_nz		mov		has_data, #1
				
				and		rxdata, #$1		wz,nr	'test pt command failed bit TO_DO: Optimize this into two (or one? instructions)
	if_z		mov		command_failed, #0		' eg : mov command_failed, rxdata
	if_nz		mov		command_failed, #1		'	   and command_failed, #$1

				and		rxdata, #$40	wz,nr	'test pt batch bit
	if_nz		mov		batch_length, rxdata	'if it is a batch, get the length
	if_nz		shr		batch_length, #2
	if_nz		and		batch_length, #$F		'only lowest four bits
				
'				muxz	outa, mask 'For debugging
				
	if_z		mov		batch_length, #1		'Default to a batch length of 1 (if data, at least one register's worth)
	
				mov		batch_length_copy, batch_length	'Make a copy, used in state 7
'				mov		batch_length_debug, rxdata 'make copy
	
				movs	:switch, #:state_4		'move on to address state
	

				
	
				jmp		#receive

'-------------------------------------------				
:state_4	' parse the address
'TO_DO: add code here for adjusting the address when in batch mode
				mov		um6_address, rxdata
				add		checksum_calc, rxdata
				cmp		has_data, #0	wz
	if_z		movs	:switch, #:state_6 		'Packet has no data
	if_nz		movs	:switch, #:state_5		'Packet has data, num registers == batch_length
	
	'---------------------------------------
'				'Test for the various packet types (Slow version)
'				mov		t1, #0
'				mov		t2, #data_register
':state_4_loop	
'				mov		t3, t2					'Reset t3 with base address (t2)
'				add		t3, t1					'Add offset (t1) to address
'				movs	:state_4_loop_read, t3
'				nop								'Can't modify the next instruction
':state_4_loop_read
'				cmp		um6_address, 0-0	wz	'Compare the addresses to the data_register variable
'	if_nz		add		t1, #1					'increment for next time through loop
'	if_nz		cmp		t1, #5+1				wc	'Test for bounds (note the +1 here, correct?)
'	if_nz_and_c	jmp		#:state_4_loop

'	if_nc		jmp		#receive				'if C is not set then it didn't find a match...
	'---------------------------------------
				'Test for the various packet types (Fast(?) version)
			
'				movs	:state_4_loop, #data_register-1
'				mov		data_offset, data_count	'DEBUG:TO_DO: Make it so that the 8 is changeable...
'												'Selected 8 because too many instructions here will make it unable to
'												'receive the bits (it hangs...)
'												
'				add		data_offset, #1
'				add		:state_4_loop, data_offset	'Set the loop index to the last (based on constant in previous instruction) instruction
'				nop								'Can't modify the next instruction
'					
':state_4_loop	cmp		um6_address, 0-0 wz		'Test received address and the address in memory. Same?
'	if_nz		sub		:state_4_loop, #1		'If different, decrement to next address
'	if_nz		djnz	data_offset, #:state_4_loop		'If different, decrement index. If there's still more to check, jump
'			
'				'Add this point
'				' data_offset - index+1 of matching address
'	if_z		sub		data_offset, #1					'Because counter is +1 from the actual index (so it works with djnz)
'	if_nz		mov		data_offset, #$FF		'$FF indicates no register match found
'					
	
				jmp		#receive

'-------------------------------------------				
:state_5	'data receive (4 bytes)
				nop
				mov		data_bytes_result, #0
'				mov		batch_byte_index, #dn	'Copy the address of the data registers


:state_5_0		add		checksum_calc, rxdata			'Add to checksum
				shl		rxdata, #24						'Put into it's correct spot
				or		data_bytes_result, rxdata		'Merge into result
				movs	:switch, #:state_5_1			'Transition for next state
				jmp		#receive
				
:state_5_1		add		checksum_calc, rxdata			'Add to checksum
				shl		rxdata, #16						'Put into it's correct spot
				or		data_bytes_result, rxdata		'Merge into result
				movs	:switch, #:state_5_2			'Transition for next state
				jmp		#receive
				
:state_5_2		add		checksum_calc, rxdata			'Add to checksum
				shl		rxdata, #8						'Put into it's correct spot
				or		data_bytes_result, rxdata		'Merge into result
				movs	:switch, #:state_5_3			'Transition for next state
				jmp		#receive
				
:state_5_3		add		checksum_calc, rxdata			'Add to checksum
'				shl		rxdata, #0						'Put into it's correct spot
				or		data_bytes_result, rxdata		'Merge into result
				

'-------------------------------------------
'Write received long to hub
				wrlong	data_bytes_result, data_address
 
				{Current Problem: It's not writting the correct(?) Data to the the hub
				Outputs with just the wrlong above seem to indicate that the data_bytes_result has the correct values
				but that somewhere in the block below it's not showing up... :(
				Anyway, the block below was outputting FFFFFFFs in the second column (first added to registers, important?)
				and 00000000s in the rest
				
				}



'				cmp		um6_address, data_register + 0 wz
'	if_z		wrlong	data_bytes_result, data_address + 0
'	
'				cmp		um6_address, data_register + 1 wz
'	if_z		wrlong	data_bytes_result, data_address + 1
'	
'				cmp		um6_address, data_register + 2 wz
'	if_z		wrlong	data_bytes_result, data_address + 2
'	
'				cmp		um6_address, data_register + 3 wz
'	if_z		wrlong	data_bytes_result, data_address + 3
'	
'				cmp		um6_address, data_register + 4 wz
'	if_z		wrlong	data_bytes_result, data_address + 4
'	
'				cmp		um6_address, data_register + 5 wz
'	if_z		wrlong	data_bytes_result, data_address + 5
'	
'				cmp		um6_address, data_register + 6 wz
'	if_z		wrlong	data_bytes_result, data_address + 6
'	
'				cmp		um6_address, data_register + 7 wz
'	if_z		wrlong	data_bytes_result, data_address + 7
'-------------------------------------------
				add		um6_address, +1			'If it's a batch operation, then the next address needs to be set
				
	if_z		movs	:switch, #:state_6		'All done (with registers)!
	if_nz		movs	:switch, #:state_5_0	'More registers to receive in batch
	
				jmp		#receive



'-------------------------------------------
:state_6	'checksumA receive
				mov		checksum_rec, rxdata	'set up the higher 8 bits of the checksum
				shl		checksum_rec, #8
				movs	:switch, #:state_7
				jmp		#receive

'-------------------------------------------				
:state_7	'checksumB receive, checksum compare, store data in hub
				movs	:switch, #:state_0		'Regardless of what happens, start over next time
				
				or		checksum_rec, rxdata	'append the lower eight bits



				
				
				
				
				
				
				cmp		checksum_calc, checksum_rec	wz

				
				jmp		#receive

'-------------------------------------------------------------------
				'The two lines below will output all eight LEDs
				and		t1, #0 wz
				muxz	outa, mask
				



'
' Transmit
'
transmit		jmpret	txcode,rxcode		'run chunk of rx code, then return

				mov		t1,par				'check for head <> tail
				add		t1,#2 << 2
				rdlong	t2,t1
				add		t1,#1 << 2
				rdlong	t3,t1
				cmp		t2,t3		wz
		if_z	jmp		#transmit

				add		t3,txbuff			'get byte and inc tail
				rdbyte	txdata,t3
				sub		t3,txbuff
				add		t3,#1
				and		t3,#$0F
				wrlong	t3,t1

				or		txdata,#$100		'ready byte to transmit
				shl		txdata,#2
				or		txdata,#1
				mov		txbits,#11
				mov		txcnt,cnt

:bit			test	rxtxmode,#%100	wz	'output bit on tx pin 
				test	rxtxmode,#%010	wc	'according to mode
	if_z_and_c	xor		txdata,#1
				shr		txdata,#1		wc
	if_z		muxc	outa,txmask		
	if_nz		muxnc	dira,txmask
				add		txcnt,bitticks		'ready next cnt

:wait			jmpret	txcode,rxcode		'run chunk of rx code, then return

				mov		t1,txcnt			'check if bit transmit period done
				sub		t1,cnt
				cmps	t1,#0			wc
	if_nc		jmp		#:wait

				djnz	txbits,#:bit		'another bit to transmit?

				jmp		#transmit			'byte done, transmit next byte
'
'
' Uninitialized data
'
'the variables data_* are meant to be written to before the object starts.
'temp			long	0'Don't use!
data_offset		long	0					'Used to index into the current value for the data_* arrays
data_count		long	0					'The number of registers to watch for
data_register	long	0[16]				'The UM6 register to watch for (note: the max, 16, is hardcoded above...)
'spacer_debug	long	0
data_address	long	0[16]				'The HUB address to store the received long (4 bytes) to

batch_length_debug	long	0

filter_received	long	$1

temp_mask_0		long	$800000
temp_mask_1		long	$400000
temp_mask_2		long	$200000
temp_mask_3		long	$100000
temp_mask_4		long	$080000
temp_mask_5		long	$040000
temp_mask_6		long	$020000
temp_mask_7		long	$010000

mask			long	$FF0000
'led				long	$0
'state			long	$0					'For the snp comparison state machine
'xornot			long	$FFFFFFFF
'data			long	$0					'will be packed with the received data
snp_sum			long	337					' sum of ASCII values, 115+110+112

save_packet		long	$1

hub_address_debug long	$F00

hub_address		res		1					'Location in the hub to store the data. 0 indicates do not store (if I decide to implement that part...?)

has_data		res		1					'length of the received packet
batch_length	res		1
batch_length_copy res	1
um6_address		res		1
command_failed	res		1
'current_byte	res		1
checksum_calc	res		1
checksum_rec	res		1

'dn				res		16*4				
data_bytes_result res	1		'This is where the received bytes get written to (formerly called dn[])
batch_length_temp res	1

batch_byte_index res	1				'Used in state_5 to indicate the current byte that it is receiving


t1				res		1
t2				res		1
t3				res		1

rxtxmode		res		1
bitticks		res		1

rxmask			res		1
rxbuff			res		1
rxdata			res		1
rxbits			res		1
rxcnt			res		1
rxcode			res		1

txmask			res		1
txbuff			res		1
txdata			res		1
txbits			res		1
txcnt			res		1
txcode			res		1



				fit		496
				
				































'Old State 7
''-------------------------------------------				
':state_7	'checksumB receive, checksum compare, store data in hub
'				movs	:switch, #:state_0		'Regardless of what happens, start over next time
'				
'				or		checksum_rec, rxdata	'append the lower eight bits

''			Temporarily blacked out for performance testing
''				movd	:state_7_mov_0, dn+0	'Reset to begining registers
''				movd	:state_7_mov_1, dn+1
''				movd	:state_7_mov_2, dn+2
''				movd	:state_7_mov_3, dn+3


'				'TO_DO: add code that does something with the checksum...



':state_7_batch_loop		'Run once through for each register to write to hub
''-------------------------------------------
''Test for the various packet types (Fast(?) version)
'{	Input: 
'		data_count 			- number of added registers
'		data_register[n] 	- register addresses to watch for
'		um6_address 		- received address to search with
'	
'	Output:
'		data_offset			- index of matching address, $FF if not found
'}
'				movs	:state_7_loop, #data_register-1
'				mov		data_offset, data_count	'DEBUG:TO_DO: Make it so that the 8 is changeable...
'												'Selected 8 because too many instructions here will make it unable to
'												'receive the bits (it hangs...)
'												
'				add		data_offset, #1
'				add		:state_7_loop, data_offset	'Set the loop index to the last (based on constant in previous instruction) instruction
'				nop								'Can't modify the next instruction
'					
':state_7_loop	cmp		um6_address, 0-0 wz		'Test received address and the address in memory. Same?
'	if_nz		sub		:state_7_loop, #1		'If different, decrement to next address
'	if_nz		djnz	data_offset, #:state_7_loop		'If different, decrement index. If there's still more to check, jump
'			
'				'Add this point
'				' data_offset - index+1 of matching address
'	if_z		sub		data_offset, #1					'Because counter is +1 from the actual index (so it works with djnz)
'	if_nz		mov		data_offset, #$FF		'$FF indicates no register match found
''------------------------------------------
'				
'				'Test to see if we should write this register to the hub
'				cmp		data_offset, #$FF	wz			'Did we find the offset, earlier?
'	if_z		jmp		#:state_7_increment				'If not, then don't upload, and skip to next address
'				
''------------------------------------------
''Save received data register to hub
'{	Input: 
'		data_offset			- index into data_register of matching address, assumed valid
'		dn[n]				- array containing the data bytes to write
'	Output:
'		<none>
'}	
'			
'				
'			
'			
''			Temporarily blacked out for performance testing
''			
''				'Concat the four data bytes into one
'':state_7_mov_0	mov		dn+0, 0-0
'':state_7_mov_1	mov		dn+1, 0-0
'':state_7_mov_2	mov		dn+2, 0-0
'':state_7_mov_3	mov		dn+3, 0-0
''				
''				
''				
''				
''				shl		dn+0, #24
''				shl		dn+1, #16
''				shl		dn+2, #8
''				shl		dn+3, #0
''				
''				mov		t2, #0
''				or		t2, dn+0
''				or		t2, dn+1
''				or		t2, dn+2
''				or		t2, dn+3
''				

''			
'				movs	:state_7_wrlong, #data_address
'				add		:state_7_wrlong, data_offset			' Offset
'				nop
':state_7_wrlong	wrlong	t2, 0-0
''------------------------------------------			



':state_7_increment

''			Temporarily blacked out for performance testing
''				add		:state_7_mov_0, #4	'Increment registers for next time
''				add		:state_7_mov_1, #4
''				add		:state_7_mov_2, #4
''				add		:state_7_mov_3, #4
'				
'				add		um6_address, #1		'Increment address for next time (needed if in batch)
'				sub		batch_length_copy, #1 wz
'	if_nz		jmp		#:state_7_loop		'more to do!
''	if_z		'all done
'		
'				
'				
'				
'				cmp		checksum_calc, checksum_rec	wz
''				cmp		um6_address, #$FD	wz
''				muxnz	outa, temp_mask_6		'Output to LED state of checksum

'							
'				'Compare checksums for validity

''				muxnz	outa, mask
''	if_nz		mov		state, #0				'Checksum doesn't match! Ignore the packet
''	if_nz		jmp		#receive				

'				'Now, need to store into hub.
''				cmp		um6_address, #$62	wz	'Hard code the address for now
''				
''	if_z		mov		d0, #127 'For testing
''				wrlong	um6_address, data_address
'	

'				
'				jmp		#receive

''-------------------------------------------------------------------
'				'The two lines below will output all eight LEDs
'				and		t1, #0 wz
'				muxz	outa, mask
'				

'' LEFTOVERS FROM ABOVE...
'				'Conditional for debugging (so that it can do the LED stuff below)
''	if_nz		jmp		#receive			'If it's not a p, then go back to begining 

''			
'''			--> "snp" found!
'				
''				'Do LED stuff for debugging:
''				add		led, #1				
''				and		led, #$FF			'limit to eight bits
''				mov		t1, mask			'
''				xor		t1, xornot			'not the mask, so of form ...1100...0011..
''				and		outa, t1			'clear the LED bits
''				mov		t2, led
''				shl		t2, #16
''				or		outa, t2			'set the led outputs

''---------------------
''From the data receive state, old code:
''				add		checksum_calc, rxdata				
''				
''					
''				
''				cmp		current_byte, #1	wc,wz
''	if_c		mov		d0, rxdata			'current_byte == 0 (or less, but that should never happen)
''	if_z		mov		d1, rxdata			'current_byte == 1
''	if_c_or_z	add		current_byte, #1	'increment for next time
''	if_c_or_z	jmp		#receive
''				
''				
''				cmp		current_byte, #3	wc,wz
''	if_c		mov		d2, rxdata			'current_byte == 2 (or less, but that should never happen (tested for above))
''	if_c		add		current_byte, #1
''	if_c		jmp		#receive
''	
''				mov		d3, rxdata			'current_byte == 3
''				
''				
''				
''				'Now, have all four bytes of rx data
''				mov		current_byte, #0	'clear for next time
''				movs	:switch, #:state_6
''				jmp		#receive
''---------------------

































				

{{
--------------------------------------------------------------------------------  
Copyright (c) 2012 Cody Lewis and Luke De Ruyter

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--------------------------------------------------------------------------------
}}

