#######################################################
#
# Core 1 Producer
#
#######################################################
# Call CRC to generate random values, check the stack is full
# or not. If the stack is not full, lock it and push the generated
# value then unlock. Increment the counter (256) and jump back to the
# beginning

org 0x0000

# setup stack to address 0x3FFC
ori $sp, $0, 0x3FFC
# CRC seed
ori $s0, $0, 0x0FFC
# counter
ori $s1, $0, 0x0000

loop_random:
  or $a0, $0, $s0
  # call CRC and get the return random value
  jal crc32
  # CRC return value
  or $s0, $0, $v0

attempt_push:
  # acquire the lock
  ori $a0, $0, lifo_lock
  jal lock

  # push CRC to LIFO
  or $a0, $0, $s0
  jal push_lifo

  # unlock if it didn't push to LIFO
  beq $v0, $0, lifo_pushed
  ori $a0, $0, lifo_lock
  jal unlock

  j attempt_push

lifo_pushed:
  # unlock if the generated value pushed successfully
  ori $a0, $0, lifo_lock
  jal unlock

  # increment the counter
  addiu $s1, $s1, 1
  ori $t0, $0, 256
  bne $s1, $t0, loop_random
  halt

#######################################################
#
# Core 2 Consumer
#
#######################################################
org 0x0200

# setup stack to address 0x7FFC
ori $sp, $zero, 0x7FFC
# sum register
ori $s0, $0, 0x0000
# min register
ori $s1, $0, 0xFFFF
# max register
ori $s2, $0, 0x0000
# counter
ori $s3, $0, 0x0000
# average register
ori $s4, $0, 0x0000
# popped value
ori $s5, $0, 0x0000

consumer:
  ori $a0, $0, lifo_lock
  jal lock
  jal pop_lifo

  # unlock if it didn't pop LIFO
  beq $v0, $0, lifo_poped
  ori $a0, $0, lifo_lock
  jal unlock

  #ori $t0, $0, 256
  #ori $s3, $s3, 0
  #beq $s3, $t0, consumer_done
  j consumer

lifo_poped:
  # unlock if the generated value popped successfully
  ori $a0, $0, lifo_lock
  jal unlock

  # compute min
  ori $a0, $s1, 0x0000
  andi $a1, $s5, 0x0000FFFF
  jal min
  ori $s1, $v0, 0
  # compute max
  ori $a0, $s2, 0
  andi $a1, $s5, 0x0000FFFF
  jal max
  ori $s2, $v0, 0
  # compute sum
  andi $a1, $s5, 0x0000FFFF
  addu $s0, $s0, $a1

  # increment the counter
  addiu $s3, $s3, 1
  ori $t0, $0, 0x00000100
  beq $s3, $t0, consumer_done
  j consumer

consumer_done:
  # calculate average
  andi $a0, $s0, 0x0000FFFF
  #ori $a1, $0, 0x00000100
  #jal divide
  #ori $s4, $v0, 0
  srl $s4, $s0, 0x08
  halt

#######################################################
#
# LIFO
#
#######################################################
push_lifo:
  ori $t0, $0, lifo
  # initialize head pointer
  ori $t1, $0, lifo_head
  # load LIFO head pointer value
  lw  $t2, 0($t1)
  # initialize tail pointer
  ori $t3, $0, lifo_tail
  #lw  $t4, 0($t3)

  # compare head and tail pointer. if head == tail, full
  # return $v0 with 1 if LIFO is full
  bne $t2, $t3, execute_push
  ori $v0, $0, 1
  jr  $ra

execute_push:
  # push the value a0 to the LIFO and update the head pointer
  # return $v0 with 0 if success
  addi $t2, $t2, 4
  sw  $a0, 0($t2)
  sw  $t2, 0($t1)
  ori $v0, $0, 0
  jr  $ra

pop_lifo:
  ori $t0, $0, lifo
  # initialize head pointer
  ori $t1, $0, lifo_head
  # load LIFO head pointer
  lw  $t2, 0($t1)
  # store LIFO pointer
  ori $t3, $0, lifo_tail
  #lw  $12, 0($11)
 
  # check if LIFO is empty, return $v0 with 1 if it's empty
  bne $t2, $t0, execute_pop
  ori $v0, $0, 1
  jr  $ra

execute_pop:
  lw $s5, 0($t2)
  #or $s5, $0, $t2
  addi $t2, $t2, -4
  sw  $t2, 0($t1)
  ori $v0, $0, 0
  jr $ra

#######################################################
#
# Lock and unlock
#
#######################################################
# pass in an address to lock function in argument register 0
# returns when lock is available
lock:
aquire:
  ll    $t0, 0($a0)         # load lock location
  bne   $t0, $0, aquire     # wait on lock to be open
  addiu $t0, $t0, 1
  sc    $t0, 0($a0)
  beq   $t0, $0, lock       # if sc failed retry
  jr    $ra


# pass in an address to unlock function in argument register 0
# returns when lock is free
unlock:
  sw    $0, 0($a0)
  jr    $ra

#######################################################
#
# CRC Generation Subroutine
#
#######################################################
# REGISTERS
# at $1 at
# v $2-3 function returns
# a $4-7 function args
# t $8-15 temps
# s $16-23 saved temps (callee preserved)
# t $24-25 temps
# k $26-27 kernel
# gp $28 gp (callee preserved)
# sp $29 sp (callee preserved)
# fp $30 fp (callee preserved)
# ra $31 return address

# USAGE random0 = crc(seed), random1 = crc(random0)
#       randomN = crc(randomN-1)
#------------------------------------------------------
# $v0 = crc32($a0)
crc32:
  lui $t1, 0x04C1
  ori $t1, $t1, 0x1DB7
  or $t2, $0, $0
  ori $t3, $0, 32

l1:
  slt $t4, $t2, $t3
  beq $t4, $zero, l2

  srl $t4, $a0, 31
  sll $a0, $a0, 1
  beq $t4, $0, l3
  xor $a0, $a0, $t1
l3:
  addiu $t2, $t2, 1
  j l1
l2:
  or $v0, $a0, $0
  jr $ra
#------------------------------------------------------

#######################################################
#
# Division Subroutine
#
#######################################################
# registers a0-1,v0-1,t0
# a0 = Numerator
# a1 = Denominator
# v0 = Quotient
# v1 = Remainder

#-divide(N=$a0,D=$a1) returns (Q=$v0,R=$v1)--------
divide:               # setup frame
  push  $ra           # saved return address
  push  $a0           # saved register
  push  $a1           # saved register
  or    $v0, $0, $0   # Quotient v0=0
  or    $v1, $0, $a0  # Remainder t2=N=a0
  beq   $0, $a1, divrtn # test zero D
  slt   $t0, $a1, $0  # test neg D
  bne   $t0, $0, divdneg
  slt   $t0, $a0, $0  # test neg N
  bne   $t0, $0, divnneg
divloop:
  slt   $t0, $v1, $a1 # while R >= D
  bne   $t0, $0, divrtn
  addiu $v0, $v0, 1   # Q = Q + 1
  subu  $v1, $v1, $a1 # R = R - D
  j     divloop
divnneg:
  subu  $a0, $0, $a0  # negate N
  jal   divide        # call divide
  subu  $v0, $0, $v0  # negate Q
  beq   $v1, $0, divrtn
  addiu $v0, $v0, -1  # return -Q-1
  j     divrtn
divdneg:
  subu  $a0, $0, $a1  # negate D
  jal   divide        # call divide
  subu  $v0, $0, $v0  # negate Q
divrtn:
  pop $a1
  pop $a0
  pop $ra
  jr  $ra
#-divide--------------------------------------------

#######################################################
#
# Min, Max Subroutine
#
#######################################################
# registers a0-1,v0,t0
# a0 = a
# a1 = b
# v0 = result

#-max (a0=a,a1=b) returns v0=max(a,b)--------------
max:
  push  $ra
  push  $a0
  push  $a1
  or    $v0, $0, $a0
  slt   $t0, $a0, $a1
  beq   $t0, $0, maxrtn
  or    $v0, $0, $a1
maxrtn:
  pop   $a1
  pop   $a0
  pop   $ra
  jr    $ra
#--------------------------------------------------

#-min (a0=a,a1=b) returns v0=min(a,b)--------------
min:
  push  $ra
  push  $a0
  push  $a1
  or    $v0, $0, $a0
  slt   $t0, $a1, $a0
  beq   $t0, $0, minrtn
  or    $v0, $0, $a1
minrtn:
  pop   $a1
  pop   $a0
  pop   $ra
  jr    $ra
#--------------------------------------------------


org 0x0550
lifo_lock:
  cfw 0
lifo_head:
  cfw lifo
lifo:
  cfw 0
  cfw 0
  cfw 0
  cfw 0
  cfw 0
  cfw 0
  cfw 0
  cfw 0
  cfw 0
  cfw 0
lifo_tail:
  cfw 0
