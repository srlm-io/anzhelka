# Introduction #

In order to exchange data between different processors and systems we need  a communication protocol to handle the exchange in a reliable and predictable format. The Anzhelka project uses a protocol very similar to NMEA-0183 where data is exchanged via sentences prefaced with a sentence code.

All strings are in standard ASCII. Numbers are converted to their ASCII equivalent and are in base 10 unless otherwise noted. If a number is decimal then it will have the ASCII decimal point included in the sentence string. I.E, all numbers are floats (although some, such as PWM, may be intended to be converted to integer).

Note that the only defined whitespace in a string is a single space after the sentence code.

For all strings shown below any of the data values may be replaced by a `*`. For example,

`$ADRPS *,*,48,*`

The `*` denotes no information transmitted for that value. It does not indicate a malfunction, or a lack of data, or anything but what it is: a placeholder. It can be used for anywhere a number would normally be placed. How the presence of a `*` is interpreted is determined by the receiver.

# Command #
Command strings are prefaced with $ACxxx (short for Anzhelka Command type xxx). Command strings are used to set runtime parameters onboard the quadrotor.

## $ACRDR ##
(Read Data register... Need to fill in.)
## $ACSDR ##

Sets the data type registers that are specified. This command is used to set any of the variables reported on by the data strings. Note that this is a one time update, and it may be ignored or quickly overwritten at the receivers discretion. It's most useful to for setting lower level variables during testing, and higher level registers (such as constants) during runtime.

For example, you can set the motor PWM values by the following command:

`$ACSDR PWM,1000,1250,1500,2000`

This will tell the receiver to update it's PWM registers with the four values specified, in the same order as the $ADPWM command.

To set the K<sub>P</sub> value of motor 3, you could send the command

`$ACSDR MKP,*,*,23.42,*`

This will set Motor 3 K<sub>P</sub> to 23.42, and not set any of the other 3 values.

The format of this command depends on the data string format. The xxx should be replaced by the unique three letter data string code, and then the following arguments should match what is described by the associated commands.

Format:

`$ACSDR xxx,t1,t2,...,tn`

## $ACSTP ##

Quadrotor stop command. This command will stop the quadrotor, based on the parameter:

Parameter Choices:
  * EMG - Emergency stop (complete shutdown of all moving systems)
  * IMM - Immediate. Will attempt to land immediately.
  * CON - Controlled stop. Will make an educated decision.

There is only one parameter.

Format:

`$ACSTP parameter`

More to come...
# Data Strings #
Data strings are prefaced with $ADxxx (short for Anzhelka Data type xxx). You can use data strings to report on the runtime characteristics of the quadrotor.

All data string numbers are floating point, although the decimal is option (ie, if there is no decimal portion of the number, the point is not needed).

In addition, every data string transmits with the system clock value. This is not the main system clock ("cnt" on the Propeller), but a divided down version suitable for transmission. 1 unit on the clock value is equal to:

`2^16 / clock_freq` seconds

Which, on the Propeller running at 100MHz, comes out to 0.00065536s. To convert, use this formula:

`realtime = receivedclock * (2^16 / clock_freq)`

Alternatively, you could just use the received clock count directly and not convert it to real units.

## $ADSTR ##
Information string, useful for conveying human readable information. Content is any sequence of ascii characters except for single quotes (').

Format:

`$ADSTR clock,'content'`



## $ADNIM ##
Most recent rotations per second for each motor. Stands for n\_i\_measured.

Format:

`$ADNIM clock,m1,m2,m3,m4`


## $ADNID ##
Most recent motor rotations per second setpoint. This is the speed that motors are trying to achieve, and is fed into the motor PID loops. Stands for n\_i\_desired.

Format:

`$ADNID clock,m1,m2,m3,m4`

## $ADMVV ##
Format:

`$ADMVV clock,m1,m2,m3,m4`


## $ADMIA ##
Most recent motor current in milliamps.

Format:

`$ADMIA clock,m1,m2,m3,m4`

## $ADPWM ##
Most recent motor PWM command, in microseconds (uS)

Format:

`$ADPWM clock,m1,m2,m3,m4`

## $ADMKP ##
Current motor PID loop proportional constant (K<sub>P</sub>). No units.

Format:

`$ADMKP clock,m1,m2,m3,m4`

## $ADMKI ##
Current clock,motor PID loop integral constant (K<sub>I</sub>). No units.

Format:

`$ADMKI clock,m1,m2,m3,m4`

## $ADMKD ##
Current clock,motor PID loop derivative constant (K<sub>D</sub>). No units.

Format:

`$ADMKD clock,m1,m2,m3,m4`

## $ADMTH ##
Most recent motor thrust in units of Newtons.

Format:

`$ADMTH clock,m1,m2,m3,m4`
## $ADMTQ ##
Most recent motor torque in units of Newton-Meters.

Format:

`$ADMTQ clock,m1,m2,m3,m4`

## $ADMOM ##
Most recent calculated moment. (Units ?)

Format:

`$ADMOM clock,M_x,M_y,M_z`

## $ADFZZ ##
Most recent calculated force Z. (Units ?)

Format:

`$ADFZZ clock,F_z`

## $ADMPP ##
The motor\_slope and motor\_intercept constants. Stands for Motor PWM Proportion.

Format:

`$ADMPP clock,motor_slope,motor_intercept`


## $ADQII ##
The most recent orientation quaternion.

w is the scalar part, and (x,y,z) is the vector part.

Format:

`$ADQDI clock,w,x,y,z`

## $ADQDI ##
The desired orientation quaternion of the quadrotor.

w is the scalar part, and (x,y,z) is the vector part.

Format:

`$ADQDI clock,w,x,y,z`

## $ADQEI ##
The most recent error quaternion (calculated, by the Propeller, difference between QII and QDI).

w is the scalar part, and (x,y,z) is the vector part.

Format:

`$ADQEI clock,w,x,y,z`

## $ADCLF ##

The current frequency of the control loop, in Hz.

Format:

`$ADCLF clock,frequency`

## $ADKPH ##

Moment Constant Proportional Heading

Format:

`$ADKPH clock,x,y,z`

## $ADKIH ##

Moment Constant Integral Heading

Format:

`$ADKIH clock,x,y,z`

## $ADKDH ##

Moment Constant Derivative Heading

Format:

`$ADKDH clock,x,y,z`

## $ADOMG ##

Angular rate of the Body processed from the gryos. Omega

Format:

`$ADOMG clock,x,y,z`

## $ADACC ##

Acceleration rate of the Body processed from the accelerometers.

Format:

`$ADACC clock,x,y,z`