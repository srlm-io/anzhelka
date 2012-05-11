{{
BMADebugger.spin - Bite My ASM Debugger
Copyright (c) 2009 by John Steven Denson (jazzed)
See below for MIT license terms.
}}

' Version 1.7 - Date 2009.12.22

{{
See Demo file for usage and description.
}}

  STUB    = p#PC
  
obj
  p  : "BMAPASMstub"
  fd : "FullDuplexSingleton"
  
pub start(entryp, parmp, task)
{{
Start the cog to debug.
Debug handler code resides at "org" entryp.
Code to debug resides at pasmp.
}}
  cog_pc := p#PC
  p.copystub(entryp)            ' copy stub to my code
  p.start(entryp, parmp, task)

pub pcstart
  return p#PC

pub setId(ptr)
  idptr := ptr

pub getId
  return idptr
  
var
'-------------------------------------------------------------------------------
' This object variable keeps track of the cog pc for the stepper
'-------------------------------------------------------------------------------
  long cog_pc
  long idptr
  
con
'-------------------------------------------------------------------------------
' These are the spin stepper's constants.
' The spin stepper interprets cog code bits to keep the "PASM stepper" happy.
'-------------------------------------------------------------------------------

  OP_S_SHFT     = 0
  OP_D_SHFT     = 9
  OP_COND_SHFT  = 18
  OP_ZCRI_SHFT  = 22
  OP_OPC_SHFT   = 26
  
  '                opcode zcri cond 876543210 876543210
  OP_MOV        = %101000_0010_1111_000000000_000000000
  OP_RDLONG_IMM = %000010_0011_1111_000000000_000000000  
  OP_TEST_IWC   = %011000_0101_1111_000000000_000000000  
  OP_TEST_IWZ   = %011000_1001_1111_000000000_000000000  
  OP_WRLONG_IMM = %000010_0001_1111_000000000_000000000  
  OP_WRLONG_IFC = %000010_0001_1100_000000000_000000000  
  OP_WRLONG_IFZ = %000010_0001_1010_000000000_000000000  
  OP_COGID      = %000011_0011_1111_000000000_000000001
  OP_I          = %000000_0001_0000_000000000_000000000
  OP_R          = %000000_0010_0000_000000000_000000000
  OP_Z          = %000000_1000_0000_000000000_000000000
  OP_C          = %000000_0100_0000_000000000_000000000

  
pub singleStep  | opc, exec, jump, jumpret, dest, c, nc, z, nz, v, addr
{
------------------------------------------------------------------------------
'' This is a substantially modified version of a method written by Ray Rodrick.
''      Copyright (c) 2008 "Cluso99" (Ray Rodrick)                              
'' A variation of Ray Rodrick's zero footprint Single Step Routine
------------------------------------------------------------------------------
}
'' Pardon the mess! I've left it this way to allo debugging with TV_Text.
'' After the debugger gets more experience, I'll clean it up.
  
  ' Get the next adr & instruction
  opc  := Peek(cog_pc)                                   'get the opcode
  cog_pc++                                               'next addr ... modified if jump

  'decode the conditional execution bits
  exec := getCondition(opc)

  'if we are going to execute this instruction, check if it can jump (jmp.../tj../dj.)?
    
  if exec
    ' decode the operand
    jump~
    jumpret~
    v := (opc >> OP_OPC_SHFT) & $3F
    case v
      %111001 : 'djnz (test and decrement)
        addr := (opc >> OP_D_SHFT ) & $1FF
        v := peek(addr)
        if v > 1
          poke(addr,v-1)
          jump~~
        else
          return 
      %111010 : 'tjnz
        jump := peek((opc >> OP_D_SHFT ) & $1FF) <> 0 
      %111011 : 'tjz
        jump := peek((opc >> OP_D_SHFT ) & $1FF) == 0 
      %010111 : 'jmp/jmpret/ret/call
        jump~~
        if opc & OP_R
          jumpret := cog_pc

        ' if jmp instruction has Z flag, handle it
        if opc & OP_Z           
          dest := peek((opc >> OP_D_SHFT ) & $1FF)
          if dest
            p.clrz
          else
            p.setz
{
          fd.str(string("jmp opz "))
          fd.hex(dest,3)
          fd.out(" ")
          fd.dec(p.getz)
          fd.out($a)
}     

    if jump 'adjust PC if a jump

      case (opc >> OP_ZCRI_SHFT) & $01                'immediate?
        0 : cog_pc := Peek(opc & $1FF) & $1FF         'src_data
        1 : cog_pc := opc & $1FF                      '#src_data

      if jump ' don't run jump instructions
        if jumpret
          addr := (opc >> OP_D_SHFT) & $1FF 
          dest := Peek(addr)
          poke(addr, (dest & !$1FF) | jumpret)

        return

    Execute(opc)                                          'execute the opc

       
pri getCondition(myopc) | c, z, nc, nz
'' This is part of the stepper code
{
------------------------------------------------------------------------------
'' This method is a modified version of code written by Ray Rodrick.
''      Copyright (c) 2008 "Cluso99" (Ray Rodrick)                              
------------------------------------------------------------------------------
}
  nc := not ( c := GetC )
  nz := not ( z := GetZ )  
  case ( myopc >> OP_COND_SHFT) & $0F
    %0000 : result := false         'NEVER  (report NEVER for wrbyte but it works anyway!)
    %0001 : result := nc and nz     'if_nc_and_nz 
    %0010 : result := nc and z      'if_nc_and_z
    %0011 : result := nc            'if_nc
    %0100 : result := c and nz      'if_c_and_nz 
    %0101 : result := nz            'if_nz
    %0110 : result := nc <> nz      'if_c_ne_z 
    %0111 : result := nc or nz      'if_nc_or_nz 
    %1000 : result := c and z       'if_c_and_z 
    %1001 : result := c == z        'if_c_eq_z 
    %1010 : result := z             'if_z 
    %1011 : result := nc or z       'if_nc_or_z 
    %1100 : result := c             'if_c 
    %1101 : result := c or nz       'if_c_or_nz 
    %1110 : result := c or z        'if_c_or_z 
    %1111 : result := true          'ALWAYS  

  
pub pc
  return cog_pc

pub pcp
  return @cog_pc

pub instruction
  return p.read(cog_pc)

pub Execute(myopc)
  p.run(myopc)

pub peek(myaddr)
  return p.read(myaddr)
  
pub poke(myaddr,myval)
  p.write(myaddr,myval)

pub getc
  return p.getc

pub getz
  return p.getz

pub getreg(addr)
  return p.getreg(addr)

pub setreg(addr, val)
  return p.setreg(addr, val)


con
  MAXBRKPTS = 16
  
var
  word brkcnt                   ' keep this order
  word brkpts[MAXBRKPTS]
  long brkdat[MAXBRKPTS]
{
pri toggleBreak | adr
  adr := gethex(0)
  if adr < 8 or adr > $1f0
    return
  if isBreak(adr)
    delBreak(adr)
  else
    addBreak(adr)
}
      
pub addBreak(adr,brkjmp) | n
  repeat n from 0 to brkcnt
    if brkpts[n] == adr
      return                    ' brk already set
  if brkcnt < MAXBRKPTS
    brkpts[brkcnt] := word[@adr]
    brkdat[brkcnt] := peek(adr)
{
    fd.tx($d)
    fd.hex(adr,3)
    fd.tx(" ")
    fd.hex(brkjmp,8)
}    
    poke(adr, brkjmp)
    brkcnt++
    brkpts[brkcnt] := $CAFE

pub delBreak(adr) | n, m
  n := brkcnt
  repeat brkcnt
    if brkpts[n-1] == word[@adr] ' cast as a word or it won't work
      poke(adr, brkdat[n-1])
      repeat m from n-1 to brkcnt
        brkpts[m] := brkpts[m+1]
        brkdat[m] := brkdat[m+1]
      brkcnt--
    n--

pub isBreak(adr) | n
'' return instruction that would normally be at the breakpoint ... if nop return $cafee (a nop)
  ifnot adr
    return false
  repeat n from 0 to brkcnt
    if brkpts[n] == adr
      ifnot brkdat[n]
        return $cafee
      return brkdat[n] ' always non-zero
      
  return false

pub chkBreak(mpcp) | n, adr
  adr := peek(0)-1           ' break address-1 in cog register 0
  repeat n from 0 to brkcnt
    if brkpts[n] == adr
      long[mpcp] := adr
      return true
  return false

pub clearBreak | n
  repeat n from 0 to brkcnt
    if brkdat[n] <> 0           ' save old instruction
      poke(brkpts[n], brkdat[n])
    brkpts[n]~  
  brkcnt~

pub listBreak | n
  repeat n from 0 to brkcnt
    printBreak(n)

pub printBreak(j)
  fd.hex(brkcnt,2)
  fd.str(string(" "))
  fd.hex(j,2)
  fd.str(string(" "))
  fd.hex(brkpts[j],4)
  fd.tx($d)
    

{{
 TERMS OF USE: MIT License                                                           

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
}}
  
