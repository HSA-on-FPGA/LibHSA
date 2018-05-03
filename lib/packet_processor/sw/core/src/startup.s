	.set    noreorder
	.section .mdebug.abiO64
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
	lui	$2,%highest(_stack_start)
	lui	$3,%hi(_stack_start)
	daddiu	$2,$2,%higher(_stack_start)
	daddiu	$3,$3,%lo(_stack_start)
	dsll	$2,$2,32
	daddu	$sp,$2,$3
    # enable interrupts
    lui $t0,0xffff
    lui $t1,0x0
    ori $t1,$t1,0xfffd
    add $t1,$zero,$t1
    add $t0,$t0,$t1
    mtc0 $t0,$12 # store 0xfffffffd at cop0 status reg
    # store $ra
    # stack is 8 byte aligned
    daddiu   $sp,$sp,-8
    sd      $ra,8($sp)
    # jump to main
	jal main
	nop
    # restore $ra
    ld      $ra,8($sp)
    daddiu   $sp,$sp,8
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
    daddiu   $sp,$sp,-16
    sd      $ra,8($sp)
    jal _exception_handler
    ld      $ra,8($sp)
    daddiu   $sp,$sp,16
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
