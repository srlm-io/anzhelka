{{
--------------------------------------------------------------------------------
Anzhelka Project
(c) 2012

For the latest code and support, please visit:
http://code.anzhelka.com
--------------------------------------------------------------------------------

Title: Eagle Tree Brushless RPM
Author: Cody Lewis (SRLM)
Date: 3-25-2012
Notes: Original author Tim Moore, (c) 2010.

TODO: Check for 80MHz hardcoded values
TODO: in getrpm and getrps precompute 80_000_000 / 6




  Brushless eagletree RPM Sensor (http://hobbyking.com/hobbyking/store/uh_viewItem.asp?idProduct=4635)

  Connect black to 3.3V, red to Gnd, white to prop pin
}}
Con
  Mhz    = (80+10)                                      ' System clock frequency in Mhz. + init instructions
  
  MAX_RPS_CHANGE = 60
   
VAR
  long  Cog
  long  Pins[8]
  long  PinShift                                          
  long  PinMask
  long	previous_speed

PUB setpins(_pinmask)
'' Set pinmask for active input pins [0..31]
'' Example: setpins(%0010_1001) to read from pin 0, 3 and 5
'
  PinMask := _pinmask
  PinShift := 0
  repeat 32
    if _pinmask & 1
      quit
    _pinmask >>= 1
    PinShift++ 

PUB start : sstatus
'' Start driver (1 Cog)  
'' - Note: Call setpins() before start
'
  previous_speed := 0
  if not Cog
    longfill(@Pins, 0, 8)
    sstatus := Cog := cognew(@INIT, @Pins) + 1

PUB stop
'' Stop driver and release cog
'
  if Cog
    cogstop(Cog~ - 1)

PUB getpinptr
  return @Pins

PUB getrpm(i) | speed
'' Get the RPM of motor i (by index, not pin number)
'' Valid index range is 0-7
'' Returns -1 when no valid data
	speed := getrps(i)
	if speed > -1 'Valid
		return speed * 60
	else		'Invalid number
		return speed 
		
PUB getrps(i) | delta, speed
'' Get the RPS of motor i (by index, not pin number)
'' Valid index range is 0-7
'' Returns -1 when no valid data
	if i > 7 OR i < 0 'Check Range
		return -1
	
	delta := Pins[i]
	
	if delta == 0
		return -1
	
	speed := (clkfreq / (delta*6))
'	if (||(speed - previous_speed)) > MAX_RPS_CHANGE
'		return -1
'	
'	previous_speed := speed
	
	return speed

PUB getpins(i)
	return Pins[i]	


DAT
        org   0

INIT    mov   p1, par                           ' Get data pointer
        add   p1, #4*8                          ' Point to PinShift
        rdlong shift, p1                        ' Read PinShift
        add   p1, #4
        rdlong pin_mask, p1                     ' Read PinMask
        andn  dira, pin_mask                    ' Set input pins

'=================================================================================

:loop   mov   d2, d1                            ' Store previous pin status
        waitpne d1, pin_mask                    ' Wait for change on pins
        mov   d1, ina                           ' Get new pin status 
        mov   c1, cnt                           ' Store change cnt                           
        and   d1, pin_mask                      ' Remove unrelevant pin changes
        shr   d1, shift                         ' Get relevant pins in 8 LSB
{
d2      1100
d1      1010
-------------
!d2     0011
&d1     1010
=       0010 POS edge
}
        ' Mask for POS edge changes
        mov   d3, d1
        andn  d3, d2

'=================================================================================

:POS    'tjz   d3, #:loop                       ' Skip if no POS edge changes
        mov   p1, par							' Hub variable address
'Pin 0
        test  d3, #%0000_0001   wz				' Change on pin?
        mov   d4, c1							' Copy :loop count value to d4
        sub   d4, pe0							' Subtract old count value from new count value ( delta(cv) = d4 - peo )
        										' If pos change:
if_nz   cmp   d4, mintim wc						' 	-> write c if d4 (delta count value) is less than minimum time
if_nz_and_nc wrlong d4, p1						'	-> write the delta count value to the hub if greater than minimum time
if_nz_and_nc mov   pe0, c1                      '	-> Store POS edge change cnt (system clk time, not delta)
												' If no pos change:
if_z    cmp   d4, maxtim wc						' 	-> write c if d4 (count value) is less than maximum time 
if_z_and_nc wrlong zero, p1						'	-> write zero to the hub if greater than maximum time

'Pin 1
        add   p1, #4
        test  d3, #%0000_0010   wz              ' ...
        mov   d4, c1
        sub   d4, pe1
if_nz   cmp   d4, mintim wc
if_nz_and_nc wrlong d4, p1
if_nz_and_nc mov   pe1, c1
if_z    cmp   d4, maxtim wc
if_z_and_nc wrlong zero, p1
'Pin 2
        add   p1, #4
        test  d3, #%0000_0100   wz
        mov   d4, c1
        sub   d4, pe2
if_nz   cmp   d4, mintim wc
if_nz_and_nc wrlong d4, p1
if_nz_and_nc mov   pe2, c1
if_z    cmp   d4, maxtim wc
if_z_and_nc wrlong zero, p1
'Pin 3
        add   p1, #4
        test  d3, #%0000_1000   wz
        mov   d4, c1
        sub   d4, pe3
if_nz   cmp   d4, mintim wc
if_nz_and_nc wrlong d4, p1
if_nz_and_nc mov   pe3, c1
if_z    cmp   d4, maxtim wc
if_z_and_nc wrlong zero, p1
'Pin 4
        add   p1, #4
        test  d3, #%0001_0000   wz
        mov   d4, c1
        sub   d4, pe4
if_nz   cmp   d4, mintim wc
if_nz_and_nc wrlong d4, p1
if_nz_and_nc mov   pe4, c1
if_z    cmp   d4, maxtim wc
if_z_and_nc wrlong zero, p1
'Pin 5
        add   p1, #4
        test  d3, #%0010_0000   wz
        mov   d4, c1
        sub   d4, pe5
if_nz   cmp   d4, mintim wc
if_nz_and_nc wrlong d4, p1
if_nz_and_nc mov   pe5, c1
if_z    cmp   d4, maxtim wc
if_z_and_nc wrlong zero, p1
'Pin 6
        add   p1, #4
        test  d3, #%0100_0000   wz
        mov   d4, c1
        sub   d4, pe6
if_nz   cmp   d4, mintim wc
if_nz_and_nc wrlong d4, p1
if_nz_and_nc mov   pe6, c1
if_z    cmp   d4, maxtim wc
if_z_and_nc wrlong zero, p1
'Pin 7
        add   p1, #4
        test  d3, #%1000_0000   wz
        mov   d4, c1
        sub   d4, pe7
if_nz   cmp   d4, mintim wc
if_nz_and_nc wrlong d4, p1
if_nz_and_nc mov   pe7, c1
if_z    cmp   d4, maxtim wc
if_z_and_nc wrlong zero, p1

        jmp   #:loop

fit Mhz                                         ' Check for at least 1µs resolution with current clock speed

'=================================================================================

mintim  long  3000
maxtim  long  10_000_000

pin_mask long %0000_0000
shift   long  0

c1      long  0
               
d1      long  0
d2      long  0
d3      long  0
d4      long  0

p1      long  0

pe0     long  0
pe1     long  0
pe2     long  0
pe3     long  0
pe4     long  0
pe5     long  0
pe6     long  0
pe7     long  0

zero    long  0

        FIT   496
