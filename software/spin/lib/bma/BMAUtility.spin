{{
BMAUtility.spin - Be My ASM Debugger Utilities
Copyright (c) 2009 by John Steven Denson (jazzed)
See below for MIT license terms.
}}

' Version 1.8 - Date 2010.07.16

  EOL = $a

obj
{
#ifndef SPINSIM
}
  fd : "FullDuplexSingleton"
{
#else
  fd : "conio"
#endif
}  ot    : "BMAopcodes"          ' required for mnemonic instructions (optional)
  bd[6] : "BMADebugger"         ' up to 6 debuggers
  
var
  'long  pcPtr
  long  pasm[8]
  long  parms[8]

dat
  task        long 0
  nooftask    long 0  

pub start
  if(nooftask < 1)
    fd.str(string(EOL,EOL,"No COG tasks started. Debugger halted.",EOL))
    repeat
  fd.str(string(EOL,EOL,"BMA Debugger Task "))        ' we're running
  fd.dec(task)
  cli(bd[task].pcstart)
  
pub taskstart(entryp, parmp, id) | ch, ut, pcstart, goinst, gopc
{{
The user interface debug routine.
@param entryp - the start address of the handler or org
@param parmp  - the start address of the user parameter block
}}
  fd.str(string("Starting BMA Debugger task "))   ' we're running
  fd.dec(nooftask)
  if(id)
    fd.tx(" ")
    fd.str(id)
    bd[nooftask].setId(id)
  fd.tx(EOL)
      
  pasm[nooftask]  := entryp
  parms[nooftask] := parmp
  result := bd[nooftask].start(entryp, parmp, nooftask)
  listpc[nooftask] := bd[task].pcstart
  nooftask++

pub debug(entryp, parmp) | ch, ut, pcstart, goinst, gopc
{{
The user interface debug routine.
@param entryp - the start address of the handler or org
@param parmp  - the start address of the user parameter block
}}
  fd.str(string(EOL,EOL,"Starting BMA Debugger ... "))             ' we're running
  pasm := entryp
  parms := parmp
  bd[task].start(pasm, parms,0)
  
  goinst~
  pcstart := bd[task].pcstart
  fd.str(string(EOL,EOL,"BMA Debugger Started."))             ' we're running

  cli(pcstart)
  
pub cli(pcstart) | ch, ut, goinst, gopc
  goinst~
  repeat                                      
    if goinst
      waitcnt(clkfreq/10+cnt)
      gopc := bd[task].peek(brkjmpaddr)-1 
      long[bd[task].pcp] := gopc
      goinst~
      listpc[task] := gopc
      'showInst(bd[task].pcp)
      'showStatus(long[bd[task].pcp])
      stepDump(bd[task].pcp)
    prompt
    ch := fd.rx
    ut := utility(ch,bd[task].pcp,pcstart)
    case ut
       0 :
        stepDump(bd[task].pcp)
      "I","i" :
        stepWatchInst
      "n":
        stepOver(bd[task].pcp,0)  ' step over
      "N":
        stepOver(bd[task].pcp,1)  ' step over verbose
      "g","G":
        'if(isbreak(long[bd[task].pcp]))
          'stepShow
        goinst := gojmp | (long[bd[task].pcp] & $1ff)
        bd[task].execute(bd[task].peek(goinst))

      other:
        if chkBreak(bd[task].pcp)
          showInst(bd[task].pcp)


pri showPC          
  fd.tx(EOL)
  fd.tx("T")
  fd.dec(task)
  fd.str(string(".PC"))

pri prompt
  showPC
  if isbreak(long[bd[task].pcp])
    fd.tx("*")
  else
    fd.tx(" ")
    
  if long[bd[task].pcp] > -1 and long[bd[task].pcp] < $200
    fd.hex(long[bd[task].pcp],3)
  else
    fd.str(string("COG Running."))
    
  'fd.tx(" ")
  'fd.hex(bd[task].peek(brkjmpaddr)-1,3)
  fd.str(string(" Ok> "))

{
pri printBreakPC(pc)
    fd.tx(EOL)
    fd.hex(pc,3)
    fd.tx(" ")
    fd.hex(bd[task].peek(pc),8)
    'fd.hex(isbreak(pc),8)
}

pri utility(ch, pcp, pcstart)
{{
Returns non-zero if utility valid
}}
  'pcPtr := pcp
  
  result~~
  case ch
    $a,$d: 'nada
      return 0
    "N","n":
      result := ch
    other:
      'fd.tx(EOL)
      fd.tx(ch)
      fd.tx(" ")
  case ch
    "a": animate
    "b": toggleBreak
    "c": clearBreak
    "d": dumpCogLines
    "D": dumpCog
    "f": fillHubAddrs
    "h": dumpHubAddrs
    "I","i": result := ch
    "G","g": result := ch
    "l": listCogLines
    "L": listCog
    "N","n": result := ch
    "P","p": printReg
    "s": setReg
    "t": setTask
    "R":
      bd[task].start(pasm[task], parms[task],task)
      long[pcp] := pcstart
    "r":
      long[pcp] := pcstart
    "Z","z": printFlags
    "?": showHelp
    'other: result~

dat
help byte 0
byte "ax     : animate with x ms delay per step",0
byte "bx     : toggles breakpoint at COG address x",0
byte "c      : clears all breakpoints",0
byte "D      : dumps all COG values",0
byte "dx n   : dumps n COG values from x",0
byte "ftx n v: fill n HUB addresses with v from x with t type = b,w,l",0
byte "g      : run COG and stop at any breakpoints",0
byte "htx n  : dumps n HUB values from x with t type = b,w,l",0
byte "ix     : step showing result of instructions at x",0
byte "L      : lists/disassembles all COG values/instructions",0
byte "l      : lists/disassembles 16 instructions from PC",0
byte "lx n   : list n instructions s starting at x",0
byte "n      : step to next jmp",0
byte "pr     : prints special register values PAR, etc...",0
byte "px     : prints content of COG register number <hex>",0
byte "r      : resets pc back to starting position",0
byte "R      : restarts COG",0
byte "sx v   : sets value at COG address x = v",0
byte "tx     : switch to COG task x",0
'byte "wx     : watch register x after step or break",0 ' later ... need a list of watches
byte "z      : shows flags",0
byte "Enter  : single-step",0
byte "?      : show this help screen",0
helpend   

pri showHelp | p, n
  repeat p from @help to @helpend
    ifnot byte[p]
      fd.tx(EOL)
    else
      fd.tx(byte[p])

pri listCog | x, n, j, p[2]
  repeat n from 0 to $1ff
    if n < 0
      next
    if n > $1ff
      quit
    p[0] := n
    showInst(@p)

var long listpc[8]

pri listCogLines | x, n, j, p[2]

  x := gethex(0)
  if x
    j := gethex(0)
  else
    x := listpc[task]           ' sb part of bd
    j := $10
  repeat n from x to x+j-1
    if n < 0
      next
    if n > $1ff
      quit
    p[0] := n
    showInst(@p)

  listpc[task] += j

pri dumpCog | n
  repeat n from 0 to $1ff
    ifnot n // 8 and n
      fd.tx(EOL)
      fd.hex(n,3)
      fd.tx(":")
    fd.tx(" ")
    fd.hex(bd[task].peek(n), 8)

pri dumpCogLines | x, n, j, p[2]
  x := gethex(0)
  j := gethex(0)
  repeat n from x to x+j-1
    if n < 0
      next
    if n > $1ff
      quit
    ifnot n // 8 and n
      fd.tx(EOL)
      fd.hex(n,3)
      fd.tx(":")
    fd.tx(" ")
    fd.hex(bd[task].peek(n), 8)


pri dumpASCII(p) | i
  fd.tx(" ")
  fd.tx(" ")
  repeat i from 0 to 15
    if byte[p][i] > $1f and byte[p][i] < $7f
      fd.tx(byte[p][i])
    else
      fd.tx(".")

pri dumpHubAddrs | n, x, i, j, t, c, w, p[4]

  repeat  ' repeat while next letter not bwl
    t := fd.rxcheck
    case t
      "b":  c := 16             ' byte
            w := 2
            quit 
      "w":  c := 8              ' word
            w := 4
            quit 
      "l":  c := 8              ' long
            w := 8
            quit 

  fd.tx(t)
  fd.tx(" ")  
  x := gethex(0)                ' address
  j := gethex(0) * (w>>1)       ' length

  i := 0
  repeat n from x to x+j-1 step (w>>1)
  
    if n < 0
      next
    if n > $ffff
      quit
      
    ifnot i // c          ' make nice columns
      if i and w == 2
        dumpASCII(@p)

      fd.tx(EOL)
      fd.hex(n,4)
      fd.tx(":")
      
    fd.tx(" ")
    
    case w                      ' dump size we want
      2: fd.hex(byte[n], w)
          byte[@p][i//c] := byte[n]
      4: fd.hex(word[n], w)
      8: fd.hex(long[n], w)

    i++
    
  if w == 2
    dumpASCII(@p)

pri fillHubAddrs | n, x, i, j, t, c, w, v, p[4]

  repeat  ' repeat while next letter not bwl
    t := fd.rxcheck
    case t
      "b":  c := 16             ' byte
            w := 2
            quit 
      "w":  c := 8              ' word
            w := 4
            quit 
      "l":  c := 8              ' long
            w := 8
            quit 

  fd.tx(t)
  fd.tx(" ")  
  x := gethex(0)                ' address
  j := gethex(0) * (w>>1)       ' length
  v := gethex(0)                ' length

  repeat n from x to x+j-1 step (w>>1)
  
    if n < 0
      next
    if n > $ffff
      quit
    
    case w                      ' fill size we want
      2: byte[n] := v
      4: word[n] := v
      8: long[n] := v


pri setReg | x, n, ch
  x := gethex(0)
  n := gethex(0)
  if x > 7 and x < $200
    if x > $1ef
      bd[task].setreg(x,n)
    else
      bd[task].poke(x,n)

pri setTask | x
  x := gethex(0)
  if(x < nooftask)
    task := x
    if(bd[task].getId)
      fd.str(string(EOL,"Task : "))
      fd.str(bd[task].getId)

dat
  org   0
  brkjmp       jmpret brkjmpaddr, #1 ' write PC+1 to COG address 0 and jump to wait for non-zero in stub
  gojmp        jmp    #0-0           ' jump to instruction at address
  long  0 [5]
  brkjmpaddr   long $                ' so we don't have to add spin code

pri toggleBreak | adr
  adr := gethex(0)
  if adr < 8 or adr > $1f0
    return
  if bd[task].isBreak(adr)
    delBreak(adr)
  else
    addBreak(adr)

pri addBreak(adr)
  bd[task].addBreak(adr,brkjmp)

pri delBreak(adr)
  bd[task].delBreak(adr)

pri isBreak(adr)
  return bd[task].isBreak(adr)

pri chkBreak(adr)
  return bd[task].chkBreak(adr)

pri clearBreak
  bd[task].clearBreak

{{  
con
  MAXBRKPTS = 16
  
var
  word brkcnt                   ' keep this order
  word brkpts[MAXBRKPTS]
  long brkdat[MAXBRKPTS]

pri toggleBreak | adr
  adr := gethex(0)
  if adr < 8 or adr > $1f0
    return
  if isBreak(adr)
    delBreak(adr)
  else
    addBreak(adr)
      
pri addBreak(adr) | n
  repeat n from 0 to brkcnt
    if brkpts[n] == adr
      return                    ' brk already set
  if brkcnt < MAXBRKPTS
    brkpts[brkcnt] := word[@adr]
    brkdat[brkcnt] := bd[task].peek(adr)
{
    fd.tx(EOL)
    fd.hex(adr,3)
    fd.tx(" ")
    fd.hex(brkjmp,8)
}    
    bd[task].poke(adr, brkjmp)
    brkcnt++
    brkpts[brkcnt] := $CAFE

pri delBreak(adr) | n, m
  n := brkcnt
  repeat brkcnt
    if brkpts[n-1] == word[@adr] ' cast as a word or it won't work
      bd[task].poke(adr, brkdat[n-1])
      repeat m from n-1 to brkcnt
        brkpts[m] := brkpts[m+1]
        brkdat[m] := brkdat[m+1]
      brkcnt--
    n--

pri isBreak(adr) | n
'' return instruction that would normally be at the breakpoint ... if nop return $cafee (a nop)
  ifnot adr
    return false
  repeat n from 0 to brkcnt
    if brkpts[n] == adr
      ifnot brkdat[n]
        return $cafee
      return brkdat[n] ' always non-zero
      
  return false

pri chkBreak(pcp) | n, adr
  adr := bd[task].peek(0)-1           ' break address-1 in cog register 0
  repeat n from 0 to brkcnt
    if brkpts[n] == adr
      long[pcp] := adr
      return true
  return false

pri clearBreak | n
  repeat n from 0 to brkcnt
    if brkdat[n] <> 0           ' save old instruction
      bd[task].poke(brkpts[n], brkdat[n])
    brkpts[n]~  
  brkcnt~

pri listBreak | n
  repeat n from 0 to brkcnt
    printBreak(n)

pri printBreak(j)
  fd.hex(brkcnt,2)
  fd.str(string(" "))
  fd.hex(j,2)
  fd.str(string(" "))
  fd.hex(brkpts[j],4)
  fd.tx(EOL)
}}
    
pri getHex(ch)
  result~
  repeat
    ifnot ch
      ch := fd.rx
      fd.tx(ch)
    case ch
      " ",$a,$d:
        return result
      "0".."9":
          result <<= 4
          result |= ch-"0"    
      "a".."f":
          result <<= 4
          result |= ch-"a"+$A    
      "A".."F":
          result <<= 4
          result |= ch-"A"+$A
    ch~

dat
regs    byte "PAR ",0
        byte "CNT ",0
        byte "INA ",0
        byte "INB ",0
        byte "OUTA",0
        byte "OUTB",0
        byte "DIRA",0
        byte "DIRB",0
        byte "CTRA",0
        byte "CTRB",0
        byte "FRQA",0
        byte "FRQB",0
        byte "PHSA",0
        byte "PHSB",0
        byte "VCFG",0
        byte "VSCL",0

pri reg(myaddr)
  return @regs+(myaddr-$1f0)*5

pri dumpRegs | n
  fd.tx(EOL)
  repeat n from $1f0 to $1ff
    dump(n)

pri dumpaddr(myaddr)
  if myaddr < $1f0
    fd.hex(myaddr, 3)
    fd.tx(" ")
  else
    fd.str(reg(myaddr))

pri dumpdata(myaddr)
  if myaddr > $1ef and myaddr < $200
    fd.hex(bd[task].getreg(myaddr), 8)
    bd[task].getc
    bd[task].getz
  else
    fd.hex(bd[task].peek(myaddr), 8)
   
pri dump(myaddr)
  dumpaddr(myaddr)
  fd.tx(" ")
  if myaddr > $1ef and myaddr < $200
    fd.hex(myaddr, 3)
    fd.tx(" ")
    fd.hex(bd[task].getreg(myaddr), 8)
    fd.tx(" ")
    fd.bin(bd[task].getreg(myaddr), 32)
  else
    fd.hex(bd[task].peek(myaddr), 8)
  fd.tx(EOL)

pri printFlags
  fd.tx(" ")
  fd.tx("Z")
  fd.tx(":")
  fd.bin(bd[task].getz, 1)
  fd.tx(" ")
  fd.tx("C")
  fd.tx(":")
  fd.bin(bd[task].getc, 1)
  fd.tx(EOL)
  
pri printReg | n, ch
  n~
  repeat
    ch := fd.rx
    fd.tx(ch)
    case ch
      $a,$d: quit
      "R","r":
        dumpRegs
        return
      "Z","z":
        printFlags
        return
      other:
        n := gethex(ch)
        quit

  dump(n)    

pri stepOver(pcp,verbose) | pc, jmpretbrk, goinst, gopc

  '-------------------------------------------------------------------------------
  ' show instruction
  '
  pc := long[pcp]
  showInst(pcp)
  
  '-------------------------------------------------------------------------------
  ' this is where the heavy lifting is done
  '
  'jmpretbrk := isJmpRet(bd[task].peek(long[bd[task].pcp]))
  jmpretbrk := isJmpRet(pc)

  if jmpretbrk

    fd.tx("R")
    fd.str(string("call ret: "))
    fd.hex(jmpretbrk,3)

{   ' don't do go yet, since it's harder to get right
    ifnot isbreak(jmpretbrk)
      addBreak(jmpretbrk-1)    ' add back the break jmp
    goinst := long[bd[task].pcp]
    bd[task].execute(bd[task].peek(goinst))

    repeat while goinst
      gopc := bd[task].peek(brkjmpaddr)-1 
      long[bd[task].pcp] := gopc
      goinst~

    delBreak(jmpretbrk)      ' delete break jmp instruction
}

    ' for now just single step until address until I have more time.
    repeat
    
      'fd.str(string($a,"PC: "))
      'fd.hex(long[bd[task].pcp],3)
      if verbose
        showInst(bd[task].pcp)

      if(long[bd[task].pcp] == jmpretbrk)
        quit
        
      if isbreak(long[bd[task].pcp])
        delBreak(long[bd[task].pcp])      ' delete break jmp instruction
        bd[task].singleStep               ' step normal instruction
        addBreak(long[bd[task].pcp]-1)    ' add back the break jmp
        quit
      else
        bd[task].singleStep

      if fd.rxready
        quit

      if verbose
        showStatus(long[bd[task].pcp])  
    
  else

    if isbreak(long[bd[task].pcp])
      delBreak(long[bd[task].pcp])      ' delete break jmp instruction
      bd[task].singleStep               ' step normal instruction
      addBreak(long[bd[task].pcp]-1)    ' add back the break jmp
    else
      bd[task].singleStep

  listpc[task] := long[pcp]

  '-------------------------------------------------------------------------------
  ' show status
  '
  showStatus(pc)  
  showInst(pcp)


pri isJmpRet(pc) | instruction, inst, wres, cond, src, dst

  instruction := bd[task].peek(pc)
{
  fd.str(string("PC: "))
  fd.hex(pc,3)
  fd.str(string(" T "))
  fd.hex(task,3)
  fd.str(string(" instruciton: "))
  fd.hex(instruction,8)
'}

  inst := (instruction >> 26) & $3f
  wres := (instruction >> 23) & 1
  cond := (instruction >> 19) & $f
  dst  := (instruction >> 9) & $1ff
  src  := instruction & $1ff
{
  fd.str(string(EOL,"isJmpRet: "))
  fd.bin(inst,6)
  fd.tx(" ")
  fd.bin(wres,1)
  fd.tx(" ")
  fd.bin(cond,4)
  fd.tx(" ")
  fd.hex(dst,3)
  fd.tx(" ")
  fd.hex(src,3)
'}
  ifnot cond  
    result := false '(string("nop     "))
  elseif inst == %010111
    case wres
      0 : result := false '(string("jmp     "))
      1 : result := pc+1 '(string("jmpret  "))

pri animate | time

  waitcnt(clkfreq/2+cnt)  ' give a moment for next argument
{
#ifndef SPINSIM
}
  if fd.rxready
{
#else
  if fd.rxcheck
#endif
}
    time := gethex(0)
  repeat while fd.rxcheck < 0
    stepShow
    if isbreak(long[bd[task].pcp])
      quit
    waitcnt(clkfreq/1000*time+cnt)

pri stepWatchInst | watchinst

  watchinst := gethex(0)
  fd.str(string(EOL,"Step-watch Instruction @ "))
  fd.hex(watchinst,3)
  repeat while fd.rxcheck < 0
    if isbreak(long[bd[task].pcp])
      quit
    if(long[bd[task].pcp] == watchinst)
      stepShow
    else
      stepInst

pri stepShow
   'fd.hex(bd[task].pcp,4)
   stepDump(bd[task].pcp)

pri stepDump(pcp) | pc

  '-------------------------------------------------------------------------------
  ' show instruction
  '
  showInst(pcp)
  pc := long[pcp]
  
  '-------------------------------------------------------------------------------
  ' step instruction
  '
  stepInst

  '-------------------------------------------------------------------------------
  ' show status
  '
  showStatus(pc)  

pri stepInst

  '-------------------------------------------------------------------------------
  ' this is where the STEP heavy lifting is done
  '
  if isbreak(long[bd[task].pcp])
    delBreak(long[bd[task].pcp])      ' delete break jmp instruction
    bd[task].singleStep               ' step normal instruction
    addBreak(long[bd[task].pcp]-1)    ' add back the break jmp
  else
    bd[task].singleStep

  listpc[task] := long[bd[task].pcp]

pri showInst(pcp) | mpc, mop, mnst, mi, mflg, mexe, msrc, mdst, ostr, mc, mz, brk
{{
  Steps the COG program and dumps output to Serial port.
  If we pass the address of PC to this and the stepper, we could move this to BMAutility.spin ?
}}
  '-------------------------------------------------------------------------------
  ' get instruction fields

  mpc := long[pcp]
  mop := bd[task].peek(mpc)           ' get instruction
  brk := isbreak(mpc)           ' isbreak returns instruction
  if brk
    mop := brk                  ' replace instruction
    
  mnst:= (mop >> bd#OP_OPC_SHFT) & $3f
  mi  := (mop >> bd#OP_ZCRI_SHFT) & 1
  mflg:= (mop >> bd#OP_ZCRI_SHFT) & $f 
  mexe:= (mop >> bd#OP_COND_SHFT) & $f 
  mdst:= (mop >> bd#OP_D_SHFT) & $1ff 
  msrc:= (mop >> bd#OP_S_SHFT) & $1ff 

  '-------------------------------------------------------------------------------
  ' show instruction details before step

  showPC
  if isbreak(mpc)
    fd.tx("*")
  else
    fd.tx(" ")
  fd.hex(mpc,3)
  fd.str(string(" "))
  fd.str(conditions(mexe))
  fd.str(string(": "))

'{ Use this to get human readable opcode form ... comment this and ot object to reduce code size
  ostr := ot.get(mop)
    if strsize(ostr)
      fd.str(ostr)
    else
'}
      fd.str(string(" I:"))
      fd.hex(mnst,2)
      fd.str(string(" "))
    fd.hex(mop,8)
    
  case (mflg>>1) & $7
    $0:     fd.str(string("   N"))
    $1:     fd.str(string("    "))
    $2:     fd.str(string("  CN"))
    $3:     fd.str(string("  C "))
    $4:     fd.str(string(" Z N"))
    $5:     fd.str(string(" Z  "))
    $6:     fd.str(string(" ZCN"))
    $7:     fd.str(string(" ZC "))
    other:  fd.str(string("    "))

  fd.str(string(" D:"))
  dumpaddr(mdst)
  'fd.hex(mdst,3)
  fd.str(string(" "))
  fd.hex(bd[task].peek(mdst),8)
  if mi
    fd.str(string(" S#"))
    fd.hex(msrc,3)
  else
    fd.str(string(" S:"))
    dumpaddr(msrc)
    'fd.hex(msrc,3)
    fd.str(string(" "))
    dumpdata(msrc)
    'fd.hex(bd[task].peek(msrc),8)

  if mi
    fd.str(string("          "))


pri showStatus(mpc) | mop, msrc, mdst, brk
  '-------------------------------------------------------------------------------
  ' show instruction and other details after step

  'mpc := long[bd[task].pcp]
  mop := bd[task].peek(mpc)

  brk := isbreak(mpc)           ' isbreak returns instruction
  if brk
    mop := brk                  ' replace instruction

  mdst:= (mop >> bd#OP_D_SHFT) & $1ff 
  msrc:= (mop >> bd#OP_S_SHFT) & $1ff 
   
  fd.str(string(" D="))
  dumpaddr(mdst)
  fd.str(string(" "))
  dumpdata(mdst)

  if bd[task].getZ
    fd.str(string(" Z"))
  if bd[task].getC
    fd.str(string(" C"))
    
{
  fd.str(string(" Z:"))
  fd.bin(mz,1)
  fd.str(string(" C:"))
  fd.bin(mc,1)
}

pri conditions(mexe)
{{
Deliver a short conditional string for debug stepper.
}}
  case mexe & $f
    %0001 : return (string("NC_&_NZ")) 
    %0010 : return (string("NC_&_Z "))
    %0011 : return (string("NC     "))
    %0100 : return (string("C_&_NZ ")) 
    %0101 : return (string("NZ     "))
    %0110 : return (string("C_<>_Z "))
    %0111 : return (string("NC_|_NZ")) 
    %1000 : return (string("C_&_Z  ")) 
    %1001 : return (string("C_==_Z "))
    %1010 : return (string("Z      "))
    %1011 : return (string("NC_|_Z ")) 
    %1100 : return (string("C      "))
    %1101 : return (string("C_|_NZ "))
    %1110 : return (string("C_|_Z  ")) 
    %0000 : return (string("nop    "))
    %1111 : return (string(".      "))

  
