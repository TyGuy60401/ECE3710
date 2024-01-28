        mov     R0, #50
loop:   LCALL   foo
        djnz    R0,loop
endlp:  sjmp    endlp


foo:    mov	A, #0FFh
        RET
        



