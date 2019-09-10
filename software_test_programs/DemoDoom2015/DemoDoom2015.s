	.file	1 "DemoDoom2015.c"
	.section .mdebug.abi32
	.previous
	.gnu_attribute 4, 1
	.text
	.align	2
	.globl	main
	.set	nomips16
	.set	nomicromips
	.ent	main
	.type	main, @function
main:
	.frame	$fp,48,$31		# vars= 24, regs= 2/0, args= 16, gp= 0
	.mask	0xc0000000,-4
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	addiu	$sp,$sp,-48
	sw	$31,44($sp)
	sw	$fp,40($sp)
	move	$fp,$sp
	li	$2,5			# 0x5
	sw	$2,28($fp)
	li	$2,9			# 0x9
	sw	$2,32($fp)
	sh	$0,16($fp)
	lw	$2,32($fp)
	sll	$2,$2,2
	sw	$2,32($fp)
	lw	$2,28($fp)
	sra	$2,$2,1
	sw	$2,28($fp)
	lw	$2,28($fp)
	andi	$3,$2,0xffff
	lw	$2,32($fp)
	andi	$2,$2,0xffff
	mul	$2,$3,$2
	andi	$2,$2,0xffff
	sll	$2,$2,16
	sra	$2,$2,16
	andi	$2,$2,0xff
	sh	$2,16($fp)
	addiu	$2,$fp,28
	sw	$2,20($fp)
	addiu	$2,$fp,32
	sw	$2,24($fp)
	lw	$4,20($fp)
	lw	$5,24($fp)
	jal	swap
	nop

	lw	$2,20($fp)
	lw	$2,0($2)
	sw	$2,28($fp)
	lw	$2,24($fp)
	lw	$2,0($2)
	sw	$2,32($fp)
	lw	$4,20($fp)
	lw	$5,24($fp)
	jal	crazyDiv
	nop

	lw	$3,28($fp)
	lw	$2,32($fp)
	addu	$2,$3,$2
	move	$sp,$fp
	lw	$31,44($sp)
	lw	$fp,40($sp)
	addiu	$sp,$sp,48
	j	$31
	nop

	.set	macro
	.set	reorder
	.end	main
	.size	main, .-main
	.align	2
	.globl	crazyDiv
	.set	nomips16
	.set	nomicromips
	.ent	crazyDiv
	.type	crazyDiv, @function
crazyDiv:
	.frame	$fp,8,$31		# vars= 0, regs= 1/0, args= 0, gp= 0
	.mask	0x40000000,-4
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	addiu	$sp,$sp,-8
	sw	$fp,4($sp)
	move	$fp,$sp
	sw	$4,8($fp)
	sw	$5,12($fp)
	lw	$2,12($fp)
	lw	$2,0($2)
	beq	$2,$0,.L2
	nop

	lw	$2,8($fp)
	lw	$3,0($2)
	lw	$2,12($fp)
	lw	$2,0($2)
	div	$0,$3,$2
	mfhi	$3
	mflo	$2
	move	$3,$2
	lw	$2,8($fp)
	sw	$3,0($2)
.L2:
	move	$sp,$fp
	lw	$fp,4($sp)
	addiu	$sp,$sp,8
	j	$31
	nop

	.set	macro
	.set	reorder
	.end	crazyDiv
	.size	crazyDiv, .-crazyDiv
	.align	2
	.globl	swap
	.set	nomips16
	.set	nomicromips
	.ent	swap
	.type	swap, @function
swap:
	.frame	$fp,16,$31		# vars= 8, regs= 1/0, args= 0, gp= 0
	.mask	0x40000000,-4
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	addiu	$sp,$sp,-16
	sw	$fp,12($sp)
	move	$fp,$sp
	sw	$4,16($fp)
	sw	$5,20($fp)
	lw	$2,16($fp)
	lw	$2,0($2)
	sw	$2,0($fp)
	lw	$2,20($fp)
	lw	$3,0($2)
	lw	$2,16($fp)
	sw	$3,0($2)
	lw	$2,20($fp)
	lw	$3,0($fp)
	sw	$3,0($2)
	move	$sp,$fp
	lw	$fp,12($sp)
	addiu	$sp,$sp,16
	j	$31
	nop

	.set	macro
	.set	reorder
	.end	swap
	.size	swap, .-swap
	.ident	"GCC: (Sourcery G++ Lite 2011.03-52) 4.5.2"
