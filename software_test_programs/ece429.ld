SECTIONS
{
/*
 * Allocate the stack to be at the top of memory, since the stack
 * grows down
 */

PROVIDE (__stack = 0);

  . = 0x80020000;
	.text : { *(.text) }
	.data : { *(.data) }
	.bss  : { *(.bss) }
}
