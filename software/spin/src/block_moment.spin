{{

--------------------------------------------------------------------------------
Anzhelka Project
(c) 2012

For the latest code and support, please visit:
http://code.anzhelka.com
--------------------------------------------------------------------------------

Title: Anzhelka Motor Control Block
Author: Cody Lewis
Date: May 13, 2012

Notes: 
--- Implements the momoment control block (#1) from the quadrotor mathematics document.
TODO:

}}

OBJ
	fp  : "F32_CMD.spin"


VAR
''Input Variables
	long omega_b_addr
	long q_addr
	long q_d_addr
	
''Input Constants
	long K_PH_addr
	long K_DH_addr
	long K_P_z_addr
	long K_D_z_addr

''Output Variables
	long M_addr

VAR
'Given Variables (with addresses)
	long	omega_b_x, omega_b_y, omega_b_z
	long	q_0, q_1, q_2, q_3
	long	q_d_0, q_d_1, q_d_2, q_d_3
	
	long	K_PH, K_DH, K_P_z, K_D_z
	
	long	M_x, M_y, M_z
	
'Intermediate Variables (local only, not written out or in)
	
	long alpha
	long alpha_H
	long beta_h
	long phi
	long q_temp_0
	long q_temp_1
	long q_temp_2
	long q_temp_3
	long q_tilde_0
	long q_tilde_1
	long q_tilde_2
	long q_tilde_3
	long q_tilde_b_0
	long q_tilde_b_1
	long q_tilde_b_2
	long q_tilde_b_3
	long r_b_1
	long r_b_2
	long r_b_3
	long r_e_1
	long r_e_2
	long r_e_3
	long r_x
	long r_y
	long t_1
	long t_2
	long t_3


PUB Start({
Input Variables:
	} omega_b_addr_,{	Angular Velocity in the body frame
	} q_addr_,{         Current Orientation Quaternion
	} q_d_addr_, {      Desired Quaternion
	
Input Constants:
	} K_PH_addr_,{	    tilt moment proportional constant
	} K_DH_addr_,{      tilt moment derivative constant
	} K_P_z_addr_,{     yaw moment derivative constant
	} K_D_z_addr_,{     yaw moment derivative constant

Output Variables:
	} M_addr_{	        total rotor moments
}) : okay

	'Copy the addresses:
	omega_b_addr := omega_b_addr_
	q_addr       := q_addr_
	q_d_addr     := q_d_addr_
	K_PH_addr    := K_PH_addr_
	K_DH_addr    := K_DH_addr_
	K_P_z_addr   := K_P_z_addr_
	K_D_z_addr   := K_D_z_addr_
	M_addr       := M_addr_

	fp.start
	Init_Instructions



'PUB GetResultAddr
'	return @M_x
	
PUB SetInput

	omega_b_x := long[omega_b_addr][0]
	omega_b_y := long[omega_b_addr][1]
	omega_b_z := long[omega_b_addr][2]
	
	q_0 := long[q_addr][0]
	q_1 := long[q_addr][1]
	q_2 := long[q_addr][2]
	q_3 := long[q_addr][3]
	
	q_d_0 := long[q_d_addr][0]
	q_d_1 := long[q_d_addr][1]
	q_d_2 := long[q_d_addr][2]
	q_d_3 := long[q_d_addr][3]
	
	K_PH := long[K_PH_addr]
	K_DH := long[K_DH_addr]
	
	K_P_z := long[K_P_z_addr]
	K_D_z := long[K_D_z_addr]


PUB SetOutput
	long[M_addr][0] := r_x
	long[M_addr][1] := r_y
	long[M_addr][2] := beta_H

	
PUB Calculate
'One iteration of the calculations
'Should be called from a repeat loop...
'Writes object local variables, does not write to address
	
	fp.FInterpret(@MOMENT_BLOCK_INSTRUCTIONS)
	
{{AZM_MATH MOMENT_BLOCK


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

