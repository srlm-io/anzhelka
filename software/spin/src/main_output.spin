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
'	_xinfreq = 6_250_000

'IO Pins
	DEBUG_TX_PIN  = 30
	DEBUG_RX_PIN  = 31
	
	CLOCK_PIN = 20 'Unconnected to anything else
	
	
	'Main quadrotor board
	IMU_RX_PIN = 27 'Note: direction is from Propeller IO port
	IMU_TX_PIN = 26 'Note: direction is from Propeller IO port

	
'	'Demo Board (green case)
'	IMU_RX_PIN = 0 'Note: direction is from Propeller IO port
'	IMU_TX_PIN = 1 'Note: direction is from Propeller IO port
'	
	MOTOR_1_PIN =  9 'NUMBER FOR TESTING
	MOTOR_2_PIN = 10 'NUMBER FOR TESTING
	MOTOR_3_PIN = 11 'NUMBER FOR TESTING
	MOTOR_4_PIN = 12 'NUMBER FOR TESTING
	
	'RPM pins are a mask, so shift 1 to make that
	'Note: will not work with pin 0 ( aka, 0-1 == -1, can't shift by that)
	RPM_1_PIN = 1 << 5
	RPM_2_PIN = 1 << 6
	RPM_3_PIN = 1 << 7
	RPM_4_PIN = 1 << 8
'	RPM_1_PIN =     %1'0_0000
'	RPM_2_PIN =    %100_0000
'	RPM_3_PIN =   %1000_0000
'	RPM_4_PIN = %1_0000_0000
	
	'Motor lower limits
	MOTOR_ZERO = 1000
	
	
	cntMin     = 4000      ' Minimum waitcnt value to prevent lock-up (400 in MikeGreens Basic functions

OBJ
	pwm 	:	"PWM_32_v4.spin"
	rpm 	:	"Eagle_Tree_Brushless_RPM.spin"
	imu : "um6.spin"

VAR
	long	gyro_proc_xy
	long	gyro_proc_z
	long	accel_proc_xy
	long	accel_proc_z
	long	mag_proc_xy
	long	mag_proc_z
	long	euler_phi_theta_um6
	long	euler_psi_um6

	long	quat_ab
	long	quat_cd
	
	long	quat_a
	long	quat_b
	long	quat_c
	long	quat_d
	
	long 	euler_phi, euler_theta, euler_psi
	long 	euler_phi_int, euler_theta_int, euler_psi_int
	
	long	fp_clkfreq


PUB Main | t1, i, lastcnt, string_to_print, loop_time, actual_time, frequency_cnt, debug_count
	
	InitFunctions
	Init_Instructions
'	InitConstants
	InitPID
	

	
	PrintStr(string("Zeroing Motors"))
	u_1 := u_2 := u_3 := u_4 := float(MOTOR_ZERO)
	motor_pwm_1 := motor_pwm_2 := motor_pwm_3 := motor_pwm_4 := MOTOR_ZERO
	pwm.start
	pwm.servo(MOTOR_1_PIN, MOTOR_ZERO)
	pwm.servo(MOTOR_2_PIN, MOTOR_ZERO)
	pwm.servo(MOTOR_3_PIN, MOTOR_ZERO)
	pwm.servo(MOTOR_4_PIN, MOTOR_ZERO)
'	waitcnt(clkfreq*3 + cnt)
	
	imu.add_register($5C, @gyro_proc_xy)
	imu.add_register($5D, @gyro_proc_z)
	imu.add_register($5E, @accel_proc_xy)
	imu.add_register($5F, @accel_proc_z)
	imu.add_register($60, @mag_proc_xy)
	imu.add_register($61, @mag_proc_z)
	imu.add_register($62, @euler_phi_theta_um6)
	imu.add_register($63, @euler_psi_um6)
	imu.add_register($64, @quat_ab)
	imu.add_register($65, @quat_cd)
	imu.start(IMU_RX_PIN, IMU_TX_PIN, 0, 115200)
	
	PrintStr(string("Zeroing IMU. Do not move."))
	waitcnt(clkfreq + cnt)
	imu.zero
	PrintStr(string("Done Zeroing Motors"))
	
	'DEBUG TODO: Set desired orientation to the current orientation
	q_d_0 := fp.FMul(fp.FFloat(quat_ab  ~> 16),        quat_scalar)
	q_d_1 := fp.FMul(fp.FFloat((quat_ab << 16) ~> 16), quat_scalar)
	q_d_2 := fp.FMul(fp.FFloat(quat_cd  ~> 16),        quat_scalar)
	q_d_3 := fp.FMul(fp.FFloat((quat_cd << 16) ~> 16), quat_scalar)
	
	PrintStr(string("Done zeroing IMU"))
	
	
	rpm.setpins(RPM_1_PIN | RPM_2_PIN | RPM_3_PIN | RPM_4_PIN) 'RPM_PIN
	rpm.start



	M_x := M_y := M_z :=  float(0) 'DEBUG TODO
	F_z := float(4) 'DEBUG TODO: to get the motors spinning at least a little bit...

	lastcnt := cnt
	string_to_print := -1
	loop_time := clkfreq/50 'Run at 50 Hz
	actual_time := cnt
	
	debug_count := 0
	
	fp_clkfreq := fp.FFloat(clkfreq)
	
	repeat	
		debug_count ++
		if debug_count == 10
			q_d_0 := q_0
			q_d_1 := q_1
			q_d_2 := q_2
			q_d_3 := q_3
			
	
'***************** Inputs **************************
		n_1_int := 0 #> rpm.getrps(0) <# 250 'Min < rps < Max
		n_2_int := 0 #> rpm.getrps(1) <# 250 'Min < rps < Max
		n_3_int := 0 #> rpm.getrps(2) <# 250 'Min < rps < Max
		n_4_int := 0 #> rpm.getrps(3) <# 250 'Min < rps < Max
'		n_1_int := rpm.gettime(0)
'		n_2_int := rpm.gettime(1)
'		n_3_int := rpm.gettime(2)
'		n_4_int := rpm.gettime(3)

		quat_a :=  quat_ab ~> 16
		quat_b := (quat_ab << 16) ~> 16
		quat_c :=  quat_cd ~> 16
		quat_d := (quat_cd << 16) ~> 16
		
		euler_phi :=  euler_phi_theta_um6 ~> 16
		euler_theta := (euler_phi_theta_um6 << 16) ~> 16
		euler_psi :=  euler_psi_um6 ~> 16
'		quat_d := (quat_cd << 16) ~> 16
	
		omega_b_x_int := gyro_proc_xy         ~> 16
		omega_b_y_int := (gyro_proc_xy << 16) ~> 16
		omega_b_z_int := gyro_proc_z          ~> 16
		
		accel_b_x_int := accel_proc_xy         ~> 16
		accel_b_y_int := (accel_proc_xy << 16) ~> 16
		accel_b_z_int := accel_proc_z          ~> 16
	
'***************** Serial **************************
		ParseSerial
'		if debug_count > 1
'			serial.str(string("Euler phi, theta, psi: "))
'			serial.str(fp.FloatToString(euler_phi))
'			serial.str(string(", "))
'			serial.str(fp.FloatToString(euler_theta))
'			serial.str(string(", "))
'			serial.str(fp.FloatToString(euler_psi))
'			serial.str(string(10, 13))
		
		'TODO: Bug, if the first thing to print hasn't been calculated yet, may hang.
		case string_to_print++
			0: PrintArrayAddr4(string("NIM"), @n_1, @n_2, @n_3, @n_4, TYPE_FLOAT)
			1: PrintArrayAddr3(string("MOM"), @M_x, @M_y, @M_z, TYPE_FLOAT)
			2: PrintArrayAddr4(string("PWM"), @u_1, @u_2, @u_3, @u_4, TYPE_FLOAT)
			3: PrintArrayAddr4(string("NID"), @n_d_1, @n_d_2, @n_d_3, @n_d_4, TYPE_FLOAT)
			4: PrintArrayAddr4(string("QII"), @q_0, @q_1, @q_2, @q_3, TYPE_FLOAT)
			5: PrintArrayAddr4(string("QDI"), @q_d_0, @q_d_1, @q_d_2, @q_d_3, TYPE_FLOAT)
			6: PrintArrayAddr4(string("QEI"), @q_tilde_b_0, @q_tilde_b_1, @q_tilde_b_2, @q_tilde_b_3, TYPE_FLOAT)
			7: PrintArrayAddr1(string("FZZ"), @F_z, TYPE_FLOAT)
			OTHER:
				PrintArrayAddr1(string("CLF"), @control_loop_frequency, TYPE_FLOAT)	
				string_to_print~ 'Reset to head
		
'***************** Stop *****************************
		if stop_command <> 0
			'Check for resume from stop.
			if stop_command == sSTP_RES
				stop_command := 0
				next
			
			stop_command := sSTP_EMG 'DEBUG TODO: treat all stops as emergency.
			if stop_command == sSTP_EMG
				pwm.servo(MOTOR_1_PIN, MOTOR_ZERO)
				pwm.servo(MOTOR_2_PIN, MOTOR_ZERO)
				pwm.servo(MOTOR_3_PIN, MOTOR_ZERO)
				pwm.servo(MOTOR_4_PIN, MOTOR_ZERO)
				u_1 := float(MOTOR_ZERO)
				u_2 := float(MOTOR_ZERO)
				u_3 := float(MOTOR_ZERO)
				u_4 := float(MOTOR_ZERO)				
				PrintStr(string("Warning: Emergency stop completed. Please reset quadrotor."))
				waitcnt(clkfreq/10 + cnt)
				next
		
'***************** Control **************************
		
		fp.FInterpret(@CONTROL_LOOP_INSTRUCTIONS)
			
		pwm.servo(MOTOR_1_PIN, motor_pwm_1)
		pwm.servo(MOTOR_2_PIN, motor_pwm_2)
		pwm.servo(MOTOR_3_PIN, motor_pwm_3)
		pwm.servo(MOTOR_4_PIN, motor_pwm_4)
			
			
'***************** Time **************************
		actual_time := cnt - actual_time + cntMin
		if actual_time < loop_time
			waitcnt(loop_time - actual_time + cnt + cntMin) 'Wait the remainder
			actual_time := cnt
		else
			actual_time := cnt
			PrintStr(string("Missed Timing Period! ***********************"))
			

		
		t1 := cnt
		frequency_cnt := t1 - frequency_cnt
		control_loop_frequency := fp.FDiv(fp.FFloat(clkfreq), fp.FFloat(frequency_cnt))
		frequency_cnt := t1
		
		

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
'	fp.InitializePID(PID_M_x.getBase, @M_x, @M_x, @moment_setpoint, fp.FSub(float(0), float(300)), float(300), fp.FDiv(float(1), float(50)))
'	fp.SetTunings(PID_M_x.getBase, K_PH_x, K_IH_y, K_DH_z)
'	PID_M_x_base := PID_M_x.getBase
'	
'	fp.InitializePID(PID_M_y.getBase, @M_y, @M_y, @moment_setpoint, fp.FSub(float(0), float(300)), float(300), fp.FDiv(float(1), float(50)))
'	fp.SetTunings(PID_M_y.getBase, K_PH_y, K_IH_y, K_DH_y)
'	PID_M_y_base := PID_M_y.getBase
'	
'	fp.InitializePID(PID_M_z.getBase, @M_z, @M_z, @moment_setpoint, fp.FSub(float(0), float(300)), float(300), fp.FDiv(float(1), float(50)))
'	fp.SetTunings(PID_M_z.getBase, K_PH_z, K_IH_z, K_DH_z)
'	PID_M_z_base := PID_M_z.getBase

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
	fp.SetTunings(PID_n_1.getBase, motor_kp, motor_ki, motor_kd)
	PID_n_1_base := PID_n_1.getBase
	
	fp.InitializePID(PID_n_2.getBase, @n_2, @PID_n_2_output, @n_d_2, fp.FSub(float(0), float(300)), float(300), fp.FDiv(float(1), float(50)))
	fp.SetTunings(PID_n_2.getBase, motor_kp, motor_ki, motor_kd)
	PID_n_2_base := PID_n_2.getBase
	
	fp.InitializePID(PID_n_3.getBase, @n_3, @PID_n_3_output, @n_d_3, fp.FSub(float(0), float(300)), float(300), fp.FDiv(float(1), float(50)))
	fp.SetTunings(PID_n_3.getBase, motor_kp, motor_ki, motor_kd)
	PID_n_3_base := PID_n_3.getBase
	
	fp.InitializePID(PID_n_4.getBase, @n_4, @PID_n_4_output, @n_d_4, fp.FSub(float(0), float(300)), float(300), fp.FDiv(float(1), float(50)))
	fp.SetTunings(PID_n_4.getBase, motor_kp, motor_ki, motor_kd)
	PID_n_4_base := PID_n_4.getBase
	


'-------------------------------------------------------------------
'-------------------------------------------------------------------
'----------------- Control Loop Functionality ----------------------
'-------------------------------------------------------------------
'-------------------------------------------------------------------

	
	
PUB Calculate
'One iteration of the calculations
'Should be called from a repeat loop...
'Writes object local variables, does not write to address
	
'	fp.FInterpret(@CONTROL_LOOP_INSTRUCTIONS)
	
	

	
	
	
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
	long CONTROL_LOOP_INSTRUCTIONS[(4 * 264) + 1]
	long azm_temp_0
	long azm_temp_1
	long azm_temp_2
	long azm_temp_3
	long azm_temp_4
	long azm_temp_5
	long azm_temp_6
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
	const_pi := pi'n_1 = fp_clkfreq / ((n_1_int ffloat 0) * 6)
'n_2 = fp_clkfreq / ((n_2_int ffloat 0) * 6)
'n_3 = fp_clkfreq / ((n_3_int ffloat 0) * 6)
'n_4 = fp_clkfreq / ((n_4_int ffloat 0) * 6)

'------------
'' n_1 = n_1_int ffloat 0
	'n_1 = @n_1_int ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @n_1_int, @const_0, @n_1)

'------------
'' n_2 = n_2_int ffloat 0
	'n_2 = @n_2_int ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @n_2_int, @const_0, @n_2)

'------------
'' n_3 = n_3_int ffloat 0
	'n_3 = @n_3_int ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @n_3_int, @const_0, @n_3)

'------------
'' n_4 = n_4_int ffloat 0
	'n_4 = @n_4_int ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @n_4_int, @const_0, @n_4)
'Make sure to do the shifting before calling this routine!

'------------
'' q_0 = (quat_a ffloat 0) * quat_scalar
	'azm_temp_0 = @quat_a ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @quat_a, @const_0, @azm_temp_0)
	'q_0 = @azm_temp_0 * @quat_scalar
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @quat_scalar, @q_0)

'------------
'' q_1 = (quat_b ffloat 0) * quat_scalar
	'azm_temp_0 = @quat_b ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @quat_b, @const_0, @azm_temp_0)
	'q_1 = @azm_temp_0 * @quat_scalar
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @quat_scalar, @q_1)

'------------
'' q_2 = (quat_c ffloat 0) * quat_scalar
	'azm_temp_0 = @quat_c ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @quat_c, @const_0, @azm_temp_0)
	'q_2 = @azm_temp_0 * @quat_scalar
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @quat_scalar, @q_2)

'------------
'' q_3 = (quat_d ffloat 0) * quat_scalar
	'azm_temp_0 = @quat_d ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @quat_d, @const_0, @azm_temp_0)
	'q_3 = @azm_temp_0 * @quat_scalar
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @quat_scalar, @q_3)

'------------
'' omega_b_x = (omega_b_x_int ffloat 0) * gyro_scalar
	'azm_temp_0 = @omega_b_x_int ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @omega_b_x_int, @const_0, @azm_temp_0)
	'omega_b_x = @azm_temp_0 * @gyro_scalar
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @gyro_scalar, @omega_b_x)

'------------
'' omega_b_y = (omega_b_x_int ffloat 0) * gyro_scalar
	'azm_temp_0 = @omega_b_x_int ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @omega_b_x_int, @const_0, @azm_temp_0)
	'omega_b_y = @azm_temp_0 * @gyro_scalar
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @gyro_scalar, @omega_b_y)

'------------
'' omega_b_z = (omega_b_x_int ffloat 0) * gyro_scalar
	'azm_temp_0 = @omega_b_x_int ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @omega_b_x_int, @const_0, @azm_temp_0)
	'omega_b_z = @azm_temp_0 * @gyro_scalar
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @gyro_scalar, @omega_b_z)

'------------
'' accel_b_x = (accel_b_x_int ffloat 0) * accel_scalar
	'azm_temp_0 = @accel_b_x_int ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @accel_b_x_int, @const_0, @azm_temp_0)
	'accel_b_x = @azm_temp_0 * @accel_scalar
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @accel_scalar, @accel_b_x)

'------------
'' accel_b_y = (accel_b_x_int ffloat 0) * accel_scalar
	'azm_temp_0 = @accel_b_x_int ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @accel_b_x_int, @const_0, @azm_temp_0)
	'accel_b_y = @azm_temp_0 * @accel_scalar
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @accel_scalar, @accel_b_y)

'------------
'' accel_b_z = (accel_b_x_int ffloat 0) * accel_scalar
	'azm_temp_0 = @accel_b_x_int ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @accel_b_x_int, @const_0, @azm_temp_0)
	'accel_b_z = @azm_temp_0 * @accel_scalar
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @accel_scalar, @accel_b_z)

'------------
'' euler_phi   = (euler_phi_int   ffloat 0) * euler_scalar
	'azm_temp_0 = @euler_phi_int ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @euler_phi_int, @const_0, @azm_temp_0)
	'euler_phi = @azm_temp_0 * @euler_scalar
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @euler_scalar, @euler_phi)

'------------
'' euler_theta = (euler_theta_int ffloat 0) * euler_scalar
	'azm_temp_0 = @euler_theta_int ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @euler_theta_int, @const_0, @azm_temp_0)
	'euler_theta = @azm_temp_0 * @euler_scalar
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @euler_scalar, @euler_theta)

'------------
'' euler_psi   = (euler_psi_int   ffloat 0) * euler_scalar
	'azm_temp_0 = @euler_psi_int ffloat @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPFloat, @euler_psi_int, @const_0, @azm_temp_0)
	'euler_psi = @azm_temp_0 * @euler_scalar
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @euler_scalar, @euler_psi)
'Normalize measured quaternion:

'------------
'' t_1 = (((q_0 * q_0) + (q_1 * q_1)) + ((q_2 * q_2) + (q_3 * q_3))) sqrt 0
	'azm_temp_0 = @q_0 * @q_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_0, @q_0, @azm_temp_0)
	'azm_temp_1 = @q_1 * @q_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_1, @q_1, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 + @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_2 * @q_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_2, @q_2, @azm_temp_3)
	'azm_temp_4 = @q_3 * @q_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_3, @q_3, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 + @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'azm_temp_6 = @azm_temp_2 + @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_2, @azm_temp_5, @azm_temp_6)
	't_1 = @azm_temp_6 sqrt @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSqr, @azm_temp_6, @const_0, @t_1)

'------------
'' q_0 = q_0 / t_1
	'q_0 = @q_0 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_0, @t_1, @q_0)

'------------
'' q_1 = q_1 / t_1
	'q_1 = @q_1 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_1, @t_1, @q_1)

'------------
'' q_2 = q_2 / t_1
	'q_2 = @q_2 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_2, @t_1, @q_2)

'------------
'' q_3 = q_3 / t_1
	'q_3 = @q_3 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_3, @t_1, @q_3)
'***************************************************
'*********** MOMENT BLOCK **************************
'***************************************************
''
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
'From here: http://www.j3d.org/matrix_faq/matrfaq_latest.html#Q53
'q_tilde_0 = ((q_d_0*q_0) - (q_d_1*q_1)) - ((q_d_2*q_2) - (q_d_3*q_3))
'q_tilde_1 = ((q_d_0*q_1) + (q_d_1*q_0)) + ((q_d_2*q_3) - (q_d_3*q_2))
'q_tilde_2 = ((q_d_0*q_2) + (q_d_2*q_0)) + ((q_d_3*q_1) - (q_d_1*q_3))
'q_tilde_3 = ((q_d_0*q_3) + (q_d_3*q_0)) + ((q_d_1*q_2) - (q_d_2*q_1))
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
'     Autogenerated quat multiplication with ./tool/quat_replace.py
''Normalize Quaternion

'------------
'' t_1 = (((q_tilde_0 * q_tilde_0) + (q_tilde_1 * q_tilde_1)) + ((q_tilde_2 * q_tilde_2) + (q_tilde_3 * q_tilde_3))) sqrt 0
	'azm_temp_0 = @q_tilde_0 * @q_tilde_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_tilde_0, @q_tilde_0, @azm_temp_0)
	'azm_temp_1 = @q_tilde_1 * @q_tilde_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_tilde_1, @q_tilde_1, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 + @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_tilde_2 * @q_tilde_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_tilde_2, @q_tilde_2, @azm_temp_3)
	'azm_temp_4 = @q_tilde_3 * @q_tilde_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_tilde_3, @q_tilde_3, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 + @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'azm_temp_6 = @azm_temp_2 + @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_2, @azm_temp_5, @azm_temp_6)
	't_1 = @azm_temp_6 sqrt @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSqr, @azm_temp_6, @const_0, @t_1)

'------------
'' q_tilde_0 = q_tilde_0 / t_1
	'q_tilde_0 = @q_tilde_0 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_tilde_0, @t_1, @q_tilde_0)

'------------
'' q_tilde_1 = q_tilde_1 / t_1
	'q_tilde_1 = @q_tilde_1 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_tilde_1, @t_1, @q_tilde_1)

'------------
'' q_tilde_2 = q_tilde_2 / t_1
	'q_tilde_2 = @q_tilde_2 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_tilde_2, @t_1, @q_tilde_2)

'------------
'' q_tilde_3 = q_tilde_3 / t_1
	'q_tilde_3 = @q_tilde_3 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_tilde_3, @t_1, @q_tilde_3)

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
'q_temp := q* (x) r_e
'  Important: q needs to be starred comming into this...

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
' Autogenerated quat multiplication with ./tool/quat_replace.py
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
' r_b := q_temp_0 (x) q
'  Important: q needs to be not stared before multiplying...
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
'     Autogenerated quat multiplication with ./tool/quat_replace.py

'------------
'' t_1 = (alpha / 2) sin 0
	'azm_temp_0 = @alpha / @const_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @alpha, @const_2, @azm_temp_0)
	't_1 = @azm_temp_0 sin @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSin, @azm_temp_0, @const_0, @t_1)

'------------
'' q_tilde_b_0 = (alpha / 2) cos 0
	'azm_temp_0 = @alpha / @const_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @alpha, @const_2, @azm_temp_0)
	'q_tilde_b_0 = @azm_temp_0 cos @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPCos, @azm_temp_0, @const_0, @q_tilde_b_0)

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
''Normalize Quaternion

'------------
'' t_1 = (((q_tilde_b_0 * q_tilde_b_0) + (q_tilde_b_1 * q_tilde_b_1)) + ((q_tilde_b_2 * q_tilde_b_2) + (q_tilde_b_3 * q_tilde_b_3))) sqrt 0
	'azm_temp_0 = @q_tilde_b_0 * @q_tilde_b_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_tilde_b_0, @q_tilde_b_0, @azm_temp_0)
	'azm_temp_1 = @q_tilde_b_1 * @q_tilde_b_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_tilde_b_1, @q_tilde_b_1, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 + @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @q_tilde_b_2 * @q_tilde_b_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_tilde_b_2, @q_tilde_b_2, @azm_temp_3)
	'azm_temp_4 = @q_tilde_b_3 * @q_tilde_b_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_tilde_b_3, @q_tilde_b_3, @azm_temp_4)
	'azm_temp_5 = @azm_temp_3 + @azm_temp_4
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_3, @azm_temp_4, @azm_temp_5)
	'azm_temp_6 = @azm_temp_2 + @azm_temp_5
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_2, @azm_temp_5, @azm_temp_6)
	't_1 = @azm_temp_6 sqrt @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSqr, @azm_temp_6, @const_0, @t_1)

'------------
'' q_tilde_b_0 = q_tilde_b_0 / t_1
	'q_tilde_b_0 = @q_tilde_b_0 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_tilde_b_0, @t_1, @q_tilde_b_0)

'------------
'' q_tilde_b_1 = q_tilde_b_1 / t_1
	'q_tilde_b_1 = @q_tilde_b_1 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_tilde_b_1, @t_1, @q_tilde_b_1)

'------------
'' q_tilde_b_2 = q_tilde_b_2 / t_1
	'q_tilde_b_2 = @q_tilde_b_2 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_tilde_b_2, @t_1, @q_tilde_b_2)

'------------
'' q_tilde_b_3 = q_tilde_b_3 / t_1
	'q_tilde_b_3 = @q_tilde_b_3 / @t_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @q_tilde_b_3, @t_1, @q_tilde_b_3)

'------------
'' alpha_H =  (1- (2 * ((q_tilde_b_1 * q_tilde_b_1) + (q_tilde_b_2 * q_tilde_b_2)))) arc_c 0
	'azm_temp_0 = @q_tilde_b_1 * @q_tilde_b_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_tilde_b_1, @q_tilde_b_1, @azm_temp_0)
	'azm_temp_1 = @q_tilde_b_2 * @q_tilde_b_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @q_tilde_b_2, @q_tilde_b_2, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 + @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @const_2 * @azm_temp_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @const_2, @azm_temp_2, @azm_temp_3)
	'azm_temp_4 = @const_1 - @azm_temp_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @const_1, @azm_temp_3, @azm_temp_4)
	'alpha_H = @azm_temp_4 arc_c @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPACos, @azm_temp_4, @const_0, @alpha_H)

'------------
'' phi = 2 * (q_tilde_b_3 arc_t2 q_tilde_b_0)
	'azm_temp_0 = @q_tilde_b_3 arc_t2 @q_tilde_b_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPATan2, @q_tilde_b_3, @q_tilde_b_0, @azm_temp_0)
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
'' r_x = ((t_1 * q_tilde_b_1) - (t_2 * q_tilde_b_2)) / t_3
	'azm_temp_0 = @t_1 * @q_tilde_b_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_1, @q_tilde_b_1, @azm_temp_0)
	'azm_temp_1 = @t_2 * @q_tilde_b_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_2, @q_tilde_b_2, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 - @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'r_x = @azm_temp_2 / @t_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @azm_temp_2, @t_3, @r_x)

'------------
'' r_y = ((t_2 * q_tilde_b_1) + (t_1 * q_tilde_b_2)) / t_3
	'azm_temp_0 = @t_2 * @q_tilde_b_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_2, @q_tilde_b_1, @azm_temp_0)
	'azm_temp_1 = @t_1 * @q_tilde_b_2
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @t_1, @q_tilde_b_2, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 + @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'r_y = @azm_temp_2 / @t_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @azm_temp_2, @t_3, @r_y)

'------------
'' beta_H = r_y arc_t2 r_x
	'beta_H = @r_y arc_t2 @r_x
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPATan2, @r_y, @r_x, @beta_H)
'TODO: need to add a derivative term, at least.

'------------
'' M_x = ((K_PH_x * alpha_H) * (beta_H cos 0)) - (K_DH_x * omega_b_x)
	'azm_temp_0 = @K_PH_x * @alpha_H
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @K_PH_x, @alpha_H, @azm_temp_0)
	'azm_temp_1 = @beta_H cos @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPCos, @beta_H, @const_0, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 * @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @K_DH_x * @omega_b_x
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @K_DH_x, @omega_b_x, @azm_temp_3)
	'M_x = @azm_temp_2 - @azm_temp_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_2, @azm_temp_3, @M_x)

'------------
'' M_y = ((K_PH_y * alpha_H) * (beta_H sin 0)) - (K_DH_y * omega_b_y)
	'azm_temp_0 = @K_PH_y * @alpha_H
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @K_PH_y, @alpha_H, @azm_temp_0)
	'azm_temp_1 = @beta_H sin @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSin, @beta_H, @const_0, @azm_temp_1)
	'azm_temp_2 = @azm_temp_0 * @azm_temp_1
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @azm_temp_0, @azm_temp_1, @azm_temp_2)
	'azm_temp_3 = @K_DH_y * @omega_b_y
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPMul, @K_DH_y, @omega_b_y, @azm_temp_3)
	'M_y = @azm_temp_2 - @azm_temp_3
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPSub, @azm_temp_2, @azm_temp_3, @M_y)
'M_x = (FNeg1 * alpha_H) * (beta_H cos 0)
'M_y = (FNeg1 * alpha_H) * (beta_H sin 0)
'M_x = alpha_H * (beta_H cos 0)
'M_y = alpha_H * (beta_H sin 0)
'M_z = 0 + 0
't_1 = PID_M_x_base ~ 0
't_2 = PID_M_y_base ~ 0
't_3 = PID_M_z_base ~ 0
'M_z = (K_P_z * phi) - (K_DH_z * omega_b_z)
'M_z = 0 * 0
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
''Follows the inverse of this equation:
''	rpm = slope * pwm + intercept
'' Graph it in open office, then create a trend line. The given values plug directly in (in anzhelka_variables)
''t_1, t_2, etc. are placeholders. Results are in:
''PID_n_1_output
''PID_n_2_output
''PID_n_3_output
''PID_n_4_output

'------------
'' t_1 = PID_n_1_base ~ 0
	't_1 = @PID_n_1_base ~ @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPPID, @PID_n_1_base, @const_0, @t_1)

'------------
'' t_2 = PID_n_2_base ~ 0
	't_2 = @PID_n_2_base ~ @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPPID, @PID_n_2_base, @const_0, @t_2)

'------------
'' t_3 = PID_n_3_base ~ 0
	't_3 = @PID_n_3_base ~ @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPPID, @PID_n_3_base, @const_0, @t_3)

'------------
'' t_4 = PID_n_4_base ~ 0
	't_4 = @PID_n_4_base ~ @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPPID, @PID_n_4_base, @const_0, @t_4)
'Apply the PID to the motor output equation

'------------
'' u_1 = ((n_d_1 + motor_intercept) / motor_slope ) + PID_n_1_output
	'azm_temp_0 = @n_d_1 + @motor_intercept
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @n_d_1, @motor_intercept, @azm_temp_0)
	'azm_temp_1 = @azm_temp_0 / @motor_slope
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @azm_temp_0, @motor_slope, @azm_temp_1)
	'u_1 = @azm_temp_1 + @PID_n_1_output
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_1, @PID_n_1_output, @u_1)

'------------
'' u_1 = (u_1 #> MIN_PWM) <# MAX_PWM
	'azm_temp_0 = @u_1 #> @MIN_PWM
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPLimitMin, @u_1, @MIN_PWM, @azm_temp_0)
	'u_1 = @azm_temp_0 <# @MAX_PWM
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPLimitMax, @azm_temp_0, @MAX_PWM, @u_1)

'------------
'' u_2 = ((n_d_2 + motor_intercept) / motor_slope ) + PID_n_2_output
	'azm_temp_0 = @n_d_2 + @motor_intercept
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @n_d_2, @motor_intercept, @azm_temp_0)
	'azm_temp_1 = @azm_temp_0 / @motor_slope
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @azm_temp_0, @motor_slope, @azm_temp_1)
	'u_2 = @azm_temp_1 + @PID_n_2_output
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_1, @PID_n_2_output, @u_2)

'------------
'' u_2 = (u_2 #> MIN_PWM) <# MAX_PWM
	'azm_temp_0 = @u_2 #> @MIN_PWM
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPLimitMin, @u_2, @MIN_PWM, @azm_temp_0)
	'u_2 = @azm_temp_0 <# @MAX_PWM
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPLimitMax, @azm_temp_0, @MAX_PWM, @u_2)

'------------
'' u_3 = ((n_d_3 + motor_intercept) / motor_slope ) + PID_n_3_output
	'azm_temp_0 = @n_d_3 + @motor_intercept
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @n_d_3, @motor_intercept, @azm_temp_0)
	'azm_temp_1 = @azm_temp_0 / @motor_slope
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @azm_temp_0, @motor_slope, @azm_temp_1)
	'u_3 = @azm_temp_1 + @PID_n_3_output
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_1, @PID_n_3_output, @u_3)

'------------
'' u_3 = (u_3 #> MIN_PWM) <# MAX_PWM
	'azm_temp_0 = @u_3 #> @MIN_PWM
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPLimitMin, @u_3, @MIN_PWM, @azm_temp_0)
	'u_3 = @azm_temp_0 <# @MAX_PWM
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPLimitMax, @azm_temp_0, @MAX_PWM, @u_3)

'------------
'' u_4 = ((n_d_4 + motor_intercept) / motor_slope ) + PID_n_4_output
	'azm_temp_0 = @n_d_4 + @motor_intercept
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @n_d_4, @motor_intercept, @azm_temp_0)
	'azm_temp_1 = @azm_temp_0 / @motor_slope
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPDiv, @azm_temp_0, @motor_slope, @azm_temp_1)
	'u_4 = @azm_temp_1 + @PID_n_4_output
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPAdd, @azm_temp_1, @PID_n_4_output, @u_4)

'------------
'' u_4 = (u_4 #> MIN_PWM) <# MAX_PWM
	'azm_temp_0 = @u_4 #> @MIN_PWM
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPLimitMin, @u_4, @MIN_PWM, @azm_temp_0)
	'u_4 = @azm_temp_0 <# @MAX_PWM
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPLimitMax, @azm_temp_0, @MAX_PWM, @u_4)
'Convert to integer outputs

'------------
'' motor_pwm_1 = u_1 || 0
	'motor_pwm_1 = @u_1 || @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPTruncRound, @u_1, @const_0, @motor_pwm_1)

'------------
'' motor_pwm_2 = u_2 || 0
	'motor_pwm_2 = @u_2 || @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPTruncRound, @u_2, @const_0, @motor_pwm_2)

'------------
'' motor_pwm_3 = u_3 || 0
	'motor_pwm_3 = @u_3 || @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPTruncRound, @u_3, @const_0, @motor_pwm_3)

'------------
'' motor_pwm_4 = u_4 || 0
	'motor_pwm_4 = @u_4 || @const_0
	fp.AddInstruction(CONTROL_LOOP_INDEX, fp#FPTruncRound, @u_4, @const_0, @motor_pwm_4)
'All variables that are used or created:
'	long @F_1
'	long @F_2
'	long @F_3
'	long @F_4
'	long @F_z
'	long @K_DH_x
'	long @K_DH_y
'	long @K_PH_x
'	long @K_PH_y
'	long @K_Q
'	long @K_T
'	long @MAX_PWM
'	long @MIN_PWM
'	long @M_x
'	long @M_y
'	long @M_z
'	long @PID_n_1_base
'	long @PID_n_1_output
'	long @PID_n_2_base
'	long @PID_n_2_output
'	long @PID_n_3_base
'	long @PID_n_3_output
'	long @PID_n_4_base
'	long @PID_n_4_output
'	long @accel_b_x_int
'	long @accel_scalar
'	long @alpha
'	long @alpha_H
'	long @azm_temp_0
'	long @azm_temp_1
'	long @azm_temp_2
'	long @azm_temp_3
'	long @azm_temp_4
'	long @azm_temp_5
'	long @azm_temp_6
'	long @beta_H
'	long @c
'	long @const_0
'	long @const_1
'	long @const_2
'	long @const_4
'	long @const_pi
'	long @diameter
'	long @euler_phi_int
'	long @euler_psi_int
'	long @euler_scalar
'	long @euler_theta_int
'	long @gyro_scalar
'	long @motor_intercept
'	long @motor_slope
'	long @n_1_int
'	long @n_2_int
'	long @n_3_int
'	long @n_4_int
'	long @n_d_1
'	long @n_d_2
'	long @n_d_3
'	long @n_d_4
'	long @offset
'	long @omega_b_x
'	long @omega_b_x_int
'	long @omega_b_y
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
'	long @q_tilde_b_0
'	long @q_tilde_b_1
'	long @q_tilde_b_2
'	long @q_tilde_b_3
'	long @quat_a
'	long @quat_b
'	long @quat_c
'	long @quat_d
'	long @quat_scalar
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
'	long @u_1
'	long @u_2
'	long @u_3
'	long @u_4
'	long F_1
'	long F_2
'	long F_3
'	long F_4
'	long M_x
'	long M_y
'	long accel_b_x
'	long accel_b_y
'	long accel_b_z
'	long alpha
'	long alpha_H
'	long azm_temp_0
'	long azm_temp_1
'	long azm_temp_2
'	long azm_temp_3
'	long azm_temp_4
'	long azm_temp_5
'	long azm_temp_6
'	long beta_H
'	long c
'	long const_2_pi
'	long euler_phi
'	long euler_psi
'	long euler_theta
'	long motor_pwm_1
'	long motor_pwm_2
'	long motor_pwm_3
'	long motor_pwm_4
'	long n_1
'	long n_2
'	long n_3
'	long n_4
'	long n_d_1
'	long n_d_2
'	long n_d_3
'	long n_d_4
'	long omega_b_x
'	long omega_b_y
'	long omega_b_z
'	long omega_d_1
'	long omega_d_2
'	long omega_d_3
'	long omega_d_4
'	long phi
'	long q_0
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
	sSTP = ("S" << 16) | ("T" << 8) | "P"
	sSTR = ("S" << 16) | ("T" << 8) | "R"
	
	sSTP_EMG = ("E" << 16) | ("M" << 8) | "G"
	sSTP_IMM = ("I" << 16) | ("M" << 8) | "M"
	sSTP_CON = ("C" << 16) | ("O" << 8) | "N"
	sSTP_RES = ("R" << 16) | ("E" << 8) | "S"
	
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

		sSTP:
			'Discard spaces, and then get first letter
			repeat
			while (stop_command := serial.rx) == " " 'Ignore spaces
			
			stop_command <<= 16 
			stop_command |= serial.rx << 8
			stop_command |= serial.rx
		sSTR:
			serial.rx 'Get space
			serial.rx 'Get first "'"
			repeat
			until serial.rx == "'"
			'Discard space
			
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
	sMPP = ("M" << 16) | ("P" << 8) | "P"
	sQII = ("Q" << 16) | ("I" << 8) | "I"
	sQDI = ("Q" << 16) | ("D" << 8) | "I"
	sQEI = ("Q" << 16) | ("E" << 8) | "I"
	sCLF = ("C" << 16) | ("L" << 8) | "F"
	sKPH = ("K" << 16) | ("P" << 8) | "H"
	sKIH = ("K" << 16) | ("I" << 8) | "H"
	sKDH = ("K" << 16) | ("D" << 8) | "H"	
	sOMG = ("O" << 16) | ("M" << 8) | "G"	
	sACC = ("A" << 16) | ("C" << 8) | "C"
'	 = ("" << 16) | ("" << 8) | ""

'	 = ("" << 16) | ("" << 8) | ""
'	 = ("" << 16) | ("" << 8) | ""
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
				PrintArrayAddr4(string("MKP"), PID_n_1.getKpAddr, PID_n_2.getKpAddr, PID_n_3.getKpAddr, PID_n_4.getKpAddr, TYPE_FLOAT)
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
				PrintArrayAddr4(string("MKI"), PID_n_1.getKiAddr, PID_n_2.getKiAddr, PID_n_3.getKiAddr, PID_n_4.getKiAddr, TYPE_FLOAT)
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
				PrintArrayAddr4(string("MKD"), PID_n_1.getKdAddr, PID_n_2.getKdAddr, PID_n_3.getKdAddr, PID_n_4.getKdAddr, TYPE_FLOAT)
			elseif TYPE == XDR_READ
				PrintArrayAddr4(string("MKD"), PID_n_1.getKdAddr, PID_n_2.getKdAddr, PID_n_3.getKdAddr, PID_n_4.getKdAddr, TYPE_FLOAT)
		sPWM:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 4, TYPE_FLOAT)
				WriteList4(@values, @u_1, @u_2, @u_3, @u_4)
				PrintArrayAddr4(string("PWM"), @u_1, @u_2, @u_3, @u_4, TYPE_FLOAT)
			elseif TYPE == XDR_READ	
				PrintArrayAddr4(string("PWM"), @u_1, @u_2, @u_3, @u_4, TYPE_FLOAT)
		sNID:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 4, TYPE_FLOAT)
				WriteList4(@values, @n_d_1, @n_d_2, @n_d_3, @n_d_4)
				PrintArrayAddr4(string("NID"), @n_d_1, @n_d_2, @n_d_3, @n_d_4, TYPE_FLOAT)
			elseif TYPE == XDR_READ	
				PrintArrayAddr4(string("NID"), @n_d_1, @n_d_2, @n_d_3, @n_d_4, TYPE_FLOAT)
				
		sNIM:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 4, TYPE_FLOAT)
				WriteList4(@values, @n_1, @n_2, @n_3, @n_4)
				PrintArrayAddr4(string("NIM"), @n_1, @n_2, @n_3, @n_4, TYPE_FLOAT)
			elseif TYPE == XDR_READ	
				PrintArrayAddr4(string("NIM"), @n_1, @n_2, @n_3, @n_4, TYPE_FLOAT)
				
		sMOM:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 3, TYPE_FLOAT)
				WriteList3(@values, @M_x, @M_y, @M_z)
				PrintArrayAddr3(string("MOM"), @M_x, @M_y, @M_z, TYPE_FLOAT)
			elseif TYPE == XDR_READ	
				PrintArrayAddr3(string("MOM"), @M_x, @M_y, @M_z, TYPE_FLOAT)
		
		sFZZ:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 1, TYPE_FLOAT)
				WriteList1(@values, @F_z)
			elseif TYPE == XDR_READ	
				PrintArrayAddr1(string("FZZ"), @F_z, TYPE_FLOAT)
		
		sMPP:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 2, TYPE_FLOAT)
				WriteList2(@values, @motor_slope, @motor_intercept)
			elseif TYPE == XDR_READ	
				PrintArrayAddr2(string("MPP"), @motor_slope, @motor_intercept, TYPE_FLOAT)
				
		sQII:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 4, TYPE_FLOAT)
				WriteList4(@values, @q_0, @q_1, @q_2, @q_3)
				PrintArrayAddr4(string("QII"), @q_0, @q_1, @q_2, @q_3, TYPE_FLOAT)
			elseif TYPE == XDR_READ	
				PrintArrayAddr4(string("QII"), @q_0, @q_1, @q_2, @q_3, TYPE_FLOAT)
		sQDI:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 4, TYPE_FLOAT)
				WriteList4(@values, @q_d_0, @q_d_1, @q_d_2, @q_d_3)
				PrintArrayAddr4(string("QDI"), @q_d_0, @q_d_1, @q_d_2, @q_d_3, TYPE_FLOAT)
			elseif TYPE == XDR_READ	
				PrintArrayAddr4(string("QDI"), @q_d_0, @q_d_1, @q_d_2, @q_d_3, TYPE_FLOAT)
		sQEI:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 4, TYPE_FLOAT)
				WriteList4(@values, @q_tilde_0, @q_tilde_1, @q_tilde_2, @q_tilde_3)
				PrintArrayAddr4(string("QEI"), @q_tilde_b_0, @q_tilde_b_1, @q_tilde_b_2, @q_tilde_b_3, TYPE_FLOAT)
			elseif TYPE == XDR_READ	
				PrintArrayAddr4(string("QEI"), @q_tilde_b_0, @q_tilde_b_1, @q_tilde_b_2, @q_tilde_b_3, TYPE_FLOAT)
				
		sCLF:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 1, TYPE_FLOAT)
				WriteList1(@values, @control_loop_frequency)
			elseif TYPE == XDR_READ	
				PrintArrayAddr1(string("CLF"), @control_loop_frequency, TYPE_FLOAT)
				
				
		sKPH:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 3, TYPE_FLOAT)
				WriteList3(@values, @K_PH_x, @K_PH_y, @K_PH_z) 'TODO: not useful, since it's not used by PIDs
				
				fp.SetTunings(PID_M_x.getBase, values[0], FNeg1, FNeg1)
				fp.SetTunings(PID_M_y.getBase, values[1], FNeg1, FNeg1)
				fp.SetTunings(PID_M_z.getBase, values[2], FNeg1, FNeg1)
				
				PrintArrayAddr3(string("KPH"), @K_PH_x, @K_PH_y, @K_PH_z, TYPE_FLOAT)
			elseif TYPE == XDR_READ	
				PrintArrayAddr3(string("KPH"), @K_PH_x, @K_PH_y, @K_PH_z, TYPE_FLOAT)
				
		sKIH:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 3, TYPE_FLOAT)
				WriteList3(@values, @K_IH_x, @K_IH_y, @K_IH_z) 'TODO: not useful, since it's not used by PIDs
				
				fp.SetTunings(PID_M_x.getBase, FNeg1, values[0], FNeg1)
				fp.SetTunings(PID_M_y.getBase, FNeg1, values[1], FNeg1)
				fp.SetTunings(PID_M_z.getBase, FNeg1, values[2], FNeg1)

				PrintArrayAddr3(string("KIH"), @K_IH_x, @K_IH_y, @K_IH_z, TYPE_FLOAT)
			elseif TYPE == XDR_READ	
				PrintArrayAddr3(string("KIH"), @K_IH_x, @K_IH_y, @K_IH_z, TYPE_FLOAT)
				
		sKDH:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 3, TYPE_FLOAT)
				WriteList3(@values, @K_DH_x, @K_DH_y, @K_DH_z) 'TODO: not useful, since it's not used by PIDs
				
				fp.SetTunings(PID_M_x.getBase, FNeg1, FNeg1, values[0])
				fp.SetTunings(PID_M_y.getBase, FNeg1, FNeg1, values[1])
				fp.SetTunings(PID_M_z.getBase, FNeg1, FNeg1, values[2])
				PrintArrayAddr3(string("KDH"), @K_DH_x, @K_DH_y, @K_DH_z, TYPE_FLOAT)
			elseif TYPE == XDR_READ	
				PrintArrayAddr3(string("KDH"), @K_DH_x, @K_DH_y, @K_DH_z, TYPE_FLOAT)
		
		sOMG:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 3, TYPE_FLOAT)
				WriteList3(@values, @omega_b_x, @omega_b_y, @omega_b_z)
				PrintArrayAddr3(string("OMG"), @omega_b_x, @omega_b_y, @omega_b_z, TYPE_FLOAT)
			elseif TYPE == XDR_READ	
				PrintArrayAddr3(string("OMG"), @omega_b_x, @omega_b_y, @omega_b_z, TYPE_FLOAT)
		sACC:
			if TYPE == XDR_WRITE
				ParseSerialList(@values, 3, TYPE_FLOAT)
				WriteList3(@values, @accel_b_x, @accel_b_y, @accel_b_z)
				PrintArrayAddr3(string("ACC"), @accel_b_x, @accel_b_y, @accel_b_z, TYPE_FLOAT)
			elseif TYPE == XDR_READ	
				PrintArrayAddr3(string("ACC"), @accel_b_x, @accel_b_y, @accel_b_z, TYPE_FLOAT)
		
		
				
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


PUB WriteList2(input_array_addr, a_addr, b_addr)
'Writes the four variables in the input array to the four addresses specified.
'If a number is NAN, it will not write it.
	
	if long[input_array_addr][0] <> NAN
		long[a_addr] := long[input_array_addr][0]
	
	if long[input_array_addr][1] <> NAN
		long[b_addr] := long[input_array_addr][1]
	

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

PUB PrintArrayAddr4(type_string_addr, a_addr, b_addr, c_addr, d_addr, type) | i, temp_addr
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
'			FPrint(long[long[@a_addr][i]])
'			serial.str(fp.FloatToString(long[long[@a_addr][i]]))
			temp_addr := fp.FloatToString(long[long[@a_addr][i]])
			serial.txblock(temp_addr, strsize(temp_addr))
		else
			serial.tx("?") 'Warning!
		
	serial.tx(10)
	serial.tx(13)

PUB PrintArrayAddr3(type_string_addr, a_addr, b_addr, c_addr, type) | i, temp_addr
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
'			FPrint(long[long[@a_addr][i]])
'			serial.str(fp.FloatToString(long[long[@a_addr][i]]))
			temp_addr := fp.FloatToString(long[long[@a_addr][i]])
			serial.txblock(temp_addr, strsize(temp_addr))
		else
			serial.tx("?") 'Warning!
		
	serial.tx(10)
	serial.tx(13)
	
PUB PrintArrayAddr2(type_string_addr, a_addr, b_addr, type) | i, temp_addr
'' Parameters:
''  - type_string_addr: a string that has the three capital letters that 
''      denote which type of data this packet is, eg PWM or MKP
''  - [a|b|c|d]_addr - the address of the variable to print
''  - type - either TYPE_FLOAT or TYPE_INT


	serial.str(string("$AD"))
	serial.str(type_string_addr)
	serial.tx(" ")
	serial.dec(phsb)

	repeat i from 0 to 2 - 1
		serial.tx(",")
		if type == TYPE_INT
			serial.dec(long[long[@a_addr][i]])
		elseif type == TYPE_FLOAT
'			FPrint(long[long[@a_addr][i]])
'			serial.str(fp.FloatToString(long[long[@a_addr][i]]))
			temp_addr := fp.FloatToString(long[long[@a_addr][i]])
			serial.txblock(temp_addr, strsize(temp_addr))
		else
			serial.tx("?") 'Warning!
		
	serial.tx(10)
	serial.tx(13)
	
PUB PrintArrayAddr1(type_string_addr, a_addr, type) | i, temp_addr
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
'		FPrint(long[a_addr])
		temp_addr := fp.FloatToString(long[a_addr])
		serial.txblock(temp_addr, strsize(temp_addr))
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
	
	
	if compile_time <> 0
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
{{
--------------------------------------------------------------------------------
Anzhelka Project
(c) 2012

For the latest code and support, please visit:
http://code.anzhelka.com
--------------------------------------------------------------------------------

Title:
Author:
Date:
Notes:



}}

OBJ
	PID_M_x	: "PID_data.spin"
	PID_M_y	: "PID_data.spin"
	PID_M_z	: "PID_data.spin"
	PID_F_z	: "PID_data.spin"
	PID_n_1	: "PID_data.spin"
	PID_n_2	: "PID_data.spin"
	PID_n_3	: "PID_data.spin"
	PID_n_4	: "PID_data.spin"

DAT


control_loop_frequency long 0.0 'Frequency in Hz of the control loop.

stop_command long 0


'***************************************************
'*********** CONTROLLER VARIABLES ******************
'***************************************************

r_d_e_0 long 0
r_d_e_1 long 0
r_d_e_2 long 0

theta long 0

K_s long 0.5


'***************************************************
'*********** MOTOR BLOCK ***************************
'***************************************************
PID_M_x_base long 0
PID_M_y_base long 0
PID_M_z_base long 0
PID_F_z_base long 0
PID_n_1_base long 0
PID_n_2_base long 0
PID_n_3_base long 0
PID_n_4_base long 0




'***************************************************
'*********** MOMENT BLOCK **************************
'***************************************************
'Moment I/O Variables

			long	0, 0
omega_b_x	long 0
omega_b_y	long 0
omega_b_z	long 0

omega_b_x_int	long 0
omega_b_y_int	long 0
omega_b_z_int	long 0

			long 0, 0
accel_b_x	long 0
accel_b_y	long 0
accel_b_z	long 0

accel_b_x_int	long 0
accel_b_y_int	long 0
accel_b_z_int	long 0

	
			long 0, 0
q_0			long 0
q_1			long 0
q_2			long 0
q_3			long 0

			long 0, 0
q_d_0		long 1.0
q_d_1		long 0.0
q_d_2		long 0.0
q_d_3		long 0.0

			long 0, 0
M_x			long 0.0'-1.15762          'Needs to be on the order of 0-15
M_y			long 0.0'1.15762'0.4280494 'Needs to be on the order of 0-15
M_z			long 0.0'-0.4372189        'Needs to be on the order of 0-0.1
	
'Moment Intermediate Variables
	

			long 0, 0
alpha		long 0


			long 0, 0
alpha_H		long 0

			long 0, 0
beta_h		long 0

			long 0, 0
gamma_h		long 0


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

K_PH_x		long 0.0 'TODO: not useful, since it's not used by PIDs
K_PH_y		long 0.0
K_PH_z		long 0.0

K_IH_x		long 0.0 'TODO: not useful, since it's not used by PIDs
K_IH_y		long 0.0
K_IH_z		long 0.0

K_DH_x		long 0.0000 'TODO: not useful, since it's not used by PIDs
K_DH_y		long 0.0000
K_DH_z		long 0.0

moment_setpoint long 0.0


'***************************************************
'*********** MOTOR BLOCK ***************************
'***************************************************


			long 0, 0
K_Q			long 0.003782 'Measured with pot scale (measured with spring scale->2.65764)
			long 0, 0
K_T			long 0.077277 ' Measured 0.67504kg with the spring scale

				'Measured with accurate scale:
				'Torque: 3.400kg at 0.1524m (6in)
				'The motor is at 24 in, so it has 3.4/4 == 0.85kg of thrust
				'That's 0.85*9.8 == 8.33 Newtons
				'K_T = 8.33 / (1.151 * 150^2 * .254^4) = .077277
				

			long 0, 0
diameter	long 0.254		'D in the documentation, 10in rotors

			long 0, 0
offset		long 0.333		'd in the documentation

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
rho			long 1.151		'Air density @ 20C (70F), 305m, and 30%humidity

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
n_1_int		long 0
			long 0, 0
n_2_int		long 0
			long 0, 0
n_3_int		long 0
			long 0, 0
n_4_int		long 0

			long 0, 0
n_d_1		long 0
			long 0, 0
n_d_2		long 0
			long 0, 0
n_d_3		long 0
			long 0, 0
n_d_4		long 0

				long 0, 0
PID_n_1_output	long 0
				long 0, 0
PID_n_2_output	long 0
				long 0, 0
PID_n_3_output	long 0
				long 0, 0
PID_n_4_output	long 0


'These are the float values of the output:
			long 0, 0
u_1			long 0
			long 0, 0
u_2			long 0
			long 0, 0
u_3			long 0
			long 0, 0
u_4			long 0

'These are the integer values of the PWM output:
			long 0, 0
motor_pwm_1	long 0
			long 0, 0
motor_pwm_2	long 0
			long 0, 0
motor_pwm_3	long 0
			long 0, 0
motor_pwm_4	long 0


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
'*********** Predefined Constants ******************
'***************************************************

'Black motor, black ESC
'motor_slope		long 0.238867
'motor_intercept long 229.37517
'MIN_PWM long 1000.0
'MAX_PWM long 1600.0

'Black motor, red ESC
motor_slope		long 0.21568 '4.6365
motor_intercept long 220.770 '1023.57
MIN_PWM long 1000.0
MAX_PWM long 1800.0


motor_kp long 1.0'12.0
motor_ki long 0.259' 9.0
motor_kd long 0.0'0.1


quat_scalar  long 0.0000335693 'From the UM6 datasheet
accel_scalar long 0.000183105
gyro_scalar  long 0.0610352
euler_scalar long 0.0109863


'***************************************************
'*********** WORKING VARIABLES *********************
'***************************************************

t_1			long 0
t_2			long 0
t_3			long 0
t_4			long 0
t_5			long 0
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
