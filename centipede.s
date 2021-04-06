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
# - Milestone 3
#
# Which approved additional features have been implemented?
# (See the project handout for the list of additional features)
# 1. None
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
	centipedeHealth: .word 3
	fleaHealth: .word 0
	fleaLocation: .word 800
.text

# function to display initial mushrooms
disp_mushrooms:
	# choose random number of 70-80 mushrooms to display
	li $v0, 42
	li $a0, 0	# not a lower bound
	li $a1, 10
	syscall
	
	# initialize loop variable $a3 with number of mushrooms to display ($a0)
	addi $a3, $a0, 70
	
	lw $s2, displayAddress  # $s2 stores the base address for display
	
	li $s3, 0xff0000	# $s3 stores the red colour code
	li $s4, 0xffffff	# $s4 stores the white colour code
	li $s5, 0x00ff00	# $s5 stores the green colour code
	li $s6, 0xffff00	# $s6 stores the yellow colour code
	li $s7, 0x000000	# $s7 stores the black colour code
	
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
		
	sll $t4, $a0, 2		# multiply mushroom unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get address of current unit
	
	sw $s6, 0($t4)		# paint the mushroom with yellow
	
	addi $a3, $a3, -1	 # decrement loop variable $a3 by 1
	bne $a3, $zero, mushroom_gen_loop

Loop:
	jal disp_centiped
	jal disp_flea
	jal check_keystroke

	# System call for sleeping
	li $v0, 32
	li $a0, 50
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
	# check whether next unit is the bug blaster
	lw $t6, 128($t4)
	beq $t6, $s4, Exit
	
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
	# check whether next unit is the bug blaster
	lw $t6, 128($t4)
	beq $t6, $s4, Exit
	
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

# function to display a flea
disp_flea:
	# push address of $ra (address to Loop) to the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $s0, 0x800080	# s0 stores the purple colour code
	la $s1, fleaHealth 	# load the address of the flea's health into $s1
	lw $t0, 0($s1)		 # load a health from fleaHealth into $t0
	beq $t0, 0, respawnFlea	# respawn flea if it is dead
	
	j gen_flea_movement
	
respawnFlea:
	addi $t0, $t0, 1	# increase fleaHealth by 1
	sw $t0, 0($s1)		 # load a health from fleaHealth into $t0
	
	# choose which side the flea enters
	li $v0, 42
	li $a0, 0	# left
	li $a1, 2	# right
	syscall
	
	beq $a0, 0, flea_enter_from_left
	beq $a0, 1, flea_enter_from_right
	
flea_enter_from_left:
	li $t1, 800		# load first unit of the row right after mushrooms lower boundary
	la $t0, fleaLocation	# load address of the fleaLocation into t0
	sw $t1, 0($t0)		# save the flea location
	
	sll $t4, $t1, 2		# multiply body segment unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get address of current unit
	
	sw $s0, 0($t4)		# paint this unit purple
	
	j gen_flea_movement

flea_enter_from_right:
	li $t1, 831		# load first unit of the row right after mushrooms lower boundary
	la $t0, fleaLocation	# load address of the fleaLocation into t0
	sw $t1, 0($t0)		# save the flea location
	
	sll $t4, $t1, 2		# multiply body segment unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get address of current unit
	
	sw $s0, 0($t4)		# paint this unit purple
	
	j gen_flea_movement
	
gen_flea_movement:
	# choose the flea movement type
	li $v0, 42
	li $a0, 0
	li $a1, 7
	syscall
	
	beq $a0, 0, flea_up
	beq $a0, 1, flea_down
	beq $a0, 2, flea_rdiagup
	beq $a0, 3, flea_rdiagdown
	beq $a0, 4, flea_ldiagup
	beq $a0, 5, flea_ldiagdown
	beq $a0, 6, flea_stay
	
flea_stay:
	# choose the flea movement type
	li $v0, 42
	li $a0, 0
	li $a1, 150
	syscall
	addi $a3, $a3, 350	# initialize loop variable $a3
flea_stay_loop:
	addi $a3, $a3, -1	# decrement loop variable
	
	bne $a3, $zero, flea_stay_loop
	
	# pop address of $ra (address to Loop) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra		# jump back to original position in Loop
	
flea_up:
	addi $a3, $zero, 3	 # initialize loop variable $a3 to number of body segments
flea_up_loop:
	la $t0, fleaLocation	# load the address of buglocation from memory	
	lw $t1, 0($t0)		# load the flea location itself in t1
	addi $t1, $t1, -32	# get location of unit in front of the flea
	
	sll $t4, $t1, 2		# multiply flea unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get current address of flea
	
	# return to point in main Loop if current address < lower mushroom spawn boundary
	blt $t1, 800, return_to_main
	
	sw $s7, 128($t4)	# paint the unit behind the current unit black
	sw $s0, 0($t4)		# paint the current unit purple
	sw $t1, 0($t0)		# save the flea location
	
	addi $a3, $a3, -1	# decrement loop variable
	
	bne $a3, $zero, flea_up_loop
	
	# pop address of $ra (address to Loop) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra		# jump back to original position in Loop
	
flea_down:
	addi $a3, $zero, 3	 # initialize loop variable $a3 to number of body segments
flea_down_loop:
	la $t0, fleaLocation	# load the address of buglocation from memory	
	lw $t1, 0($t0)		# load the flea location itself in t1
	addi $t1, $t1, 32	# get location of unit in front of the flea
	
	sll $t4, $t1, 2		# multiply flea unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get current address of flea
	
	lw $t2, 0($t4)		# get colour value of current address
	beq $t2, $s4, Exit	# game over if hit bug blaster
	
	# return to point in main Loop if current address > lower canvas boundary
	bgt $t1, 1023, return_to_main
	
	sw $s7, -128($t4)	# paint the unit behind the current unit black
	sw $s0, 0($t4)		# paint the current unit purple
	sw $t1, 0($t0)		# save the flea location
	
	addi $a3, $a3, -1	# decrement loop variable
	
	bne $a3, $zero, flea_down_loop
	
	# pop address of $ra (address to Loop) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra		# jump back to original position in Loop
	
flea_rdiagup:
	addi $a3, $zero, 4	 # initialize loop variable $a3 to number of body segments
flea_rdiagup_loop:
	la $t0, fleaLocation	# load the address of buglocation from memory	
	lw $t1, 0($t0)		# load the flea location itself in t1
	addi $t1, $t1, -31	# get location of right unit in front of the flea
	
	sll $t4, $t1, 2		# multiply unit in front of flea number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get current address of flea
	
	lw $t2, 0($t4)		# get colour value of current address
	beq $t2, $s4, Exit	# game over if hit bug blaster
	
	# return to point in main Loop if unit in front of flea < lower mushroom spawn boundary
	blt $t1, 800, return_to_main
	
	sw $s7, 124($t4)	# paint the unit behind the current unit black
	sw $s0, 0($t4)		# paint the current unit purple
	sw $t1, 0($t0)		# save the flea location
	
	addi $a3, $a3, -1	# decrement loop variable

	bne $a3, $zero, flea_rdiagup_loop
	
	# pop address of $ra (address to Loop) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra		# jump back to original position in Loop
	
flea_rdiagdown:
	addi $a3, $zero, 4	 # initialize loop variable $a3 to number of body segments
flea_rdiagdown_loop:
	la $t0, fleaLocation	# load the address of buglocation from memory	
	lw $t1, 0($t0)		# load the flea location itself in t1
	addi $t1, $t1, 33	# get location of right unit behind the flea
	
	sll $t4, $t1, 2		# multiply right unit behind the flea by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get current address of flea
	
	lw $t2, 0($t4)		# get colour value of current address
	beq $t2, $s4, Exit	# game over if hit bug blaster
	
	# return to point in main Loop if right unit behind the flea > lower canvas boundary
	bgt $t1, 1023, return_to_main
	
	sw $s7, -132($t4)	# paint the previous unit black
	sw $s0, 0($t4)		# paint the current unit purple
	sw $t1, 0($t0)		# save the flea location
	
	addi $a3, $a3, -1	# decrement loop variable
	
	bne $a3, $zero, flea_rdiagdown_loop
	
	# pop address of $ra (address to Loop) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra		# jump back to original position in Loop
	
flea_ldiagup:
	addi $a3, $zero, 4	 # initialize loop variable $a3 to number of body segments
flea_ldiagup_loop:
	la $t0, fleaLocation	# load the address of buglocation from memory	
	lw $t1, 0($t0)		# load the flea location itself in t1
	addi $t1, $t1, -33	# get location of left unit in front of the flea
	
	sll $t4, $t1, 2		# multiply left unit in front of flea number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get current address of flea
	
	lw $t2, 0($t4)		# get colour value of current address
	beq $t2, $s4, Exit	# game over if hit bug blaster
	
	# return to point in main Loop if unit in front of flea < lower mushroom spawn boundary
	blt $t1, 800, return_to_main
	
	sw $s7, 132($t4)	# paint the unit behind the current unit black
	sw $s0, 0($t4)		# paint the current unit purple
	sw $t1, 0($t0)		# save the flea location
	
	addi $a3, $a3, -1	# decrement loop variable
	
	bne $a3, $zero, flea_ldiagup_loop
	
	# pop address of $ra (address to Loop) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra		# jump back to original position in Loop
	
flea_ldiagdown:
	addi $a3, $zero, 4	 # initialize loop variable $a3 to number of body segments
flea_ldiagdown_loop:
	la $t0, fleaLocation	# load the address of buglocation from memory	
	lw $t1, 0($t0)		# load the flea location itself in t1
	addi $t1, $t1, 31	# get location of right unit behind the flea
	
	sll $t4, $t1, 2		# multiply right unit behind the flea by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get current address of flea
	
	lw $t2, 0($t4)		# get colour value of current address
	beq $t2, $s4, Exit	# game over if hit bug blaster
	
	# return to point in main Loop if right unit behind the flea > lower canvas boundary
	bgt $t1, 1023, return_to_main
	
	sw $s7, -124($t4)	# paint the previous unit black
	sw $s0, 0($t4)		# paint the current unit purple
	sw $t1, 0($t0)		# save the flea location
	
	addi $a3, $a3, -1	# decrement loop variable
	
	bne $a3, $zero, flea_ldiagdown_loop
	
	# pop address of $ra (address to Loop) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra		# jump back to original position in Loop
	
return_to_main:
	# pop address of $ra (address to Loop) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra		# jump back to original position in Loop

# function to detect any keystroke
check_keystroke:
	# push address of $ra (address to Loop) to the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000
	beq $t8, 1, get_keyboard_input # if key is pressed, jump to get this key
	addi $t8, $zero, 0
	
	# pop address of $ra (address to Loop) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# function to get the input key
get_keyboard_input:
	# push address of $ra (address to check_keystroke) to the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	addi $v0, $zero, 0	#default case
	beq $t2, 0x6A, respond_to_j
	beq $t2, 0x6B, respond_to_k
	beq $t2, 0x78, respond_to_x
	beq $t2, 0x72, respond_to_r
	
	# pop address of $ra (address to check_keystroke) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of j key
respond_to_j:
	# push address of $ra (address to get_keyboard_input) to the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	sll $t4, $t1, 2		# multiply bug blaster unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get current address of bug blaster
	sw $s7, 0($t4)		# paint the first (top-left) unit black.
	
	beq $t1, 992, skip_movement1 # prevent the bug from getting out of the canvas
	addi $t1, $t1, -1	# move the bug one location to the left
skip_movement1:
	sw $t1, 0($t0)		# save the bug location

	sll $t4, $t1, 2		# multiply bug blaster unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get current address of bug blaster
	sw $s4, 0($t4)		# paint the first (top-left) unit white.
	
	
	# pop address of $ra (address to get_keyboard_input) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# Call back function of k key
respond_to_k:
	# push address of $ra (address to get_keyboard_input) to the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	sll $t4, $t1, 2		# multiply bug blaster unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get current address of bug blaster
	sw $s7, 0($t4)		# paint the block with black
	
	beq $t1, 1023, skip_movement2 #prevent the bug from getting out of the canvas
	addi $t1, $t1, 1	# move the bug one location to the right
skip_movement2:
	sw $t1, 0($t0)		# save the bug location

	sll $t4, $t1, 2		# multiply bug blaster unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get current address of bug blaster
	sw $s4, 0($t4)		# paint the block with white
	
	
	# pop address of $ra (address to get_keyboard_input) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_x:
	# push address of $ra (address to get_keyboard_input) to the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	addi $t1, $t1, -32	# get location of unit in front of bug blaster
	
	sll $t4, $t1, 2		# multiply bug blaster unit number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get current address of bug blaster
shoot:
	li $s0, 0x800080	# s0 stores the purple colour code
	lw $t5, 0($t4)			# extract colour value of the current unit
	beq $t5, $s3, centipedeHit	# decrease centipede health if bullet hit
	beq $t5, $s6, mushroomHit	# break mushroom if bullet hit
	beq $t5, $s0, fleaHit		# decrease flea health if bullet hit
	
	# return to get_keyboard_input if current address < displayAddress - 128
	blt $t4, $s2, return_to_get_keyboard_input	
	
	lw $t3, 128($t4)			# extract colour value of unit behind the bullet
	beq $t3, $s4, leave_bug_blaster		# leave bug blaster if unit behind bullet is bug blaster
	sw $s7, 128($t4)			# paint the unit behind the bullet black
	
	sw $s5, 0($t4)		# paint the current unit green
	addi $t4, $t4, -128	# increase address value $t4 by 128 for next row
	
	# System call for sleeping
	li $v0, 32
	li $a0, 10
	syscall
	
	j shoot
	
leave_bug_blaster:
	sw $s5, 0($t4)		# paint the current unit green
	addi $t4, $t4, -128	# increase address value $t4 by 128 for next row
	j shoot
	
return_to_get_keyboard_input:
	sw $s7, 128($t4)	# paint the bullet black
	
	# pop address of $ra (address to get_keyboard_input) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
centipedeHit:
	sw $s7, 128($t4)	# paint the bullet black
	la $s0, centipedeHealth # load the address of the centipede's health into $s0
	lw $t1, 0($s0)		 # load a health from centipedeHealth into $t1
	
	addi $t1, $t1, -1	# minus 1 to health of the centipede
	beq $t1, 0, Exit	# end game if centipede dies
	
	sw $t1, 0($s0)		# store new health of centipede back into centipedeHealth
	
	# pop address of $ra (address to get_keyboard_input) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
fleaHit:
	sw $s7, 128($t4)	# paint the bullet black
	la $s0, fleaHealth 	# load the address of the flea's health into $s0
	lw $t1, 0($s0)		 # load a health from fleaHealth into $t1
	
	addi $t1, $t1, -1	# minus 1 to health of the flea

	sw $t1, 0($s0)		# store new health of flea back into fleaHealth
	
	la $t0, fleaLocation	# load the address of buglocation from memory	
	lw $t1, 0($t0)		# load the flea location itself in t1
	
	sll $t4, $t1, 2		# multiply left unit in front of flea number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get current address of flea
	sw $s7, 0($t4)		# paint the unit behind the current unit black
	sw $t1, 0($t0)		# save the flea location
	
	# pop address of $ra (address to get_keyboard_input) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
mushroomHit:
	sw $s7, 0($t4)		# paint the block with black
	sw $s7, 128($t4)	# paint the bullet black
	
	# pop address of $ra (address to get_keyboard_input) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_r:
	# push address of $ra (address to get_keyboard_input) to the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory	
	li $t1, 1000		# reset bug location back to 1000
	sw $t1, 0($t0)		# save the bug location

	la $t0, centipedLocation	# load the address of centipedLocation from memory	
	la $t3, centipedDirection	# load the address of centipedDirection from memory
	addi $a3, $a3, 0		# initialize loop variable
	li $t4, 1
resetCentipedLocation:
	sw $a3, 0($t0)		# save the centipede location
	sw $t4, 0($t3)		# save the direction

	addi $t0, $t0, 4	# next element in array
	addi $t3, $t3, 4	# next element in array
	
	addi $a3, $a3, 1	# update loop variable
	bne $a3, 10, resetCentipedLocation
	
	la $t0, centipedeHealth
	li $t1, 3
	sw $t1, 0($t0)
	
	la $t0, fleaHealth
	li $t1, 0
	sw $t1, 0($t0)
	
	la $t0, fleaLocation
	li $t1, 800
	sw $t1, 0($t0)

	addi $a3, $a3, 1024		# initialize loop variable
resetCanvas:
	sll $t4, $a3, 2		# multiply left unit in front of flea number by 4; each unit is 4 bytes
	add $t4, $s2, $t4	# add number of $t4 bytes to base address to get current address of flea
	sw $s7, 0($t4)		# paint the current unit black
	
	addi $a3, $a3, -1
	bne $a3, 0, resetCanvas
	
	# pop address of $ra (address to get_keyboard_input) from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	# System call for sleeping
	li $v0, 32
	li $a0, 100
	syscall
	
	j disp_mushrooms