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

K_PH_x		long 0.2
K_PH_y		long 0.2
K_P_z		long 0.0
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


quat_scalar long 0.0000335693 'From the UM6 datasheet

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
