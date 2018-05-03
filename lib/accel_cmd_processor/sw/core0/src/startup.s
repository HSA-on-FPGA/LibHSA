	.set    noreorder
	.section .mdebug.abi32
	.previous
	.text
	.align	2
	.globl _start
	.set	nomips16
	.ent	_start
	.type	_start, @function
_start:
	.frame	$fp,32,$31		# vars= 8, regs= 2/0, args= 16, gp= 0
    jal _startup_code
    nop
    j _halt
    nop
    j __exception_handler
    nop
	# .set    reorder
	.end	_start
	.size	_start, .-_start
	.align	2
	.globl	_startup_code
	.set	nomips16
	.ent	_startup_code
	.type	_startup_code, @function
_startup_code:
    # set stack pointer
	lui	$sp,%hi(_stack_start)           # set stack pointer hi
	addiu	$sp,$sp,%lo(_stack_start)   # set stack pointer lo
    # enable interrupts
    lui $t0,0xffff
    lui $t1,0x0
    ori $t1,$t1,0xfffd
    add $t1,$zero,$t1
    add $t0,$t0,$t1
    mtc0 $t0,$12 # store 0xfffffffd at cop0 status reg
    # store $ra
    # stack is 8 byte aligned
    addiu   $sp,$sp,-8
    sw      $ra,4($sp)
    # jump to main
	jal main
	nop
    # restore $ra
    lw      $ra,4($sp)
    addiu   $sp,$sp,8
    # jump back into _start
    jr $ra
	.end	_startup_code
	.size	_startup_code, .-_startup_code
	.set    reorder
	.ident	"GCC: (GNU) 4.8.1"
	.align	2
	.globl	_halt
	.set	nomips16
	.ent	_halt
	.type	_halt, @function
_halt:
    j _halt
    nop
	.end	_halt
	.size	_halt, .-_halt
	.set    reorder
	.ident	"GCC: (GNU) 4.8.1"
	.align	2
	.globl	__exception_handler
	.set	nomips16
	.ent	__exception_handler
	.type	__exception_handler, @function
__exception_handler:
    addiu   $sp,$sp,-8
    sw      $ra,4($sp)
    jal _exception_handler
    lw      $ra,4($sp)
    addiu   $sp,$sp,8
    eret
    nop
	.end	__exception_handler
	.size	__exception_handler, .-__exception_handler
	.set    reorder
	.ident	"GCC: (GNU) 4.8.1"
#	.align	2
#	.globl	exception_handler
#	.set	nomips16
#	.ent	exception_handler
#	.type	exception_handler, @function
#exception_handler:
#    j exception_handler
#    nop
#	.end	exception_handler
#	.size	exception_handler, .-exception_handler
#	.set    reorder
#	.ident	"GCC: (GNU) 4.8.1"
