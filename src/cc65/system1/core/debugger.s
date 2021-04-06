
.include "macros.inc"
.include "zeropage.inc"

.import dump_registers, dump_memory, jump_memory, write_memory
.import console_read_string, console_write_string, console_write_newline
.import mem_clear
.export debugger_run

.code

  debugger_run:
      loadptr prompt, console_out_ptr
      jsr console_write_string

      loadptr console_buffer, ptr1
      lda #BUFFLEN
      jsr console_read_string

      lda console_buffer
      cmp #'m'
      beq @dumpmem

      cmp #'w'
      beq @writemem

      cmp #'j'
      beq @jumpmem

      cmp #'d'
      beq @dumpreg

      cmp #'h'
      beq @help

      cmp #'x'
      beq @exit

      cmp #'t'
      beq @memclear

      loadptr unknown, console_out_ptr
      jsr console_write_string
      jmp debugger_run

@memclear:
jsr mem_clear
jmp debugger_run

    @dumpmem:
      jsr dump_memory
      jmp debugger_run

    @jumpmem:
      jsr jump_memory
      jmp debugger_run

    @writemem:
      jsr write_memory
      jmp debugger_run

    @dumpreg:
      jsr dump_registers
      jmp debugger_run

    @help:
      loadptr help, console_out_ptr
      jsr console_write_string
      jmp debugger_run

    @exit:
      jsr console_write_newline
      rts


.bss
    BUFFLEN = 20
    console_buffer: .res BUFFLEN + 1, 0

.rodata
  prompt:
    .byte $0D, $0A, "Debugger>", $00
  help:
    .byte $0D, $0A
    .byte "m xxxx [ll] - Look at memory at address xxxx with an optional length of l.", $0D, $0A
    .byte "w xxxx dd - Write dd to memory address xxxx", $0D, $0A
    .byte "j xxxx - Jump to memory address xxxx", $0D, $0A
    .byte "d - Dump all registers", $0D, $0A
    .byte "h - Help (this message)", $0D, $0A
    .byte "x - Exit", $0D, $0A
    .byte $0D, $0A
    .byte $00
  unknown:
    .byte "Unknown command. Type 'h' for help.", $0D, $0A, $00
  