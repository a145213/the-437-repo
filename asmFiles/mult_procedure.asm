# set the address where you want this code segment
org     0x0000

# setup stack to address 0xFFFC
ori     $29, $0, 0xFFFC

# initialize registers for storing result and counter
# register 4 for storing temp operand
# register 6 for storing counter for the loop
# register 7 for storing number of operands
# register 8 for storing counter for the number of operands
# register 9 for storing the result
ori     $4, $0, 0x0002
push   $4
ori     $4, $0, 0x0003
push   $4
ori     $4, $0, 0x0003
push   $4

ori     $6, $0, 0x0000
ori     $7, $0, 0x0003             # change to set number of operands
ori     $8, $0, 0x0001
ori     $9, $0, 0x0000

push   $7                              # push the numner of operands last

pop     $7                              # get the number of operands
mult:
        beq $7, $8, exit2
        pop $4                          # get the first operand
        pop $5                          # get the second operand
        loop:
                beq $6, $5, exit
                addu $9, $9, $4
                addiu $6, $6, 0x0001
                j loop
        exit:
                push $9                 # push the result
                ori $6, $0, 0x0001  # clear counter
                addiu $8, $8, 0x0001
                j mult
 exit2:
        halt
        
