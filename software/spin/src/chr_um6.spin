{{
--------------------------------------------------------------------------------
Anzhelka Project
(c) 2012

For the latest code and support, please visit:
http://code.anzhelka.com
--------------------------------------------------------------------------------

Title: CHR UM6 IMU
Author: Cody Lewis
Date: February 11, 2012

Notes: Works with the CH Robotics UM6 9DOF IMU over a serial interface.

CHR_UM6 Checksum is calculated by the following:
"The checksum is computed by summing the each unsigned character in the packet
and storing the result in an unsigned 16-bit integer. If your sum treats the
characters as signed, then that could generate inconsistent problems (ie.
sometimes it works, sometimes it doesn't). I don't know if this is the problem,
but it is something worth checking."


}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

CON
'IO Pins
	DEBUG_TX_PIN  = 30
	DEBUG_RX_PIN  = 31
	
	IMU_RX_PIN = 19 'Note: direction is from Propeller IO port
	IMU_TX_PIN = 18 'Note: direction is form Propeller IO port
	
'Settings

VAR

	byte um6_packet[20] 'Note: should require only 18 bytes, but extra just in case...

OBJ
	debug : "FullDuplexSerialPlus.spin"
	imu : "FullDuplexSerialPlus.spin"

PUB Main | i, t1, addr

	debug.start(DEBUG_RX_PIN, DEBUG_TX_PIN, 0, 115200)
	imu.start(IMU_RX_PIN, IMU_TX_PIN, 0, 115200)
	waitcnt(clkfreq + cnt)
	
	debug.str(string("Starting"))
	debug.tx(10)
	debug.tx(13)
	
	AppendChecksum(@UM6_GET_FW_VERSION)
	repeat i from 0 to 6
		imu.tx(byte[@UM6_GET_FW_VERSION][i])
		
	repeat 100
		repeat 20
			debug.hex(imu.rx, 2)
			debug.tx(" ")
		debug.tx(10)
		debug.tx(13)
	
	repeat
	
	repeat
		debug.str(string("Receive packet"))
		addr := ReceivePacket(@um6_packet)
		if addr <> @um6_packet
			debug.str(string("Error in the return address from ReceivePacket: "))
			debug.hex(addr, 8)
			debug.tx("/")
			debug.hex(@um6_packet, 8)
			debug.str(string(" (given/expected)", 10, 13))
		else
			debug.str(string("New packet!"))
	

'---------------------------------------------------------
'	'Test transmitting for the FW reading
'	debug.str(string("Attempting to read UM6_GET_FW_VERSION register (0xAA)"))
'	
'	AppendChecksum(@UM6_GET_FW_VERSION)
'	
'	debug.str(string(10, 13, "Checksum should be $01FB == $"))
'	t1 := (byte[@UM6_GET_FW_VERSION][5] << 8) | (byte[@UM6_GET_FW_VERSION][6])
'	debug.hex(t1, 4)
'	
'	debug.str(string(10, 13, "Sending UM6_GET_FW_VERSION command to UM6"))
'	repeat i from 0 to 6
'		imu.tx(byte[@UM6_GET_FW_VERSION][i])
'  'Should get a response of: 73 6E 70 80 AA 55 4D 31 42 03 90
'		
'---------------------------------------------------------	
	
'	debug.str(string(10, 13, "Output 20 memory locations from the start of the string:"))
'	repeat i from 0 to 19
'		debug.str(string(10, 13, "   "))
'		debug.hex(@UM6_GET_FW_VERSION + i, 8)
'		debug.str(string(":  $"))
'		debug.hex(byte[@UM6_GET_FW_VERSION][i], 2)
'		
	
'---------------------------------------------------------
'	'Will receive packets and break into specific bytes...
'	debug.str(string(10, 13, "Packet Type PT AD D0 D1 D2 D3 C1 C2", 10, 13))
'	debug.str(string(        "-----------------------------------", 10, 13))
'	repeat 50
'		repeat until imu.rx == "s"
'		if imu.rx == "n" and imu.rx == "p"
'			debug.str(string("New packet! "))
'			debug.hex(imu.rx, 2)
'			debug.tx(" ")
'			debug.hex(imu.rx, 2)
'			debug.tx(" ")
'			debug.hex(imu.rx, 2)
'			debug.tx(" ")
'			debug.hex(imu.rx, 2)
'			debug.tx(" ")
'			debug.hex(imu.rx, 2)
'			debug.tx(" ")
'			debug.hex(imu.rx, 2)
'			debug.tx(" ")
'			debug.hex(imu.rx, 2)
'			debug.tx(" ")
'			debug.hex(imu.rx, 2)
'			debug.tx(" ")
'---------------------------------------------------------
			
'			t1 := imu.rx 'pt packet			
'			if (t1 & %1000_0000) == %0
'				debug.str(string(" - no data in packet"))
'			else
'				debug.str(string(" - packet has data"))
'			
'			if (t1 & %0100_0000) == %0
'				debug.str(string(" - not a batch"))
'			else
'				debug.str(string(" - is a batch with length "))
'				debug.dec((t1 & %0011_1100) >> 2)
'				
'			debug.str(string(" - binary of PT byte: "))
'			debug.bin(t1, 8)
'			
'			debug.str(string(" - address: $"))
'			debug.hex(imu.rx, 4)
				
				
			
				
				
		debug.tx(10)
		debug.tx(13)


PRI ReceivePacket(addr_i) | i, t1, addr, pt, um6_address, checksum, data_length, checksum_running_total
''Addr is the location to store the received string, should be large enough to hold everything (18 bytes...)

{{
Stores data in the following format:

Byte Offset - Contents
0 - type (um6_address)
1 - data length (bytes)
2+- data (if any)

This function will block until data is received...
}}

	addr := addr_i 'Copy the value so we can return it at the end...

	repeat 
		debug.tx("*")
		if imu.rx == "s"
			if imu.rx == "n"
				if imu.rx == "p"
					quit 'break from loop
	
	pt := imu.rx

	debug.str(string(10, 13))	
	
	'debug.str(string("pt == $"))
	'debug.hex(pt, 2)

	
	if (pt & %1000_0000) == 0 'then no data (has data bit is 0)
		'debug.str(string(10, 13, "Data bit is set to 0"))
		data_length := 0
	elseif (pt & %0100_0000) == 0 'then has data, but no batch, so 4 bytes of data
		'debug.str(string(10, 13, "Single register of data"))
		data_length := 4
	else 'then has data, is a batch, with length of:
		'debug.str(string(10, 13, "Batch of data..."))
		data_length := 4 * ((pt & %0011_1100) >> 2)

	'Check to make sure the data_length size isn't corrupted
	if data_length < 0 OR data_length > 16
		debug.str(@RECEIVE_PACKET_ERROR)
		debug.str(string("Invalid data_length: out of bounds.", 10, 13))
		return -1
		
	'debug.str(string(10, 13, "getting um6_address...", 10, 13))
	um6_address := imu.rx
	
	byte[addr++] := um6_address & $FF
	byte[addr++] := data_length & $FF
	
	checksum_running_total := "s" + "n" + "p" + pt + um6_address
	
	if data_length <> 0
		'Hmmm, the indicies on repeat are inclusive, so we need to take off 1. Right?
		repeat i from 0 to data_length - 1 'If data_legth is 0, then the loop should never execute (right???)
			'debug.str(string("getting data...", 10, 13))
			t1 := imu.rx
			byte[addr++] := t1
			checksum_running_total += t1
	
	'debug.str(string("getting checksum...", 10, 13))
	checksum := imu.rx << 8
	checksum := checksum | imu.rx
	
	
	
	if checksum <> checksum_running_total
		debug.str(@RECEIVE_PACKET_ERROR)
		debug.str(string("Invalid Checksum: "))
		debug.hex(checksum, 4)
		debug.tx("/")
		debug.hex(checksum_running_total, 4)
		debug.str(string(" (given/calculated)", 10, 13))
		return -1
		

	return addr_i 'return the original value
	
			

PRI VerifyChecksum(addr)




PRI AppendChecksum(addr) | i, data_length, t1
	result := 0
	
'	debug.str(string(13, 10, "Starting Address: $"))
'	debug.hex(addr, 8)
	
	'Check (and add) "snp" string
	repeat i from 1 to 3 '1 to 3 because loopup is not zero based...
		t1 := byte[addr++]
		if t1 <> lookup(i: "s", "n", "p")
			debug.str(@APPEND_CHECKSUM_ERROR)
			debug.str(string("t1 should equal $"))
			debug.hex(lookup(i: "s", "n", "p"), 2)
			debug.str(string(" but is really $"))
			debug.hex(t1, 2)
			debug.tx(10)
			debug.tx(13)
			return -1
		result += t1
	
	
'	debug.str(string(13, 10, "Result == $"))
'	debug.hex(result, 8)
'	
	
	'Evaluate the PT byte
	t1 := byte[addr++]
	result += t1
	
	if (t1 & %1000_0000) == 0
		'then no data (has data bit is 0)
'		debug.str(string(10, 13, "Data bit is set to 0"))
		data_length := 0
	elseif (t1 & %0100_0000) == 0
		'then has data, but no batch, so 4 bytes of data
'		debug.str(string(10, 13, "Single register of data"))
		data_length := 4
	else
		'then has data, is a batch, with length of:
'		debug.str(string(10, 13, "Batch of data..."))
		data_length := 4 * ((t1 & %0011_1100) >> 2)
	
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

	
DAT
	'Debug strings
	APPEND_CHECKSUM_ERROR byte 10, 13, "ERROR: in string passed to AppendChecksum", 10, 13, 0
	RECEIVE_PACKET_ERROR  byte 10, 13, "ERROR: in receiving a packet from UM6", 10, 13, 0
	
	UM6_GET_FW_VERSION byte "snp", %0_0_0000_0_0, $AA, 0, 0, 0   '0 here, but should have a checksum of $1FB
	
	
		  
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
