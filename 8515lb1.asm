; ��. ��6-71 ��������
.include "m8515def.inc" ; ���������� ATmega8515
.def tmp = r16 ; ��������� �������
.def dr1 = r17 ; ������� ��������
.def stt = r18 ; ������� ������/���������� ���������
.def stp = r19 ; ������� ���������/���� ������
.def with = r20 ; ������� �������� - ������� ����� ������
.def witl = r21 ; ������� �������� - ������� ����� ������
.def wrt = r22 ; ������� ������
.def resl = r23 ; ������� ���������� - ������� ������
.def resh = r24 ; ������� ���������� - ������� ������
.def rep = r25 ; ���-�� ����������
.equ STEP = 0 ; ������ "����� / ���� ���"
.equ STAT = 1 ; ������ "������� ����� / �� ��������"

.org $000
	rjmp init
.org $006
	rjmp t1_ovf

init: ; *�������������

	ldi tmp, low(RAMEND) ;���������
	out SPL, tmp ; ��������� �����
	ldi tmp, high(RAMEND) ; �� ���������
	out SPH, tmp

	ldi tmp,0x80 ;���������� ���������� ��
	out TIMSK,tmp ; ������������ ������� �1
	clr tmp ;������ �1
	out TCCR1B,tmp ; ����������
	cli

	ldi tmp, 0x00
	out UCSRA, tmp
	sbi UCSRB, TXEN ; ���������� ��������
	;ldi tmp, 0x86 ; ������ �������
	;out UCSRC, tmp 
	ldi tmp, 0x00
	out UBRRH, tmp
	ldi tmp, 11
	out UBRRL, tmp ; ������� �������� ��������

	ldi rep, 0b00000000
	ldi ZL, $40
	ldi ZH, $02
	ldi stt, 0b10000000 ; �������� � ������ 0 - ��������� �� 5 �� 20
	ldi stp, 0b10000000

    ldi tmp, 0b11001111 ; ����������� ���� � �� ����� �� �������
	out DDRC, tmp

	ldi tmp, 0b00000011 ; ����������� ���� D �� ����� �� UART
	out DDRD, tmp

	ldi tmp, 0b00000000 ; ����������� ���� � �� ����� � ������
	out DDRA, tmp
	ldi tmp, 0b11111111 ; ������������� ���������
	out PORTA, tmp

	;������ ��������� UART 0 'hi'
	ldi tmp, 'h'
	out UDR, tmp
	sbi UCSRA,TXC
	rcall delay
	ldi tmp, 'i'
	out UDR, tmp
	sbi UCSRA,TXC
	rcall delay
	
	;������������� LCD
	;_
	ldi tmp, 0b00000011 ; ������� ������ �� D4-D7
	out PORTC, tmp	
	rcall delay
	sbi PORTC, 6 ; ������������� ����� E - ���� ������ �������
	rcall delay
	cbi PORTC, 6 ; ������� ����� E
	rcall delay
	sbi PORTC, 6 ; ������ ������
	rcall delay
	cbi PORTC, 6
	rcall delay
	sbi PORTC, 6 ; ������ ������
	rcall delay
	cbi PORTC, 6
	rcall delay
	;_
	ldi tmp, 0b00000010
	out PORTC, tmp
	rcall delay
	sbi PORTC, 6
	rcall delay
	cbi PORTC, 6
	rcall delay
	sbi PORTC, 6
	rcall delay
	cbi PORTC, 6
	rcall delay
	;_
	ldi tmp, 0b00000001
	out PORTC, tmp
	rcall delay
	sbi PORTC, 6
	rcall delay
	cbi PORTC, 6
	rcall delay
	;_
	ldi tmp, 0b00000000
	out PORTC, tmp
	rcall delay
	sbi PORTC, 6
	rcall delay
	cbi PORTC, 6
	rcall delay
	;_
	ldi tmp, 0b00001111
	out PORTC, tmp
	rcall delay
	sbi PORTC, 6
	rcall delay
	cbi PORTC, 6
	rcall delay

	; ��������, ��� ��������� � ������� ������
	mov wrt, stt
	ldi tmp, 0b10000011
	rcall write_wrt
	; ������� ������� ������
	loop1:
		sbic PINA, STEP
		rjmp loop2
		rjmp stepn
	loop2:
		sbic PINA, STAT
		rjmp loop1
		rjmp statn

	statn:
		inc stt
		cpi stt, 0b10000100
		brne statn2
		; ���������� ��� � 0
		ldi stt, 0b10000000
	statn2:
		rcall clear_display
		mov wrt, stt
		ldi tmp, 0b10000011
		rcall write_wrt
		rjmp loop1

	step_gen: ; ���������� ��������� ����� ��� ������ �������
		cpi stt, 0b10000000
		breq step_gen1
		cpi stt, 0b10000001
		breq step_gen2
		cpi stt, 0b10000010
		breq step_gen3
		cpi stt, 0b10000011
		breq step_gen4
	step_gen1: ;5 .. 20
		ldi resl, 0b10000101
		ldi resh, 0b10000000
		ldi with, 0b10000010
		ldi witl, 0b10000000
		rjmp step_gen5
	step_gen2: ;20 .. 40
		ldi resh, 0b10000010
		ldi resl, 0b10000000
		ldi with, 0b10000100
		ldi witl, 0b10000000
		rjmp step_gen5
	step_gen3: ;30 .. 60
		ldi resh, 0b10000011
		ldi resl, 0b10000000
		ldi with, 0b10000110
		ldi witl, 0b10000000
		rjmp step_gen5
	step_gen4: ;5 .. 60
		ldi resh, 0b10000000
		ldi resl, 0b10000101
		ldi with, 0b10000110
		ldi witl, 0b10000000
		rjmp step_gen5
	step_gen5:
		rcall clear_display
		ldi wrt,0xFF ; �������� TCNT1
		out TCNT1H,wrt
		ldi wrt,0xFF
		out TCNT1L,wrt
		sei ;���������� ���������� ����������
		ldi wrt, 0x01
		out TCCR1B,wrt ;������ ������� � �������������
		rjmp loop1

	stepn:
		inc stp
		cpi stp, 0b10000001
		breq step_gen
		cpi stp, 0b10000010
		breq step_shg
		cpi stp, 0b10000011
		breq step_wait
		cpi stp, 0b10000100
		breq step_res
		cpi stp, 0b10000101
		breq step_c
		rjmp loop1

	step_c: ; ���� ��� 5, ���������� � 0 � ������� ���
		ldi stp, 0b10000000
		rcall clear_display
		mov wrt, stt
		ldi tmp, 0b10000011
		rcall write_wrt
		rjmp loop1

	step_shg:
		cli
		clr wrt ;�������
		out TCCR1B,wrt ; ������� �1
		mov with, resh
		mov witl, resl
		rcall clear_display
		mov wrt, resh
		ldi tmp, 0b10000011
		rcall write_wrt
		mov wrt, resl
		ldi tmp, 0b10000011
		rcall write_wrt
		mov witl, resl
		mov with, resh
		rjmp loop1

	step_wait:
		ldi resl, 0b10000000
		ldi resh, 0b10000000 ;***��������� ������� �1 �� ����� �������
		ldi wrt,0x1E ; �������� TCNT1
		out TCNT1H,wrt
		ldi wrt,0xC8
		out TCNT1L,wrt
		sei ;���������� ���������� ����������
		ldi wrt, 0x03
		out TCCR1B,wrt ;������ ������� � �������������
		ldi tmp, 0b10000010
		ldi wrt, 0b10000001
		rcall write_wrt
		rjmp loop1

	step_res: ; ������� ���������
		cli
		clr wrt ;���������
		out TCCR1B,wrt ; ������� �1
		rcall clear_display
		mov wrt, resh
		ldi tmp, 0b10000011
		rcall write_wrt
		ldi tmp, 0b10000011
		mov wrt, resl
		rcall write_wrt
		ldi tmp, 0b10000010
		ldi wrt, 0b10000000
		rcall write_wrt ; ����� ������� " "
		; �������� �� ����������� ��������� � ������� �������
		andi resl, 0b00001111
		andi resh, 0b00001111
		andi witl, 0b00001111
		andi with, 0b00001111
		; �������� ������� � ���� 10resh+resl-(10with+witl)
sub_s1:	ldi tmp, 10
		mul with, tmp
		mov with, r0
		add with, witl
sub_s2:
		mul resh, tmp
		mov resh, r0
		add resh, resl
		sub resh, with
		brmi sub_c2
		rjmp sub_s3
sub_c2: ; ��������� � ������ ���, ���� ������� < 0
		ldi dr1, 0xff
		eor resh, dr1
		inc resh
sub_s3:
		ldi dr1, 0
		ldi tmp, 0b00001010
sub_loop: ; �������, ������� ������� ������ � �����
		cp resh, tmp
		brlo sub_out
		inc dr1
		sub resh, tmp
		rjmp sub_loop
sub_out: ; ����� �� ������� � ������ � ������
		mov resl, resh
		mov resh, dr1
		andi resl, 0b00001111
		andi resh, 0b00001111
		ldi dr1, $30 ; ��� ��������� ����� � ascii
		mov tmp, resl
		add tmp, dr1
		st Z+, tmp
		mov tmp, resh
		add tmp, dr1
		st Z+, tmp
		inc rep
		ori resh, 0b10000000
		ori resl, 0b10000000
		ldi tmp, 0b10000011
		mov wrt, resh
		rcall write_wrt
		ldi tmp, 0b10000011
		mov wrt, resl
		rcall write_wrt
		cpi rep, 0b00000101
		breq res_res
		rjmp loop1

res_res: ; ����� 5 ����������� ����������� �� UART
	ldi tmp, ' '
	out UDR, tmp
	sbi UCSRA,TXC
	rcall delay
	ldi tmp, 'r'
	out UDR, tmp
	sbi UCSRA,TXC
	rcall delay
	ldi tmp, 'e'
	out UDR, tmp
	sbi UCSRA,TXC
	rcall delay
	ldi tmp, 's'
	out UDR, tmp
	sbi UCSRA,TXC
	rcall delay
	ldi tmp, ':'
	out UDR, tmp
	sbi UCSRA,TXC
	rcall delay
	ldi tmp, ' '
	out UDR, tmp
	sbi UCSRA,TXC
	rcall delay
mem_loop:	
	ld tmp, -Z
	out UDR, tmp
	sbi UCSRA,TXC
	rcall delay
	ld tmp, -Z
	out UDR, tmp
	sbi UCSRA,TXC
	rcall delay
	ldi tmp, ' '
	out UDR, tmp
	sbi UCSRA,TXC
	rcall delay
	dec rep
	brne mem_loop
	rjmp loop1

t1_ovf: ; �� ������ ����� ���������� ������� ������
	cpi stp, 0b10000001
	brne t1_ovf_w ; ���� ������������ ��������, �� ���������
	clr tmp ; ���� �������� - ���������� ������������
	out TCCR1B,tmp ; ������������� ������ �1
	ldi tmp,0xFF
	out TCNT1H,tmp ; ������������ TCNT1
	ldi tmp,0xFF
	out TCNT1L,tmp
	ldi tmp, 0x01
	out TCCR1B,tmp ;������ ������� � �������������
	inc resl
	cpi resl, 0b10001010
	breq resl_ovf
	cp resh, with
	breq resh_ovf
	reti

resh_ovf: ; ������������ �������� ������� ��� ��������� - ����� � 00
	cpi stt, 0b10000000
	breq resh_ovf1
	cpi stt, 0b10000001
	breq resh_ovf2
	cpi stt, 0b10000010
	breq resh_ovf3
	cpi stt, 0b10000011
	breq resh_ovf4
	reti
resh_ovf1:
	ldi resl, 0b10000101
	ldi resh, 0b10000000
	reti
resh_ovf2:
	ldi resh, 0b10000010
	ldi resl, 0b10000000
	reti
resh_ovf3:
	ldi resh, 0b10000011
	ldi resl, 0b10000000
	reti
resh_ovf4:
	ldi resh, 0b10000000
	ldi resl, 0b10000101
	reti

t1_ovf_w: ; �������� �����
	clr tmp
	out TCCR1B,tmp ; ������������� ������ �1
	ldi tmp,0x1E
	out TCNT1H,tmp ; ������������ TCNT1
	ldi tmp,0xC8
	out TCNT1L,tmp
	ldi tmp, 0x03
	out TCCR1B,tmp ;������ ������� � �������������
	inc resl
	cpi resl, 0b10001010
	breq resl_ovf
	reti

resl_ovf: ; ������������ �������� ������� - ���������� ��������, ����� �������� � 0
	ldi resl, 0b10000000
	inc resh
	reti


delay:
    dms:
        ldi  dr1, 170    ; ������������� ������� �����
    dl1:ldi  tmp, 255    ; ������������� ������� �����
    dl2:dec  tmp        ; ���� ������� �����
        brne dl2       ; �������� ���������� �� ������� ����� (������� ��� 0 � ����� ���������� ��������)
        dec  dr1        ; ���� ������� �����
        brne dl1        ; �������� ���������� �� ������� �����
    dend: ret          ; �������

write_wrt: ; tmp - ������ �������, wrt - ������
		out PORTC, tmp
		rcall delay
		sbi PORTC, 6 ; �����
		rcall delay
		cbi PORTC, 6
		rcall delay
		out PORTC, wrt
		rcall delay
		sbi PORTC, 6 ; �����
		rcall delay
		cbi PORTC, 6
		rcall delay
		ret

clear_display:
	ldi tmp, 0b00000000 ; �������
	out PORTC, tmp
	rcall delay
	sbi PORTC, 6 ; �����
	rcall delay
	cbi PORTC, 6
	rcall delay
	ldi tmp, 0b00000001 ; ��������� �������
	out PORTC, tmp
	rcall delay
	sbi PORTC, 6 ; �����
	rcall delay
	cbi PORTC, 6
	rcall delay
	ret
