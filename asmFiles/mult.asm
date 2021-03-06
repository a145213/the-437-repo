# set the address where you want this code segment
org     0x0000

# setup stack to address 0xFFFC
ori     $29, $0, 0xFFFC

# initialize registers for storing result and counter
# register 4 for storing result
# register 5 for storing counter
ori     $4, $0, 0x0000
ori     $5, $0, 0x0000

# get values from stack and store in register 2 and 3
# register 3 = second operand
# register 2 = first operand
ori     $2, $0, 0x0002
ori     $3, $0, 3

push   $2
push   $3

mult:
        pop     $3
        pop     $2

loop:
        beq $5, $3, exit
        addu $4, $4, $2
        addiu $5, $5, 0x0001
        j loop
exit:
        push $4
        halt
