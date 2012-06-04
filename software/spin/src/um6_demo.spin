{{
--------------------------------------------------------------------------------
Anzhelka Project
(c) 2012

For the latest code and support, please visit:
http://code.anzhelka.com
--------------------------------------------------------------------------------

Title: CHR UM6 IMU Demo Program
Author: Cody Lewis
Date: February 11, 2012

This program shows how to use the um6.spin object.

Required hardware:
--- Propeller Chip
---	CHR UM6 IMU
--- USB to Serial connection



}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

CON
'IO Pins
	DEBUG_TX_PIN  = 30
	DEBUG_RX_PIN  = 31
	
	IMU_RX_PIN = 19 'Note: direction is from Propeller IO port
	IMU_TX_PIN = 18 'Note: direction is from Propeller IO port
	
'Settings

VAR
	byte um6_packet[20] 'Note: maximum size is theoretically 1 (addr) + 1 (length) + 16*4 (data) = 66 bytes

	long	gyro_proc_xy
	long	gyro_proc_z
	long	accel_proc_xy
	long	accel_proc_z
	long	mag_proc_xy
	long	mag_proc_z
	long	euler_phi_theta
	long	euler_psi

	long	quat_ab
	long	quat_cd

	long	temp_debug_stack[30]

OBJ
	debug : "FastFullDuplexSerialPlusBuffer.spin"
'	imu : "FullDuplexSerialPlus.spin"
	imu : "um6.spin"

PUB Main | i, t1, addr, roll, pitch


	imu.add_register($5C, @gyro_proc_xy)
	imu.add_register($5D, @gyro_proc_z)
	imu.add_register($5E, @accel_proc_xy)
	imu.add_register($5F, @accel_proc_z)
	imu.add_register($60, @mag_proc_xy)
	imu.add_register($61, @mag_proc_z)
'	imu.add_register($62, @euler_phi_theta)
	imu.add_register($63, @euler_psi)
	imu.add_register($64, @quat_ab)
	imu.add_register($65, @quat_cd)

	debug.start(DEBUG_RX_PIN, DEBUG_TX_PIN, 0, 115200)
	waitcnt(clkfreq + cnt)
	

	debug.str(string("Starting", 10, 13))
'	debug.str(string("Register count added: "))
'	debug.dec(imu.get_data_count)
'	debug.tx(10)
'	debug.tx(13)

	imu.start(IMU_RX_PIN, IMU_TX_PIN, 0, 115200)

	waitcnt(clkfreq >> 2 + cnt)
	
	cognew(debug_transmit_commands, @temp_debug_stack)
	 
'	repeat
'		debug.hex(quat_ab, 8)
'		debug.tx(" ")
'		debug.hex(quat_cd, 8)
'		debug.tx(10)
'		debug.tx(13)
	 
'	repeat
'		debug.hex(imu.rx, 2)
'		debug.tx(" ")
	
'	imu.str(@UM6_RESET_EKF)	
'	waitcnt(clkfreq >> 2 + cnt)
'	imu.str(@UM6_SET_ACCEL_REF)
'	waitcnt(clkfreq >> 2 + cnt)
'	imu.str(@UM6_SET_MAG_REF)
'	waitcnt(clkfreq >> 2 + cnt)
'	imu.str(@UM6_ZERO_GYROS)


'	repeat
'		debug.hex(euler_phi_theta, 8)
'		debug.tx(9)
'		debug.hex(euler_psi, 8)
'		debug.tx(9)
'		debug.hex(gyro_proc_xy, 8)
'		debug.tx(9)
'		debug.hex(gyro_proc_z, 8)
'		debug.tx(9)
'		debug.hex(accel_proc_xy, 8)
'		debug.tx(9)
'		debug.hex(mag_proc_xy, 8)
'		debug.tx(10)
'		debug.tx(13)
''	
'	
'	AppendChecksum(@UM6_GET_FW_VERSION)
'	repeat i from 0 to 7
'		imu.tx(byte[@UM6_GET_FW_VERSION][i])
		
		
'	repeat
'		debug.tx(imu.rx)
		
'	imu.str(@UM6_GET_FW_VERSION)
'	repeat 75
'		repeat 40
'			debug.tx(imu.rx)', 2)
'			debug.tx(" ")
'		debug.tx(10)
'		debug.tx(13)
'	
'	debug.str(string("Stopping output"))
'	repeat
	
	
'	repeat
'		addr := ReceivePacket(@um6_packet)
'		debug.hex(byte[addr][0], 2)
'		debug.tx(10)
'		debug.tx(13)	

	
'	repeat
'		debug.bin( (euler_phi_theta << 0) >> 24, 8)
'		debug.tx(9)
'		debug.bin( (euler_phi_theta << 8) >> 24, 8)
'		debug.tx(9)
'		debug.bin( (euler_phi_theta << 16) >> 24, 8)
'		debug.tx(9)
'		debug.bin( (euler_phi_theta << 24) >> 24, 8)
'		debug.tx(10)
'		debug.tx(13)
'		

	'Print the received address, ORIGINAL
'	repeat
'		addr := ReceiveOriginalPacket(@um6_packet)
'		
'		if byte[addr][0] > $A9
'			debug.hex(byte[addr][0], 2)
'			debug.str(string(" Command"))
'			debug.tx(10)
'			debug.tx(13)


	debug.str(string("Beginning Display of packets that make it past the filter:",10,13))
	'This repeat loop receives packets and parses them to the terminal
	repeat
		addr := imu.ReceiveFilteredPacket(@um6_packet)
'		if addr <> @um6_packet
'			debug.str(string("Error in the return address from ReceivePacket: "))
'			debug.hex(addr, 8)
'			debug.tx("/")
'			debug.hex(@um6_packet, 8)
'			debug.str(string(" (given/expected)", 10, 13))
'		else
'			debug.str(string("Addr: $"))
'			debug.hex(byte[addr][0], 2)
'			debug.str(string(9, "Data($"))
'			debug.hex(byte[addr][1], 2)
'			debug.str(string("): "))
'			repeat i from 0 to byte[addr][1]-1
'				debug.hex(byte[addr][2+i], 2)
'				debug.tx(" ")
'			debug.tx(10)
'			debug.tx(13)

		debug.str(string("Addr: $"))
		debug.hex(byte[addr][0], 2)
		debug.str(string(9, "Data[$"))
		debug.hex(byte[addr][1], 2)
		debug.str(string("]: "))
		repeat i from 0 to byte[addr][1]-1
			debug.hex(byte[addr][2+i], 2)
			debug.tx(" ")
		debug.tx(10)
		debug.tx(13)

	repeat
		roll  := (euler_phi_theta & $FFFF0000) ~> 16
		pitch := (euler_phi_theta << 16) ~> 16
		debug.str(string("Roll: "))
		debug.dec(roll)
		debug.str(string(9, "Pitch: "))
		debug.dec(pitch)
		debug.tx(10)
		debug.tx(13)


'-----------------------------------------------------------------------
	debug.str(string("Hello..."))
	repeat
		'debug.str(string("Receive packet"))
		addr := imu.ReceiveFilteredPacket(@um6_packet)
		if addr <> @um6_packet
			debug.str(string("Error in the return address from ReceivePacket: "))
			debug.hex(addr, 8)
			debug.tx("/")
			debug.hex(@um6_packet, 8)
			debug.str(string(" (given/expected)", 10, 13))
		else
			'debug.str(string("New packet! "))
			'debug.str(string("Type: $"))
'			debug.hex(byte[addr][0], 2)
			'debug.str(string(9, "Length: $"))
'			debug.hex(byte[addr][1], 2)
'			debug.dec(imu.get_data_count)
'			debug.tx(10)
'			debug.tx(13)
			
						
'			'Display the roll and pitch using the spin based parser
			if byte[addr][0] == $62
				debug.str(string(" Euler roll: "))
				pitch := (((byte[addr][4] << 8) | byte[addr][5]) << 16) ~> 16 'The 16 shift is for the sign extend
				roll := (((byte[addr][2] << 8) | byte[addr][3]) << 16) ~> 16 'The 16 shift is for the sign extend
				debug.dec(roll)
				debug.tx(" ")
				
				debug.bin(byte[addr][2], 8)
				debug.tx(" ")
				debug.bin(byte[addr][3], 8)
				
				debug.str(string(" pitch: "))
				debug.dec(pitch)
				debug.tx(" ")
				debug.bin(byte[addr][4], 8)
				debug.tx(" ")
				debug.bin(byte[addr][5], 8)
				debug.tx(10)
				debug.tx(13)

	

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
				
				
			
				
				
PRI debug_transmit_commands	
	repeat	
		imu.str(@UM6_GET_FW_VERSION)
		waitcnt(clkfreq * 5 + cnt)
		imu.str(@UM6_RESET_EKF)	
		waitcnt(clkfreq * 5 + cnt)
		imu.str(@UM6_SET_ACCEL_REF)
		waitcnt(clkfreq * 5 + cnt)
		imu.str(@UM6_SET_MAG_REF)
		waitcnt(clkfreq * 5 + cnt)
		imu.str(@UM6_ZERO_GYROS)
		waitcnt(clkfreq * 5 + cnt)

	
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
