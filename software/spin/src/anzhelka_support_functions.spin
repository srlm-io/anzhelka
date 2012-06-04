{{
--------------------------------------------------------------------------------
Anzhelka Project
(c) 2012

For the latest code and support, please visit:
http://code.anzhelka.com
--------------------------------------------------------------------------------

Title: anzhelka_support_functions.spin
Author: Cody Lewis
Date: 31 May 2012
Notes: This file contains functions for use in Anzhelka terminal interfacing. To use, you'll need
		combine it into a single file with the "main" file you are writting. You'll also need to:
		
		- define
			- DEBUG_TX_PIN
			- DEBUG_RX_PIN
			- CLOCK_PIN
			
		- call
			InitFunctions
		- account for
			2 cogs (floating point and serial)

Notes:
	--- If a '?' is received for any of the numbers, that means that it couldn't be translated (ie, not float, not int, ?)

    --- Be very careful with types. Most things should probably be floats...

}}




CON
	SERIAL_BAUD = 115200

	'System Clock settings
	FREQ_VALUE = $0001_0000
	FREQ_COUNTS = 65536 '2^n, where n is the number of freq1's needed before overflow
	
	

OBJ
	serial	:   "FastFullDuplexSerialPlusBuffer.spin"
	fp		:	"F32_CMD.spin"
	
VAR
	long	FNeg1
PUB InitFunctions
	
	FNeg1 := fp.FNeg(float(1))
	
	fp.start
	InitClock
	InitUart


'-------------------------------------------------------------------
'-------------------------------------------------------------------
'----------------- $ATXXX Input Functions --------------------------
'-------------------------------------------------------------------
'-------------------------------------------------------------------

PUB ParseSerial
	repeat until ParseString == -1

PUB ParseString | t1, rxdata
' Master Serial Parsing Function

	'Wait for start character
	repeat
		t1 := serial.rxcheck
		if t1 == -1
			return -1
		if t1 == "$"
			quit
	
'	serial.str(string("Found a packet! $"))
	
	t1 := serial.rx
	if t1 <> "A"
		'Not an $ATXXX packet! Ignore
		return
		
		
	'Test for Type
	t1 := serial.rx
	if t1 == "C" 'Command Packet
		ParseSerialCommand
		
	if t1 == "D" 'Data Packet
		ParseSerialData
	
	return 0

CON
	XDR_READ = 0
	XDR_WRITE = 1

	sSDR = ("S" << 16) | ("D" << 8) | "R"
	sRDR = ("R" << 16) | ("D" << 8) | "R"
PUB ParseSerialCommand | t1, t2, t3, command
''Parses packets of the form "$ACXXX ...", ie command packets
	
	'Get three letter packet type
	command := serial.rx
	command := (command << 8) | serial.rx
	command := (command << 8) | serial.rx
	
	'Decide what to do based on three letter packet type:
	case command
		sSDR:
			ParseSerialXDR(XDR_WRITE)
		sRDR:
			ParseSerialXDR(XDR_READ)
		OTHER:
			PrintStrStart
			serial.str(string("Warning: Unknown command type: "))
'			command <<=  8
			command := (command & $FF) << 16 | (command & $FF00) | (command & $FF_0000) >> 16
			serial.str(@command)
			serial.str(string(" ($"))
			serial.hex(command, 8)
			serial.tx(")")
			PrintStrStop
			
CON
	sPWM = ("P" << 16) | ("W" << 8) | "M"
	sMKP = ("M" << 16) | ("K" << 8) | "P"
	sMKI = ("M" << 16) | ("K" << 8) | "I"
	sMKD = ("M" << 16) | ("K" << 8) | "D"
	sNID = ("N" << 16) | ("I" << 8) | "D"
	sNIM = ("N" << 16) | ("I" << 8) | "M"
	sMOM = ("M" << 16) | ("O" << 8) | "M"
	sFZZ = ("F" << 16) | ("Z" << 8) | "Z"
'	 = ("" << 16) | ("" << 8) | ""
'	 = ("" << 16) | ("" << 8) | ""

	NAN = $7FFF_FFFF
	 
PUB ParseSerialXDR(TYPE) | register, values[10], i
'Note: this sets a maximum number of values (up to ten longs)
'This packet will inject the received values into the appropriate variables.
'TYPE is either XDR_READ or XDR_WRITE

	'Discard spaces, and then get first letter
	repeat
	while (register := serial.rx) == " " 'Ignore spaces
	
	'Get second and third letters
	register := (register << 8) | serial.rx
	register := (register << 8) | serial.rx
	
	'Ignore the following comma or newline
	serial.rx

	case register
		sMKP:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 4, TYPE_FLOAT)
				fp.SetTunings(PID_n_1.getBase, values[0], FNeg1, FNeg1)
				fp.SetTunings(PID_n_2.getBase, values[1], FNeg1, FNeg1)
				fp.SetTunings(PID_n_3.getBase, values[2], FNeg1, FNeg1)
				fp.SetTunings(PID_n_4.getBase, values[3], FNeg1, FNeg1)
'				WriteList(@values, PID_n_1.getKpAddr, PID_n_2.getKpAddr, PID_n_3.getKpAddr, PID_n_4.getKpAddr)
			elseif TYPE == XDR_READ
				PrintArrayAddr4(string("MKP"), PID_n_1.getKpAddr, PID_n_2.getKpAddr, PID_n_3.getKpAddr, PID_n_4.getKpAddr, TYPE_FLOAT)
		sMKI:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 4, TYPE_FLOAT)
				fp.SetTunings(PID_n_1.getBase, FNeg1, values[0], FNeg1)
				fp.SetTunings(PID_n_2.getBase, FNeg1, values[1], FNeg1)
				fp.SetTunings(PID_n_3.getBase, FNeg1, values[2], FNeg1)
				fp.SetTunings(PID_n_4.getBase, FNeg1, values[3], FNeg1)
'				WriteList(@values, PID_n_1.getKiAddr, PID_n_2.getKiAddr, PID_n_3.getKiAddr, PID_n_4.getKiAddr)
			elseif TYPE == XDR_READ
				PrintArrayAddr4(string("MKI"), PID_n_1.getKiAddr, PID_n_2.getKiAddr, PID_n_3.getKiAddr, PID_n_4.getKiAddr, TYPE_FLOAT)
			
		sMKD:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 4, TYPE_FLOAT)
				fp.SetTunings(PID_n_1.getBase, FNeg1, FNeg1, values[0])
				fp.SetTunings(PID_n_2.getBase, FNeg1, FNeg1, values[1])
				fp.SetTunings(PID_n_3.getBase, FNeg1, FNeg1, values[2])
				fp.SetTunings(PID_n_4.getBase, FNeg1, FNeg1, values[3])
'				WriteList(@values, PID_n_1.getKdAddr, PID_n_2.getKdAddr, PID_n_3.getKdAddr, PID_n_4.getKdAddr)
			elseif TYPE == XDR_READ
				PrintArrayAddr4(string("MKD"), PID_n_1.getKdAddr, PID_n_2.getKdAddr, PID_n_3.getKdAddr, PID_n_4.getKdAddr, TYPE_FLOAT)
		sPWM:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 4, TYPE_FLOAT)
				WriteList4(@values, @u_1, @u_2, @u_3, @u_4)
			elseif TYPE == XDR_READ	
				PrintArrayAddr4(string("PWM"), @u_1, @u_2, @u_3, @u_4, TYPE_FLOAT)
		sNID:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 4, TYPE_FLOAT)
				WriteList4(@values, @n_d_1, @n_d_2, @n_d_3, @n_d_4)
			elseif TYPE == XDR_READ	
				PrintArrayAddr4(string("NID"), @n_d_1, @n_d_2, @n_d_3, @n_d_4, TYPE_FLOAT)
				
		sNIM:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 4, TYPE_FLOAT)
				WriteList4(@values, @n_1, @n_2, @n_3, @n_4)
			elseif TYPE == XDR_READ	
				PrintArrayAddr4(string("NIM"), @n_1, @n_2, @n_3, @n_4, TYPE_FLOAT)
				
		sMOM:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 3, TYPE_FLOAT)
				WriteList3(@values, @M_x, @M_y, @M_z)
			elseif TYPE == XDR_READ	
				PrintArrayAddr3(string("MOM"), @M_x, @M_y, @M_z, TYPE_FLOAT)
		
		sFZZ:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 1, TYPE_FLOAT)
				WriteList1(@values, @F_z)
			elseif TYPE == XDR_READ	
				PrintArrayAddr1(string("FZZ"), @F_z, TYPE_FLOAT)
				
		OTHER:
			PrintStrStart
			serial.str(string("Warning: Unknown register type: "))
			register := (register & $FF) << 16 | (register & $FF00) | (register & $FF_0000) >> 16
			serial.str(@register) 'TODO: this won't output the ascii letters of the string, need to fix
			serial.hex(register, 8)
			serial.tx(")")
			PrintStrStop
			

PUB WriteList1(input_array_addr, a_addr)
'Writes the four variables in the input array to the four addresses specified.
'If a number is NAN, it will not write it.
	
	if long[input_array_addr][0] <> NAN
		long[a_addr] := long[input_array_addr][0]

PUB WriteList3(input_array_addr, a_addr, b_addr, c_addr)
'Writes the four variables in the input array to the four addresses specified.
'If a number is NAN, it will not write it.
	
	if long[input_array_addr][0] <> NAN
		long[a_addr] := long[input_array_addr][0]
	
	if long[input_array_addr][1] <> NAN
		long[b_addr] := long[input_array_addr][1]
	
	if long[input_array_addr][2] <> NAN
		long[c_addr] := long[input_array_addr][2]
					

PUB WriteList4(input_array_addr, a_addr, b_addr, c_addr, d_addr)
'Writes the four variables in the input array to the four addresses specified.
'If a number is NAN, it will not write it.
	
	if long[input_array_addr][0] <> NAN
		long[a_addr] := long[input_array_addr][0]
	
	if long[input_array_addr][1] <> NAN
		long[b_addr] := long[input_array_addr][1]
	
	if long[input_array_addr][2] <> NAN
		long[c_addr] := long[input_array_addr][2]
		
	if long[input_array_addr][3] <> NAN
		long[d_addr] := long[input_array_addr][3]

PUB WriteListArray(input_array_addr, output_array_addr, length) | i
'Writes the four variables in the input array to the four addresses specified.
'If a number is NAN, it will not write it.
	
	repeat i from 0 to length - 1
		if long[input_array_addr][0] <> NAN
			long[output_array_addr][i] := long[input_array_addr][i]
	

PUB ParseSerialList(array_addr, length, type) | i, float_num[11]
	'Reads a sequence of newline terminated, comma seperated numbers
	'eg 135,42,173,33\n
	'Type - either TYPE_INT or TYPE_FLOAT
	'It will ignore entries with a *. Returns NaN in that case
	
	repeat i from 0 to length-1
		
		if serial.rxpeek == "*"
			long[array_addr][i] := NAN
			serial.rx 'Get rid of '*'
			serial.rx 'Get rid of ','
			next
			
		if type == TYPE_INT
			long[array_addr][i] := serial.GetDec(",")
		elseif type == TYPE_FLOAT
			serial.getstr(@float_num, ",")
			long[array_addr][i] := fp.StringToFloat(@float_num)
		elseif type == TYPE_INT_CAST
			serial.getstr(@float_num, ",")
			long[array_addr][i] := fp.FloatRound(fp.StringToFloat(@float_num))
		else
			PrintStr(string("Warning: Unknown number type in the ParseSerialList..."))
	
	
PUB ParseSerialData
	PrintStr(string("Error: Parsing ADXXX type packets not set yet."))


'-------------------------------------------------------------------
'-------------------------------------------------------------------
'----------------- $ATXXX Output Functions -------------------------
'-------------------------------------------------------------------
'-------------------------------------------------------------------

	
CON
	TYPE_INT = 0
	TYPE_FLOAT = 1
	TYPE_INT_CAST = 2 'Read as a float, but cast to int
PUB PrintArray(type_string_addr, array_addr, length, type) | i
'' Parameters:
''  - type_string_addr: a string that has the three capital letters that 
''      denote which type of data this packet is, eg PWM or MKP
''  - array_addr: the values to send. A long array only.
''  - length: the length of the array.


	serial.str(string("$AD"))
	serial.str(type_string_addr)
	serial.tx(" ")
	serial.dec(phsb)

	repeat i from 0 to length - 1
		serial.tx(",")
		if type == TYPE_INT
			serial.dec(long[array_addr][i])
		elseif type == TYPE_FLOAT
			FPrint(long[array_addr][i])
		else
			serial.tx("?") 'Warning!
		
	serial.tx(10)
	serial.tx(13)

PUB PrintArrayAddr4(type_string_addr, a_addr, b_addr, c_addr, d_addr, type) | i
'' Parameters:
''  - type_string_addr: a string that has the three capital letters that 
''      denote which type of data this packet is, eg PWM or MKP
''  - [a|b|c|d]_addr - the address of the variable to print
''  - type - either TYPE_FLOAT or TYPE_INT


	serial.str(string("$AD"))
	serial.str(type_string_addr)
	serial.tx(" ")
	serial.dec(phsb)

	repeat i from 0 to 4 - 1
		serial.tx(",")
		if type == TYPE_INT
			serial.dec(long[long[@a_addr][i]])
		elseif type == TYPE_FLOAT
			FPrint(long[long[@a_addr][i]])
		else
			serial.tx("?") 'Warning!
		
	serial.tx(10)
	serial.tx(13)

PUB PrintArrayAddr3(type_string_addr, a_addr, b_addr, c_addr, type) | i
'' Parameters:
''  - type_string_addr: a string that has the three capital letters that 
''      denote which type of data this packet is, eg PWM or MKP
''  - [a|b|c|d]_addr - the address of the variable to print
''  - type - either TYPE_FLOAT or TYPE_INT


	serial.str(string("$AD"))
	serial.str(type_string_addr)
	serial.tx(" ")
	serial.dec(phsb)

	repeat i from 0 to 3 - 1
		serial.tx(",")
		if type == TYPE_INT
			serial.dec(long[long[@a_addr][i]])
		elseif type == TYPE_FLOAT
			FPrint(long[long[@a_addr][i]])
		else
			serial.tx("?") 'Warning!
		
	serial.tx(10)
	serial.tx(13)
	
PUB PrintArrayAddr1(type_string_addr, a_addr, type) | i
'' Parameters:
''  - type_string_addr: a string that has the three capital letters that 
''      denote which type of data this packet is, eg PWM or MKP
''  - [a|b|c|d]_addr - the address of the variable to print
''  - type - either TYPE_FLOAT or TYPE_INT


	serial.str(string("$AD"))
	serial.str(type_string_addr)
	serial.tx(" ")
	serial.dec(phsb)

	
	serial.tx(",")
	if type == TYPE_INT
		serial.dec(long[a_addr])
	elseif type == TYPE_FLOAT
		FPrint(long[a_addr])
	else
		serial.tx("?") 'Warning!
	
	serial.tx(10)
	serial.tx(13)
	
		
PUB PrintStr(addr)
'	serial.str(string("$ADSTR "))
	serial.txblock(string("$ADSTR "), 7)
	serial.dec(phsb)
	serial.tx(",")
	serial.tx("'")
'	serial.str(addr)
	serial.txblock(addr, strsize(addr))
'	serial.str(string("'", 10, 13))
	serial.tx("'")
	serial.tx(10)
	serial.tx(13)
	
PUB PrintStrStart
'	serial.str(string("$ADSTR "))
	serial.txblock(string("$ADSTR "), 7)
	serial.dec(phsb)
	serial.tx(",")
	serial.tx("'")
	
PUB PrintStrStop
'	serial.str(string("'", 10, 13))
	serial.tx("'")
	serial.tx(10)
	serial.tx(13)

'-------------------------------------------------------------------
'-------------------------------------------------------------------
'----------------- Support Functions -------------------------------
'-------------------------------------------------------------------
'-------------------------------------------------------------------

PRI FPrint(fnumA) | temp
	serial.str(fp.FloatToString(fnumA))

PRI ClockSeconds
	return (fp.FMul(fp.FFloat(phsb), fp.FDiv(float(FREQ_COUNTS), fp.FFloat(clkfreq))))


'-------------------------------------------------------------------
'-------------------------------------------------------------------
'----------------- Init Functions ----------------------------------
'-------------------------------------------------------------------
'-------------------------------------------------------------------


PUB InitUart | i, char
	serial.start(DEBUG_RX_PIN, DEBUG_TX_PIN, 0, SERIAL_BAUD)	
	waitcnt(clkfreq + cnt)
	PrintStr(string("Starting..."))
	
	PrintStrStart
	serial.str(string("Compile Time: "))
	i := 0
	
	'Output the compile time, but not the LF at the end
	repeat until (char := byte[@compile_time][i++]) == 10
		serial.tx(char)
		
	PrintStrStop

DAT
	compile_time file "compile_time.dat"
				 long 0
PUB InitClock
' sets pin as output
	DIRA[CLOCK_PIN]~~
	CTRa := %00100<<26 + CLOCK_PIN           ' set oscillation mode on pin
	FRQa := FREQ_VALUE                    ' set FRequency of first counter                   

	CTRB := %01010<<26 + CLOCK_PIN           ' at every zero crossing add 1 to phsb
	FRQB := 1


	
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
