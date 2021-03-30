#####################################################################
#
# CSC258H Winter 2021 Assembly Final Project
# University of Toronto, St. George
#
# Student: Roger Lam, 1005778767
# # Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the project handout for descriptions of the milestones)
# - Milestone 1
#
# Which approved additional features have been implemented?
# (See the project handout for the list of additional features)
# 1. IPR
#
# Any additional information that the TA needs to know:
# - IPR
#
#####################################################################
.data
	displayAddress:	.word 0x10008000
	bugLocation: .word 1000
	centipedLocation: .word 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
	centipedDirection: .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
.text 

# function to display initial mushrooms
disp_mushrooms:	
	# choose random number of mushrooms to display
	li $v0, 42
	li $a0, 0	# not a lower bound
	li $a1, 10
	syscall
	
	# initialize loop variable $a3 with number of mushrooms to display ($a0)
	addi $a3, $a0, 100
	
	# load $s6 with colour yellow
	li $s6, 0xffff00
	
	lw $s2, displayAddress  # $s2 stores the base address for display
	
mushroom_gen_loop:
	# choose random location for mushroom
	li $v0, 42
	li $a0, 0	# not a lower bound
	li $a1, 767
	syscall
	
	addi $a0, $a0, 32	# prevent mushroom spawn on first row
	
	sll $t4, $a0, 2		# multiply mushroom unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get address of current unit
	lw $t4, 0($t4)		# retrieve value of address at $t4
	
	beq $t4, $s6, mushroom_gen_loop	# find another location if mushroom here
	lw $t2, displayAddress	# load base address into $t2
	
	sll $t4, $a0, 2		# multiply mushroom unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get address of current unit
	
	sw $s6, 0($t4)		# paint the mushroom with yellow
	
	addi $a3, $a3, -1	 # decrement loop variable $a3 by 1
	bne $a3, $zero, mushroom_gen_loop

Loop:
	# Check for keyboard input
		# Update the location of the Blaster
		# Check for collision events
	# Update location of all centipede parts and other moving obj
	# Redraw the screen
	# Sleep
	# Repeat
	jal disp_centiped
	jal check_keystroke

	li $v0, 32
	li $a0, 10
	syscall
	
	j Loop

Exit:
	li $v0, 10		# terminate the program gracefully
	syscall

# function to display a centipede
disp_centiped:
	# push address of $ra (address to Loop) to the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a3, $zero, 10	 # initialize loop variable $a3 to number of body segments
	la $s0, centipedLocation # load the address of the location array into $s0
	la $s1, centipedDirection # load the address of the direction array into $s1
	
	lw $s2, displayAddress  # $s2 stores the base address for display
	li $s3, 0xff0000	# $s3 stores the red colour code
	li $s4, 0xffffff	# $s4 stores the white colour code
	li $s7, 0x000000	# $s7 stores the black colour code
	
	
	lw $t1, 0($s0)		 # load a word from the centipedLocation array into $t1
	lw $t5, 0($s1)		 # load a word from the centipedDirection  array into $t5
	
	sll $t4, $t1, 2		# multiply body segment unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get address of current unit
	
	sw $s7, 0($t4)		# paint first unit black

arr_loop:	# iterate over the loops elements to draw each body segment of the centipede
	lw $t1, 0($s0)		 # load a word from the centipedLocation array into $t1
	lw $t5, 0($s1)		 # load a word from the centipedDirection  array into $t5
	
	sll $t4, $t1, 2		# multiply body segment unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get address of current unit
	
	beq $t5, 1, move_right
	beq $t5, -1, move_left
	
# function that moves a body segment with direction 1 (right)
move_right:
	# check whether next unit is the bug blaster
	# TODO: GAME OVER INSTEAD OF RIGHT_BLOCKED
	# beq $t6, 0xffffff, right_blocked
	
	# check whether next unit is the right side boundary
	la $t6, 4($t4)
	li $t7, 128
	div $t6, $t7
	mfhi $t7
	beq $t7, 0, right_blocked
	
	# check whether next unit is a mushroom
	lw $t6, 4($t4)
	beq $t6, $s6, right_blocked
	
	# check whether next unit is the bug blaster
	beq $t6, $s4, Exit
	
	sw $s3, 4($t4)		# paint the next unit red
	
	# add 1 to unit value of current body segment 
	addi $t1, $t1, 1
	sw $t1, 0($s0)
	
	# add 4 to location and direction arrays to refer to next elements
	addi $s0, $s0, 4
	addi $s1, $s1, 4
	
	addi $a3, $a3, -1	 # decrement loop variable $a3 by 1
	bne $a3, $zero, arr_loop
	
	# pop address of $ra (address to Loop) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra		# jump back to original position in Loop

# function that moves a body segment with direction -1 (left)
move_left:
	# check whether next unit is the bug blaster
	# TODO: GAME OVER INSTEAD OF LEFT_BLOCKED
	# beq $t6, 0xffffff, left_blocked
	
	# check whether next unit is the left side boundary
	la $t6, 0($t4)
	li $t7, 128
	div $t6, $t7
	mfhi $t7
	beq $t7, 0, left_blocked
	
	# check whether next unit is a mushroom
	lw $t6, -4($t4)
	beq $t6, $s6, left_blocked
	
	# check whether next unit is the bug blaster
	beq $t6, $s4, Exit
	
	sw $s3, -4($t4)		# paint the next unit red
	
	# add -1 to unit value of current body segment 
	addi $t1, $t1, -1
	sw $t1, 0($s0)
	
	# add 4 to location and direction arrays to refer to next elements
	addi $s0, $s0, 4
	addi $s1, $s1, 4
	
	addi $a3, $a3, -1	 # decrement loop variable $a3 by 1
	bne $a3, $zero, arr_loop
	
	# pop address of $ra (address to Loop) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra		# jump back to original position in Loop

# function that moves a blocked body segment with direction 1 (right)
right_blocked:
	sw $s3, 128($t4)	# paint the unit below current unit red
	
	# add 32 to unit value of current body segment 
	addi $t1, $t1, 32
	sw $t1, 0($s0)
	
	# add -2 to direction value of current body segment
	addi $t5, $t5, -2
	sw $t5, 0($s1)
	
	# add 4 to location and direction arrays to refer to next elements
	addi $s0, $s0, 4
	addi $s1, $s1, 4
	
	addi $a3, $a3, -1	 # decrement loop variable $a3 by 1
	bne $a3, $zero, arr_loop
	
	# pop address of $ra (address to Loop) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra		# jump back to original position in Loop

# function that moves a blocked body segment with direction -1 (left)
left_blocked:
	sw $s3, 128($t4)	# paint the unit below current unit red
	
	# add 32 to unit value of current body segment 
	addi $t1, $t1, 32
	sw $t1, 0($s0)
	
	# add 2 to direction value of current body segment
	addi $t5, $t5, 2
	sw $t5, 0($s1)
	
	# add 4 to location and direction arrays to refer to next elements
	addi $s0, $s0, 4
	addi $s1, $s1, 4
	
	addi $a3, $a3, -1	 # decrement loop variable $a3 by 1
	bne $a3, $zero, arr_loop
	
	# pop address of $ra (address to Loop) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra		# jump back to original position in Loop

# function to detect any keystroke
check_keystroke:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000
	beq $t8, 1, get_keyboard_input # if key is pressed, jump to get this key
	addi $t8, $zero, 0
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# function to get the input key
get_keyboard_input:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	addi $v0, $zero, 0	#default case
	beq $t2, 0x6A, respond_to_j
	beq $t2, 0x6B, respond_to_k
	beq $t2, 0x78, respond_to_x
	beq $t2, 0x73, respond_to_s
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of j key
respond_to_j:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the first (top-left) unit black.
	
	beq $t1, 992, skip_movement # prevent the bug from getting out of the canvas
	addi $t1, $t1, -1	# move the bug one location to the left
skip_movement:
	sw $t1, 0($t0)		# save the bug location

	li $t3, 0xffffff	# $t3 stores the white colour code
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the first (top-left) unit white.
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# Call back function of k key
respond_to_k:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the block with black
	
	beq $t1, 1023, skip_movement2 #prevent the bug from getting out of the canvas
	addi $t1, $t1, 1	# move the bug one location to the right
skip_movement2:
	sw $t1, 0($t0)		# save the bug location

	li $t3, 0xffffff	# $t3 stores the white colour code
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the block with white
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_x:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $v0, $zero, 3
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_s:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $v0, $zero, 4
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

delay:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $a2, 10000
	addi $a2, $a2, -1
	bgtz $a2, delay
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
