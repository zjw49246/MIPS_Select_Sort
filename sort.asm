.data
int_num_request: .asciiz "\nPlease enter the number of input integers:"
int_num_print: .asciiz "\nThe number of input integers is:"
input_isnot_int_error: .asciiz "\nInput is not a integer, please enter again!!!"
enter_request: .asciiz "\nPlease enter an integer:"
int_too_small: .asciiz "The input integer is smaller than -128, please enter again!!!"
int_too_large: .asciiz "The input integer is larger than 127, please enter again!!!"
time_print: .asciiz "The time of sorting process is:"
hex_0x: .asciiz "0x"
hex_print: .asciiz "The hex of sorted array:"

int_num: .word 0 # stores the number of input integers, initialized by 0
array: .space 100 #stores the array of input integers
array_hex: .byte '0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f' # array for hex 0-f

.text
main:
## read in n integers
# request for the number of input integers
print_int_num_request:
la $a0, int_num_request
li $v0, 4
syscall
la $t7, int_num # $t7 stores the address of int_num
li $s5, 10 # ascii of "enter" or "\n"
li $t9, 57 #ascii of '9'
li $t8, 48 #ascii of '0'

# scan the number of input integers into int_num
# beginning loop num
num: 
# mult original int_num by 10
lw $t0, int_num
li $t1, 10
mult $t0, $t1
mflo $t2 # result of mult 10
li $v0, 12 # read a char into $v0 (ascii)
syscall
move $t0, $v0
beq $t0, $s5, END_num # if input is '\n', exit loop num
slt $s7, $t0, $t8 #if the ascii of input is smaller than 48, $s7=1
slt $s7, $t9, $t0 #if the ascii of input is larger than 57, $s7=1
# if $s7=1, i.e. input is not an integer, print an error, clear the int_num and go back to the beginning of loop num
beq $s7, $zero, is_int_intnum
la $a0, input_isnot_int_error
li $v0, 4
syscall
sw $zero, int_num
j print_int_num_request
# if input is an integer
is_int_intnum:
addi $t0, $t0, -48 # ascii to number
add $t0, $t0, $t2 # add new X to Y0, get YX
sw $t0, int_num
j num
END_num:
# end of loop num

# print the number of input integers
la $a0, int_num_print
li $v0, 4
syscall
lw $a0, ($t7)
li $v0, 1
syscall

# read in integers
lw $t6, ($t7) # $t6 stores the number of input integers
la $t5, array # $t5 stores the address of array
li $t4, 0 # $t4 is the cyclic variable of loop read_nums_int

# beginning of loop read_num_ints
read_num_ints:
# request for an input integer
la $a0, enter_request
li $v0, 4
syscall
# calculate the address at which the input integer will be store
sll $t3, $t4, 2 # mult $t4 by 4
add $s0, $t5, $t3 # $s0 stores the address at which the input integer will be store
sw $zero, ($s0)
li $s3, 0 # help to verify if '-' is the first char
li $s6, 0 # 0:positive int, 1: negative number
# scan an integer into array[$t4], i.e. 4*$t4($t5)=$s0
# beginning of loop read_int
read_int:
# mult original integer at $s0 by 10
lw $t0, ($s0)
li $t1, 10
mult $t0, $t1
mflo $t2 # result of mult 10
li $v0, 12 # read a char into $v0 (ascii)
syscall
move $t0, $v0
beq $t0, $s5, END_read_int # if input is '\n', exit loop num
bne $s3, $zero, isnot_firstchar_or_45
li $t1, 45 # ascii of '-'
bne $t0, $t1, isnot_firstchar_or_45
li $s6, 1 # if $t0='-', this int is a negative one, use $s6=1 to tag it
addi $s3, $s3, 1 # when one char is added, $s3=$s3+1, to help verify if '-' is the first char
j read_int
isnot_firstchar_or_45:
slt $s7, $t0, $t8 #if the ascii of input is smaller than 48, $s7=1
bne $s7, $zero, smaller_than_48 #if the ascii of input int is smaller than 48, skip next code
slt $s7, $t9, $t0 #if the ascii of input is larger than 57, $s7=1
smaller_than_48:
# if $s7=1, i.e. input is not an integer, print an error, clear the ($s0) and go back to the beginning of loop read_num_ints
beq $s7, $zero, is_int_readint # print an error
la $a0, input_isnot_int_error
li $v0, 4
syscall
sw $zero, ($s0) # clear the ($s0)
j read_num_ints # go back to the beginning of loop read_num_ints
# if input is an integer
is_int_readint:
addi $t0, $t0, -48 # ascii to number
add $t0, $t0, $t2 # add new X to Y0, get YX
move $s7, $t0
sw $t0, ($s0)
addi $s3, $s3, 1 # when one char is added, $s3=$s3+1, to help verify if '-' is the first char
j read_int
END_read_int:
# end of loop read_int
li $t2, 0 # 0: in the range, 1: not in the range
# $s7 stores hilo+new int
srl $t1, $s7, 7 # get high 9 bit of $s7
slt $t2, $zero, $t1
beq $s6, $zero, positive_int_range # if $s6=0, the int is a positive one
sll $t3, $s7, 25 # get low 7 bit of $s7
bne $t3, $zero, low_7_not_zero # low 7 bit =? 0
li $t3, 1
bne $t2, $t3, high_9_not_1 # high 9 bit =? 1
li $t2, 0 # int=10000000b=128
high_9_not_1:
low_7_not_zero:
positive_int_range:
beq $t2, $zero, in_range # if $t2=0, the int is in the range
beq $s6, $zero, positive_int_large # positive int and not in the range -> too large
# the int is smaller than -128
la $a0, int_too_small
li $v0, 4
syscall
j read_num_ints
# the int is larger than 127
positive_int_large:
la $a0, int_too_large
li $v0, 4
syscall
j read_num_ints
# between -128 and 127
in_range:
# if $s6=1, this int is a negative one
beq $s6, $zero, positive_int
lw $t0, ($s0)
sub $t0, $zero, $t0
sw $t0, ($s0)
# if $s6=0, this int is a positive one. However, both positive and negative integers will go through codes in positive_int
positive_int:
# verify this int is between -128 and 127
#lw $t0, ($s0)
#li $t2, -128
#slt $t1, $t0, $t2
#beq $t1, $zero, larger_minus128
addi $t4, $t4, 1
bne $t4, $t6, read_num_ints
# end of loop read_num_ints

## print all the integers in array
li $t4, 0
li $s7, 0 # denote that directly go into print_array, instead of going from select_sort to print_array
# beginning of loop print_array
print_array:
sll $t3, $t4, 2 # mult $t4 by 4
add $s0, $t5, $t3 # $s0 stores the address at which the input integer will be store
lw $a0, ($s0)
li $v0, 1
syscall
li $a0, 32 # print ' '
li $v0, 11
syscall
addi $t4, $t4, 1
bne $t4, $t6, print_array
# end of loop print_array
bne $s7, $zero, skip_sort # if $s7=1, skip the following sort; if $s7=0, continue to do the sort 

# time start
li $v0, 30
syscall
move $s5, $a1
move $s4, $a0

## select sort of array 
lw $t6, int_num # $t6 stores the number of input integers
addi $t9, $t6, -1 # $t9 stores $t6-1 to help the loop end correctly
la $t5, array # $t5 stores the address of array
li $t0, 0
# beginning of loop select_sort_out
select_sort_out: # cyclic variable is $t0
sll $t2, $t0, 2 # mult $t0 by 4, to denote 1 int will be stored in 4 bytes
add $s0, $t5, $t2 # the address of this int
lw $t3, ($s0) # $t3 stores the fixed int
addi $t4, $t0, 1 # use $t4 to visit the integers in the right
# beginning of loop select_sort_in
select_sort_in: #cyclic variable is $t4
sll $t7, $t4, 2 # mult $t4 by 4, to denote 1 int will be stored in 4 bytes
add $s1, $t5, $t7 # the address of this int
lw $t8, ($s1) # $t8 stores the int
slt $s2, $t8, $t3 # $s2 is a tag denoting whether $t8 is smaller than $t3
beq $s2, $zero, not_smaller
# if $t8 is smaller than $t3, exchange the value in ($s0) and ($s1)
sw $t8, ($s0)
sw $t3, ($s1)
move $t3, $t8
# if $t8 is not smaller than $t3
not_smaller:
addi $t4, $t4, 1
bne $t4, $t6, select_sort_in
# end of loop select_sort_in
addi $t0, $t0, 1
bne $t0, $t9, select_sort_out # use $t9=$t6-1 to help the loop end correctly
# end of loop select_sort_out

# time end
li $v0, 30
syscall
move $s7, $a1
move $s6, $a0

# print time
li $a0, 10 # print '\n'
li $v0, 11
syscall

move $a0, $s5
li $v0, 1
syscall

li $a0, 35 # print ' '
li $v0, 11
syscall

move $a0, $s4
li $v0, 1
syscall

li $a0, 10 # print '\n'
li $v0, 11
syscall

move $a0, $s7
li $v0, 1
syscall

li $a0, 35 # print ' '
li $v0, 11
syscall

move $a0, $s6
li $v0, 1
syscall

# print the duration
li $a0, 10
li $v0, 11
syscall
la $a0, time_print
li $v0, 4
syscall
sub $a0, $s6, $s4
li $v0, 1
syscall
li $a0, 'm'
li $v0, 11
syscall
li $a0, 's'
li $v0, 11
syscall
li $a0, 10
li $v0, 11
syscall
# end of print time

## print all the integers in array
li $a0, 10 # print '\n'
li $v0, 11
syscall
li $t4, 0
li $s7, 1 # denote that go from select_sort to print_array
j print_array

# after print the sorted array, continue to execute the following code
skip_sort:
# print '\n'
li $a0, 10
li $v0, 11
syscall
# print hex_print
la $a0, hex_print
li $v0, 4
syscall
## print sorted array as hex
lw $t6, int_num # $t6 stores the number of input integers
#addi $t9, $t6, -1 # $t9 stores $t6-1 to help the loop end correctly
la $t5, array # $t5 stores the address of array
la $t7, array_hex # $t7 stores the address of array_hex
la $t8, hex_0x # $t8 stores the address of hex_0x
li $s1, 0 # 1:negative int, 0:0 or positive int
li $t0, 0
print_array_hex: # cyclic variable is $t0
sll $t1, $t0, 2 # mult $t0 by 4
add $s0, $t5, $t1 # $s0 stores the address of current int
lw $t2, ($s0) # $t2 stores current int

# print hex of $t2 (use $v0=34)
#move $a0, $t2
#li $v0, 34
#syscall
# print ' '
#li $a0, 32
#li $v0, 11
#syscall

slt $s1, $t2, $zero # whether $t2 is smaller than 0, yes(negative int): $s1=1, no(0 or positive int): $s1=0
beq $s1, $zero, non_negative_hex
addi $t2, $t2, 256
# 256 doesn't add to $t2
non_negative_hex:
li $t3, 16
div $t2, $t3
mflo $t4 # integer quotient
mfhi $t9 # remainder
add $s4, $t7, $t4 # $s4 stores the address of integer quotient(hex)
add $s5, $t7, $t9 # $s5 stores the address of remainder(hex)


# print "0x"
#la $a0, hex_0x
move $a0, $t8
li $v0, 4
syscall
# print the first char
lb $a0, ($s4)
li $v0, 11
syscall
# print the second char
lb $a0, ($s5)
li $v0, 11
syscall
# print ' '
li $a0, 32
li $v0, 11
syscall

addi $t0, $t0, 1
bne $t0, $t6, print_array_hex
# end of loop print_array_hex

li $v0, 10
syscall






