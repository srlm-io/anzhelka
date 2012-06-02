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


	'System Clock settings


	
	
	'Motor lower limits
	MOTOR_ZERO = 1000
	MOTOR_SIZE = 1000 'The range, in uS, from smallest value to highest value
	



OBJ
'	serial	:   "FastFullDuplexSerialPlusBuffer.spin"
'	fp		:	"F32_CMD.spin"
	pwm 	:	"PWM_32_v4.spin"
	
'	PID_M_x	: "PID_data.spin"
'	PID_M_y	: "PID_data.spin"
'	PID_M_z	: "PID_data.spin"
'	PID_F_z	: "PID_data.spin"
'	PID_n_1	: "PID_data.spin"
'	PID_n_2	: "PID_data.spin"
'	PID_n_3	: "PID_data.spin"
'	PID_n_4	: "PID_data.spin"
	
	
PUB Main | t1
	
	pwm.start
	pwm.servo(MOTOR_1_PIN, MOTOR_ZERO)
	pwm.servo(MOTOR_2_PIN, MOTOR_ZERO)
	pwm.servo(MOTOR_3_PIN, MOTOR_ZERO)
	pwm.servo(MOTOR_4_PIN, MOTOR_ZERO)
	
'	fp.start
'	InitClock
'	InitUart
	InitFunctions
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


'-------------------------------------------------------------------
'-------------------------------------------------------------------
'----------------- Control Loop Functionality ----------------------
'-------------------------------------------------------------------
'-------------------------------------------------------------------

'DAT
''***************************************************
''*********** MOMENT BLOCK **************************
''***************************************************
''Moment I/O Variables

'			long	0, 0
'omega_b_x	long 0
'omega_b_y	long 0
'omega_b_z	long 0
'	
'			long 0, 0
'q_0			long 0
'q_1			long 0
'q_2			long 0
'q_3			long 0

'			long 0, 0
'q_d_0		long 0
'q_d_1		long 0
'q_d_2		long 0
'q_d_3		long 0

'			long 0, 0
'M_x			long 0
'M_y			long 0
'M_z			long 0
'	
''Moment Intermediate Variables
'	

'			long 0, 0
'alpha		long 0


'			long 0, 0
'alpha_H		long 0

'			long 0, 0
'beta_h		long 0


'			long 0, 0
'phi			long 0

'			long 0, 0
'q_temp_0	long 0
'q_temp_1	long 0
'q_temp_2	long 0
'q_temp_3	long 0


'			long 0, 0
'q_tilde_0	long 0
'q_tilde_1	long 0
'q_tilde_2	long 0
'q_tilde_3	long 0

'			long 0, 0
'q_tilde_b_0	long 0
'q_tilde_b_1 long 0
'q_tilde_b_2	long 0
'q_tilde_b_3	long 0


'			long 0, 0
'r_b_1		long 0
'r_b_2		long 0
'r_b_3		long 0

'			long 0, 0
'r_e_1		long 0
'r_e_2		long 0
'r_e_3		long 0


'			long 0, 0
'r_x			long 0
'r_y			long 0


''***************************************************
''*********** MOTOR BLOCK ***************************
''***************************************************


'			long 0, 0
'K_Q			long 0
'			long 0, 0
'K_T			long 0

'			long 0, 0
'diameter	long 0		'D in the documentation

'			long 0, 0
'offset		long 0		'd in the documentation

'			long 0, 0
'c			long 0

'			long 0, 0
'F_z			long 0


'			long 0, 0
'F_1			long 0
'F_2			long 0
'F_3			long 0
'F_4			long 0

'			long 0, 0
'rho			long 0		'Air density

'			long 0, 0
'omega_d_1	long 0
'			long 0, 0
'omega_d_2	long 0
'			long 0, 0
'omega_d_3	long 0
'			long 0, 0
'omega_d_4	long 0


'			long 0, 0
'n_1			long 0
'			long 0, 0
'n_2			long 0
'			long 0, 0
'n_3			long 0
'			long 0, 0
'n_4			long 0



'			long 0, 0
'n_d_1		long 0
'			long 0, 0
'n_d_2		long 0
'			long 0, 0
'n_d_3		long 0
'			long 0, 0
'n_d_4		long 0


'			long 0, 0
'u_1			long 0
'			long 0, 0
'u_2			long 0
'			long 0, 0
'u_3			long 0
'			long 0, 0
'u_4			long 0


'			long 0, 0
'const_2_pi	long 0


''			long 0, 0
''n_1			long 0
''			long 0, 0
''n_2			long 0
''			long 0, 0
''n_3			long 0
''			long 0, 0
''n_4			long 0



''***************************************************
''*********** WORKING VARIABLES *********************
''***************************************************

't_1			long 0
't_2			long 0
't_3			long 0
't_4			long 0
't_5			long 0






	
	
PUB Calculate
'One iteration of the calculations
'Should be called from a repeat loop...
'Writes object local variables, does not write to address
	
	fp.FInterpret(@CONTROL_LOOP_INSTRUCTIONS)
	
{{AZM_MATH CONTROL_LOOP

'***************************************************
'*********** MOMENT BLOCK **************************
'***************************************************


'q star:
q_1 = 0 - q_1
q_2 = 0 - q_2
q_3 = 0 - q_3

'Moment Block, first Quat Mul
q_tilde_0 = ((q_d_0*q_0) - (q_d_1*q_1)) - ((q_d_2*q_2) - (q_d_3*q_3))
q_tilde_1 = ((q_d_0*q_1) + (q_d_1*q_0)) + ((q_d_2*q_3) - (q_d_3*q_2))
q_tilde_2 = ((q_d_0*q_2) - (q_d_1*q_3)) + ((q_d_2*q_0) + (q_d_3*q_1))
q_tilde_3 = ((q_d_0*q_3) + (q_d_1*q_2)) - ((q_d_2*q_1) + (q_d_3*q_0))

alpha = 2 * (q_tilde_0 arc_c 0)


t_1 = (alpha / 2) sin 0

r_e_1 = q_tilde_1 / t_1
r_e_2 = q_tilde_2 / t_1
r_e_3 = q_tilde_3 / t_1

'Moment Block, r_b first (lhs) quat mult:
q_temp_0 = ((q_0*0) - (q_1*r_e_1)) - ((q_2*r_e_2) - (q_3*r_e_3))
q_temp_1 = ((q_0*r_e_1) + (q_1*0)) + ((q_2*r_e_3) - (q_3*r_e_2))
q_temp_2 = ((q_0*r_e_2) - (q_1*r_e_3)) + ((q_2*0) + (q_3*r_e_1))
q_temp_3 = ((q_0*r_e_3) + (q_1*r_e_2)) - ((q_2*r_e_1) + (q_3*0))


'q star:
q_1 = 0 - q_1
q_2 = 0 - q_2
q_3 = 0 - q_3

'Moment Block, r_b second (rhs) quat mult:
'0 = ((q_temp_0*q_0) - (q_temp_1*q_1)) - ((q_temp_2*q_2) - (q_temp_3*q_3))
r_b_1 = ((q_temp_0*q_1) + (q_temp_1*q_0)) + ((q_temp_2*q_3) - (q_temp_3*q_2))
r_b_2 = ((q_temp_0*q_2) - (q_temp_1*q_3)) + ((q_temp_2*q_0) + (q_temp_3*q_1))
r_b_3 = ((q_temp_0*q_3) + (q_temp_1*q_2)) - ((q_temp_2*q_1) + (q_temp_3*q_0))

q_tilde_b_0 = (alpha / 2) sin 0
q_tilde_b_1 = t_1 * r_b_1
q_tilde_b_2 = t_1 * r_b_2
q_tilde_b_3 = t_1 * r_b_3

alpha_H =  (1- (2 * ((q_1 * q_1) + (q_2 * q_2)))) arc_c 0
phi = 2 * (q_3 arc_t2 q_0)

t_1 = (phi / 2) cos 0
t_2 = (phi / 2) sin 0
t_3 = (alpha_H / 2) sin 0

r_x = ((t_1 * q_1) - (t_2 * q_2)) / t_3
r_y = ((t_2 * q_1) - (t_1 * q_2)) / t_3
beta_H = r_y arc_t2 r_x


'***************************************************
'*********** MOTOR BLOCK ***************************
'***************************************************

t_5 = 2 * offset
const_2_pi = 2 * pi

c = (K_Q * diameter) / K_T
t_1 = M_z / (4*c)
t_2 = M_y / t_5
t_3 = M_x / t_5
t_4 = F_z / 4

F_1 = (t_4 + (t_1 - t_2)) #> 0
F_2 = (t_4 - (t_1 + t_3)) #> 0
F_3 = (t_4 + (t_1 + t_2)) #> 0
F_4 = (t_4 + (t_3 - t_1)) #> 0


t_1 = const_2_pi / (diameter * diameter)
t_2 = rho * K_T

omega_d_1 = t_1 * ((F_1 / t_2) sqrt 0)
omega_d_2 = t_1 * ((F_2 / t_2) sqrt 0)
omega_d_3 = t_1 * ((F_3 / t_2) sqrt 0)
omega_d_4 = t_1 * ((F_4 / t_2) sqrt 0)

n_d_1 = omega_d_1 / const_2_pi
n_d_2 = omega_d_2 / const_2_pi
n_d_3 = omega_d_3 / const_2_pi
n_d_4 = omega_d_4 / const_2_pi

'PID Section, with truncation (||)
u_1 = (PID_n_1.getBase ~ 0) || 0
u_2 = (PID_n_2.getBase ~ 0) || 0
u_3 = (PID_n_3.getBase ~ 0) || 0
u_4 = (PID_n_4.getBase ~ 0) || 0


}}
	
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
