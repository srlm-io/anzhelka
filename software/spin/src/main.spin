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
	
	

	
	
{{AZM_MATH CONTROL_LOOP

'n_1 = fp_clkfreq / ((n_1_int ffloat 0) * 6)
'n_2 = fp_clkfreq / ((n_2_int ffloat 0) * 6)
'n_3 = fp_clkfreq / ((n_3_int ffloat 0) * 6)
'n_4 = fp_clkfreq / ((n_4_int ffloat 0) * 6)

n_1 = n_1_int ffloat 0
n_2 = n_2_int ffloat 0
n_3 = n_3_int ffloat 0
n_4 = n_4_int ffloat 0

'Make sure to do the shifting before calling this routine!
q_0 = (quat_a ffloat 0) * quat_scalar
q_1 = (quat_b ffloat 0) * quat_scalar
q_2 = (quat_c ffloat 0) * quat_scalar
q_3 = (quat_d ffloat 0) * quat_scalar

omega_b_x = (omega_b_x_int ffloat 0) * gyro_scalar
omega_b_y = (omega_b_x_int ffloat 0) * gyro_scalar
omega_b_z = (omega_b_x_int ffloat 0) * gyro_scalar

accel_b_x = (accel_b_x_int ffloat 0) * accel_scalar
accel_b_y = (accel_b_x_int ffloat 0) * accel_scalar
accel_b_z = (accel_b_x_int ffloat 0) * accel_scalar

euler_phi   = (euler_phi_int   ffloat 0) * euler_scalar
euler_theta = (euler_theta_int ffloat 0) * euler_scalar
euler_psi   = (euler_psi_int   ffloat 0) * euler_scalar


'Normalize measured quaternion:
t_1 = (((q_0 * q_0) + (q_1 * q_1)) + ((q_2 * q_2) + (q_3 * q_3))) sqrt 0
q_0 = q_0 / t_1
q_1 = q_1 / t_1
q_2 = q_2 / t_1
q_3 = q_3 / t_1



'***************************************************
'*********** MOMENT BLOCK **************************
'***************************************************
''

'q star:
q_1 = 0 - q_1
q_2 = 0 - q_2
q_3 = 0 - q_3

'Moment Block, first Quat Mul
'From here: http://www.j3d.org/matrix_faq/matrfaq_latest.html#Q53
'q_tilde_0 = ((q_d_0*q_0) - (q_d_1*q_1)) - ((q_d_2*q_2) - (q_d_3*q_3))
'q_tilde_1 = ((q_d_0*q_1) + (q_d_1*q_0)) + ((q_d_2*q_3) - (q_d_3*q_2))
'q_tilde_2 = ((q_d_0*q_2) + (q_d_2*q_0)) + ((q_d_3*q_1) - (q_d_1*q_3))
'q_tilde_3 = ((q_d_0*q_3) + (q_d_3*q_0)) + ((q_d_1*q_2) - (q_d_2*q_1))

'Moment Block, first Quat Mul
q_tilde_0 = ((q_d_0*q_0) - (q_d_1*q_1)) - ((q_d_2*q_2) - (q_d_3*q_3))
q_tilde_1 = ((q_d_0*q_1) + (q_d_1*q_0)) + ((q_d_2*q_3) - (q_d_3*q_2))
q_tilde_2 = ((q_d_0*q_2) - (q_d_1*q_3)) + ((q_d_2*q_0) + (q_d_3*q_1))
q_tilde_3 = ((q_d_0*q_3) + (q_d_1*q_2)) - ((q_d_2*q_1) + (q_d_3*q_0))
'     Autogenerated quat multiplication with ./tool/quat_replace.py

''Normalize Quaternion
t_1 = (((q_tilde_0 * q_tilde_0) + (q_tilde_1 * q_tilde_1)) + ((q_tilde_2 * q_tilde_2) + (q_tilde_3 * q_tilde_3))) sqrt 0
q_tilde_0 = q_tilde_0 / t_1
q_tilde_1 = q_tilde_1 / t_1
q_tilde_2 = q_tilde_2 / t_1
q_tilde_3 = q_tilde_3 / t_1



alpha = 2 * (q_tilde_0 arc_c 0)


t_1 = (alpha / 2) sin 0

r_e_1 = q_tilde_1 / t_1
r_e_2 = q_tilde_2 / t_1
r_e_3 = q_tilde_3 / t_1

'Moment Block, r_b first (lhs) quat mult:
'q_temp := q* (x) r_e
'  Important: q needs to be starred comming into this...
q_temp_0 = ((q_0*0) - (q_1*r_e_1)) - ((q_2*r_e_2) - (q_3*r_e_3))
q_temp_1 = ((q_0*r_e_1) + (q_1*0)) + ((q_2*r_e_3) - (q_3*r_e_2))
q_temp_2 = ((q_0*r_e_2) - (q_1*r_e_3)) + ((q_2*0) + (q_3*r_e_1))
q_temp_3 = ((q_0*r_e_3) + (q_1*r_e_2)) - ((q_2*r_e_1) + (q_3*0))
' Autogenerated quat multiplication with ./tool/quat_replace.py


'q star:
q_1 = 0 - q_1
q_2 = 0 - q_2
q_3 = 0 - q_3

'Moment Block, r_b second (rhs) quat mult:
' r_b := q_temp_0 (x) q
'  Important: q needs to be not stared before multiplying...
'0 = ((q_temp_0*q_0) - (q_temp_1*q_1)) - ((q_temp_2*q_2) - (q_temp_3*q_3))
r_b_1 = ((q_temp_0*q_1) + (q_temp_1*q_0)) + ((q_temp_2*q_3) - (q_temp_3*q_2))
r_b_2 = ((q_temp_0*q_2) - (q_temp_1*q_3)) + ((q_temp_2*q_0) + (q_temp_3*q_1))
r_b_3 = ((q_temp_0*q_3) + (q_temp_1*q_2)) - ((q_temp_2*q_1) + (q_temp_3*q_0))
'     Autogenerated quat multiplication with ./tool/quat_replace.py

t_1 = (alpha / 2) sin 0
q_tilde_b_0 = (alpha / 2) cos 0
q_tilde_b_1 = t_1 * r_b_1
q_tilde_b_2 = t_1 * r_b_2
q_tilde_b_3 = t_1 * r_b_3

''Normalize Quaternion
t_1 = (((q_tilde_b_0 * q_tilde_b_0) + (q_tilde_b_1 * q_tilde_b_1)) + ((q_tilde_b_2 * q_tilde_b_2) + (q_tilde_b_3 * q_tilde_b_3))) sqrt 0
q_tilde_b_0 = q_tilde_b_0 / t_1
q_tilde_b_1 = q_tilde_b_1 / t_1
q_tilde_b_2 = q_tilde_b_2 / t_1
q_tilde_b_3 = q_tilde_b_3 / t_1



alpha_H =  (1- (2 * ((q_tilde_b_1 * q_tilde_b_1) + (q_tilde_b_2 * q_tilde_b_2)))) arc_c 0
phi = 2 * (q_tilde_b_3 arc_t2 q_tilde_b_0)

t_1 = (phi / 2) cos 0
t_2 = (phi / 2) sin 0
t_3 = (alpha_H / 2) sin 0

r_x = ((t_1 * q_tilde_b_1) - (t_2 * q_tilde_b_2)) / t_3
r_y = ((t_2 * q_tilde_b_1) + (t_1 * q_tilde_b_2)) / t_3
beta_H = r_y arc_t2 r_x

'TODO: need to add a derivative term, at least.
M_x = ((K_PH_x * alpha_H) * (beta_H cos 0)) - (K_DH_x * omega_b_x)
M_y = ((K_PH_y * alpha_H) * (beta_H sin 0)) - (K_DH_y * omega_b_y)

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


''Follows the inverse of this equation:
''	rpm = slope * pwm + intercept
'' Graph it in open office, then create a trend line. The given values plug directly in (in anzhelka_variables)


''t_1, t_2, etc. are placeholders. Results are in:
''PID_n_1_output
''PID_n_2_output
''PID_n_3_output
''PID_n_4_output

t_1 = PID_n_1_base ~ 0
t_2 = PID_n_2_base ~ 0
t_3 = PID_n_3_base ~ 0
t_4 = PID_n_4_base ~ 0

'Apply the PID to the motor output equation
u_1 = ((n_d_1 + motor_intercept) / motor_slope ) + PID_n_1_output
u_1 = (u_1 #> MIN_PWM) <# MAX_PWM

u_2 = ((n_d_2 + motor_intercept) / motor_slope ) + PID_n_2_output
u_2 = (u_2 #> MIN_PWM) <# MAX_PWM

u_3 = ((n_d_3 + motor_intercept) / motor_slope ) + PID_n_3_output
u_3 = (u_3 #> MIN_PWM) <# MAX_PWM

u_4 = ((n_d_4 + motor_intercept) / motor_slope ) + PID_n_4_output
u_4 = (u_4 #> MIN_PWM) <# MAX_PWM

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
