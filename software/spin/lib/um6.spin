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
--- 99% compatible with FDS+ (TODO: explain)

CHR_UM6 Checksum is calculated by the following:
"The checksum is computed by summing the each unsigned character in the packet
and storing the result in an unsigned 16-bit integer. If your sum treats the
characters as signed, then that could generate inconsistent problems (ie.
sometimes it works, sometimes it doesn't). I don't know if this is the problem,
but it is something worth checking."



The IMU transmits the MSB first. That means that the first data byte received is B3, then B2, B1, and B0.


TODO:
---	Note: the variables will be updated in the hub as single longs. This could be a problem for things like the quats
		where the "single" number is broken into two packets. If half is new and half is old...
		POSSIBLE SOLUTION -- Use the GET_DATA command  to retrieve the desired addresses, instead of the auto updating.

---	Bug: I think it will hicup on writting the received bytes to the hub if it's a string such as "snsnp": it won't write
		the first "sn" when it should...
	
--- Receive Function tests for maximum packet length of 16. Shouldn't it be 4*16, or 64? (Solved???)
--- Check whether it works with tx code... I can't seem to get it to respond to anything I send it (eg. AA)
		Note: it does seem to occasionally send FD (invalid checksum) when sending it command registers
				but the checksum appears to be correct.
				
---	Need to figure out something to do when the command failed bit is set (both in assembly and spin versions)
}}

''------------------------------------------------------------------
''--------------------[BEGIN][DEBUGGER]-----------------------------
''------------------------------------------------------------------

'VAR
'	long command
'	long readptr
'	long readbuf[256/4]

'	long	gyro_proc_xy
'	long	accel_proc_xy
'	long	mag_proc_xy
'	long	euler_phi_theta

'CON
'  _clkmode = xtal1 + pll16x
'  _xinfreq = 5_000_000

''IO Pins
'	IMU_RX_PIN = 0 'Note: direction is from Propeller IO port
'	IMU_TX_PIN = 1 'Note: direction is form Propeller IO port

'OBJ
'	bu	: "BMAutility"
'	s : "FullDuplexSingleton"
'PUB main_debug
'{{ Should be run when this object is being debugged. Otherwise, don't call!
'}}

'	waitcnt(clkfreq*1+cnt)        ' wait a second for user to start terminal
'	s.start(31,30,0,230400)       ' start the default serial interface

'	'Setup parameters
'	add_register($5C, @gyro_proc_xy)
'	add_register($5E, @accel_proc_xy)
'	add_register($60, @mag_proc_xy)
'	add_register($62, @euler_phi_theta)


'	readptr := @readbuf

'	bu.taskstart(@entry, start_debug(IMU_RX_PIN, IMU_TX_PIN, 0, 115200), string("Main Task"))
'	bu.start                      ' start multi cog task debugger
'	repeat


'PUB start_debug(rxpin, txpin, mode, baudrate) : okay
'  {{

'  DEBUG VERSION - Identical, except it doesnt't start a cog, and instead returns parameter address
'}}  

'	stop
'	longfill(@rx_head, 0, 4)
'	longmove(@rx_pin, @rxpin, 3)
'	bit_ticks := clkfreq / baudrate
'	buffer_ptr := @rx_buffer

'	okay := @rx_head 'For Debugger

''------------------------------------------------------------------
''--------------------[END][DEBUGGER]-------------------------------
''------------------------------------------------------------------






  
CON                                          ''
   

	DEFAULT_BAUD_RATE = 115200	'CHR UM6 Default baud is 115200




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



PUB zero
'Will call various calibration routines on the IMU. Should be stationary for at least 6 seconds!
	str(@UM6_RESET_EKF)	
	waitcnt(clkfreq >> 2 + cnt)
'	debug.str(string(10, 13, "Set ACCEL_REF"))
	str(@UM6_SET_ACCEL_REF)
	waitcnt(clkfreq >> 2 + cnt)
'	debug.str(string(10, 13, "Set MAG_REF"))
	str(@UM6_SET_MAG_REF)
	waitcnt(clkfreq >> 2 + cnt)
'	debug.str(string(10, 13, "ZERO_GYROS"))
	str(@UM6_ZERO_GYROS)
	waitcnt(clkfreq * 3 + cnt)

DAT
	'Debug strings
	APPEND_CHECKSUM_ERROR byte 10, 13, "ERROR: in string passed to AppendChecksum", 10, 13, 0
	RECEIVE_PACKET_ERROR  byte 10, 13, "ERROR: in receiving a packet from UM6", 10, 13, 0
	
	UM6_GET_FW_VERSION 	byte "snp", %0_0_0000_0_0, $AA, $01, $FB, 0   '0 here, but should have a checksum of $1FB
'	UM6_GET_FW_VERSION byte "snp", %0_0_0000_0_0, $AA, 0, 0, 0   '0 here, but should have a checksum of $1FB
	
	UM6_ZERO_GYROS 		byte "snp", %0_0_0000_0_0, $AC, $01, $FD, 0
	UM6_RESET_EKF  		byte "snp", %0_0_0000_0_0, $AD, $01, $FE, 0
	UM6_SET_ACCEL_REF 	byte "snp", %0_0_0000_0_0, $AF, $02, $00, 0
	UM6_SET_MAG_REF 	byte "snp", %0_0_0000_0_0, $B0, $02, $01, 0
	
	
PUB add_register(register, hub_address_a)
{{ Adds a register to watch for to the current count.
	Must be called before start method.

	
	The _a subscript is to prevent name errors with the long in the PASM cog of the same name...
	
	Note: if you plan on using batch mode, you need to call this function for each address.
	You can do this with a for loop, like follows:
	TODO: insert example code

	
	
	 }}

'	TODO: add bounds check for making sure that register is less than or == to $84

	long[@data_address][register] := hub_address_a

PUB startdefault(rxpin, txpin) : okay
	{{ Same as start, but with default parameters }}
	return start(rxpin, txpin, 0, DEFAULT_BAUD_RATE)

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






PUB ReceiveFilteredPacket(addr_i) | i, addr, rp_pt, rp_um6_address, checksum, data_length, checksum_running_total, state
{{Addr is the location to store the received string, should be large enough to hold everything (18 bytes...)

Stores data in the following format:


Byte Offset - Contents
0 - type (um6_address)
1 - data length (bytes)
2+- data (if any)

This function will block until data is received...


Returns the address passed in.
}}

	addr := addr_i 'Copy the value so we can return it at the end...

	repeat until rx == "$"		
	rp_pt := rx

	if (rp_pt & %1000_0000) == 0 'then no data (has data bit is 0)
		'debug.str(string(10, 13, "Data bit is set to 0"))
		data_length := 0
	else
		data_length := 4
		
	
	rp_um6_address := rx
	
	byte[addr++] := rp_um6_address & $FF
	byte[addr++] := data_length & $FF
	
	if data_length <> 0
		'Hmmm, the indicies on repeat are inclusive, so we need to take off 1. Right?
		repeat i from 0 to data_length - 1 'If data_legth is 0, then the loop should never execute (right???)
			byte[addr] := rx
			checksum_running_total += byte[addr++]

	return addr_i 'return the original value


PUB ReceiveOriginalPacket(addr_i) | i, addr, rp_pt, rp_um6_address, checksum, data_length, checksum_running_total, state
{{
Addr is the location to store the received string, should be large enough to hold everything (18 bytes...)


Stores data in the following format:

Byte Offset - Contents
0 - type (um6_address)
1 - data length (bytes)
2+- data (if any)


This function will block (wait) until a valid packet is received.

Return
	addr	on	success
	-1		on	checksum failure
	-2		on	packet length error (via pt byte)

}}

	addr := addr_i 'Copy the value so we can return it at the end...

'------------------------------------
'  snp state machine
'------------------------------------
	state := 1
	{state description:
		1 -- Waiting for s
		2 -- Received s
		3 -- Received sn
		

		Each state then waits for the next char and transitions to state S[1-3] based on the received char.
		Note that state 2 must check for 2 types of strings: "ssssssn_" and "sn_", both of which are valid.
		
	}
	repeat 
		i := rx
		if state == 1
			if i == "s"
				state := 2
		elseif state == 2
			if i == "s"
				state := 2
			elseif i == "n"
				state := 3
			else
				state := 1
		elseif state == 3
			if i == "s"
				state := 2
			elseif i == "p"
				quit
			else
				state := 1
		else
			state := 1 'Should never happen
'------------------------------------

	rp_pt := rx

	if (rp_pt & %1000_0000) == 0 'then no data (has data bit is 0)
		data_length := 0
	elseif (rp_pt & %0100_0000) == 0 'then has data, but no batch, so 4 bytes of data
		data_length := 4
	else 'then has data, is a batch, with length of:
		data_length := 4 * ((rp_pt & %00111100) >> 2)
	'Check to make sure the data_length size isn't corrupted
	if data_length < 0 OR data_length > 48
'		debug.str(@RECEIVE_PACKET_ERROR)
'		debug.str(string("Invalid data_length: out of bounds.", 10, 13))
		return -2
	
'	if (rp_pt & %0000_0001) == 1 'Then command failed
'		debug.str(string("Command failed!", 10, 13))	
		'What shoul we do if command failed bit is set?
		
	rp_um6_address := rx
	
	byte[addr++] := rp_um6_address & $FF
	byte[addr++] := data_length & $FF
	
	checksum_running_total := "s" + "n" + "p" + rp_pt + rp_um6_address
	
	if data_length <> 0
		'Hmmm, the indicies on repeat are inclusive, so we need to take off 1. Right? Correct
		repeat i from 0 to data_length - 1 'If data_legth is 0, then the loop should never execute (right???)
			byte[addr] := rx
			checksum_running_total += byte[addr++]
	

	checksum := rx << 8
	checksum := checksum | rx
	
	if checksum <> checksum_running_total
'		debug.str(@RECEIVE_PACKET_ERROR)
'		debug.str(string("Invalid Checksum: "))
'		debug.hex(checksum, 4)
'		debug.tx("/")
'		debug.hex(checksum_running_total, 4)
'		debug.str(string(" (given/calculated)", 10, 13))
		return -1
		
	return addr_i 'return the original value
	

PRI AppendChecksum(addr) | i, data_length
{{
This function still needs to be tested...

I think it is correct, but I am unsure

}}

	result := 0
	
'	debug.str(string(13, 10, "Starting Address: $"))
'	debug.hex(addr, 8)
	
	'Check (and add) "snp" string
	repeat i from 1 to 3 '1 to 3 because loopup is not zero based...
'		t1 := byte[addr++]
		if byte[addr] <> lookup(i: "s", "n", "p")
'			debug.str(@APPEND_CHECKSUM_ERROR)
'			debug.str(string("t1 should equal $"))
'			debug.hex(lookup(i: "s", "n", "p"), 2)
'			debug.str(string(" but is really $"))
'			debug.hex(t1, 2)
'			debug.tx(10)
'			debug.tx(13)
			return -1
		result += byte[addr++]
	
	
'	debug.str(string(13, 10, "Result == $"))
'	debug.hex(result, 8)
'	
	
	'Evaluate the PT byte
'	t1 := byte[addr++]
	result += byte[addr]
	
	if (byte[addr] & %1000_0000) == 0
		'then no data (has data bit is 0)
'		debug.str(string(10, 13, "Data bit is set to 0"))
		data_length := 0
	elseif (byte[addr] & %0100_0000) == 0
		'then has data, but no batch, so 4 bytes of data
'		debug.str(string(10, 13, "Single register of data"))
		data_length := 4
	else
		'then has data, is a batch, with length of:
'		debug.str(string(10, 13, "Batch of data..."))
		data_length := 4 * ((byte[addr] & %0011_1100) >> 2)
	addr++ 'increment address from pt byte to first data byte
	
	'Add in the address byte
	result += byte[addr++]
	
	
'	debug.str(string(13, 10, "Result == $"))
'	debug.hex(result, 8)

	if data_length <> 0
		'Hmmm, the indicies on repeat are inclusive, so we need to take off 1. Right?
		repeat i from 0 to data_length - 1 'If data_legth is 0, then the loop should never execute (right???)
'			debug.str(string(10, 13, "In loop..."))
			result += byte[addr++]
	
'	debug.str(string(13, 10, "Result == $"))
'	debug.hex(result, 8)
	
	
'	debug.str(string(13, 10, "Checksum Address: $"))
'	debug.hex(addr, 8)
	
	
	'Now, we have the checksum in result, and need to store it at addr
	byte[addr++] := (result & $FF00) >> 8 'Upper portion first
	byte[addr++] := (result & $FF) 'Lower portion second
	
	return result








''------------------------------------------------------------------
''--------------------[BEGIN][FULLDUPLEXSERIALPLUS ROUTINES]--------
''------------------------------------------------------------------


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







''------------------------------------------------------------------
''--------------------[BEGIN][PASM]---------------------------------
''------------------------------------------------------------------

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
				mov		write_raw, #0	'Default to not write
				
				
				

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

				

write_packet	'Checks to see if the packet should be written to the hub, based on the write_raw flag
				cmp		write_raw, #1	wz	
	if_nz		jmp		#state_machine		'skip to rest of code
				
'				TODO: optimization:
'				djnz	write_raw, #state_machine nr 'Basically a == 1 test with branch, but the nr says no effect
				
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
				
				mov		pt, rxdata
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
	if_z		mov		batch_length, #1		'Default to a batch length of 1 (if data, at least one register's worth)

				movs	:switch, #:state_4		'move on to address state
	
				jmp		#receive

'-------------------------------------------				
:state_4	' parse the address

				mov		um6_address, rxdata
				add		checksum_calc, rxdata
				cmp		has_data, #0	wz
	if_z		movs	:switch, #:state_6 		'Packet has no data
	if_nz		movs	:switch, #:state_5		'Packet has data, num registers == batch_length
	
	
	
	
:state_4_batch
				'This should be called if the address has been calculated by batch incrementing (not rx receive)
				cmp		um6_address, #$84 + 1 wc	'Check to see if it is past the maximum register
	if_nc		mov		write_raw, #1
	if_nc		jmp		#:state_4_write
				
				
				
				mov		t1, #data_address
				add		t1, um6_address
				movd	:state_4_dr_cmp, t1
				movs	:state_5_wrlong, t1		'Update the base address 
				
:state_4_dr_cmp	cmp		0-0, #0 wz				'Check to see if data_address[um6_address] == 0
	if_z		mov		write_raw, #1			'If it is == 0, that indicates that it's an unwatched address.
	if_nz		mov		write_raw, #0			'If it is != 0, that indicates that we should filter it out of the buffer
	
	
:state_4_write	cmp		write_raw, #1
	if_z		mov		rxdata, #"$"
	if_z		rdlong	t2,par				'Write '$' to hub
	if_z		add		t2,rxbuff
	if_z		wrbyte	rxdata,t2
	if_z		sub		t2,rxbuff
	if_z		add		t2,#1
	if_z		and		t2,#$0F


	if_z		mov		rxdata, pt
	if_z		and		rxdata, #%1000_0011 'get rid of batch data (since we write only one register at a time to hub
	
	
	if_z		add		t2,rxbuff			'write pt byte to hub
	if_z		wrbyte	rxdata,t2
	if_z		sub		t2,rxbuff
	if_z		add		t2,#1
	if_z		and		t2,#$0F

	if_z		mov		rxdata, um6_address
	if_z		add		t2,rxbuff			'write um6_address to hub
	if_z		wrbyte	rxdata,t2
	if_z		sub		t2,rxbuff
	if_z		add		t2,#1
	if_z		and		t2,#$0F
	if_z		wrlong	t2,par


				jmp		#receive

'-------------------------------------------				
:state_5	'data receive (4 bytes)
				mov		data_bytes_result, #0			'Clear results for this register



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
'				
				cmp		write_raw, #0 wz
			
:state_5_wrlong
	if_z		wrlong	data_bytes_result, 0-0	'if valid address, write result (address loaded in state 4 (address) state)
'				wrlong	data_bytes_result, 0-0	'if valid address, write result (address loaded in state 4 (address) state)

	
'-------------------------------------------
				add		um6_address, #1			'If it's a batch operation, then the next address needs to be set
				
				sub		batch_length, #1	wz
	if_z		movs	:switch, #:state_6		'All done (with registers)!
	if_z		mov		write_raw, #0			'If all done, then we don't want to write checksums to hub
	
	if_nz		movs	:switch, #:state_5		'If not done, More registers to receive in batch
	if_nz		jmp		#:state_4_batch			'Need to update UM6 address before receiving next byte...
	
				movs	:switch, #:state_6		'DEBUG
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
				'TODO: write code to check checksum...
				
				jmp		#receive

'-------------------------------------------------------------------
				'The two lines below will output all eight LEDs
'				and		t1, #0 wz
'				muxz	outa, mask
				



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


temp_mask_0		long	$800000	'Debug
temp_mask_1		long	$400000	'Debug
temp_mask_2		long	$200000	'Debug
temp_mask_3		long	$100000	'Debug
temp_mask_4		long	$080000	'Debug
temp_mask_5		long	$040000	'Debug
temp_mask_6		long	$020000	'Debug
temp_mask_7		long	$010000	'Debug
mask			long	$FF0000	'Debug


snp_sum			long	337					' sum of ASCII values, 115+110+112
write_raw		long	$1					'1 == write raw packet to hub, 0 == don't write current packet
data_address	long	0[$85]		'The address in the hub to store a um6_register (indexed by the um6_register address)
									'	Meant to be written to before start, and read only after start


'hub_address_debug long	$F00
'led				long	$0
'state			long	$0					'For the snp comparison state machine
'xornot			long	$FFFFFFFF
'data			long	$0					'will be packed with the received data
'temp			long	0'Don't use!
'data_offset		long	0					'Used to index into the current value for the data_* arrays
'data_count		long	0					'The number of registers to watch for
'data_register	long	0[16]				'The UM6 register to watch for (note: the max, 16, is hardcoded above...)
'spacer_debug	long	0
'data_address	long	0[16]				'The HUB address to store the received long (4 bytes) to

'batch_length_debug	long	0

'filter_received	long	$1



'
'
' Uninitialized data
'

pt				res		1
hub_address		res		1					'Location in the hub to store the data. 0 indicates do not store (if I decide to implement that part...?)
has_data		res		1					'length of the received packet
batch_length	res		1
um6_address		res		1
command_failed	res		1
checksum_calc	res		1
checksum_rec	res		1
data_bytes_result res	1		'This is where the received bytes get written to (formerly called dn[])


'batch_length_temp res	1

'batch_byte_index res	1				'Used in state_5 to indicate the current byte that it is receiving
'dn				res		16*4				
'batch_length_copy res	1

'current_byte	res		1



'Original FullDuplexSerial Plus Constants
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
'Test for the various packet types (Fast(?) version)
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

















			{
				----Algorithm for Batch Writting a series of bytes to a hub buffer:

				max_remaining = $F - buffer_index
				
				if num_bytes_to_write >  max_remaining
					first_count = remaining
					secound_count = num_bytes_to_write - first_count
				else 'num_bytes_to_write =< max_remaining
					first_count = num_bytes_to_write

					second_count = 0
				
				----Some associated Code:
				rdlong	buffer_index, par
				mov		buffer_base, rxbuff
				

				mov		btw, #5			'Five bytes to write: snp pt addr(TO_DO: optimize by making into register)
				mov		max_remaining, buffer_index
				cmp		max_remaining, btw	wc 		' if btw > max_remaining , write C
		if_c	mov		first_count, max_remaining
		if_c	mov		second_count, btw
		if_c	sub		second_count, first_count
		if_nc	mov		first_count, btw

		if_nc	mov		second_count, #0
		
		
		
				mov		t1, buffer_base
:state_4_primary_loop

				add		t1, buffer_index
				'Need to comlete secondary loop
				}

















' State 5 lookup table for um6_addresses...
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
'			
'				cmp		um6_address, data_register + 8 wz
'	if_z		wrlong	data_bytes_result, data_address + 8
'	
'				cmp		um6_address, data_register + 9 wz
'	if_z		wrlong	data_bytes_result, data_address + 9
'	
'				cmp		um6_address, data_register + 10 wz
'	if_z		wrlong	data_bytes_result, data_address + 10
	
'				cmp		um6_address, data_register + 1 wz
'	if_z		wrlong	data_bytes_result, data_address + 1
'	
'				cmp		um6_address, data_register + 1 wz
'	if_z		wrlong	data_bytes_result, data_address + 1
'	


























				

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

