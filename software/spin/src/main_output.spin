{{
--------------------------------------------------------------------------------
Anzhelka Project
(c) 2012

For the latest code and support, please visit:
http://code.anzhelka.com
--------------------------------------------------------------------------------

Title: main.spin
Author: Cody Lewis
Date: 28 May 2012
Notes: This is the top level file for the Anzhelka quadrotor project.

Notes:
	--- If a '?' is received for any of the numbers, that means that it couldn't be translated (ie, not float, not int, ?)

TODO
	--- n_i needs to be converted from RPM input to whatever units it needs to be in for the PID...

}}
CON
	_clkmode = xtal1 + pll16x
	_xinfreq = 5_000_000

'IO Pins
	DEBUG_TX_PIN  = 30
	DEBUG_RX_PIN  = 31
	
	CLOCK_PIN = 20 'Unconnected to anything else
	
	MOTOR_1_PIN = 16 'NUMBER FOR TESTING
	MOTOR_2_PIN = 17 'NUMBER FOR TESTING
	MOTOR_3_PIN = 18 'NUMBER FOR TESTING
	MOTOR_4_PIN = 19 'NUMBER FOR TESTING
	
	
'Settings
	'Port names for Full Duplex Serial 4 port Plus
'	PDEBUG = 0 'Debug port
	SERIAL_BAUD = 115200

	'System Clock settings
	FREQ_VALUE = $0001_0000
	FREQ_COUNTS = 65536 '2^n, where n is the number of freq1's needed before overflow
	
	
	'Motor lower limits
	MOTOR_ZERO = 1000
	MOTOR_SIZE = 1000 'The range, in uS, from smallest value to highest value
	
VAR
	long seconds_multiplier

OBJ
	serial	:   "FastFullDuplexSerialPlusBuffer.spin"
	fp		:	"F32_CMD.spin"
	pwm 	:	"PWM_32_v4.spin"
	
	PID_M_x	: "PID_data.spin"
	PID_M_y	: "PID_data.spin"
	PID_M_z	: "PID_data.spin"
	PID_F_z	: "PID_data.spin"
	PID_n_1	: "PID_data.spin"
	PID_n_2	: "PID_data.spin"
	PID_n_3	: "PID_data.spin"
	PID_n_4	: "PID_data.spin"
	
	
PUB Main | t1
	
	pwm.start
	pwm.servo(MOTOR_1_PIN, MOTOR_ZERO)
	pwm.servo(MOTOR_2_PIN, MOTOR_ZERO)
	pwm.servo(MOTOR_3_PIN, MOTOR_ZERO)
	pwm.servo(MOTOR_4_PIN, MOTOR_ZERO)
	
	fp.start
	InitClock
	InitUart
	InitPID

	repeat
		ParseSerial
	
'	repeat
'		serial.str(string(10, 13, "Type in a number here:"))
'		t1 := serial.GetDec(",")
'		serial.bin(t1, 8)
'		
	
	repeat
		Calculate
		pwm.servo(MOTOR_1_PIN, u_1)
		pwm.servo(MOTOR_2_PIN, u_2)
		pwm.servo(MOTOR_3_PIN, u_3)
		pwm.servo(MOTOR_4_PIN, u_4)
		ParseSerial


'-------------------------------------------------------------------
'-------------------------------------------------------------------
'----------------- $ATXXX Input Functions --------------------------
'-------------------------------------------------------------------
'-------------------------------------------------------------------

PUB ParseSerial | t1, rxdata
' Master Serial Parsing Function

	'Wait for start character
	repeat
		t1 := serial.rxcheck
		if t1 == -1
			return
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

CON
	sSDR = ("S" << 16) | ("D" << 8) | "R"
PUB ParseSerialCommand | t1, t2, t3, command
''Parses packets of the form "$ACXXX ...", ie command packets
	
	'Get three letter packet type
	command := serial.rx
	command := (command << 8) | serial.rx
	command := (command << 8) | serial.rx
	
	'Decide what to do based on three letter packet type:
	case command
		sSDR:
			ParseSerialSDR
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
'	 = ("" << 16) | ("" << 8) | ""

	NAN = $7FFF_FFFF
	 
PUB ParseSerialSDR | register, values[10], i
'Note: this sets a maximum number of values (up to ten longs)
'This packet will inject the received values into the appropriate variables.

	'Discard spaces, and then get first letter
	repeat
	while (register := serial.rx) == " " 'Ignore spaces
	
	'Get second and third letters
	register := (register << 8) | serial.rx
	register := (register << 8) | serial.rx
	
	'Ignore the following comma
	serial.rx

	case register
		sPWM:
			ParseSerialList(@values, 4, TYPE_INT)
		sMKP:
'			serial.str(string(10, 13))
'			PrintStr(string("Parsing MKP"))
			ParseSerialList(@values, 4, TYPE_FLOAT)
			WriteList(@values, PID_n_1.getKpAddr, PID_n_2.getKpAddr, PID_n_3.getKpAddr, PID_n_4.getKpAddr)
			PrintArrayAddr(string("MKP"), PID_n_1.getKpAddr, PID_n_2.getKpAddr, PID_n_3.getKpAddr, PID_n_4.getKpAddr, TYPE_FLOAT)

		sMKI:
'			serial.str(string(10, 13))
'			PrintStr(string("Parsing MKI"))
			ParseSerialList(@values, 4, TYPE_FLOAT)
			WriteList(@values, PID_n_1.getKiAddr, PID_n_2.getKiAddr, PID_n_3.getKiAddr, PID_n_4.getKiAddr)
			PrintArrayAddr(string("MKI"), PID_n_1.getKiAddr, PID_n_2.getKiAddr, PID_n_3.getKiAddr, PID_n_4.getKiAddr, TYPE_FLOAT)
			
		sMKD:
			ParseSerialList(@values, 4, TYPE_FLOAT)
			WriteList(@values, PID_n_1.getKdAddr, PID_n_2.getKdAddr, PID_n_3.getKdAddr, PID_n_4.getKdAddr)
			PrintArrayAddr(string("MKD"), PID_n_1.getKdAddr, PID_n_2.getKdAddr, PID_n_3.getKdAddr, PID_n_4.getKdAddr, TYPE_FLOAT)

		OTHER:
			PrintStrStart
			serial.str(string("Warning: Unknown register type: "))
			register := (register & $FF) << 16 | (register & $FF00) | (register & $FF_0000) >> 16
			serial.str(@register) 'TODO: this won't output the ascii letters of the string, need to fix
			serial.hex(register, 8)
			serial.tx(")")
			PrintStrStop
			
			

PUB WriteList(input_array_addr, a_addr, b_addr, c_addr, d_addr)
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

PUB PrintArrayAddr(type_string_addr, a_addr, b_addr, c_addr, d_addr, type) | i
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
		
PUB PrintStr(addr)
	serial.str(string("$ADSTR "))
	serial.dec(phsb)
	serial.tx(",")
	serial.tx("'")
	serial.str(addr)
	serial.str(string("'", 10, 13))
	
PUB PrintStrStart
	serial.str(string("$ADSTR "))
	serial.dec(phsb)
	serial.tx(",")
	serial.tx("'")
	
PUB PrintStrStop
	serial.str(string("'", 10, 13))

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

PUB InitPID
'	PID_M_x.setOutput_addr()
'	PID_M_x.setInput_addr()
'	PID_M_X.setSetpoint_addr()
'	
'	PID_M_y.setOutput_addr()
'	PID_M_y.setInput_addr()
'	PID_M_y.setSetpoint_addr()
'	
'	PID_M_z.setOutput_addr()
'	PID_M_z.setInput_addr()
'	PID_M_z.setSetpoint_addr()
	
'	PID_F_z.setOutput_addr()
'	PID_F_z.setInput_addr(@Current_altitude)
'	PID_F_z.setSetpoint_addr(@Desired_altitude)
'	
	PID_n_1.setOutput_addr(@u_1)
	PID_n_1.setInput_addr(@n_1)
	PID_n_1.setSetpoint_addr(@n_d_1)
	PID_n_1.setOutmin(fp.FFloat(MOTOR_ZERO))
	PID_n_1.setOutmax(fp.FFloat(MOTOR_ZERO + MOTOR_SIZE))
	
	PID_n_2.setOutput_addr(@u_2)
	PID_n_2.setInput_addr(@n_2)
	PID_n_2.setSetpoint_addr(@n_d_2)
	PID_n_2.setOutmin(fp.FFloat(MOTOR_ZERO))
	PID_n_2.setOutmax(fp.FFloat(MOTOR_ZERO + MOTOR_SIZE))
	
	PID_n_3.setOutput_addr(@u_3)
	PID_n_3.setInput_addr(@n_3)
	PID_n_3.setSetpoint_addr(@n_d_3)
	PID_n_3.setOutmin(fp.FFloat(MOTOR_ZERO))
	PID_n_3.setOutmax(fp.FFloat(MOTOR_ZERO + MOTOR_SIZE))
	
	PID_n_4.setOutput_addr(@u_4)
	PID_n_4.setInput_addr(@n_4)
	PID_n_4.setSetpoint_addr(@n_d_4)
	PID_n_4.setOutmin(fp.FFloat(MOTOR_ZERO))
	PID_n_4.setOutmax(fp.FFloat(MOTOR_ZERO + MOTOR_SIZE))

PUB InitUart | extra
	serial.start(DEBUG_RX_PIN, DEBUG_TX_PIN, 0, SERIAL_BAUD)	
	waitcnt(clkfreq + cnt)
	PrintStr(string("Starting..."))
	
PUB InitClock
' sets pin as output
	DIRA[CLOCK_PIN]~~
	CTRa := %00100<<26 + CLOCK_PIN           ' set oscillation mode on pin
	FRQa := FREQ_VALUE                    ' set FRequency of first counter                   

	CTRB := %01010<<26 + CLOCK_PIN           ' at every zero crossing add 1 to phsb
	FRQB := 1

'-------------------------------------------------------------------
'-------------------------------------------------------------------
'----------------- Control Loop Functionality ----------------------
'-------------------------------------------------------------------
'-------------------------------------------------------------------

DAT
'***************************************************
'*********** MOMENT BLOCK **************************
'***************************************************
'Moment I/O Variables

			long	0, 0
omega_b_x	long 0
omega_b_y	long 0
omega_b_z	long 0
	
			long 0, 0
q_0			long 0
q_1			long 0
q_2			long 0
q_3			long 0

			long 0, 0
q_d_0		long 0
q_d_1		long 0
q_d_2		long 0
q_d_3		long 0

			long 0, 0
M_x			long 0
M_y			long 0
M_z			long 0
	
'Moment Intermediate Variables
	

			long 0, 0
alpha		long 0


			long 0, 0
alpha_H		long 0

			long 0, 0
beta_h		long 0


			long 0, 0
phi			long 0

			long 0, 0
q_temp_0	long 0
q_temp_1	long 0
q_temp_2	long 0
q_temp_3	long 0


			long 0, 0
q_tilde_0	long 0
q_tilde_1	long 0
q_tilde_2	long 0
q_tilde_3	long 0

			long 0, 0
q_tilde_b_0	long 0
q_tilde_b_1 long 0
q_tilde_b_2	long 0
q_tilde_b_3	long 0


			long 0, 0
r_b_1		long 0
r_b_2		long 0
r_b_3		long 0

			long 0, 0
r_e_1		long 0
r_e_2		long 0
r_e_3		long 0


			long 0, 0
r_x			long 0
r_y			long 0


'***************************************************
'*********** MOTOR BLOCK ***************************
'***************************************************


			long 0, 0
K_Q			long 0
			long 0, 0
K_T			long 0

			long 0, 0
diameter	long 0		'D in the documentation

			long 0, 0
offset		long 0		'd in the documentation

			long 0, 0
c			long 0

			long 0, 0
F_z			long 0


			long 0, 0
F_1			long 0
F_2			long 0
F_3			long 0
F_4			long 0

			long 0, 0
rho			long 0		'Air density

			long 0, 0
omega_d_1	long 0
			long 0, 0
omega_d_2	long 0
			long 0, 0
omega_d_3	long 0
			long 0, 0
omega_d_4	long 0


			long 0, 0
n_1			long 0
			long 0, 0
n_2			long 0
			long 0, 0
n_3			long 0
			long 0, 0
n_4			long 0



			long 0, 0
n_d_1		long 0
			long 0, 0
n_d_2		long 0
			long 0, 0
n_d_3		long 0
			long 0, 0
n_d_4		long 0


			long 0, 0
u_1			long 0
			long 0, 0
u_2			long 0
			long 0, 0
u_3			long 0
			long 0, 0
u_4			long 0


			long 0, 0
const_2_pi	long 0


'			long 0, 0
'n_1			long 0
'			long 0, 0
'n_2			long 0
'			long 0, 0
'n_3			long 0
'			long 0, 0
'n_4			long 0



'***************************************************
'*********** WORKING VARIABLES *********************
'***************************************************

t_1			long 0
t_2			long 0
t_3			long 0
t_4			long 0
t_5			long 0






	
	
PUB Calculate
'One iteration of the calculations
'Should be called from a repeat loop...
'Writes object local variables, does not write to address
	
	fp.FInterpret(@CONTROL_LOOP_INSTRUCTIONS)
	

DAT

'tenf is for the StringToFloat function
tenf    long  1e+00, 1e-01, 1e-02, 1e-03, 1e-04, 1e-05, 1e-06, 1e-07, 1e-08, 1e-09
        long  1e-10, 1e-11, 1e-12, 1e-13, 1e-14, 1e-15, 1e-16, 1e-17, 1e-18, 1e-19
        long  1e-20, 1e-21, 1e-22, 1e-23, 1e-24, 1e-25, 1e-26, 1e-27, 1e-28, 1e-29
        long  1e-30, 1e-31, 1e-32, 1e-33, 1e-34, 1e-35, 1e-36, 1e-37, 1e-38
	
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

'=========================================


CON
	CONTROL_LOOP_INDEX = 0

VAR
	long CONTROL_LOOP_INSTRUCTIONS[(4 * 166) + 1]
	long azm_temp_0
	long azm_temp_1
	long azm_temp_2
	long azm_temp_3
	long azm_temp_4
	long azm_temp_5
	long const_0
	long const_1
	long const_2
	long const_4
	long const_pi

PUB Init_Instructions

	fp.AddSequence(CONTROL_LOOP_INDEX, @CONTROL_LOOP_Instructions)

	const_0 := float(0)
	const_1 := float(1)
	const_2 := float(2)
	const_4 := float(4)
	const_pi := pi'***************************************************
'*********** MOMENT BLOCK **************************
'***************************************************
'q star:

'------------
'' q_1 = 0 - q_1
	'q_1 = @const_0 - @q_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @const_0, @q_1, @q_1)

'------------
'' q_2 = 0 - q_2
	'q_2 = @const_0 - @q_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @const_0, @q_2, @q_2)

'------------
'' q_3 = 0 - q_3
	'q_3 = @const_0 - @q_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @const_0, @q_3, @q_3)
'Moment Block, first Quat Mul

'------------
'' q_tilde_0 = ((q_d_0*q_0) - (q_d_1*q_1)) - ((q_d_2*q_2) - (q_d_3*q_3))
	'azm_temp_0 = @q_d_0 * @q_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_0, @q_0, @azm_temp_0)
	'azm_temp_1 = @q_d_1 * @q_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_1, @q_1, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 - @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_d_2 * @q_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_2, @q_2, @azm_temp_3)
	'azm_temp_4 = @q_d_3 * @q_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_3, @q_3, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 - @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'q_tilde_0 = @azm_temp_2 - @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_2, @azm_temp_5, @q_tilde_0)

'------------
'' q_tilde_1 = ((q_d_0*q_1) + (q_d_1*q_0)) + ((q_d_2*q_3) - (q_d_3*q_2))
	'azm_temp_0 = @q_d_0 * @q_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_0, @q_1, @azm_temp_0)
	'azm_temp_1 = @q_d_1 * @q_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_1, @q_0, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 + @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_d_2 * @q_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_2, @q_3, @azm_temp_3)
	'azm_temp_4 = @q_d_3 * @q_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_3, @q_2, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 - @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'q_tilde_1 = @azm_temp_2 + @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_2, @azm_temp_5, @q_tilde_1)

'------------
'' q_tilde_2 = ((q_d_0*q_2) - (q_d_1*q_3)) + ((q_d_2*q_0) + (q_d_3*q_1))
	'azm_temp_0 = @q_d_0 * @q_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_0, @q_2, @azm_temp_0)
	'azm_temp_1 = @q_d_1 * @q_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_1, @q_3, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 - @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_d_2 * @q_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_2, @q_0, @azm_temp_3)
	'azm_temp_4 = @q_d_3 * @q_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_3, @q_1, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 + @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'q_tilde_2 = @azm_temp_2 + @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_2, @azm_temp_5, @q_tilde_2)

'------------
'' q_tilde_3 = ((q_d_0*q_3) + (q_d_1*q_2)) - ((q_d_2*q_1) + (q_d_3*q_0))
	'azm_temp_0 = @q_d_0 * @q_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_0, @q_3, @azm_temp_0)
	'azm_temp_1 = @q_d_1 * @q_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_1, @q_2, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 + @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_d_2 * @q_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_2, @q_1, @azm_temp_3)
	'azm_temp_4 = @q_d_3 * @q_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_d_3, @q_0, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 + @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'q_tilde_3 = @azm_temp_2 - @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_2, @azm_temp_5, @q_tilde_3)

'------------
'' alpha = 2 * (q_tilde_0 arc_c 0)
	'azm_temp_0 = @q_tilde_0 arc_c @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPACos, @q_tilde_0, @const_0, @azm_temp_0)
	'alpha = @const_2 * @azm_temp_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @const_2, @azm_temp_0, @alpha)

'------------
'' t_1 = (alpha / 2) sin 0
	'azm_temp_0 = @alpha / @const_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @alpha, @const_2, @azm_temp_0)
	't_1 = @azm_temp_0 sin @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSin, @azm_temp_0, @const_0, @t_1)

'------------
'' r_e_1 = q_tilde_1 / t_1
	'r_e_1 = @q_tilde_1 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_tilde_1, @t_1, @r_e_1)

'------------
'' r_e_2 = q_tilde_2 / t_1
	'r_e_2 = @q_tilde_2 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_tilde_2, @t_1, @r_e_2)

'------------
'' r_e_3 = q_tilde_3 / t_1
	'r_e_3 = @q_tilde_3 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_tilde_3, @t_1, @r_e_3)
'Moment Block, r_b first (lhs) quat mult:

'------------
'' q_temp_0 = ((q_0*0) - (q_1*r_e_1)) - ((q_2*r_e_2) - (q_3*r_e_3))
	'azm_temp_0 = @q_0 * @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_0, @const_0, @azm_temp_0)
	'azm_temp_1 = @q_1 * @r_e_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_1, @r_e_1, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 - @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_2 * @r_e_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_2, @r_e_2, @azm_temp_3)
	'azm_temp_4 = @q_3 * @r_e_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_3, @r_e_3, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 - @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'q_temp_0 = @azm_temp_2 - @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_2, @azm_temp_5, @q_temp_0)

'------------
'' q_temp_1 = ((q_0*r_e_1) + (q_1*0)) + ((q_2*r_e_3) - (q_3*r_e_2))
	'azm_temp_0 = @q_0 * @r_e_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_0, @r_e_1, @azm_temp_0)
	'azm_temp_1 = @q_1 * @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_1, @const_0, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 + @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_2 * @r_e_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_2, @r_e_3, @azm_temp_3)
	'azm_temp_4 = @q_3 * @r_e_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_3, @r_e_2, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 - @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'q_temp_1 = @azm_temp_2 + @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_2, @azm_temp_5, @q_temp_1)

'------------
'' q_temp_2 = ((q_0*r_e_2) - (q_1*r_e_3)) + ((q_2*0) + (q_3*r_e_1))
	'azm_temp_0 = @q_0 * @r_e_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_0, @r_e_2, @azm_temp_0)
	'azm_temp_1 = @q_1 * @r_e_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_1, @r_e_3, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 - @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_2 * @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_2, @const_0, @azm_temp_3)
	'azm_temp_4 = @q_3 * @r_e_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_3, @r_e_1, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 + @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'q_temp_2 = @azm_temp_2 + @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_2, @azm_temp_5, @q_temp_2)

'------------
'' q_temp_3 = ((q_0*r_e_3) + (q_1*r_e_2)) - ((q_2*r_e_1) + (q_3*0))
	'azm_temp_0 = @q_0 * @r_e_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_0, @r_e_3, @azm_temp_0)
	'azm_temp_1 = @q_1 * @r_e_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_1, @r_e_2, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 + @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_2 * @r_e_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_2, @r_e_1, @azm_temp_3)
	'azm_temp_4 = @q_3 * @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_3, @const_0, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 + @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'q_temp_3 = @azm_temp_2 - @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_2, @azm_temp_5, @q_temp_3)
'q star:

'------------
'' q_1 = 0 - q_1
	'q_1 = @const_0 - @q_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @const_0, @q_1, @q_1)

'------------
'' q_2 = 0 - q_2
	'q_2 = @const_0 - @q_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @const_0, @q_2, @q_2)

'------------
'' q_3 = 0 - q_3
	'q_3 = @const_0 - @q_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @const_0, @q_3, @q_3)
'Moment Block, r_b second (rhs) quat mult:
'0 = ((q_temp_0*q_0) - (q_temp_1*q_1)) - ((q_temp_2*q_2) - (q_temp_3*q_3))

'------------
'' r_b_1 = ((q_temp_0*q_1) + (q_temp_1*q_0)) + ((q_temp_2*q_3) - (q_temp_3*q_2))
	'azm_temp_0 = @q_temp_0 * @q_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_temp_0, @q_1, @azm_temp_0)
	'azm_temp_1 = @q_temp_1 * @q_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_temp_1, @q_0, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 + @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_temp_2 * @q_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_temp_2, @q_3, @azm_temp_3)
	'azm_temp_4 = @q_temp_3 * @q_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_temp_3, @q_2, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 - @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'r_b_1 = @azm_temp_2 + @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_2, @azm_temp_5, @r_b_1)

'------------
'' r_b_2 = ((q_temp_0*q_2) - (q_temp_1*q_3)) + ((q_temp_2*q_0) + (q_temp_3*q_1))
	'azm_temp_0 = @q_temp_0 * @q_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_temp_0, @q_2, @azm_temp_0)
	'azm_temp_1 = @q_temp_1 * @q_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_temp_1, @q_3, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 - @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_temp_2 * @q_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_temp_2, @q_0, @azm_temp_3)
	'azm_temp_4 = @q_temp_3 * @q_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_temp_3, @q_1, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 + @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'r_b_2 = @azm_temp_2 + @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_2, @azm_temp_5, @r_b_2)

'------------
'' r_b_3 = ((q_temp_0*q_3) + (q_temp_1*q_2)) - ((q_temp_2*q_1) + (q_temp_3*q_0))
	'azm_temp_0 = @q_temp_0 * @q_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_temp_0, @q_3, @azm_temp_0)
	'azm_temp_1 = @q_temp_1 * @q_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_temp_1, @q_2, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 + @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_temp_2 * @q_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_temp_2, @q_1, @azm_temp_3)
	'azm_temp_4 = @q_temp_3 * @q_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_temp_3, @q_0, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 + @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'r_b_3 = @azm_temp_2 - @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_2, @azm_temp_5, @r_b_3)

'------------
'' q_tilde_b_0 = (alpha / 2) sin 0
	'azm_temp_0 = @alpha / @const_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @alpha, @const_2, @azm_temp_0)
	'q_tilde_b_0 = @azm_temp_0 sin @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSin, @azm_temp_0, @const_0, @q_tilde_b_0)

'------------
'' q_tilde_b_1 = t_1 * r_b_1
	'q_tilde_b_1 = @t_1 * @r_b_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_1, @r_b_1, @q_tilde_b_1)

'------------
'' q_tilde_b_2 = t_1 * r_b_2
	'q_tilde_b_2 = @t_1 * @r_b_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_1, @r_b_2, @q_tilde_b_2)

'------------
'' q_tilde_b_3 = t_1 * r_b_3
	'q_tilde_b_3 = @t_1 * @r_b_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_1, @r_b_3, @q_tilde_b_3)

'------------
'' alpha_H =  (1- (2 * ((q_1 * q_1) + (q_2 * q_2)))) arc_c 0
	'azm_temp_0 = @q_1 * @q_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_1, @q_1, @azm_temp_0)
	'azm_temp_1 = @q_2 * @q_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_2, @q_2, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 + @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @const_2 * @azm_temp_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @const_2, @azm_temp_2, @azm_temp_3)
	'azm_temp_4 = @const_1 - @azm_temp_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @const_1, @azm_temp_3, @azm_temp_4)
	'alpha_H = @azm_temp_4 arc_c @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPACos, @azm_temp_4, @const_0, @alpha_H)

'------------
'' phi = 2 * (q_3 arc_t2 q_0)
	'azm_temp_0 = @q_3 arc_t2 @q_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPATan2, @q_3, @q_0, @azm_temp_0)
	'phi = @const_2 * @azm_temp_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @const_2, @azm_temp_0, @phi)

'------------
'' t_1 = (phi / 2) cos 0
	'azm_temp_0 = @phi / @const_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @phi, @const_2, @azm_temp_0)
	't_1 = @azm_temp_0 cos @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPCos, @azm_temp_0, @const_0, @t_1)

'------------
'' t_2 = (phi / 2) sin 0
	'azm_temp_0 = @phi / @const_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @phi, @const_2, @azm_temp_0)
	't_2 = @azm_temp_0 sin @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSin, @azm_temp_0, @const_0, @t_2)

'------------
'' t_3 = (alpha_H / 2) sin 0
	'azm_temp_0 = @alpha_H / @const_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @alpha_H, @const_2, @azm_temp_0)
	't_3 = @azm_temp_0 sin @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSin, @azm_temp_0, @const_0, @t_3)

'------------
'' r_x = ((t_1 * q_1) - (t_2 * q_2)) / t_3
	'azm_temp_0 = @t_1 * @q_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_1, @q_1, @azm_temp_0)
	'azm_temp_1 = @t_2 * @q_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_2, @q_2, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 - @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'r_x = @azm_temp_2 / @t_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @azm_temp_2, @t_3, @r_x)

'------------
'' r_y = ((t_2 * q_1) - (t_1 * q_2)) / t_3
	'azm_temp_0 = @t_2 * @q_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_2, @q_1, @azm_temp_0)
	'azm_temp_1 = @t_1 * @q_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_1, @q_2, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 - @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'r_y = @azm_temp_2 / @t_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @azm_temp_2, @t_3, @r_y)

'------------
'' beta_H = r_y arc_t2 r_x
	'beta_H = @r_y arc_t2 @r_x
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPATan2, @r_y, @r_x, @beta_H)
'***************************************************
'*********** MOTOR BLOCK ***************************
'***************************************************

'------------
'' t_5 = 2 * offset
	't_5 = @const_2 * @offset
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @const_2, @offset, @t_5)

'------------
'' const_2_pi = 2 * pi
	'const_2_pi = @const_2 * @const_pi
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @const_2, @const_pi, @const_2_pi)

'------------
'' c = (K_Q * diameter) / K_T
	'azm_temp_0 = @K_Q * @diameter
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @K_Q, @diameter, @azm_temp_0)
	'c = @azm_temp_0 / @K_T
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @azm_temp_0, @K_T, @c)

'------------
'' t_1 = M_z / (4*c)
	'azm_temp_0 = @const_4 * @c
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @const_4, @c, @azm_temp_0)
	't_1 = @M_z / @azm_temp_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @M_z, @azm_temp_0, @t_1)

'------------
'' t_2 = M_y / t_5
	't_2 = @M_y / @t_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @M_y, @t_5, @t_2)

'------------
'' t_3 = M_x / t_5
	't_3 = @M_x / @t_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @M_x, @t_5, @t_3)

'------------
'' t_4 = F_z / 4
	't_4 = @F_z / @const_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @F_z, @const_4, @t_4)

'------------
'' F_1 = (t_4 + (t_1 - t_2)) #> 0
	'azm_temp_0 = @t_1 - @t_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @t_1, @t_2, @azm_temp_0)
	'azm_temp_1 = @t_4 + @azm_temp_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @t_4, @azm_temp_0, @azm_temp_1)
	'F_1 = @azm_temp_1 #> @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPLimitMin, @azm_temp_1, @const_0, @F_1)

'------------
'' F_2 = (t_4 - (t_1 + t_3)) #> 0
	'azm_temp_0 = @t_1 + @t_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @t_1, @t_3, @azm_temp_0)
	'azm_temp_1 = @t_4 - @azm_temp_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @t_4, @azm_temp_0, @azm_temp_1)
	'F_2 = @azm_temp_1 #> @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPLimitMin, @azm_temp_1, @const_0, @F_2)

'------------
'' F_3 = (t_4 + (t_1 + t_2)) #> 0
	'azm_temp_0 = @t_1 + @t_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @t_1, @t_2, @azm_temp_0)
	'azm_temp_1 = @t_4 + @azm_temp_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @t_4, @azm_temp_0, @azm_temp_1)
	'F_3 = @azm_temp_1 #> @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPLimitMin, @azm_temp_1, @const_0, @F_3)

'------------
'' F_4 = (t_4 + (t_3 - t_1)) #> 0
	'azm_temp_0 = @t_3 - @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @t_3, @t_1, @azm_temp_0)
	'azm_temp_1 = @t_4 + @azm_temp_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @t_4, @azm_temp_0, @azm_temp_1)
	'F_4 = @azm_temp_1 #> @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPLimitMin, @azm_temp_1, @const_0, @F_4)

'------------
'' t_1 = const_2_pi / (diameter * diameter)
	'azm_temp_0 = @diameter * @diameter
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @diameter, @diameter, @azm_temp_0)
	't_1 = @const_pi / @azm_temp_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @const_pi, @azm_temp_0, @t_1)

'------------
'' t_2 = rho * K_T
	't_2 = @rho * @K_T
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @rho, @K_T, @t_2)

'------------
'' omega_d_1 = t_1 * ((F_1 / t_2) sqrt 0)
	'azm_temp_0 = @F_1 / @t_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @F_1, @t_2, @azm_temp_0)
	'azm_temp_1 = @azm_temp_0 sqrt @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSqr, @azm_temp_0, @const_0, @azm_temp_1)
	'omega_d_1 = @t_1 * @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_1, @azm_temp_1, @omega_d_1)

'------------
'' omega_d_2 = t_1 * ((F_2 / t_2) sqrt 0)
	'azm_temp_0 = @F_2 / @t_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @F_2, @t_2, @azm_temp_0)
	'azm_temp_1 = @azm_temp_0 sqrt @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSqr, @azm_temp_0, @const_0, @azm_temp_1)
	'omega_d_2 = @t_1 * @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_1, @azm_temp_1, @omega_d_2)

'------------
'' omega_d_3 = t_1 * ((F_3 / t_2) sqrt 0)
	'azm_temp_0 = @F_3 / @t_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @F_3, @t_2, @azm_temp_0)
	'azm_temp_1 = @azm_temp_0 sqrt @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSqr, @azm_temp_0, @const_0, @azm_temp_1)
	'omega_d_3 = @t_1 * @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_1, @azm_temp_1, @omega_d_3)

'------------
'' omega_d_4 = t_1 * ((F_4 / t_2) sqrt 0)
	'azm_temp_0 = @F_4 / @t_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @F_4, @t_2, @azm_temp_0)
	'azm_temp_1 = @azm_temp_0 sqrt @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSqr, @azm_temp_0, @const_0, @azm_temp_1)
	'omega_d_4 = @t_1 * @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_1, @azm_temp_1, @omega_d_4)

'------------
'' n_d_1 = omega_d_1 / const_2_pi
	'n_d_1 = @omega_d_1 / @const_pi
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @omega_d_1, @const_pi, @n_d_1)

'------------
'' n_d_2 = omega_d_2 / const_2_pi
	'n_d_2 = @omega_d_2 / @const_pi
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @omega_d_2, @const_pi, @n_d_2)

'------------
'' n_d_3 = omega_d_3 / const_2_pi
	'n_d_3 = @omega_d_3 / @const_pi
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @omega_d_3, @const_pi, @n_d_3)

'------------
'' n_d_4 = omega_d_4 / const_2_pi
	'n_d_4 = @omega_d_4 / @const_pi
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @omega_d_4, @const_pi, @n_d_4)
'PID Section, with truncation (||)

'------------
'' u_1 = (PID_n_1.getBase ~ 0) || 0
	'azm_temp_0 = PID_n_1.getBase ~ @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPPID, PID_n_1.getBase, @const_0, @azm_temp_0)
	'u_1 = @azm_temp_0 || @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPTruncRound, @azm_temp_0, @const_0, @u_1)

'------------
'' u_2 = (PID_n_2.getBase ~ 0) || 0
	'azm_temp_0 = PID_n_2.getBase ~ @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPPID, PID_n_2.getBase, @const_0, @azm_temp_0)
	'u_2 = @azm_temp_0 || @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPTruncRound, @azm_temp_0, @const_0, @u_2)

'------------
'' u_3 = (PID_n_3.getBase ~ 0) || 0
	'azm_temp_0 = PID_n_3.getBase ~ @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPPID, PID_n_3.getBase, @const_0, @azm_temp_0)
	'u_3 = @azm_temp_0 || @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPTruncRound, @azm_temp_0, @const_0, @u_3)

'------------
'' u_4 = (PID_n_4.getBase ~ 0) || 0
	'azm_temp_0 = PID_n_4.getBase ~ @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPPID, PID_n_4.getBase, @const_0, @azm_temp_0)
	'u_4 = @azm_temp_0 || @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPTruncRound, @azm_temp_0, @const_0, @u_4)
'All variables that are used or created:
'	long @F_1
'	long @F_2
'	long @F_3
'	long @F_4
'	long @F_z
'	long @K_Q
'	long @K_T
'	long @M_x
'	long @M_y
'	long @M_z
'	long @alpha
'	long @alpha_H
'	long @azm_temp_0
'	long @azm_temp_1
'	long @azm_temp_2
'	long @azm_temp_3
'	long @azm_temp_4
'	long @azm_temp_5
'	long @c
'	long @const_0
'	long @const_1
'	long @const_2
'	long @const_4
'	long @const_pi
'	long @diameter
'	long @offset
'	long @omega_d_1
'	long @omega_d_2
'	long @omega_d_3
'	long @omega_d_4
'	long @phi
'	long @q_0
'	long @q_1
'	long @q_2
'	long @q_3
'	long @q_d_0
'	long @q_d_1
'	long @q_d_2
'	long @q_d_3
'	long @q_temp_0
'	long @q_temp_1
'	long @q_temp_2
'	long @q_temp_3
'	long @q_tilde_0
'	long @q_tilde_1
'	long @q_tilde_2
'	long @q_tilde_3
'	long @r_b_1
'	long @r_b_2
'	long @r_b_3
'	long @r_e_1
'	long @r_e_2
'	long @r_e_3
'	long @r_x
'	long @r_y
'	long @rho
'	long @t_1
'	long @t_2
'	long @t_3
'	long @t_4
'	long @t_5
'	long F_1
'	long F_2
'	long F_3
'	long F_4
'	long PID_n_1.getBase
'	long PID_n_2.getBase
'	long PID_n_3.getBase
'	long PID_n_4.getBase
'	long alpha
'	long alpha_H
'	long azm_temp_0
'	long azm_temp_1
'	long azm_temp_2
'	long azm_temp_3
'	long azm_temp_4
'	long azm_temp_5
'	long beta_H
'	long c
'	long const_2_pi
'	long n_d_1
'	long n_d_2
'	long n_d_3
'	long n_d_4
'	long omega_d_1
'	long omega_d_2
'	long omega_d_3
'	long omega_d_4
'	long phi
'	long q_1
'	long q_2
'	long q_3
'	long q_temp_0
'	long q_temp_1
'	long q_temp_2
'	long q_temp_3
'	long q_tilde_0
'	long q_tilde_1
'	long q_tilde_2
'	long q_tilde_3
'	long q_tilde_b_0
'	long q_tilde_b_1
'	long q_tilde_b_2
'	long q_tilde_b_3
'	long r_b_1
'	long r_b_2
'	long r_b_3
'	long r_e_1
'	long r_e_2
'	long r_e_3
'	long r_x
'	long r_y
'	long t_1
'	long t_2
'	long t_3
'	long t_4
'	long t_5
'	long u_1
'	long u_2
'	long u_3
'	long u_4
'=========================================
