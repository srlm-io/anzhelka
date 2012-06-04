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
'	_xinfreq = 5_000_000
	_xinfreq = 6_250_000

'IO Pins
	DEBUG_TX_PIN  = 30
	DEBUG_RX_PIN  = 31
	
	CLOCK_PIN = 20 'Unconnected to anything else
	
	MOTOR_1_PIN =  9 'NUMBER FOR TESTING
	MOTOR_2_PIN = 10 'NUMBER FOR TESTING
	MOTOR_3_PIN = 11 'NUMBER FOR TESTING
	MOTOR_4_PIN = 12 'NUMBER FOR TESTING
	
	'RPM pins are a mask, so shift 1 to make that
	'Note: will not work with pin 0 ( aka, 0-1 == -1, can't shift by that)
	RPM_1_PIN = 1 << (5 -1)
	RPM_2_PIN = 1 << (6 -1)
	RPM_3_PIN = 1 << (7 -1)
	RPM_4_PIN = 1 << (8 -1)
	
	'Motor lower limits
	MOTOR_ZERO = 1000

OBJ
	pwm 	:	"PWM_32_v4.spin"
	rpm 	:	"Eagle_Tree_Brushless_RPM.spin"
	

PUB Main | t1, i
	
	
	u_1 := u_2 := u_3 := u_4 := float(MOTOR_ZERO)
	motor_pwm_1 := motor_pwm_2 := motor_pwm_3 := motor_pwm_4 := MOTOR_ZERO
	pwm.start
	pwm.servo(MOTOR_1_PIN, MOTOR_ZERO)
	pwm.servo(MOTOR_2_PIN, MOTOR_ZERO)
	pwm.servo(MOTOR_3_PIN, MOTOR_ZERO)
	pwm.servo(MOTOR_4_PIN, MOTOR_ZERO)
	
	repeat
	
	InitFunctions
	Init_Instructions
	InitPID
	
	rpm.setpins(RPM_1_PIN | RPM_2_PIN | RPM_3_PIN | RPM_4_PIN) 'RPM_PIN
	rpm.start

	PrintStrStart
	serial.str(string("RPM Pins: %"))
	serial.bin(RPM_1_PIN | RPM_2_PIN | RPM_3_PIN | RPM_4_PIN, 32)
	PrintStrStop
	
	'TODO: set U_1, etc.
	

	repeat	
		n_1 := fp.FFloat( 0 #> rpm.getrps(0) <# 250) 'Min < rps < Max
		n_2 := fp.FFloat( 0 #> rpm.getrps(1) <# 250) 'Min < rps < Max
		n_3 := fp.FFloat( 0 #> rpm.getrps(2) <# 250) 'Min < rps < Max
		n_4 := fp.FFloat( 0 #> rpm.getrps(3) <# 250) 'Min < rps < Max
		
		PrintArrayAddr4(string("NIM"), @n_1, @n_2, @n_3, @n_4, TYPE_FLOAT)
		
		fp.FInterpret(@CONTROL_LOOP_INSTRUCTIONS)
		
		pwm.servo(MOTOR_1_PIN, motor_pwm_1)
		pwm.servo(MOTOR_2_PIN, motor_pwm_2)
		pwm.servo(MOTOR_3_PIN, motor_pwm_3)
		pwm.servo(MOTOR_4_PIN, motor_pwm_4)
		
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
	
	
	fp.InitializePID(PID_n_1.getBase, @n_1, @PID_n_1_output, @n_d_1, fp.FSub(float(0), float(300)), float(300), fp.FDiv(float(1), float(50)))
	fp.SetTunings(PID_n_1.getBase, float(1), float(0), float(0))
	
	fp.InitializePID(PID_n_2.getBase, @n_2, @PID_n_2_output, @n_d_2, fp.FSub(float(0), float(300)), float(300), fp.FDiv(float(1), float(50)))
	fp.SetTunings(PID_n_2.getBase, float(1), float(0), float(0))
	
	fp.InitializePID(PID_n_3.getBase, @n_3, @PID_n_3_output, @n_d_3, fp.FSub(float(0), float(300)), float(300), fp.FDiv(float(1), float(50)))
	fp.SetTunings(PID_n_3.getBase, float(1), float(0), float(0))
	
	fp.InitializePID(PID_n_4.getBase, @n_4, @PID_n_4_output, @n_d_4, fp.FSub(float(0), float(300)), float(300), fp.FDiv(float(1), float(50)))
	fp.SetTunings(PID_n_4.getBase, float(1), float(0), float(0))
	


'-------------------------------------------------------------------
'-------------------------------------------------------------------
'----------------- Control Loop Functionality ----------------------
'-------------------------------------------------------------------
'-------------------------------------------------------------------

	
	
PUB Calculate
'One iteration of the calculations
'Should be called from a repeat loop...
'Writes object local variables, does not write to address
	
	fp.FInterpret(@CONTROL_LOOP_INSTRUCTIONS)
	
{{AZM_MATH CONTROL_LOOP

'***************************************************
'*********** MOMENT BLOCK **************************
'***************************************************


''q star:
'q_1 = 0 - q_1
'q_2 = 0 - q_2
'q_3 = 0 - q_3

''Moment Block, first Quat Mul
'q_tilde_0 = ((q_d_0*q_0) - (q_d_1*q_1)) - ((q_d_2*q_2) - (q_d_3*q_3))
'q_tilde_1 = ((q_d_0*q_1) + (q_d_1*q_0)) + ((q_d_2*q_3) - (q_d_3*q_2))
'q_tilde_2 = ((q_d_0*q_2) - (q_d_1*q_3)) + ((q_d_2*q_0) + (q_d_3*q_1))
'q_tilde_3 = ((q_d_0*q_3) + (q_d_1*q_2)) - ((q_d_2*q_1) + (q_d_3*q_0))

'alpha = 2 * (q_tilde_0 arc_c 0)


't_1 = (alpha / 2) sin 0

'r_e_1 = q_tilde_1 / t_1
'r_e_2 = q_tilde_2 / t_1
'r_e_3 = q_tilde_3 / t_1

''Moment Block, r_b first (lhs) quat mult:
'q_temp_0 = ((q_0*0) - (q_1*r_e_1)) - ((q_2*r_e_2) - (q_3*r_e_3))
'q_temp_1 = ((q_0*r_e_1) + (q_1*0)) + ((q_2*r_e_3) - (q_3*r_e_2))
'q_temp_2 = ((q_0*r_e_2) - (q_1*r_e_3)) + ((q_2*0) + (q_3*r_e_1))
'q_temp_3 = ((q_0*r_e_3) + (q_1*r_e_2)) - ((q_2*r_e_1) + (q_3*0))


''q star:
'q_1 = 0 - q_1
'q_2 = 0 - q_2
'q_3 = 0 - q_3

''Moment Block, r_b second (rhs) quat mult:
''0 = ((q_temp_0*q_0) - (q_temp_1*q_1)) - ((q_temp_2*q_2) - (q_temp_3*q_3))
'r_b_1 = ((q_temp_0*q_1) + (q_temp_1*q_0)) + ((q_temp_2*q_3) - (q_temp_3*q_2))
'r_b_2 = ((q_temp_0*q_2) - (q_temp_1*q_3)) + ((q_temp_2*q_0) + (q_temp_3*q_1))
'r_b_3 = ((q_temp_0*q_3) + (q_temp_1*q_2)) - ((q_temp_2*q_1) + (q_temp_3*q_0))

'q_tilde_b_0 = (alpha / 2) sin 0
'q_tilde_b_1 = t_1 * r_b_1
'q_tilde_b_2 = t_1 * r_b_2
'q_tilde_b_3 = t_1 * r_b_3

'alpha_H =  (1- (2 * ((q_1 * q_1) + (q_2 * q_2)))) arc_c 0
'phi = 2 * (q_3 arc_t2 q_0)

't_1 = (phi / 2) cos 0
't_2 = (phi / 2) sin 0
't_3 = (alpha_H / 2) sin 0

'r_x = ((t_1 * q_1) - (t_2 * q_2)) / t_3
'r_y = ((t_2 * q_1) - (t_1 * q_2)) / t_3
'beta_H = r_y arc_t2 r_x


'***************************************************
'*********** MOTOR BLOCK ***************************
'***************************************************

't_5 = 2 * offset
'const_2_pi = 2 * pi

'c = (K_Q * diameter) / K_T
't_1 = M_z / (4*c)
't_2 = M_y / t_5
't_3 = M_x / t_5
't_4 = F_z / 4

'F_1 = (t_4 + (t_1 - t_2)) #> 0
'F_2 = (t_4 - (t_1 + t_3)) #> 0
'F_3 = (t_4 + (t_1 + t_2)) #> 0
'F_4 = (t_4 + (t_3 - t_1)) #> 0


't_1 = const_2_pi / (diameter * diameter)
't_2 = rho * K_T

'omega_d_1 = t_1 * ((F_1 / t_2) sqrt 0)
'omega_d_2 = t_1 * ((F_2 / t_2) sqrt 0)
'omega_d_3 = t_1 * ((F_3 / t_2) sqrt 0)
'omega_d_4 = t_1 * ((F_4 / t_2) sqrt 0)

'n_d_1 = omega_d_1 / const_2_pi
'n_d_2 = omega_d_2 / const_2_pi
'n_d_3 = omega_d_3 / const_2_pi
'n_d_4 = omega_d_4 / const_2_pi

''PID Section, with truncation (||)
''u_1 = (PID_n_1.getBase ~ 0) || 0
''u_2 = (PID_n_2.getBase ~ 0) || 0
''u_3 = (PID_n_3.getBase ~ 0) || 0
''u_4 = (PID_n_4.getBase ~ 0) || 0


'Follows the inverse of this equation:
'	rpm = (max_rpm - y_intercept)/(pwm@max_rpm) * pwm + y_intercept
' the constants above are determined by experiment.
' Inverse
'	pwm = ( pwm@max_rpm / (max_rpm - y_intercept))*rpm - (y_intercept * max_rpm)/(max_rpm - y_intercept)

'Below, I am using
' motor_slope = ( pwm@max_rpm / (max_rpm - y_intercept))
' motor_intercept = (y_intercept * max_rpm)/(max_rpm - y_intercept)

't_1, t_2, etc. are placeholders. Results are in:
'PID_n_1_output
'PID_n_2_output
'PID_n_3_output
'PID_n_4_output

't_1 = PID_n_1.getBase ~ 0
't_2 = PID_n_2.getBase ~ 0
't_3 = PID_n_3.getBase ~ 0
't_4 = PID_n_4.getBase ~ 0

'Apply the PID to the motor output equation
'u_1 = ((motor_slope * n_d_1) - motor_intercept) + PID_n_1_output
'u_1 = (u_1 #> 1000) <# 1600

'u_2 = ((motor_slope * n_d_2) - motor_intercept) + PID_n_2_output
'u_2 = (u_2 #> 1000) <# 1600

'u_3 = ((motor_slope * n_d_3) - motor_intercept) + PID_n_3_output
'u_3 = (u_3 #> 1000) <# 1600

'u_4 = ((motor_slope * n_d_4) - motor_intercept) + PID_n_4_output
'u_4 = (u_4 #> 1000) <# 1600


'Convert to integer outputs
motor_pwm_1 = u_1 || 0
motor_pwm_2 = u_2 || 0
motor_pwm_3 = u_3 || 0
motor_pwm_4 = u_4 || 0

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
