{{
BMAOpcodes.spin - Be My ASM Debugger Opcodes
Copyright (c) 2009 by John Steven Denson (jazzed)
See below for MIT license terms.
}}

' Version 1.6 - Date 2009.12.21

pub get(instruction) | inst, wres, cond, src
{{
  Used to get a mnemonic form of a PASM 32 bit instruction.
}}
{
------------------------------------------------------------------------------
'' This is a variation version of a method written by Ray Rodrick.
'' NOP and others were broken, fixed now. This is substantially different.
'' Thus I no longer feel obligated to show Ray's copyright here.
------------------------------------------------------------------------------
}
  inst := (instruction >> 26) & $3f
  wres := (instruction >> 23) & 1
  cond := (instruction >> 19) & $f
  src  := instruction & $1ff

  ifnot cond  
    result := (string("nop     "))
  else
    case (inst)
      %000000 :
        case wres
          0 : result := (string("wrbyte  "))
          1 : result := (string("rdbyte  "))
      %000001 : case wres
                  0 : result := (string("wrword  "))
                  1 : result := (string("rdword  "))
      %000010 : case wres
                  0 : result := (string("wrlong  "))
                  1 : result := (string("rdlong  "))
      %000011 : case src
                  0 : result := (string("clkset  "))
                  1 : result := (string("cogid   "))
                  2 : result := (string("coginit "))
                  3 : result := (string("cogstop "))
                  4 : result := (string("locknew "))
                  5 : result := (string("lockret "))
                  6 : result := (string("lockset "))
                  7 : result := (string("lockclr "))
      %000100 : result := (string("mul     ")) ' not implemented
      %000101 : result := (string("muls    ")) ' not implemented
      %000110 : result := (string("enc     ")) ' not implemented  
      %000111 : result := (string("ones    ")) ' not implemented
      %001000 : result := (string("ror     "))
      %001001 : result := (string("rol     "))
      %001010 : result := (string("shr     "))
      %001011 : result := (string("shl     "))
      %001100 : result := (string("rcr     "))
      %001101 : result := (string("rcl     "))
      %001110 : result := (string("sar     "))
      %001111 : result := (string("rev     "))
      %010000 : result := (string("mins    "))
      %010001 : result := (string("maxs    "))
      %010010 : result := (string("min     "))
      %010011 : result := (string("max     "))
      %010100 : result := (string("movs    "))
      %010101 : result := (string("movd    "))
      %010110 : result := (string("movi    "))  
      %010111 : case wres
                  0 : result := (string("jmp     "))
                  1 : result := (string("call    "))
      %011000 : case wres
                  0 : result := (string("test    "))
                  1 : result := (string("and     "))
      %011001 : case wres
                  0 : result := (string("testn   "))
                  1 : result := (string("andn    "))
      %011010 : result := (string("or      "))
      %011011 : result := (string("xor     "))
      %011100 : result := (string("muxc    "))
      %011101 : result := (string("muxnc   "))
      %011110 : result := (string("muxz    "))
      %011111 : result := (string("muxnz   "))
      %100000 : result := (string("add     "))
      %100001 : case wres
                  0 : result := (string("cmp     "))
                  1 : result := (string("sub     "))
      %100010 : result := (string("addabs  "))
      %100011 : result := (string("subabs  "))
      %100100 : result := (string("sumc    "))
      %100101 : result := (string("sumnc   "))
      %100110 : result := (string("sumz    "))  
      %100111 : result := (string("sumnz   "))
      %101000 : result := (string("mov     "))
      %101001 : result := (string("neg     "))
      %101010 : result := (string("abs     "))
      %101011 : result := (string("absneg  "))
      %101100 : result := (string("negc    "))
      %101101 : result := (string("negnc   "))
      %101110 : result := (string("negz    "))
      %101111 : result := (string("negnz   "))
      %110000 : result := (string("cmps    "))
      %110001 : result := (string("cmpsx   "))
      %110010 : result := (string("addx    "))
      %110011 : result := (string("subx    "))
      %110100 : result := (string("adds    "))
      %110101 : result := (string("subs    "))
      %110110 : result := (string("addsx   "))  
      %110111 : result := (string("subsx   "))
      %111000 : result := (string("cmpsub  "))
      %111001 : result := (string("djnz    "))
      %111010 : result := (string("tjnz    "))
      %111011 : result := (string("tjz     "))
      %111100 : result := (string("waitpeq "))
      %111101 : result := (string("waitpne "))
      %111110 : result := (string("waitcnt "))
      %111111 : result := (string("waitvid "))

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
