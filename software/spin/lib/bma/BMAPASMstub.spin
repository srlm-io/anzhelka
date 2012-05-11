{{
PASMstub.spin - uses a small 7+3 long PASM "emulation" communications routine
Copyright (c) 2009 by John Steven Denson (jazzed)
See MIT License Terms
}}

' Version 1.7 - Date 2009.12.22

con
  PC = 8
  
dat
'pasm org  0
{    
'----------------------------------------------------------------------
' 7 instructions + dirb,inb,outb
' user can be anything after startup ...
:user   neg         outb,   :insa       ' 0 save neg of :insa to outb $xxxx7fff ... adjust later
:wait   rdlong      :inst,  outb        ' 1 wait for instruction to be non-zero
        tjnz        :inst,  #:wait      ' 2 wait while inst still zero
:geti   rdlong      :inst,  outb        ' 3 get instruction
        tjz         :inst,  #:geti      ' 4 wait while inst is zero - delay slot for SMC
:inst   nop                             ' 5 the instruction to execute
:insa   long        $5c7c8001           ' 6 Changes to "jmp #1" by the neg :insa, :insa
'       nop                             ' 7 use for "go" address
'----------------------------------------------------------------------
'}
stub
long $a4bfea06, $08bc0bf5, $e87c0a01, $08bc0bf5, $ec7c0a03, $0, $5c7c8001, $0     ' stub binary form 

var
  long mytask
  
pub start(entryp,parmp,task) | n
{{
Start the cog to debug.
Debug handler code resides at "org" entryp.
}}
  cognew(entryp,parmp)
  waitcnt(clkfreq/50+cnt)       ' wait for startup

  mytask := task+1              ' make sure task is non-zero
  
  INSA := $7FFC
  run(init1)                    ' align to long boundary
  case task
    0: run(init0t)              ' adjust comm address for task
      INSA -= $c
    1: run(init1t)              ' adjust comm address for task
      INSA -= $10
    2: run(init2t)              ' adjust comm address for task
      INSA -= $14
    3: run(init3t)              ' adjust comm address for task
      INSA -= $18
    4: run(init4t)              ' adjust comm address for task
      INSA -= $1c
    5: run(init5t)              ' adjust comm address for task
      INSA -= $20
    6: run(init6t)              ' adjust comm address for task
      INSA -= $24
    7: run(init7t)              ' adjust comm address for task
      INSA -= $28
     
  DATA := $7FF4                 ' outb = DATA
  ' do rest of init now
  repeat n from 0 to (@initlast-@init3)/4
    run(long[@init3+(n*4)])

pub copystub(ptr)
  longmove(ptr, @stub, 7)
   
dat
tstcode
tst1           or   dira,   #1
tst2           xor  outa,   #1 wc,wz

initcode                                                 
init1          sub  outb,   #3          ' align comm address to long boundary
init2          sub  outb,   #4          ' mov comm address down
                                                                              
init3          mov  0,      #0          ' nop in address 0
               mov  inb,    #$7f        ' setup for inb data comm address   
               shl  inb,    #8          ' inb = $7f00
               or   inb,    #$f4        ' inb = $7ff4
               mov  USER,   #$f         ' ALWAYS mask   
initlast       shl  USER,   #18         ' set cond ALWAYS bits       

init0t         sub  outb,   #$c         ' mov comm address down to $7ff0
init1t         sub  outb,   #$10        ' mov comm address down to $7fec
init2t         sub  outb,   #$14        ' mov comm address down to $7fe8
init3t         sub  outb,   #$18        ' mov comm address down to $7fe4
init4t         sub  outb,   #$1c        ' mov comm address down to $7fe0
init5t         sub  outb,   #$20        ' mov comm address down to $7fdc
init6t         sub  outb,   #$24        ' mov comm address down to $7fd8
init7t         sub  outb,   #$28        ' mov comm address down to $7fd4
             
var
  long  INSA
  long  DATA

con
  MRDLONG       = %000_010_001
  MWRLONG       = %000_010_000
  USER          = 0
  JMPUSER       = $5c7c0000
    
pub run(minst)
  long[INSA]~                  ' tell stub we're ready
  long[INSA] := minst          ' set instruction

pub read(madr) | n
'' the read method creates a wrlong instruction at register 1 and executes it
  run(rdcode | madr)                                
  repeat n from 1 to (@rdlast-@rdcode)/4
    run(long[@rdcode+(n*4)])
  return long[DATA] ' inb points to here
                                                   
dat            ' build a rdlong instruction
rdcode         movd     USER,   #0-0            ' set destination       
               movs     USER,   #inb            ' src is in inb     
               movi     USER,   #MWRLONG        ' wrlong - write to hub long[data] for caller to read
rdlast         long     JMPUSER                 ' run instruction

pub write(madr,mdat) | n
'' the write method creates a rdlong instruction at register 1 and executes it
  long[DATA] := mdat ' inb points to here
  run(wrcode | madr)                                
  repeat n from 1 to (@wrlast-@wrcode)/4
    run(long[@wrcode+(n*4)])

dat            ' build a wrlong instruction
wrcode         movd     USER,   #0-0            ' set destination
               movs     USER,   #inb            ' src is in inb
               movi     USER,   #MRDLONG        ' rdlong - read from hub long[data] where caller wrote
wrlast         long     JMPUSER                 ' run instruction

pub getc  | n
'' the getc method changes and executes stub register 0 & 1 instructions to get the COG's C flag state 
  repeat n from 0 to (@gclast-@gccode)/4
    run(long[@gccode+(n*4)])
  return long[DATA]

dat            ' build a get carry flag instruction
gccode         mov      dirb,   #0
               muxc     dirb,   #1              ' get carry bit
               movd     USER,   #dirb           ' set destination
               movs     USER,   #inb            ' src location is in inb        
               movi     USER,   #MWRLONG        ' wrlong - write to hub long[data] for caller to read 
gclast         long     JMPUSER                 ' run instruction       
        
pub getz | n
'' the getz method changes and executes stub register 0 & 1 instructions to get the COG's Z flag state
  repeat n from 0 to (@gzlast-@gzcode)/4
    run(long[@gzcode+(n*4)])
  return long[DATA]

dat            ' build a get zero flag instruction
gzcode         mov      dirb,   #0
               muxz     dirb,   #1              ' get zero bit
               movd     USER,   #dirb           ' set destination
               movs     USER,   #inb            ' src location is in inb        
               movi     USER,   #MWRLONG        ' wrlong - write to hub long[data] for caller to read 
gzlast         long     JMPUSER                 ' run instruction       

pub clrz | n
'' the clrz method changes and executes stub register 0 & 1 to clr the COG's Z flag state
  repeat n from 0 to (@czlast-@czcode)/4
    run(long[@czcode+(n*4)])

dat            ' build a get zero flag instruction
czcode         testn    $,      #1 wz           ' clr zero bit
czlast         long     JMPUSER                 ' run instruction       

pub setz | n
'' the setz method changes and executes stub register 0 & 1 to set the COG's Z flag state
  repeat n from 0 to (@szlast-@szcode)/4
    run(long[@czcode+(n*4)])

dat            ' build a get zero flag instruction
szcode         cmp      dirb,   dirb wz         ' set zero bit
szlast         long     JMPUSER                 ' run instruction       



pub getreg(addr) | n
'' the getreg method changes and executes stub register 0 & 1 instructions to get the COG's register value at addr
  grcode &= !$1ff
  grcode |= addr & $1ff
  repeat n from 0 to (@grlast-@grcode)/4
    run(long[@grcode+(n*4)])
  return long[DATA]

dat            ' build a get zero flag instruction
grcode         mov      dirb,   0-0             ' get reg
               movd     USER,   #dirb           ' set destination
               movs     USER,   #inb            ' src location is in inb        
               movi     USER,   #MWRLONG        ' wrlong - write to hub long[data] for caller to read 
grlast         long     JMPUSER                 ' run instruction       

pub setreg(addr, val) | n
'' the getreg method changes and executes stub register 0 & 1 instructions to get the COG's register value at addr
  write($1f7, val)
  'gscode  &= !$1ff
  'gscode  |= $1f5
  gscode &= !($1ff << 9)
  gscode |= (addr & $1ff) << 9
  repeat n from 0 to (@gslast-@gscode)/4
    run(long[@gscode+(n*4)])
  return long[DATA]

dat            ' build a get zero flag instruction
gscode         mov      0-0,   dirb             ' set value
'gswrite        mov      0-0,    outb            ' get zero bit
               movd     USER,   #dirb           ' set destination
               movs     USER,   #inb            ' src location is in inb        
               movi     USER,   #MWRLONG        ' wrlong - write to hub long[data] for caller to read 
gslast         long     JMPUSER                 ' run instruction       
