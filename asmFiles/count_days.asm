# set the address where you want this code segment
org     0x0000

# setup stack to address 0xFFFC
ori     $29, $0, 0xFFFC

# initialize registers for storing result and counter
# register 4 for storing temp operand 1
# register 5 for storing temp operand 2
# register 6 for storing counter for the loop
# register 9 for storing the result

# register 10 for storing current day
# register 11 for storing current month
# register 12 for storing current year
ori     $4, $0, 0x0000
ori     $5, $0, 0x0000
ori     $6, $0, 0x0000
ori     $7, $0, 0x0002             # change to set number of operands
ori     $8, $0, 0x0001
ori     $9, $0, 0x0000
ori     $10, $0, 20          # day (19)
ori     $11, $0, 1            # month
ori     $12, $0, 2015          # year

# 30 * (month - 1)
ori $15, $0, 1
subu $11, $11, $15
push   $11
ori $15, $0, 30
push   $15
jal mult
pop     $16

# 365 * (year - 2000)
ori $15, $0, 2000
subu $13, $12, $15
push   $13
ori $15, $0, 365
push   $15
jal mult
pop     $24

# calculating final result
ori       $11, $0, 0x0000
addu   $11, $11, $16
addu   $11, $11, $24
addu   $11, $11, $10
push   $11
halt

mult:
        pop $4                          # get the first operand
        pop $5                          # get the second operand
        loop:
                beq $6, $5, exit
                addu $9, $9, $4
                addiu $6, $6, 0x0001
                j loop
exit:
        push $9                 # push the result
        ori $6, $0, 0x0000  # clear counter
        ori $9, $0, 0x0000  # clear result
        jr $31
  
