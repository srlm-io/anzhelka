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
--- Implements the motor control block (#3) from the quadrotor mathematics document.
TODO:

}}


OBJ
'	fp	: "Float32.spin"
'    fp  : "Float.spin"
	fp : "F32.spin"
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
	long	q_1, q_2, q_3, q_4
	long	q_d_1, q_d_2, q_d_3, q_d_4
	
	long	K_PH, K_DH, K_P_z, K_D_z
	
	long	M_x, M_y, M_z
	
'Intermediate Variables (local only, not written out or in)
	long t_1


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


PUB GetResultAddr
	return @M_x
	
PUB SetInput

	omega_b_x := long[omega_b_addr][0]
	omega_b_y := long[omega_b_addr][1]
	omega_b_z := long[omega_b_addr][2]
	
	q_1 := long[q_addr][0]
	q_2 := long[q_addr][1]
	q_3 := long[q_addr][2]
	q_4 := long[q_addr][3]
	
	q_d_1 := long[q_d_addr][0]
	q_d_2 := long[q_d_addr][1]
	q_d_3 := long[q_d_addr][2]
	q_d_4 := long[q_d_addr][3]
	
	K_PH := long[K_PH_addr]
	K_DH := long[K_DH_addr]
	
	K_P_z := long[K_P_z_addr]
	K_D_z := long[K_D_z_addr]


PUB SetOutput
	long[M_addr][0] := M_x
	long[M_addr][1] := M_y
	long[M_addr][2] := M_z

	
PUB Calculate
'One iteration of the calculations
'Should be called from a repeat loop...
'Writes object local variables, does not write to address
'	M_x := fp.FMul(omega_b_x, float(3))
'	M_y := fp.FMul(omega_b_y, float(3))
'	M_z := fp.FMul(omega_b_z, float(3))
	QuatMul(@q_1, @q_d_1, @q_1)
	
	M_x := q_1
	M_y := q_2
	M_z := q_4







PUB VectNorm(v_addr, v_result_addr) | a, b, c, t1, t2, t3, norm

	a := long[v_addr][0]
	b := long[v_addr][1]
	c := long[v_addr][2]
	
	t1 := fp.FMul(a, a)
	t2 := fp.FMul(b, b)
	t3 := fp.FMul(c, c)
	
	norm := fp.FAdd(t1, t2) 'Not Parallel
	norm := fp.FAdd(t1, t3) 'Not Parallel
	
	a := fp.FDiv(a, norm)
	b := fp.FDiv(b, norm)
	c := fp.FDiv(c, norm)
	
	long[v_result_addr][0] := a
	long[v_result_addr][1] := b
	long[v_result_addr][2] := c
	
PUB VectDot(v_1_addr, v_2_addr, v_result_addr)

	long[v_result_addr][0] := fp.FMul(long[v_1_addr][0], long[v_2_addr][0])
	long[v_result_addr][1] := fp.FMul(long[v_1_addr][1], long[v_2_addr][1])
	long[v_result_addr][2] := fp.FMul(long[v_1_addr][2], long[v_2_addr][2])
	
PUB QuatStar(q_1_addr, q_result_addr)
	
	long[q_result_addr][0] :=         long[q_1_addr][0]
	long[q_result_addr][1] := fp.FNeg(long[q_1_addr][1])
	long[q_result_addr][2] := fp.FNeg(long[q_1_addr][2])
	long[q_result_addr][3] := fp.FNeg(long[q_1_addr][3])

PUB QuatMul(q_1_addr, q_2_addr, q_result_addr) | w, x, y, z, t1, t2, t3, t4, w1, x1, y1, z1, w2, x2, y2, z2
'	w1, x1, y1, z1 = q1
'	w2, x2, y2, z2 = q2
'	
	w1 := long[q_1_addr][0]
	x1 := long[q_1_addr][1]
	y1 := long[q_1_addr][2]
	z1 := long[q_1_addr][3]

	w2 := long[q_2_addr][0]
	x2 := long[q_2_addr][1]
	y2 := long[q_2_addr][2]
	z2 := long[q_2_addr][3]


'	w = ([w1*w2] - x1*x2 - y1*y2 - z1*z2)
'	x = ([w1*x2] + x1*w2 + y1*z2 - z1*y2)
'	y = ([w1*y2] - x1*z2 + y1*w2 + z1*x2)
'	z = ([w1*z2] + x1*y2 - y1*x2 + z1*w2)
	w := fp.FMul(w1,w2)
	x := fp.FMul(w1,x2)
	y := fp.FMul(w1,y2)
	z := fp.FMul(w1,z2)
	
'	w = (w1*w2 - [x1*x2] - y1*y2 - z1*z2)
'	x = (w1*x2 + [x1*w2] + y1*z2 - z1*y2)
'	y = (w1*y2 - [x1*z2] + y1*w2 + z1*x2)
'	z = (w1*z2 + [x1*y2] - y1*x2 + z1*w2)
	t1 := fp.FMul(x1,x2)
	t2 := fp.FMul(x1,w2)
	t3 := fp.FMul(x1,z2)
	t4 := fp.FMul(x1,y2)
	
	
'	w = ([w1*w2 - x1*x2] - y1*y2 - z1*z2)
'	x = ([w1*x2 + x1*w2] + y1*z2 - z1*y2)
'	y = ([w1*y2 - x1*z2] + y1*w2 + z1*x2)
'	z = ([w1*z2 + x1*y2] - y1*x2 + z1*w2)
	w := fp.FSub(w, t1)
	x := fp.FAdd(x, t2)
	y := fp.FSub(y, t3)
	z := fp.FAdd(z, t4)
		
'	w = (w1*w2 - x1*x2 - [y1*y2] - z1*z2)
'	x = (w1*x2 + x1*w2 + [y1*z2] - z1*y2)
'	y = (w1*y2 - x1*z2 + [y1*w2] + z1*x2)
'	z = (w1*z2 + x1*y2 - [y1*x2] + z1*w2)
	t1 := fp.FMul(y1,y2)
	t2 := fp.FMul(y1,z2)
	t3 := fp.FMul(y1,w2)
	t4 := fp.FMul(y1,x2)
	
'	w = ([w1*w2 - x1*x2 - y1*y2] - z1*z2)
'	x = ([w1*x2 + x1*w2 + y1*z2] - z1*y2)
'	y = ([w1*y2 - x1*z2 + y1*w2] + z1*x2)
'	z = ([w1*z2 + x1*y2 - y1*x2] + z1*w2)
	w := fp.FSub(w, t1)
	x := fp.FAdd(x, t2)
	y := fp.FAdd(y, t3)
	z := fp.FSub(z, t4)
	
'	w = (w1*w2 - x1*x2 - y1*y2 - [z1*z2])
'	x = (w1*x2 + x1*w2 + y1*z2 - [z1*y2])
'	y = (w1*y2 - x1*z2 + y1*w2 + [z1*x2])
'	z = (w1*z2 + x1*y2 - y1*x2 + [z1*w2])
	t1 := fp.FMul(z1,z2)
	t2 := fp.FMul(z1,y2)
	t3 := fp.FMul(z1,x2)
	t4 := fp.FMul(z1,w2)
	
'	w = ([w1*w2 - x1*x2 - y1*y2 - z1*z2])
'	x = ([w1*x2 + x1*w2 + y1*z2 - z1*y2])
'	y = ([w1*y2 - x1*z2 + y1*w2 + z1*x2])
'	z = ([w1*z2 + x1*y2 - y1*x2 + z1*w2])
	w := fp.FSub(w, t1)
	x := fp.FSub(x, t2)
	y := fp.FAdd(y, t3)
	z := fp.FAdd(z, t4)
	

	long[q_result_addr][0] := w
	long[q_result_addr][1] := x
	long[q_result_addr][2] := y
	long[q_result_addr][3] := z

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

