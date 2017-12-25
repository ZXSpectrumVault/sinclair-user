; Z80DASM 1.1.3
; COMMAND LINE: Z80DASM -L -G 0X8000H -B BLOCKS.ASM -O DECOMPILED.ASM DECOMPILED.REF.BIN

        ORG     08000H

NO_SHAPES:
	EQU 6

DETECT_DEMO:
        LD A,001H                ; set the border to blue
        OUT (0FEH),A
        LD HL,04000H             ; clear the pixel screen
        LD DE,04001H
        LD BC,017FFH
        LD (HL),L
        LDIR
        CALL DRAW STARS          ; draw in the background and borders
        LD IX,BLOB_VARS          ; set up IX to point to the first set
        LD B,006H                ; of shape variables and make B equal
                                 ; to the number of shapes we want
INIT_LOOP:
        PUSH BC                  ; preserve B - the counter
        LD D,(IX+001H)           ; set up DE with the X and Y coords
        LD E,(IX+000H)           ; of the shape
        CALL DRAW_BLOB           ; draw it to the screen
        LD C,004H
        ADD IX,BC                ; make IX point to the next shape
        POP BC                   ; restore B
        DJNZ INIT_LOOP           ; loop back to draw in the rest of
                                 ; the shapes
MAIN_LOOP:                       ; synchronise the output loop with a
        HALT                     ; HALT and set up BC for the flicker
        LD BC,0076CH             ; reducing counter
DELAY:  DEC BC                   ; if BC has not gone negative then go
        BIT 7,B                  ; back (1901 times)
        JR Z,DELAY
        LD IX,BLOB_VARS          ; initialise IX to the shape variable
        LD B,006H                ; list and B as a counter to the
BLOB_LOOP:                       ; number of shapes required
        PUSH BC                  ; save the counter
        CALL OUTPUT_BLOB         ; CALL the main shape output and test
                                 ; routine
        DEC D                    ; NO CARRY from OUTPUT_BLOB
        LD D,B                   ; means that collision has occurred so we
        ADD A,B                  ; CALL CHANGE_DIR to make the shape
        LD BC,00004H             ; rebound
        ADD IX,BC                ; move IX on to the next set of shape
        POP BC                   ; variables and restore B
        DJNZ BLOB_LOOP           ; loop back as required
        LD A,07FH                ; set A to the keyboard half row
        IN A,(0FEH)              ; B-SPACE and read it
        RRA                      ; check Bit 0 (SPACE)
        JR C,MAIN_LOOP           ; jump back if not pressed
        RET                      ; else return to BASIC
CHANGE_DIR:
        CALL DIR10               ; CALL DIR10 to get a random value of
        LD (IX+002H),A           ; 0,1,-1 into the accumulator. Store
        LD C,A                   ; it in the X movement variable
                                 ; (IX+2) and also temporarily in C
        CALL DIR10               ; do the same for the Y movement
        LD (IX+003H),A
        OR C                     ; variable and then OR it with C
                                 ; if the X and Y movement variables
        JR Z,CHANGE_DIR          ; are both zero then the shape would
                                 ; not move so jump back to CHANGE_DIR
        RET                      ; then return
DIR10:  CALL RAND_NUM            ; get an 8-bit random number
        CP 060H
        JR NC,DIR20              ; jump if A>96
        LD A,0FFH                ; if A is 0-95, then make A=-1
        RET
DIR20:  CP 0A0H
        JR C,DIR30               ; jump if A<160
        LD A,001H                ; if A>160 then make A=1
        RET                      ;
DIR30:  XOR A                    ; if 96<=A<160 then make A=0
        RET
DRAW STARS:
        LD BC,0FFBFH             ; make BC = counter values
        LD DE,00000H             ; DE = screen top left coordinates
ST10:   CALL PLOT                ; plot at DE
        INC E                    ; stop along a pixel
        DJNZ ST10                ; and repeat for 255 times
        LD B,C                   ; make B = 191
ST20:   CALL PLOT                ; plot at top right corner
        INC D                    ; and step down the screen 191 times
        DJNZ ST20
        DEC B                    ; decrement B to make it = 255
ST30:   JP M,PLOT ; CALL PLOT    ; plot at bottom right corner
        DEC E     ; DEC D        ; step from right to left
        DJNZ ST30                ; for 255 times
        LD B,C                   ; make B = 191
ST40:   CALL PLOT                ; plot at bottom left corner
        DEC D                    ; and step up the left edge of the
        DJNZ ST40                ; screen for 191 times
        INC B                    ; make BC = 447
ST50:   PUSH BC                  ; save it
        CALL Y_RAND_NUM          ; get random number from 0-191
        LD D,A                   ; put it in D
        CALL RAND_NUM            ; now get one from 0-255
        LD E,A                   ; and put it in E
        CALL PLOT_ADDR           ; now plot at this random coordinate
        OR (HL)                    by OR'ing with the screen
        LD (HL),A                ; point at by HL
        POP BC                   ; restore the counter
        DEC BC                   ; decrement it and loop back for 448
        BIT 7,B                  ; times (until BC goes negative)
        JR Z,ST50
        RET
OUTPUT_BLOB:
        LD D,(IX+001H)           ; set up DE from the shape coordinate
        LD E,(IX+000H)           ; variables
        CALL DRAW_BLOB           ; rub out the blob from its present
                                 ; position
        LD A,(IX+002H)           ; now add in the X movement variable
        ADD A,E                  ; to the X coordinate and put in E
        LD E,A                   ;
        LD A,(IX+003H)           ; do the same with the Y movement
        ADD A,D                  ; variable but put it in D
        LD D,A                   ;
        CALL DRAW_BLOB           ; draw in the shape at the new moved
                                 ; position
        JR C,PUT_BACK            ; if there was a CARRY, then the new
                                 ; position has hit a pixel so jump
                                 ; to PUT_BACK and don't move
        LD (IX+001H),D           ; if the new position was OK then
        LD (IX+000H),E           ; store the new X and Y coordinates
        SCF                      ; and set the CARRY before returning
        RET                      ; to signal - MOVE SUCCESSFUL
PUT_BACK:
        CALL DRAW_BLOB           ; rub out the moved shape
        LD D,(IX+001H)           ;
        LD E,(IX+000H)           ; Y position
        CALL DRAW_BLOB           ; and re-draw the shape at its first
        AND A                    ; position, CLEAR the carry flag
        RET                      ; before returning to signal - MOVE
                                 ; UNSUCCESSFUL
DRAW_BLOB:
        PUSH DE                  ; save DE
        CALL PLOT_ADDR           ; calculate the screen address at
                                 ; which to draw the shape (from DE)
        LD DE,SHAPE              ; make DE point to the shape data
        EX AF,AF'                ; clear the alternative carry flag
        AND A
        EX AF,AF'
        LD B,008H                ; there are 8 pixel rows in the shape
BLOB10: PUSH BC                  ; save the counter
        PUSH DE                  ; ... and the shape pointer
        LD B,C                   ; B = C = X pixel position (1 - 8)
        LD A,(DE)                ; get the shape data byte
        LD D,A                   ; put it in DE (E = 0)
        LD E,000H
BLOB20: SRL D                    ; rotate DE as required to bring the
        RR E                     ; shape data into the correct place
        DJNZ BLOB20              ; for outputting to the screen
                                 ; The detection and output stage
        LD A,D                   ; get the leftmost byte of data and
        XOR L                    ; logically XOR it with the screen
        LD (HL),A                ; data then store it in the screen
        AND D                    ; mask off the bits we have just put
        CP D                     ; in and check to see that they are
                                 ; the same - Zero flag set
        JR Z,BLOB30              ; jump if the same - no collision
        EX AF,AF'                ; set the alternative carry flag to
        SCF                      ; indicate that a collision has in
        EX AF,AF'                ; fact occurred
BLOB30: INC HL                   ; step on the screen point across
        LD A,E                   ; the screen and now treat the right
        XOR (HL)                 ; most byte of shape data in the same
        LD (HL),A                  way - XORing to the screen, masking
        AND E                    ; the bits we are interested in and
        CP E                     ; comparing to check that they are
        JR Z,BLOB40              ; the same - jumping if they are
        EX AF,AF'                ; as before, set the alternative
        SCF                      ; carry flag if a collision has
        EX AF,AF'                ; occurred
BLOB40: DEC HL                   ; step the screen pointer back to its
        INC H                    ; first place and increment it down
        LD A,H                   ; the screen
        AND 007H                 ; if within the same character cell
        JR NZ,BLOB50             ; then jump
        LD A,L                   ; else add 32 to the low byte of the
        ADD A,020H               ; screen pointer
        LD L,A
        JR C,BLOB50              ; if transition across a screen
                                 ; 'third' has been made then jump
        LD A,A                   ; else subtract 8 off the pointer
        SUB 008H                 ; high byte
        LD H,A
BLOB50: POP DE                   ; restore the shape pointer
        POP BC                   ; and the 8 pixel row counter
        INC DE                   ; increment the shape pointer
        DJNZ BLOB10              ; and decrement the counter
        EX AF,AF'                ; make the alternative carry flag
        POP DE                   ; available to the CALLing routine
        RET                      ; restore DE and return
PLOT:
        PUSH BC                  ; save registers from corruption
        PUSH DE                  ;
        CALL PLOT_ADDR           ; calculate the screen plot address
        OR (HL)                  ; and OR in the pixel to
        LD (HL),A                ; the screen
        POP DE
        POP BC                   ; restore registers and return
        RET
PLOT_ADDR:
        LD A,D                   ; check the Y coordinate range to see
        CP 0C0H                  ; that it is not off the screen
        RET NC                   ; return if it is
        AND 0C0H                 ; put the screen 'third' bits into
        RRA                      ; bits 3 and 4 with a 010 in bit
        SCF                      ; positions 5, 6 and 7
        RRA
        RRA
        XOR D                    ; merge in the bits 0, 1, and 2 from
        AND 0F8H                 ; the Y coordinate
        XOR D
        LD H,A                   ; and store in H
        LD A,E                   ; move the top 5 bits of the X co-
        RLCA                     ; ordinate into bits 0, 1, 2 and 6, 7
        RLCA
        RLCA
        XOR D                    ; merge in bits 3, 4 and 5 from the
        AND 0C7H                 ; Y coordinate
        XOR D
        RLCA                     ; rotate the byte twice more and
        RLCA                     ; hey presto we have
        LD L,A                   ; the low byte of the screen address
        LD A,E                   ; get the three lower bits of the X
        AND 007H                 ; coordinate and increment them to
        INC A                    ; give the range 1 - 8
        LD B,A                   ; copy it to B and C
        LD C,A
        LD A,001H                ; set bit 0 of A
PLOT10: RRCA                     ; rotate it so that the set bit is
        DJNZ PLOT10              ; in the correct place before
        RET                      ; returning
Y_RAND_NUM:
        CALL RAND_NUM            ; get an 8-bit random number and
        CP 0C5H                  ; check to see that it is less than
        JR NC,Y_RAND             ; 192. Jump back if it isn't until
        RET                      ; we get a valid number less than 192
RAND_NUM:
        LD HL,(SEED_POINTER)     ; the random number is obtained by
        INC HL                   ; poking the Spectrum ROM from 0000H
        LD A,H                   ; to 4000H
        AND 03FH                 ; the pointer to the ROM address is
        LD H,A                   ; incremented each time we call the
        LD (SEED_POINTER),HL     ; random number routine and the
        LD A,(HL)                ; accumulator is loaded with the
        RET                      ; current pointer value before
                                 ; returning

        ; this is the 8 bytes of shape data
SHAPE:
        RST 38H
        ADD A,C
        ADD A,C
        SBC A,A
        ADD A,B
        ADD A,C
        ADD A,C
        RST 38H

        ; the random number pointer
SEED_POINTER:
        RET NC
        RLCA

        ;initial values for the 6 shape variables
BLOB_VARS:
        DJNZ $+50
        LD BC,050FFH
        ADD HL,BC
        RST 38H
        NOP
        LD H,B
        ADD HL,BC
        LD BC,07001H
        SBC A,A
        NOP
        RST 38H
        ADD A,B
        SBC A,A
        RST 38H
        NOP
        DJNZ $+129
        RST 38H
        NOP
