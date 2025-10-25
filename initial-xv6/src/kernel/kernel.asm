
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a7010113          	addi	sp,sp,-1424 # 80008a70 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8de70713          	addi	a4,a4,-1826 # 80008930 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	06c78793          	addi	a5,a5,108 # 800060d0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbc647>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	f4a78793          	addi	a5,a5,-182 # 80000ff8 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	57a080e7          	jalr	1402(ra) # 800026a6 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8e650513          	addi	a0,a0,-1818 # 80010a70 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	bc4080e7          	jalr	-1084(ra) # 80000d56 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8d648493          	addi	s1,s1,-1834 # 80010a70 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	96690913          	addi	s2,s2,-1690 # 80010b08 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	9c0080e7          	jalr	-1600(ra) # 80001b80 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	328080e7          	jalr	808(ra) # 800024f0 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	066080e7          	jalr	102(ra) # 8000223c <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	43e080e7          	jalr	1086(ra) # 80002650 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	84a50513          	addi	a0,a0,-1974 # 80010a70 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	bdc080e7          	jalr	-1060(ra) # 80000e0a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	83450513          	addi	a0,a0,-1996 # 80010a70 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	bc6080e7          	jalr	-1082(ra) # 80000e0a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	88f72b23          	sw	a5,-1898(a4) # 80010b08 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7a450513          	addi	a0,a0,1956 # 80010a70 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a82080e7          	jalr	-1406(ra) # 80000d56 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	40a080e7          	jalr	1034(ra) # 800026fc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	77650513          	addi	a0,a0,1910 # 80010a70 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	b08080e7          	jalr	-1272(ra) # 80000e0a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	75270713          	addi	a4,a4,1874 # 80010a70 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	72878793          	addi	a5,a5,1832 # 80010a70 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7927a783          	lw	a5,1938(a5) # 80010b08 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6e670713          	addi	a4,a4,1766 # 80010a70 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6d648493          	addi	s1,s1,1750 # 80010a70 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	69a70713          	addi	a4,a4,1690 # 80010a70 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	72f72223          	sw	a5,1828(a4) # 80010b10 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	65e78793          	addi	a5,a5,1630 # 80010a70 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6cc7ab23          	sw	a2,1750(a5) # 80010b0c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ca50513          	addi	a0,a0,1738 # 80010b08 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e5a080e7          	jalr	-422(ra) # 800022a0 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	61050513          	addi	a0,a0,1552 # 80010a70 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	85e080e7          	jalr	-1954(ra) # 80000cc6 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00241797          	auipc	a5,0x241
    8000047c:	ba878793          	addi	a5,a5,-1112 # 80241020 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5e07a323          	sw	zero,1510(a5) # 80010b30 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	bac50513          	addi	a0,a0,-1108 # 80008118 <digits+0xd8>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	36f72923          	sw	a5,882(a4) # 800088f0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	576dad83          	lw	s11,1398(s11) # 80010b30 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	52050513          	addi	a0,a0,1312 # 80010b18 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	756080e7          	jalr	1878(ra) # 80000d56 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	3c250513          	addi	a0,a0,962 # 80010b18 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	6ac080e7          	jalr	1708(ra) # 80000e0a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	3a648493          	addi	s1,s1,934 # 80010b18 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	542080e7          	jalr	1346(ra) # 80000cc6 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	36650513          	addi	a0,a0,870 # 80010b38 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	4ec080e7          	jalr	1260(ra) # 80000cc6 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	514080e7          	jalr	1300(ra) # 80000d0a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0f27a783          	lw	a5,242(a5) # 800088f0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	586080e7          	jalr	1414(ra) # 80000daa <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0c27b783          	ld	a5,194(a5) # 800088f8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0c273703          	ld	a4,194(a4) # 80008900 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	2d8a0a13          	addi	s4,s4,728 # 80010b38 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	09048493          	addi	s1,s1,144 # 800088f8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	09098993          	addi	s3,s3,144 # 80008900 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	a0e080e7          	jalr	-1522(ra) # 800022a0 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	26a50513          	addi	a0,a0,618 # 80010b38 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	480080e7          	jalr	1152(ra) # 80000d56 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0127a783          	lw	a5,18(a5) # 800088f0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	01873703          	ld	a4,24(a4) # 80008900 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	0087b783          	ld	a5,8(a5) # 800088f8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	23c98993          	addi	s3,s3,572 # 80010b38 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	ff448493          	addi	s1,s1,-12 # 800088f8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	ff490913          	addi	s2,s2,-12 # 80008900 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	920080e7          	jalr	-1760(ra) # 8000223c <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	20648493          	addi	s1,s1,518 # 80010b38 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	fae7bd23          	sd	a4,-70(a5) # 80008900 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	4b2080e7          	jalr	1202(ra) # 80000e0a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	17c48493          	addi	s1,s1,380 # 80010b38 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	390080e7          	jalr	912(ra) # 80000d56 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	432080e7          	jalr	1074(ra) # 80000e0a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <initializePageReferenceCount>:
  int pageRefCount[PHYSTOP >> 12];
}referenceCountManager;
referenceCountManager refcntmgr;

void initializePageReferenceCount(void) 
{
    800009ea:	1141                	addi	sp,sp,-16
    800009ec:	e406                	sd	ra,8(sp)
    800009ee:	e022                	sd	s0,0(sp)
    800009f0:	0800                	addi	s0,sp,16
  initlock(&refcntmgr.lock,"refCount");
    800009f2:	00007597          	auipc	a1,0x7
    800009f6:	66e58593          	addi	a1,a1,1646 # 80008060 <digits+0x20>
    800009fa:	00010517          	auipc	a0,0x10
    800009fe:	19650513          	addi	a0,a0,406 # 80010b90 <refcntmgr>
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2c4080e7          	jalr	708(ra) # 80000cc6 <initlock>
  acquire(&refcntmgr.lock);
    80000a0a:	00010517          	auipc	a0,0x10
    80000a0e:	18650513          	addi	a0,a0,390 # 80010b90 <refcntmgr>
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	344080e7          	jalr	836(ra) # 80000d56 <acquire>
  int pageCount=PHYSTOP >> 12;
  for(int i=0;i<pageCount;i++){
    80000a1a:	00010797          	auipc	a5,0x10
    80000a1e:	18e78793          	addi	a5,a5,398 # 80010ba8 <refcntmgr+0x18>
    80000a22:	00230717          	auipc	a4,0x230
    80000a26:	18670713          	addi	a4,a4,390 # 80230ba8 <pid_lock>
    refcntmgr.pageRefCount[i]=0;
    80000a2a:	0007a023          	sw	zero,0(a5)
  for(int i=0;i<pageCount;i++){
    80000a2e:	0791                	addi	a5,a5,4
    80000a30:	fee79de3          	bne	a5,a4,80000a2a <initializePageReferenceCount+0x40>
  }
  release(&refcntmgr.lock);
    80000a34:	00010517          	auipc	a0,0x10
    80000a38:	15c50513          	addi	a0,a0,348 # 80010b90 <refcntmgr>
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	3ce080e7          	jalr	974(ra) # 80000e0a <release>
}
    80000a44:	60a2                	ld	ra,8(sp)
    80000a46:	6402                	ld	s0,0(sp)
    80000a48:	0141                	addi	sp,sp,16
    80000a4a:	8082                	ret

0000000080000a4c <DecrementAndGetPageReference>:
  initializePageReferenceCount();
  freerange(end, (void*)PHYSTOP);
}

int DecrementAndGetPageReference(void *pa) 
{
    80000a4c:	1101                	addi	sp,sp,-32
    80000a4e:	ec06                	sd	ra,24(sp)
    80000a50:	e822                	sd	s0,16(sp)
    80000a52:	e426                	sd	s1,8(sp)
    80000a54:	1000                	addi	s0,sp,32
    80000a56:	84aa                	mv	s1,a0
  acquire(&refcntmgr.lock);
    80000a58:	00010517          	auipc	a0,0x10
    80000a5c:	13850513          	addi	a0,a0,312 # 80010b90 <refcntmgr>
    80000a60:	00000097          	auipc	ra,0x0
    80000a64:	2f6080e7          	jalr	758(ra) # 80000d56 <acquire>
  uint64 pageIdx=(uint64)pa >> 12;
    80000a68:	00c4d793          	srli	a5,s1,0xc
  int refCount=refcntmgr.pageRefCount[pageIdx];
    80000a6c:	00478713          	addi	a4,a5,4
    80000a70:	00271693          	slli	a3,a4,0x2
    80000a74:	00010717          	auipc	a4,0x10
    80000a78:	11c70713          	addi	a4,a4,284 # 80010b90 <refcntmgr>
    80000a7c:	9736                	add	a4,a4,a3
    80000a7e:	4718                	lw	a4,8(a4)
  if(refCount<=0){
    80000a80:	02e05763          	blez	a4,80000aae <DecrementAndGetPageReference+0x62>
    panic("DecrementAndGetPageReference");
  }
  refcntmgr.pageRefCount[pageIdx]--;
    80000a84:	377d                	addiw	a4,a4,-1
    80000a86:	0007049b          	sext.w	s1,a4
    80000a8a:	00010517          	auipc	a0,0x10
    80000a8e:	10650513          	addi	a0,a0,262 # 80010b90 <refcntmgr>
    80000a92:	0791                	addi	a5,a5,4
    80000a94:	078a                	slli	a5,a5,0x2
    80000a96:	97aa                	add	a5,a5,a0
    80000a98:	c798                	sw	a4,8(a5)
  release(&refcntmgr.lock);
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	370080e7          	jalr	880(ra) # 80000e0a <release>
  return refCount-1;  
}
    80000aa2:	8526                	mv	a0,s1
    80000aa4:	60e2                	ld	ra,24(sp)
    80000aa6:	6442                	ld	s0,16(sp)
    80000aa8:	64a2                	ld	s1,8(sp)
    80000aaa:	6105                	addi	sp,sp,32
    80000aac:	8082                	ret
    panic("DecrementAndGetPageReference");
    80000aae:	00007517          	auipc	a0,0x7
    80000ab2:	5c250513          	addi	a0,a0,1474 # 80008070 <digits+0x30>
    80000ab6:	00000097          	auipc	ra,0x0
    80000aba:	a88080e7          	jalr	-1400(ra) # 8000053e <panic>

0000000080000abe <IncrementAndGetPageReference>:

int IncrementAndGetPageReference(void *pa) 
{
    80000abe:	1101                	addi	sp,sp,-32
    80000ac0:	ec06                	sd	ra,24(sp)
    80000ac2:	e822                	sd	s0,16(sp)
    80000ac4:	e426                	sd	s1,8(sp)
    80000ac6:	1000                	addi	s0,sp,32
    80000ac8:	84aa                	mv	s1,a0
  acquire(&refcntmgr.lock);
    80000aca:	00010517          	auipc	a0,0x10
    80000ace:	0c650513          	addi	a0,a0,198 # 80010b90 <refcntmgr>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	284080e7          	jalr	644(ra) # 80000d56 <acquire>
  uint64 pageIdx=(uint64)pa >> 12;
    80000ada:	00c4d793          	srli	a5,s1,0xc
  int refCount=refcntmgr.pageRefCount[pageIdx];
    80000ade:	00478713          	addi	a4,a5,4
    80000ae2:	00271693          	slli	a3,a4,0x2
    80000ae6:	00010717          	auipc	a4,0x10
    80000aea:	0aa70713          	addi	a4,a4,170 # 80010b90 <refcntmgr>
    80000aee:	9736                	add	a4,a4,a3
    80000af0:	4718                	lw	a4,8(a4)
  if(refCount<0){
    80000af2:	02074763          	bltz	a4,80000b20 <IncrementAndGetPageReference+0x62>
    panic("IncrementAndGetPageReference");
  }
  refcntmgr.pageRefCount[pageIdx]++;
    80000af6:	2705                	addiw	a4,a4,1
    80000af8:	0007049b          	sext.w	s1,a4
    80000afc:	00010517          	auipc	a0,0x10
    80000b00:	09450513          	addi	a0,a0,148 # 80010b90 <refcntmgr>
    80000b04:	0791                	addi	a5,a5,4
    80000b06:	078a                	slli	a5,a5,0x2
    80000b08:	97aa                	add	a5,a5,a0
    80000b0a:	c798                	sw	a4,8(a5)
  release(&refcntmgr.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	2fe080e7          	jalr	766(ra) # 80000e0a <release>
  return refCount+1;  
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
    panic("IncrementAndGetPageReference");
    80000b20:	00007517          	auipc	a0,0x7
    80000b24:	57050513          	addi	a0,a0,1392 # 80008090 <digits+0x50>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	a16080e7          	jalr	-1514(ra) # 8000053e <panic>

0000000080000b30 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000b30:	1101                	addi	sp,sp,-32
    80000b32:	ec06                	sd	ra,24(sp)
    80000b34:	e822                	sd	s0,16(sp)
    80000b36:	e426                	sd	s1,8(sp)
    80000b38:	e04a                	sd	s2,0(sp)
    80000b3a:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000b3c:	03451793          	slli	a5,a0,0x34
    80000b40:	eb85                	bnez	a5,80000b70 <kfree+0x40>
    80000b42:	84aa                	mv	s1,a0
    80000b44:	00241797          	auipc	a5,0x241
    80000b48:	67478793          	addi	a5,a5,1652 # 802421b8 <end>
    80000b4c:	02f56263          	bltu	a0,a5,80000b70 <kfree+0x40>
    80000b50:	47c5                	li	a5,17
    80000b52:	07ee                	slli	a5,a5,0x1b
    80000b54:	00f57e63          	bgeu	a0,a5,80000b70 <kfree+0x40>
    panic("kfree");

  int refCount=DecrementAndGetPageReference(pa);
    80000b58:	00000097          	auipc	ra,0x0
    80000b5c:	ef4080e7          	jalr	-268(ra) # 80000a4c <DecrementAndGetPageReference>
  if(refCount>0){
    80000b60:	02a05063          	blez	a0,80000b80 <kfree+0x50>

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6902                	ld	s2,0(sp)
    80000b6c:	6105                	addi	sp,sp,32
    80000b6e:	8082                	ret
    panic("kfree");
    80000b70:	00007517          	auipc	a0,0x7
    80000b74:	54050513          	addi	a0,a0,1344 # 800080b0 <digits+0x70>
    80000b78:	00000097          	auipc	ra,0x0
    80000b7c:	9c6080e7          	jalr	-1594(ra) # 8000053e <panic>
  memset(pa, 1, PGSIZE);
    80000b80:	6605                	lui	a2,0x1
    80000b82:	4585                	li	a1,1
    80000b84:	8526                	mv	a0,s1
    80000b86:	00000097          	auipc	ra,0x0
    80000b8a:	2cc080e7          	jalr	716(ra) # 80000e52 <memset>
  acquire(&kmem.lock);
    80000b8e:	00010917          	auipc	s2,0x10
    80000b92:	fe290913          	addi	s2,s2,-30 # 80010b70 <kmem>
    80000b96:	854a                	mv	a0,s2
    80000b98:	00000097          	auipc	ra,0x0
    80000b9c:	1be080e7          	jalr	446(ra) # 80000d56 <acquire>
  r->next = kmem.freelist;
    80000ba0:	01893783          	ld	a5,24(s2)
    80000ba4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000ba6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000baa:	854a                	mv	a0,s2
    80000bac:	00000097          	auipc	ra,0x0
    80000bb0:	25e080e7          	jalr	606(ra) # 80000e0a <release>
    80000bb4:	bf45                	j	80000b64 <kfree+0x34>

0000000080000bb6 <freerange>:
{
    80000bb6:	7139                	addi	sp,sp,-64
    80000bb8:	fc06                	sd	ra,56(sp)
    80000bba:	f822                	sd	s0,48(sp)
    80000bbc:	f426                	sd	s1,40(sp)
    80000bbe:	f04a                	sd	s2,32(sp)
    80000bc0:	ec4e                	sd	s3,24(sp)
    80000bc2:	e852                	sd	s4,16(sp)
    80000bc4:	e456                	sd	s5,8(sp)
    80000bc6:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000bc8:	6785                	lui	a5,0x1
    80000bca:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000bce:	94aa                	add	s1,s1,a0
    80000bd0:	757d                	lui	a0,0xfffff
    80000bd2:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000bd4:	94be                	add	s1,s1,a5
    80000bd6:	0295e463          	bltu	a1,s1,80000bfe <freerange+0x48>
    80000bda:	89ae                	mv	s3,a1
    80000bdc:	7afd                	lui	s5,0xfffff
    80000bde:	6a05                	lui	s4,0x1
    80000be0:	01548933          	add	s2,s1,s5
    IncrementAndGetPageReference(p);
    80000be4:	854a                	mv	a0,s2
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	ed8080e7          	jalr	-296(ra) # 80000abe <IncrementAndGetPageReference>
    kfree(p);
    80000bee:	854a                	mv	a0,s2
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	f40080e7          	jalr	-192(ra) # 80000b30 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000bf8:	94d2                	add	s1,s1,s4
    80000bfa:	fe99f3e3          	bgeu	s3,s1,80000be0 <freerange+0x2a>
}
    80000bfe:	70e2                	ld	ra,56(sp)
    80000c00:	7442                	ld	s0,48(sp)
    80000c02:	74a2                	ld	s1,40(sp)
    80000c04:	7902                	ld	s2,32(sp)
    80000c06:	69e2                	ld	s3,24(sp)
    80000c08:	6a42                	ld	s4,16(sp)
    80000c0a:	6aa2                	ld	s5,8(sp)
    80000c0c:	6121                	addi	sp,sp,64
    80000c0e:	8082                	ret

0000000080000c10 <kinit>:
{
    80000c10:	1141                	addi	sp,sp,-16
    80000c12:	e406                	sd	ra,8(sp)
    80000c14:	e022                	sd	s0,0(sp)
    80000c16:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000c18:	00007597          	auipc	a1,0x7
    80000c1c:	4a058593          	addi	a1,a1,1184 # 800080b8 <digits+0x78>
    80000c20:	00010517          	auipc	a0,0x10
    80000c24:	f5050513          	addi	a0,a0,-176 # 80010b70 <kmem>
    80000c28:	00000097          	auipc	ra,0x0
    80000c2c:	09e080e7          	jalr	158(ra) # 80000cc6 <initlock>
  initializePageReferenceCount();
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	dba080e7          	jalr	-582(ra) # 800009ea <initializePageReferenceCount>
  freerange(end, (void*)PHYSTOP);
    80000c38:	45c5                	li	a1,17
    80000c3a:	05ee                	slli	a1,a1,0x1b
    80000c3c:	00241517          	auipc	a0,0x241
    80000c40:	57c50513          	addi	a0,a0,1404 # 802421b8 <end>
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	f72080e7          	jalr	-142(ra) # 80000bb6 <freerange>
}
    80000c4c:	60a2                	ld	ra,8(sp)
    80000c4e:	6402                	ld	s0,0(sp)
    80000c50:	0141                	addi	sp,sp,16
    80000c52:	8082                	ret

0000000080000c54 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000c54:	1101                	addi	sp,sp,-32
    80000c56:	ec06                	sd	ra,24(sp)
    80000c58:	e822                	sd	s0,16(sp)
    80000c5a:	e426                	sd	s1,8(sp)
    80000c5c:	e04a                	sd	s2,0(sp)
    80000c5e:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000c60:	00010497          	auipc	s1,0x10
    80000c64:	f1048493          	addi	s1,s1,-240 # 80010b70 <kmem>
    80000c68:	8526                	mv	a0,s1
    80000c6a:	00000097          	auipc	ra,0x0
    80000c6e:	0ec080e7          	jalr	236(ra) # 80000d56 <acquire>
  r = kmem.freelist;
    80000c72:	6c84                	ld	s1,24(s1)
  if(r){
    80000c74:	c0a1                	beqz	s1,80000cb4 <kalloc+0x60>
    kmem.freelist = r->next;
    80000c76:	609c                	ld	a5,0(s1)
    80000c78:	00010917          	auipc	s2,0x10
    80000c7c:	ef890913          	addi	s2,s2,-264 # 80010b70 <kmem>
    80000c80:	00f93c23          	sd	a5,24(s2)
    IncrementAndGetPageReference((void *)r);
    80000c84:	8526                	mv	a0,s1
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	e38080e7          	jalr	-456(ra) # 80000abe <IncrementAndGetPageReference>
  }
  release(&kmem.lock);
    80000c8e:	854a                	mv	a0,s2
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	17a080e7          	jalr	378(ra) # 80000e0a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c98:	6605                	lui	a2,0x1
    80000c9a:	4595                	li	a1,5
    80000c9c:	8526                	mv	a0,s1
    80000c9e:	00000097          	auipc	ra,0x0
    80000ca2:	1b4080e7          	jalr	436(ra) # 80000e52 <memset>
  return (void*)r;
}
    80000ca6:	8526                	mv	a0,s1
    80000ca8:	60e2                	ld	ra,24(sp)
    80000caa:	6442                	ld	s0,16(sp)
    80000cac:	64a2                	ld	s1,8(sp)
    80000cae:	6902                	ld	s2,0(sp)
    80000cb0:	6105                	addi	sp,sp,32
    80000cb2:	8082                	ret
  release(&kmem.lock);
    80000cb4:	00010517          	auipc	a0,0x10
    80000cb8:	ebc50513          	addi	a0,a0,-324 # 80010b70 <kmem>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	14e080e7          	jalr	334(ra) # 80000e0a <release>
  if(r)
    80000cc4:	b7cd                	j	80000ca6 <kalloc+0x52>

0000000080000cc6 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000cc6:	1141                	addi	sp,sp,-16
    80000cc8:	e422                	sd	s0,8(sp)
    80000cca:	0800                	addi	s0,sp,16
  lk->name = name;
    80000ccc:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000cce:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000cd2:	00053823          	sd	zero,16(a0)
}
    80000cd6:	6422                	ld	s0,8(sp)
    80000cd8:	0141                	addi	sp,sp,16
    80000cda:	8082                	ret

0000000080000cdc <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000cdc:	411c                	lw	a5,0(a0)
    80000cde:	e399                	bnez	a5,80000ce4 <holding+0x8>
    80000ce0:	4501                	li	a0,0
  return r;
}
    80000ce2:	8082                	ret
{
    80000ce4:	1101                	addi	sp,sp,-32
    80000ce6:	ec06                	sd	ra,24(sp)
    80000ce8:	e822                	sd	s0,16(sp)
    80000cea:	e426                	sd	s1,8(sp)
    80000cec:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cee:	6904                	ld	s1,16(a0)
    80000cf0:	00001097          	auipc	ra,0x1
    80000cf4:	e74080e7          	jalr	-396(ra) # 80001b64 <mycpu>
    80000cf8:	40a48533          	sub	a0,s1,a0
    80000cfc:	00153513          	seqz	a0,a0
}
    80000d00:	60e2                	ld	ra,24(sp)
    80000d02:	6442                	ld	s0,16(sp)
    80000d04:	64a2                	ld	s1,8(sp)
    80000d06:	6105                	addi	sp,sp,32
    80000d08:	8082                	ret

0000000080000d0a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d0a:	1101                	addi	sp,sp,-32
    80000d0c:	ec06                	sd	ra,24(sp)
    80000d0e:	e822                	sd	s0,16(sp)
    80000d10:	e426                	sd	s1,8(sp)
    80000d12:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d14:	100024f3          	csrr	s1,sstatus
    80000d18:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d1c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d1e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d22:	00001097          	auipc	ra,0x1
    80000d26:	e42080e7          	jalr	-446(ra) # 80001b64 <mycpu>
    80000d2a:	5d3c                	lw	a5,120(a0)
    80000d2c:	cf89                	beqz	a5,80000d46 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d2e:	00001097          	auipc	ra,0x1
    80000d32:	e36080e7          	jalr	-458(ra) # 80001b64 <mycpu>
    80000d36:	5d3c                	lw	a5,120(a0)
    80000d38:	2785                	addiw	a5,a5,1
    80000d3a:	dd3c                	sw	a5,120(a0)
}
    80000d3c:	60e2                	ld	ra,24(sp)
    80000d3e:	6442                	ld	s0,16(sp)
    80000d40:	64a2                	ld	s1,8(sp)
    80000d42:	6105                	addi	sp,sp,32
    80000d44:	8082                	ret
    mycpu()->intena = old;
    80000d46:	00001097          	auipc	ra,0x1
    80000d4a:	e1e080e7          	jalr	-482(ra) # 80001b64 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d4e:	8085                	srli	s1,s1,0x1
    80000d50:	8885                	andi	s1,s1,1
    80000d52:	dd64                	sw	s1,124(a0)
    80000d54:	bfe9                	j	80000d2e <push_off+0x24>

0000000080000d56 <acquire>:
{
    80000d56:	1101                	addi	sp,sp,-32
    80000d58:	ec06                	sd	ra,24(sp)
    80000d5a:	e822                	sd	s0,16(sp)
    80000d5c:	e426                	sd	s1,8(sp)
    80000d5e:	1000                	addi	s0,sp,32
    80000d60:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d62:	00000097          	auipc	ra,0x0
    80000d66:	fa8080e7          	jalr	-88(ra) # 80000d0a <push_off>
  if(holding(lk))
    80000d6a:	8526                	mv	a0,s1
    80000d6c:	00000097          	auipc	ra,0x0
    80000d70:	f70080e7          	jalr	-144(ra) # 80000cdc <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d74:	4705                	li	a4,1
  if(holding(lk))
    80000d76:	e115                	bnez	a0,80000d9a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d78:	87ba                	mv	a5,a4
    80000d7a:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d7e:	2781                	sext.w	a5,a5
    80000d80:	ffe5                	bnez	a5,80000d78 <acquire+0x22>
  __sync_synchronize();
    80000d82:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d86:	00001097          	auipc	ra,0x1
    80000d8a:	dde080e7          	jalr	-546(ra) # 80001b64 <mycpu>
    80000d8e:	e888                	sd	a0,16(s1)
}
    80000d90:	60e2                	ld	ra,24(sp)
    80000d92:	6442                	ld	s0,16(sp)
    80000d94:	64a2                	ld	s1,8(sp)
    80000d96:	6105                	addi	sp,sp,32
    80000d98:	8082                	ret
    panic("acquire");
    80000d9a:	00007517          	auipc	a0,0x7
    80000d9e:	32650513          	addi	a0,a0,806 # 800080c0 <digits+0x80>
    80000da2:	fffff097          	auipc	ra,0xfffff
    80000da6:	79c080e7          	jalr	1948(ra) # 8000053e <panic>

0000000080000daa <pop_off>:

void
pop_off(void)
{
    80000daa:	1141                	addi	sp,sp,-16
    80000dac:	e406                	sd	ra,8(sp)
    80000dae:	e022                	sd	s0,0(sp)
    80000db0:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000db2:	00001097          	auipc	ra,0x1
    80000db6:	db2080e7          	jalr	-590(ra) # 80001b64 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000dbe:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000dc0:	e78d                	bnez	a5,80000dea <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000dc2:	5d3c                	lw	a5,120(a0)
    80000dc4:	02f05b63          	blez	a5,80000dfa <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000dc8:	37fd                	addiw	a5,a5,-1
    80000dca:	0007871b          	sext.w	a4,a5
    80000dce:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000dd0:	eb09                	bnez	a4,80000de2 <pop_off+0x38>
    80000dd2:	5d7c                	lw	a5,124(a0)
    80000dd4:	c799                	beqz	a5,80000de2 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dd6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000dda:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000dde:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000de2:	60a2                	ld	ra,8(sp)
    80000de4:	6402                	ld	s0,0(sp)
    80000de6:	0141                	addi	sp,sp,16
    80000de8:	8082                	ret
    panic("pop_off - interruptible");
    80000dea:	00007517          	auipc	a0,0x7
    80000dee:	2de50513          	addi	a0,a0,734 # 800080c8 <digits+0x88>
    80000df2:	fffff097          	auipc	ra,0xfffff
    80000df6:	74c080e7          	jalr	1868(ra) # 8000053e <panic>
    panic("pop_off");
    80000dfa:	00007517          	auipc	a0,0x7
    80000dfe:	2e650513          	addi	a0,a0,742 # 800080e0 <digits+0xa0>
    80000e02:	fffff097          	auipc	ra,0xfffff
    80000e06:	73c080e7          	jalr	1852(ra) # 8000053e <panic>

0000000080000e0a <release>:
{
    80000e0a:	1101                	addi	sp,sp,-32
    80000e0c:	ec06                	sd	ra,24(sp)
    80000e0e:	e822                	sd	s0,16(sp)
    80000e10:	e426                	sd	s1,8(sp)
    80000e12:	1000                	addi	s0,sp,32
    80000e14:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e16:	00000097          	auipc	ra,0x0
    80000e1a:	ec6080e7          	jalr	-314(ra) # 80000cdc <holding>
    80000e1e:	c115                	beqz	a0,80000e42 <release+0x38>
  lk->cpu = 0;
    80000e20:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e24:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e28:	0f50000f          	fence	iorw,ow
    80000e2c:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e30:	00000097          	auipc	ra,0x0
    80000e34:	f7a080e7          	jalr	-134(ra) # 80000daa <pop_off>
}
    80000e38:	60e2                	ld	ra,24(sp)
    80000e3a:	6442                	ld	s0,16(sp)
    80000e3c:	64a2                	ld	s1,8(sp)
    80000e3e:	6105                	addi	sp,sp,32
    80000e40:	8082                	ret
    panic("release");
    80000e42:	00007517          	auipc	a0,0x7
    80000e46:	2a650513          	addi	a0,a0,678 # 800080e8 <digits+0xa8>
    80000e4a:	fffff097          	auipc	ra,0xfffff
    80000e4e:	6f4080e7          	jalr	1780(ra) # 8000053e <panic>

0000000080000e52 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e52:	1141                	addi	sp,sp,-16
    80000e54:	e422                	sd	s0,8(sp)
    80000e56:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e58:	ca19                	beqz	a2,80000e6e <memset+0x1c>
    80000e5a:	87aa                	mv	a5,a0
    80000e5c:	1602                	slli	a2,a2,0x20
    80000e5e:	9201                	srli	a2,a2,0x20
    80000e60:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e64:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e68:	0785                	addi	a5,a5,1
    80000e6a:	fee79de3          	bne	a5,a4,80000e64 <memset+0x12>
  }
  return dst;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret

0000000080000e74 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e74:	1141                	addi	sp,sp,-16
    80000e76:	e422                	sd	s0,8(sp)
    80000e78:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e7a:	ca05                	beqz	a2,80000eaa <memcmp+0x36>
    80000e7c:	fff6069b          	addiw	a3,a2,-1
    80000e80:	1682                	slli	a3,a3,0x20
    80000e82:	9281                	srli	a3,a3,0x20
    80000e84:	0685                	addi	a3,a3,1
    80000e86:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e88:	00054783          	lbu	a5,0(a0)
    80000e8c:	0005c703          	lbu	a4,0(a1)
    80000e90:	00e79863          	bne	a5,a4,80000ea0 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e94:	0505                	addi	a0,a0,1
    80000e96:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e98:	fed518e3          	bne	a0,a3,80000e88 <memcmp+0x14>
  }

  return 0;
    80000e9c:	4501                	li	a0,0
    80000e9e:	a019                	j	80000ea4 <memcmp+0x30>
      return *s1 - *s2;
    80000ea0:	40e7853b          	subw	a0,a5,a4
}
    80000ea4:	6422                	ld	s0,8(sp)
    80000ea6:	0141                	addi	sp,sp,16
    80000ea8:	8082                	ret
  return 0;
    80000eaa:	4501                	li	a0,0
    80000eac:	bfe5                	j	80000ea4 <memcmp+0x30>

0000000080000eae <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000eae:	1141                	addi	sp,sp,-16
    80000eb0:	e422                	sd	s0,8(sp)
    80000eb2:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000eb4:	c205                	beqz	a2,80000ed4 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000eb6:	02a5e263          	bltu	a1,a0,80000eda <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000eba:	1602                	slli	a2,a2,0x20
    80000ebc:	9201                	srli	a2,a2,0x20
    80000ebe:	00c587b3          	add	a5,a1,a2
{
    80000ec2:	872a                	mv	a4,a0
      *d++ = *s++;
    80000ec4:	0585                	addi	a1,a1,1
    80000ec6:	0705                	addi	a4,a4,1
    80000ec8:	fff5c683          	lbu	a3,-1(a1)
    80000ecc:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000ed0:	fef59ae3          	bne	a1,a5,80000ec4 <memmove+0x16>

  return dst;
}
    80000ed4:	6422                	ld	s0,8(sp)
    80000ed6:	0141                	addi	sp,sp,16
    80000ed8:	8082                	ret
  if(s < d && s + n > d){
    80000eda:	02061693          	slli	a3,a2,0x20
    80000ede:	9281                	srli	a3,a3,0x20
    80000ee0:	00d58733          	add	a4,a1,a3
    80000ee4:	fce57be3          	bgeu	a0,a4,80000eba <memmove+0xc>
    d += n;
    80000ee8:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000eea:	fff6079b          	addiw	a5,a2,-1
    80000eee:	1782                	slli	a5,a5,0x20
    80000ef0:	9381                	srli	a5,a5,0x20
    80000ef2:	fff7c793          	not	a5,a5
    80000ef6:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000ef8:	177d                	addi	a4,a4,-1
    80000efa:	16fd                	addi	a3,a3,-1
    80000efc:	00074603          	lbu	a2,0(a4)
    80000f00:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f04:	fee79ae3          	bne	a5,a4,80000ef8 <memmove+0x4a>
    80000f08:	b7f1                	j	80000ed4 <memmove+0x26>

0000000080000f0a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f0a:	1141                	addi	sp,sp,-16
    80000f0c:	e406                	sd	ra,8(sp)
    80000f0e:	e022                	sd	s0,0(sp)
    80000f10:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	f9c080e7          	jalr	-100(ra) # 80000eae <memmove>
}
    80000f1a:	60a2                	ld	ra,8(sp)
    80000f1c:	6402                	ld	s0,0(sp)
    80000f1e:	0141                	addi	sp,sp,16
    80000f20:	8082                	ret

0000000080000f22 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f22:	1141                	addi	sp,sp,-16
    80000f24:	e422                	sd	s0,8(sp)
    80000f26:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f28:	ce11                	beqz	a2,80000f44 <strncmp+0x22>
    80000f2a:	00054783          	lbu	a5,0(a0)
    80000f2e:	cf89                	beqz	a5,80000f48 <strncmp+0x26>
    80000f30:	0005c703          	lbu	a4,0(a1)
    80000f34:	00f71a63          	bne	a4,a5,80000f48 <strncmp+0x26>
    n--, p++, q++;
    80000f38:	367d                	addiw	a2,a2,-1
    80000f3a:	0505                	addi	a0,a0,1
    80000f3c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f3e:	f675                	bnez	a2,80000f2a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f40:	4501                	li	a0,0
    80000f42:	a809                	j	80000f54 <strncmp+0x32>
    80000f44:	4501                	li	a0,0
    80000f46:	a039                	j	80000f54 <strncmp+0x32>
  if(n == 0)
    80000f48:	ca09                	beqz	a2,80000f5a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f4a:	00054503          	lbu	a0,0(a0)
    80000f4e:	0005c783          	lbu	a5,0(a1)
    80000f52:	9d1d                	subw	a0,a0,a5
}
    80000f54:	6422                	ld	s0,8(sp)
    80000f56:	0141                	addi	sp,sp,16
    80000f58:	8082                	ret
    return 0;
    80000f5a:	4501                	li	a0,0
    80000f5c:	bfe5                	j	80000f54 <strncmp+0x32>

0000000080000f5e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f5e:	1141                	addi	sp,sp,-16
    80000f60:	e422                	sd	s0,8(sp)
    80000f62:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f64:	872a                	mv	a4,a0
    80000f66:	8832                	mv	a6,a2
    80000f68:	367d                	addiw	a2,a2,-1
    80000f6a:	01005963          	blez	a6,80000f7c <strncpy+0x1e>
    80000f6e:	0705                	addi	a4,a4,1
    80000f70:	0005c783          	lbu	a5,0(a1)
    80000f74:	fef70fa3          	sb	a5,-1(a4)
    80000f78:	0585                	addi	a1,a1,1
    80000f7a:	f7f5                	bnez	a5,80000f66 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f7c:	86ba                	mv	a3,a4
    80000f7e:	00c05c63          	blez	a2,80000f96 <strncpy+0x38>
    *s++ = 0;
    80000f82:	0685                	addi	a3,a3,1
    80000f84:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f88:	fff6c793          	not	a5,a3
    80000f8c:	9fb9                	addw	a5,a5,a4
    80000f8e:	010787bb          	addw	a5,a5,a6
    80000f92:	fef048e3          	bgtz	a5,80000f82 <strncpy+0x24>
  return os;
}
    80000f96:	6422                	ld	s0,8(sp)
    80000f98:	0141                	addi	sp,sp,16
    80000f9a:	8082                	ret

0000000080000f9c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f9c:	1141                	addi	sp,sp,-16
    80000f9e:	e422                	sd	s0,8(sp)
    80000fa0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000fa2:	02c05363          	blez	a2,80000fc8 <safestrcpy+0x2c>
    80000fa6:	fff6069b          	addiw	a3,a2,-1
    80000faa:	1682                	slli	a3,a3,0x20
    80000fac:	9281                	srli	a3,a3,0x20
    80000fae:	96ae                	add	a3,a3,a1
    80000fb0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000fb2:	00d58963          	beq	a1,a3,80000fc4 <safestrcpy+0x28>
    80000fb6:	0585                	addi	a1,a1,1
    80000fb8:	0785                	addi	a5,a5,1
    80000fba:	fff5c703          	lbu	a4,-1(a1)
    80000fbe:	fee78fa3          	sb	a4,-1(a5)
    80000fc2:	fb65                	bnez	a4,80000fb2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000fc4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fc8:	6422                	ld	s0,8(sp)
    80000fca:	0141                	addi	sp,sp,16
    80000fcc:	8082                	ret

0000000080000fce <strlen>:

int
strlen(const char *s)
{
    80000fce:	1141                	addi	sp,sp,-16
    80000fd0:	e422                	sd	s0,8(sp)
    80000fd2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000fd4:	00054783          	lbu	a5,0(a0)
    80000fd8:	cf91                	beqz	a5,80000ff4 <strlen+0x26>
    80000fda:	0505                	addi	a0,a0,1
    80000fdc:	87aa                	mv	a5,a0
    80000fde:	4685                	li	a3,1
    80000fe0:	9e89                	subw	a3,a3,a0
    80000fe2:	00f6853b          	addw	a0,a3,a5
    80000fe6:	0785                	addi	a5,a5,1
    80000fe8:	fff7c703          	lbu	a4,-1(a5)
    80000fec:	fb7d                	bnez	a4,80000fe2 <strlen+0x14>
    ;
  return n;
}
    80000fee:	6422                	ld	s0,8(sp)
    80000ff0:	0141                	addi	sp,sp,16
    80000ff2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ff4:	4501                	li	a0,0
    80000ff6:	bfe5                	j	80000fee <strlen+0x20>

0000000080000ff8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ff8:	1141                	addi	sp,sp,-16
    80000ffa:	e406                	sd	ra,8(sp)
    80000ffc:	e022                	sd	s0,0(sp)
    80000ffe:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001000:	00001097          	auipc	ra,0x1
    80001004:	b54080e7          	jalr	-1196(ra) # 80001b54 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001008:	00008717          	auipc	a4,0x8
    8000100c:	90070713          	addi	a4,a4,-1792 # 80008908 <started>
  if(cpuid() == 0){
    80001010:	c139                	beqz	a0,80001056 <main+0x5e>
    while(started == 0)
    80001012:	431c                	lw	a5,0(a4)
    80001014:	2781                	sext.w	a5,a5
    80001016:	dff5                	beqz	a5,80001012 <main+0x1a>
      ;
    __sync_synchronize();
    80001018:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000101c:	00001097          	auipc	ra,0x1
    80001020:	b38080e7          	jalr	-1224(ra) # 80001b54 <cpuid>
    80001024:	85aa                	mv	a1,a0
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	0e250513          	addi	a0,a0,226 # 80008108 <digits+0xc8>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	55a080e7          	jalr	1370(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80001036:	00000097          	auipc	ra,0x0
    8000103a:	0d8080e7          	jalr	216(ra) # 8000110e <kvminithart>
    trapinithart();   // install kernel trap vector
    8000103e:	00002097          	auipc	ra,0x2
    80001042:	9a8080e7          	jalr	-1624(ra) # 800029e6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001046:	00005097          	auipc	ra,0x5
    8000104a:	0ca080e7          	jalr	202(ra) # 80006110 <plicinithart>
  }

  scheduler();        
    8000104e:	00001097          	auipc	ra,0x1
    80001052:	03c080e7          	jalr	60(ra) # 8000208a <scheduler>
    consoleinit();
    80001056:	fffff097          	auipc	ra,0xfffff
    8000105a:	3fa080e7          	jalr	1018(ra) # 80000450 <consoleinit>
    printfinit();
    8000105e:	fffff097          	auipc	ra,0xfffff
    80001062:	70a080e7          	jalr	1802(ra) # 80000768 <printfinit>
    printf("\n");
    80001066:	00007517          	auipc	a0,0x7
    8000106a:	0b250513          	addi	a0,a0,178 # 80008118 <digits+0xd8>
    8000106e:	fffff097          	auipc	ra,0xfffff
    80001072:	51a080e7          	jalr	1306(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80001076:	00007517          	auipc	a0,0x7
    8000107a:	07a50513          	addi	a0,a0,122 # 800080f0 <digits+0xb0>
    8000107e:	fffff097          	auipc	ra,0xfffff
    80001082:	50a080e7          	jalr	1290(ra) # 80000588 <printf>
    printf("\n");
    80001086:	00007517          	auipc	a0,0x7
    8000108a:	09250513          	addi	a0,a0,146 # 80008118 <digits+0xd8>
    8000108e:	fffff097          	auipc	ra,0xfffff
    80001092:	4fa080e7          	jalr	1274(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80001096:	00000097          	auipc	ra,0x0
    8000109a:	b7a080e7          	jalr	-1158(ra) # 80000c10 <kinit>
    kvminit();       // create kernel page table
    8000109e:	00000097          	auipc	ra,0x0
    800010a2:	326080e7          	jalr	806(ra) # 800013c4 <kvminit>
    kvminithart();   // turn on paging
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	068080e7          	jalr	104(ra) # 8000110e <kvminithart>
    procinit();      // process table
    800010ae:	00001097          	auipc	ra,0x1
    800010b2:	9f2080e7          	jalr	-1550(ra) # 80001aa0 <procinit>
    trapinit();      // trap vectors
    800010b6:	00002097          	auipc	ra,0x2
    800010ba:	908080e7          	jalr	-1784(ra) # 800029be <trapinit>
    trapinithart();  // install kernel trap vector
    800010be:	00002097          	auipc	ra,0x2
    800010c2:	928080e7          	jalr	-1752(ra) # 800029e6 <trapinithart>
    plicinit();      // set up interrupt controller
    800010c6:	00005097          	auipc	ra,0x5
    800010ca:	034080e7          	jalr	52(ra) # 800060fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010ce:	00005097          	auipc	ra,0x5
    800010d2:	042080e7          	jalr	66(ra) # 80006110 <plicinithart>
    binit();         // buffer cache
    800010d6:	00002097          	auipc	ra,0x2
    800010da:	1e8080e7          	jalr	488(ra) # 800032be <binit>
    iinit();         // inode table
    800010de:	00003097          	auipc	ra,0x3
    800010e2:	88c080e7          	jalr	-1908(ra) # 8000396a <iinit>
    fileinit();      // file table
    800010e6:	00004097          	auipc	ra,0x4
    800010ea:	82a080e7          	jalr	-2006(ra) # 80004910 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010ee:	00005097          	auipc	ra,0x5
    800010f2:	12a080e7          	jalr	298(ra) # 80006218 <virtio_disk_init>
    userinit();      // first user process
    800010f6:	00001097          	auipc	ra,0x1
    800010fa:	d76080e7          	jalr	-650(ra) # 80001e6c <userinit>
    __sync_synchronize();
    800010fe:	0ff0000f          	fence
    started = 1;
    80001102:	4785                	li	a5,1
    80001104:	00008717          	auipc	a4,0x8
    80001108:	80f72223          	sw	a5,-2044(a4) # 80008908 <started>
    8000110c:	b789                	j	8000104e <main+0x56>

000000008000110e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000110e:	1141                	addi	sp,sp,-16
    80001110:	e422                	sd	s0,8(sp)
    80001112:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001114:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001118:	00007797          	auipc	a5,0x7
    8000111c:	7f87b783          	ld	a5,2040(a5) # 80008910 <kernel_pagetable>
    80001120:	83b1                	srli	a5,a5,0xc
    80001122:	577d                	li	a4,-1
    80001124:	177e                	slli	a4,a4,0x3f
    80001126:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001128:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000112c:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001130:	6422                	ld	s0,8(sp)
    80001132:	0141                	addi	sp,sp,16
    80001134:	8082                	ret

0000000080001136 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001136:	7139                	addi	sp,sp,-64
    80001138:	fc06                	sd	ra,56(sp)
    8000113a:	f822                	sd	s0,48(sp)
    8000113c:	f426                	sd	s1,40(sp)
    8000113e:	f04a                	sd	s2,32(sp)
    80001140:	ec4e                	sd	s3,24(sp)
    80001142:	e852                	sd	s4,16(sp)
    80001144:	e456                	sd	s5,8(sp)
    80001146:	e05a                	sd	s6,0(sp)
    80001148:	0080                	addi	s0,sp,64
    8000114a:	84aa                	mv	s1,a0
    8000114c:	89ae                	mv	s3,a1
    8000114e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001150:	57fd                	li	a5,-1
    80001152:	83e9                	srli	a5,a5,0x1a
    80001154:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001156:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001158:	04b7f263          	bgeu	a5,a1,8000119c <walk+0x66>
    panic("walk");
    8000115c:	00007517          	auipc	a0,0x7
    80001160:	fc450513          	addi	a0,a0,-60 # 80008120 <digits+0xe0>
    80001164:	fffff097          	auipc	ra,0xfffff
    80001168:	3da080e7          	jalr	986(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000116c:	060a8663          	beqz	s5,800011d8 <walk+0xa2>
    80001170:	00000097          	auipc	ra,0x0
    80001174:	ae4080e7          	jalr	-1308(ra) # 80000c54 <kalloc>
    80001178:	84aa                	mv	s1,a0
    8000117a:	c529                	beqz	a0,800011c4 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000117c:	6605                	lui	a2,0x1
    8000117e:	4581                	li	a1,0
    80001180:	00000097          	auipc	ra,0x0
    80001184:	cd2080e7          	jalr	-814(ra) # 80000e52 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001188:	00c4d793          	srli	a5,s1,0xc
    8000118c:	07aa                	slli	a5,a5,0xa
    8000118e:	0017e793          	ori	a5,a5,1
    80001192:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001196:	3a5d                	addiw	s4,s4,-9
    80001198:	036a0063          	beq	s4,s6,800011b8 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000119c:	0149d933          	srl	s2,s3,s4
    800011a0:	1ff97913          	andi	s2,s2,511
    800011a4:	090e                	slli	s2,s2,0x3
    800011a6:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011a8:	00093483          	ld	s1,0(s2)
    800011ac:	0014f793          	andi	a5,s1,1
    800011b0:	dfd5                	beqz	a5,8000116c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011b2:	80a9                	srli	s1,s1,0xa
    800011b4:	04b2                	slli	s1,s1,0xc
    800011b6:	b7c5                	j	80001196 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011b8:	00c9d513          	srli	a0,s3,0xc
    800011bc:	1ff57513          	andi	a0,a0,511
    800011c0:	050e                	slli	a0,a0,0x3
    800011c2:	9526                	add	a0,a0,s1
}
    800011c4:	70e2                	ld	ra,56(sp)
    800011c6:	7442                	ld	s0,48(sp)
    800011c8:	74a2                	ld	s1,40(sp)
    800011ca:	7902                	ld	s2,32(sp)
    800011cc:	69e2                	ld	s3,24(sp)
    800011ce:	6a42                	ld	s4,16(sp)
    800011d0:	6aa2                	ld	s5,8(sp)
    800011d2:	6b02                	ld	s6,0(sp)
    800011d4:	6121                	addi	sp,sp,64
    800011d6:	8082                	ret
        return 0;
    800011d8:	4501                	li	a0,0
    800011da:	b7ed                	j	800011c4 <walk+0x8e>

00000000800011dc <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800011dc:	57fd                	li	a5,-1
    800011de:	83e9                	srli	a5,a5,0x1a
    800011e0:	00b7f463          	bgeu	a5,a1,800011e8 <walkaddr+0xc>
    return 0;
    800011e4:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011e6:	8082                	ret
{
    800011e8:	1141                	addi	sp,sp,-16
    800011ea:	e406                	sd	ra,8(sp)
    800011ec:	e022                	sd	s0,0(sp)
    800011ee:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011f0:	4601                	li	a2,0
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	f44080e7          	jalr	-188(ra) # 80001136 <walk>
  if(pte == 0)
    800011fa:	c105                	beqz	a0,8000121a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011fc:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011fe:	0117f693          	andi	a3,a5,17
    80001202:	4745                	li	a4,17
    return 0;
    80001204:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001206:	00e68663          	beq	a3,a4,80001212 <walkaddr+0x36>
}
    8000120a:	60a2                	ld	ra,8(sp)
    8000120c:	6402                	ld	s0,0(sp)
    8000120e:	0141                	addi	sp,sp,16
    80001210:	8082                	ret
  pa = PTE2PA(*pte);
    80001212:	00a7d513          	srli	a0,a5,0xa
    80001216:	0532                	slli	a0,a0,0xc
  return pa;
    80001218:	bfcd                	j	8000120a <walkaddr+0x2e>
    return 0;
    8000121a:	4501                	li	a0,0
    8000121c:	b7fd                	j	8000120a <walkaddr+0x2e>

000000008000121e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000121e:	715d                	addi	sp,sp,-80
    80001220:	e486                	sd	ra,72(sp)
    80001222:	e0a2                	sd	s0,64(sp)
    80001224:	fc26                	sd	s1,56(sp)
    80001226:	f84a                	sd	s2,48(sp)
    80001228:	f44e                	sd	s3,40(sp)
    8000122a:	f052                	sd	s4,32(sp)
    8000122c:	ec56                	sd	s5,24(sp)
    8000122e:	e85a                	sd	s6,16(sp)
    80001230:	e45e                	sd	s7,8(sp)
    80001232:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001234:	c639                	beqz	a2,80001282 <mappages+0x64>
    80001236:	8aaa                	mv	s5,a0
    80001238:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000123a:	77fd                	lui	a5,0xfffff
    8000123c:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001240:	15fd                	addi	a1,a1,-1
    80001242:	00c589b3          	add	s3,a1,a2
    80001246:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    8000124a:	8952                	mv	s2,s4
    8000124c:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001250:	6b85                	lui	s7,0x1
    80001252:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001256:	4605                	li	a2,1
    80001258:	85ca                	mv	a1,s2
    8000125a:	8556                	mv	a0,s5
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	eda080e7          	jalr	-294(ra) # 80001136 <walk>
    80001264:	cd1d                	beqz	a0,800012a2 <mappages+0x84>
    if(*pte & PTE_V)
    80001266:	611c                	ld	a5,0(a0)
    80001268:	8b85                	andi	a5,a5,1
    8000126a:	e785                	bnez	a5,80001292 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000126c:	80b1                	srli	s1,s1,0xc
    8000126e:	04aa                	slli	s1,s1,0xa
    80001270:	0164e4b3          	or	s1,s1,s6
    80001274:	0014e493          	ori	s1,s1,1
    80001278:	e104                	sd	s1,0(a0)
    if(a == last)
    8000127a:	05390063          	beq	s2,s3,800012ba <mappages+0x9c>
    a += PGSIZE;
    8000127e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001280:	bfc9                	j	80001252 <mappages+0x34>
    panic("mappages: size");
    80001282:	00007517          	auipc	a0,0x7
    80001286:	ea650513          	addi	a0,a0,-346 # 80008128 <digits+0xe8>
    8000128a:	fffff097          	auipc	ra,0xfffff
    8000128e:	2b4080e7          	jalr	692(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001292:	00007517          	auipc	a0,0x7
    80001296:	ea650513          	addi	a0,a0,-346 # 80008138 <digits+0xf8>
    8000129a:	fffff097          	auipc	ra,0xfffff
    8000129e:	2a4080e7          	jalr	676(ra) # 8000053e <panic>
      return -1;
    800012a2:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012a4:	60a6                	ld	ra,72(sp)
    800012a6:	6406                	ld	s0,64(sp)
    800012a8:	74e2                	ld	s1,56(sp)
    800012aa:	7942                	ld	s2,48(sp)
    800012ac:	79a2                	ld	s3,40(sp)
    800012ae:	7a02                	ld	s4,32(sp)
    800012b0:	6ae2                	ld	s5,24(sp)
    800012b2:	6b42                	ld	s6,16(sp)
    800012b4:	6ba2                	ld	s7,8(sp)
    800012b6:	6161                	addi	sp,sp,80
    800012b8:	8082                	ret
  return 0;
    800012ba:	4501                	li	a0,0
    800012bc:	b7e5                	j	800012a4 <mappages+0x86>

00000000800012be <kvmmap>:
{
    800012be:	1141                	addi	sp,sp,-16
    800012c0:	e406                	sd	ra,8(sp)
    800012c2:	e022                	sd	s0,0(sp)
    800012c4:	0800                	addi	s0,sp,16
    800012c6:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800012c8:	86b2                	mv	a3,a2
    800012ca:	863e                	mv	a2,a5
    800012cc:	00000097          	auipc	ra,0x0
    800012d0:	f52080e7          	jalr	-174(ra) # 8000121e <mappages>
    800012d4:	e509                	bnez	a0,800012de <kvmmap+0x20>
}
    800012d6:	60a2                	ld	ra,8(sp)
    800012d8:	6402                	ld	s0,0(sp)
    800012da:	0141                	addi	sp,sp,16
    800012dc:	8082                	ret
    panic("kvmmap");
    800012de:	00007517          	auipc	a0,0x7
    800012e2:	e6a50513          	addi	a0,a0,-406 # 80008148 <digits+0x108>
    800012e6:	fffff097          	auipc	ra,0xfffff
    800012ea:	258080e7          	jalr	600(ra) # 8000053e <panic>

00000000800012ee <kvmmake>:
{
    800012ee:	1101                	addi	sp,sp,-32
    800012f0:	ec06                	sd	ra,24(sp)
    800012f2:	e822                	sd	s0,16(sp)
    800012f4:	e426                	sd	s1,8(sp)
    800012f6:	e04a                	sd	s2,0(sp)
    800012f8:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	95a080e7          	jalr	-1702(ra) # 80000c54 <kalloc>
    80001302:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001304:	6605                	lui	a2,0x1
    80001306:	4581                	li	a1,0
    80001308:	00000097          	auipc	ra,0x0
    8000130c:	b4a080e7          	jalr	-1206(ra) # 80000e52 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001310:	4719                	li	a4,6
    80001312:	6685                	lui	a3,0x1
    80001314:	10000637          	lui	a2,0x10000
    80001318:	100005b7          	lui	a1,0x10000
    8000131c:	8526                	mv	a0,s1
    8000131e:	00000097          	auipc	ra,0x0
    80001322:	fa0080e7          	jalr	-96(ra) # 800012be <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001326:	4719                	li	a4,6
    80001328:	6685                	lui	a3,0x1
    8000132a:	10001637          	lui	a2,0x10001
    8000132e:	100015b7          	lui	a1,0x10001
    80001332:	8526                	mv	a0,s1
    80001334:	00000097          	auipc	ra,0x0
    80001338:	f8a080e7          	jalr	-118(ra) # 800012be <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000133c:	4719                	li	a4,6
    8000133e:	004006b7          	lui	a3,0x400
    80001342:	0c000637          	lui	a2,0xc000
    80001346:	0c0005b7          	lui	a1,0xc000
    8000134a:	8526                	mv	a0,s1
    8000134c:	00000097          	auipc	ra,0x0
    80001350:	f72080e7          	jalr	-142(ra) # 800012be <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001354:	00007917          	auipc	s2,0x7
    80001358:	cac90913          	addi	s2,s2,-852 # 80008000 <etext>
    8000135c:	4729                	li	a4,10
    8000135e:	80007697          	auipc	a3,0x80007
    80001362:	ca268693          	addi	a3,a3,-862 # 8000 <_entry-0x7fff8000>
    80001366:	4605                	li	a2,1
    80001368:	067e                	slli	a2,a2,0x1f
    8000136a:	85b2                	mv	a1,a2
    8000136c:	8526                	mv	a0,s1
    8000136e:	00000097          	auipc	ra,0x0
    80001372:	f50080e7          	jalr	-176(ra) # 800012be <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001376:	4719                	li	a4,6
    80001378:	46c5                	li	a3,17
    8000137a:	06ee                	slli	a3,a3,0x1b
    8000137c:	412686b3          	sub	a3,a3,s2
    80001380:	864a                	mv	a2,s2
    80001382:	85ca                	mv	a1,s2
    80001384:	8526                	mv	a0,s1
    80001386:	00000097          	auipc	ra,0x0
    8000138a:	f38080e7          	jalr	-200(ra) # 800012be <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000138e:	4729                	li	a4,10
    80001390:	6685                	lui	a3,0x1
    80001392:	00006617          	auipc	a2,0x6
    80001396:	c6e60613          	addi	a2,a2,-914 # 80007000 <_trampoline>
    8000139a:	040005b7          	lui	a1,0x4000
    8000139e:	15fd                	addi	a1,a1,-1
    800013a0:	05b2                	slli	a1,a1,0xc
    800013a2:	8526                	mv	a0,s1
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	f1a080e7          	jalr	-230(ra) # 800012be <kvmmap>
  proc_mapstacks(kpgtbl);
    800013ac:	8526                	mv	a0,s1
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	65c080e7          	jalr	1628(ra) # 80001a0a <proc_mapstacks>
}
    800013b6:	8526                	mv	a0,s1
    800013b8:	60e2                	ld	ra,24(sp)
    800013ba:	6442                	ld	s0,16(sp)
    800013bc:	64a2                	ld	s1,8(sp)
    800013be:	6902                	ld	s2,0(sp)
    800013c0:	6105                	addi	sp,sp,32
    800013c2:	8082                	ret

00000000800013c4 <kvminit>:
{
    800013c4:	1141                	addi	sp,sp,-16
    800013c6:	e406                	sd	ra,8(sp)
    800013c8:	e022                	sd	s0,0(sp)
    800013ca:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013cc:	00000097          	auipc	ra,0x0
    800013d0:	f22080e7          	jalr	-222(ra) # 800012ee <kvmmake>
    800013d4:	00007797          	auipc	a5,0x7
    800013d8:	52a7be23          	sd	a0,1340(a5) # 80008910 <kernel_pagetable>
}
    800013dc:	60a2                	ld	ra,8(sp)
    800013de:	6402                	ld	s0,0(sp)
    800013e0:	0141                	addi	sp,sp,16
    800013e2:	8082                	ret

00000000800013e4 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013e4:	715d                	addi	sp,sp,-80
    800013e6:	e486                	sd	ra,72(sp)
    800013e8:	e0a2                	sd	s0,64(sp)
    800013ea:	fc26                	sd	s1,56(sp)
    800013ec:	f84a                	sd	s2,48(sp)
    800013ee:	f44e                	sd	s3,40(sp)
    800013f0:	f052                	sd	s4,32(sp)
    800013f2:	ec56                	sd	s5,24(sp)
    800013f4:	e85a                	sd	s6,16(sp)
    800013f6:	e45e                	sd	s7,8(sp)
    800013f8:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013fa:	03459793          	slli	a5,a1,0x34
    800013fe:	e795                	bnez	a5,8000142a <uvmunmap+0x46>
    80001400:	8a2a                	mv	s4,a0
    80001402:	892e                	mv	s2,a1
    80001404:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001406:	0632                	slli	a2,a2,0xc
    80001408:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000140c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000140e:	6b05                	lui	s6,0x1
    80001410:	0735e263          	bltu	a1,s3,80001474 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001414:	60a6                	ld	ra,72(sp)
    80001416:	6406                	ld	s0,64(sp)
    80001418:	74e2                	ld	s1,56(sp)
    8000141a:	7942                	ld	s2,48(sp)
    8000141c:	79a2                	ld	s3,40(sp)
    8000141e:	7a02                	ld	s4,32(sp)
    80001420:	6ae2                	ld	s5,24(sp)
    80001422:	6b42                	ld	s6,16(sp)
    80001424:	6ba2                	ld	s7,8(sp)
    80001426:	6161                	addi	sp,sp,80
    80001428:	8082                	ret
    panic("uvmunmap: not aligned");
    8000142a:	00007517          	auipc	a0,0x7
    8000142e:	d2650513          	addi	a0,a0,-730 # 80008150 <digits+0x110>
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	10c080e7          	jalr	268(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    8000143a:	00007517          	auipc	a0,0x7
    8000143e:	d2e50513          	addi	a0,a0,-722 # 80008168 <digits+0x128>
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	0fc080e7          	jalr	252(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    8000144a:	00007517          	auipc	a0,0x7
    8000144e:	d2e50513          	addi	a0,a0,-722 # 80008178 <digits+0x138>
    80001452:	fffff097          	auipc	ra,0xfffff
    80001456:	0ec080e7          	jalr	236(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    8000145a:	00007517          	auipc	a0,0x7
    8000145e:	d3650513          	addi	a0,a0,-714 # 80008190 <digits+0x150>
    80001462:	fffff097          	auipc	ra,0xfffff
    80001466:	0dc080e7          	jalr	220(ra) # 8000053e <panic>
    *pte = 0;
    8000146a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000146e:	995a                	add	s2,s2,s6
    80001470:	fb3972e3          	bgeu	s2,s3,80001414 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001474:	4601                	li	a2,0
    80001476:	85ca                	mv	a1,s2
    80001478:	8552                	mv	a0,s4
    8000147a:	00000097          	auipc	ra,0x0
    8000147e:	cbc080e7          	jalr	-836(ra) # 80001136 <walk>
    80001482:	84aa                	mv	s1,a0
    80001484:	d95d                	beqz	a0,8000143a <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001486:	6108                	ld	a0,0(a0)
    80001488:	00157793          	andi	a5,a0,1
    8000148c:	dfdd                	beqz	a5,8000144a <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000148e:	3ff57793          	andi	a5,a0,1023
    80001492:	fd7784e3          	beq	a5,s7,8000145a <uvmunmap+0x76>
    if(do_free){
    80001496:	fc0a8ae3          	beqz	s5,8000146a <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000149a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000149c:	0532                	slli	a0,a0,0xc
    8000149e:	fffff097          	auipc	ra,0xfffff
    800014a2:	692080e7          	jalr	1682(ra) # 80000b30 <kfree>
    800014a6:	b7d1                	j	8000146a <uvmunmap+0x86>

00000000800014a8 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014a8:	1101                	addi	sp,sp,-32
    800014aa:	ec06                	sd	ra,24(sp)
    800014ac:	e822                	sd	s0,16(sp)
    800014ae:	e426                	sd	s1,8(sp)
    800014b0:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	7a2080e7          	jalr	1954(ra) # 80000c54 <kalloc>
    800014ba:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014bc:	c519                	beqz	a0,800014ca <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014be:	6605                	lui	a2,0x1
    800014c0:	4581                	li	a1,0
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	990080e7          	jalr	-1648(ra) # 80000e52 <memset>
  return pagetable;
}
    800014ca:	8526                	mv	a0,s1
    800014cc:	60e2                	ld	ra,24(sp)
    800014ce:	6442                	ld	s0,16(sp)
    800014d0:	64a2                	ld	s1,8(sp)
    800014d2:	6105                	addi	sp,sp,32
    800014d4:	8082                	ret

00000000800014d6 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800014d6:	7179                	addi	sp,sp,-48
    800014d8:	f406                	sd	ra,40(sp)
    800014da:	f022                	sd	s0,32(sp)
    800014dc:	ec26                	sd	s1,24(sp)
    800014de:	e84a                	sd	s2,16(sp)
    800014e0:	e44e                	sd	s3,8(sp)
    800014e2:	e052                	sd	s4,0(sp)
    800014e4:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014e6:	6785                	lui	a5,0x1
    800014e8:	04f67863          	bgeu	a2,a5,80001538 <uvmfirst+0x62>
    800014ec:	8a2a                	mv	s4,a0
    800014ee:	89ae                	mv	s3,a1
    800014f0:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014f2:	fffff097          	auipc	ra,0xfffff
    800014f6:	762080e7          	jalr	1890(ra) # 80000c54 <kalloc>
    800014fa:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014fc:	6605                	lui	a2,0x1
    800014fe:	4581                	li	a1,0
    80001500:	00000097          	auipc	ra,0x0
    80001504:	952080e7          	jalr	-1710(ra) # 80000e52 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001508:	4779                	li	a4,30
    8000150a:	86ca                	mv	a3,s2
    8000150c:	6605                	lui	a2,0x1
    8000150e:	4581                	li	a1,0
    80001510:	8552                	mv	a0,s4
    80001512:	00000097          	auipc	ra,0x0
    80001516:	d0c080e7          	jalr	-756(ra) # 8000121e <mappages>
  memmove(mem, src, sz);
    8000151a:	8626                	mv	a2,s1
    8000151c:	85ce                	mv	a1,s3
    8000151e:	854a                	mv	a0,s2
    80001520:	00000097          	auipc	ra,0x0
    80001524:	98e080e7          	jalr	-1650(ra) # 80000eae <memmove>
}
    80001528:	70a2                	ld	ra,40(sp)
    8000152a:	7402                	ld	s0,32(sp)
    8000152c:	64e2                	ld	s1,24(sp)
    8000152e:	6942                	ld	s2,16(sp)
    80001530:	69a2                	ld	s3,8(sp)
    80001532:	6a02                	ld	s4,0(sp)
    80001534:	6145                	addi	sp,sp,48
    80001536:	8082                	ret
    panic("uvmfirst: more than a page");
    80001538:	00007517          	auipc	a0,0x7
    8000153c:	c7050513          	addi	a0,a0,-912 # 800081a8 <digits+0x168>
    80001540:	fffff097          	auipc	ra,0xfffff
    80001544:	ffe080e7          	jalr	-2(ra) # 8000053e <panic>

0000000080001548 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001552:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001554:	00b67d63          	bgeu	a2,a1,8000156e <uvmdealloc+0x26>
    80001558:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000155a:	6785                	lui	a5,0x1
    8000155c:	17fd                	addi	a5,a5,-1
    8000155e:	00f60733          	add	a4,a2,a5
    80001562:	767d                	lui	a2,0xfffff
    80001564:	8f71                	and	a4,a4,a2
    80001566:	97ae                	add	a5,a5,a1
    80001568:	8ff1                	and	a5,a5,a2
    8000156a:	00f76863          	bltu	a4,a5,8000157a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000156e:	8526                	mv	a0,s1
    80001570:	60e2                	ld	ra,24(sp)
    80001572:	6442                	ld	s0,16(sp)
    80001574:	64a2                	ld	s1,8(sp)
    80001576:	6105                	addi	sp,sp,32
    80001578:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000157a:	8f99                	sub	a5,a5,a4
    8000157c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000157e:	4685                	li	a3,1
    80001580:	0007861b          	sext.w	a2,a5
    80001584:	85ba                	mv	a1,a4
    80001586:	00000097          	auipc	ra,0x0
    8000158a:	e5e080e7          	jalr	-418(ra) # 800013e4 <uvmunmap>
    8000158e:	b7c5                	j	8000156e <uvmdealloc+0x26>

0000000080001590 <uvmalloc>:
  if(newsz < oldsz)
    80001590:	0ab66563          	bltu	a2,a1,8000163a <uvmalloc+0xaa>
{
    80001594:	7139                	addi	sp,sp,-64
    80001596:	fc06                	sd	ra,56(sp)
    80001598:	f822                	sd	s0,48(sp)
    8000159a:	f426                	sd	s1,40(sp)
    8000159c:	f04a                	sd	s2,32(sp)
    8000159e:	ec4e                	sd	s3,24(sp)
    800015a0:	e852                	sd	s4,16(sp)
    800015a2:	e456                	sd	s5,8(sp)
    800015a4:	e05a                	sd	s6,0(sp)
    800015a6:	0080                	addi	s0,sp,64
    800015a8:	8aaa                	mv	s5,a0
    800015aa:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015ac:	6985                	lui	s3,0x1
    800015ae:	19fd                	addi	s3,s3,-1
    800015b0:	95ce                	add	a1,a1,s3
    800015b2:	79fd                	lui	s3,0xfffff
    800015b4:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015b8:	08c9f363          	bgeu	s3,a2,8000163e <uvmalloc+0xae>
    800015bc:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015be:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	692080e7          	jalr	1682(ra) # 80000c54 <kalloc>
    800015ca:	84aa                	mv	s1,a0
    if(mem == 0){
    800015cc:	c51d                	beqz	a0,800015fa <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800015ce:	6605                	lui	a2,0x1
    800015d0:	4581                	li	a1,0
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	880080e7          	jalr	-1920(ra) # 80000e52 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015da:	875a                	mv	a4,s6
    800015dc:	86a6                	mv	a3,s1
    800015de:	6605                	lui	a2,0x1
    800015e0:	85ca                	mv	a1,s2
    800015e2:	8556                	mv	a0,s5
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	c3a080e7          	jalr	-966(ra) # 8000121e <mappages>
    800015ec:	e90d                	bnez	a0,8000161e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015ee:	6785                	lui	a5,0x1
    800015f0:	993e                	add	s2,s2,a5
    800015f2:	fd4968e3          	bltu	s2,s4,800015c2 <uvmalloc+0x32>
  return newsz;
    800015f6:	8552                	mv	a0,s4
    800015f8:	a809                	j	8000160a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800015fa:	864e                	mv	a2,s3
    800015fc:	85ca                	mv	a1,s2
    800015fe:	8556                	mv	a0,s5
    80001600:	00000097          	auipc	ra,0x0
    80001604:	f48080e7          	jalr	-184(ra) # 80001548 <uvmdealloc>
      return 0;
    80001608:	4501                	li	a0,0
}
    8000160a:	70e2                	ld	ra,56(sp)
    8000160c:	7442                	ld	s0,48(sp)
    8000160e:	74a2                	ld	s1,40(sp)
    80001610:	7902                	ld	s2,32(sp)
    80001612:	69e2                	ld	s3,24(sp)
    80001614:	6a42                	ld	s4,16(sp)
    80001616:	6aa2                	ld	s5,8(sp)
    80001618:	6b02                	ld	s6,0(sp)
    8000161a:	6121                	addi	sp,sp,64
    8000161c:	8082                	ret
      kfree(mem);
    8000161e:	8526                	mv	a0,s1
    80001620:	fffff097          	auipc	ra,0xfffff
    80001624:	510080e7          	jalr	1296(ra) # 80000b30 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001628:	864e                	mv	a2,s3
    8000162a:	85ca                	mv	a1,s2
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	f1a080e7          	jalr	-230(ra) # 80001548 <uvmdealloc>
      return 0;
    80001636:	4501                	li	a0,0
    80001638:	bfc9                	j	8000160a <uvmalloc+0x7a>
    return oldsz;
    8000163a:	852e                	mv	a0,a1
}
    8000163c:	8082                	ret
  return newsz;
    8000163e:	8532                	mv	a0,a2
    80001640:	b7e9                	j	8000160a <uvmalloc+0x7a>

0000000080001642 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001642:	7179                	addi	sp,sp,-48
    80001644:	f406                	sd	ra,40(sp)
    80001646:	f022                	sd	s0,32(sp)
    80001648:	ec26                	sd	s1,24(sp)
    8000164a:	e84a                	sd	s2,16(sp)
    8000164c:	e44e                	sd	s3,8(sp)
    8000164e:	e052                	sd	s4,0(sp)
    80001650:	1800                	addi	s0,sp,48
    80001652:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001654:	84aa                	mv	s1,a0
    80001656:	6905                	lui	s2,0x1
    80001658:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000165a:	4985                	li	s3,1
    8000165c:	a821                	j	80001674 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000165e:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001660:	0532                	slli	a0,a0,0xc
    80001662:	00000097          	auipc	ra,0x0
    80001666:	fe0080e7          	jalr	-32(ra) # 80001642 <freewalk>
      pagetable[i] = 0;
    8000166a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000166e:	04a1                	addi	s1,s1,8
    80001670:	03248163          	beq	s1,s2,80001692 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001674:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001676:	00f57793          	andi	a5,a0,15
    8000167a:	ff3782e3          	beq	a5,s3,8000165e <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000167e:	8905                	andi	a0,a0,1
    80001680:	d57d                	beqz	a0,8000166e <freewalk+0x2c>
      panic("freewalk: leaf");
    80001682:	00007517          	auipc	a0,0x7
    80001686:	b4650513          	addi	a0,a0,-1210 # 800081c8 <digits+0x188>
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	eb4080e7          	jalr	-332(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001692:	8552                	mv	a0,s4
    80001694:	fffff097          	auipc	ra,0xfffff
    80001698:	49c080e7          	jalr	1180(ra) # 80000b30 <kfree>
}
    8000169c:	70a2                	ld	ra,40(sp)
    8000169e:	7402                	ld	s0,32(sp)
    800016a0:	64e2                	ld	s1,24(sp)
    800016a2:	6942                	ld	s2,16(sp)
    800016a4:	69a2                	ld	s3,8(sp)
    800016a6:	6a02                	ld	s4,0(sp)
    800016a8:	6145                	addi	sp,sp,48
    800016aa:	8082                	ret

00000000800016ac <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016ac:	1101                	addi	sp,sp,-32
    800016ae:	ec06                	sd	ra,24(sp)
    800016b0:	e822                	sd	s0,16(sp)
    800016b2:	e426                	sd	s1,8(sp)
    800016b4:	1000                	addi	s0,sp,32
    800016b6:	84aa                	mv	s1,a0
  if(sz > 0)
    800016b8:	e999                	bnez	a1,800016ce <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016ba:	8526                	mv	a0,s1
    800016bc:	00000097          	auipc	ra,0x0
    800016c0:	f86080e7          	jalr	-122(ra) # 80001642 <freewalk>
}
    800016c4:	60e2                	ld	ra,24(sp)
    800016c6:	6442                	ld	s0,16(sp)
    800016c8:	64a2                	ld	s1,8(sp)
    800016ca:	6105                	addi	sp,sp,32
    800016cc:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016ce:	6605                	lui	a2,0x1
    800016d0:	167d                	addi	a2,a2,-1
    800016d2:	962e                	add	a2,a2,a1
    800016d4:	4685                	li	a3,1
    800016d6:	8231                	srli	a2,a2,0xc
    800016d8:	4581                	li	a1,0
    800016da:	00000097          	auipc	ra,0x0
    800016de:	d0a080e7          	jalr	-758(ra) # 800013e4 <uvmunmap>
    800016e2:	bfe1                	j	800016ba <uvmfree+0xe>

00000000800016e4 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  // char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800016e4:	c66d                	beqz	a2,800017ce <uvmcopy+0xea>
{
    800016e6:	711d                	addi	sp,sp,-96
    800016e8:	ec86                	sd	ra,88(sp)
    800016ea:	e8a2                	sd	s0,80(sp)
    800016ec:	e4a6                	sd	s1,72(sp)
    800016ee:	e0ca                	sd	s2,64(sp)
    800016f0:	fc4e                	sd	s3,56(sp)
    800016f2:	f852                	sd	s4,48(sp)
    800016f4:	f456                	sd	s5,40(sp)
    800016f6:	f05a                	sd	s6,32(sp)
    800016f8:	ec5e                	sd	s7,24(sp)
    800016fa:	e862                	sd	s8,16(sp)
    800016fc:	e466                	sd	s9,8(sp)
    800016fe:	e06a                	sd	s10,0(sp)
    80001700:	1080                	addi	s0,sp,96
    80001702:	8c2a                	mv	s8,a0
    80001704:	8bae                	mv	s7,a1
    80001706:	8b32                	mv	s6,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001708:	4981                	li	s3,0
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    IncrementAndGetPageReference((void*)pa);
    if(flags&PTE_W){
      flags = (flags&(~PTE_W))|PTE_C;
      *pte = PA2PTE(pa)|flags;
    8000170a:	7cfd                	lui	s9,0xfffff
    8000170c:	002cdc93          	srli	s9,s9,0x2
    80001710:	a83d                	j	8000174e <uvmcopy+0x6a>
      panic("uvmcopy: pte should exist");
    80001712:	00007517          	auipc	a0,0x7
    80001716:	ac650513          	addi	a0,a0,-1338 # 800081d8 <digits+0x198>
    8000171a:	fffff097          	auipc	ra,0xfffff
    8000171e:	e24080e7          	jalr	-476(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001722:	00007517          	auipc	a0,0x7
    80001726:	ad650513          	addi	a0,a0,-1322 # 800081f8 <digits+0x1b8>
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	e14080e7          	jalr	-492(ra) # 8000053e <panic>
    }
    // if((mem = kalloc()) == 0)
    //   goto err;
    // memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    80001732:	8756                	mv	a4,s5
    80001734:	86d2                	mv	a3,s4
    80001736:	6605                	lui	a2,0x1
    80001738:	85ce                	mv	a1,s3
    8000173a:	855e                	mv	a0,s7
    8000173c:	00000097          	auipc	ra,0x0
    80001740:	ae2080e7          	jalr	-1310(ra) # 8000121e <mappages>
    80001744:	ed29                	bnez	a0,8000179e <uvmcopy+0xba>
  for(i = 0; i < sz; i += PGSIZE){
    80001746:	6785                	lui	a5,0x1
    80001748:	99be                	add	s3,s3,a5
    8000174a:	0769f463          	bgeu	s3,s6,800017b2 <uvmcopy+0xce>
    if((pte = walk(old, i, 0)) == 0)
    8000174e:	4601                	li	a2,0
    80001750:	85ce                	mv	a1,s3
    80001752:	8562                	mv	a0,s8
    80001754:	00000097          	auipc	ra,0x0
    80001758:	9e2080e7          	jalr	-1566(ra) # 80001136 <walk>
    8000175c:	892a                	mv	s2,a0
    8000175e:	d955                	beqz	a0,80001712 <uvmcopy+0x2e>
    if((*pte & PTE_V) == 0)
    80001760:	6104                	ld	s1,0(a0)
    80001762:	0014f793          	andi	a5,s1,1
    80001766:	dfd5                	beqz	a5,80001722 <uvmcopy+0x3e>
    pa = PTE2PA(*pte);
    80001768:	00a4da13          	srli	s4,s1,0xa
    8000176c:	0a32                	slli	s4,s4,0xc
    flags = PTE_FLAGS(*pte);
    8000176e:	00048d1b          	sext.w	s10,s1
    80001772:	3ff4fa93          	andi	s5,s1,1023
    IncrementAndGetPageReference((void*)pa);
    80001776:	8552                	mv	a0,s4
    80001778:	fffff097          	auipc	ra,0xfffff
    8000177c:	346080e7          	jalr	838(ra) # 80000abe <IncrementAndGetPageReference>
    if(flags&PTE_W){
    80001780:	004d7d13          	andi	s10,s10,4
    80001784:	fa0d07e3          	beqz	s10,80001732 <uvmcopy+0x4e>
      flags = (flags&(~PTE_W))|PTE_C;
    80001788:	fdbaf793          	andi	a5,s5,-37
    8000178c:	0207ea93          	ori	s5,a5,32
      *pte = PA2PTE(pa)|flags;
    80001790:	0194f4b3          	and	s1,s1,s9
    80001794:	0154e4b3          	or	s1,s1,s5
    80001798:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
    8000179c:	bf59                	j	80001732 <uvmcopy+0x4e>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000179e:	4685                	li	a3,1
    800017a0:	00c9d613          	srli	a2,s3,0xc
    800017a4:	4581                	li	a1,0
    800017a6:	855e                	mv	a0,s7
    800017a8:	00000097          	auipc	ra,0x0
    800017ac:	c3c080e7          	jalr	-964(ra) # 800013e4 <uvmunmap>
  return -1;
    800017b0:	557d                	li	a0,-1
}
    800017b2:	60e6                	ld	ra,88(sp)
    800017b4:	6446                	ld	s0,80(sp)
    800017b6:	64a6                	ld	s1,72(sp)
    800017b8:	6906                	ld	s2,64(sp)
    800017ba:	79e2                	ld	s3,56(sp)
    800017bc:	7a42                	ld	s4,48(sp)
    800017be:	7aa2                	ld	s5,40(sp)
    800017c0:	7b02                	ld	s6,32(sp)
    800017c2:	6be2                	ld	s7,24(sp)
    800017c4:	6c42                	ld	s8,16(sp)
    800017c6:	6ca2                	ld	s9,8(sp)
    800017c8:	6d02                	ld	s10,0(sp)
    800017ca:	6125                	addi	sp,sp,96
    800017cc:	8082                	ret
  return 0;
    800017ce:	4501                	li	a0,0
}
    800017d0:	8082                	ret

00000000800017d2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017d2:	1141                	addi	sp,sp,-16
    800017d4:	e406                	sd	ra,8(sp)
    800017d6:	e022                	sd	s0,0(sp)
    800017d8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017da:	4601                	li	a2,0
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	95a080e7          	jalr	-1702(ra) # 80001136 <walk>
  if(pte == 0)
    800017e4:	c901                	beqz	a0,800017f4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017e6:	611c                	ld	a5,0(a0)
    800017e8:	9bbd                	andi	a5,a5,-17
    800017ea:	e11c                	sd	a5,0(a0)
}
    800017ec:	60a2                	ld	ra,8(sp)
    800017ee:	6402                	ld	s0,0(sp)
    800017f0:	0141                	addi	sp,sp,16
    800017f2:	8082                	ret
    panic("uvmclear");
    800017f4:	00007517          	auipc	a0,0x7
    800017f8:	a2450513          	addi	a0,a0,-1500 # 80008218 <digits+0x1d8>
    800017fc:	fffff097          	auipc	ra,0xfffff
    80001800:	d42080e7          	jalr	-702(ra) # 8000053e <panic>

0000000080001804 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001804:	c2d5                	beqz	a3,800018a8 <copyout+0xa4>
{
    80001806:	711d                	addi	sp,sp,-96
    80001808:	ec86                	sd	ra,88(sp)
    8000180a:	e8a2                	sd	s0,80(sp)
    8000180c:	e4a6                	sd	s1,72(sp)
    8000180e:	e0ca                	sd	s2,64(sp)
    80001810:	fc4e                	sd	s3,56(sp)
    80001812:	f852                	sd	s4,48(sp)
    80001814:	f456                	sd	s5,40(sp)
    80001816:	f05a                	sd	s6,32(sp)
    80001818:	ec5e                	sd	s7,24(sp)
    8000181a:	e862                	sd	s8,16(sp)
    8000181c:	e466                	sd	s9,8(sp)
    8000181e:	1080                	addi	s0,sp,96
    80001820:	8baa                	mv	s7,a0
    80001822:	89ae                	mv	s3,a1
    80001824:	8b32                	mv	s6,a2
    80001826:	8ab6                	mv	s5,a3
    va0 = PGROUNDDOWN(dstva);
    80001828:	7cfd                	lui	s9,0xfffff
    if(flags & PTE_C){
      handle_page_fault((void*)va0,pagetable);
      pa0=walkaddr(pagetable,va0);
    }
    
    n = PGSIZE - (dstva - va0);
    8000182a:	6c05                	lui	s8,0x1
    8000182c:	a081                	j	8000186c <copyout+0x68>
      handle_page_fault((void*)va0,pagetable);
    8000182e:	85de                	mv	a1,s7
    80001830:	854a                	mv	a0,s2
    80001832:	00001097          	auipc	ra,0x1
    80001836:	1cc080e7          	jalr	460(ra) # 800029fe <handle_page_fault>
      pa0=walkaddr(pagetable,va0);
    8000183a:	85ca                	mv	a1,s2
    8000183c:	855e                	mv	a0,s7
    8000183e:	00000097          	auipc	ra,0x0
    80001842:	99e080e7          	jalr	-1634(ra) # 800011dc <walkaddr>
    80001846:	8a2a                	mv	s4,a0
    80001848:	a0b9                	j	80001896 <copyout+0x92>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000184a:	41298533          	sub	a0,s3,s2
    8000184e:	0004861b          	sext.w	a2,s1
    80001852:	85da                	mv	a1,s6
    80001854:	9552                	add	a0,a0,s4
    80001856:	fffff097          	auipc	ra,0xfffff
    8000185a:	658080e7          	jalr	1624(ra) # 80000eae <memmove>

    len -= n;
    8000185e:	409a8ab3          	sub	s5,s5,s1
    src += n;
    80001862:	9b26                	add	s6,s6,s1
    dstva = va0 + PGSIZE;
    80001864:	018909b3          	add	s3,s2,s8
  while(len > 0){
    80001868:	020a8e63          	beqz	s5,800018a4 <copyout+0xa0>
    va0 = PGROUNDDOWN(dstva);
    8000186c:	0199f933          	and	s2,s3,s9
    pa0 = walkaddr(pagetable, va0);
    80001870:	85ca                	mv	a1,s2
    80001872:	855e                	mv	a0,s7
    80001874:	00000097          	auipc	ra,0x0
    80001878:	968080e7          	jalr	-1688(ra) # 800011dc <walkaddr>
    8000187c:	8a2a                	mv	s4,a0
    if(pa0 == 0)
    8000187e:	c51d                	beqz	a0,800018ac <copyout+0xa8>
    uint64 flags=PTE_FLAGS(*(walk(pagetable,va0,0)));
    80001880:	4601                	li	a2,0
    80001882:	85ca                	mv	a1,s2
    80001884:	855e                	mv	a0,s7
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8b0080e7          	jalr	-1872(ra) # 80001136 <walk>
    if(flags & PTE_C){
    8000188e:	611c                	ld	a5,0(a0)
    80001890:	0207f793          	andi	a5,a5,32
    80001894:	ffc9                	bnez	a5,8000182e <copyout+0x2a>
    n = PGSIZE - (dstva - va0);
    80001896:	413904b3          	sub	s1,s2,s3
    8000189a:	94e2                	add	s1,s1,s8
    if(n > len)
    8000189c:	fa9af7e3          	bgeu	s5,s1,8000184a <copyout+0x46>
    800018a0:	84d6                	mv	s1,s5
    800018a2:	b765                	j	8000184a <copyout+0x46>
  }
  return 0;
    800018a4:	4501                	li	a0,0
    800018a6:	a021                	j	800018ae <copyout+0xaa>
    800018a8:	4501                	li	a0,0
}
    800018aa:	8082                	ret
      return -1;
    800018ac:	557d                	li	a0,-1
}
    800018ae:	60e6                	ld	ra,88(sp)
    800018b0:	6446                	ld	s0,80(sp)
    800018b2:	64a6                	ld	s1,72(sp)
    800018b4:	6906                	ld	s2,64(sp)
    800018b6:	79e2                	ld	s3,56(sp)
    800018b8:	7a42                	ld	s4,48(sp)
    800018ba:	7aa2                	ld	s5,40(sp)
    800018bc:	7b02                	ld	s6,32(sp)
    800018be:	6be2                	ld	s7,24(sp)
    800018c0:	6c42                	ld	s8,16(sp)
    800018c2:	6ca2                	ld	s9,8(sp)
    800018c4:	6125                	addi	sp,sp,96
    800018c6:	8082                	ret

00000000800018c8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018c8:	caa5                	beqz	a3,80001938 <copyin+0x70>
{
    800018ca:	715d                	addi	sp,sp,-80
    800018cc:	e486                	sd	ra,72(sp)
    800018ce:	e0a2                	sd	s0,64(sp)
    800018d0:	fc26                	sd	s1,56(sp)
    800018d2:	f84a                	sd	s2,48(sp)
    800018d4:	f44e                	sd	s3,40(sp)
    800018d6:	f052                	sd	s4,32(sp)
    800018d8:	ec56                	sd	s5,24(sp)
    800018da:	e85a                	sd	s6,16(sp)
    800018dc:	e45e                	sd	s7,8(sp)
    800018de:	e062                	sd	s8,0(sp)
    800018e0:	0880                	addi	s0,sp,80
    800018e2:	8b2a                	mv	s6,a0
    800018e4:	8a2e                	mv	s4,a1
    800018e6:	8c32                	mv	s8,a2
    800018e8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800018ea:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018ec:	6a85                	lui	s5,0x1
    800018ee:	a01d                	j	80001914 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018f0:	018505b3          	add	a1,a0,s8
    800018f4:	0004861b          	sext.w	a2,s1
    800018f8:	412585b3          	sub	a1,a1,s2
    800018fc:	8552                	mv	a0,s4
    800018fe:	fffff097          	auipc	ra,0xfffff
    80001902:	5b0080e7          	jalr	1456(ra) # 80000eae <memmove>

    len -= n;
    80001906:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000190a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000190c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001910:	02098263          	beqz	s3,80001934 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001914:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001918:	85ca                	mv	a1,s2
    8000191a:	855a                	mv	a0,s6
    8000191c:	00000097          	auipc	ra,0x0
    80001920:	8c0080e7          	jalr	-1856(ra) # 800011dc <walkaddr>
    if(pa0 == 0)
    80001924:	cd01                	beqz	a0,8000193c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001926:	418904b3          	sub	s1,s2,s8
    8000192a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000192c:	fc99f2e3          	bgeu	s3,s1,800018f0 <copyin+0x28>
    80001930:	84ce                	mv	s1,s3
    80001932:	bf7d                	j	800018f0 <copyin+0x28>
  }
  return 0;
    80001934:	4501                	li	a0,0
    80001936:	a021                	j	8000193e <copyin+0x76>
    80001938:	4501                	li	a0,0
}
    8000193a:	8082                	ret
      return -1;
    8000193c:	557d                	li	a0,-1
}
    8000193e:	60a6                	ld	ra,72(sp)
    80001940:	6406                	ld	s0,64(sp)
    80001942:	74e2                	ld	s1,56(sp)
    80001944:	7942                	ld	s2,48(sp)
    80001946:	79a2                	ld	s3,40(sp)
    80001948:	7a02                	ld	s4,32(sp)
    8000194a:	6ae2                	ld	s5,24(sp)
    8000194c:	6b42                	ld	s6,16(sp)
    8000194e:	6ba2                	ld	s7,8(sp)
    80001950:	6c02                	ld	s8,0(sp)
    80001952:	6161                	addi	sp,sp,80
    80001954:	8082                	ret

0000000080001956 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001956:	c6c5                	beqz	a3,800019fe <copyinstr+0xa8>
{
    80001958:	715d                	addi	sp,sp,-80
    8000195a:	e486                	sd	ra,72(sp)
    8000195c:	e0a2                	sd	s0,64(sp)
    8000195e:	fc26                	sd	s1,56(sp)
    80001960:	f84a                	sd	s2,48(sp)
    80001962:	f44e                	sd	s3,40(sp)
    80001964:	f052                	sd	s4,32(sp)
    80001966:	ec56                	sd	s5,24(sp)
    80001968:	e85a                	sd	s6,16(sp)
    8000196a:	e45e                	sd	s7,8(sp)
    8000196c:	0880                	addi	s0,sp,80
    8000196e:	8a2a                	mv	s4,a0
    80001970:	8b2e                	mv	s6,a1
    80001972:	8bb2                	mv	s7,a2
    80001974:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001976:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001978:	6985                	lui	s3,0x1
    8000197a:	a035                	j	800019a6 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000197c:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001980:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001982:	0017b793          	seqz	a5,a5
    80001986:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000198a:	60a6                	ld	ra,72(sp)
    8000198c:	6406                	ld	s0,64(sp)
    8000198e:	74e2                	ld	s1,56(sp)
    80001990:	7942                	ld	s2,48(sp)
    80001992:	79a2                	ld	s3,40(sp)
    80001994:	7a02                	ld	s4,32(sp)
    80001996:	6ae2                	ld	s5,24(sp)
    80001998:	6b42                	ld	s6,16(sp)
    8000199a:	6ba2                	ld	s7,8(sp)
    8000199c:	6161                	addi	sp,sp,80
    8000199e:	8082                	ret
    srcva = va0 + PGSIZE;
    800019a0:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800019a4:	c8a9                	beqz	s1,800019f6 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800019a6:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800019aa:	85ca                	mv	a1,s2
    800019ac:	8552                	mv	a0,s4
    800019ae:	00000097          	auipc	ra,0x0
    800019b2:	82e080e7          	jalr	-2002(ra) # 800011dc <walkaddr>
    if(pa0 == 0)
    800019b6:	c131                	beqz	a0,800019fa <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800019b8:	41790833          	sub	a6,s2,s7
    800019bc:	984e                	add	a6,a6,s3
    if(n > max)
    800019be:	0104f363          	bgeu	s1,a6,800019c4 <copyinstr+0x6e>
    800019c2:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800019c4:	955e                	add	a0,a0,s7
    800019c6:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800019ca:	fc080be3          	beqz	a6,800019a0 <copyinstr+0x4a>
    800019ce:	985a                	add	a6,a6,s6
    800019d0:	87da                	mv	a5,s6
      if(*p == '\0'){
    800019d2:	41650633          	sub	a2,a0,s6
    800019d6:	14fd                	addi	s1,s1,-1
    800019d8:	9b26                	add	s6,s6,s1
    800019da:	00f60733          	add	a4,a2,a5
    800019de:	00074703          	lbu	a4,0(a4)
    800019e2:	df49                	beqz	a4,8000197c <copyinstr+0x26>
        *dst = *p;
    800019e4:	00e78023          	sb	a4,0(a5)
      --max;
    800019e8:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800019ec:	0785                	addi	a5,a5,1
    while(n > 0){
    800019ee:	ff0796e3          	bne	a5,a6,800019da <copyinstr+0x84>
      dst++;
    800019f2:	8b42                	mv	s6,a6
    800019f4:	b775                	j	800019a0 <copyinstr+0x4a>
    800019f6:	4781                	li	a5,0
    800019f8:	b769                	j	80001982 <copyinstr+0x2c>
      return -1;
    800019fa:	557d                	li	a0,-1
    800019fc:	b779                	j	8000198a <copyinstr+0x34>
  int got_null = 0;
    800019fe:	4781                	li	a5,0
  if(got_null){
    80001a00:	0017b793          	seqz	a5,a5
    80001a04:	40f00533          	neg	a0,a5
}
    80001a08:	8082                	ret

0000000080001a0a <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001a0a:	7139                	addi	sp,sp,-64
    80001a0c:	fc06                	sd	ra,56(sp)
    80001a0e:	f822                	sd	s0,48(sp)
    80001a10:	f426                	sd	s1,40(sp)
    80001a12:	f04a                	sd	s2,32(sp)
    80001a14:	ec4e                	sd	s3,24(sp)
    80001a16:	e852                	sd	s4,16(sp)
    80001a18:	e456                	sd	s5,8(sp)
    80001a1a:	e05a                	sd	s6,0(sp)
    80001a1c:	0080                	addi	s0,sp,64
    80001a1e:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a20:	0022f497          	auipc	s1,0x22f
    80001a24:	5b848493          	addi	s1,s1,1464 # 80230fd8 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a28:	8b26                	mv	s6,s1
    80001a2a:	00006a97          	auipc	s5,0x6
    80001a2e:	5d6a8a93          	addi	s5,s5,1494 # 80008000 <etext>
    80001a32:	04000937          	lui	s2,0x4000
    80001a36:	197d                	addi	s2,s2,-1
    80001a38:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a3a:	00235a17          	auipc	s4,0x235
    80001a3e:	39ea0a13          	addi	s4,s4,926 # 80236dd8 <tickslock>
    char *pa = kalloc();
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	212080e7          	jalr	530(ra) # 80000c54 <kalloc>
    80001a4a:	862a                	mv	a2,a0
    if (pa == 0)
    80001a4c:	c131                	beqz	a0,80001a90 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001a4e:	416485b3          	sub	a1,s1,s6
    80001a52:	858d                	srai	a1,a1,0x3
    80001a54:	000ab783          	ld	a5,0(s5)
    80001a58:	02f585b3          	mul	a1,a1,a5
    80001a5c:	2585                	addiw	a1,a1,1
    80001a5e:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a62:	4719                	li	a4,6
    80001a64:	6685                	lui	a3,0x1
    80001a66:	40b905b3          	sub	a1,s2,a1
    80001a6a:	854e                	mv	a0,s3
    80001a6c:	00000097          	auipc	ra,0x0
    80001a70:	852080e7          	jalr	-1966(ra) # 800012be <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a74:	17848493          	addi	s1,s1,376
    80001a78:	fd4495e3          	bne	s1,s4,80001a42 <proc_mapstacks+0x38>
  }
}
    80001a7c:	70e2                	ld	ra,56(sp)
    80001a7e:	7442                	ld	s0,48(sp)
    80001a80:	74a2                	ld	s1,40(sp)
    80001a82:	7902                	ld	s2,32(sp)
    80001a84:	69e2                	ld	s3,24(sp)
    80001a86:	6a42                	ld	s4,16(sp)
    80001a88:	6aa2                	ld	s5,8(sp)
    80001a8a:	6b02                	ld	s6,0(sp)
    80001a8c:	6121                	addi	sp,sp,64
    80001a8e:	8082                	ret
      panic("kalloc");
    80001a90:	00006517          	auipc	a0,0x6
    80001a94:	79850513          	addi	a0,a0,1944 # 80008228 <digits+0x1e8>
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	aa6080e7          	jalr	-1370(ra) # 8000053e <panic>

0000000080001aa0 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001aa0:	7139                	addi	sp,sp,-64
    80001aa2:	fc06                	sd	ra,56(sp)
    80001aa4:	f822                	sd	s0,48(sp)
    80001aa6:	f426                	sd	s1,40(sp)
    80001aa8:	f04a                	sd	s2,32(sp)
    80001aaa:	ec4e                	sd	s3,24(sp)
    80001aac:	e852                	sd	s4,16(sp)
    80001aae:	e456                	sd	s5,8(sp)
    80001ab0:	e05a                	sd	s6,0(sp)
    80001ab2:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001ab4:	00006597          	auipc	a1,0x6
    80001ab8:	77c58593          	addi	a1,a1,1916 # 80008230 <digits+0x1f0>
    80001abc:	0022f517          	auipc	a0,0x22f
    80001ac0:	0ec50513          	addi	a0,a0,236 # 80230ba8 <pid_lock>
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	202080e7          	jalr	514(ra) # 80000cc6 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001acc:	00006597          	auipc	a1,0x6
    80001ad0:	76c58593          	addi	a1,a1,1900 # 80008238 <digits+0x1f8>
    80001ad4:	0022f517          	auipc	a0,0x22f
    80001ad8:	0ec50513          	addi	a0,a0,236 # 80230bc0 <wait_lock>
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	1ea080e7          	jalr	490(ra) # 80000cc6 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001ae4:	0022f497          	auipc	s1,0x22f
    80001ae8:	4f448493          	addi	s1,s1,1268 # 80230fd8 <proc>
  {
    initlock(&p->lock, "proc");
    80001aec:	00006b17          	auipc	s6,0x6
    80001af0:	75cb0b13          	addi	s6,s6,1884 # 80008248 <digits+0x208>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001af4:	8aa6                	mv	s5,s1
    80001af6:	00006a17          	auipc	s4,0x6
    80001afa:	50aa0a13          	addi	s4,s4,1290 # 80008000 <etext>
    80001afe:	04000937          	lui	s2,0x4000
    80001b02:	197d                	addi	s2,s2,-1
    80001b04:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001b06:	00235997          	auipc	s3,0x235
    80001b0a:	2d298993          	addi	s3,s3,722 # 80236dd8 <tickslock>
    initlock(&p->lock, "proc");
    80001b0e:	85da                	mv	a1,s6
    80001b10:	8526                	mv	a0,s1
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	1b4080e7          	jalr	436(ra) # 80000cc6 <initlock>
    p->state = UNUSED;
    80001b1a:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001b1e:	415487b3          	sub	a5,s1,s5
    80001b22:	878d                	srai	a5,a5,0x3
    80001b24:	000a3703          	ld	a4,0(s4)
    80001b28:	02e787b3          	mul	a5,a5,a4
    80001b2c:	2785                	addiw	a5,a5,1
    80001b2e:	00d7979b          	slliw	a5,a5,0xd
    80001b32:	40f907b3          	sub	a5,s2,a5
    80001b36:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b38:	17848493          	addi	s1,s1,376
    80001b3c:	fd3499e3          	bne	s1,s3,80001b0e <procinit+0x6e>
  }
}
    80001b40:	70e2                	ld	ra,56(sp)
    80001b42:	7442                	ld	s0,48(sp)
    80001b44:	74a2                	ld	s1,40(sp)
    80001b46:	7902                	ld	s2,32(sp)
    80001b48:	69e2                	ld	s3,24(sp)
    80001b4a:	6a42                	ld	s4,16(sp)
    80001b4c:	6aa2                	ld	s5,8(sp)
    80001b4e:	6b02                	ld	s6,0(sp)
    80001b50:	6121                	addi	sp,sp,64
    80001b52:	8082                	ret

0000000080001b54 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b54:	1141                	addi	sp,sp,-16
    80001b56:	e422                	sd	s0,8(sp)
    80001b58:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b5a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b5c:	2501                	sext.w	a0,a0
    80001b5e:	6422                	ld	s0,8(sp)
    80001b60:	0141                	addi	sp,sp,16
    80001b62:	8082                	ret

0000000080001b64 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b64:	1141                	addi	sp,sp,-16
    80001b66:	e422                	sd	s0,8(sp)
    80001b68:	0800                	addi	s0,sp,16
    80001b6a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b6c:	2781                	sext.w	a5,a5
    80001b6e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b70:	0022f517          	auipc	a0,0x22f
    80001b74:	06850513          	addi	a0,a0,104 # 80230bd8 <cpus>
    80001b78:	953e                	add	a0,a0,a5
    80001b7a:	6422                	ld	s0,8(sp)
    80001b7c:	0141                	addi	sp,sp,16
    80001b7e:	8082                	ret

0000000080001b80 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b80:	1101                	addi	sp,sp,-32
    80001b82:	ec06                	sd	ra,24(sp)
    80001b84:	e822                	sd	s0,16(sp)
    80001b86:	e426                	sd	s1,8(sp)
    80001b88:	1000                	addi	s0,sp,32
  push_off();
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	180080e7          	jalr	384(ra) # 80000d0a <push_off>
    80001b92:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b94:	2781                	sext.w	a5,a5
    80001b96:	079e                	slli	a5,a5,0x7
    80001b98:	0022f717          	auipc	a4,0x22f
    80001b9c:	01070713          	addi	a4,a4,16 # 80230ba8 <pid_lock>
    80001ba0:	97ba                	add	a5,a5,a4
    80001ba2:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	206080e7          	jalr	518(ra) # 80000daa <pop_off>
  return p;
}
    80001bac:	8526                	mv	a0,s1
    80001bae:	60e2                	ld	ra,24(sp)
    80001bb0:	6442                	ld	s0,16(sp)
    80001bb2:	64a2                	ld	s1,8(sp)
    80001bb4:	6105                	addi	sp,sp,32
    80001bb6:	8082                	ret

0000000080001bb8 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bb8:	1141                	addi	sp,sp,-16
    80001bba:	e406                	sd	ra,8(sp)
    80001bbc:	e022                	sd	s0,0(sp)
    80001bbe:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bc0:	00000097          	auipc	ra,0x0
    80001bc4:	fc0080e7          	jalr	-64(ra) # 80001b80 <myproc>
    80001bc8:	fffff097          	auipc	ra,0xfffff
    80001bcc:	242080e7          	jalr	578(ra) # 80000e0a <release>

  if (first)
    80001bd0:	00007797          	auipc	a5,0x7
    80001bd4:	cd07a783          	lw	a5,-816(a5) # 800088a0 <first.1>
    80001bd8:	eb89                	bnez	a5,80001bea <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bda:	00001097          	auipc	ra,0x1
    80001bde:	eda080e7          	jalr	-294(ra) # 80002ab4 <usertrapret>
}
    80001be2:	60a2                	ld	ra,8(sp)
    80001be4:	6402                	ld	s0,0(sp)
    80001be6:	0141                	addi	sp,sp,16
    80001be8:	8082                	ret
    first = 0;
    80001bea:	00007797          	auipc	a5,0x7
    80001bee:	ca07ab23          	sw	zero,-842(a5) # 800088a0 <first.1>
    fsinit(ROOTDEV);
    80001bf2:	4505                	li	a0,1
    80001bf4:	00002097          	auipc	ra,0x2
    80001bf8:	cf6080e7          	jalr	-778(ra) # 800038ea <fsinit>
    80001bfc:	bff9                	j	80001bda <forkret+0x22>

0000000080001bfe <allocpid>:
{
    80001bfe:	1101                	addi	sp,sp,-32
    80001c00:	ec06                	sd	ra,24(sp)
    80001c02:	e822                	sd	s0,16(sp)
    80001c04:	e426                	sd	s1,8(sp)
    80001c06:	e04a                	sd	s2,0(sp)
    80001c08:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c0a:	0022f917          	auipc	s2,0x22f
    80001c0e:	f9e90913          	addi	s2,s2,-98 # 80230ba8 <pid_lock>
    80001c12:	854a                	mv	a0,s2
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	142080e7          	jalr	322(ra) # 80000d56 <acquire>
  pid = nextpid;
    80001c1c:	00007797          	auipc	a5,0x7
    80001c20:	c8878793          	addi	a5,a5,-888 # 800088a4 <nextpid>
    80001c24:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c26:	0014871b          	addiw	a4,s1,1
    80001c2a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c2c:	854a                	mv	a0,s2
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	1dc080e7          	jalr	476(ra) # 80000e0a <release>
}
    80001c36:	8526                	mv	a0,s1
    80001c38:	60e2                	ld	ra,24(sp)
    80001c3a:	6442                	ld	s0,16(sp)
    80001c3c:	64a2                	ld	s1,8(sp)
    80001c3e:	6902                	ld	s2,0(sp)
    80001c40:	6105                	addi	sp,sp,32
    80001c42:	8082                	ret

0000000080001c44 <proc_pagetable>:
{
    80001c44:	1101                	addi	sp,sp,-32
    80001c46:	ec06                	sd	ra,24(sp)
    80001c48:	e822                	sd	s0,16(sp)
    80001c4a:	e426                	sd	s1,8(sp)
    80001c4c:	e04a                	sd	s2,0(sp)
    80001c4e:	1000                	addi	s0,sp,32
    80001c50:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c52:	00000097          	auipc	ra,0x0
    80001c56:	856080e7          	jalr	-1962(ra) # 800014a8 <uvmcreate>
    80001c5a:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c5c:	c121                	beqz	a0,80001c9c <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c5e:	4729                	li	a4,10
    80001c60:	00005697          	auipc	a3,0x5
    80001c64:	3a068693          	addi	a3,a3,928 # 80007000 <_trampoline>
    80001c68:	6605                	lui	a2,0x1
    80001c6a:	040005b7          	lui	a1,0x4000
    80001c6e:	15fd                	addi	a1,a1,-1
    80001c70:	05b2                	slli	a1,a1,0xc
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	5ac080e7          	jalr	1452(ra) # 8000121e <mappages>
    80001c7a:	02054863          	bltz	a0,80001caa <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c7e:	4719                	li	a4,6
    80001c80:	05893683          	ld	a3,88(s2)
    80001c84:	6605                	lui	a2,0x1
    80001c86:	020005b7          	lui	a1,0x2000
    80001c8a:	15fd                	addi	a1,a1,-1
    80001c8c:	05b6                	slli	a1,a1,0xd
    80001c8e:	8526                	mv	a0,s1
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	58e080e7          	jalr	1422(ra) # 8000121e <mappages>
    80001c98:	02054163          	bltz	a0,80001cba <proc_pagetable+0x76>
}
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	60e2                	ld	ra,24(sp)
    80001ca0:	6442                	ld	s0,16(sp)
    80001ca2:	64a2                	ld	s1,8(sp)
    80001ca4:	6902                	ld	s2,0(sp)
    80001ca6:	6105                	addi	sp,sp,32
    80001ca8:	8082                	ret
    uvmfree(pagetable, 0);
    80001caa:	4581                	li	a1,0
    80001cac:	8526                	mv	a0,s1
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	9fe080e7          	jalr	-1538(ra) # 800016ac <uvmfree>
    return 0;
    80001cb6:	4481                	li	s1,0
    80001cb8:	b7d5                	j	80001c9c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cba:	4681                	li	a3,0
    80001cbc:	4605                	li	a2,1
    80001cbe:	040005b7          	lui	a1,0x4000
    80001cc2:	15fd                	addi	a1,a1,-1
    80001cc4:	05b2                	slli	a1,a1,0xc
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	71c080e7          	jalr	1820(ra) # 800013e4 <uvmunmap>
    uvmfree(pagetable, 0);
    80001cd0:	4581                	li	a1,0
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	9d8080e7          	jalr	-1576(ra) # 800016ac <uvmfree>
    return 0;
    80001cdc:	4481                	li	s1,0
    80001cde:	bf7d                	j	80001c9c <proc_pagetable+0x58>

0000000080001ce0 <proc_freepagetable>:
{
    80001ce0:	1101                	addi	sp,sp,-32
    80001ce2:	ec06                	sd	ra,24(sp)
    80001ce4:	e822                	sd	s0,16(sp)
    80001ce6:	e426                	sd	s1,8(sp)
    80001ce8:	e04a                	sd	s2,0(sp)
    80001cea:	1000                	addi	s0,sp,32
    80001cec:	84aa                	mv	s1,a0
    80001cee:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cf0:	4681                	li	a3,0
    80001cf2:	4605                	li	a2,1
    80001cf4:	040005b7          	lui	a1,0x4000
    80001cf8:	15fd                	addi	a1,a1,-1
    80001cfa:	05b2                	slli	a1,a1,0xc
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	6e8080e7          	jalr	1768(ra) # 800013e4 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d04:	4681                	li	a3,0
    80001d06:	4605                	li	a2,1
    80001d08:	020005b7          	lui	a1,0x2000
    80001d0c:	15fd                	addi	a1,a1,-1
    80001d0e:	05b6                	slli	a1,a1,0xd
    80001d10:	8526                	mv	a0,s1
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	6d2080e7          	jalr	1746(ra) # 800013e4 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d1a:	85ca                	mv	a1,s2
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	00000097          	auipc	ra,0x0
    80001d22:	98e080e7          	jalr	-1650(ra) # 800016ac <uvmfree>
}
    80001d26:	60e2                	ld	ra,24(sp)
    80001d28:	6442                	ld	s0,16(sp)
    80001d2a:	64a2                	ld	s1,8(sp)
    80001d2c:	6902                	ld	s2,0(sp)
    80001d2e:	6105                	addi	sp,sp,32
    80001d30:	8082                	ret

0000000080001d32 <freeproc>:
{
    80001d32:	1101                	addi	sp,sp,-32
    80001d34:	ec06                	sd	ra,24(sp)
    80001d36:	e822                	sd	s0,16(sp)
    80001d38:	e426                	sd	s1,8(sp)
    80001d3a:	1000                	addi	s0,sp,32
    80001d3c:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d3e:	6d28                	ld	a0,88(a0)
    80001d40:	c509                	beqz	a0,80001d4a <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	dee080e7          	jalr	-530(ra) # 80000b30 <kfree>
  p->trapframe = 0;
    80001d4a:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001d4e:	68a8                	ld	a0,80(s1)
    80001d50:	c511                	beqz	a0,80001d5c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d52:	64ac                	ld	a1,72(s1)
    80001d54:	00000097          	auipc	ra,0x0
    80001d58:	f8c080e7          	jalr	-116(ra) # 80001ce0 <proc_freepagetable>
  p->pagetable = 0;
    80001d5c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d60:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d64:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d68:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d6c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d70:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d74:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d78:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d7c:	0004ac23          	sw	zero,24(s1)
}
    80001d80:	60e2                	ld	ra,24(sp)
    80001d82:	6442                	ld	s0,16(sp)
    80001d84:	64a2                	ld	s1,8(sp)
    80001d86:	6105                	addi	sp,sp,32
    80001d88:	8082                	ret

0000000080001d8a <allocproc>:
{
    80001d8a:	1101                	addi	sp,sp,-32
    80001d8c:	ec06                	sd	ra,24(sp)
    80001d8e:	e822                	sd	s0,16(sp)
    80001d90:	e426                	sd	s1,8(sp)
    80001d92:	e04a                	sd	s2,0(sp)
    80001d94:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d96:	0022f497          	auipc	s1,0x22f
    80001d9a:	24248493          	addi	s1,s1,578 # 80230fd8 <proc>
    80001d9e:	00235917          	auipc	s2,0x235
    80001da2:	03a90913          	addi	s2,s2,58 # 80236dd8 <tickslock>
    acquire(&p->lock);
    80001da6:	8526                	mv	a0,s1
    80001da8:	fffff097          	auipc	ra,0xfffff
    80001dac:	fae080e7          	jalr	-82(ra) # 80000d56 <acquire>
    if (p->state == UNUSED)
    80001db0:	4c9c                	lw	a5,24(s1)
    80001db2:	cf81                	beqz	a5,80001dca <allocproc+0x40>
      release(&p->lock);
    80001db4:	8526                	mv	a0,s1
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	054080e7          	jalr	84(ra) # 80000e0a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001dbe:	17848493          	addi	s1,s1,376
    80001dc2:	ff2492e3          	bne	s1,s2,80001da6 <allocproc+0x1c>
  return 0;
    80001dc6:	4481                	li	s1,0
    80001dc8:	a09d                	j	80001e2e <allocproc+0xa4>
  p->pid = allocpid();
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	e34080e7          	jalr	-460(ra) # 80001bfe <allocpid>
    80001dd2:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001dd4:	4785                	li	a5,1
    80001dd6:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	e7c080e7          	jalr	-388(ra) # 80000c54 <kalloc>
    80001de0:	892a                	mv	s2,a0
    80001de2:	eca8                	sd	a0,88(s1)
    80001de4:	cd21                	beqz	a0,80001e3c <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001de6:	8526                	mv	a0,s1
    80001de8:	00000097          	auipc	ra,0x0
    80001dec:	e5c080e7          	jalr	-420(ra) # 80001c44 <proc_pagetable>
    80001df0:	892a                	mv	s2,a0
    80001df2:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001df4:	c125                	beqz	a0,80001e54 <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001df6:	07000613          	li	a2,112
    80001dfa:	4581                	li	a1,0
    80001dfc:	06048513          	addi	a0,s1,96
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	052080e7          	jalr	82(ra) # 80000e52 <memset>
  p->context.ra = (uint64)forkret;
    80001e08:	00000797          	auipc	a5,0x0
    80001e0c:	db078793          	addi	a5,a5,-592 # 80001bb8 <forkret>
    80001e10:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e12:	60bc                	ld	a5,64(s1)
    80001e14:	6705                	lui	a4,0x1
    80001e16:	97ba                	add	a5,a5,a4
    80001e18:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001e1a:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001e1e:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001e22:	00007797          	auipc	a5,0x7
    80001e26:	afe7a783          	lw	a5,-1282(a5) # 80008920 <ticks>
    80001e2a:	16f4a623          	sw	a5,364(s1)
}
    80001e2e:	8526                	mv	a0,s1
    80001e30:	60e2                	ld	ra,24(sp)
    80001e32:	6442                	ld	s0,16(sp)
    80001e34:	64a2                	ld	s1,8(sp)
    80001e36:	6902                	ld	s2,0(sp)
    80001e38:	6105                	addi	sp,sp,32
    80001e3a:	8082                	ret
    freeproc(p);
    80001e3c:	8526                	mv	a0,s1
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	ef4080e7          	jalr	-268(ra) # 80001d32 <freeproc>
    release(&p->lock);
    80001e46:	8526                	mv	a0,s1
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	fc2080e7          	jalr	-62(ra) # 80000e0a <release>
    return 0;
    80001e50:	84ca                	mv	s1,s2
    80001e52:	bff1                	j	80001e2e <allocproc+0xa4>
    freeproc(p);
    80001e54:	8526                	mv	a0,s1
    80001e56:	00000097          	auipc	ra,0x0
    80001e5a:	edc080e7          	jalr	-292(ra) # 80001d32 <freeproc>
    release(&p->lock);
    80001e5e:	8526                	mv	a0,s1
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	faa080e7          	jalr	-86(ra) # 80000e0a <release>
    return 0;
    80001e68:	84ca                	mv	s1,s2
    80001e6a:	b7d1                	j	80001e2e <allocproc+0xa4>

0000000080001e6c <userinit>:
{
    80001e6c:	1101                	addi	sp,sp,-32
    80001e6e:	ec06                	sd	ra,24(sp)
    80001e70:	e822                	sd	s0,16(sp)
    80001e72:	e426                	sd	s1,8(sp)
    80001e74:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e76:	00000097          	auipc	ra,0x0
    80001e7a:	f14080e7          	jalr	-236(ra) # 80001d8a <allocproc>
    80001e7e:	84aa                	mv	s1,a0
  initproc = p;
    80001e80:	00007797          	auipc	a5,0x7
    80001e84:	a8a7bc23          	sd	a0,-1384(a5) # 80008918 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e88:	03400613          	li	a2,52
    80001e8c:	00007597          	auipc	a1,0x7
    80001e90:	a2458593          	addi	a1,a1,-1500 # 800088b0 <initcode>
    80001e94:	6928                	ld	a0,80(a0)
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	640080e7          	jalr	1600(ra) # 800014d6 <uvmfirst>
  p->sz = PGSIZE;
    80001e9e:	6785                	lui	a5,0x1
    80001ea0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ea2:	6cb8                	ld	a4,88(s1)
    80001ea4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ea8:	6cb8                	ld	a4,88(s1)
    80001eaa:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001eac:	4641                	li	a2,16
    80001eae:	00006597          	auipc	a1,0x6
    80001eb2:	3a258593          	addi	a1,a1,930 # 80008250 <digits+0x210>
    80001eb6:	15848513          	addi	a0,s1,344
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	0e2080e7          	jalr	226(ra) # 80000f9c <safestrcpy>
  p->cwd = namei("/");
    80001ec2:	00006517          	auipc	a0,0x6
    80001ec6:	39e50513          	addi	a0,a0,926 # 80008260 <digits+0x220>
    80001eca:	00002097          	auipc	ra,0x2
    80001ece:	442080e7          	jalr	1090(ra) # 8000430c <namei>
    80001ed2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ed6:	478d                	li	a5,3
    80001ed8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001eda:	8526                	mv	a0,s1
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	f2e080e7          	jalr	-210(ra) # 80000e0a <release>
}
    80001ee4:	60e2                	ld	ra,24(sp)
    80001ee6:	6442                	ld	s0,16(sp)
    80001ee8:	64a2                	ld	s1,8(sp)
    80001eea:	6105                	addi	sp,sp,32
    80001eec:	8082                	ret

0000000080001eee <growproc>:
{
    80001eee:	1101                	addi	sp,sp,-32
    80001ef0:	ec06                	sd	ra,24(sp)
    80001ef2:	e822                	sd	s0,16(sp)
    80001ef4:	e426                	sd	s1,8(sp)
    80001ef6:	e04a                	sd	s2,0(sp)
    80001ef8:	1000                	addi	s0,sp,32
    80001efa:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001efc:	00000097          	auipc	ra,0x0
    80001f00:	c84080e7          	jalr	-892(ra) # 80001b80 <myproc>
    80001f04:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f06:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001f08:	01204c63          	bgtz	s2,80001f20 <growproc+0x32>
  else if (n < 0)
    80001f0c:	02094663          	bltz	s2,80001f38 <growproc+0x4a>
  p->sz = sz;
    80001f10:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f12:	4501                	li	a0,0
}
    80001f14:	60e2                	ld	ra,24(sp)
    80001f16:	6442                	ld	s0,16(sp)
    80001f18:	64a2                	ld	s1,8(sp)
    80001f1a:	6902                	ld	s2,0(sp)
    80001f1c:	6105                	addi	sp,sp,32
    80001f1e:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f20:	4691                	li	a3,4
    80001f22:	00b90633          	add	a2,s2,a1
    80001f26:	6928                	ld	a0,80(a0)
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	668080e7          	jalr	1640(ra) # 80001590 <uvmalloc>
    80001f30:	85aa                	mv	a1,a0
    80001f32:	fd79                	bnez	a0,80001f10 <growproc+0x22>
      return -1;
    80001f34:	557d                	li	a0,-1
    80001f36:	bff9                	j	80001f14 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f38:	00b90633          	add	a2,s2,a1
    80001f3c:	6928                	ld	a0,80(a0)
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	60a080e7          	jalr	1546(ra) # 80001548 <uvmdealloc>
    80001f46:	85aa                	mv	a1,a0
    80001f48:	b7e1                	j	80001f10 <growproc+0x22>

0000000080001f4a <fork>:
{
    80001f4a:	7139                	addi	sp,sp,-64
    80001f4c:	fc06                	sd	ra,56(sp)
    80001f4e:	f822                	sd	s0,48(sp)
    80001f50:	f426                	sd	s1,40(sp)
    80001f52:	f04a                	sd	s2,32(sp)
    80001f54:	ec4e                	sd	s3,24(sp)
    80001f56:	e852                	sd	s4,16(sp)
    80001f58:	e456                	sd	s5,8(sp)
    80001f5a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f5c:	00000097          	auipc	ra,0x0
    80001f60:	c24080e7          	jalr	-988(ra) # 80001b80 <myproc>
    80001f64:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	e24080e7          	jalr	-476(ra) # 80001d8a <allocproc>
    80001f6e:	10050c63          	beqz	a0,80002086 <fork+0x13c>
    80001f72:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f74:	048ab603          	ld	a2,72(s5)
    80001f78:	692c                	ld	a1,80(a0)
    80001f7a:	050ab503          	ld	a0,80(s5)
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	766080e7          	jalr	1894(ra) # 800016e4 <uvmcopy>
    80001f86:	04054863          	bltz	a0,80001fd6 <fork+0x8c>
  np->sz = p->sz;
    80001f8a:	048ab783          	ld	a5,72(s5)
    80001f8e:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f92:	058ab683          	ld	a3,88(s5)
    80001f96:	87b6                	mv	a5,a3
    80001f98:	058a3703          	ld	a4,88(s4)
    80001f9c:	12068693          	addi	a3,a3,288
    80001fa0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fa4:	6788                	ld	a0,8(a5)
    80001fa6:	6b8c                	ld	a1,16(a5)
    80001fa8:	6f90                	ld	a2,24(a5)
    80001faa:	01073023          	sd	a6,0(a4)
    80001fae:	e708                	sd	a0,8(a4)
    80001fb0:	eb0c                	sd	a1,16(a4)
    80001fb2:	ef10                	sd	a2,24(a4)
    80001fb4:	02078793          	addi	a5,a5,32
    80001fb8:	02070713          	addi	a4,a4,32
    80001fbc:	fed792e3          	bne	a5,a3,80001fa0 <fork+0x56>
  np->trapframe->a0 = 0;
    80001fc0:	058a3783          	ld	a5,88(s4)
    80001fc4:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001fc8:	0d0a8493          	addi	s1,s5,208
    80001fcc:	0d0a0913          	addi	s2,s4,208
    80001fd0:	150a8993          	addi	s3,s5,336
    80001fd4:	a00d                	j	80001ff6 <fork+0xac>
    freeproc(np);
    80001fd6:	8552                	mv	a0,s4
    80001fd8:	00000097          	auipc	ra,0x0
    80001fdc:	d5a080e7          	jalr	-678(ra) # 80001d32 <freeproc>
    release(&np->lock);
    80001fe0:	8552                	mv	a0,s4
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	e28080e7          	jalr	-472(ra) # 80000e0a <release>
    return -1;
    80001fea:	597d                	li	s2,-1
    80001fec:	a059                	j	80002072 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001fee:	04a1                	addi	s1,s1,8
    80001ff0:	0921                	addi	s2,s2,8
    80001ff2:	01348b63          	beq	s1,s3,80002008 <fork+0xbe>
    if (p->ofile[i])
    80001ff6:	6088                	ld	a0,0(s1)
    80001ff8:	d97d                	beqz	a0,80001fee <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ffa:	00003097          	auipc	ra,0x3
    80001ffe:	9a8080e7          	jalr	-1624(ra) # 800049a2 <filedup>
    80002002:	00a93023          	sd	a0,0(s2)
    80002006:	b7e5                	j	80001fee <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002008:	150ab503          	ld	a0,336(s5)
    8000200c:	00002097          	auipc	ra,0x2
    80002010:	b1c080e7          	jalr	-1252(ra) # 80003b28 <idup>
    80002014:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002018:	4641                	li	a2,16
    8000201a:	158a8593          	addi	a1,s5,344
    8000201e:	158a0513          	addi	a0,s4,344
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	f7a080e7          	jalr	-134(ra) # 80000f9c <safestrcpy>
  pid = np->pid;
    8000202a:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    8000202e:	8552                	mv	a0,s4
    80002030:	fffff097          	auipc	ra,0xfffff
    80002034:	dda080e7          	jalr	-550(ra) # 80000e0a <release>
  acquire(&wait_lock);
    80002038:	0022f497          	auipc	s1,0x22f
    8000203c:	b8848493          	addi	s1,s1,-1144 # 80230bc0 <wait_lock>
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	d14080e7          	jalr	-748(ra) # 80000d56 <acquire>
  np->parent = p;
    8000204a:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    8000204e:	8526                	mv	a0,s1
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	dba080e7          	jalr	-582(ra) # 80000e0a <release>
  acquire(&np->lock);
    80002058:	8552                	mv	a0,s4
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	cfc080e7          	jalr	-772(ra) # 80000d56 <acquire>
  np->state = RUNNABLE;
    80002062:	478d                	li	a5,3
    80002064:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002068:	8552                	mv	a0,s4
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	da0080e7          	jalr	-608(ra) # 80000e0a <release>
}
    80002072:	854a                	mv	a0,s2
    80002074:	70e2                	ld	ra,56(sp)
    80002076:	7442                	ld	s0,48(sp)
    80002078:	74a2                	ld	s1,40(sp)
    8000207a:	7902                	ld	s2,32(sp)
    8000207c:	69e2                	ld	s3,24(sp)
    8000207e:	6a42                	ld	s4,16(sp)
    80002080:	6aa2                	ld	s5,8(sp)
    80002082:	6121                	addi	sp,sp,64
    80002084:	8082                	ret
    return -1;
    80002086:	597d                	li	s2,-1
    80002088:	b7ed                	j	80002072 <fork+0x128>

000000008000208a <scheduler>:
{
    8000208a:	7139                	addi	sp,sp,-64
    8000208c:	fc06                	sd	ra,56(sp)
    8000208e:	f822                	sd	s0,48(sp)
    80002090:	f426                	sd	s1,40(sp)
    80002092:	f04a                	sd	s2,32(sp)
    80002094:	ec4e                	sd	s3,24(sp)
    80002096:	e852                	sd	s4,16(sp)
    80002098:	e456                	sd	s5,8(sp)
    8000209a:	e05a                	sd	s6,0(sp)
    8000209c:	0080                	addi	s0,sp,64
    8000209e:	8792                	mv	a5,tp
  int id = r_tp();
    800020a0:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020a2:	00779a93          	slli	s5,a5,0x7
    800020a6:	0022f717          	auipc	a4,0x22f
    800020aa:	b0270713          	addi	a4,a4,-1278 # 80230ba8 <pid_lock>
    800020ae:	9756                	add	a4,a4,s5
    800020b0:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800020b4:	0022f717          	auipc	a4,0x22f
    800020b8:	b2c70713          	addi	a4,a4,-1236 # 80230be0 <cpus+0x8>
    800020bc:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    800020be:	498d                	li	s3,3
        p->state = RUNNING;
    800020c0:	4b11                	li	s6,4
        c->proc = p;
    800020c2:	079e                	slli	a5,a5,0x7
    800020c4:	0022fa17          	auipc	s4,0x22f
    800020c8:	ae4a0a13          	addi	s4,s4,-1308 # 80230ba8 <pid_lock>
    800020cc:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800020ce:	00235917          	auipc	s2,0x235
    800020d2:	d0a90913          	addi	s2,s2,-758 # 80236dd8 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020da:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020de:	10079073          	csrw	sstatus,a5
    800020e2:	0022f497          	auipc	s1,0x22f
    800020e6:	ef648493          	addi	s1,s1,-266 # 80230fd8 <proc>
    800020ea:	a811                	j	800020fe <scheduler+0x74>
      release(&p->lock);
    800020ec:	8526                	mv	a0,s1
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	d1c080e7          	jalr	-740(ra) # 80000e0a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800020f6:	17848493          	addi	s1,s1,376
    800020fa:	fd248ee3          	beq	s1,s2,800020d6 <scheduler+0x4c>
      acquire(&p->lock);
    800020fe:	8526                	mv	a0,s1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	c56080e7          	jalr	-938(ra) # 80000d56 <acquire>
      if (p->state == RUNNABLE)
    80002108:	4c9c                	lw	a5,24(s1)
    8000210a:	ff3791e3          	bne	a5,s3,800020ec <scheduler+0x62>
        p->state = RUNNING;
    8000210e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002112:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002116:	06048593          	addi	a1,s1,96
    8000211a:	8556                	mv	a0,s5
    8000211c:	00001097          	auipc	ra,0x1
    80002120:	838080e7          	jalr	-1992(ra) # 80002954 <swtch>
        c->proc = 0;
    80002124:	020a3823          	sd	zero,48(s4)
    80002128:	b7d1                	j	800020ec <scheduler+0x62>

000000008000212a <sched>:
{
    8000212a:	7179                	addi	sp,sp,-48
    8000212c:	f406                	sd	ra,40(sp)
    8000212e:	f022                	sd	s0,32(sp)
    80002130:	ec26                	sd	s1,24(sp)
    80002132:	e84a                	sd	s2,16(sp)
    80002134:	e44e                	sd	s3,8(sp)
    80002136:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002138:	00000097          	auipc	ra,0x0
    8000213c:	a48080e7          	jalr	-1464(ra) # 80001b80 <myproc>
    80002140:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	b9a080e7          	jalr	-1126(ra) # 80000cdc <holding>
    8000214a:	c93d                	beqz	a0,800021c0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000214c:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000214e:	2781                	sext.w	a5,a5
    80002150:	079e                	slli	a5,a5,0x7
    80002152:	0022f717          	auipc	a4,0x22f
    80002156:	a5670713          	addi	a4,a4,-1450 # 80230ba8 <pid_lock>
    8000215a:	97ba                	add	a5,a5,a4
    8000215c:	0a87a703          	lw	a4,168(a5)
    80002160:	4785                	li	a5,1
    80002162:	06f71763          	bne	a4,a5,800021d0 <sched+0xa6>
  if (p->state == RUNNING)
    80002166:	4c98                	lw	a4,24(s1)
    80002168:	4791                	li	a5,4
    8000216a:	06f70b63          	beq	a4,a5,800021e0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000216e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002172:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002174:	efb5                	bnez	a5,800021f0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002176:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002178:	0022f917          	auipc	s2,0x22f
    8000217c:	a3090913          	addi	s2,s2,-1488 # 80230ba8 <pid_lock>
    80002180:	2781                	sext.w	a5,a5
    80002182:	079e                	slli	a5,a5,0x7
    80002184:	97ca                	add	a5,a5,s2
    80002186:	0ac7a983          	lw	s3,172(a5)
    8000218a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000218c:	2781                	sext.w	a5,a5
    8000218e:	079e                	slli	a5,a5,0x7
    80002190:	0022f597          	auipc	a1,0x22f
    80002194:	a5058593          	addi	a1,a1,-1456 # 80230be0 <cpus+0x8>
    80002198:	95be                	add	a1,a1,a5
    8000219a:	06048513          	addi	a0,s1,96
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	7b6080e7          	jalr	1974(ra) # 80002954 <swtch>
    800021a6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021a8:	2781                	sext.w	a5,a5
    800021aa:	079e                	slli	a5,a5,0x7
    800021ac:	97ca                	add	a5,a5,s2
    800021ae:	0b37a623          	sw	s3,172(a5)
}
    800021b2:	70a2                	ld	ra,40(sp)
    800021b4:	7402                	ld	s0,32(sp)
    800021b6:	64e2                	ld	s1,24(sp)
    800021b8:	6942                	ld	s2,16(sp)
    800021ba:	69a2                	ld	s3,8(sp)
    800021bc:	6145                	addi	sp,sp,48
    800021be:	8082                	ret
    panic("sched p->lock");
    800021c0:	00006517          	auipc	a0,0x6
    800021c4:	0a850513          	addi	a0,a0,168 # 80008268 <digits+0x228>
    800021c8:	ffffe097          	auipc	ra,0xffffe
    800021cc:	376080e7          	jalr	886(ra) # 8000053e <panic>
    panic("sched locks");
    800021d0:	00006517          	auipc	a0,0x6
    800021d4:	0a850513          	addi	a0,a0,168 # 80008278 <digits+0x238>
    800021d8:	ffffe097          	auipc	ra,0xffffe
    800021dc:	366080e7          	jalr	870(ra) # 8000053e <panic>
    panic("sched running");
    800021e0:	00006517          	auipc	a0,0x6
    800021e4:	0a850513          	addi	a0,a0,168 # 80008288 <digits+0x248>
    800021e8:	ffffe097          	auipc	ra,0xffffe
    800021ec:	356080e7          	jalr	854(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021f0:	00006517          	auipc	a0,0x6
    800021f4:	0a850513          	addi	a0,a0,168 # 80008298 <digits+0x258>
    800021f8:	ffffe097          	auipc	ra,0xffffe
    800021fc:	346080e7          	jalr	838(ra) # 8000053e <panic>

0000000080002200 <yield>:
{
    80002200:	1101                	addi	sp,sp,-32
    80002202:	ec06                	sd	ra,24(sp)
    80002204:	e822                	sd	s0,16(sp)
    80002206:	e426                	sd	s1,8(sp)
    80002208:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	976080e7          	jalr	-1674(ra) # 80001b80 <myproc>
    80002212:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	b42080e7          	jalr	-1214(ra) # 80000d56 <acquire>
  p->state = RUNNABLE;
    8000221c:	478d                	li	a5,3
    8000221e:	cc9c                	sw	a5,24(s1)
  sched();
    80002220:	00000097          	auipc	ra,0x0
    80002224:	f0a080e7          	jalr	-246(ra) # 8000212a <sched>
  release(&p->lock);
    80002228:	8526                	mv	a0,s1
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	be0080e7          	jalr	-1056(ra) # 80000e0a <release>
}
    80002232:	60e2                	ld	ra,24(sp)
    80002234:	6442                	ld	s0,16(sp)
    80002236:	64a2                	ld	s1,8(sp)
    80002238:	6105                	addi	sp,sp,32
    8000223a:	8082                	ret

000000008000223c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000223c:	7179                	addi	sp,sp,-48
    8000223e:	f406                	sd	ra,40(sp)
    80002240:	f022                	sd	s0,32(sp)
    80002242:	ec26                	sd	s1,24(sp)
    80002244:	e84a                	sd	s2,16(sp)
    80002246:	e44e                	sd	s3,8(sp)
    80002248:	1800                	addi	s0,sp,48
    8000224a:	89aa                	mv	s3,a0
    8000224c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	932080e7          	jalr	-1742(ra) # 80001b80 <myproc>
    80002256:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	afe080e7          	jalr	-1282(ra) # 80000d56 <acquire>
  release(lk);
    80002260:	854a                	mv	a0,s2
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	ba8080e7          	jalr	-1112(ra) # 80000e0a <release>

  // Go to sleep.
  p->chan = chan;
    8000226a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000226e:	4789                	li	a5,2
    80002270:	cc9c                	sw	a5,24(s1)

  sched();
    80002272:	00000097          	auipc	ra,0x0
    80002276:	eb8080e7          	jalr	-328(ra) # 8000212a <sched>

  // Tidy up.
  p->chan = 0;
    8000227a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	b8a080e7          	jalr	-1142(ra) # 80000e0a <release>
  acquire(lk);
    80002288:	854a                	mv	a0,s2
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	acc080e7          	jalr	-1332(ra) # 80000d56 <acquire>
}
    80002292:	70a2                	ld	ra,40(sp)
    80002294:	7402                	ld	s0,32(sp)
    80002296:	64e2                	ld	s1,24(sp)
    80002298:	6942                	ld	s2,16(sp)
    8000229a:	69a2                	ld	s3,8(sp)
    8000229c:	6145                	addi	sp,sp,48
    8000229e:	8082                	ret

00000000800022a0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800022a0:	7139                	addi	sp,sp,-64
    800022a2:	fc06                	sd	ra,56(sp)
    800022a4:	f822                	sd	s0,48(sp)
    800022a6:	f426                	sd	s1,40(sp)
    800022a8:	f04a                	sd	s2,32(sp)
    800022aa:	ec4e                	sd	s3,24(sp)
    800022ac:	e852                	sd	s4,16(sp)
    800022ae:	e456                	sd	s5,8(sp)
    800022b0:	0080                	addi	s0,sp,64
    800022b2:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022b4:	0022f497          	auipc	s1,0x22f
    800022b8:	d2448493          	addi	s1,s1,-732 # 80230fd8 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800022bc:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800022be:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800022c0:	00235917          	auipc	s2,0x235
    800022c4:	b1890913          	addi	s2,s2,-1256 # 80236dd8 <tickslock>
    800022c8:	a811                	j	800022dc <wakeup+0x3c>
      }
      release(&p->lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	b3e080e7          	jalr	-1218(ra) # 80000e0a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022d4:	17848493          	addi	s1,s1,376
    800022d8:	03248663          	beq	s1,s2,80002304 <wakeup+0x64>
    if (p != myproc())
    800022dc:	00000097          	auipc	ra,0x0
    800022e0:	8a4080e7          	jalr	-1884(ra) # 80001b80 <myproc>
    800022e4:	fea488e3          	beq	s1,a0,800022d4 <wakeup+0x34>
      acquire(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	a6c080e7          	jalr	-1428(ra) # 80000d56 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800022f2:	4c9c                	lw	a5,24(s1)
    800022f4:	fd379be3          	bne	a5,s3,800022ca <wakeup+0x2a>
    800022f8:	709c                	ld	a5,32(s1)
    800022fa:	fd4798e3          	bne	a5,s4,800022ca <wakeup+0x2a>
        p->state = RUNNABLE;
    800022fe:	0154ac23          	sw	s5,24(s1)
    80002302:	b7e1                	j	800022ca <wakeup+0x2a>
    }
  }
}
    80002304:	70e2                	ld	ra,56(sp)
    80002306:	7442                	ld	s0,48(sp)
    80002308:	74a2                	ld	s1,40(sp)
    8000230a:	7902                	ld	s2,32(sp)
    8000230c:	69e2                	ld	s3,24(sp)
    8000230e:	6a42                	ld	s4,16(sp)
    80002310:	6aa2                	ld	s5,8(sp)
    80002312:	6121                	addi	sp,sp,64
    80002314:	8082                	ret

0000000080002316 <reparent>:
{
    80002316:	7179                	addi	sp,sp,-48
    80002318:	f406                	sd	ra,40(sp)
    8000231a:	f022                	sd	s0,32(sp)
    8000231c:	ec26                	sd	s1,24(sp)
    8000231e:	e84a                	sd	s2,16(sp)
    80002320:	e44e                	sd	s3,8(sp)
    80002322:	e052                	sd	s4,0(sp)
    80002324:	1800                	addi	s0,sp,48
    80002326:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002328:	0022f497          	auipc	s1,0x22f
    8000232c:	cb048493          	addi	s1,s1,-848 # 80230fd8 <proc>
      pp->parent = initproc;
    80002330:	00006a17          	auipc	s4,0x6
    80002334:	5e8a0a13          	addi	s4,s4,1512 # 80008918 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002338:	00235997          	auipc	s3,0x235
    8000233c:	aa098993          	addi	s3,s3,-1376 # 80236dd8 <tickslock>
    80002340:	a029                	j	8000234a <reparent+0x34>
    80002342:	17848493          	addi	s1,s1,376
    80002346:	01348d63          	beq	s1,s3,80002360 <reparent+0x4a>
    if (pp->parent == p)
    8000234a:	7c9c                	ld	a5,56(s1)
    8000234c:	ff279be3          	bne	a5,s2,80002342 <reparent+0x2c>
      pp->parent = initproc;
    80002350:	000a3503          	ld	a0,0(s4)
    80002354:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002356:	00000097          	auipc	ra,0x0
    8000235a:	f4a080e7          	jalr	-182(ra) # 800022a0 <wakeup>
    8000235e:	b7d5                	j	80002342 <reparent+0x2c>
}
    80002360:	70a2                	ld	ra,40(sp)
    80002362:	7402                	ld	s0,32(sp)
    80002364:	64e2                	ld	s1,24(sp)
    80002366:	6942                	ld	s2,16(sp)
    80002368:	69a2                	ld	s3,8(sp)
    8000236a:	6a02                	ld	s4,0(sp)
    8000236c:	6145                	addi	sp,sp,48
    8000236e:	8082                	ret

0000000080002370 <exit>:
{
    80002370:	7179                	addi	sp,sp,-48
    80002372:	f406                	sd	ra,40(sp)
    80002374:	f022                	sd	s0,32(sp)
    80002376:	ec26                	sd	s1,24(sp)
    80002378:	e84a                	sd	s2,16(sp)
    8000237a:	e44e                	sd	s3,8(sp)
    8000237c:	e052                	sd	s4,0(sp)
    8000237e:	1800                	addi	s0,sp,48
    80002380:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	7fe080e7          	jalr	2046(ra) # 80001b80 <myproc>
    8000238a:	89aa                	mv	s3,a0
  if (p == initproc)
    8000238c:	00006797          	auipc	a5,0x6
    80002390:	58c7b783          	ld	a5,1420(a5) # 80008918 <initproc>
    80002394:	0d050493          	addi	s1,a0,208
    80002398:	15050913          	addi	s2,a0,336
    8000239c:	02a79363          	bne	a5,a0,800023c2 <exit+0x52>
    panic("init exiting");
    800023a0:	00006517          	auipc	a0,0x6
    800023a4:	f1050513          	addi	a0,a0,-240 # 800082b0 <digits+0x270>
    800023a8:	ffffe097          	auipc	ra,0xffffe
    800023ac:	196080e7          	jalr	406(ra) # 8000053e <panic>
      fileclose(f);
    800023b0:	00002097          	auipc	ra,0x2
    800023b4:	644080e7          	jalr	1604(ra) # 800049f4 <fileclose>
      p->ofile[fd] = 0;
    800023b8:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800023bc:	04a1                	addi	s1,s1,8
    800023be:	01248563          	beq	s1,s2,800023c8 <exit+0x58>
    if (p->ofile[fd])
    800023c2:	6088                	ld	a0,0(s1)
    800023c4:	f575                	bnez	a0,800023b0 <exit+0x40>
    800023c6:	bfdd                	j	800023bc <exit+0x4c>
  begin_op();
    800023c8:	00002097          	auipc	ra,0x2
    800023cc:	160080e7          	jalr	352(ra) # 80004528 <begin_op>
  iput(p->cwd);
    800023d0:	1509b503          	ld	a0,336(s3)
    800023d4:	00002097          	auipc	ra,0x2
    800023d8:	94c080e7          	jalr	-1716(ra) # 80003d20 <iput>
  end_op();
    800023dc:	00002097          	auipc	ra,0x2
    800023e0:	1cc080e7          	jalr	460(ra) # 800045a8 <end_op>
  p->cwd = 0;
    800023e4:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023e8:	0022e497          	auipc	s1,0x22e
    800023ec:	7d848493          	addi	s1,s1,2008 # 80230bc0 <wait_lock>
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	964080e7          	jalr	-1692(ra) # 80000d56 <acquire>
  reparent(p);
    800023fa:	854e                	mv	a0,s3
    800023fc:	00000097          	auipc	ra,0x0
    80002400:	f1a080e7          	jalr	-230(ra) # 80002316 <reparent>
  wakeup(p->parent);
    80002404:	0389b503          	ld	a0,56(s3)
    80002408:	00000097          	auipc	ra,0x0
    8000240c:	e98080e7          	jalr	-360(ra) # 800022a0 <wakeup>
  acquire(&p->lock);
    80002410:	854e                	mv	a0,s3
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	944080e7          	jalr	-1724(ra) # 80000d56 <acquire>
  p->xstate = status;
    8000241a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000241e:	4795                	li	a5,5
    80002420:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002424:	00006797          	auipc	a5,0x6
    80002428:	4fc7a783          	lw	a5,1276(a5) # 80008920 <ticks>
    8000242c:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002430:	8526                	mv	a0,s1
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	9d8080e7          	jalr	-1576(ra) # 80000e0a <release>
  sched();
    8000243a:	00000097          	auipc	ra,0x0
    8000243e:	cf0080e7          	jalr	-784(ra) # 8000212a <sched>
  panic("zombie exit");
    80002442:	00006517          	auipc	a0,0x6
    80002446:	e7e50513          	addi	a0,a0,-386 # 800082c0 <digits+0x280>
    8000244a:	ffffe097          	auipc	ra,0xffffe
    8000244e:	0f4080e7          	jalr	244(ra) # 8000053e <panic>

0000000080002452 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002452:	7179                	addi	sp,sp,-48
    80002454:	f406                	sd	ra,40(sp)
    80002456:	f022                	sd	s0,32(sp)
    80002458:	ec26                	sd	s1,24(sp)
    8000245a:	e84a                	sd	s2,16(sp)
    8000245c:	e44e                	sd	s3,8(sp)
    8000245e:	1800                	addi	s0,sp,48
    80002460:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002462:	0022f497          	auipc	s1,0x22f
    80002466:	b7648493          	addi	s1,s1,-1162 # 80230fd8 <proc>
    8000246a:	00235997          	auipc	s3,0x235
    8000246e:	96e98993          	addi	s3,s3,-1682 # 80236dd8 <tickslock>
  {
    acquire(&p->lock);
    80002472:	8526                	mv	a0,s1
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	8e2080e7          	jalr	-1822(ra) # 80000d56 <acquire>
    if (p->pid == pid)
    8000247c:	589c                	lw	a5,48(s1)
    8000247e:	01278d63          	beq	a5,s2,80002498 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002482:	8526                	mv	a0,s1
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	986080e7          	jalr	-1658(ra) # 80000e0a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000248c:	17848493          	addi	s1,s1,376
    80002490:	ff3491e3          	bne	s1,s3,80002472 <kill+0x20>
  }
  return -1;
    80002494:	557d                	li	a0,-1
    80002496:	a829                	j	800024b0 <kill+0x5e>
      p->killed = 1;
    80002498:	4785                	li	a5,1
    8000249a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000249c:	4c98                	lw	a4,24(s1)
    8000249e:	4789                	li	a5,2
    800024a0:	00f70f63          	beq	a4,a5,800024be <kill+0x6c>
      release(&p->lock);
    800024a4:	8526                	mv	a0,s1
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	964080e7          	jalr	-1692(ra) # 80000e0a <release>
      return 0;
    800024ae:	4501                	li	a0,0
}
    800024b0:	70a2                	ld	ra,40(sp)
    800024b2:	7402                	ld	s0,32(sp)
    800024b4:	64e2                	ld	s1,24(sp)
    800024b6:	6942                	ld	s2,16(sp)
    800024b8:	69a2                	ld	s3,8(sp)
    800024ba:	6145                	addi	sp,sp,48
    800024bc:	8082                	ret
        p->state = RUNNABLE;
    800024be:	478d                	li	a5,3
    800024c0:	cc9c                	sw	a5,24(s1)
    800024c2:	b7cd                	j	800024a4 <kill+0x52>

00000000800024c4 <setkilled>:

void setkilled(struct proc *p)
{
    800024c4:	1101                	addi	sp,sp,-32
    800024c6:	ec06                	sd	ra,24(sp)
    800024c8:	e822                	sd	s0,16(sp)
    800024ca:	e426                	sd	s1,8(sp)
    800024cc:	1000                	addi	s0,sp,32
    800024ce:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	886080e7          	jalr	-1914(ra) # 80000d56 <acquire>
  p->killed = 1;
    800024d8:	4785                	li	a5,1
    800024da:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800024dc:	8526                	mv	a0,s1
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	92c080e7          	jalr	-1748(ra) # 80000e0a <release>
}
    800024e6:	60e2                	ld	ra,24(sp)
    800024e8:	6442                	ld	s0,16(sp)
    800024ea:	64a2                	ld	s1,8(sp)
    800024ec:	6105                	addi	sp,sp,32
    800024ee:	8082                	ret

00000000800024f0 <killed>:

int killed(struct proc *p)
{
    800024f0:	1101                	addi	sp,sp,-32
    800024f2:	ec06                	sd	ra,24(sp)
    800024f4:	e822                	sd	s0,16(sp)
    800024f6:	e426                	sd	s1,8(sp)
    800024f8:	e04a                	sd	s2,0(sp)
    800024fa:	1000                	addi	s0,sp,32
    800024fc:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	858080e7          	jalr	-1960(ra) # 80000d56 <acquire>
  k = p->killed;
    80002506:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000250a:	8526                	mv	a0,s1
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	8fe080e7          	jalr	-1794(ra) # 80000e0a <release>
  return k;
}
    80002514:	854a                	mv	a0,s2
    80002516:	60e2                	ld	ra,24(sp)
    80002518:	6442                	ld	s0,16(sp)
    8000251a:	64a2                	ld	s1,8(sp)
    8000251c:	6902                	ld	s2,0(sp)
    8000251e:	6105                	addi	sp,sp,32
    80002520:	8082                	ret

0000000080002522 <wait>:
{
    80002522:	715d                	addi	sp,sp,-80
    80002524:	e486                	sd	ra,72(sp)
    80002526:	e0a2                	sd	s0,64(sp)
    80002528:	fc26                	sd	s1,56(sp)
    8000252a:	f84a                	sd	s2,48(sp)
    8000252c:	f44e                	sd	s3,40(sp)
    8000252e:	f052                	sd	s4,32(sp)
    80002530:	ec56                	sd	s5,24(sp)
    80002532:	e85a                	sd	s6,16(sp)
    80002534:	e45e                	sd	s7,8(sp)
    80002536:	e062                	sd	s8,0(sp)
    80002538:	0880                	addi	s0,sp,80
    8000253a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	644080e7          	jalr	1604(ra) # 80001b80 <myproc>
    80002544:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002546:	0022e517          	auipc	a0,0x22e
    8000254a:	67a50513          	addi	a0,a0,1658 # 80230bc0 <wait_lock>
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	808080e7          	jalr	-2040(ra) # 80000d56 <acquire>
    havekids = 0;
    80002556:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002558:	4a15                	li	s4,5
        havekids = 1;
    8000255a:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000255c:	00235997          	auipc	s3,0x235
    80002560:	87c98993          	addi	s3,s3,-1924 # 80236dd8 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002564:	0022ec17          	auipc	s8,0x22e
    80002568:	65cc0c13          	addi	s8,s8,1628 # 80230bc0 <wait_lock>
    havekids = 0;
    8000256c:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000256e:	0022f497          	auipc	s1,0x22f
    80002572:	a6a48493          	addi	s1,s1,-1430 # 80230fd8 <proc>
    80002576:	a0bd                	j	800025e4 <wait+0xc2>
          pid = pp->pid;
    80002578:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000257c:	000b0e63          	beqz	s6,80002598 <wait+0x76>
    80002580:	4691                	li	a3,4
    80002582:	02c48613          	addi	a2,s1,44
    80002586:	85da                	mv	a1,s6
    80002588:	05093503          	ld	a0,80(s2)
    8000258c:	fffff097          	auipc	ra,0xfffff
    80002590:	278080e7          	jalr	632(ra) # 80001804 <copyout>
    80002594:	02054563          	bltz	a0,800025be <wait+0x9c>
          freeproc(pp);
    80002598:	8526                	mv	a0,s1
    8000259a:	fffff097          	auipc	ra,0xfffff
    8000259e:	798080e7          	jalr	1944(ra) # 80001d32 <freeproc>
          release(&pp->lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	fffff097          	auipc	ra,0xfffff
    800025a8:	866080e7          	jalr	-1946(ra) # 80000e0a <release>
          release(&wait_lock);
    800025ac:	0022e517          	auipc	a0,0x22e
    800025b0:	61450513          	addi	a0,a0,1556 # 80230bc0 <wait_lock>
    800025b4:	fffff097          	auipc	ra,0xfffff
    800025b8:	856080e7          	jalr	-1962(ra) # 80000e0a <release>
          return pid;
    800025bc:	a0b5                	j	80002628 <wait+0x106>
            release(&pp->lock);
    800025be:	8526                	mv	a0,s1
    800025c0:	fffff097          	auipc	ra,0xfffff
    800025c4:	84a080e7          	jalr	-1974(ra) # 80000e0a <release>
            release(&wait_lock);
    800025c8:	0022e517          	auipc	a0,0x22e
    800025cc:	5f850513          	addi	a0,a0,1528 # 80230bc0 <wait_lock>
    800025d0:	fffff097          	auipc	ra,0xfffff
    800025d4:	83a080e7          	jalr	-1990(ra) # 80000e0a <release>
            return -1;
    800025d8:	59fd                	li	s3,-1
    800025da:	a0b9                	j	80002628 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025dc:	17848493          	addi	s1,s1,376
    800025e0:	03348463          	beq	s1,s3,80002608 <wait+0xe6>
      if (pp->parent == p)
    800025e4:	7c9c                	ld	a5,56(s1)
    800025e6:	ff279be3          	bne	a5,s2,800025dc <wait+0xba>
        acquire(&pp->lock);
    800025ea:	8526                	mv	a0,s1
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	76a080e7          	jalr	1898(ra) # 80000d56 <acquire>
        if (pp->state == ZOMBIE)
    800025f4:	4c9c                	lw	a5,24(s1)
    800025f6:	f94781e3          	beq	a5,s4,80002578 <wait+0x56>
        release(&pp->lock);
    800025fa:	8526                	mv	a0,s1
    800025fc:	fffff097          	auipc	ra,0xfffff
    80002600:	80e080e7          	jalr	-2034(ra) # 80000e0a <release>
        havekids = 1;
    80002604:	8756                	mv	a4,s5
    80002606:	bfd9                	j	800025dc <wait+0xba>
    if (!havekids || killed(p))
    80002608:	c719                	beqz	a4,80002616 <wait+0xf4>
    8000260a:	854a                	mv	a0,s2
    8000260c:	00000097          	auipc	ra,0x0
    80002610:	ee4080e7          	jalr	-284(ra) # 800024f0 <killed>
    80002614:	c51d                	beqz	a0,80002642 <wait+0x120>
      release(&wait_lock);
    80002616:	0022e517          	auipc	a0,0x22e
    8000261a:	5aa50513          	addi	a0,a0,1450 # 80230bc0 <wait_lock>
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	7ec080e7          	jalr	2028(ra) # 80000e0a <release>
      return -1;
    80002626:	59fd                	li	s3,-1
}
    80002628:	854e                	mv	a0,s3
    8000262a:	60a6                	ld	ra,72(sp)
    8000262c:	6406                	ld	s0,64(sp)
    8000262e:	74e2                	ld	s1,56(sp)
    80002630:	7942                	ld	s2,48(sp)
    80002632:	79a2                	ld	s3,40(sp)
    80002634:	7a02                	ld	s4,32(sp)
    80002636:	6ae2                	ld	s5,24(sp)
    80002638:	6b42                	ld	s6,16(sp)
    8000263a:	6ba2                	ld	s7,8(sp)
    8000263c:	6c02                	ld	s8,0(sp)
    8000263e:	6161                	addi	sp,sp,80
    80002640:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002642:	85e2                	mv	a1,s8
    80002644:	854a                	mv	a0,s2
    80002646:	00000097          	auipc	ra,0x0
    8000264a:	bf6080e7          	jalr	-1034(ra) # 8000223c <sleep>
    havekids = 0;
    8000264e:	bf39                	j	8000256c <wait+0x4a>

0000000080002650 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002650:	7179                	addi	sp,sp,-48
    80002652:	f406                	sd	ra,40(sp)
    80002654:	f022                	sd	s0,32(sp)
    80002656:	ec26                	sd	s1,24(sp)
    80002658:	e84a                	sd	s2,16(sp)
    8000265a:	e44e                	sd	s3,8(sp)
    8000265c:	e052                	sd	s4,0(sp)
    8000265e:	1800                	addi	s0,sp,48
    80002660:	84aa                	mv	s1,a0
    80002662:	892e                	mv	s2,a1
    80002664:	89b2                	mv	s3,a2
    80002666:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002668:	fffff097          	auipc	ra,0xfffff
    8000266c:	518080e7          	jalr	1304(ra) # 80001b80 <myproc>
  if (user_dst)
    80002670:	c08d                	beqz	s1,80002692 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002672:	86d2                	mv	a3,s4
    80002674:	864e                	mv	a2,s3
    80002676:	85ca                	mv	a1,s2
    80002678:	6928                	ld	a0,80(a0)
    8000267a:	fffff097          	auipc	ra,0xfffff
    8000267e:	18a080e7          	jalr	394(ra) # 80001804 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002682:	70a2                	ld	ra,40(sp)
    80002684:	7402                	ld	s0,32(sp)
    80002686:	64e2                	ld	s1,24(sp)
    80002688:	6942                	ld	s2,16(sp)
    8000268a:	69a2                	ld	s3,8(sp)
    8000268c:	6a02                	ld	s4,0(sp)
    8000268e:	6145                	addi	sp,sp,48
    80002690:	8082                	ret
    memmove((char *)dst, src, len);
    80002692:	000a061b          	sext.w	a2,s4
    80002696:	85ce                	mv	a1,s3
    80002698:	854a                	mv	a0,s2
    8000269a:	fffff097          	auipc	ra,0xfffff
    8000269e:	814080e7          	jalr	-2028(ra) # 80000eae <memmove>
    return 0;
    800026a2:	8526                	mv	a0,s1
    800026a4:	bff9                	j	80002682 <either_copyout+0x32>

00000000800026a6 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026a6:	7179                	addi	sp,sp,-48
    800026a8:	f406                	sd	ra,40(sp)
    800026aa:	f022                	sd	s0,32(sp)
    800026ac:	ec26                	sd	s1,24(sp)
    800026ae:	e84a                	sd	s2,16(sp)
    800026b0:	e44e                	sd	s3,8(sp)
    800026b2:	e052                	sd	s4,0(sp)
    800026b4:	1800                	addi	s0,sp,48
    800026b6:	892a                	mv	s2,a0
    800026b8:	84ae                	mv	s1,a1
    800026ba:	89b2                	mv	s3,a2
    800026bc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026be:	fffff097          	auipc	ra,0xfffff
    800026c2:	4c2080e7          	jalr	1218(ra) # 80001b80 <myproc>
  if (user_src)
    800026c6:	c08d                	beqz	s1,800026e8 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800026c8:	86d2                	mv	a3,s4
    800026ca:	864e                	mv	a2,s3
    800026cc:	85ca                	mv	a1,s2
    800026ce:	6928                	ld	a0,80(a0)
    800026d0:	fffff097          	auipc	ra,0xfffff
    800026d4:	1f8080e7          	jalr	504(ra) # 800018c8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800026d8:	70a2                	ld	ra,40(sp)
    800026da:	7402                	ld	s0,32(sp)
    800026dc:	64e2                	ld	s1,24(sp)
    800026de:	6942                	ld	s2,16(sp)
    800026e0:	69a2                	ld	s3,8(sp)
    800026e2:	6a02                	ld	s4,0(sp)
    800026e4:	6145                	addi	sp,sp,48
    800026e6:	8082                	ret
    memmove(dst, (char *)src, len);
    800026e8:	000a061b          	sext.w	a2,s4
    800026ec:	85ce                	mv	a1,s3
    800026ee:	854a                	mv	a0,s2
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	7be080e7          	jalr	1982(ra) # 80000eae <memmove>
    return 0;
    800026f8:	8526                	mv	a0,s1
    800026fa:	bff9                	j	800026d8 <either_copyin+0x32>

00000000800026fc <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800026fc:	715d                	addi	sp,sp,-80
    800026fe:	e486                	sd	ra,72(sp)
    80002700:	e0a2                	sd	s0,64(sp)
    80002702:	fc26                	sd	s1,56(sp)
    80002704:	f84a                	sd	s2,48(sp)
    80002706:	f44e                	sd	s3,40(sp)
    80002708:	f052                	sd	s4,32(sp)
    8000270a:	ec56                	sd	s5,24(sp)
    8000270c:	e85a                	sd	s6,16(sp)
    8000270e:	e45e                	sd	s7,8(sp)
    80002710:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002712:	00006517          	auipc	a0,0x6
    80002716:	a0650513          	addi	a0,a0,-1530 # 80008118 <digits+0xd8>
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	e6e080e7          	jalr	-402(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002722:	0022f497          	auipc	s1,0x22f
    80002726:	a0e48493          	addi	s1,s1,-1522 # 80231130 <proc+0x158>
    8000272a:	00235917          	auipc	s2,0x235
    8000272e:	80690913          	addi	s2,s2,-2042 # 80236f30 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002732:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002734:	00006997          	auipc	s3,0x6
    80002738:	b9c98993          	addi	s3,s3,-1124 # 800082d0 <digits+0x290>
    printf("%d %s %s", p->pid, state, p->name);
    8000273c:	00006a97          	auipc	s5,0x6
    80002740:	b9ca8a93          	addi	s5,s5,-1124 # 800082d8 <digits+0x298>
    printf("\n");
    80002744:	00006a17          	auipc	s4,0x6
    80002748:	9d4a0a13          	addi	s4,s4,-1580 # 80008118 <digits+0xd8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000274c:	00006b97          	auipc	s7,0x6
    80002750:	bccb8b93          	addi	s7,s7,-1076 # 80008318 <states.0>
    80002754:	a00d                	j	80002776 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002756:	ed86a583          	lw	a1,-296(a3)
    8000275a:	8556                	mv	a0,s5
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	e2c080e7          	jalr	-468(ra) # 80000588 <printf>
    printf("\n");
    80002764:	8552                	mv	a0,s4
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	e22080e7          	jalr	-478(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000276e:	17848493          	addi	s1,s1,376
    80002772:	03248163          	beq	s1,s2,80002794 <procdump+0x98>
    if (p->state == UNUSED)
    80002776:	86a6                	mv	a3,s1
    80002778:	ec04a783          	lw	a5,-320(s1)
    8000277c:	dbed                	beqz	a5,8000276e <procdump+0x72>
      state = "???";
    8000277e:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002780:	fcfb6be3          	bltu	s6,a5,80002756 <procdump+0x5a>
    80002784:	1782                	slli	a5,a5,0x20
    80002786:	9381                	srli	a5,a5,0x20
    80002788:	078e                	slli	a5,a5,0x3
    8000278a:	97de                	add	a5,a5,s7
    8000278c:	6390                	ld	a2,0(a5)
    8000278e:	f661                	bnez	a2,80002756 <procdump+0x5a>
      state = "???";
    80002790:	864e                	mv	a2,s3
    80002792:	b7d1                	j	80002756 <procdump+0x5a>
  }
}
    80002794:	60a6                	ld	ra,72(sp)
    80002796:	6406                	ld	s0,64(sp)
    80002798:	74e2                	ld	s1,56(sp)
    8000279a:	7942                	ld	s2,48(sp)
    8000279c:	79a2                	ld	s3,40(sp)
    8000279e:	7a02                	ld	s4,32(sp)
    800027a0:	6ae2                	ld	s5,24(sp)
    800027a2:	6b42                	ld	s6,16(sp)
    800027a4:	6ba2                	ld	s7,8(sp)
    800027a6:	6161                	addi	sp,sp,80
    800027a8:	8082                	ret

00000000800027aa <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800027aa:	711d                	addi	sp,sp,-96
    800027ac:	ec86                	sd	ra,88(sp)
    800027ae:	e8a2                	sd	s0,80(sp)
    800027b0:	e4a6                	sd	s1,72(sp)
    800027b2:	e0ca                	sd	s2,64(sp)
    800027b4:	fc4e                	sd	s3,56(sp)
    800027b6:	f852                	sd	s4,48(sp)
    800027b8:	f456                	sd	s5,40(sp)
    800027ba:	f05a                	sd	s6,32(sp)
    800027bc:	ec5e                	sd	s7,24(sp)
    800027be:	e862                	sd	s8,16(sp)
    800027c0:	e466                	sd	s9,8(sp)
    800027c2:	e06a                	sd	s10,0(sp)
    800027c4:	1080                	addi	s0,sp,96
    800027c6:	8b2a                	mv	s6,a0
    800027c8:	8bae                	mv	s7,a1
    800027ca:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800027cc:	fffff097          	auipc	ra,0xfffff
    800027d0:	3b4080e7          	jalr	948(ra) # 80001b80 <myproc>
    800027d4:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800027d6:	0022e517          	auipc	a0,0x22e
    800027da:	3ea50513          	addi	a0,a0,1002 # 80230bc0 <wait_lock>
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	578080e7          	jalr	1400(ra) # 80000d56 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800027e6:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    800027e8:	4a15                	li	s4,5
        havekids = 1;
    800027ea:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800027ec:	00234997          	auipc	s3,0x234
    800027f0:	5ec98993          	addi	s3,s3,1516 # 80236dd8 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027f4:	0022ed17          	auipc	s10,0x22e
    800027f8:	3ccd0d13          	addi	s10,s10,972 # 80230bc0 <wait_lock>
    havekids = 0;
    800027fc:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800027fe:	0022e497          	auipc	s1,0x22e
    80002802:	7da48493          	addi	s1,s1,2010 # 80230fd8 <proc>
    80002806:	a059                	j	8000288c <waitx+0xe2>
          pid = np->pid;
    80002808:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000280c:	1684a703          	lw	a4,360(s1)
    80002810:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002814:	16c4a783          	lw	a5,364(s1)
    80002818:	9f3d                	addw	a4,a4,a5
    8000281a:	1704a783          	lw	a5,368(s1)
    8000281e:	9f99                	subw	a5,a5,a4
    80002820:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002824:	000b0e63          	beqz	s6,80002840 <waitx+0x96>
    80002828:	4691                	li	a3,4
    8000282a:	02c48613          	addi	a2,s1,44
    8000282e:	85da                	mv	a1,s6
    80002830:	05093503          	ld	a0,80(s2)
    80002834:	fffff097          	auipc	ra,0xfffff
    80002838:	fd0080e7          	jalr	-48(ra) # 80001804 <copyout>
    8000283c:	02054563          	bltz	a0,80002866 <waitx+0xbc>
          freeproc(np);
    80002840:	8526                	mv	a0,s1
    80002842:	fffff097          	auipc	ra,0xfffff
    80002846:	4f0080e7          	jalr	1264(ra) # 80001d32 <freeproc>
          release(&np->lock);
    8000284a:	8526                	mv	a0,s1
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	5be080e7          	jalr	1470(ra) # 80000e0a <release>
          release(&wait_lock);
    80002854:	0022e517          	auipc	a0,0x22e
    80002858:	36c50513          	addi	a0,a0,876 # 80230bc0 <wait_lock>
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	5ae080e7          	jalr	1454(ra) # 80000e0a <release>
          return pid;
    80002864:	a09d                	j	800028ca <waitx+0x120>
            release(&np->lock);
    80002866:	8526                	mv	a0,s1
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	5a2080e7          	jalr	1442(ra) # 80000e0a <release>
            release(&wait_lock);
    80002870:	0022e517          	auipc	a0,0x22e
    80002874:	35050513          	addi	a0,a0,848 # 80230bc0 <wait_lock>
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	592080e7          	jalr	1426(ra) # 80000e0a <release>
            return -1;
    80002880:	59fd                	li	s3,-1
    80002882:	a0a1                	j	800028ca <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002884:	17848493          	addi	s1,s1,376
    80002888:	03348463          	beq	s1,s3,800028b0 <waitx+0x106>
      if (np->parent == p)
    8000288c:	7c9c                	ld	a5,56(s1)
    8000288e:	ff279be3          	bne	a5,s2,80002884 <waitx+0xda>
        acquire(&np->lock);
    80002892:	8526                	mv	a0,s1
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	4c2080e7          	jalr	1218(ra) # 80000d56 <acquire>
        if (np->state == ZOMBIE)
    8000289c:	4c9c                	lw	a5,24(s1)
    8000289e:	f74785e3          	beq	a5,s4,80002808 <waitx+0x5e>
        release(&np->lock);
    800028a2:	8526                	mv	a0,s1
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	566080e7          	jalr	1382(ra) # 80000e0a <release>
        havekids = 1;
    800028ac:	8756                	mv	a4,s5
    800028ae:	bfd9                	j	80002884 <waitx+0xda>
    if (!havekids || p->killed)
    800028b0:	c701                	beqz	a4,800028b8 <waitx+0x10e>
    800028b2:	02892783          	lw	a5,40(s2)
    800028b6:	cb8d                	beqz	a5,800028e8 <waitx+0x13e>
      release(&wait_lock);
    800028b8:	0022e517          	auipc	a0,0x22e
    800028bc:	30850513          	addi	a0,a0,776 # 80230bc0 <wait_lock>
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	54a080e7          	jalr	1354(ra) # 80000e0a <release>
      return -1;
    800028c8:	59fd                	li	s3,-1
  }
}
    800028ca:	854e                	mv	a0,s3
    800028cc:	60e6                	ld	ra,88(sp)
    800028ce:	6446                	ld	s0,80(sp)
    800028d0:	64a6                	ld	s1,72(sp)
    800028d2:	6906                	ld	s2,64(sp)
    800028d4:	79e2                	ld	s3,56(sp)
    800028d6:	7a42                	ld	s4,48(sp)
    800028d8:	7aa2                	ld	s5,40(sp)
    800028da:	7b02                	ld	s6,32(sp)
    800028dc:	6be2                	ld	s7,24(sp)
    800028de:	6c42                	ld	s8,16(sp)
    800028e0:	6ca2                	ld	s9,8(sp)
    800028e2:	6d02                	ld	s10,0(sp)
    800028e4:	6125                	addi	sp,sp,96
    800028e6:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028e8:	85ea                	mv	a1,s10
    800028ea:	854a                	mv	a0,s2
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	950080e7          	jalr	-1712(ra) # 8000223c <sleep>
    havekids = 0;
    800028f4:	b721                	j	800027fc <waitx+0x52>

00000000800028f6 <update_time>:

void update_time()
{
    800028f6:	7179                	addi	sp,sp,-48
    800028f8:	f406                	sd	ra,40(sp)
    800028fa:	f022                	sd	s0,32(sp)
    800028fc:	ec26                	sd	s1,24(sp)
    800028fe:	e84a                	sd	s2,16(sp)
    80002900:	e44e                	sd	s3,8(sp)
    80002902:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002904:	0022e497          	auipc	s1,0x22e
    80002908:	6d448493          	addi	s1,s1,1748 # 80230fd8 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    8000290c:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    8000290e:	00234917          	auipc	s2,0x234
    80002912:	4ca90913          	addi	s2,s2,1226 # 80236dd8 <tickslock>
    80002916:	a811                	j	8000292a <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002918:	8526                	mv	a0,s1
    8000291a:	ffffe097          	auipc	ra,0xffffe
    8000291e:	4f0080e7          	jalr	1264(ra) # 80000e0a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002922:	17848493          	addi	s1,s1,376
    80002926:	03248063          	beq	s1,s2,80002946 <update_time+0x50>
    acquire(&p->lock);
    8000292a:	8526                	mv	a0,s1
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	42a080e7          	jalr	1066(ra) # 80000d56 <acquire>
    if (p->state == RUNNING)
    80002934:	4c9c                	lw	a5,24(s1)
    80002936:	ff3791e3          	bne	a5,s3,80002918 <update_time+0x22>
      p->rtime++;
    8000293a:	1684a783          	lw	a5,360(s1)
    8000293e:	2785                	addiw	a5,a5,1
    80002940:	16f4a423          	sw	a5,360(s1)
    80002944:	bfd1                	j	80002918 <update_time+0x22>
  }
    80002946:	70a2                	ld	ra,40(sp)
    80002948:	7402                	ld	s0,32(sp)
    8000294a:	64e2                	ld	s1,24(sp)
    8000294c:	6942                	ld	s2,16(sp)
    8000294e:	69a2                	ld	s3,8(sp)
    80002950:	6145                	addi	sp,sp,48
    80002952:	8082                	ret

0000000080002954 <swtch>:
    80002954:	00153023          	sd	ra,0(a0)
    80002958:	00253423          	sd	sp,8(a0)
    8000295c:	e900                	sd	s0,16(a0)
    8000295e:	ed04                	sd	s1,24(a0)
    80002960:	03253023          	sd	s2,32(a0)
    80002964:	03353423          	sd	s3,40(a0)
    80002968:	03453823          	sd	s4,48(a0)
    8000296c:	03553c23          	sd	s5,56(a0)
    80002970:	05653023          	sd	s6,64(a0)
    80002974:	05753423          	sd	s7,72(a0)
    80002978:	05853823          	sd	s8,80(a0)
    8000297c:	05953c23          	sd	s9,88(a0)
    80002980:	07a53023          	sd	s10,96(a0)
    80002984:	07b53423          	sd	s11,104(a0)
    80002988:	0005b083          	ld	ra,0(a1)
    8000298c:	0085b103          	ld	sp,8(a1)
    80002990:	6980                	ld	s0,16(a1)
    80002992:	6d84                	ld	s1,24(a1)
    80002994:	0205b903          	ld	s2,32(a1)
    80002998:	0285b983          	ld	s3,40(a1)
    8000299c:	0305ba03          	ld	s4,48(a1)
    800029a0:	0385ba83          	ld	s5,56(a1)
    800029a4:	0405bb03          	ld	s6,64(a1)
    800029a8:	0485bb83          	ld	s7,72(a1)
    800029ac:	0505bc03          	ld	s8,80(a1)
    800029b0:	0585bc83          	ld	s9,88(a1)
    800029b4:	0605bd03          	ld	s10,96(a1)
    800029b8:	0685bd83          	ld	s11,104(a1)
    800029bc:	8082                	ret

00000000800029be <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800029be:	1141                	addi	sp,sp,-16
    800029c0:	e406                	sd	ra,8(sp)
    800029c2:	e022                	sd	s0,0(sp)
    800029c4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029c6:	00006597          	auipc	a1,0x6
    800029ca:	98258593          	addi	a1,a1,-1662 # 80008348 <states.0+0x30>
    800029ce:	00234517          	auipc	a0,0x234
    800029d2:	40a50513          	addi	a0,a0,1034 # 80236dd8 <tickslock>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	2f0080e7          	jalr	752(ra) # 80000cc6 <initlock>
}
    800029de:	60a2                	ld	ra,8(sp)
    800029e0:	6402                	ld	s0,0(sp)
    800029e2:	0141                	addi	sp,sp,16
    800029e4:	8082                	ret

00000000800029e6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    800029e6:	1141                	addi	sp,sp,-16
    800029e8:	e422                	sd	s0,8(sp)
    800029ea:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ec:	00003797          	auipc	a5,0x3
    800029f0:	65478793          	addi	a5,a5,1620 # 80006040 <kernelvec>
    800029f4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029f8:	6422                	ld	s0,8(sp)
    800029fa:	0141                	addi	sp,sp,16
    800029fc:	8082                	ret

00000000800029fe <handle_page_fault>:

int handle_page_fault(void *faulting_address,pagetable_t pagetable)
{
    800029fe:	7179                	addi	sp,sp,-48
    80002a00:	f406                	sd	ra,40(sp)
    80002a02:	f022                	sd	s0,32(sp)
    80002a04:	ec26                	sd	s1,24(sp)
    80002a06:	e84a                	sd	s2,16(sp)
    80002a08:	e44e                	sd	s3,8(sp)
    80002a0a:	e052                	sd	s4,0(sp)
    80002a0c:	1800                	addi	s0,sp,48
    80002a0e:	84aa                	mv	s1,a0
    80002a10:	892e                	mv	s2,a1
  struct proc *current_proc=myproc();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	16e080e7          	jalr	366(ra) # 80001b80 <myproc>
  pte_t *pte;
  uint64 phy_addr;
  uint64 stack_pointer=current_proc->trapframe->sp;
    80002a1a:	6d38                	ld	a4,88(a0)
  int is_below_stack=((uint64)faulting_address>=PGROUNDDOWN(stack_pointer)-PGSIZE) && ((uint64)faulting_address<=PGROUNDDOWN(stack_pointer));
    80002a1c:	77fd                	lui	a5,0xfffff
    80002a1e:	7b18                	ld	a4,48(a4)
    80002a20:	8f7d                	and	a4,a4,a5
    80002a22:	86a6                	mv	a3,s1
    80002a24:	97ba                	add	a5,a5,a4
    80002a26:	00f4e563          	bltu	s1,a5,80002a30 <handle_page_fault+0x32>
  int is_invalid_address=(uint64)faulting_address>=MAXVA;
  if(is_invalid_address || is_below_stack){
    return -2; 
    80002a2a:	5579                	li	a0,-2
  int is_below_stack=((uint64)faulting_address>=PGROUNDDOWN(stack_pointer)-PGSIZE) && ((uint64)faulting_address<=PGROUNDDOWN(stack_pointer));
    80002a2c:	02977863          	bgeu	a4,s1,80002a5c <handle_page_fault+0x5e>
  if(is_invalid_address || is_below_stack){
    80002a30:	57fd                	li	a5,-1
    80002a32:	83e9                	srli	a5,a5,0x1a
    80002a34:	06d7ea63          	bltu	a5,a3,80002aa8 <handle_page_fault+0xaa>
  }
  uint64 virtual_addr=(uint64)faulting_address;
  faulting_address=(void *)PGROUNDDOWN(virtual_addr);
  pte=walk(pagetable, virtual_addr, 0);
    80002a38:	4601                	li	a2,0
    80002a3a:	85a6                	mv	a1,s1
    80002a3c:	854a                	mv	a0,s2
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	6f8080e7          	jalr	1784(ra) # 80001136 <walk>
    80002a46:	892a                	mv	s2,a0
  phy_addr=PTE2PA(*pte);
    80002a48:	611c                	ld	a5,0(a0)
    80002a4a:	00a7d493          	srli	s1,a5,0xa
    80002a4e:	04b2                	slli	s1,s1,0xc
  if(pte==0 || phy_addr==0){
    80002a50:	ccb1                	beqz	s1,80002aac <handle_page_fault+0xae>
    return -1; 
  }
  uint flags=PTE_FLAGS(*pte);
    80002a52:	0007871b          	sext.w	a4,a5
  int is_copy_on_write=flags & PTE_C;
    80002a56:	0207f513          	andi	a0,a5,32
  if(is_copy_on_write!=0){
    80002a5a:	e909                	bnez	a0,80002a6c <handle_page_fault+0x6e>
    memmove(new_memory,(void *)phy_addr,PGSIZE);
    *pte=PA2PTE(new_memory) | flags;
    kfree((void *)phy_addr);
  }
  return 0; 
}
    80002a5c:	70a2                	ld	ra,40(sp)
    80002a5e:	7402                	ld	s0,32(sp)
    80002a60:	64e2                	ld	s1,24(sp)
    80002a62:	6942                	ld	s2,16(sp)
    80002a64:	69a2                	ld	s3,8(sp)
    80002a66:	6a02                	ld	s4,0(sp)
    80002a68:	6145                	addi	sp,sp,48
    80002a6a:	8082                	ret
    flags=(flags | PTE_W) & (~PTE_C);
    80002a6c:	3df77713          	andi	a4,a4,991
    80002a70:	00476993          	ori	s3,a4,4
    char *new_memory=kalloc();
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	1e0080e7          	jalr	480(ra) # 80000c54 <kalloc>
    80002a7c:	8a2a                	mv	s4,a0
    if(new_memory==0){
    80002a7e:	c90d                	beqz	a0,80002ab0 <handle_page_fault+0xb2>
    memmove(new_memory,(void *)phy_addr,PGSIZE);
    80002a80:	6605                	lui	a2,0x1
    80002a82:	85a6                	mv	a1,s1
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	42a080e7          	jalr	1066(ra) # 80000eae <memmove>
    *pte=PA2PTE(new_memory) | flags;
    80002a8c:	00ca5713          	srli	a4,s4,0xc
    80002a90:	072a                	slli	a4,a4,0xa
    80002a92:	00e9e733          	or	a4,s3,a4
    80002a96:	00e93023          	sd	a4,0(s2)
    kfree((void *)phy_addr);
    80002a9a:	8526                	mv	a0,s1
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	094080e7          	jalr	148(ra) # 80000b30 <kfree>
  return 0; 
    80002aa4:	4501                	li	a0,0
    80002aa6:	bf5d                	j	80002a5c <handle_page_fault+0x5e>
    return -2; 
    80002aa8:	5579                	li	a0,-2
    80002aaa:	bf4d                	j	80002a5c <handle_page_fault+0x5e>
    return -1; 
    80002aac:	557d                	li	a0,-1
    80002aae:	b77d                	j	80002a5c <handle_page_fault+0x5e>
      return -1; 
    80002ab0:	557d                	li	a0,-1
    80002ab2:	b76d                	j	80002a5c <handle_page_fault+0x5e>

0000000080002ab4 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002ab4:	1141                	addi	sp,sp,-16
    80002ab6:	e406                	sd	ra,8(sp)
    80002ab8:	e022                	sd	s0,0(sp)
    80002aba:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	0c4080e7          	jalr	196(ra) # 80001b80 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ac8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aca:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002ace:	00004617          	auipc	a2,0x4
    80002ad2:	53260613          	addi	a2,a2,1330 # 80007000 <_trampoline>
    80002ad6:	00004697          	auipc	a3,0x4
    80002ada:	52a68693          	addi	a3,a3,1322 # 80007000 <_trampoline>
    80002ade:	8e91                	sub	a3,a3,a2
    80002ae0:	040007b7          	lui	a5,0x4000
    80002ae4:	17fd                	addi	a5,a5,-1
    80002ae6:	07b2                	slli	a5,a5,0xc
    80002ae8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aea:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002aee:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002af0:	180026f3          	csrr	a3,satp
    80002af4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002af6:	6d38                	ld	a4,88(a0)
    80002af8:	6134                	ld	a3,64(a0)
    80002afa:	6585                	lui	a1,0x1
    80002afc:	96ae                	add	a3,a3,a1
    80002afe:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b00:	6d38                	ld	a4,88(a0)
    80002b02:	00000697          	auipc	a3,0x0
    80002b06:	13e68693          	addi	a3,a3,318 # 80002c40 <usertrap>
    80002b0a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002b0c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b0e:	8692                	mv	a3,tp
    80002b10:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b12:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b16:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b1a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b1e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b22:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b24:	6f18                	ld	a4,24(a4)
    80002b26:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b2a:	6928                	ld	a0,80(a0)
    80002b2c:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b2e:	00004717          	auipc	a4,0x4
    80002b32:	56e70713          	addi	a4,a4,1390 # 8000709c <userret>
    80002b36:	8f11                	sub	a4,a4,a2
    80002b38:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b3a:	577d                	li	a4,-1
    80002b3c:	177e                	slli	a4,a4,0x3f
    80002b3e:	8d59                	or	a0,a0,a4
    80002b40:	9782                	jalr	a5
}
    80002b42:	60a2                	ld	ra,8(sp)
    80002b44:	6402                	ld	s0,0(sp)
    80002b46:	0141                	addi	sp,sp,16
    80002b48:	8082                	ret

0000000080002b4a <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002b4a:	1101                	addi	sp,sp,-32
    80002b4c:	ec06                	sd	ra,24(sp)
    80002b4e:	e822                	sd	s0,16(sp)
    80002b50:	e426                	sd	s1,8(sp)
    80002b52:	e04a                	sd	s2,0(sp)
    80002b54:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b56:	00234917          	auipc	s2,0x234
    80002b5a:	28290913          	addi	s2,s2,642 # 80236dd8 <tickslock>
    80002b5e:	854a                	mv	a0,s2
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	1f6080e7          	jalr	502(ra) # 80000d56 <acquire>
  ticks++;
    80002b68:	00006497          	auipc	s1,0x6
    80002b6c:	db848493          	addi	s1,s1,-584 # 80008920 <ticks>
    80002b70:	409c                	lw	a5,0(s1)
    80002b72:	2785                	addiw	a5,a5,1
    80002b74:	c09c                	sw	a5,0(s1)
  update_time();
    80002b76:	00000097          	auipc	ra,0x0
    80002b7a:	d80080e7          	jalr	-640(ra) # 800028f6 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002b7e:	8526                	mv	a0,s1
    80002b80:	fffff097          	auipc	ra,0xfffff
    80002b84:	720080e7          	jalr	1824(ra) # 800022a0 <wakeup>
  release(&tickslock);
    80002b88:	854a                	mv	a0,s2
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	280080e7          	jalr	640(ra) # 80000e0a <release>
}
    80002b92:	60e2                	ld	ra,24(sp)
    80002b94:	6442                	ld	s0,16(sp)
    80002b96:	64a2                	ld	s1,8(sp)
    80002b98:	6902                	ld	s2,0(sp)
    80002b9a:	6105                	addi	sp,sp,32
    80002b9c:	8082                	ret

0000000080002b9e <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002b9e:	1101                	addi	sp,sp,-32
    80002ba0:	ec06                	sd	ra,24(sp)
    80002ba2:	e822                	sd	s0,16(sp)
    80002ba4:	e426                	sd	s1,8(sp)
    80002ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ba8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002bac:	00074d63          	bltz	a4,80002bc6 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002bb0:	57fd                	li	a5,-1
    80002bb2:	17fe                	slli	a5,a5,0x3f
    80002bb4:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002bb6:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002bb8:	06f70363          	beq	a4,a5,80002c1e <devintr+0x80>
  }
}
    80002bbc:	60e2                	ld	ra,24(sp)
    80002bbe:	6442                	ld	s0,16(sp)
    80002bc0:	64a2                	ld	s1,8(sp)
    80002bc2:	6105                	addi	sp,sp,32
    80002bc4:	8082                	ret
      (scause & 0xff) == 9)
    80002bc6:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002bca:	46a5                	li	a3,9
    80002bcc:	fed792e3          	bne	a5,a3,80002bb0 <devintr+0x12>
    int irq = plic_claim();
    80002bd0:	00003097          	auipc	ra,0x3
    80002bd4:	578080e7          	jalr	1400(ra) # 80006148 <plic_claim>
    80002bd8:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002bda:	47a9                	li	a5,10
    80002bdc:	02f50763          	beq	a0,a5,80002c0a <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002be0:	4785                	li	a5,1
    80002be2:	02f50963          	beq	a0,a5,80002c14 <devintr+0x76>
    return 1;
    80002be6:	4505                	li	a0,1
    else if (irq)
    80002be8:	d8f1                	beqz	s1,80002bbc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bea:	85a6                	mv	a1,s1
    80002bec:	00005517          	auipc	a0,0x5
    80002bf0:	76450513          	addi	a0,a0,1892 # 80008350 <states.0+0x38>
    80002bf4:	ffffe097          	auipc	ra,0xffffe
    80002bf8:	994080e7          	jalr	-1644(ra) # 80000588 <printf>
      plic_complete(irq);
    80002bfc:	8526                	mv	a0,s1
    80002bfe:	00003097          	auipc	ra,0x3
    80002c02:	56e080e7          	jalr	1390(ra) # 8000616c <plic_complete>
    return 1;
    80002c06:	4505                	li	a0,1
    80002c08:	bf55                	j	80002bbc <devintr+0x1e>
      uartintr();
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	d90080e7          	jalr	-624(ra) # 8000099a <uartintr>
    80002c12:	b7ed                	j	80002bfc <devintr+0x5e>
      virtio_disk_intr();
    80002c14:	00004097          	auipc	ra,0x4
    80002c18:	a24080e7          	jalr	-1500(ra) # 80006638 <virtio_disk_intr>
    80002c1c:	b7c5                	j	80002bfc <devintr+0x5e>
    if (cpuid() == 0)
    80002c1e:	fffff097          	auipc	ra,0xfffff
    80002c22:	f36080e7          	jalr	-202(ra) # 80001b54 <cpuid>
    80002c26:	c901                	beqz	a0,80002c36 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c28:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c2c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c2e:	14479073          	csrw	sip,a5
    return 2;
    80002c32:	4509                	li	a0,2
    80002c34:	b761                	j	80002bbc <devintr+0x1e>
      clockintr();
    80002c36:	00000097          	auipc	ra,0x0
    80002c3a:	f14080e7          	jalr	-236(ra) # 80002b4a <clockintr>
    80002c3e:	b7ed                	j	80002c28 <devintr+0x8a>

0000000080002c40 <usertrap>:
{
    80002c40:	1101                	addi	sp,sp,-32
    80002c42:	ec06                	sd	ra,24(sp)
    80002c44:	e822                	sd	s0,16(sp)
    80002c46:	e426                	sd	s1,8(sp)
    80002c48:	e04a                	sd	s2,0(sp)
    80002c4a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c4c:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002c50:	1007f793          	andi	a5,a5,256
    80002c54:	efa5                	bnez	a5,80002ccc <usertrap+0x8c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c56:	00003797          	auipc	a5,0x3
    80002c5a:	3ea78793          	addi	a5,a5,1002 # 80006040 <kernelvec>
    80002c5e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	f1e080e7          	jalr	-226(ra) # 80001b80 <myproc>
    80002c6a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c6c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c6e:	14102773          	csrr	a4,sepc
    80002c72:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c74:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002c78:	47a1                	li	a5,8
    80002c7a:	06f70163          	beq	a4,a5,80002cdc <usertrap+0x9c>
    80002c7e:	14202773          	csrr	a4,scause
  else if(r_scause()==15 || r_scause()==13){
    80002c82:	47bd                	li	a5,15
    80002c84:	00f70763          	beq	a4,a5,80002c92 <usertrap+0x52>
    80002c88:	14202773          	csrr	a4,scause
    80002c8c:	47b5                	li	a5,13
    80002c8e:	08f71763          	bne	a4,a5,80002d1c <usertrap+0xdc>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c92:	14302573          	csrr	a0,stval
    int value=handle_page_fault((void *)r_stval(),p->pagetable);
    80002c96:	68ac                	ld	a1,80(s1)
    80002c98:	00000097          	auipc	ra,0x0
    80002c9c:	d66080e7          	jalr	-666(ra) # 800029fe <handle_page_fault>
    if(value==-1){
    80002ca0:	57fd                	li	a5,-1
    80002ca2:	06f50763          	beq	a0,a5,80002d10 <usertrap+0xd0>
    else if(value==-2){
    80002ca6:	57f9                	li	a5,-2
    80002ca8:	06f50763          	beq	a0,a5,80002d16 <usertrap+0xd6>
  if (killed(p))
    80002cac:	8526                	mv	a0,s1
    80002cae:	00000097          	auipc	ra,0x0
    80002cb2:	842080e7          	jalr	-1982(ra) # 800024f0 <killed>
    80002cb6:	ed4d                	bnez	a0,80002d70 <usertrap+0x130>
  usertrapret();
    80002cb8:	00000097          	auipc	ra,0x0
    80002cbc:	dfc080e7          	jalr	-516(ra) # 80002ab4 <usertrapret>
}
    80002cc0:	60e2                	ld	ra,24(sp)
    80002cc2:	6442                	ld	s0,16(sp)
    80002cc4:	64a2                	ld	s1,8(sp)
    80002cc6:	6902                	ld	s2,0(sp)
    80002cc8:	6105                	addi	sp,sp,32
    80002cca:	8082                	ret
    panic("usertrap: not from user mode");
    80002ccc:	00005517          	auipc	a0,0x5
    80002cd0:	6a450513          	addi	a0,a0,1700 # 80008370 <states.0+0x58>
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	86a080e7          	jalr	-1942(ra) # 8000053e <panic>
    if (killed(p))
    80002cdc:	00000097          	auipc	ra,0x0
    80002ce0:	814080e7          	jalr	-2028(ra) # 800024f0 <killed>
    80002ce4:	e105                	bnez	a0,80002d04 <usertrap+0xc4>
    p->trapframe->epc += 4;
    80002ce6:	6cb8                	ld	a4,88(s1)
    80002ce8:	6f1c                	ld	a5,24(a4)
    80002cea:	0791                	addi	a5,a5,4
    80002cec:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cf2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cf6:	10079073          	csrw	sstatus,a5
    syscall();
    80002cfa:	00000097          	auipc	ra,0x0
    80002cfe:	2dc080e7          	jalr	732(ra) # 80002fd6 <syscall>
    80002d02:	b76d                	j	80002cac <usertrap+0x6c>
      exit(-1);
    80002d04:	557d                	li	a0,-1
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	66a080e7          	jalr	1642(ra) # 80002370 <exit>
    80002d0e:	bfe1                	j	80002ce6 <usertrap+0xa6>
      p->killed=1;
    80002d10:	4785                	li	a5,1
    80002d12:	d49c                	sw	a5,40(s1)
    80002d14:	bf61                	j	80002cac <usertrap+0x6c>
      p->killed=1;
    80002d16:	4785                	li	a5,1
    80002d18:	d49c                	sw	a5,40(s1)
    80002d1a:	bf49                	j	80002cac <usertrap+0x6c>
  else if ((which_dev = devintr()) != 0)
    80002d1c:	00000097          	auipc	ra,0x0
    80002d20:	e82080e7          	jalr	-382(ra) # 80002b9e <devintr>
    80002d24:	892a                	mv	s2,a0
    80002d26:	c901                	beqz	a0,80002d36 <usertrap+0xf6>
  if (killed(p))
    80002d28:	8526                	mv	a0,s1
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	7c6080e7          	jalr	1990(ra) # 800024f0 <killed>
    80002d32:	c529                	beqz	a0,80002d7c <usertrap+0x13c>
    80002d34:	a83d                	j	80002d72 <usertrap+0x132>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d36:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d3a:	5890                	lw	a2,48(s1)
    80002d3c:	00005517          	auipc	a0,0x5
    80002d40:	65450513          	addi	a0,a0,1620 # 80008390 <states.0+0x78>
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	844080e7          	jalr	-1980(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d4c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d50:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d54:	00005517          	auipc	a0,0x5
    80002d58:	66c50513          	addi	a0,a0,1644 # 800083c0 <states.0+0xa8>
    80002d5c:	ffffe097          	auipc	ra,0xffffe
    80002d60:	82c080e7          	jalr	-2004(ra) # 80000588 <printf>
    setkilled(p);
    80002d64:	8526                	mv	a0,s1
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	75e080e7          	jalr	1886(ra) # 800024c4 <setkilled>
    80002d6e:	bf3d                	j	80002cac <usertrap+0x6c>
  if (killed(p))
    80002d70:	4901                	li	s2,0
    exit(-1);
    80002d72:	557d                	li	a0,-1
    80002d74:	fffff097          	auipc	ra,0xfffff
    80002d78:	5fc080e7          	jalr	1532(ra) # 80002370 <exit>
  if (which_dev == 2)
    80002d7c:	4789                	li	a5,2
    80002d7e:	f2f91de3          	bne	s2,a5,80002cb8 <usertrap+0x78>
    yield();
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	47e080e7          	jalr	1150(ra) # 80002200 <yield>
    80002d8a:	b73d                	j	80002cb8 <usertrap+0x78>

0000000080002d8c <kerneltrap>:
{
    80002d8c:	7179                	addi	sp,sp,-48
    80002d8e:	f406                	sd	ra,40(sp)
    80002d90:	f022                	sd	s0,32(sp)
    80002d92:	ec26                	sd	s1,24(sp)
    80002d94:	e84a                	sd	s2,16(sp)
    80002d96:	e44e                	sd	s3,8(sp)
    80002d98:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d9a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d9e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002da2:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002da6:	1004f793          	andi	a5,s1,256
    80002daa:	cb85                	beqz	a5,80002dda <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002db0:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002db2:	ef85                	bnez	a5,80002dea <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002db4:	00000097          	auipc	ra,0x0
    80002db8:	dea080e7          	jalr	-534(ra) # 80002b9e <devintr>
    80002dbc:	cd1d                	beqz	a0,80002dfa <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002dbe:	4789                	li	a5,2
    80002dc0:	06f50a63          	beq	a0,a5,80002e34 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dc4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dc8:	10049073          	csrw	sstatus,s1
}
    80002dcc:	70a2                	ld	ra,40(sp)
    80002dce:	7402                	ld	s0,32(sp)
    80002dd0:	64e2                	ld	s1,24(sp)
    80002dd2:	6942                	ld	s2,16(sp)
    80002dd4:	69a2                	ld	s3,8(sp)
    80002dd6:	6145                	addi	sp,sp,48
    80002dd8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002dda:	00005517          	auipc	a0,0x5
    80002dde:	60650513          	addi	a0,a0,1542 # 800083e0 <states.0+0xc8>
    80002de2:	ffffd097          	auipc	ra,0xffffd
    80002de6:	75c080e7          	jalr	1884(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002dea:	00005517          	auipc	a0,0x5
    80002dee:	61e50513          	addi	a0,a0,1566 # 80008408 <states.0+0xf0>
    80002df2:	ffffd097          	auipc	ra,0xffffd
    80002df6:	74c080e7          	jalr	1868(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002dfa:	85ce                	mv	a1,s3
    80002dfc:	00005517          	auipc	a0,0x5
    80002e00:	62c50513          	addi	a0,a0,1580 # 80008428 <states.0+0x110>
    80002e04:	ffffd097          	auipc	ra,0xffffd
    80002e08:	784080e7          	jalr	1924(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e0c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e10:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e14:	00005517          	auipc	a0,0x5
    80002e18:	62450513          	addi	a0,a0,1572 # 80008438 <states.0+0x120>
    80002e1c:	ffffd097          	auipc	ra,0xffffd
    80002e20:	76c080e7          	jalr	1900(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002e24:	00005517          	auipc	a0,0x5
    80002e28:	62c50513          	addi	a0,a0,1580 # 80008450 <states.0+0x138>
    80002e2c:	ffffd097          	auipc	ra,0xffffd
    80002e30:	712080e7          	jalr	1810(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e34:	fffff097          	auipc	ra,0xfffff
    80002e38:	d4c080e7          	jalr	-692(ra) # 80001b80 <myproc>
    80002e3c:	d541                	beqz	a0,80002dc4 <kerneltrap+0x38>
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	d42080e7          	jalr	-702(ra) # 80001b80 <myproc>
    80002e46:	4d18                	lw	a4,24(a0)
    80002e48:	4791                	li	a5,4
    80002e4a:	f6f71de3          	bne	a4,a5,80002dc4 <kerneltrap+0x38>
    yield();
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	3b2080e7          	jalr	946(ra) # 80002200 <yield>
    80002e56:	b7bd                	j	80002dc4 <kerneltrap+0x38>

0000000080002e58 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e58:	1101                	addi	sp,sp,-32
    80002e5a:	ec06                	sd	ra,24(sp)
    80002e5c:	e822                	sd	s0,16(sp)
    80002e5e:	e426                	sd	s1,8(sp)
    80002e60:	1000                	addi	s0,sp,32
    80002e62:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	d1c080e7          	jalr	-740(ra) # 80001b80 <myproc>
  switch (n) {
    80002e6c:	4795                	li	a5,5
    80002e6e:	0497e163          	bltu	a5,s1,80002eb0 <argraw+0x58>
    80002e72:	048a                	slli	s1,s1,0x2
    80002e74:	00005717          	auipc	a4,0x5
    80002e78:	61470713          	addi	a4,a4,1556 # 80008488 <states.0+0x170>
    80002e7c:	94ba                	add	s1,s1,a4
    80002e7e:	409c                	lw	a5,0(s1)
    80002e80:	97ba                	add	a5,a5,a4
    80002e82:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e84:	6d3c                	ld	a5,88(a0)
    80002e86:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e88:	60e2                	ld	ra,24(sp)
    80002e8a:	6442                	ld	s0,16(sp)
    80002e8c:	64a2                	ld	s1,8(sp)
    80002e8e:	6105                	addi	sp,sp,32
    80002e90:	8082                	ret
    return p->trapframe->a1;
    80002e92:	6d3c                	ld	a5,88(a0)
    80002e94:	7fa8                	ld	a0,120(a5)
    80002e96:	bfcd                	j	80002e88 <argraw+0x30>
    return p->trapframe->a2;
    80002e98:	6d3c                	ld	a5,88(a0)
    80002e9a:	63c8                	ld	a0,128(a5)
    80002e9c:	b7f5                	j	80002e88 <argraw+0x30>
    return p->trapframe->a3;
    80002e9e:	6d3c                	ld	a5,88(a0)
    80002ea0:	67c8                	ld	a0,136(a5)
    80002ea2:	b7dd                	j	80002e88 <argraw+0x30>
    return p->trapframe->a4;
    80002ea4:	6d3c                	ld	a5,88(a0)
    80002ea6:	6bc8                	ld	a0,144(a5)
    80002ea8:	b7c5                	j	80002e88 <argraw+0x30>
    return p->trapframe->a5;
    80002eaa:	6d3c                	ld	a5,88(a0)
    80002eac:	6fc8                	ld	a0,152(a5)
    80002eae:	bfe9                	j	80002e88 <argraw+0x30>
  panic("argraw");
    80002eb0:	00005517          	auipc	a0,0x5
    80002eb4:	5b050513          	addi	a0,a0,1456 # 80008460 <states.0+0x148>
    80002eb8:	ffffd097          	auipc	ra,0xffffd
    80002ebc:	686080e7          	jalr	1670(ra) # 8000053e <panic>

0000000080002ec0 <fetchaddr>:
{
    80002ec0:	1101                	addi	sp,sp,-32
    80002ec2:	ec06                	sd	ra,24(sp)
    80002ec4:	e822                	sd	s0,16(sp)
    80002ec6:	e426                	sd	s1,8(sp)
    80002ec8:	e04a                	sd	s2,0(sp)
    80002eca:	1000                	addi	s0,sp,32
    80002ecc:	84aa                	mv	s1,a0
    80002ece:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ed0:	fffff097          	auipc	ra,0xfffff
    80002ed4:	cb0080e7          	jalr	-848(ra) # 80001b80 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ed8:	653c                	ld	a5,72(a0)
    80002eda:	02f4f863          	bgeu	s1,a5,80002f0a <fetchaddr+0x4a>
    80002ede:	00848713          	addi	a4,s1,8
    80002ee2:	02e7e663          	bltu	a5,a4,80002f0e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ee6:	46a1                	li	a3,8
    80002ee8:	8626                	mv	a2,s1
    80002eea:	85ca                	mv	a1,s2
    80002eec:	6928                	ld	a0,80(a0)
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	9da080e7          	jalr	-1574(ra) # 800018c8 <copyin>
    80002ef6:	00a03533          	snez	a0,a0
    80002efa:	40a00533          	neg	a0,a0
}
    80002efe:	60e2                	ld	ra,24(sp)
    80002f00:	6442                	ld	s0,16(sp)
    80002f02:	64a2                	ld	s1,8(sp)
    80002f04:	6902                	ld	s2,0(sp)
    80002f06:	6105                	addi	sp,sp,32
    80002f08:	8082                	ret
    return -1;
    80002f0a:	557d                	li	a0,-1
    80002f0c:	bfcd                	j	80002efe <fetchaddr+0x3e>
    80002f0e:	557d                	li	a0,-1
    80002f10:	b7fd                	j	80002efe <fetchaddr+0x3e>

0000000080002f12 <fetchstr>:
{
    80002f12:	7179                	addi	sp,sp,-48
    80002f14:	f406                	sd	ra,40(sp)
    80002f16:	f022                	sd	s0,32(sp)
    80002f18:	ec26                	sd	s1,24(sp)
    80002f1a:	e84a                	sd	s2,16(sp)
    80002f1c:	e44e                	sd	s3,8(sp)
    80002f1e:	1800                	addi	s0,sp,48
    80002f20:	892a                	mv	s2,a0
    80002f22:	84ae                	mv	s1,a1
    80002f24:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	c5a080e7          	jalr	-934(ra) # 80001b80 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002f2e:	86ce                	mv	a3,s3
    80002f30:	864a                	mv	a2,s2
    80002f32:	85a6                	mv	a1,s1
    80002f34:	6928                	ld	a0,80(a0)
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	a20080e7          	jalr	-1504(ra) # 80001956 <copyinstr>
    80002f3e:	00054e63          	bltz	a0,80002f5a <fetchstr+0x48>
  return strlen(buf);
    80002f42:	8526                	mv	a0,s1
    80002f44:	ffffe097          	auipc	ra,0xffffe
    80002f48:	08a080e7          	jalr	138(ra) # 80000fce <strlen>
}
    80002f4c:	70a2                	ld	ra,40(sp)
    80002f4e:	7402                	ld	s0,32(sp)
    80002f50:	64e2                	ld	s1,24(sp)
    80002f52:	6942                	ld	s2,16(sp)
    80002f54:	69a2                	ld	s3,8(sp)
    80002f56:	6145                	addi	sp,sp,48
    80002f58:	8082                	ret
    return -1;
    80002f5a:	557d                	li	a0,-1
    80002f5c:	bfc5                	j	80002f4c <fetchstr+0x3a>

0000000080002f5e <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002f5e:	1101                	addi	sp,sp,-32
    80002f60:	ec06                	sd	ra,24(sp)
    80002f62:	e822                	sd	s0,16(sp)
    80002f64:	e426                	sd	s1,8(sp)
    80002f66:	1000                	addi	s0,sp,32
    80002f68:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f6a:	00000097          	auipc	ra,0x0
    80002f6e:	eee080e7          	jalr	-274(ra) # 80002e58 <argraw>
    80002f72:	c088                	sw	a0,0(s1)
}
    80002f74:	60e2                	ld	ra,24(sp)
    80002f76:	6442                	ld	s0,16(sp)
    80002f78:	64a2                	ld	s1,8(sp)
    80002f7a:	6105                	addi	sp,sp,32
    80002f7c:	8082                	ret

0000000080002f7e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002f7e:	1101                	addi	sp,sp,-32
    80002f80:	ec06                	sd	ra,24(sp)
    80002f82:	e822                	sd	s0,16(sp)
    80002f84:	e426                	sd	s1,8(sp)
    80002f86:	1000                	addi	s0,sp,32
    80002f88:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f8a:	00000097          	auipc	ra,0x0
    80002f8e:	ece080e7          	jalr	-306(ra) # 80002e58 <argraw>
    80002f92:	e088                	sd	a0,0(s1)
}
    80002f94:	60e2                	ld	ra,24(sp)
    80002f96:	6442                	ld	s0,16(sp)
    80002f98:	64a2                	ld	s1,8(sp)
    80002f9a:	6105                	addi	sp,sp,32
    80002f9c:	8082                	ret

0000000080002f9e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f9e:	7179                	addi	sp,sp,-48
    80002fa0:	f406                	sd	ra,40(sp)
    80002fa2:	f022                	sd	s0,32(sp)
    80002fa4:	ec26                	sd	s1,24(sp)
    80002fa6:	e84a                	sd	s2,16(sp)
    80002fa8:	1800                	addi	s0,sp,48
    80002faa:	84ae                	mv	s1,a1
    80002fac:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002fae:	fd840593          	addi	a1,s0,-40
    80002fb2:	00000097          	auipc	ra,0x0
    80002fb6:	fcc080e7          	jalr	-52(ra) # 80002f7e <argaddr>
  return fetchstr(addr, buf, max);
    80002fba:	864a                	mv	a2,s2
    80002fbc:	85a6                	mv	a1,s1
    80002fbe:	fd843503          	ld	a0,-40(s0)
    80002fc2:	00000097          	auipc	ra,0x0
    80002fc6:	f50080e7          	jalr	-176(ra) # 80002f12 <fetchstr>
}
    80002fca:	70a2                	ld	ra,40(sp)
    80002fcc:	7402                	ld	s0,32(sp)
    80002fce:	64e2                	ld	s1,24(sp)
    80002fd0:	6942                	ld	s2,16(sp)
    80002fd2:	6145                	addi	sp,sp,48
    80002fd4:	8082                	ret

0000000080002fd6 <syscall>:
[SYS_waitx]   sys_waitx,
};

void
syscall(void)
{
    80002fd6:	1101                	addi	sp,sp,-32
    80002fd8:	ec06                	sd	ra,24(sp)
    80002fda:	e822                	sd	s0,16(sp)
    80002fdc:	e426                	sd	s1,8(sp)
    80002fde:	e04a                	sd	s2,0(sp)
    80002fe0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002fe2:	fffff097          	auipc	ra,0xfffff
    80002fe6:	b9e080e7          	jalr	-1122(ra) # 80001b80 <myproc>
    80002fea:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fec:	05853903          	ld	s2,88(a0)
    80002ff0:	0a893783          	ld	a5,168(s2)
    80002ff4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ff8:	37fd                	addiw	a5,a5,-1
    80002ffa:	4755                	li	a4,21
    80002ffc:	00f76f63          	bltu	a4,a5,8000301a <syscall+0x44>
    80003000:	00369713          	slli	a4,a3,0x3
    80003004:	00005797          	auipc	a5,0x5
    80003008:	49c78793          	addi	a5,a5,1180 # 800084a0 <syscalls>
    8000300c:	97ba                	add	a5,a5,a4
    8000300e:	639c                	ld	a5,0(a5)
    80003010:	c789                	beqz	a5,8000301a <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003012:	9782                	jalr	a5
    80003014:	06a93823          	sd	a0,112(s2)
    80003018:	a839                	j	80003036 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000301a:	15848613          	addi	a2,s1,344
    8000301e:	588c                	lw	a1,48(s1)
    80003020:	00005517          	auipc	a0,0x5
    80003024:	44850513          	addi	a0,a0,1096 # 80008468 <states.0+0x150>
    80003028:	ffffd097          	auipc	ra,0xffffd
    8000302c:	560080e7          	jalr	1376(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003030:	6cbc                	ld	a5,88(s1)
    80003032:	577d                	li	a4,-1
    80003034:	fbb8                	sd	a4,112(a5)
  }
}
    80003036:	60e2                	ld	ra,24(sp)
    80003038:	6442                	ld	s0,16(sp)
    8000303a:	64a2                	ld	s1,8(sp)
    8000303c:	6902                	ld	s2,0(sp)
    8000303e:	6105                	addi	sp,sp,32
    80003040:	8082                	ret

0000000080003042 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003042:	1101                	addi	sp,sp,-32
    80003044:	ec06                	sd	ra,24(sp)
    80003046:	e822                	sd	s0,16(sp)
    80003048:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000304a:	fec40593          	addi	a1,s0,-20
    8000304e:	4501                	li	a0,0
    80003050:	00000097          	auipc	ra,0x0
    80003054:	f0e080e7          	jalr	-242(ra) # 80002f5e <argint>
  exit(n);
    80003058:	fec42503          	lw	a0,-20(s0)
    8000305c:	fffff097          	auipc	ra,0xfffff
    80003060:	314080e7          	jalr	788(ra) # 80002370 <exit>
  return 0; // not reached
}
    80003064:	4501                	li	a0,0
    80003066:	60e2                	ld	ra,24(sp)
    80003068:	6442                	ld	s0,16(sp)
    8000306a:	6105                	addi	sp,sp,32
    8000306c:	8082                	ret

000000008000306e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000306e:	1141                	addi	sp,sp,-16
    80003070:	e406                	sd	ra,8(sp)
    80003072:	e022                	sd	s0,0(sp)
    80003074:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003076:	fffff097          	auipc	ra,0xfffff
    8000307a:	b0a080e7          	jalr	-1270(ra) # 80001b80 <myproc>
}
    8000307e:	5908                	lw	a0,48(a0)
    80003080:	60a2                	ld	ra,8(sp)
    80003082:	6402                	ld	s0,0(sp)
    80003084:	0141                	addi	sp,sp,16
    80003086:	8082                	ret

0000000080003088 <sys_fork>:

uint64
sys_fork(void)
{
    80003088:	1141                	addi	sp,sp,-16
    8000308a:	e406                	sd	ra,8(sp)
    8000308c:	e022                	sd	s0,0(sp)
    8000308e:	0800                	addi	s0,sp,16
  return fork();
    80003090:	fffff097          	auipc	ra,0xfffff
    80003094:	eba080e7          	jalr	-326(ra) # 80001f4a <fork>
}
    80003098:	60a2                	ld	ra,8(sp)
    8000309a:	6402                	ld	s0,0(sp)
    8000309c:	0141                	addi	sp,sp,16
    8000309e:	8082                	ret

00000000800030a0 <sys_wait>:

uint64
sys_wait(void)
{
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800030a8:	fe840593          	addi	a1,s0,-24
    800030ac:	4501                	li	a0,0
    800030ae:	00000097          	auipc	ra,0x0
    800030b2:	ed0080e7          	jalr	-304(ra) # 80002f7e <argaddr>
  return wait(p);
    800030b6:	fe843503          	ld	a0,-24(s0)
    800030ba:	fffff097          	auipc	ra,0xfffff
    800030be:	468080e7          	jalr	1128(ra) # 80002522 <wait>
}
    800030c2:	60e2                	ld	ra,24(sp)
    800030c4:	6442                	ld	s0,16(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret

00000000800030ca <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800030ca:	7179                	addi	sp,sp,-48
    800030cc:	f406                	sd	ra,40(sp)
    800030ce:	f022                	sd	s0,32(sp)
    800030d0:	ec26                	sd	s1,24(sp)
    800030d2:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800030d4:	fdc40593          	addi	a1,s0,-36
    800030d8:	4501                	li	a0,0
    800030da:	00000097          	auipc	ra,0x0
    800030de:	e84080e7          	jalr	-380(ra) # 80002f5e <argint>
  addr = myproc()->sz;
    800030e2:	fffff097          	auipc	ra,0xfffff
    800030e6:	a9e080e7          	jalr	-1378(ra) # 80001b80 <myproc>
    800030ea:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800030ec:	fdc42503          	lw	a0,-36(s0)
    800030f0:	fffff097          	auipc	ra,0xfffff
    800030f4:	dfe080e7          	jalr	-514(ra) # 80001eee <growproc>
    800030f8:	00054863          	bltz	a0,80003108 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800030fc:	8526                	mv	a0,s1
    800030fe:	70a2                	ld	ra,40(sp)
    80003100:	7402                	ld	s0,32(sp)
    80003102:	64e2                	ld	s1,24(sp)
    80003104:	6145                	addi	sp,sp,48
    80003106:	8082                	ret
    return -1;
    80003108:	54fd                	li	s1,-1
    8000310a:	bfcd                	j	800030fc <sys_sbrk+0x32>

000000008000310c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000310c:	7139                	addi	sp,sp,-64
    8000310e:	fc06                	sd	ra,56(sp)
    80003110:	f822                	sd	s0,48(sp)
    80003112:	f426                	sd	s1,40(sp)
    80003114:	f04a                	sd	s2,32(sp)
    80003116:	ec4e                	sd	s3,24(sp)
    80003118:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000311a:	fcc40593          	addi	a1,s0,-52
    8000311e:	4501                	li	a0,0
    80003120:	00000097          	auipc	ra,0x0
    80003124:	e3e080e7          	jalr	-450(ra) # 80002f5e <argint>
  acquire(&tickslock);
    80003128:	00234517          	auipc	a0,0x234
    8000312c:	cb050513          	addi	a0,a0,-848 # 80236dd8 <tickslock>
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	c26080e7          	jalr	-986(ra) # 80000d56 <acquire>
  ticks0 = ticks;
    80003138:	00005917          	auipc	s2,0x5
    8000313c:	7e892903          	lw	s2,2024(s2) # 80008920 <ticks>
  while (ticks - ticks0 < n)
    80003140:	fcc42783          	lw	a5,-52(s0)
    80003144:	cf9d                	beqz	a5,80003182 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003146:	00234997          	auipc	s3,0x234
    8000314a:	c9298993          	addi	s3,s3,-878 # 80236dd8 <tickslock>
    8000314e:	00005497          	auipc	s1,0x5
    80003152:	7d248493          	addi	s1,s1,2002 # 80008920 <ticks>
    if (killed(myproc()))
    80003156:	fffff097          	auipc	ra,0xfffff
    8000315a:	a2a080e7          	jalr	-1494(ra) # 80001b80 <myproc>
    8000315e:	fffff097          	auipc	ra,0xfffff
    80003162:	392080e7          	jalr	914(ra) # 800024f0 <killed>
    80003166:	ed15                	bnez	a0,800031a2 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003168:	85ce                	mv	a1,s3
    8000316a:	8526                	mv	a0,s1
    8000316c:	fffff097          	auipc	ra,0xfffff
    80003170:	0d0080e7          	jalr	208(ra) # 8000223c <sleep>
  while (ticks - ticks0 < n)
    80003174:	409c                	lw	a5,0(s1)
    80003176:	412787bb          	subw	a5,a5,s2
    8000317a:	fcc42703          	lw	a4,-52(s0)
    8000317e:	fce7ece3          	bltu	a5,a4,80003156 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003182:	00234517          	auipc	a0,0x234
    80003186:	c5650513          	addi	a0,a0,-938 # 80236dd8 <tickslock>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	c80080e7          	jalr	-896(ra) # 80000e0a <release>
  return 0;
    80003192:	4501                	li	a0,0
}
    80003194:	70e2                	ld	ra,56(sp)
    80003196:	7442                	ld	s0,48(sp)
    80003198:	74a2                	ld	s1,40(sp)
    8000319a:	7902                	ld	s2,32(sp)
    8000319c:	69e2                	ld	s3,24(sp)
    8000319e:	6121                	addi	sp,sp,64
    800031a0:	8082                	ret
      release(&tickslock);
    800031a2:	00234517          	auipc	a0,0x234
    800031a6:	c3650513          	addi	a0,a0,-970 # 80236dd8 <tickslock>
    800031aa:	ffffe097          	auipc	ra,0xffffe
    800031ae:	c60080e7          	jalr	-928(ra) # 80000e0a <release>
      return -1;
    800031b2:	557d                	li	a0,-1
    800031b4:	b7c5                	j	80003194 <sys_sleep+0x88>

00000000800031b6 <sys_kill>:

uint64
sys_kill(void)
{
    800031b6:	1101                	addi	sp,sp,-32
    800031b8:	ec06                	sd	ra,24(sp)
    800031ba:	e822                	sd	s0,16(sp)
    800031bc:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800031be:	fec40593          	addi	a1,s0,-20
    800031c2:	4501                	li	a0,0
    800031c4:	00000097          	auipc	ra,0x0
    800031c8:	d9a080e7          	jalr	-614(ra) # 80002f5e <argint>
  return kill(pid);
    800031cc:	fec42503          	lw	a0,-20(s0)
    800031d0:	fffff097          	auipc	ra,0xfffff
    800031d4:	282080e7          	jalr	642(ra) # 80002452 <kill>
}
    800031d8:	60e2                	ld	ra,24(sp)
    800031da:	6442                	ld	s0,16(sp)
    800031dc:	6105                	addi	sp,sp,32
    800031de:	8082                	ret

00000000800031e0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031e0:	1101                	addi	sp,sp,-32
    800031e2:	ec06                	sd	ra,24(sp)
    800031e4:	e822                	sd	s0,16(sp)
    800031e6:	e426                	sd	s1,8(sp)
    800031e8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031ea:	00234517          	auipc	a0,0x234
    800031ee:	bee50513          	addi	a0,a0,-1042 # 80236dd8 <tickslock>
    800031f2:	ffffe097          	auipc	ra,0xffffe
    800031f6:	b64080e7          	jalr	-1180(ra) # 80000d56 <acquire>
  xticks = ticks;
    800031fa:	00005497          	auipc	s1,0x5
    800031fe:	7264a483          	lw	s1,1830(s1) # 80008920 <ticks>
  release(&tickslock);
    80003202:	00234517          	auipc	a0,0x234
    80003206:	bd650513          	addi	a0,a0,-1066 # 80236dd8 <tickslock>
    8000320a:	ffffe097          	auipc	ra,0xffffe
    8000320e:	c00080e7          	jalr	-1024(ra) # 80000e0a <release>
  return xticks;
}
    80003212:	02049513          	slli	a0,s1,0x20
    80003216:	9101                	srli	a0,a0,0x20
    80003218:	60e2                	ld	ra,24(sp)
    8000321a:	6442                	ld	s0,16(sp)
    8000321c:	64a2                	ld	s1,8(sp)
    8000321e:	6105                	addi	sp,sp,32
    80003220:	8082                	ret

0000000080003222 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003222:	7139                	addi	sp,sp,-64
    80003224:	fc06                	sd	ra,56(sp)
    80003226:	f822                	sd	s0,48(sp)
    80003228:	f426                	sd	s1,40(sp)
    8000322a:	f04a                	sd	s2,32(sp)
    8000322c:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000322e:	fd840593          	addi	a1,s0,-40
    80003232:	4501                	li	a0,0
    80003234:	00000097          	auipc	ra,0x0
    80003238:	d4a080e7          	jalr	-694(ra) # 80002f7e <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000323c:	fd040593          	addi	a1,s0,-48
    80003240:	4505                	li	a0,1
    80003242:	00000097          	auipc	ra,0x0
    80003246:	d3c080e7          	jalr	-708(ra) # 80002f7e <argaddr>
  argaddr(2, &addr2);
    8000324a:	fc840593          	addi	a1,s0,-56
    8000324e:	4509                	li	a0,2
    80003250:	00000097          	auipc	ra,0x0
    80003254:	d2e080e7          	jalr	-722(ra) # 80002f7e <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003258:	fc040613          	addi	a2,s0,-64
    8000325c:	fc440593          	addi	a1,s0,-60
    80003260:	fd843503          	ld	a0,-40(s0)
    80003264:	fffff097          	auipc	ra,0xfffff
    80003268:	546080e7          	jalr	1350(ra) # 800027aa <waitx>
    8000326c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000326e:	fffff097          	auipc	ra,0xfffff
    80003272:	912080e7          	jalr	-1774(ra) # 80001b80 <myproc>
    80003276:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003278:	4691                	li	a3,4
    8000327a:	fc440613          	addi	a2,s0,-60
    8000327e:	fd043583          	ld	a1,-48(s0)
    80003282:	6928                	ld	a0,80(a0)
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	580080e7          	jalr	1408(ra) # 80001804 <copyout>
    return -1;
    8000328c:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000328e:	00054f63          	bltz	a0,800032ac <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003292:	4691                	li	a3,4
    80003294:	fc040613          	addi	a2,s0,-64
    80003298:	fc843583          	ld	a1,-56(s0)
    8000329c:	68a8                	ld	a0,80(s1)
    8000329e:	ffffe097          	auipc	ra,0xffffe
    800032a2:	566080e7          	jalr	1382(ra) # 80001804 <copyout>
    800032a6:	00054a63          	bltz	a0,800032ba <sys_waitx+0x98>
    return -1;
  return ret;
    800032aa:	87ca                	mv	a5,s2
    800032ac:	853e                	mv	a0,a5
    800032ae:	70e2                	ld	ra,56(sp)
    800032b0:	7442                	ld	s0,48(sp)
    800032b2:	74a2                	ld	s1,40(sp)
    800032b4:	7902                	ld	s2,32(sp)
    800032b6:	6121                	addi	sp,sp,64
    800032b8:	8082                	ret
    return -1;
    800032ba:	57fd                	li	a5,-1
    800032bc:	bfc5                	j	800032ac <sys_waitx+0x8a>

00000000800032be <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032be:	7179                	addi	sp,sp,-48
    800032c0:	f406                	sd	ra,40(sp)
    800032c2:	f022                	sd	s0,32(sp)
    800032c4:	ec26                	sd	s1,24(sp)
    800032c6:	e84a                	sd	s2,16(sp)
    800032c8:	e44e                	sd	s3,8(sp)
    800032ca:	e052                	sd	s4,0(sp)
    800032cc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800032ce:	00005597          	auipc	a1,0x5
    800032d2:	28a58593          	addi	a1,a1,650 # 80008558 <syscalls+0xb8>
    800032d6:	00234517          	auipc	a0,0x234
    800032da:	b1a50513          	addi	a0,a0,-1254 # 80236df0 <bcache>
    800032de:	ffffe097          	auipc	ra,0xffffe
    800032e2:	9e8080e7          	jalr	-1560(ra) # 80000cc6 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800032e6:	0023c797          	auipc	a5,0x23c
    800032ea:	b0a78793          	addi	a5,a5,-1270 # 8023edf0 <bcache+0x8000>
    800032ee:	0023c717          	auipc	a4,0x23c
    800032f2:	d6a70713          	addi	a4,a4,-662 # 8023f058 <bcache+0x8268>
    800032f6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800032fa:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032fe:	00234497          	auipc	s1,0x234
    80003302:	b0a48493          	addi	s1,s1,-1270 # 80236e08 <bcache+0x18>
    b->next = bcache.head.next;
    80003306:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003308:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000330a:	00005a17          	auipc	s4,0x5
    8000330e:	256a0a13          	addi	s4,s4,598 # 80008560 <syscalls+0xc0>
    b->next = bcache.head.next;
    80003312:	2b893783          	ld	a5,696(s2)
    80003316:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003318:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000331c:	85d2                	mv	a1,s4
    8000331e:	01048513          	addi	a0,s1,16
    80003322:	00001097          	auipc	ra,0x1
    80003326:	4c4080e7          	jalr	1220(ra) # 800047e6 <initsleeplock>
    bcache.head.next->prev = b;
    8000332a:	2b893783          	ld	a5,696(s2)
    8000332e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003330:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003334:	45848493          	addi	s1,s1,1112
    80003338:	fd349de3          	bne	s1,s3,80003312 <binit+0x54>
  }
}
    8000333c:	70a2                	ld	ra,40(sp)
    8000333e:	7402                	ld	s0,32(sp)
    80003340:	64e2                	ld	s1,24(sp)
    80003342:	6942                	ld	s2,16(sp)
    80003344:	69a2                	ld	s3,8(sp)
    80003346:	6a02                	ld	s4,0(sp)
    80003348:	6145                	addi	sp,sp,48
    8000334a:	8082                	ret

000000008000334c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000334c:	7179                	addi	sp,sp,-48
    8000334e:	f406                	sd	ra,40(sp)
    80003350:	f022                	sd	s0,32(sp)
    80003352:	ec26                	sd	s1,24(sp)
    80003354:	e84a                	sd	s2,16(sp)
    80003356:	e44e                	sd	s3,8(sp)
    80003358:	1800                	addi	s0,sp,48
    8000335a:	892a                	mv	s2,a0
    8000335c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000335e:	00234517          	auipc	a0,0x234
    80003362:	a9250513          	addi	a0,a0,-1390 # 80236df0 <bcache>
    80003366:	ffffe097          	auipc	ra,0xffffe
    8000336a:	9f0080e7          	jalr	-1552(ra) # 80000d56 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000336e:	0023c497          	auipc	s1,0x23c
    80003372:	d3a4b483          	ld	s1,-710(s1) # 8023f0a8 <bcache+0x82b8>
    80003376:	0023c797          	auipc	a5,0x23c
    8000337a:	ce278793          	addi	a5,a5,-798 # 8023f058 <bcache+0x8268>
    8000337e:	02f48f63          	beq	s1,a5,800033bc <bread+0x70>
    80003382:	873e                	mv	a4,a5
    80003384:	a021                	j	8000338c <bread+0x40>
    80003386:	68a4                	ld	s1,80(s1)
    80003388:	02e48a63          	beq	s1,a4,800033bc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000338c:	449c                	lw	a5,8(s1)
    8000338e:	ff279ce3          	bne	a5,s2,80003386 <bread+0x3a>
    80003392:	44dc                	lw	a5,12(s1)
    80003394:	ff3799e3          	bne	a5,s3,80003386 <bread+0x3a>
      b->refcnt++;
    80003398:	40bc                	lw	a5,64(s1)
    8000339a:	2785                	addiw	a5,a5,1
    8000339c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000339e:	00234517          	auipc	a0,0x234
    800033a2:	a5250513          	addi	a0,a0,-1454 # 80236df0 <bcache>
    800033a6:	ffffe097          	auipc	ra,0xffffe
    800033aa:	a64080e7          	jalr	-1436(ra) # 80000e0a <release>
      acquiresleep(&b->lock);
    800033ae:	01048513          	addi	a0,s1,16
    800033b2:	00001097          	auipc	ra,0x1
    800033b6:	46e080e7          	jalr	1134(ra) # 80004820 <acquiresleep>
      return b;
    800033ba:	a8b9                	j	80003418 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033bc:	0023c497          	auipc	s1,0x23c
    800033c0:	ce44b483          	ld	s1,-796(s1) # 8023f0a0 <bcache+0x82b0>
    800033c4:	0023c797          	auipc	a5,0x23c
    800033c8:	c9478793          	addi	a5,a5,-876 # 8023f058 <bcache+0x8268>
    800033cc:	00f48863          	beq	s1,a5,800033dc <bread+0x90>
    800033d0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800033d2:	40bc                	lw	a5,64(s1)
    800033d4:	cf81                	beqz	a5,800033ec <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033d6:	64a4                	ld	s1,72(s1)
    800033d8:	fee49de3          	bne	s1,a4,800033d2 <bread+0x86>
  panic("bget: no buffers");
    800033dc:	00005517          	auipc	a0,0x5
    800033e0:	18c50513          	addi	a0,a0,396 # 80008568 <syscalls+0xc8>
    800033e4:	ffffd097          	auipc	ra,0xffffd
    800033e8:	15a080e7          	jalr	346(ra) # 8000053e <panic>
      b->dev = dev;
    800033ec:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800033f0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800033f4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800033f8:	4785                	li	a5,1
    800033fa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033fc:	00234517          	auipc	a0,0x234
    80003400:	9f450513          	addi	a0,a0,-1548 # 80236df0 <bcache>
    80003404:	ffffe097          	auipc	ra,0xffffe
    80003408:	a06080e7          	jalr	-1530(ra) # 80000e0a <release>
      acquiresleep(&b->lock);
    8000340c:	01048513          	addi	a0,s1,16
    80003410:	00001097          	auipc	ra,0x1
    80003414:	410080e7          	jalr	1040(ra) # 80004820 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003418:	409c                	lw	a5,0(s1)
    8000341a:	cb89                	beqz	a5,8000342c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000341c:	8526                	mv	a0,s1
    8000341e:	70a2                	ld	ra,40(sp)
    80003420:	7402                	ld	s0,32(sp)
    80003422:	64e2                	ld	s1,24(sp)
    80003424:	6942                	ld	s2,16(sp)
    80003426:	69a2                	ld	s3,8(sp)
    80003428:	6145                	addi	sp,sp,48
    8000342a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000342c:	4581                	li	a1,0
    8000342e:	8526                	mv	a0,s1
    80003430:	00003097          	auipc	ra,0x3
    80003434:	fd4080e7          	jalr	-44(ra) # 80006404 <virtio_disk_rw>
    b->valid = 1;
    80003438:	4785                	li	a5,1
    8000343a:	c09c                	sw	a5,0(s1)
  return b;
    8000343c:	b7c5                	j	8000341c <bread+0xd0>

000000008000343e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000343e:	1101                	addi	sp,sp,-32
    80003440:	ec06                	sd	ra,24(sp)
    80003442:	e822                	sd	s0,16(sp)
    80003444:	e426                	sd	s1,8(sp)
    80003446:	1000                	addi	s0,sp,32
    80003448:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000344a:	0541                	addi	a0,a0,16
    8000344c:	00001097          	auipc	ra,0x1
    80003450:	46e080e7          	jalr	1134(ra) # 800048ba <holdingsleep>
    80003454:	cd01                	beqz	a0,8000346c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003456:	4585                	li	a1,1
    80003458:	8526                	mv	a0,s1
    8000345a:	00003097          	auipc	ra,0x3
    8000345e:	faa080e7          	jalr	-86(ra) # 80006404 <virtio_disk_rw>
}
    80003462:	60e2                	ld	ra,24(sp)
    80003464:	6442                	ld	s0,16(sp)
    80003466:	64a2                	ld	s1,8(sp)
    80003468:	6105                	addi	sp,sp,32
    8000346a:	8082                	ret
    panic("bwrite");
    8000346c:	00005517          	auipc	a0,0x5
    80003470:	11450513          	addi	a0,a0,276 # 80008580 <syscalls+0xe0>
    80003474:	ffffd097          	auipc	ra,0xffffd
    80003478:	0ca080e7          	jalr	202(ra) # 8000053e <panic>

000000008000347c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000347c:	1101                	addi	sp,sp,-32
    8000347e:	ec06                	sd	ra,24(sp)
    80003480:	e822                	sd	s0,16(sp)
    80003482:	e426                	sd	s1,8(sp)
    80003484:	e04a                	sd	s2,0(sp)
    80003486:	1000                	addi	s0,sp,32
    80003488:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000348a:	01050913          	addi	s2,a0,16
    8000348e:	854a                	mv	a0,s2
    80003490:	00001097          	auipc	ra,0x1
    80003494:	42a080e7          	jalr	1066(ra) # 800048ba <holdingsleep>
    80003498:	c92d                	beqz	a0,8000350a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000349a:	854a                	mv	a0,s2
    8000349c:	00001097          	auipc	ra,0x1
    800034a0:	3da080e7          	jalr	986(ra) # 80004876 <releasesleep>

  acquire(&bcache.lock);
    800034a4:	00234517          	auipc	a0,0x234
    800034a8:	94c50513          	addi	a0,a0,-1716 # 80236df0 <bcache>
    800034ac:	ffffe097          	auipc	ra,0xffffe
    800034b0:	8aa080e7          	jalr	-1878(ra) # 80000d56 <acquire>
  b->refcnt--;
    800034b4:	40bc                	lw	a5,64(s1)
    800034b6:	37fd                	addiw	a5,a5,-1
    800034b8:	0007871b          	sext.w	a4,a5
    800034bc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034be:	eb05                	bnez	a4,800034ee <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034c0:	68bc                	ld	a5,80(s1)
    800034c2:	64b8                	ld	a4,72(s1)
    800034c4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800034c6:	64bc                	ld	a5,72(s1)
    800034c8:	68b8                	ld	a4,80(s1)
    800034ca:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034cc:	0023c797          	auipc	a5,0x23c
    800034d0:	92478793          	addi	a5,a5,-1756 # 8023edf0 <bcache+0x8000>
    800034d4:	2b87b703          	ld	a4,696(a5)
    800034d8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800034da:	0023c717          	auipc	a4,0x23c
    800034de:	b7e70713          	addi	a4,a4,-1154 # 8023f058 <bcache+0x8268>
    800034e2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800034e4:	2b87b703          	ld	a4,696(a5)
    800034e8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800034ea:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800034ee:	00234517          	auipc	a0,0x234
    800034f2:	90250513          	addi	a0,a0,-1790 # 80236df0 <bcache>
    800034f6:	ffffe097          	auipc	ra,0xffffe
    800034fa:	914080e7          	jalr	-1772(ra) # 80000e0a <release>
}
    800034fe:	60e2                	ld	ra,24(sp)
    80003500:	6442                	ld	s0,16(sp)
    80003502:	64a2                	ld	s1,8(sp)
    80003504:	6902                	ld	s2,0(sp)
    80003506:	6105                	addi	sp,sp,32
    80003508:	8082                	ret
    panic("brelse");
    8000350a:	00005517          	auipc	a0,0x5
    8000350e:	07e50513          	addi	a0,a0,126 # 80008588 <syscalls+0xe8>
    80003512:	ffffd097          	auipc	ra,0xffffd
    80003516:	02c080e7          	jalr	44(ra) # 8000053e <panic>

000000008000351a <bpin>:

void
bpin(struct buf *b) {
    8000351a:	1101                	addi	sp,sp,-32
    8000351c:	ec06                	sd	ra,24(sp)
    8000351e:	e822                	sd	s0,16(sp)
    80003520:	e426                	sd	s1,8(sp)
    80003522:	1000                	addi	s0,sp,32
    80003524:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003526:	00234517          	auipc	a0,0x234
    8000352a:	8ca50513          	addi	a0,a0,-1846 # 80236df0 <bcache>
    8000352e:	ffffe097          	auipc	ra,0xffffe
    80003532:	828080e7          	jalr	-2008(ra) # 80000d56 <acquire>
  b->refcnt++;
    80003536:	40bc                	lw	a5,64(s1)
    80003538:	2785                	addiw	a5,a5,1
    8000353a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000353c:	00234517          	auipc	a0,0x234
    80003540:	8b450513          	addi	a0,a0,-1868 # 80236df0 <bcache>
    80003544:	ffffe097          	auipc	ra,0xffffe
    80003548:	8c6080e7          	jalr	-1850(ra) # 80000e0a <release>
}
    8000354c:	60e2                	ld	ra,24(sp)
    8000354e:	6442                	ld	s0,16(sp)
    80003550:	64a2                	ld	s1,8(sp)
    80003552:	6105                	addi	sp,sp,32
    80003554:	8082                	ret

0000000080003556 <bunpin>:

void
bunpin(struct buf *b) {
    80003556:	1101                	addi	sp,sp,-32
    80003558:	ec06                	sd	ra,24(sp)
    8000355a:	e822                	sd	s0,16(sp)
    8000355c:	e426                	sd	s1,8(sp)
    8000355e:	1000                	addi	s0,sp,32
    80003560:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003562:	00234517          	auipc	a0,0x234
    80003566:	88e50513          	addi	a0,a0,-1906 # 80236df0 <bcache>
    8000356a:	ffffd097          	auipc	ra,0xffffd
    8000356e:	7ec080e7          	jalr	2028(ra) # 80000d56 <acquire>
  b->refcnt--;
    80003572:	40bc                	lw	a5,64(s1)
    80003574:	37fd                	addiw	a5,a5,-1
    80003576:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003578:	00234517          	auipc	a0,0x234
    8000357c:	87850513          	addi	a0,a0,-1928 # 80236df0 <bcache>
    80003580:	ffffe097          	auipc	ra,0xffffe
    80003584:	88a080e7          	jalr	-1910(ra) # 80000e0a <release>
}
    80003588:	60e2                	ld	ra,24(sp)
    8000358a:	6442                	ld	s0,16(sp)
    8000358c:	64a2                	ld	s1,8(sp)
    8000358e:	6105                	addi	sp,sp,32
    80003590:	8082                	ret

0000000080003592 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003592:	1101                	addi	sp,sp,-32
    80003594:	ec06                	sd	ra,24(sp)
    80003596:	e822                	sd	s0,16(sp)
    80003598:	e426                	sd	s1,8(sp)
    8000359a:	e04a                	sd	s2,0(sp)
    8000359c:	1000                	addi	s0,sp,32
    8000359e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035a0:	00d5d59b          	srliw	a1,a1,0xd
    800035a4:	0023c797          	auipc	a5,0x23c
    800035a8:	f287a783          	lw	a5,-216(a5) # 8023f4cc <sb+0x1c>
    800035ac:	9dbd                	addw	a1,a1,a5
    800035ae:	00000097          	auipc	ra,0x0
    800035b2:	d9e080e7          	jalr	-610(ra) # 8000334c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035b6:	0074f713          	andi	a4,s1,7
    800035ba:	4785                	li	a5,1
    800035bc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035c0:	14ce                	slli	s1,s1,0x33
    800035c2:	90d9                	srli	s1,s1,0x36
    800035c4:	00950733          	add	a4,a0,s1
    800035c8:	05874703          	lbu	a4,88(a4)
    800035cc:	00e7f6b3          	and	a3,a5,a4
    800035d0:	c69d                	beqz	a3,800035fe <bfree+0x6c>
    800035d2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800035d4:	94aa                	add	s1,s1,a0
    800035d6:	fff7c793          	not	a5,a5
    800035da:	8ff9                	and	a5,a5,a4
    800035dc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800035e0:	00001097          	auipc	ra,0x1
    800035e4:	120080e7          	jalr	288(ra) # 80004700 <log_write>
  brelse(bp);
    800035e8:	854a                	mv	a0,s2
    800035ea:	00000097          	auipc	ra,0x0
    800035ee:	e92080e7          	jalr	-366(ra) # 8000347c <brelse>
}
    800035f2:	60e2                	ld	ra,24(sp)
    800035f4:	6442                	ld	s0,16(sp)
    800035f6:	64a2                	ld	s1,8(sp)
    800035f8:	6902                	ld	s2,0(sp)
    800035fa:	6105                	addi	sp,sp,32
    800035fc:	8082                	ret
    panic("freeing free block");
    800035fe:	00005517          	auipc	a0,0x5
    80003602:	f9250513          	addi	a0,a0,-110 # 80008590 <syscalls+0xf0>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	f38080e7          	jalr	-200(ra) # 8000053e <panic>

000000008000360e <balloc>:
{
    8000360e:	711d                	addi	sp,sp,-96
    80003610:	ec86                	sd	ra,88(sp)
    80003612:	e8a2                	sd	s0,80(sp)
    80003614:	e4a6                	sd	s1,72(sp)
    80003616:	e0ca                	sd	s2,64(sp)
    80003618:	fc4e                	sd	s3,56(sp)
    8000361a:	f852                	sd	s4,48(sp)
    8000361c:	f456                	sd	s5,40(sp)
    8000361e:	f05a                	sd	s6,32(sp)
    80003620:	ec5e                	sd	s7,24(sp)
    80003622:	e862                	sd	s8,16(sp)
    80003624:	e466                	sd	s9,8(sp)
    80003626:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003628:	0023c797          	auipc	a5,0x23c
    8000362c:	e8c7a783          	lw	a5,-372(a5) # 8023f4b4 <sb+0x4>
    80003630:	10078163          	beqz	a5,80003732 <balloc+0x124>
    80003634:	8baa                	mv	s7,a0
    80003636:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003638:	0023cb17          	auipc	s6,0x23c
    8000363c:	e78b0b13          	addi	s6,s6,-392 # 8023f4b0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003640:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003642:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003644:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003646:	6c89                	lui	s9,0x2
    80003648:	a061                	j	800036d0 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000364a:	974a                	add	a4,a4,s2
    8000364c:	8fd5                	or	a5,a5,a3
    8000364e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003652:	854a                	mv	a0,s2
    80003654:	00001097          	auipc	ra,0x1
    80003658:	0ac080e7          	jalr	172(ra) # 80004700 <log_write>
        brelse(bp);
    8000365c:	854a                	mv	a0,s2
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	e1e080e7          	jalr	-482(ra) # 8000347c <brelse>
  bp = bread(dev, bno);
    80003666:	85a6                	mv	a1,s1
    80003668:	855e                	mv	a0,s7
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	ce2080e7          	jalr	-798(ra) # 8000334c <bread>
    80003672:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003674:	40000613          	li	a2,1024
    80003678:	4581                	li	a1,0
    8000367a:	05850513          	addi	a0,a0,88
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	7d4080e7          	jalr	2004(ra) # 80000e52 <memset>
  log_write(bp);
    80003686:	854a                	mv	a0,s2
    80003688:	00001097          	auipc	ra,0x1
    8000368c:	078080e7          	jalr	120(ra) # 80004700 <log_write>
  brelse(bp);
    80003690:	854a                	mv	a0,s2
    80003692:	00000097          	auipc	ra,0x0
    80003696:	dea080e7          	jalr	-534(ra) # 8000347c <brelse>
}
    8000369a:	8526                	mv	a0,s1
    8000369c:	60e6                	ld	ra,88(sp)
    8000369e:	6446                	ld	s0,80(sp)
    800036a0:	64a6                	ld	s1,72(sp)
    800036a2:	6906                	ld	s2,64(sp)
    800036a4:	79e2                	ld	s3,56(sp)
    800036a6:	7a42                	ld	s4,48(sp)
    800036a8:	7aa2                	ld	s5,40(sp)
    800036aa:	7b02                	ld	s6,32(sp)
    800036ac:	6be2                	ld	s7,24(sp)
    800036ae:	6c42                	ld	s8,16(sp)
    800036b0:	6ca2                	ld	s9,8(sp)
    800036b2:	6125                	addi	sp,sp,96
    800036b4:	8082                	ret
    brelse(bp);
    800036b6:	854a                	mv	a0,s2
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	dc4080e7          	jalr	-572(ra) # 8000347c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036c0:	015c87bb          	addw	a5,s9,s5
    800036c4:	00078a9b          	sext.w	s5,a5
    800036c8:	004b2703          	lw	a4,4(s6)
    800036cc:	06eaf363          	bgeu	s5,a4,80003732 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800036d0:	41fad79b          	sraiw	a5,s5,0x1f
    800036d4:	0137d79b          	srliw	a5,a5,0x13
    800036d8:	015787bb          	addw	a5,a5,s5
    800036dc:	40d7d79b          	sraiw	a5,a5,0xd
    800036e0:	01cb2583          	lw	a1,28(s6)
    800036e4:	9dbd                	addw	a1,a1,a5
    800036e6:	855e                	mv	a0,s7
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	c64080e7          	jalr	-924(ra) # 8000334c <bread>
    800036f0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036f2:	004b2503          	lw	a0,4(s6)
    800036f6:	000a849b          	sext.w	s1,s5
    800036fa:	8662                	mv	a2,s8
    800036fc:	faa4fde3          	bgeu	s1,a0,800036b6 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003700:	41f6579b          	sraiw	a5,a2,0x1f
    80003704:	01d7d69b          	srliw	a3,a5,0x1d
    80003708:	00c6873b          	addw	a4,a3,a2
    8000370c:	00777793          	andi	a5,a4,7
    80003710:	9f95                	subw	a5,a5,a3
    80003712:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003716:	4037571b          	sraiw	a4,a4,0x3
    8000371a:	00e906b3          	add	a3,s2,a4
    8000371e:	0586c683          	lbu	a3,88(a3)
    80003722:	00d7f5b3          	and	a1,a5,a3
    80003726:	d195                	beqz	a1,8000364a <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003728:	2605                	addiw	a2,a2,1
    8000372a:	2485                	addiw	s1,s1,1
    8000372c:	fd4618e3          	bne	a2,s4,800036fc <balloc+0xee>
    80003730:	b759                	j	800036b6 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003732:	00005517          	auipc	a0,0x5
    80003736:	e7650513          	addi	a0,a0,-394 # 800085a8 <syscalls+0x108>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	e4e080e7          	jalr	-434(ra) # 80000588 <printf>
  return 0;
    80003742:	4481                	li	s1,0
    80003744:	bf99                	j	8000369a <balloc+0x8c>

0000000080003746 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003746:	7179                	addi	sp,sp,-48
    80003748:	f406                	sd	ra,40(sp)
    8000374a:	f022                	sd	s0,32(sp)
    8000374c:	ec26                	sd	s1,24(sp)
    8000374e:	e84a                	sd	s2,16(sp)
    80003750:	e44e                	sd	s3,8(sp)
    80003752:	e052                	sd	s4,0(sp)
    80003754:	1800                	addi	s0,sp,48
    80003756:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003758:	47ad                	li	a5,11
    8000375a:	02b7e763          	bltu	a5,a1,80003788 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000375e:	02059493          	slli	s1,a1,0x20
    80003762:	9081                	srli	s1,s1,0x20
    80003764:	048a                	slli	s1,s1,0x2
    80003766:	94aa                	add	s1,s1,a0
    80003768:	0504a903          	lw	s2,80(s1)
    8000376c:	06091e63          	bnez	s2,800037e8 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003770:	4108                	lw	a0,0(a0)
    80003772:	00000097          	auipc	ra,0x0
    80003776:	e9c080e7          	jalr	-356(ra) # 8000360e <balloc>
    8000377a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000377e:	06090563          	beqz	s2,800037e8 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003782:	0524a823          	sw	s2,80(s1)
    80003786:	a08d                	j	800037e8 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003788:	ff45849b          	addiw	s1,a1,-12
    8000378c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003790:	0ff00793          	li	a5,255
    80003794:	08e7e563          	bltu	a5,a4,8000381e <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003798:	08052903          	lw	s2,128(a0)
    8000379c:	00091d63          	bnez	s2,800037b6 <bmap+0x70>
      addr = balloc(ip->dev);
    800037a0:	4108                	lw	a0,0(a0)
    800037a2:	00000097          	auipc	ra,0x0
    800037a6:	e6c080e7          	jalr	-404(ra) # 8000360e <balloc>
    800037aa:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037ae:	02090d63          	beqz	s2,800037e8 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800037b2:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800037b6:	85ca                	mv	a1,s2
    800037b8:	0009a503          	lw	a0,0(s3)
    800037bc:	00000097          	auipc	ra,0x0
    800037c0:	b90080e7          	jalr	-1136(ra) # 8000334c <bread>
    800037c4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037c6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037ca:	02049593          	slli	a1,s1,0x20
    800037ce:	9181                	srli	a1,a1,0x20
    800037d0:	058a                	slli	a1,a1,0x2
    800037d2:	00b784b3          	add	s1,a5,a1
    800037d6:	0004a903          	lw	s2,0(s1)
    800037da:	02090063          	beqz	s2,800037fa <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800037de:	8552                	mv	a0,s4
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	c9c080e7          	jalr	-868(ra) # 8000347c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037e8:	854a                	mv	a0,s2
    800037ea:	70a2                	ld	ra,40(sp)
    800037ec:	7402                	ld	s0,32(sp)
    800037ee:	64e2                	ld	s1,24(sp)
    800037f0:	6942                	ld	s2,16(sp)
    800037f2:	69a2                	ld	s3,8(sp)
    800037f4:	6a02                	ld	s4,0(sp)
    800037f6:	6145                	addi	sp,sp,48
    800037f8:	8082                	ret
      addr = balloc(ip->dev);
    800037fa:	0009a503          	lw	a0,0(s3)
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	e10080e7          	jalr	-496(ra) # 8000360e <balloc>
    80003806:	0005091b          	sext.w	s2,a0
      if(addr){
    8000380a:	fc090ae3          	beqz	s2,800037de <bmap+0x98>
        a[bn] = addr;
    8000380e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003812:	8552                	mv	a0,s4
    80003814:	00001097          	auipc	ra,0x1
    80003818:	eec080e7          	jalr	-276(ra) # 80004700 <log_write>
    8000381c:	b7c9                	j	800037de <bmap+0x98>
  panic("bmap: out of range");
    8000381e:	00005517          	auipc	a0,0x5
    80003822:	da250513          	addi	a0,a0,-606 # 800085c0 <syscalls+0x120>
    80003826:	ffffd097          	auipc	ra,0xffffd
    8000382a:	d18080e7          	jalr	-744(ra) # 8000053e <panic>

000000008000382e <iget>:
{
    8000382e:	7179                	addi	sp,sp,-48
    80003830:	f406                	sd	ra,40(sp)
    80003832:	f022                	sd	s0,32(sp)
    80003834:	ec26                	sd	s1,24(sp)
    80003836:	e84a                	sd	s2,16(sp)
    80003838:	e44e                	sd	s3,8(sp)
    8000383a:	e052                	sd	s4,0(sp)
    8000383c:	1800                	addi	s0,sp,48
    8000383e:	89aa                	mv	s3,a0
    80003840:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003842:	0023c517          	auipc	a0,0x23c
    80003846:	c8e50513          	addi	a0,a0,-882 # 8023f4d0 <itable>
    8000384a:	ffffd097          	auipc	ra,0xffffd
    8000384e:	50c080e7          	jalr	1292(ra) # 80000d56 <acquire>
  empty = 0;
    80003852:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003854:	0023c497          	auipc	s1,0x23c
    80003858:	c9448493          	addi	s1,s1,-876 # 8023f4e8 <itable+0x18>
    8000385c:	0023d697          	auipc	a3,0x23d
    80003860:	71c68693          	addi	a3,a3,1820 # 80240f78 <log>
    80003864:	a039                	j	80003872 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003866:	02090b63          	beqz	s2,8000389c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000386a:	08848493          	addi	s1,s1,136
    8000386e:	02d48a63          	beq	s1,a3,800038a2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003872:	449c                	lw	a5,8(s1)
    80003874:	fef059e3          	blez	a5,80003866 <iget+0x38>
    80003878:	4098                	lw	a4,0(s1)
    8000387a:	ff3716e3          	bne	a4,s3,80003866 <iget+0x38>
    8000387e:	40d8                	lw	a4,4(s1)
    80003880:	ff4713e3          	bne	a4,s4,80003866 <iget+0x38>
      ip->ref++;
    80003884:	2785                	addiw	a5,a5,1
    80003886:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003888:	0023c517          	auipc	a0,0x23c
    8000388c:	c4850513          	addi	a0,a0,-952 # 8023f4d0 <itable>
    80003890:	ffffd097          	auipc	ra,0xffffd
    80003894:	57a080e7          	jalr	1402(ra) # 80000e0a <release>
      return ip;
    80003898:	8926                	mv	s2,s1
    8000389a:	a03d                	j	800038c8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000389c:	f7f9                	bnez	a5,8000386a <iget+0x3c>
    8000389e:	8926                	mv	s2,s1
    800038a0:	b7e9                	j	8000386a <iget+0x3c>
  if(empty == 0)
    800038a2:	02090c63          	beqz	s2,800038da <iget+0xac>
  ip->dev = dev;
    800038a6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038aa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038ae:	4785                	li	a5,1
    800038b0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038b4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038b8:	0023c517          	auipc	a0,0x23c
    800038bc:	c1850513          	addi	a0,a0,-1000 # 8023f4d0 <itable>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	54a080e7          	jalr	1354(ra) # 80000e0a <release>
}
    800038c8:	854a                	mv	a0,s2
    800038ca:	70a2                	ld	ra,40(sp)
    800038cc:	7402                	ld	s0,32(sp)
    800038ce:	64e2                	ld	s1,24(sp)
    800038d0:	6942                	ld	s2,16(sp)
    800038d2:	69a2                	ld	s3,8(sp)
    800038d4:	6a02                	ld	s4,0(sp)
    800038d6:	6145                	addi	sp,sp,48
    800038d8:	8082                	ret
    panic("iget: no inodes");
    800038da:	00005517          	auipc	a0,0x5
    800038de:	cfe50513          	addi	a0,a0,-770 # 800085d8 <syscalls+0x138>
    800038e2:	ffffd097          	auipc	ra,0xffffd
    800038e6:	c5c080e7          	jalr	-932(ra) # 8000053e <panic>

00000000800038ea <fsinit>:
fsinit(int dev) {
    800038ea:	7179                	addi	sp,sp,-48
    800038ec:	f406                	sd	ra,40(sp)
    800038ee:	f022                	sd	s0,32(sp)
    800038f0:	ec26                	sd	s1,24(sp)
    800038f2:	e84a                	sd	s2,16(sp)
    800038f4:	e44e                	sd	s3,8(sp)
    800038f6:	1800                	addi	s0,sp,48
    800038f8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038fa:	4585                	li	a1,1
    800038fc:	00000097          	auipc	ra,0x0
    80003900:	a50080e7          	jalr	-1456(ra) # 8000334c <bread>
    80003904:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003906:	0023c997          	auipc	s3,0x23c
    8000390a:	baa98993          	addi	s3,s3,-1110 # 8023f4b0 <sb>
    8000390e:	02000613          	li	a2,32
    80003912:	05850593          	addi	a1,a0,88
    80003916:	854e                	mv	a0,s3
    80003918:	ffffd097          	auipc	ra,0xffffd
    8000391c:	596080e7          	jalr	1430(ra) # 80000eae <memmove>
  brelse(bp);
    80003920:	8526                	mv	a0,s1
    80003922:	00000097          	auipc	ra,0x0
    80003926:	b5a080e7          	jalr	-1190(ra) # 8000347c <brelse>
  if(sb.magic != FSMAGIC)
    8000392a:	0009a703          	lw	a4,0(s3)
    8000392e:	102037b7          	lui	a5,0x10203
    80003932:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003936:	02f71263          	bne	a4,a5,8000395a <fsinit+0x70>
  initlog(dev, &sb);
    8000393a:	0023c597          	auipc	a1,0x23c
    8000393e:	b7658593          	addi	a1,a1,-1162 # 8023f4b0 <sb>
    80003942:	854a                	mv	a0,s2
    80003944:	00001097          	auipc	ra,0x1
    80003948:	b40080e7          	jalr	-1216(ra) # 80004484 <initlog>
}
    8000394c:	70a2                	ld	ra,40(sp)
    8000394e:	7402                	ld	s0,32(sp)
    80003950:	64e2                	ld	s1,24(sp)
    80003952:	6942                	ld	s2,16(sp)
    80003954:	69a2                	ld	s3,8(sp)
    80003956:	6145                	addi	sp,sp,48
    80003958:	8082                	ret
    panic("invalid file system");
    8000395a:	00005517          	auipc	a0,0x5
    8000395e:	c8e50513          	addi	a0,a0,-882 # 800085e8 <syscalls+0x148>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	bdc080e7          	jalr	-1060(ra) # 8000053e <panic>

000000008000396a <iinit>:
{
    8000396a:	7179                	addi	sp,sp,-48
    8000396c:	f406                	sd	ra,40(sp)
    8000396e:	f022                	sd	s0,32(sp)
    80003970:	ec26                	sd	s1,24(sp)
    80003972:	e84a                	sd	s2,16(sp)
    80003974:	e44e                	sd	s3,8(sp)
    80003976:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003978:	00005597          	auipc	a1,0x5
    8000397c:	c8858593          	addi	a1,a1,-888 # 80008600 <syscalls+0x160>
    80003980:	0023c517          	auipc	a0,0x23c
    80003984:	b5050513          	addi	a0,a0,-1200 # 8023f4d0 <itable>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	33e080e7          	jalr	830(ra) # 80000cc6 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003990:	0023c497          	auipc	s1,0x23c
    80003994:	b6848493          	addi	s1,s1,-1176 # 8023f4f8 <itable+0x28>
    80003998:	0023d997          	auipc	s3,0x23d
    8000399c:	5f098993          	addi	s3,s3,1520 # 80240f88 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039a0:	00005917          	auipc	s2,0x5
    800039a4:	c6890913          	addi	s2,s2,-920 # 80008608 <syscalls+0x168>
    800039a8:	85ca                	mv	a1,s2
    800039aa:	8526                	mv	a0,s1
    800039ac:	00001097          	auipc	ra,0x1
    800039b0:	e3a080e7          	jalr	-454(ra) # 800047e6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039b4:	08848493          	addi	s1,s1,136
    800039b8:	ff3498e3          	bne	s1,s3,800039a8 <iinit+0x3e>
}
    800039bc:	70a2                	ld	ra,40(sp)
    800039be:	7402                	ld	s0,32(sp)
    800039c0:	64e2                	ld	s1,24(sp)
    800039c2:	6942                	ld	s2,16(sp)
    800039c4:	69a2                	ld	s3,8(sp)
    800039c6:	6145                	addi	sp,sp,48
    800039c8:	8082                	ret

00000000800039ca <ialloc>:
{
    800039ca:	715d                	addi	sp,sp,-80
    800039cc:	e486                	sd	ra,72(sp)
    800039ce:	e0a2                	sd	s0,64(sp)
    800039d0:	fc26                	sd	s1,56(sp)
    800039d2:	f84a                	sd	s2,48(sp)
    800039d4:	f44e                	sd	s3,40(sp)
    800039d6:	f052                	sd	s4,32(sp)
    800039d8:	ec56                	sd	s5,24(sp)
    800039da:	e85a                	sd	s6,16(sp)
    800039dc:	e45e                	sd	s7,8(sp)
    800039de:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039e0:	0023c717          	auipc	a4,0x23c
    800039e4:	adc72703          	lw	a4,-1316(a4) # 8023f4bc <sb+0xc>
    800039e8:	4785                	li	a5,1
    800039ea:	04e7fa63          	bgeu	a5,a4,80003a3e <ialloc+0x74>
    800039ee:	8aaa                	mv	s5,a0
    800039f0:	8bae                	mv	s7,a1
    800039f2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039f4:	0023ca17          	auipc	s4,0x23c
    800039f8:	abca0a13          	addi	s4,s4,-1348 # 8023f4b0 <sb>
    800039fc:	00048b1b          	sext.w	s6,s1
    80003a00:	0044d793          	srli	a5,s1,0x4
    80003a04:	018a2583          	lw	a1,24(s4)
    80003a08:	9dbd                	addw	a1,a1,a5
    80003a0a:	8556                	mv	a0,s5
    80003a0c:	00000097          	auipc	ra,0x0
    80003a10:	940080e7          	jalr	-1728(ra) # 8000334c <bread>
    80003a14:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a16:	05850993          	addi	s3,a0,88
    80003a1a:	00f4f793          	andi	a5,s1,15
    80003a1e:	079a                	slli	a5,a5,0x6
    80003a20:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a22:	00099783          	lh	a5,0(s3)
    80003a26:	c3a1                	beqz	a5,80003a66 <ialloc+0x9c>
    brelse(bp);
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	a54080e7          	jalr	-1452(ra) # 8000347c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a30:	0485                	addi	s1,s1,1
    80003a32:	00ca2703          	lw	a4,12(s4)
    80003a36:	0004879b          	sext.w	a5,s1
    80003a3a:	fce7e1e3          	bltu	a5,a4,800039fc <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003a3e:	00005517          	auipc	a0,0x5
    80003a42:	bd250513          	addi	a0,a0,-1070 # 80008610 <syscalls+0x170>
    80003a46:	ffffd097          	auipc	ra,0xffffd
    80003a4a:	b42080e7          	jalr	-1214(ra) # 80000588 <printf>
  return 0;
    80003a4e:	4501                	li	a0,0
}
    80003a50:	60a6                	ld	ra,72(sp)
    80003a52:	6406                	ld	s0,64(sp)
    80003a54:	74e2                	ld	s1,56(sp)
    80003a56:	7942                	ld	s2,48(sp)
    80003a58:	79a2                	ld	s3,40(sp)
    80003a5a:	7a02                	ld	s4,32(sp)
    80003a5c:	6ae2                	ld	s5,24(sp)
    80003a5e:	6b42                	ld	s6,16(sp)
    80003a60:	6ba2                	ld	s7,8(sp)
    80003a62:	6161                	addi	sp,sp,80
    80003a64:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003a66:	04000613          	li	a2,64
    80003a6a:	4581                	li	a1,0
    80003a6c:	854e                	mv	a0,s3
    80003a6e:	ffffd097          	auipc	ra,0xffffd
    80003a72:	3e4080e7          	jalr	996(ra) # 80000e52 <memset>
      dip->type = type;
    80003a76:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a7a:	854a                	mv	a0,s2
    80003a7c:	00001097          	auipc	ra,0x1
    80003a80:	c84080e7          	jalr	-892(ra) # 80004700 <log_write>
      brelse(bp);
    80003a84:	854a                	mv	a0,s2
    80003a86:	00000097          	auipc	ra,0x0
    80003a8a:	9f6080e7          	jalr	-1546(ra) # 8000347c <brelse>
      return iget(dev, inum);
    80003a8e:	85da                	mv	a1,s6
    80003a90:	8556                	mv	a0,s5
    80003a92:	00000097          	auipc	ra,0x0
    80003a96:	d9c080e7          	jalr	-612(ra) # 8000382e <iget>
    80003a9a:	bf5d                	j	80003a50 <ialloc+0x86>

0000000080003a9c <iupdate>:
{
    80003a9c:	1101                	addi	sp,sp,-32
    80003a9e:	ec06                	sd	ra,24(sp)
    80003aa0:	e822                	sd	s0,16(sp)
    80003aa2:	e426                	sd	s1,8(sp)
    80003aa4:	e04a                	sd	s2,0(sp)
    80003aa6:	1000                	addi	s0,sp,32
    80003aa8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003aaa:	415c                	lw	a5,4(a0)
    80003aac:	0047d79b          	srliw	a5,a5,0x4
    80003ab0:	0023c597          	auipc	a1,0x23c
    80003ab4:	a185a583          	lw	a1,-1512(a1) # 8023f4c8 <sb+0x18>
    80003ab8:	9dbd                	addw	a1,a1,a5
    80003aba:	4108                	lw	a0,0(a0)
    80003abc:	00000097          	auipc	ra,0x0
    80003ac0:	890080e7          	jalr	-1904(ra) # 8000334c <bread>
    80003ac4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ac6:	05850793          	addi	a5,a0,88
    80003aca:	40c8                	lw	a0,4(s1)
    80003acc:	893d                	andi	a0,a0,15
    80003ace:	051a                	slli	a0,a0,0x6
    80003ad0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003ad2:	04449703          	lh	a4,68(s1)
    80003ad6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003ada:	04649703          	lh	a4,70(s1)
    80003ade:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003ae2:	04849703          	lh	a4,72(s1)
    80003ae6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003aea:	04a49703          	lh	a4,74(s1)
    80003aee:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003af2:	44f8                	lw	a4,76(s1)
    80003af4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003af6:	03400613          	li	a2,52
    80003afa:	05048593          	addi	a1,s1,80
    80003afe:	0531                	addi	a0,a0,12
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	3ae080e7          	jalr	942(ra) # 80000eae <memmove>
  log_write(bp);
    80003b08:	854a                	mv	a0,s2
    80003b0a:	00001097          	auipc	ra,0x1
    80003b0e:	bf6080e7          	jalr	-1034(ra) # 80004700 <log_write>
  brelse(bp);
    80003b12:	854a                	mv	a0,s2
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	968080e7          	jalr	-1688(ra) # 8000347c <brelse>
}
    80003b1c:	60e2                	ld	ra,24(sp)
    80003b1e:	6442                	ld	s0,16(sp)
    80003b20:	64a2                	ld	s1,8(sp)
    80003b22:	6902                	ld	s2,0(sp)
    80003b24:	6105                	addi	sp,sp,32
    80003b26:	8082                	ret

0000000080003b28 <idup>:
{
    80003b28:	1101                	addi	sp,sp,-32
    80003b2a:	ec06                	sd	ra,24(sp)
    80003b2c:	e822                	sd	s0,16(sp)
    80003b2e:	e426                	sd	s1,8(sp)
    80003b30:	1000                	addi	s0,sp,32
    80003b32:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b34:	0023c517          	auipc	a0,0x23c
    80003b38:	99c50513          	addi	a0,a0,-1636 # 8023f4d0 <itable>
    80003b3c:	ffffd097          	auipc	ra,0xffffd
    80003b40:	21a080e7          	jalr	538(ra) # 80000d56 <acquire>
  ip->ref++;
    80003b44:	449c                	lw	a5,8(s1)
    80003b46:	2785                	addiw	a5,a5,1
    80003b48:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b4a:	0023c517          	auipc	a0,0x23c
    80003b4e:	98650513          	addi	a0,a0,-1658 # 8023f4d0 <itable>
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	2b8080e7          	jalr	696(ra) # 80000e0a <release>
}
    80003b5a:	8526                	mv	a0,s1
    80003b5c:	60e2                	ld	ra,24(sp)
    80003b5e:	6442                	ld	s0,16(sp)
    80003b60:	64a2                	ld	s1,8(sp)
    80003b62:	6105                	addi	sp,sp,32
    80003b64:	8082                	ret

0000000080003b66 <ilock>:
{
    80003b66:	1101                	addi	sp,sp,-32
    80003b68:	ec06                	sd	ra,24(sp)
    80003b6a:	e822                	sd	s0,16(sp)
    80003b6c:	e426                	sd	s1,8(sp)
    80003b6e:	e04a                	sd	s2,0(sp)
    80003b70:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b72:	c115                	beqz	a0,80003b96 <ilock+0x30>
    80003b74:	84aa                	mv	s1,a0
    80003b76:	451c                	lw	a5,8(a0)
    80003b78:	00f05f63          	blez	a5,80003b96 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b7c:	0541                	addi	a0,a0,16
    80003b7e:	00001097          	auipc	ra,0x1
    80003b82:	ca2080e7          	jalr	-862(ra) # 80004820 <acquiresleep>
  if(ip->valid == 0){
    80003b86:	40bc                	lw	a5,64(s1)
    80003b88:	cf99                	beqz	a5,80003ba6 <ilock+0x40>
}
    80003b8a:	60e2                	ld	ra,24(sp)
    80003b8c:	6442                	ld	s0,16(sp)
    80003b8e:	64a2                	ld	s1,8(sp)
    80003b90:	6902                	ld	s2,0(sp)
    80003b92:	6105                	addi	sp,sp,32
    80003b94:	8082                	ret
    panic("ilock");
    80003b96:	00005517          	auipc	a0,0x5
    80003b9a:	a9250513          	addi	a0,a0,-1390 # 80008628 <syscalls+0x188>
    80003b9e:	ffffd097          	auipc	ra,0xffffd
    80003ba2:	9a0080e7          	jalr	-1632(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ba6:	40dc                	lw	a5,4(s1)
    80003ba8:	0047d79b          	srliw	a5,a5,0x4
    80003bac:	0023c597          	auipc	a1,0x23c
    80003bb0:	91c5a583          	lw	a1,-1764(a1) # 8023f4c8 <sb+0x18>
    80003bb4:	9dbd                	addw	a1,a1,a5
    80003bb6:	4088                	lw	a0,0(s1)
    80003bb8:	fffff097          	auipc	ra,0xfffff
    80003bbc:	794080e7          	jalr	1940(ra) # 8000334c <bread>
    80003bc0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bc2:	05850593          	addi	a1,a0,88
    80003bc6:	40dc                	lw	a5,4(s1)
    80003bc8:	8bbd                	andi	a5,a5,15
    80003bca:	079a                	slli	a5,a5,0x6
    80003bcc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bce:	00059783          	lh	a5,0(a1)
    80003bd2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003bd6:	00259783          	lh	a5,2(a1)
    80003bda:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003bde:	00459783          	lh	a5,4(a1)
    80003be2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003be6:	00659783          	lh	a5,6(a1)
    80003bea:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003bee:	459c                	lw	a5,8(a1)
    80003bf0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003bf2:	03400613          	li	a2,52
    80003bf6:	05b1                	addi	a1,a1,12
    80003bf8:	05048513          	addi	a0,s1,80
    80003bfc:	ffffd097          	auipc	ra,0xffffd
    80003c00:	2b2080e7          	jalr	690(ra) # 80000eae <memmove>
    brelse(bp);
    80003c04:	854a                	mv	a0,s2
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	876080e7          	jalr	-1930(ra) # 8000347c <brelse>
    ip->valid = 1;
    80003c0e:	4785                	li	a5,1
    80003c10:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c12:	04449783          	lh	a5,68(s1)
    80003c16:	fbb5                	bnez	a5,80003b8a <ilock+0x24>
      panic("ilock: no type");
    80003c18:	00005517          	auipc	a0,0x5
    80003c1c:	a1850513          	addi	a0,a0,-1512 # 80008630 <syscalls+0x190>
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	91e080e7          	jalr	-1762(ra) # 8000053e <panic>

0000000080003c28 <iunlock>:
{
    80003c28:	1101                	addi	sp,sp,-32
    80003c2a:	ec06                	sd	ra,24(sp)
    80003c2c:	e822                	sd	s0,16(sp)
    80003c2e:	e426                	sd	s1,8(sp)
    80003c30:	e04a                	sd	s2,0(sp)
    80003c32:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c34:	c905                	beqz	a0,80003c64 <iunlock+0x3c>
    80003c36:	84aa                	mv	s1,a0
    80003c38:	01050913          	addi	s2,a0,16
    80003c3c:	854a                	mv	a0,s2
    80003c3e:	00001097          	auipc	ra,0x1
    80003c42:	c7c080e7          	jalr	-900(ra) # 800048ba <holdingsleep>
    80003c46:	cd19                	beqz	a0,80003c64 <iunlock+0x3c>
    80003c48:	449c                	lw	a5,8(s1)
    80003c4a:	00f05d63          	blez	a5,80003c64 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c4e:	854a                	mv	a0,s2
    80003c50:	00001097          	auipc	ra,0x1
    80003c54:	c26080e7          	jalr	-986(ra) # 80004876 <releasesleep>
}
    80003c58:	60e2                	ld	ra,24(sp)
    80003c5a:	6442                	ld	s0,16(sp)
    80003c5c:	64a2                	ld	s1,8(sp)
    80003c5e:	6902                	ld	s2,0(sp)
    80003c60:	6105                	addi	sp,sp,32
    80003c62:	8082                	ret
    panic("iunlock");
    80003c64:	00005517          	auipc	a0,0x5
    80003c68:	9dc50513          	addi	a0,a0,-1572 # 80008640 <syscalls+0x1a0>
    80003c6c:	ffffd097          	auipc	ra,0xffffd
    80003c70:	8d2080e7          	jalr	-1838(ra) # 8000053e <panic>

0000000080003c74 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c74:	7179                	addi	sp,sp,-48
    80003c76:	f406                	sd	ra,40(sp)
    80003c78:	f022                	sd	s0,32(sp)
    80003c7a:	ec26                	sd	s1,24(sp)
    80003c7c:	e84a                	sd	s2,16(sp)
    80003c7e:	e44e                	sd	s3,8(sp)
    80003c80:	e052                	sd	s4,0(sp)
    80003c82:	1800                	addi	s0,sp,48
    80003c84:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c86:	05050493          	addi	s1,a0,80
    80003c8a:	08050913          	addi	s2,a0,128
    80003c8e:	a021                	j	80003c96 <itrunc+0x22>
    80003c90:	0491                	addi	s1,s1,4
    80003c92:	01248d63          	beq	s1,s2,80003cac <itrunc+0x38>
    if(ip->addrs[i]){
    80003c96:	408c                	lw	a1,0(s1)
    80003c98:	dde5                	beqz	a1,80003c90 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c9a:	0009a503          	lw	a0,0(s3)
    80003c9e:	00000097          	auipc	ra,0x0
    80003ca2:	8f4080e7          	jalr	-1804(ra) # 80003592 <bfree>
      ip->addrs[i] = 0;
    80003ca6:	0004a023          	sw	zero,0(s1)
    80003caa:	b7dd                	j	80003c90 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cac:	0809a583          	lw	a1,128(s3)
    80003cb0:	e185                	bnez	a1,80003cd0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cb2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003cb6:	854e                	mv	a0,s3
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	de4080e7          	jalr	-540(ra) # 80003a9c <iupdate>
}
    80003cc0:	70a2                	ld	ra,40(sp)
    80003cc2:	7402                	ld	s0,32(sp)
    80003cc4:	64e2                	ld	s1,24(sp)
    80003cc6:	6942                	ld	s2,16(sp)
    80003cc8:	69a2                	ld	s3,8(sp)
    80003cca:	6a02                	ld	s4,0(sp)
    80003ccc:	6145                	addi	sp,sp,48
    80003cce:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cd0:	0009a503          	lw	a0,0(s3)
    80003cd4:	fffff097          	auipc	ra,0xfffff
    80003cd8:	678080e7          	jalr	1656(ra) # 8000334c <bread>
    80003cdc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003cde:	05850493          	addi	s1,a0,88
    80003ce2:	45850913          	addi	s2,a0,1112
    80003ce6:	a021                	j	80003cee <itrunc+0x7a>
    80003ce8:	0491                	addi	s1,s1,4
    80003cea:	01248b63          	beq	s1,s2,80003d00 <itrunc+0x8c>
      if(a[j])
    80003cee:	408c                	lw	a1,0(s1)
    80003cf0:	dde5                	beqz	a1,80003ce8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003cf2:	0009a503          	lw	a0,0(s3)
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	89c080e7          	jalr	-1892(ra) # 80003592 <bfree>
    80003cfe:	b7ed                	j	80003ce8 <itrunc+0x74>
    brelse(bp);
    80003d00:	8552                	mv	a0,s4
    80003d02:	fffff097          	auipc	ra,0xfffff
    80003d06:	77a080e7          	jalr	1914(ra) # 8000347c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d0a:	0809a583          	lw	a1,128(s3)
    80003d0e:	0009a503          	lw	a0,0(s3)
    80003d12:	00000097          	auipc	ra,0x0
    80003d16:	880080e7          	jalr	-1920(ra) # 80003592 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d1a:	0809a023          	sw	zero,128(s3)
    80003d1e:	bf51                	j	80003cb2 <itrunc+0x3e>

0000000080003d20 <iput>:
{
    80003d20:	1101                	addi	sp,sp,-32
    80003d22:	ec06                	sd	ra,24(sp)
    80003d24:	e822                	sd	s0,16(sp)
    80003d26:	e426                	sd	s1,8(sp)
    80003d28:	e04a                	sd	s2,0(sp)
    80003d2a:	1000                	addi	s0,sp,32
    80003d2c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d2e:	0023b517          	auipc	a0,0x23b
    80003d32:	7a250513          	addi	a0,a0,1954 # 8023f4d0 <itable>
    80003d36:	ffffd097          	auipc	ra,0xffffd
    80003d3a:	020080e7          	jalr	32(ra) # 80000d56 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d3e:	4498                	lw	a4,8(s1)
    80003d40:	4785                	li	a5,1
    80003d42:	02f70363          	beq	a4,a5,80003d68 <iput+0x48>
  ip->ref--;
    80003d46:	449c                	lw	a5,8(s1)
    80003d48:	37fd                	addiw	a5,a5,-1
    80003d4a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d4c:	0023b517          	auipc	a0,0x23b
    80003d50:	78450513          	addi	a0,a0,1924 # 8023f4d0 <itable>
    80003d54:	ffffd097          	auipc	ra,0xffffd
    80003d58:	0b6080e7          	jalr	182(ra) # 80000e0a <release>
}
    80003d5c:	60e2                	ld	ra,24(sp)
    80003d5e:	6442                	ld	s0,16(sp)
    80003d60:	64a2                	ld	s1,8(sp)
    80003d62:	6902                	ld	s2,0(sp)
    80003d64:	6105                	addi	sp,sp,32
    80003d66:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d68:	40bc                	lw	a5,64(s1)
    80003d6a:	dff1                	beqz	a5,80003d46 <iput+0x26>
    80003d6c:	04a49783          	lh	a5,74(s1)
    80003d70:	fbf9                	bnez	a5,80003d46 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d72:	01048913          	addi	s2,s1,16
    80003d76:	854a                	mv	a0,s2
    80003d78:	00001097          	auipc	ra,0x1
    80003d7c:	aa8080e7          	jalr	-1368(ra) # 80004820 <acquiresleep>
    release(&itable.lock);
    80003d80:	0023b517          	auipc	a0,0x23b
    80003d84:	75050513          	addi	a0,a0,1872 # 8023f4d0 <itable>
    80003d88:	ffffd097          	auipc	ra,0xffffd
    80003d8c:	082080e7          	jalr	130(ra) # 80000e0a <release>
    itrunc(ip);
    80003d90:	8526                	mv	a0,s1
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	ee2080e7          	jalr	-286(ra) # 80003c74 <itrunc>
    ip->type = 0;
    80003d9a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d9e:	8526                	mv	a0,s1
    80003da0:	00000097          	auipc	ra,0x0
    80003da4:	cfc080e7          	jalr	-772(ra) # 80003a9c <iupdate>
    ip->valid = 0;
    80003da8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dac:	854a                	mv	a0,s2
    80003dae:	00001097          	auipc	ra,0x1
    80003db2:	ac8080e7          	jalr	-1336(ra) # 80004876 <releasesleep>
    acquire(&itable.lock);
    80003db6:	0023b517          	auipc	a0,0x23b
    80003dba:	71a50513          	addi	a0,a0,1818 # 8023f4d0 <itable>
    80003dbe:	ffffd097          	auipc	ra,0xffffd
    80003dc2:	f98080e7          	jalr	-104(ra) # 80000d56 <acquire>
    80003dc6:	b741                	j	80003d46 <iput+0x26>

0000000080003dc8 <iunlockput>:
{
    80003dc8:	1101                	addi	sp,sp,-32
    80003dca:	ec06                	sd	ra,24(sp)
    80003dcc:	e822                	sd	s0,16(sp)
    80003dce:	e426                	sd	s1,8(sp)
    80003dd0:	1000                	addi	s0,sp,32
    80003dd2:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	e54080e7          	jalr	-428(ra) # 80003c28 <iunlock>
  iput(ip);
    80003ddc:	8526                	mv	a0,s1
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	f42080e7          	jalr	-190(ra) # 80003d20 <iput>
}
    80003de6:	60e2                	ld	ra,24(sp)
    80003de8:	6442                	ld	s0,16(sp)
    80003dea:	64a2                	ld	s1,8(sp)
    80003dec:	6105                	addi	sp,sp,32
    80003dee:	8082                	ret

0000000080003df0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003df0:	1141                	addi	sp,sp,-16
    80003df2:	e422                	sd	s0,8(sp)
    80003df4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003df6:	411c                	lw	a5,0(a0)
    80003df8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003dfa:	415c                	lw	a5,4(a0)
    80003dfc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003dfe:	04451783          	lh	a5,68(a0)
    80003e02:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e06:	04a51783          	lh	a5,74(a0)
    80003e0a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e0e:	04c56783          	lwu	a5,76(a0)
    80003e12:	e99c                	sd	a5,16(a1)
}
    80003e14:	6422                	ld	s0,8(sp)
    80003e16:	0141                	addi	sp,sp,16
    80003e18:	8082                	ret

0000000080003e1a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e1a:	457c                	lw	a5,76(a0)
    80003e1c:	0ed7e963          	bltu	a5,a3,80003f0e <readi+0xf4>
{
    80003e20:	7159                	addi	sp,sp,-112
    80003e22:	f486                	sd	ra,104(sp)
    80003e24:	f0a2                	sd	s0,96(sp)
    80003e26:	eca6                	sd	s1,88(sp)
    80003e28:	e8ca                	sd	s2,80(sp)
    80003e2a:	e4ce                	sd	s3,72(sp)
    80003e2c:	e0d2                	sd	s4,64(sp)
    80003e2e:	fc56                	sd	s5,56(sp)
    80003e30:	f85a                	sd	s6,48(sp)
    80003e32:	f45e                	sd	s7,40(sp)
    80003e34:	f062                	sd	s8,32(sp)
    80003e36:	ec66                	sd	s9,24(sp)
    80003e38:	e86a                	sd	s10,16(sp)
    80003e3a:	e46e                	sd	s11,8(sp)
    80003e3c:	1880                	addi	s0,sp,112
    80003e3e:	8b2a                	mv	s6,a0
    80003e40:	8bae                	mv	s7,a1
    80003e42:	8a32                	mv	s4,a2
    80003e44:	84b6                	mv	s1,a3
    80003e46:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003e48:	9f35                	addw	a4,a4,a3
    return 0;
    80003e4a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e4c:	0ad76063          	bltu	a4,a3,80003eec <readi+0xd2>
  if(off + n > ip->size)
    80003e50:	00e7f463          	bgeu	a5,a4,80003e58 <readi+0x3e>
    n = ip->size - off;
    80003e54:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e58:	0a0a8963          	beqz	s5,80003f0a <readi+0xf0>
    80003e5c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e5e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e62:	5c7d                	li	s8,-1
    80003e64:	a82d                	j	80003e9e <readi+0x84>
    80003e66:	020d1d93          	slli	s11,s10,0x20
    80003e6a:	020ddd93          	srli	s11,s11,0x20
    80003e6e:	05890793          	addi	a5,s2,88
    80003e72:	86ee                	mv	a3,s11
    80003e74:	963e                	add	a2,a2,a5
    80003e76:	85d2                	mv	a1,s4
    80003e78:	855e                	mv	a0,s7
    80003e7a:	ffffe097          	auipc	ra,0xffffe
    80003e7e:	7d6080e7          	jalr	2006(ra) # 80002650 <either_copyout>
    80003e82:	05850d63          	beq	a0,s8,80003edc <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e86:	854a                	mv	a0,s2
    80003e88:	fffff097          	auipc	ra,0xfffff
    80003e8c:	5f4080e7          	jalr	1524(ra) # 8000347c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e90:	013d09bb          	addw	s3,s10,s3
    80003e94:	009d04bb          	addw	s1,s10,s1
    80003e98:	9a6e                	add	s4,s4,s11
    80003e9a:	0559f763          	bgeu	s3,s5,80003ee8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003e9e:	00a4d59b          	srliw	a1,s1,0xa
    80003ea2:	855a                	mv	a0,s6
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	8a2080e7          	jalr	-1886(ra) # 80003746 <bmap>
    80003eac:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003eb0:	cd85                	beqz	a1,80003ee8 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003eb2:	000b2503          	lw	a0,0(s6)
    80003eb6:	fffff097          	auipc	ra,0xfffff
    80003eba:	496080e7          	jalr	1174(ra) # 8000334c <bread>
    80003ebe:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ec0:	3ff4f613          	andi	a2,s1,1023
    80003ec4:	40cc87bb          	subw	a5,s9,a2
    80003ec8:	413a873b          	subw	a4,s5,s3
    80003ecc:	8d3e                	mv	s10,a5
    80003ece:	2781                	sext.w	a5,a5
    80003ed0:	0007069b          	sext.w	a3,a4
    80003ed4:	f8f6f9e3          	bgeu	a3,a5,80003e66 <readi+0x4c>
    80003ed8:	8d3a                	mv	s10,a4
    80003eda:	b771                	j	80003e66 <readi+0x4c>
      brelse(bp);
    80003edc:	854a                	mv	a0,s2
    80003ede:	fffff097          	auipc	ra,0xfffff
    80003ee2:	59e080e7          	jalr	1438(ra) # 8000347c <brelse>
      tot = -1;
    80003ee6:	59fd                	li	s3,-1
  }
  return tot;
    80003ee8:	0009851b          	sext.w	a0,s3
}
    80003eec:	70a6                	ld	ra,104(sp)
    80003eee:	7406                	ld	s0,96(sp)
    80003ef0:	64e6                	ld	s1,88(sp)
    80003ef2:	6946                	ld	s2,80(sp)
    80003ef4:	69a6                	ld	s3,72(sp)
    80003ef6:	6a06                	ld	s4,64(sp)
    80003ef8:	7ae2                	ld	s5,56(sp)
    80003efa:	7b42                	ld	s6,48(sp)
    80003efc:	7ba2                	ld	s7,40(sp)
    80003efe:	7c02                	ld	s8,32(sp)
    80003f00:	6ce2                	ld	s9,24(sp)
    80003f02:	6d42                	ld	s10,16(sp)
    80003f04:	6da2                	ld	s11,8(sp)
    80003f06:	6165                	addi	sp,sp,112
    80003f08:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f0a:	89d6                	mv	s3,s5
    80003f0c:	bff1                	j	80003ee8 <readi+0xce>
    return 0;
    80003f0e:	4501                	li	a0,0
}
    80003f10:	8082                	ret

0000000080003f12 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f12:	457c                	lw	a5,76(a0)
    80003f14:	10d7e863          	bltu	a5,a3,80004024 <writei+0x112>
{
    80003f18:	7159                	addi	sp,sp,-112
    80003f1a:	f486                	sd	ra,104(sp)
    80003f1c:	f0a2                	sd	s0,96(sp)
    80003f1e:	eca6                	sd	s1,88(sp)
    80003f20:	e8ca                	sd	s2,80(sp)
    80003f22:	e4ce                	sd	s3,72(sp)
    80003f24:	e0d2                	sd	s4,64(sp)
    80003f26:	fc56                	sd	s5,56(sp)
    80003f28:	f85a                	sd	s6,48(sp)
    80003f2a:	f45e                	sd	s7,40(sp)
    80003f2c:	f062                	sd	s8,32(sp)
    80003f2e:	ec66                	sd	s9,24(sp)
    80003f30:	e86a                	sd	s10,16(sp)
    80003f32:	e46e                	sd	s11,8(sp)
    80003f34:	1880                	addi	s0,sp,112
    80003f36:	8aaa                	mv	s5,a0
    80003f38:	8bae                	mv	s7,a1
    80003f3a:	8a32                	mv	s4,a2
    80003f3c:	8936                	mv	s2,a3
    80003f3e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f40:	00e687bb          	addw	a5,a3,a4
    80003f44:	0ed7e263          	bltu	a5,a3,80004028 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f48:	00043737          	lui	a4,0x43
    80003f4c:	0ef76063          	bltu	a4,a5,8000402c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f50:	0c0b0863          	beqz	s6,80004020 <writei+0x10e>
    80003f54:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f56:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f5a:	5c7d                	li	s8,-1
    80003f5c:	a091                	j	80003fa0 <writei+0x8e>
    80003f5e:	020d1d93          	slli	s11,s10,0x20
    80003f62:	020ddd93          	srli	s11,s11,0x20
    80003f66:	05848793          	addi	a5,s1,88
    80003f6a:	86ee                	mv	a3,s11
    80003f6c:	8652                	mv	a2,s4
    80003f6e:	85de                	mv	a1,s7
    80003f70:	953e                	add	a0,a0,a5
    80003f72:	ffffe097          	auipc	ra,0xffffe
    80003f76:	734080e7          	jalr	1844(ra) # 800026a6 <either_copyin>
    80003f7a:	07850263          	beq	a0,s8,80003fde <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f7e:	8526                	mv	a0,s1
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	780080e7          	jalr	1920(ra) # 80004700 <log_write>
    brelse(bp);
    80003f88:	8526                	mv	a0,s1
    80003f8a:	fffff097          	auipc	ra,0xfffff
    80003f8e:	4f2080e7          	jalr	1266(ra) # 8000347c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f92:	013d09bb          	addw	s3,s10,s3
    80003f96:	012d093b          	addw	s2,s10,s2
    80003f9a:	9a6e                	add	s4,s4,s11
    80003f9c:	0569f663          	bgeu	s3,s6,80003fe8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003fa0:	00a9559b          	srliw	a1,s2,0xa
    80003fa4:	8556                	mv	a0,s5
    80003fa6:	fffff097          	auipc	ra,0xfffff
    80003faa:	7a0080e7          	jalr	1952(ra) # 80003746 <bmap>
    80003fae:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003fb2:	c99d                	beqz	a1,80003fe8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003fb4:	000aa503          	lw	a0,0(s5)
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	394080e7          	jalr	916(ra) # 8000334c <bread>
    80003fc0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fc2:	3ff97513          	andi	a0,s2,1023
    80003fc6:	40ac87bb          	subw	a5,s9,a0
    80003fca:	413b073b          	subw	a4,s6,s3
    80003fce:	8d3e                	mv	s10,a5
    80003fd0:	2781                	sext.w	a5,a5
    80003fd2:	0007069b          	sext.w	a3,a4
    80003fd6:	f8f6f4e3          	bgeu	a3,a5,80003f5e <writei+0x4c>
    80003fda:	8d3a                	mv	s10,a4
    80003fdc:	b749                	j	80003f5e <writei+0x4c>
      brelse(bp);
    80003fde:	8526                	mv	a0,s1
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	49c080e7          	jalr	1180(ra) # 8000347c <brelse>
  }

  if(off > ip->size)
    80003fe8:	04caa783          	lw	a5,76(s5)
    80003fec:	0127f463          	bgeu	a5,s2,80003ff4 <writei+0xe2>
    ip->size = off;
    80003ff0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ff4:	8556                	mv	a0,s5
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	aa6080e7          	jalr	-1370(ra) # 80003a9c <iupdate>

  return tot;
    80003ffe:	0009851b          	sext.w	a0,s3
}
    80004002:	70a6                	ld	ra,104(sp)
    80004004:	7406                	ld	s0,96(sp)
    80004006:	64e6                	ld	s1,88(sp)
    80004008:	6946                	ld	s2,80(sp)
    8000400a:	69a6                	ld	s3,72(sp)
    8000400c:	6a06                	ld	s4,64(sp)
    8000400e:	7ae2                	ld	s5,56(sp)
    80004010:	7b42                	ld	s6,48(sp)
    80004012:	7ba2                	ld	s7,40(sp)
    80004014:	7c02                	ld	s8,32(sp)
    80004016:	6ce2                	ld	s9,24(sp)
    80004018:	6d42                	ld	s10,16(sp)
    8000401a:	6da2                	ld	s11,8(sp)
    8000401c:	6165                	addi	sp,sp,112
    8000401e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004020:	89da                	mv	s3,s6
    80004022:	bfc9                	j	80003ff4 <writei+0xe2>
    return -1;
    80004024:	557d                	li	a0,-1
}
    80004026:	8082                	ret
    return -1;
    80004028:	557d                	li	a0,-1
    8000402a:	bfe1                	j	80004002 <writei+0xf0>
    return -1;
    8000402c:	557d                	li	a0,-1
    8000402e:	bfd1                	j	80004002 <writei+0xf0>

0000000080004030 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004030:	1141                	addi	sp,sp,-16
    80004032:	e406                	sd	ra,8(sp)
    80004034:	e022                	sd	s0,0(sp)
    80004036:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004038:	4639                	li	a2,14
    8000403a:	ffffd097          	auipc	ra,0xffffd
    8000403e:	ee8080e7          	jalr	-280(ra) # 80000f22 <strncmp>
}
    80004042:	60a2                	ld	ra,8(sp)
    80004044:	6402                	ld	s0,0(sp)
    80004046:	0141                	addi	sp,sp,16
    80004048:	8082                	ret

000000008000404a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000404a:	7139                	addi	sp,sp,-64
    8000404c:	fc06                	sd	ra,56(sp)
    8000404e:	f822                	sd	s0,48(sp)
    80004050:	f426                	sd	s1,40(sp)
    80004052:	f04a                	sd	s2,32(sp)
    80004054:	ec4e                	sd	s3,24(sp)
    80004056:	e852                	sd	s4,16(sp)
    80004058:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000405a:	04451703          	lh	a4,68(a0)
    8000405e:	4785                	li	a5,1
    80004060:	00f71a63          	bne	a4,a5,80004074 <dirlookup+0x2a>
    80004064:	892a                	mv	s2,a0
    80004066:	89ae                	mv	s3,a1
    80004068:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000406a:	457c                	lw	a5,76(a0)
    8000406c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000406e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004070:	e79d                	bnez	a5,8000409e <dirlookup+0x54>
    80004072:	a8a5                	j	800040ea <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004074:	00004517          	auipc	a0,0x4
    80004078:	5d450513          	addi	a0,a0,1492 # 80008648 <syscalls+0x1a8>
    8000407c:	ffffc097          	auipc	ra,0xffffc
    80004080:	4c2080e7          	jalr	1218(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004084:	00004517          	auipc	a0,0x4
    80004088:	5dc50513          	addi	a0,a0,1500 # 80008660 <syscalls+0x1c0>
    8000408c:	ffffc097          	auipc	ra,0xffffc
    80004090:	4b2080e7          	jalr	1202(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004094:	24c1                	addiw	s1,s1,16
    80004096:	04c92783          	lw	a5,76(s2)
    8000409a:	04f4f763          	bgeu	s1,a5,800040e8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000409e:	4741                	li	a4,16
    800040a0:	86a6                	mv	a3,s1
    800040a2:	fc040613          	addi	a2,s0,-64
    800040a6:	4581                	li	a1,0
    800040a8:	854a                	mv	a0,s2
    800040aa:	00000097          	auipc	ra,0x0
    800040ae:	d70080e7          	jalr	-656(ra) # 80003e1a <readi>
    800040b2:	47c1                	li	a5,16
    800040b4:	fcf518e3          	bne	a0,a5,80004084 <dirlookup+0x3a>
    if(de.inum == 0)
    800040b8:	fc045783          	lhu	a5,-64(s0)
    800040bc:	dfe1                	beqz	a5,80004094 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040be:	fc240593          	addi	a1,s0,-62
    800040c2:	854e                	mv	a0,s3
    800040c4:	00000097          	auipc	ra,0x0
    800040c8:	f6c080e7          	jalr	-148(ra) # 80004030 <namecmp>
    800040cc:	f561                	bnez	a0,80004094 <dirlookup+0x4a>
      if(poff)
    800040ce:	000a0463          	beqz	s4,800040d6 <dirlookup+0x8c>
        *poff = off;
    800040d2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040d6:	fc045583          	lhu	a1,-64(s0)
    800040da:	00092503          	lw	a0,0(s2)
    800040de:	fffff097          	auipc	ra,0xfffff
    800040e2:	750080e7          	jalr	1872(ra) # 8000382e <iget>
    800040e6:	a011                	j	800040ea <dirlookup+0xa0>
  return 0;
    800040e8:	4501                	li	a0,0
}
    800040ea:	70e2                	ld	ra,56(sp)
    800040ec:	7442                	ld	s0,48(sp)
    800040ee:	74a2                	ld	s1,40(sp)
    800040f0:	7902                	ld	s2,32(sp)
    800040f2:	69e2                	ld	s3,24(sp)
    800040f4:	6a42                	ld	s4,16(sp)
    800040f6:	6121                	addi	sp,sp,64
    800040f8:	8082                	ret

00000000800040fa <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040fa:	711d                	addi	sp,sp,-96
    800040fc:	ec86                	sd	ra,88(sp)
    800040fe:	e8a2                	sd	s0,80(sp)
    80004100:	e4a6                	sd	s1,72(sp)
    80004102:	e0ca                	sd	s2,64(sp)
    80004104:	fc4e                	sd	s3,56(sp)
    80004106:	f852                	sd	s4,48(sp)
    80004108:	f456                	sd	s5,40(sp)
    8000410a:	f05a                	sd	s6,32(sp)
    8000410c:	ec5e                	sd	s7,24(sp)
    8000410e:	e862                	sd	s8,16(sp)
    80004110:	e466                	sd	s9,8(sp)
    80004112:	1080                	addi	s0,sp,96
    80004114:	84aa                	mv	s1,a0
    80004116:	8aae                	mv	s5,a1
    80004118:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000411a:	00054703          	lbu	a4,0(a0)
    8000411e:	02f00793          	li	a5,47
    80004122:	02f70363          	beq	a4,a5,80004148 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004126:	ffffe097          	auipc	ra,0xffffe
    8000412a:	a5a080e7          	jalr	-1446(ra) # 80001b80 <myproc>
    8000412e:	15053503          	ld	a0,336(a0)
    80004132:	00000097          	auipc	ra,0x0
    80004136:	9f6080e7          	jalr	-1546(ra) # 80003b28 <idup>
    8000413a:	89aa                	mv	s3,a0
  while(*path == '/')
    8000413c:	02f00913          	li	s2,47
  len = path - s;
    80004140:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004142:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004144:	4b85                	li	s7,1
    80004146:	a865                	j	800041fe <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004148:	4585                	li	a1,1
    8000414a:	4505                	li	a0,1
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	6e2080e7          	jalr	1762(ra) # 8000382e <iget>
    80004154:	89aa                	mv	s3,a0
    80004156:	b7dd                	j	8000413c <namex+0x42>
      iunlockput(ip);
    80004158:	854e                	mv	a0,s3
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	c6e080e7          	jalr	-914(ra) # 80003dc8 <iunlockput>
      return 0;
    80004162:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004164:	854e                	mv	a0,s3
    80004166:	60e6                	ld	ra,88(sp)
    80004168:	6446                	ld	s0,80(sp)
    8000416a:	64a6                	ld	s1,72(sp)
    8000416c:	6906                	ld	s2,64(sp)
    8000416e:	79e2                	ld	s3,56(sp)
    80004170:	7a42                	ld	s4,48(sp)
    80004172:	7aa2                	ld	s5,40(sp)
    80004174:	7b02                	ld	s6,32(sp)
    80004176:	6be2                	ld	s7,24(sp)
    80004178:	6c42                	ld	s8,16(sp)
    8000417a:	6ca2                	ld	s9,8(sp)
    8000417c:	6125                	addi	sp,sp,96
    8000417e:	8082                	ret
      iunlock(ip);
    80004180:	854e                	mv	a0,s3
    80004182:	00000097          	auipc	ra,0x0
    80004186:	aa6080e7          	jalr	-1370(ra) # 80003c28 <iunlock>
      return ip;
    8000418a:	bfe9                	j	80004164 <namex+0x6a>
      iunlockput(ip);
    8000418c:	854e                	mv	a0,s3
    8000418e:	00000097          	auipc	ra,0x0
    80004192:	c3a080e7          	jalr	-966(ra) # 80003dc8 <iunlockput>
      return 0;
    80004196:	89e6                	mv	s3,s9
    80004198:	b7f1                	j	80004164 <namex+0x6a>
  len = path - s;
    8000419a:	40b48633          	sub	a2,s1,a1
    8000419e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800041a2:	099c5463          	bge	s8,s9,8000422a <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041a6:	4639                	li	a2,14
    800041a8:	8552                	mv	a0,s4
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	d04080e7          	jalr	-764(ra) # 80000eae <memmove>
  while(*path == '/')
    800041b2:	0004c783          	lbu	a5,0(s1)
    800041b6:	01279763          	bne	a5,s2,800041c4 <namex+0xca>
    path++;
    800041ba:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041bc:	0004c783          	lbu	a5,0(s1)
    800041c0:	ff278de3          	beq	a5,s2,800041ba <namex+0xc0>
    ilock(ip);
    800041c4:	854e                	mv	a0,s3
    800041c6:	00000097          	auipc	ra,0x0
    800041ca:	9a0080e7          	jalr	-1632(ra) # 80003b66 <ilock>
    if(ip->type != T_DIR){
    800041ce:	04499783          	lh	a5,68(s3)
    800041d2:	f97793e3          	bne	a5,s7,80004158 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800041d6:	000a8563          	beqz	s5,800041e0 <namex+0xe6>
    800041da:	0004c783          	lbu	a5,0(s1)
    800041de:	d3cd                	beqz	a5,80004180 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041e0:	865a                	mv	a2,s6
    800041e2:	85d2                	mv	a1,s4
    800041e4:	854e                	mv	a0,s3
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	e64080e7          	jalr	-412(ra) # 8000404a <dirlookup>
    800041ee:	8caa                	mv	s9,a0
    800041f0:	dd51                	beqz	a0,8000418c <namex+0x92>
    iunlockput(ip);
    800041f2:	854e                	mv	a0,s3
    800041f4:	00000097          	auipc	ra,0x0
    800041f8:	bd4080e7          	jalr	-1068(ra) # 80003dc8 <iunlockput>
    ip = next;
    800041fc:	89e6                	mv	s3,s9
  while(*path == '/')
    800041fe:	0004c783          	lbu	a5,0(s1)
    80004202:	05279763          	bne	a5,s2,80004250 <namex+0x156>
    path++;
    80004206:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004208:	0004c783          	lbu	a5,0(s1)
    8000420c:	ff278de3          	beq	a5,s2,80004206 <namex+0x10c>
  if(*path == 0)
    80004210:	c79d                	beqz	a5,8000423e <namex+0x144>
    path++;
    80004212:	85a6                	mv	a1,s1
  len = path - s;
    80004214:	8cda                	mv	s9,s6
    80004216:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004218:	01278963          	beq	a5,s2,8000422a <namex+0x130>
    8000421c:	dfbd                	beqz	a5,8000419a <namex+0xa0>
    path++;
    8000421e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004220:	0004c783          	lbu	a5,0(s1)
    80004224:	ff279ce3          	bne	a5,s2,8000421c <namex+0x122>
    80004228:	bf8d                	j	8000419a <namex+0xa0>
    memmove(name, s, len);
    8000422a:	2601                	sext.w	a2,a2
    8000422c:	8552                	mv	a0,s4
    8000422e:	ffffd097          	auipc	ra,0xffffd
    80004232:	c80080e7          	jalr	-896(ra) # 80000eae <memmove>
    name[len] = 0;
    80004236:	9cd2                	add	s9,s9,s4
    80004238:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000423c:	bf9d                	j	800041b2 <namex+0xb8>
  if(nameiparent){
    8000423e:	f20a83e3          	beqz	s5,80004164 <namex+0x6a>
    iput(ip);
    80004242:	854e                	mv	a0,s3
    80004244:	00000097          	auipc	ra,0x0
    80004248:	adc080e7          	jalr	-1316(ra) # 80003d20 <iput>
    return 0;
    8000424c:	4981                	li	s3,0
    8000424e:	bf19                	j	80004164 <namex+0x6a>
  if(*path == 0)
    80004250:	d7fd                	beqz	a5,8000423e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004252:	0004c783          	lbu	a5,0(s1)
    80004256:	85a6                	mv	a1,s1
    80004258:	b7d1                	j	8000421c <namex+0x122>

000000008000425a <dirlink>:
{
    8000425a:	7139                	addi	sp,sp,-64
    8000425c:	fc06                	sd	ra,56(sp)
    8000425e:	f822                	sd	s0,48(sp)
    80004260:	f426                	sd	s1,40(sp)
    80004262:	f04a                	sd	s2,32(sp)
    80004264:	ec4e                	sd	s3,24(sp)
    80004266:	e852                	sd	s4,16(sp)
    80004268:	0080                	addi	s0,sp,64
    8000426a:	892a                	mv	s2,a0
    8000426c:	8a2e                	mv	s4,a1
    8000426e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004270:	4601                	li	a2,0
    80004272:	00000097          	auipc	ra,0x0
    80004276:	dd8080e7          	jalr	-552(ra) # 8000404a <dirlookup>
    8000427a:	e93d                	bnez	a0,800042f0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000427c:	04c92483          	lw	s1,76(s2)
    80004280:	c49d                	beqz	s1,800042ae <dirlink+0x54>
    80004282:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004284:	4741                	li	a4,16
    80004286:	86a6                	mv	a3,s1
    80004288:	fc040613          	addi	a2,s0,-64
    8000428c:	4581                	li	a1,0
    8000428e:	854a                	mv	a0,s2
    80004290:	00000097          	auipc	ra,0x0
    80004294:	b8a080e7          	jalr	-1142(ra) # 80003e1a <readi>
    80004298:	47c1                	li	a5,16
    8000429a:	06f51163          	bne	a0,a5,800042fc <dirlink+0xa2>
    if(de.inum == 0)
    8000429e:	fc045783          	lhu	a5,-64(s0)
    800042a2:	c791                	beqz	a5,800042ae <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042a4:	24c1                	addiw	s1,s1,16
    800042a6:	04c92783          	lw	a5,76(s2)
    800042aa:	fcf4ede3          	bltu	s1,a5,80004284 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042ae:	4639                	li	a2,14
    800042b0:	85d2                	mv	a1,s4
    800042b2:	fc240513          	addi	a0,s0,-62
    800042b6:	ffffd097          	auipc	ra,0xffffd
    800042ba:	ca8080e7          	jalr	-856(ra) # 80000f5e <strncpy>
  de.inum = inum;
    800042be:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042c2:	4741                	li	a4,16
    800042c4:	86a6                	mv	a3,s1
    800042c6:	fc040613          	addi	a2,s0,-64
    800042ca:	4581                	li	a1,0
    800042cc:	854a                	mv	a0,s2
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	c44080e7          	jalr	-956(ra) # 80003f12 <writei>
    800042d6:	1541                	addi	a0,a0,-16
    800042d8:	00a03533          	snez	a0,a0
    800042dc:	40a00533          	neg	a0,a0
}
    800042e0:	70e2                	ld	ra,56(sp)
    800042e2:	7442                	ld	s0,48(sp)
    800042e4:	74a2                	ld	s1,40(sp)
    800042e6:	7902                	ld	s2,32(sp)
    800042e8:	69e2                	ld	s3,24(sp)
    800042ea:	6a42                	ld	s4,16(sp)
    800042ec:	6121                	addi	sp,sp,64
    800042ee:	8082                	ret
    iput(ip);
    800042f0:	00000097          	auipc	ra,0x0
    800042f4:	a30080e7          	jalr	-1488(ra) # 80003d20 <iput>
    return -1;
    800042f8:	557d                	li	a0,-1
    800042fa:	b7dd                	j	800042e0 <dirlink+0x86>
      panic("dirlink read");
    800042fc:	00004517          	auipc	a0,0x4
    80004300:	37450513          	addi	a0,a0,884 # 80008670 <syscalls+0x1d0>
    80004304:	ffffc097          	auipc	ra,0xffffc
    80004308:	23a080e7          	jalr	570(ra) # 8000053e <panic>

000000008000430c <namei>:

struct inode*
namei(char *path)
{
    8000430c:	1101                	addi	sp,sp,-32
    8000430e:	ec06                	sd	ra,24(sp)
    80004310:	e822                	sd	s0,16(sp)
    80004312:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004314:	fe040613          	addi	a2,s0,-32
    80004318:	4581                	li	a1,0
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	de0080e7          	jalr	-544(ra) # 800040fa <namex>
}
    80004322:	60e2                	ld	ra,24(sp)
    80004324:	6442                	ld	s0,16(sp)
    80004326:	6105                	addi	sp,sp,32
    80004328:	8082                	ret

000000008000432a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000432a:	1141                	addi	sp,sp,-16
    8000432c:	e406                	sd	ra,8(sp)
    8000432e:	e022                	sd	s0,0(sp)
    80004330:	0800                	addi	s0,sp,16
    80004332:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004334:	4585                	li	a1,1
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	dc4080e7          	jalr	-572(ra) # 800040fa <namex>
}
    8000433e:	60a2                	ld	ra,8(sp)
    80004340:	6402                	ld	s0,0(sp)
    80004342:	0141                	addi	sp,sp,16
    80004344:	8082                	ret

0000000080004346 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004346:	1101                	addi	sp,sp,-32
    80004348:	ec06                	sd	ra,24(sp)
    8000434a:	e822                	sd	s0,16(sp)
    8000434c:	e426                	sd	s1,8(sp)
    8000434e:	e04a                	sd	s2,0(sp)
    80004350:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004352:	0023d917          	auipc	s2,0x23d
    80004356:	c2690913          	addi	s2,s2,-986 # 80240f78 <log>
    8000435a:	01892583          	lw	a1,24(s2)
    8000435e:	02892503          	lw	a0,40(s2)
    80004362:	fffff097          	auipc	ra,0xfffff
    80004366:	fea080e7          	jalr	-22(ra) # 8000334c <bread>
    8000436a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000436c:	02c92683          	lw	a3,44(s2)
    80004370:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004372:	02d05763          	blez	a3,800043a0 <write_head+0x5a>
    80004376:	0023d797          	auipc	a5,0x23d
    8000437a:	c3278793          	addi	a5,a5,-974 # 80240fa8 <log+0x30>
    8000437e:	05c50713          	addi	a4,a0,92
    80004382:	36fd                	addiw	a3,a3,-1
    80004384:	1682                	slli	a3,a3,0x20
    80004386:	9281                	srli	a3,a3,0x20
    80004388:	068a                	slli	a3,a3,0x2
    8000438a:	0023d617          	auipc	a2,0x23d
    8000438e:	c2260613          	addi	a2,a2,-990 # 80240fac <log+0x34>
    80004392:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004394:	4390                	lw	a2,0(a5)
    80004396:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004398:	0791                	addi	a5,a5,4
    8000439a:	0711                	addi	a4,a4,4
    8000439c:	fed79ce3          	bne	a5,a3,80004394 <write_head+0x4e>
  }
  bwrite(buf);
    800043a0:	8526                	mv	a0,s1
    800043a2:	fffff097          	auipc	ra,0xfffff
    800043a6:	09c080e7          	jalr	156(ra) # 8000343e <bwrite>
  brelse(buf);
    800043aa:	8526                	mv	a0,s1
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	0d0080e7          	jalr	208(ra) # 8000347c <brelse>
}
    800043b4:	60e2                	ld	ra,24(sp)
    800043b6:	6442                	ld	s0,16(sp)
    800043b8:	64a2                	ld	s1,8(sp)
    800043ba:	6902                	ld	s2,0(sp)
    800043bc:	6105                	addi	sp,sp,32
    800043be:	8082                	ret

00000000800043c0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043c0:	0023d797          	auipc	a5,0x23d
    800043c4:	be47a783          	lw	a5,-1052(a5) # 80240fa4 <log+0x2c>
    800043c8:	0af05d63          	blez	a5,80004482 <install_trans+0xc2>
{
    800043cc:	7139                	addi	sp,sp,-64
    800043ce:	fc06                	sd	ra,56(sp)
    800043d0:	f822                	sd	s0,48(sp)
    800043d2:	f426                	sd	s1,40(sp)
    800043d4:	f04a                	sd	s2,32(sp)
    800043d6:	ec4e                	sd	s3,24(sp)
    800043d8:	e852                	sd	s4,16(sp)
    800043da:	e456                	sd	s5,8(sp)
    800043dc:	e05a                	sd	s6,0(sp)
    800043de:	0080                	addi	s0,sp,64
    800043e0:	8b2a                	mv	s6,a0
    800043e2:	0023da97          	auipc	s5,0x23d
    800043e6:	bc6a8a93          	addi	s5,s5,-1082 # 80240fa8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ea:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043ec:	0023d997          	auipc	s3,0x23d
    800043f0:	b8c98993          	addi	s3,s3,-1140 # 80240f78 <log>
    800043f4:	a00d                	j	80004416 <install_trans+0x56>
    brelse(lbuf);
    800043f6:	854a                	mv	a0,s2
    800043f8:	fffff097          	auipc	ra,0xfffff
    800043fc:	084080e7          	jalr	132(ra) # 8000347c <brelse>
    brelse(dbuf);
    80004400:	8526                	mv	a0,s1
    80004402:	fffff097          	auipc	ra,0xfffff
    80004406:	07a080e7          	jalr	122(ra) # 8000347c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000440a:	2a05                	addiw	s4,s4,1
    8000440c:	0a91                	addi	s5,s5,4
    8000440e:	02c9a783          	lw	a5,44(s3)
    80004412:	04fa5e63          	bge	s4,a5,8000446e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004416:	0189a583          	lw	a1,24(s3)
    8000441a:	014585bb          	addw	a1,a1,s4
    8000441e:	2585                	addiw	a1,a1,1
    80004420:	0289a503          	lw	a0,40(s3)
    80004424:	fffff097          	auipc	ra,0xfffff
    80004428:	f28080e7          	jalr	-216(ra) # 8000334c <bread>
    8000442c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000442e:	000aa583          	lw	a1,0(s5)
    80004432:	0289a503          	lw	a0,40(s3)
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	f16080e7          	jalr	-234(ra) # 8000334c <bread>
    8000443e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004440:	40000613          	li	a2,1024
    80004444:	05890593          	addi	a1,s2,88
    80004448:	05850513          	addi	a0,a0,88
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	a62080e7          	jalr	-1438(ra) # 80000eae <memmove>
    bwrite(dbuf);  // write dst to disk
    80004454:	8526                	mv	a0,s1
    80004456:	fffff097          	auipc	ra,0xfffff
    8000445a:	fe8080e7          	jalr	-24(ra) # 8000343e <bwrite>
    if(recovering == 0)
    8000445e:	f80b1ce3          	bnez	s6,800043f6 <install_trans+0x36>
      bunpin(dbuf);
    80004462:	8526                	mv	a0,s1
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	0f2080e7          	jalr	242(ra) # 80003556 <bunpin>
    8000446c:	b769                	j	800043f6 <install_trans+0x36>
}
    8000446e:	70e2                	ld	ra,56(sp)
    80004470:	7442                	ld	s0,48(sp)
    80004472:	74a2                	ld	s1,40(sp)
    80004474:	7902                	ld	s2,32(sp)
    80004476:	69e2                	ld	s3,24(sp)
    80004478:	6a42                	ld	s4,16(sp)
    8000447a:	6aa2                	ld	s5,8(sp)
    8000447c:	6b02                	ld	s6,0(sp)
    8000447e:	6121                	addi	sp,sp,64
    80004480:	8082                	ret
    80004482:	8082                	ret

0000000080004484 <initlog>:
{
    80004484:	7179                	addi	sp,sp,-48
    80004486:	f406                	sd	ra,40(sp)
    80004488:	f022                	sd	s0,32(sp)
    8000448a:	ec26                	sd	s1,24(sp)
    8000448c:	e84a                	sd	s2,16(sp)
    8000448e:	e44e                	sd	s3,8(sp)
    80004490:	1800                	addi	s0,sp,48
    80004492:	892a                	mv	s2,a0
    80004494:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004496:	0023d497          	auipc	s1,0x23d
    8000449a:	ae248493          	addi	s1,s1,-1310 # 80240f78 <log>
    8000449e:	00004597          	auipc	a1,0x4
    800044a2:	1e258593          	addi	a1,a1,482 # 80008680 <syscalls+0x1e0>
    800044a6:	8526                	mv	a0,s1
    800044a8:	ffffd097          	auipc	ra,0xffffd
    800044ac:	81e080e7          	jalr	-2018(ra) # 80000cc6 <initlock>
  log.start = sb->logstart;
    800044b0:	0149a583          	lw	a1,20(s3)
    800044b4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044b6:	0109a783          	lw	a5,16(s3)
    800044ba:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044bc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044c0:	854a                	mv	a0,s2
    800044c2:	fffff097          	auipc	ra,0xfffff
    800044c6:	e8a080e7          	jalr	-374(ra) # 8000334c <bread>
  log.lh.n = lh->n;
    800044ca:	4d34                	lw	a3,88(a0)
    800044cc:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044ce:	02d05563          	blez	a3,800044f8 <initlog+0x74>
    800044d2:	05c50793          	addi	a5,a0,92
    800044d6:	0023d717          	auipc	a4,0x23d
    800044da:	ad270713          	addi	a4,a4,-1326 # 80240fa8 <log+0x30>
    800044de:	36fd                	addiw	a3,a3,-1
    800044e0:	1682                	slli	a3,a3,0x20
    800044e2:	9281                	srli	a3,a3,0x20
    800044e4:	068a                	slli	a3,a3,0x2
    800044e6:	06050613          	addi	a2,a0,96
    800044ea:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800044ec:	4390                	lw	a2,0(a5)
    800044ee:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044f0:	0791                	addi	a5,a5,4
    800044f2:	0711                	addi	a4,a4,4
    800044f4:	fed79ce3          	bne	a5,a3,800044ec <initlog+0x68>
  brelse(buf);
    800044f8:	fffff097          	auipc	ra,0xfffff
    800044fc:	f84080e7          	jalr	-124(ra) # 8000347c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004500:	4505                	li	a0,1
    80004502:	00000097          	auipc	ra,0x0
    80004506:	ebe080e7          	jalr	-322(ra) # 800043c0 <install_trans>
  log.lh.n = 0;
    8000450a:	0023d797          	auipc	a5,0x23d
    8000450e:	a807ad23          	sw	zero,-1382(a5) # 80240fa4 <log+0x2c>
  write_head(); // clear the log
    80004512:	00000097          	auipc	ra,0x0
    80004516:	e34080e7          	jalr	-460(ra) # 80004346 <write_head>
}
    8000451a:	70a2                	ld	ra,40(sp)
    8000451c:	7402                	ld	s0,32(sp)
    8000451e:	64e2                	ld	s1,24(sp)
    80004520:	6942                	ld	s2,16(sp)
    80004522:	69a2                	ld	s3,8(sp)
    80004524:	6145                	addi	sp,sp,48
    80004526:	8082                	ret

0000000080004528 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004528:	1101                	addi	sp,sp,-32
    8000452a:	ec06                	sd	ra,24(sp)
    8000452c:	e822                	sd	s0,16(sp)
    8000452e:	e426                	sd	s1,8(sp)
    80004530:	e04a                	sd	s2,0(sp)
    80004532:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004534:	0023d517          	auipc	a0,0x23d
    80004538:	a4450513          	addi	a0,a0,-1468 # 80240f78 <log>
    8000453c:	ffffd097          	auipc	ra,0xffffd
    80004540:	81a080e7          	jalr	-2022(ra) # 80000d56 <acquire>
  while(1){
    if(log.committing){
    80004544:	0023d497          	auipc	s1,0x23d
    80004548:	a3448493          	addi	s1,s1,-1484 # 80240f78 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000454c:	4979                	li	s2,30
    8000454e:	a039                	j	8000455c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004550:	85a6                	mv	a1,s1
    80004552:	8526                	mv	a0,s1
    80004554:	ffffe097          	auipc	ra,0xffffe
    80004558:	ce8080e7          	jalr	-792(ra) # 8000223c <sleep>
    if(log.committing){
    8000455c:	50dc                	lw	a5,36(s1)
    8000455e:	fbed                	bnez	a5,80004550 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004560:	509c                	lw	a5,32(s1)
    80004562:	0017871b          	addiw	a4,a5,1
    80004566:	0007069b          	sext.w	a3,a4
    8000456a:	0027179b          	slliw	a5,a4,0x2
    8000456e:	9fb9                	addw	a5,a5,a4
    80004570:	0017979b          	slliw	a5,a5,0x1
    80004574:	54d8                	lw	a4,44(s1)
    80004576:	9fb9                	addw	a5,a5,a4
    80004578:	00f95963          	bge	s2,a5,8000458a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000457c:	85a6                	mv	a1,s1
    8000457e:	8526                	mv	a0,s1
    80004580:	ffffe097          	auipc	ra,0xffffe
    80004584:	cbc080e7          	jalr	-836(ra) # 8000223c <sleep>
    80004588:	bfd1                	j	8000455c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000458a:	0023d517          	auipc	a0,0x23d
    8000458e:	9ee50513          	addi	a0,a0,-1554 # 80240f78 <log>
    80004592:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004594:	ffffd097          	auipc	ra,0xffffd
    80004598:	876080e7          	jalr	-1930(ra) # 80000e0a <release>
      break;
    }
  }
}
    8000459c:	60e2                	ld	ra,24(sp)
    8000459e:	6442                	ld	s0,16(sp)
    800045a0:	64a2                	ld	s1,8(sp)
    800045a2:	6902                	ld	s2,0(sp)
    800045a4:	6105                	addi	sp,sp,32
    800045a6:	8082                	ret

00000000800045a8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045a8:	7139                	addi	sp,sp,-64
    800045aa:	fc06                	sd	ra,56(sp)
    800045ac:	f822                	sd	s0,48(sp)
    800045ae:	f426                	sd	s1,40(sp)
    800045b0:	f04a                	sd	s2,32(sp)
    800045b2:	ec4e                	sd	s3,24(sp)
    800045b4:	e852                	sd	s4,16(sp)
    800045b6:	e456                	sd	s5,8(sp)
    800045b8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045ba:	0023d497          	auipc	s1,0x23d
    800045be:	9be48493          	addi	s1,s1,-1602 # 80240f78 <log>
    800045c2:	8526                	mv	a0,s1
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	792080e7          	jalr	1938(ra) # 80000d56 <acquire>
  log.outstanding -= 1;
    800045cc:	509c                	lw	a5,32(s1)
    800045ce:	37fd                	addiw	a5,a5,-1
    800045d0:	0007891b          	sext.w	s2,a5
    800045d4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800045d6:	50dc                	lw	a5,36(s1)
    800045d8:	e7b9                	bnez	a5,80004626 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045da:	04091e63          	bnez	s2,80004636 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800045de:	0023d497          	auipc	s1,0x23d
    800045e2:	99a48493          	addi	s1,s1,-1638 # 80240f78 <log>
    800045e6:	4785                	li	a5,1
    800045e8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045ea:	8526                	mv	a0,s1
    800045ec:	ffffd097          	auipc	ra,0xffffd
    800045f0:	81e080e7          	jalr	-2018(ra) # 80000e0a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045f4:	54dc                	lw	a5,44(s1)
    800045f6:	06f04763          	bgtz	a5,80004664 <end_op+0xbc>
    acquire(&log.lock);
    800045fa:	0023d497          	auipc	s1,0x23d
    800045fe:	97e48493          	addi	s1,s1,-1666 # 80240f78 <log>
    80004602:	8526                	mv	a0,s1
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	752080e7          	jalr	1874(ra) # 80000d56 <acquire>
    log.committing = 0;
    8000460c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004610:	8526                	mv	a0,s1
    80004612:	ffffe097          	auipc	ra,0xffffe
    80004616:	c8e080e7          	jalr	-882(ra) # 800022a0 <wakeup>
    release(&log.lock);
    8000461a:	8526                	mv	a0,s1
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	7ee080e7          	jalr	2030(ra) # 80000e0a <release>
}
    80004624:	a03d                	j	80004652 <end_op+0xaa>
    panic("log.committing");
    80004626:	00004517          	auipc	a0,0x4
    8000462a:	06250513          	addi	a0,a0,98 # 80008688 <syscalls+0x1e8>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	f10080e7          	jalr	-240(ra) # 8000053e <panic>
    wakeup(&log);
    80004636:	0023d497          	auipc	s1,0x23d
    8000463a:	94248493          	addi	s1,s1,-1726 # 80240f78 <log>
    8000463e:	8526                	mv	a0,s1
    80004640:	ffffe097          	auipc	ra,0xffffe
    80004644:	c60080e7          	jalr	-928(ra) # 800022a0 <wakeup>
  release(&log.lock);
    80004648:	8526                	mv	a0,s1
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	7c0080e7          	jalr	1984(ra) # 80000e0a <release>
}
    80004652:	70e2                	ld	ra,56(sp)
    80004654:	7442                	ld	s0,48(sp)
    80004656:	74a2                	ld	s1,40(sp)
    80004658:	7902                	ld	s2,32(sp)
    8000465a:	69e2                	ld	s3,24(sp)
    8000465c:	6a42                	ld	s4,16(sp)
    8000465e:	6aa2                	ld	s5,8(sp)
    80004660:	6121                	addi	sp,sp,64
    80004662:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004664:	0023da97          	auipc	s5,0x23d
    80004668:	944a8a93          	addi	s5,s5,-1724 # 80240fa8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000466c:	0023da17          	auipc	s4,0x23d
    80004670:	90ca0a13          	addi	s4,s4,-1780 # 80240f78 <log>
    80004674:	018a2583          	lw	a1,24(s4)
    80004678:	012585bb          	addw	a1,a1,s2
    8000467c:	2585                	addiw	a1,a1,1
    8000467e:	028a2503          	lw	a0,40(s4)
    80004682:	fffff097          	auipc	ra,0xfffff
    80004686:	cca080e7          	jalr	-822(ra) # 8000334c <bread>
    8000468a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000468c:	000aa583          	lw	a1,0(s5)
    80004690:	028a2503          	lw	a0,40(s4)
    80004694:	fffff097          	auipc	ra,0xfffff
    80004698:	cb8080e7          	jalr	-840(ra) # 8000334c <bread>
    8000469c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000469e:	40000613          	li	a2,1024
    800046a2:	05850593          	addi	a1,a0,88
    800046a6:	05848513          	addi	a0,s1,88
    800046aa:	ffffd097          	auipc	ra,0xffffd
    800046ae:	804080e7          	jalr	-2044(ra) # 80000eae <memmove>
    bwrite(to);  // write the log
    800046b2:	8526                	mv	a0,s1
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	d8a080e7          	jalr	-630(ra) # 8000343e <bwrite>
    brelse(from);
    800046bc:	854e                	mv	a0,s3
    800046be:	fffff097          	auipc	ra,0xfffff
    800046c2:	dbe080e7          	jalr	-578(ra) # 8000347c <brelse>
    brelse(to);
    800046c6:	8526                	mv	a0,s1
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	db4080e7          	jalr	-588(ra) # 8000347c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046d0:	2905                	addiw	s2,s2,1
    800046d2:	0a91                	addi	s5,s5,4
    800046d4:	02ca2783          	lw	a5,44(s4)
    800046d8:	f8f94ee3          	blt	s2,a5,80004674 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046dc:	00000097          	auipc	ra,0x0
    800046e0:	c6a080e7          	jalr	-918(ra) # 80004346 <write_head>
    install_trans(0); // Now install writes to home locations
    800046e4:	4501                	li	a0,0
    800046e6:	00000097          	auipc	ra,0x0
    800046ea:	cda080e7          	jalr	-806(ra) # 800043c0 <install_trans>
    log.lh.n = 0;
    800046ee:	0023d797          	auipc	a5,0x23d
    800046f2:	8a07ab23          	sw	zero,-1866(a5) # 80240fa4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046f6:	00000097          	auipc	ra,0x0
    800046fa:	c50080e7          	jalr	-944(ra) # 80004346 <write_head>
    800046fe:	bdf5                	j	800045fa <end_op+0x52>

0000000080004700 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004700:	1101                	addi	sp,sp,-32
    80004702:	ec06                	sd	ra,24(sp)
    80004704:	e822                	sd	s0,16(sp)
    80004706:	e426                	sd	s1,8(sp)
    80004708:	e04a                	sd	s2,0(sp)
    8000470a:	1000                	addi	s0,sp,32
    8000470c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000470e:	0023d917          	auipc	s2,0x23d
    80004712:	86a90913          	addi	s2,s2,-1942 # 80240f78 <log>
    80004716:	854a                	mv	a0,s2
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	63e080e7          	jalr	1598(ra) # 80000d56 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004720:	02c92603          	lw	a2,44(s2)
    80004724:	47f5                	li	a5,29
    80004726:	06c7c563          	blt	a5,a2,80004790 <log_write+0x90>
    8000472a:	0023d797          	auipc	a5,0x23d
    8000472e:	86a7a783          	lw	a5,-1942(a5) # 80240f94 <log+0x1c>
    80004732:	37fd                	addiw	a5,a5,-1
    80004734:	04f65e63          	bge	a2,a5,80004790 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004738:	0023d797          	auipc	a5,0x23d
    8000473c:	8607a783          	lw	a5,-1952(a5) # 80240f98 <log+0x20>
    80004740:	06f05063          	blez	a5,800047a0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004744:	4781                	li	a5,0
    80004746:	06c05563          	blez	a2,800047b0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000474a:	44cc                	lw	a1,12(s1)
    8000474c:	0023d717          	auipc	a4,0x23d
    80004750:	85c70713          	addi	a4,a4,-1956 # 80240fa8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004754:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004756:	4314                	lw	a3,0(a4)
    80004758:	04b68c63          	beq	a3,a1,800047b0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000475c:	2785                	addiw	a5,a5,1
    8000475e:	0711                	addi	a4,a4,4
    80004760:	fef61be3          	bne	a2,a5,80004756 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004764:	0621                	addi	a2,a2,8
    80004766:	060a                	slli	a2,a2,0x2
    80004768:	0023d797          	auipc	a5,0x23d
    8000476c:	81078793          	addi	a5,a5,-2032 # 80240f78 <log>
    80004770:	963e                	add	a2,a2,a5
    80004772:	44dc                	lw	a5,12(s1)
    80004774:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004776:	8526                	mv	a0,s1
    80004778:	fffff097          	auipc	ra,0xfffff
    8000477c:	da2080e7          	jalr	-606(ra) # 8000351a <bpin>
    log.lh.n++;
    80004780:	0023c717          	auipc	a4,0x23c
    80004784:	7f870713          	addi	a4,a4,2040 # 80240f78 <log>
    80004788:	575c                	lw	a5,44(a4)
    8000478a:	2785                	addiw	a5,a5,1
    8000478c:	d75c                	sw	a5,44(a4)
    8000478e:	a835                	j	800047ca <log_write+0xca>
    panic("too big a transaction");
    80004790:	00004517          	auipc	a0,0x4
    80004794:	f0850513          	addi	a0,a0,-248 # 80008698 <syscalls+0x1f8>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	da6080e7          	jalr	-602(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800047a0:	00004517          	auipc	a0,0x4
    800047a4:	f1050513          	addi	a0,a0,-240 # 800086b0 <syscalls+0x210>
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	d96080e7          	jalr	-618(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800047b0:	00878713          	addi	a4,a5,8
    800047b4:	00271693          	slli	a3,a4,0x2
    800047b8:	0023c717          	auipc	a4,0x23c
    800047bc:	7c070713          	addi	a4,a4,1984 # 80240f78 <log>
    800047c0:	9736                	add	a4,a4,a3
    800047c2:	44d4                	lw	a3,12(s1)
    800047c4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047c6:	faf608e3          	beq	a2,a5,80004776 <log_write+0x76>
  }
  release(&log.lock);
    800047ca:	0023c517          	auipc	a0,0x23c
    800047ce:	7ae50513          	addi	a0,a0,1966 # 80240f78 <log>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	638080e7          	jalr	1592(ra) # 80000e0a <release>
}
    800047da:	60e2                	ld	ra,24(sp)
    800047dc:	6442                	ld	s0,16(sp)
    800047de:	64a2                	ld	s1,8(sp)
    800047e0:	6902                	ld	s2,0(sp)
    800047e2:	6105                	addi	sp,sp,32
    800047e4:	8082                	ret

00000000800047e6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047e6:	1101                	addi	sp,sp,-32
    800047e8:	ec06                	sd	ra,24(sp)
    800047ea:	e822                	sd	s0,16(sp)
    800047ec:	e426                	sd	s1,8(sp)
    800047ee:	e04a                	sd	s2,0(sp)
    800047f0:	1000                	addi	s0,sp,32
    800047f2:	84aa                	mv	s1,a0
    800047f4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047f6:	00004597          	auipc	a1,0x4
    800047fa:	eda58593          	addi	a1,a1,-294 # 800086d0 <syscalls+0x230>
    800047fe:	0521                	addi	a0,a0,8
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	4c6080e7          	jalr	1222(ra) # 80000cc6 <initlock>
  lk->name = name;
    80004808:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000480c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004810:	0204a423          	sw	zero,40(s1)
}
    80004814:	60e2                	ld	ra,24(sp)
    80004816:	6442                	ld	s0,16(sp)
    80004818:	64a2                	ld	s1,8(sp)
    8000481a:	6902                	ld	s2,0(sp)
    8000481c:	6105                	addi	sp,sp,32
    8000481e:	8082                	ret

0000000080004820 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004820:	1101                	addi	sp,sp,-32
    80004822:	ec06                	sd	ra,24(sp)
    80004824:	e822                	sd	s0,16(sp)
    80004826:	e426                	sd	s1,8(sp)
    80004828:	e04a                	sd	s2,0(sp)
    8000482a:	1000                	addi	s0,sp,32
    8000482c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000482e:	00850913          	addi	s2,a0,8
    80004832:	854a                	mv	a0,s2
    80004834:	ffffc097          	auipc	ra,0xffffc
    80004838:	522080e7          	jalr	1314(ra) # 80000d56 <acquire>
  while (lk->locked) {
    8000483c:	409c                	lw	a5,0(s1)
    8000483e:	cb89                	beqz	a5,80004850 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004840:	85ca                	mv	a1,s2
    80004842:	8526                	mv	a0,s1
    80004844:	ffffe097          	auipc	ra,0xffffe
    80004848:	9f8080e7          	jalr	-1544(ra) # 8000223c <sleep>
  while (lk->locked) {
    8000484c:	409c                	lw	a5,0(s1)
    8000484e:	fbed                	bnez	a5,80004840 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004850:	4785                	li	a5,1
    80004852:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004854:	ffffd097          	auipc	ra,0xffffd
    80004858:	32c080e7          	jalr	812(ra) # 80001b80 <myproc>
    8000485c:	591c                	lw	a5,48(a0)
    8000485e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004860:	854a                	mv	a0,s2
    80004862:	ffffc097          	auipc	ra,0xffffc
    80004866:	5a8080e7          	jalr	1448(ra) # 80000e0a <release>
}
    8000486a:	60e2                	ld	ra,24(sp)
    8000486c:	6442                	ld	s0,16(sp)
    8000486e:	64a2                	ld	s1,8(sp)
    80004870:	6902                	ld	s2,0(sp)
    80004872:	6105                	addi	sp,sp,32
    80004874:	8082                	ret

0000000080004876 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004876:	1101                	addi	sp,sp,-32
    80004878:	ec06                	sd	ra,24(sp)
    8000487a:	e822                	sd	s0,16(sp)
    8000487c:	e426                	sd	s1,8(sp)
    8000487e:	e04a                	sd	s2,0(sp)
    80004880:	1000                	addi	s0,sp,32
    80004882:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004884:	00850913          	addi	s2,a0,8
    80004888:	854a                	mv	a0,s2
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	4cc080e7          	jalr	1228(ra) # 80000d56 <acquire>
  lk->locked = 0;
    80004892:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004896:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000489a:	8526                	mv	a0,s1
    8000489c:	ffffe097          	auipc	ra,0xffffe
    800048a0:	a04080e7          	jalr	-1532(ra) # 800022a0 <wakeup>
  release(&lk->lk);
    800048a4:	854a                	mv	a0,s2
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	564080e7          	jalr	1380(ra) # 80000e0a <release>
}
    800048ae:	60e2                	ld	ra,24(sp)
    800048b0:	6442                	ld	s0,16(sp)
    800048b2:	64a2                	ld	s1,8(sp)
    800048b4:	6902                	ld	s2,0(sp)
    800048b6:	6105                	addi	sp,sp,32
    800048b8:	8082                	ret

00000000800048ba <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048ba:	7179                	addi	sp,sp,-48
    800048bc:	f406                	sd	ra,40(sp)
    800048be:	f022                	sd	s0,32(sp)
    800048c0:	ec26                	sd	s1,24(sp)
    800048c2:	e84a                	sd	s2,16(sp)
    800048c4:	e44e                	sd	s3,8(sp)
    800048c6:	1800                	addi	s0,sp,48
    800048c8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048ca:	00850913          	addi	s2,a0,8
    800048ce:	854a                	mv	a0,s2
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	486080e7          	jalr	1158(ra) # 80000d56 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048d8:	409c                	lw	a5,0(s1)
    800048da:	ef99                	bnez	a5,800048f8 <holdingsleep+0x3e>
    800048dc:	4481                	li	s1,0
  release(&lk->lk);
    800048de:	854a                	mv	a0,s2
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	52a080e7          	jalr	1322(ra) # 80000e0a <release>
  return r;
}
    800048e8:	8526                	mv	a0,s1
    800048ea:	70a2                	ld	ra,40(sp)
    800048ec:	7402                	ld	s0,32(sp)
    800048ee:	64e2                	ld	s1,24(sp)
    800048f0:	6942                	ld	s2,16(sp)
    800048f2:	69a2                	ld	s3,8(sp)
    800048f4:	6145                	addi	sp,sp,48
    800048f6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048f8:	0284a983          	lw	s3,40(s1)
    800048fc:	ffffd097          	auipc	ra,0xffffd
    80004900:	284080e7          	jalr	644(ra) # 80001b80 <myproc>
    80004904:	5904                	lw	s1,48(a0)
    80004906:	413484b3          	sub	s1,s1,s3
    8000490a:	0014b493          	seqz	s1,s1
    8000490e:	bfc1                	j	800048de <holdingsleep+0x24>

0000000080004910 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004910:	1141                	addi	sp,sp,-16
    80004912:	e406                	sd	ra,8(sp)
    80004914:	e022                	sd	s0,0(sp)
    80004916:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004918:	00004597          	auipc	a1,0x4
    8000491c:	dc858593          	addi	a1,a1,-568 # 800086e0 <syscalls+0x240>
    80004920:	0023c517          	auipc	a0,0x23c
    80004924:	7a050513          	addi	a0,a0,1952 # 802410c0 <ftable>
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	39e080e7          	jalr	926(ra) # 80000cc6 <initlock>
}
    80004930:	60a2                	ld	ra,8(sp)
    80004932:	6402                	ld	s0,0(sp)
    80004934:	0141                	addi	sp,sp,16
    80004936:	8082                	ret

0000000080004938 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004938:	1101                	addi	sp,sp,-32
    8000493a:	ec06                	sd	ra,24(sp)
    8000493c:	e822                	sd	s0,16(sp)
    8000493e:	e426                	sd	s1,8(sp)
    80004940:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004942:	0023c517          	auipc	a0,0x23c
    80004946:	77e50513          	addi	a0,a0,1918 # 802410c0 <ftable>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	40c080e7          	jalr	1036(ra) # 80000d56 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004952:	0023c497          	auipc	s1,0x23c
    80004956:	78648493          	addi	s1,s1,1926 # 802410d8 <ftable+0x18>
    8000495a:	0023d717          	auipc	a4,0x23d
    8000495e:	71e70713          	addi	a4,a4,1822 # 80242078 <disk>
    if(f->ref == 0){
    80004962:	40dc                	lw	a5,4(s1)
    80004964:	cf99                	beqz	a5,80004982 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004966:	02848493          	addi	s1,s1,40
    8000496a:	fee49ce3          	bne	s1,a4,80004962 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000496e:	0023c517          	auipc	a0,0x23c
    80004972:	75250513          	addi	a0,a0,1874 # 802410c0 <ftable>
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	494080e7          	jalr	1172(ra) # 80000e0a <release>
  return 0;
    8000497e:	4481                	li	s1,0
    80004980:	a819                	j	80004996 <filealloc+0x5e>
      f->ref = 1;
    80004982:	4785                	li	a5,1
    80004984:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004986:	0023c517          	auipc	a0,0x23c
    8000498a:	73a50513          	addi	a0,a0,1850 # 802410c0 <ftable>
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	47c080e7          	jalr	1148(ra) # 80000e0a <release>
}
    80004996:	8526                	mv	a0,s1
    80004998:	60e2                	ld	ra,24(sp)
    8000499a:	6442                	ld	s0,16(sp)
    8000499c:	64a2                	ld	s1,8(sp)
    8000499e:	6105                	addi	sp,sp,32
    800049a0:	8082                	ret

00000000800049a2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049a2:	1101                	addi	sp,sp,-32
    800049a4:	ec06                	sd	ra,24(sp)
    800049a6:	e822                	sd	s0,16(sp)
    800049a8:	e426                	sd	s1,8(sp)
    800049aa:	1000                	addi	s0,sp,32
    800049ac:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049ae:	0023c517          	auipc	a0,0x23c
    800049b2:	71250513          	addi	a0,a0,1810 # 802410c0 <ftable>
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	3a0080e7          	jalr	928(ra) # 80000d56 <acquire>
  if(f->ref < 1)
    800049be:	40dc                	lw	a5,4(s1)
    800049c0:	02f05263          	blez	a5,800049e4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049c4:	2785                	addiw	a5,a5,1
    800049c6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049c8:	0023c517          	auipc	a0,0x23c
    800049cc:	6f850513          	addi	a0,a0,1784 # 802410c0 <ftable>
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	43a080e7          	jalr	1082(ra) # 80000e0a <release>
  return f;
}
    800049d8:	8526                	mv	a0,s1
    800049da:	60e2                	ld	ra,24(sp)
    800049dc:	6442                	ld	s0,16(sp)
    800049de:	64a2                	ld	s1,8(sp)
    800049e0:	6105                	addi	sp,sp,32
    800049e2:	8082                	ret
    panic("filedup");
    800049e4:	00004517          	auipc	a0,0x4
    800049e8:	d0450513          	addi	a0,a0,-764 # 800086e8 <syscalls+0x248>
    800049ec:	ffffc097          	auipc	ra,0xffffc
    800049f0:	b52080e7          	jalr	-1198(ra) # 8000053e <panic>

00000000800049f4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049f4:	7139                	addi	sp,sp,-64
    800049f6:	fc06                	sd	ra,56(sp)
    800049f8:	f822                	sd	s0,48(sp)
    800049fa:	f426                	sd	s1,40(sp)
    800049fc:	f04a                	sd	s2,32(sp)
    800049fe:	ec4e                	sd	s3,24(sp)
    80004a00:	e852                	sd	s4,16(sp)
    80004a02:	e456                	sd	s5,8(sp)
    80004a04:	0080                	addi	s0,sp,64
    80004a06:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a08:	0023c517          	auipc	a0,0x23c
    80004a0c:	6b850513          	addi	a0,a0,1720 # 802410c0 <ftable>
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	346080e7          	jalr	838(ra) # 80000d56 <acquire>
  if(f->ref < 1)
    80004a18:	40dc                	lw	a5,4(s1)
    80004a1a:	06f05163          	blez	a5,80004a7c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a1e:	37fd                	addiw	a5,a5,-1
    80004a20:	0007871b          	sext.w	a4,a5
    80004a24:	c0dc                	sw	a5,4(s1)
    80004a26:	06e04363          	bgtz	a4,80004a8c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a2a:	0004a903          	lw	s2,0(s1)
    80004a2e:	0094ca83          	lbu	s5,9(s1)
    80004a32:	0104ba03          	ld	s4,16(s1)
    80004a36:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a3a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a3e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a42:	0023c517          	auipc	a0,0x23c
    80004a46:	67e50513          	addi	a0,a0,1662 # 802410c0 <ftable>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	3c0080e7          	jalr	960(ra) # 80000e0a <release>

  if(ff.type == FD_PIPE){
    80004a52:	4785                	li	a5,1
    80004a54:	04f90d63          	beq	s2,a5,80004aae <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a58:	3979                	addiw	s2,s2,-2
    80004a5a:	4785                	li	a5,1
    80004a5c:	0527e063          	bltu	a5,s2,80004a9c <fileclose+0xa8>
    begin_op();
    80004a60:	00000097          	auipc	ra,0x0
    80004a64:	ac8080e7          	jalr	-1336(ra) # 80004528 <begin_op>
    iput(ff.ip);
    80004a68:	854e                	mv	a0,s3
    80004a6a:	fffff097          	auipc	ra,0xfffff
    80004a6e:	2b6080e7          	jalr	694(ra) # 80003d20 <iput>
    end_op();
    80004a72:	00000097          	auipc	ra,0x0
    80004a76:	b36080e7          	jalr	-1226(ra) # 800045a8 <end_op>
    80004a7a:	a00d                	j	80004a9c <fileclose+0xa8>
    panic("fileclose");
    80004a7c:	00004517          	auipc	a0,0x4
    80004a80:	c7450513          	addi	a0,a0,-908 # 800086f0 <syscalls+0x250>
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	aba080e7          	jalr	-1350(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004a8c:	0023c517          	auipc	a0,0x23c
    80004a90:	63450513          	addi	a0,a0,1588 # 802410c0 <ftable>
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	376080e7          	jalr	886(ra) # 80000e0a <release>
  }
}
    80004a9c:	70e2                	ld	ra,56(sp)
    80004a9e:	7442                	ld	s0,48(sp)
    80004aa0:	74a2                	ld	s1,40(sp)
    80004aa2:	7902                	ld	s2,32(sp)
    80004aa4:	69e2                	ld	s3,24(sp)
    80004aa6:	6a42                	ld	s4,16(sp)
    80004aa8:	6aa2                	ld	s5,8(sp)
    80004aaa:	6121                	addi	sp,sp,64
    80004aac:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004aae:	85d6                	mv	a1,s5
    80004ab0:	8552                	mv	a0,s4
    80004ab2:	00000097          	auipc	ra,0x0
    80004ab6:	34c080e7          	jalr	844(ra) # 80004dfe <pipeclose>
    80004aba:	b7cd                	j	80004a9c <fileclose+0xa8>

0000000080004abc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004abc:	715d                	addi	sp,sp,-80
    80004abe:	e486                	sd	ra,72(sp)
    80004ac0:	e0a2                	sd	s0,64(sp)
    80004ac2:	fc26                	sd	s1,56(sp)
    80004ac4:	f84a                	sd	s2,48(sp)
    80004ac6:	f44e                	sd	s3,40(sp)
    80004ac8:	0880                	addi	s0,sp,80
    80004aca:	84aa                	mv	s1,a0
    80004acc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ace:	ffffd097          	auipc	ra,0xffffd
    80004ad2:	0b2080e7          	jalr	178(ra) # 80001b80 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ad6:	409c                	lw	a5,0(s1)
    80004ad8:	37f9                	addiw	a5,a5,-2
    80004ada:	4705                	li	a4,1
    80004adc:	04f76763          	bltu	a4,a5,80004b2a <filestat+0x6e>
    80004ae0:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ae2:	6c88                	ld	a0,24(s1)
    80004ae4:	fffff097          	auipc	ra,0xfffff
    80004ae8:	082080e7          	jalr	130(ra) # 80003b66 <ilock>
    stati(f->ip, &st);
    80004aec:	fb840593          	addi	a1,s0,-72
    80004af0:	6c88                	ld	a0,24(s1)
    80004af2:	fffff097          	auipc	ra,0xfffff
    80004af6:	2fe080e7          	jalr	766(ra) # 80003df0 <stati>
    iunlock(f->ip);
    80004afa:	6c88                	ld	a0,24(s1)
    80004afc:	fffff097          	auipc	ra,0xfffff
    80004b00:	12c080e7          	jalr	300(ra) # 80003c28 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b04:	46e1                	li	a3,24
    80004b06:	fb840613          	addi	a2,s0,-72
    80004b0a:	85ce                	mv	a1,s3
    80004b0c:	05093503          	ld	a0,80(s2)
    80004b10:	ffffd097          	auipc	ra,0xffffd
    80004b14:	cf4080e7          	jalr	-780(ra) # 80001804 <copyout>
    80004b18:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b1c:	60a6                	ld	ra,72(sp)
    80004b1e:	6406                	ld	s0,64(sp)
    80004b20:	74e2                	ld	s1,56(sp)
    80004b22:	7942                	ld	s2,48(sp)
    80004b24:	79a2                	ld	s3,40(sp)
    80004b26:	6161                	addi	sp,sp,80
    80004b28:	8082                	ret
  return -1;
    80004b2a:	557d                	li	a0,-1
    80004b2c:	bfc5                	j	80004b1c <filestat+0x60>

0000000080004b2e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b2e:	7179                	addi	sp,sp,-48
    80004b30:	f406                	sd	ra,40(sp)
    80004b32:	f022                	sd	s0,32(sp)
    80004b34:	ec26                	sd	s1,24(sp)
    80004b36:	e84a                	sd	s2,16(sp)
    80004b38:	e44e                	sd	s3,8(sp)
    80004b3a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b3c:	00854783          	lbu	a5,8(a0)
    80004b40:	c3d5                	beqz	a5,80004be4 <fileread+0xb6>
    80004b42:	84aa                	mv	s1,a0
    80004b44:	89ae                	mv	s3,a1
    80004b46:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b48:	411c                	lw	a5,0(a0)
    80004b4a:	4705                	li	a4,1
    80004b4c:	04e78963          	beq	a5,a4,80004b9e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b50:	470d                	li	a4,3
    80004b52:	04e78d63          	beq	a5,a4,80004bac <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b56:	4709                	li	a4,2
    80004b58:	06e79e63          	bne	a5,a4,80004bd4 <fileread+0xa6>
    ilock(f->ip);
    80004b5c:	6d08                	ld	a0,24(a0)
    80004b5e:	fffff097          	auipc	ra,0xfffff
    80004b62:	008080e7          	jalr	8(ra) # 80003b66 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b66:	874a                	mv	a4,s2
    80004b68:	5094                	lw	a3,32(s1)
    80004b6a:	864e                	mv	a2,s3
    80004b6c:	4585                	li	a1,1
    80004b6e:	6c88                	ld	a0,24(s1)
    80004b70:	fffff097          	auipc	ra,0xfffff
    80004b74:	2aa080e7          	jalr	682(ra) # 80003e1a <readi>
    80004b78:	892a                	mv	s2,a0
    80004b7a:	00a05563          	blez	a0,80004b84 <fileread+0x56>
      f->off += r;
    80004b7e:	509c                	lw	a5,32(s1)
    80004b80:	9fa9                	addw	a5,a5,a0
    80004b82:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b84:	6c88                	ld	a0,24(s1)
    80004b86:	fffff097          	auipc	ra,0xfffff
    80004b8a:	0a2080e7          	jalr	162(ra) # 80003c28 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b8e:	854a                	mv	a0,s2
    80004b90:	70a2                	ld	ra,40(sp)
    80004b92:	7402                	ld	s0,32(sp)
    80004b94:	64e2                	ld	s1,24(sp)
    80004b96:	6942                	ld	s2,16(sp)
    80004b98:	69a2                	ld	s3,8(sp)
    80004b9a:	6145                	addi	sp,sp,48
    80004b9c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b9e:	6908                	ld	a0,16(a0)
    80004ba0:	00000097          	auipc	ra,0x0
    80004ba4:	3c6080e7          	jalr	966(ra) # 80004f66 <piperead>
    80004ba8:	892a                	mv	s2,a0
    80004baa:	b7d5                	j	80004b8e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bac:	02451783          	lh	a5,36(a0)
    80004bb0:	03079693          	slli	a3,a5,0x30
    80004bb4:	92c1                	srli	a3,a3,0x30
    80004bb6:	4725                	li	a4,9
    80004bb8:	02d76863          	bltu	a4,a3,80004be8 <fileread+0xba>
    80004bbc:	0792                	slli	a5,a5,0x4
    80004bbe:	0023c717          	auipc	a4,0x23c
    80004bc2:	46270713          	addi	a4,a4,1122 # 80241020 <devsw>
    80004bc6:	97ba                	add	a5,a5,a4
    80004bc8:	639c                	ld	a5,0(a5)
    80004bca:	c38d                	beqz	a5,80004bec <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bcc:	4505                	li	a0,1
    80004bce:	9782                	jalr	a5
    80004bd0:	892a                	mv	s2,a0
    80004bd2:	bf75                	j	80004b8e <fileread+0x60>
    panic("fileread");
    80004bd4:	00004517          	auipc	a0,0x4
    80004bd8:	b2c50513          	addi	a0,a0,-1236 # 80008700 <syscalls+0x260>
    80004bdc:	ffffc097          	auipc	ra,0xffffc
    80004be0:	962080e7          	jalr	-1694(ra) # 8000053e <panic>
    return -1;
    80004be4:	597d                	li	s2,-1
    80004be6:	b765                	j	80004b8e <fileread+0x60>
      return -1;
    80004be8:	597d                	li	s2,-1
    80004bea:	b755                	j	80004b8e <fileread+0x60>
    80004bec:	597d                	li	s2,-1
    80004bee:	b745                	j	80004b8e <fileread+0x60>

0000000080004bf0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004bf0:	715d                	addi	sp,sp,-80
    80004bf2:	e486                	sd	ra,72(sp)
    80004bf4:	e0a2                	sd	s0,64(sp)
    80004bf6:	fc26                	sd	s1,56(sp)
    80004bf8:	f84a                	sd	s2,48(sp)
    80004bfa:	f44e                	sd	s3,40(sp)
    80004bfc:	f052                	sd	s4,32(sp)
    80004bfe:	ec56                	sd	s5,24(sp)
    80004c00:	e85a                	sd	s6,16(sp)
    80004c02:	e45e                	sd	s7,8(sp)
    80004c04:	e062                	sd	s8,0(sp)
    80004c06:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c08:	00954783          	lbu	a5,9(a0)
    80004c0c:	10078663          	beqz	a5,80004d18 <filewrite+0x128>
    80004c10:	892a                	mv	s2,a0
    80004c12:	8aae                	mv	s5,a1
    80004c14:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c16:	411c                	lw	a5,0(a0)
    80004c18:	4705                	li	a4,1
    80004c1a:	02e78263          	beq	a5,a4,80004c3e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c1e:	470d                	li	a4,3
    80004c20:	02e78663          	beq	a5,a4,80004c4c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c24:	4709                	li	a4,2
    80004c26:	0ee79163          	bne	a5,a4,80004d08 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c2a:	0ac05d63          	blez	a2,80004ce4 <filewrite+0xf4>
    int i = 0;
    80004c2e:	4981                	li	s3,0
    80004c30:	6b05                	lui	s6,0x1
    80004c32:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c36:	6b85                	lui	s7,0x1
    80004c38:	c00b8b9b          	addiw	s7,s7,-1024
    80004c3c:	a861                	j	80004cd4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c3e:	6908                	ld	a0,16(a0)
    80004c40:	00000097          	auipc	ra,0x0
    80004c44:	22e080e7          	jalr	558(ra) # 80004e6e <pipewrite>
    80004c48:	8a2a                	mv	s4,a0
    80004c4a:	a045                	j	80004cea <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c4c:	02451783          	lh	a5,36(a0)
    80004c50:	03079693          	slli	a3,a5,0x30
    80004c54:	92c1                	srli	a3,a3,0x30
    80004c56:	4725                	li	a4,9
    80004c58:	0cd76263          	bltu	a4,a3,80004d1c <filewrite+0x12c>
    80004c5c:	0792                	slli	a5,a5,0x4
    80004c5e:	0023c717          	auipc	a4,0x23c
    80004c62:	3c270713          	addi	a4,a4,962 # 80241020 <devsw>
    80004c66:	97ba                	add	a5,a5,a4
    80004c68:	679c                	ld	a5,8(a5)
    80004c6a:	cbdd                	beqz	a5,80004d20 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c6c:	4505                	li	a0,1
    80004c6e:	9782                	jalr	a5
    80004c70:	8a2a                	mv	s4,a0
    80004c72:	a8a5                	j	80004cea <filewrite+0xfa>
    80004c74:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c78:	00000097          	auipc	ra,0x0
    80004c7c:	8b0080e7          	jalr	-1872(ra) # 80004528 <begin_op>
      ilock(f->ip);
    80004c80:	01893503          	ld	a0,24(s2)
    80004c84:	fffff097          	auipc	ra,0xfffff
    80004c88:	ee2080e7          	jalr	-286(ra) # 80003b66 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c8c:	8762                	mv	a4,s8
    80004c8e:	02092683          	lw	a3,32(s2)
    80004c92:	01598633          	add	a2,s3,s5
    80004c96:	4585                	li	a1,1
    80004c98:	01893503          	ld	a0,24(s2)
    80004c9c:	fffff097          	auipc	ra,0xfffff
    80004ca0:	276080e7          	jalr	630(ra) # 80003f12 <writei>
    80004ca4:	84aa                	mv	s1,a0
    80004ca6:	00a05763          	blez	a0,80004cb4 <filewrite+0xc4>
        f->off += r;
    80004caa:	02092783          	lw	a5,32(s2)
    80004cae:	9fa9                	addw	a5,a5,a0
    80004cb0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cb4:	01893503          	ld	a0,24(s2)
    80004cb8:	fffff097          	auipc	ra,0xfffff
    80004cbc:	f70080e7          	jalr	-144(ra) # 80003c28 <iunlock>
      end_op();
    80004cc0:	00000097          	auipc	ra,0x0
    80004cc4:	8e8080e7          	jalr	-1816(ra) # 800045a8 <end_op>

      if(r != n1){
    80004cc8:	009c1f63          	bne	s8,s1,80004ce6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ccc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cd0:	0149db63          	bge	s3,s4,80004ce6 <filewrite+0xf6>
      int n1 = n - i;
    80004cd4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004cd8:	84be                	mv	s1,a5
    80004cda:	2781                	sext.w	a5,a5
    80004cdc:	f8fb5ce3          	bge	s6,a5,80004c74 <filewrite+0x84>
    80004ce0:	84de                	mv	s1,s7
    80004ce2:	bf49                	j	80004c74 <filewrite+0x84>
    int i = 0;
    80004ce4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ce6:	013a1f63          	bne	s4,s3,80004d04 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004cea:	8552                	mv	a0,s4
    80004cec:	60a6                	ld	ra,72(sp)
    80004cee:	6406                	ld	s0,64(sp)
    80004cf0:	74e2                	ld	s1,56(sp)
    80004cf2:	7942                	ld	s2,48(sp)
    80004cf4:	79a2                	ld	s3,40(sp)
    80004cf6:	7a02                	ld	s4,32(sp)
    80004cf8:	6ae2                	ld	s5,24(sp)
    80004cfa:	6b42                	ld	s6,16(sp)
    80004cfc:	6ba2                	ld	s7,8(sp)
    80004cfe:	6c02                	ld	s8,0(sp)
    80004d00:	6161                	addi	sp,sp,80
    80004d02:	8082                	ret
    ret = (i == n ? n : -1);
    80004d04:	5a7d                	li	s4,-1
    80004d06:	b7d5                	j	80004cea <filewrite+0xfa>
    panic("filewrite");
    80004d08:	00004517          	auipc	a0,0x4
    80004d0c:	a0850513          	addi	a0,a0,-1528 # 80008710 <syscalls+0x270>
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	82e080e7          	jalr	-2002(ra) # 8000053e <panic>
    return -1;
    80004d18:	5a7d                	li	s4,-1
    80004d1a:	bfc1                	j	80004cea <filewrite+0xfa>
      return -1;
    80004d1c:	5a7d                	li	s4,-1
    80004d1e:	b7f1                	j	80004cea <filewrite+0xfa>
    80004d20:	5a7d                	li	s4,-1
    80004d22:	b7e1                	j	80004cea <filewrite+0xfa>

0000000080004d24 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d24:	7179                	addi	sp,sp,-48
    80004d26:	f406                	sd	ra,40(sp)
    80004d28:	f022                	sd	s0,32(sp)
    80004d2a:	ec26                	sd	s1,24(sp)
    80004d2c:	e84a                	sd	s2,16(sp)
    80004d2e:	e44e                	sd	s3,8(sp)
    80004d30:	e052                	sd	s4,0(sp)
    80004d32:	1800                	addi	s0,sp,48
    80004d34:	84aa                	mv	s1,a0
    80004d36:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d38:	0005b023          	sd	zero,0(a1)
    80004d3c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d40:	00000097          	auipc	ra,0x0
    80004d44:	bf8080e7          	jalr	-1032(ra) # 80004938 <filealloc>
    80004d48:	e088                	sd	a0,0(s1)
    80004d4a:	c551                	beqz	a0,80004dd6 <pipealloc+0xb2>
    80004d4c:	00000097          	auipc	ra,0x0
    80004d50:	bec080e7          	jalr	-1044(ra) # 80004938 <filealloc>
    80004d54:	00aa3023          	sd	a0,0(s4)
    80004d58:	c92d                	beqz	a0,80004dca <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d5a:	ffffc097          	auipc	ra,0xffffc
    80004d5e:	efa080e7          	jalr	-262(ra) # 80000c54 <kalloc>
    80004d62:	892a                	mv	s2,a0
    80004d64:	c125                	beqz	a0,80004dc4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d66:	4985                	li	s3,1
    80004d68:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d6c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d70:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d74:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d78:	00004597          	auipc	a1,0x4
    80004d7c:	9a858593          	addi	a1,a1,-1624 # 80008720 <syscalls+0x280>
    80004d80:	ffffc097          	auipc	ra,0xffffc
    80004d84:	f46080e7          	jalr	-186(ra) # 80000cc6 <initlock>
  (*f0)->type = FD_PIPE;
    80004d88:	609c                	ld	a5,0(s1)
    80004d8a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d8e:	609c                	ld	a5,0(s1)
    80004d90:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d94:	609c                	ld	a5,0(s1)
    80004d96:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d9a:	609c                	ld	a5,0(s1)
    80004d9c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004da0:	000a3783          	ld	a5,0(s4)
    80004da4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004da8:	000a3783          	ld	a5,0(s4)
    80004dac:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004db0:	000a3783          	ld	a5,0(s4)
    80004db4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004db8:	000a3783          	ld	a5,0(s4)
    80004dbc:	0127b823          	sd	s2,16(a5)
  return 0;
    80004dc0:	4501                	li	a0,0
    80004dc2:	a025                	j	80004dea <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004dc4:	6088                	ld	a0,0(s1)
    80004dc6:	e501                	bnez	a0,80004dce <pipealloc+0xaa>
    80004dc8:	a039                	j	80004dd6 <pipealloc+0xb2>
    80004dca:	6088                	ld	a0,0(s1)
    80004dcc:	c51d                	beqz	a0,80004dfa <pipealloc+0xd6>
    fileclose(*f0);
    80004dce:	00000097          	auipc	ra,0x0
    80004dd2:	c26080e7          	jalr	-986(ra) # 800049f4 <fileclose>
  if(*f1)
    80004dd6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004dda:	557d                	li	a0,-1
  if(*f1)
    80004ddc:	c799                	beqz	a5,80004dea <pipealloc+0xc6>
    fileclose(*f1);
    80004dde:	853e                	mv	a0,a5
    80004de0:	00000097          	auipc	ra,0x0
    80004de4:	c14080e7          	jalr	-1004(ra) # 800049f4 <fileclose>
  return -1;
    80004de8:	557d                	li	a0,-1
}
    80004dea:	70a2                	ld	ra,40(sp)
    80004dec:	7402                	ld	s0,32(sp)
    80004dee:	64e2                	ld	s1,24(sp)
    80004df0:	6942                	ld	s2,16(sp)
    80004df2:	69a2                	ld	s3,8(sp)
    80004df4:	6a02                	ld	s4,0(sp)
    80004df6:	6145                	addi	sp,sp,48
    80004df8:	8082                	ret
  return -1;
    80004dfa:	557d                	li	a0,-1
    80004dfc:	b7fd                	j	80004dea <pipealloc+0xc6>

0000000080004dfe <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004dfe:	1101                	addi	sp,sp,-32
    80004e00:	ec06                	sd	ra,24(sp)
    80004e02:	e822                	sd	s0,16(sp)
    80004e04:	e426                	sd	s1,8(sp)
    80004e06:	e04a                	sd	s2,0(sp)
    80004e08:	1000                	addi	s0,sp,32
    80004e0a:	84aa                	mv	s1,a0
    80004e0c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e0e:	ffffc097          	auipc	ra,0xffffc
    80004e12:	f48080e7          	jalr	-184(ra) # 80000d56 <acquire>
  if(writable){
    80004e16:	02090d63          	beqz	s2,80004e50 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e1a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e1e:	21848513          	addi	a0,s1,536
    80004e22:	ffffd097          	auipc	ra,0xffffd
    80004e26:	47e080e7          	jalr	1150(ra) # 800022a0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e2a:	2204b783          	ld	a5,544(s1)
    80004e2e:	eb95                	bnez	a5,80004e62 <pipeclose+0x64>
    release(&pi->lock);
    80004e30:	8526                	mv	a0,s1
    80004e32:	ffffc097          	auipc	ra,0xffffc
    80004e36:	fd8080e7          	jalr	-40(ra) # 80000e0a <release>
    kfree((char*)pi);
    80004e3a:	8526                	mv	a0,s1
    80004e3c:	ffffc097          	auipc	ra,0xffffc
    80004e40:	cf4080e7          	jalr	-780(ra) # 80000b30 <kfree>
  } else
    release(&pi->lock);
}
    80004e44:	60e2                	ld	ra,24(sp)
    80004e46:	6442                	ld	s0,16(sp)
    80004e48:	64a2                	ld	s1,8(sp)
    80004e4a:	6902                	ld	s2,0(sp)
    80004e4c:	6105                	addi	sp,sp,32
    80004e4e:	8082                	ret
    pi->readopen = 0;
    80004e50:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e54:	21c48513          	addi	a0,s1,540
    80004e58:	ffffd097          	auipc	ra,0xffffd
    80004e5c:	448080e7          	jalr	1096(ra) # 800022a0 <wakeup>
    80004e60:	b7e9                	j	80004e2a <pipeclose+0x2c>
    release(&pi->lock);
    80004e62:	8526                	mv	a0,s1
    80004e64:	ffffc097          	auipc	ra,0xffffc
    80004e68:	fa6080e7          	jalr	-90(ra) # 80000e0a <release>
}
    80004e6c:	bfe1                	j	80004e44 <pipeclose+0x46>

0000000080004e6e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e6e:	711d                	addi	sp,sp,-96
    80004e70:	ec86                	sd	ra,88(sp)
    80004e72:	e8a2                	sd	s0,80(sp)
    80004e74:	e4a6                	sd	s1,72(sp)
    80004e76:	e0ca                	sd	s2,64(sp)
    80004e78:	fc4e                	sd	s3,56(sp)
    80004e7a:	f852                	sd	s4,48(sp)
    80004e7c:	f456                	sd	s5,40(sp)
    80004e7e:	f05a                	sd	s6,32(sp)
    80004e80:	ec5e                	sd	s7,24(sp)
    80004e82:	e862                	sd	s8,16(sp)
    80004e84:	1080                	addi	s0,sp,96
    80004e86:	84aa                	mv	s1,a0
    80004e88:	8aae                	mv	s5,a1
    80004e8a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e8c:	ffffd097          	auipc	ra,0xffffd
    80004e90:	cf4080e7          	jalr	-780(ra) # 80001b80 <myproc>
    80004e94:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e96:	8526                	mv	a0,s1
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	ebe080e7          	jalr	-322(ra) # 80000d56 <acquire>
  while(i < n){
    80004ea0:	0b405663          	blez	s4,80004f4c <pipewrite+0xde>
  int i = 0;
    80004ea4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ea6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ea8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004eac:	21c48b93          	addi	s7,s1,540
    80004eb0:	a089                	j	80004ef2 <pipewrite+0x84>
      release(&pi->lock);
    80004eb2:	8526                	mv	a0,s1
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	f56080e7          	jalr	-170(ra) # 80000e0a <release>
      return -1;
    80004ebc:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ebe:	854a                	mv	a0,s2
    80004ec0:	60e6                	ld	ra,88(sp)
    80004ec2:	6446                	ld	s0,80(sp)
    80004ec4:	64a6                	ld	s1,72(sp)
    80004ec6:	6906                	ld	s2,64(sp)
    80004ec8:	79e2                	ld	s3,56(sp)
    80004eca:	7a42                	ld	s4,48(sp)
    80004ecc:	7aa2                	ld	s5,40(sp)
    80004ece:	7b02                	ld	s6,32(sp)
    80004ed0:	6be2                	ld	s7,24(sp)
    80004ed2:	6c42                	ld	s8,16(sp)
    80004ed4:	6125                	addi	sp,sp,96
    80004ed6:	8082                	ret
      wakeup(&pi->nread);
    80004ed8:	8562                	mv	a0,s8
    80004eda:	ffffd097          	auipc	ra,0xffffd
    80004ede:	3c6080e7          	jalr	966(ra) # 800022a0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ee2:	85a6                	mv	a1,s1
    80004ee4:	855e                	mv	a0,s7
    80004ee6:	ffffd097          	auipc	ra,0xffffd
    80004eea:	356080e7          	jalr	854(ra) # 8000223c <sleep>
  while(i < n){
    80004eee:	07495063          	bge	s2,s4,80004f4e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004ef2:	2204a783          	lw	a5,544(s1)
    80004ef6:	dfd5                	beqz	a5,80004eb2 <pipewrite+0x44>
    80004ef8:	854e                	mv	a0,s3
    80004efa:	ffffd097          	auipc	ra,0xffffd
    80004efe:	5f6080e7          	jalr	1526(ra) # 800024f0 <killed>
    80004f02:	f945                	bnez	a0,80004eb2 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f04:	2184a783          	lw	a5,536(s1)
    80004f08:	21c4a703          	lw	a4,540(s1)
    80004f0c:	2007879b          	addiw	a5,a5,512
    80004f10:	fcf704e3          	beq	a4,a5,80004ed8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f14:	4685                	li	a3,1
    80004f16:	01590633          	add	a2,s2,s5
    80004f1a:	faf40593          	addi	a1,s0,-81
    80004f1e:	0509b503          	ld	a0,80(s3)
    80004f22:	ffffd097          	auipc	ra,0xffffd
    80004f26:	9a6080e7          	jalr	-1626(ra) # 800018c8 <copyin>
    80004f2a:	03650263          	beq	a0,s6,80004f4e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f2e:	21c4a783          	lw	a5,540(s1)
    80004f32:	0017871b          	addiw	a4,a5,1
    80004f36:	20e4ae23          	sw	a4,540(s1)
    80004f3a:	1ff7f793          	andi	a5,a5,511
    80004f3e:	97a6                	add	a5,a5,s1
    80004f40:	faf44703          	lbu	a4,-81(s0)
    80004f44:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f48:	2905                	addiw	s2,s2,1
    80004f4a:	b755                	j	80004eee <pipewrite+0x80>
  int i = 0;
    80004f4c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f4e:	21848513          	addi	a0,s1,536
    80004f52:	ffffd097          	auipc	ra,0xffffd
    80004f56:	34e080e7          	jalr	846(ra) # 800022a0 <wakeup>
  release(&pi->lock);
    80004f5a:	8526                	mv	a0,s1
    80004f5c:	ffffc097          	auipc	ra,0xffffc
    80004f60:	eae080e7          	jalr	-338(ra) # 80000e0a <release>
  return i;
    80004f64:	bfa9                	j	80004ebe <pipewrite+0x50>

0000000080004f66 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f66:	715d                	addi	sp,sp,-80
    80004f68:	e486                	sd	ra,72(sp)
    80004f6a:	e0a2                	sd	s0,64(sp)
    80004f6c:	fc26                	sd	s1,56(sp)
    80004f6e:	f84a                	sd	s2,48(sp)
    80004f70:	f44e                	sd	s3,40(sp)
    80004f72:	f052                	sd	s4,32(sp)
    80004f74:	ec56                	sd	s5,24(sp)
    80004f76:	e85a                	sd	s6,16(sp)
    80004f78:	0880                	addi	s0,sp,80
    80004f7a:	84aa                	mv	s1,a0
    80004f7c:	892e                	mv	s2,a1
    80004f7e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f80:	ffffd097          	auipc	ra,0xffffd
    80004f84:	c00080e7          	jalr	-1024(ra) # 80001b80 <myproc>
    80004f88:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f8a:	8526                	mv	a0,s1
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	dca080e7          	jalr	-566(ra) # 80000d56 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f94:	2184a703          	lw	a4,536(s1)
    80004f98:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f9c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fa0:	02f71763          	bne	a4,a5,80004fce <piperead+0x68>
    80004fa4:	2244a783          	lw	a5,548(s1)
    80004fa8:	c39d                	beqz	a5,80004fce <piperead+0x68>
    if(killed(pr)){
    80004faa:	8552                	mv	a0,s4
    80004fac:	ffffd097          	auipc	ra,0xffffd
    80004fb0:	544080e7          	jalr	1348(ra) # 800024f0 <killed>
    80004fb4:	e941                	bnez	a0,80005044 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fb6:	85a6                	mv	a1,s1
    80004fb8:	854e                	mv	a0,s3
    80004fba:	ffffd097          	auipc	ra,0xffffd
    80004fbe:	282080e7          	jalr	642(ra) # 8000223c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fc2:	2184a703          	lw	a4,536(s1)
    80004fc6:	21c4a783          	lw	a5,540(s1)
    80004fca:	fcf70de3          	beq	a4,a5,80004fa4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fce:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fd0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fd2:	05505363          	blez	s5,80005018 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004fd6:	2184a783          	lw	a5,536(s1)
    80004fda:	21c4a703          	lw	a4,540(s1)
    80004fde:	02f70d63          	beq	a4,a5,80005018 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004fe2:	0017871b          	addiw	a4,a5,1
    80004fe6:	20e4ac23          	sw	a4,536(s1)
    80004fea:	1ff7f793          	andi	a5,a5,511
    80004fee:	97a6                	add	a5,a5,s1
    80004ff0:	0187c783          	lbu	a5,24(a5)
    80004ff4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ff8:	4685                	li	a3,1
    80004ffa:	fbf40613          	addi	a2,s0,-65
    80004ffe:	85ca                	mv	a1,s2
    80005000:	050a3503          	ld	a0,80(s4)
    80005004:	ffffd097          	auipc	ra,0xffffd
    80005008:	800080e7          	jalr	-2048(ra) # 80001804 <copyout>
    8000500c:	01650663          	beq	a0,s6,80005018 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005010:	2985                	addiw	s3,s3,1
    80005012:	0905                	addi	s2,s2,1
    80005014:	fd3a91e3          	bne	s5,s3,80004fd6 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005018:	21c48513          	addi	a0,s1,540
    8000501c:	ffffd097          	auipc	ra,0xffffd
    80005020:	284080e7          	jalr	644(ra) # 800022a0 <wakeup>
  release(&pi->lock);
    80005024:	8526                	mv	a0,s1
    80005026:	ffffc097          	auipc	ra,0xffffc
    8000502a:	de4080e7          	jalr	-540(ra) # 80000e0a <release>
  return i;
}
    8000502e:	854e                	mv	a0,s3
    80005030:	60a6                	ld	ra,72(sp)
    80005032:	6406                	ld	s0,64(sp)
    80005034:	74e2                	ld	s1,56(sp)
    80005036:	7942                	ld	s2,48(sp)
    80005038:	79a2                	ld	s3,40(sp)
    8000503a:	7a02                	ld	s4,32(sp)
    8000503c:	6ae2                	ld	s5,24(sp)
    8000503e:	6b42                	ld	s6,16(sp)
    80005040:	6161                	addi	sp,sp,80
    80005042:	8082                	ret
      release(&pi->lock);
    80005044:	8526                	mv	a0,s1
    80005046:	ffffc097          	auipc	ra,0xffffc
    8000504a:	dc4080e7          	jalr	-572(ra) # 80000e0a <release>
      return -1;
    8000504e:	59fd                	li	s3,-1
    80005050:	bff9                	j	8000502e <piperead+0xc8>

0000000080005052 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005052:	1141                	addi	sp,sp,-16
    80005054:	e422                	sd	s0,8(sp)
    80005056:	0800                	addi	s0,sp,16
    80005058:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000505a:	8905                	andi	a0,a0,1
    8000505c:	c111                	beqz	a0,80005060 <flags2perm+0xe>
      perm = PTE_X;
    8000505e:	4521                	li	a0,8
    if(flags & 0x2)
    80005060:	8b89                	andi	a5,a5,2
    80005062:	c399                	beqz	a5,80005068 <flags2perm+0x16>
      perm |= PTE_W;
    80005064:	00456513          	ori	a0,a0,4
    return perm;
}
    80005068:	6422                	ld	s0,8(sp)
    8000506a:	0141                	addi	sp,sp,16
    8000506c:	8082                	ret

000000008000506e <exec>:

int
exec(char *path, char **argv)
{
    8000506e:	de010113          	addi	sp,sp,-544
    80005072:	20113c23          	sd	ra,536(sp)
    80005076:	20813823          	sd	s0,528(sp)
    8000507a:	20913423          	sd	s1,520(sp)
    8000507e:	21213023          	sd	s2,512(sp)
    80005082:	ffce                	sd	s3,504(sp)
    80005084:	fbd2                	sd	s4,496(sp)
    80005086:	f7d6                	sd	s5,488(sp)
    80005088:	f3da                	sd	s6,480(sp)
    8000508a:	efde                	sd	s7,472(sp)
    8000508c:	ebe2                	sd	s8,464(sp)
    8000508e:	e7e6                	sd	s9,456(sp)
    80005090:	e3ea                	sd	s10,448(sp)
    80005092:	ff6e                	sd	s11,440(sp)
    80005094:	1400                	addi	s0,sp,544
    80005096:	892a                	mv	s2,a0
    80005098:	dea43423          	sd	a0,-536(s0)
    8000509c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050a0:	ffffd097          	auipc	ra,0xffffd
    800050a4:	ae0080e7          	jalr	-1312(ra) # 80001b80 <myproc>
    800050a8:	84aa                	mv	s1,a0

  begin_op();
    800050aa:	fffff097          	auipc	ra,0xfffff
    800050ae:	47e080e7          	jalr	1150(ra) # 80004528 <begin_op>

  if((ip = namei(path)) == 0){
    800050b2:	854a                	mv	a0,s2
    800050b4:	fffff097          	auipc	ra,0xfffff
    800050b8:	258080e7          	jalr	600(ra) # 8000430c <namei>
    800050bc:	c93d                	beqz	a0,80005132 <exec+0xc4>
    800050be:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050c0:	fffff097          	auipc	ra,0xfffff
    800050c4:	aa6080e7          	jalr	-1370(ra) # 80003b66 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050c8:	04000713          	li	a4,64
    800050cc:	4681                	li	a3,0
    800050ce:	e5040613          	addi	a2,s0,-432
    800050d2:	4581                	li	a1,0
    800050d4:	8556                	mv	a0,s5
    800050d6:	fffff097          	auipc	ra,0xfffff
    800050da:	d44080e7          	jalr	-700(ra) # 80003e1a <readi>
    800050de:	04000793          	li	a5,64
    800050e2:	00f51a63          	bne	a0,a5,800050f6 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800050e6:	e5042703          	lw	a4,-432(s0)
    800050ea:	464c47b7          	lui	a5,0x464c4
    800050ee:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050f2:	04f70663          	beq	a4,a5,8000513e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050f6:	8556                	mv	a0,s5
    800050f8:	fffff097          	auipc	ra,0xfffff
    800050fc:	cd0080e7          	jalr	-816(ra) # 80003dc8 <iunlockput>
    end_op();
    80005100:	fffff097          	auipc	ra,0xfffff
    80005104:	4a8080e7          	jalr	1192(ra) # 800045a8 <end_op>
  }
  return -1;
    80005108:	557d                	li	a0,-1
}
    8000510a:	21813083          	ld	ra,536(sp)
    8000510e:	21013403          	ld	s0,528(sp)
    80005112:	20813483          	ld	s1,520(sp)
    80005116:	20013903          	ld	s2,512(sp)
    8000511a:	79fe                	ld	s3,504(sp)
    8000511c:	7a5e                	ld	s4,496(sp)
    8000511e:	7abe                	ld	s5,488(sp)
    80005120:	7b1e                	ld	s6,480(sp)
    80005122:	6bfe                	ld	s7,472(sp)
    80005124:	6c5e                	ld	s8,464(sp)
    80005126:	6cbe                	ld	s9,456(sp)
    80005128:	6d1e                	ld	s10,448(sp)
    8000512a:	7dfa                	ld	s11,440(sp)
    8000512c:	22010113          	addi	sp,sp,544
    80005130:	8082                	ret
    end_op();
    80005132:	fffff097          	auipc	ra,0xfffff
    80005136:	476080e7          	jalr	1142(ra) # 800045a8 <end_op>
    return -1;
    8000513a:	557d                	li	a0,-1
    8000513c:	b7f9                	j	8000510a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000513e:	8526                	mv	a0,s1
    80005140:	ffffd097          	auipc	ra,0xffffd
    80005144:	b04080e7          	jalr	-1276(ra) # 80001c44 <proc_pagetable>
    80005148:	8b2a                	mv	s6,a0
    8000514a:	d555                	beqz	a0,800050f6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000514c:	e7042783          	lw	a5,-400(s0)
    80005150:	e8845703          	lhu	a4,-376(s0)
    80005154:	c735                	beqz	a4,800051c0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005156:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005158:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000515c:	6a05                	lui	s4,0x1
    8000515e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005162:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005166:	6d85                	lui	s11,0x1
    80005168:	7d7d                	lui	s10,0xfffff
    8000516a:	a481                	j	800053aa <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000516c:	00003517          	auipc	a0,0x3
    80005170:	5bc50513          	addi	a0,a0,1468 # 80008728 <syscalls+0x288>
    80005174:	ffffb097          	auipc	ra,0xffffb
    80005178:	3ca080e7          	jalr	970(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000517c:	874a                	mv	a4,s2
    8000517e:	009c86bb          	addw	a3,s9,s1
    80005182:	4581                	li	a1,0
    80005184:	8556                	mv	a0,s5
    80005186:	fffff097          	auipc	ra,0xfffff
    8000518a:	c94080e7          	jalr	-876(ra) # 80003e1a <readi>
    8000518e:	2501                	sext.w	a0,a0
    80005190:	1aa91a63          	bne	s2,a0,80005344 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005194:	009d84bb          	addw	s1,s11,s1
    80005198:	013d09bb          	addw	s3,s10,s3
    8000519c:	1f74f763          	bgeu	s1,s7,8000538a <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    800051a0:	02049593          	slli	a1,s1,0x20
    800051a4:	9181                	srli	a1,a1,0x20
    800051a6:	95e2                	add	a1,a1,s8
    800051a8:	855a                	mv	a0,s6
    800051aa:	ffffc097          	auipc	ra,0xffffc
    800051ae:	032080e7          	jalr	50(ra) # 800011dc <walkaddr>
    800051b2:	862a                	mv	a2,a0
    if(pa == 0)
    800051b4:	dd45                	beqz	a0,8000516c <exec+0xfe>
      n = PGSIZE;
    800051b6:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800051b8:	fd49f2e3          	bgeu	s3,s4,8000517c <exec+0x10e>
      n = sz - i;
    800051bc:	894e                	mv	s2,s3
    800051be:	bf7d                	j	8000517c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051c0:	4901                	li	s2,0
  iunlockput(ip);
    800051c2:	8556                	mv	a0,s5
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	c04080e7          	jalr	-1020(ra) # 80003dc8 <iunlockput>
  end_op();
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	3dc080e7          	jalr	988(ra) # 800045a8 <end_op>
  p = myproc();
    800051d4:	ffffd097          	auipc	ra,0xffffd
    800051d8:	9ac080e7          	jalr	-1620(ra) # 80001b80 <myproc>
    800051dc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800051de:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800051e2:	6785                	lui	a5,0x1
    800051e4:	17fd                	addi	a5,a5,-1
    800051e6:	993e                	add	s2,s2,a5
    800051e8:	77fd                	lui	a5,0xfffff
    800051ea:	00f977b3          	and	a5,s2,a5
    800051ee:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800051f2:	4691                	li	a3,4
    800051f4:	6609                	lui	a2,0x2
    800051f6:	963e                	add	a2,a2,a5
    800051f8:	85be                	mv	a1,a5
    800051fa:	855a                	mv	a0,s6
    800051fc:	ffffc097          	auipc	ra,0xffffc
    80005200:	394080e7          	jalr	916(ra) # 80001590 <uvmalloc>
    80005204:	8c2a                	mv	s8,a0
  ip = 0;
    80005206:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005208:	12050e63          	beqz	a0,80005344 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000520c:	75f9                	lui	a1,0xffffe
    8000520e:	95aa                	add	a1,a1,a0
    80005210:	855a                	mv	a0,s6
    80005212:	ffffc097          	auipc	ra,0xffffc
    80005216:	5c0080e7          	jalr	1472(ra) # 800017d2 <uvmclear>
  stackbase = sp - PGSIZE;
    8000521a:	7afd                	lui	s5,0xfffff
    8000521c:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000521e:	df043783          	ld	a5,-528(s0)
    80005222:	6388                	ld	a0,0(a5)
    80005224:	c925                	beqz	a0,80005294 <exec+0x226>
    80005226:	e9040993          	addi	s3,s0,-368
    8000522a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000522e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005230:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005232:	ffffc097          	auipc	ra,0xffffc
    80005236:	d9c080e7          	jalr	-612(ra) # 80000fce <strlen>
    8000523a:	0015079b          	addiw	a5,a0,1
    8000523e:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005242:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005246:	13596663          	bltu	s2,s5,80005372 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000524a:	df043d83          	ld	s11,-528(s0)
    8000524e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005252:	8552                	mv	a0,s4
    80005254:	ffffc097          	auipc	ra,0xffffc
    80005258:	d7a080e7          	jalr	-646(ra) # 80000fce <strlen>
    8000525c:	0015069b          	addiw	a3,a0,1
    80005260:	8652                	mv	a2,s4
    80005262:	85ca                	mv	a1,s2
    80005264:	855a                	mv	a0,s6
    80005266:	ffffc097          	auipc	ra,0xffffc
    8000526a:	59e080e7          	jalr	1438(ra) # 80001804 <copyout>
    8000526e:	10054663          	bltz	a0,8000537a <exec+0x30c>
    ustack[argc] = sp;
    80005272:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005276:	0485                	addi	s1,s1,1
    80005278:	008d8793          	addi	a5,s11,8
    8000527c:	def43823          	sd	a5,-528(s0)
    80005280:	008db503          	ld	a0,8(s11)
    80005284:	c911                	beqz	a0,80005298 <exec+0x22a>
    if(argc >= MAXARG)
    80005286:	09a1                	addi	s3,s3,8
    80005288:	fb3c95e3          	bne	s9,s3,80005232 <exec+0x1c4>
  sz = sz1;
    8000528c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005290:	4a81                	li	s5,0
    80005292:	a84d                	j	80005344 <exec+0x2d6>
  sp = sz;
    80005294:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005296:	4481                	li	s1,0
  ustack[argc] = 0;
    80005298:	00349793          	slli	a5,s1,0x3
    8000529c:	f9040713          	addi	a4,s0,-112
    800052a0:	97ba                	add	a5,a5,a4
    800052a2:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7fdbcd48>
  sp -= (argc+1) * sizeof(uint64);
    800052a6:	00148693          	addi	a3,s1,1
    800052aa:	068e                	slli	a3,a3,0x3
    800052ac:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052b0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052b4:	01597663          	bgeu	s2,s5,800052c0 <exec+0x252>
  sz = sz1;
    800052b8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052bc:	4a81                	li	s5,0
    800052be:	a059                	j	80005344 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052c0:	e9040613          	addi	a2,s0,-368
    800052c4:	85ca                	mv	a1,s2
    800052c6:	855a                	mv	a0,s6
    800052c8:	ffffc097          	auipc	ra,0xffffc
    800052cc:	53c080e7          	jalr	1340(ra) # 80001804 <copyout>
    800052d0:	0a054963          	bltz	a0,80005382 <exec+0x314>
  p->trapframe->a1 = sp;
    800052d4:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800052d8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052dc:	de843783          	ld	a5,-536(s0)
    800052e0:	0007c703          	lbu	a4,0(a5)
    800052e4:	cf11                	beqz	a4,80005300 <exec+0x292>
    800052e6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052e8:	02f00693          	li	a3,47
    800052ec:	a039                	j	800052fa <exec+0x28c>
      last = s+1;
    800052ee:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800052f2:	0785                	addi	a5,a5,1
    800052f4:	fff7c703          	lbu	a4,-1(a5)
    800052f8:	c701                	beqz	a4,80005300 <exec+0x292>
    if(*s == '/')
    800052fa:	fed71ce3          	bne	a4,a3,800052f2 <exec+0x284>
    800052fe:	bfc5                	j	800052ee <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005300:	4641                	li	a2,16
    80005302:	de843583          	ld	a1,-536(s0)
    80005306:	158b8513          	addi	a0,s7,344
    8000530a:	ffffc097          	auipc	ra,0xffffc
    8000530e:	c92080e7          	jalr	-878(ra) # 80000f9c <safestrcpy>
  oldpagetable = p->pagetable;
    80005312:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005316:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000531a:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000531e:	058bb783          	ld	a5,88(s7)
    80005322:	e6843703          	ld	a4,-408(s0)
    80005326:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005328:	058bb783          	ld	a5,88(s7)
    8000532c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005330:	85ea                	mv	a1,s10
    80005332:	ffffd097          	auipc	ra,0xffffd
    80005336:	9ae080e7          	jalr	-1618(ra) # 80001ce0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000533a:	0004851b          	sext.w	a0,s1
    8000533e:	b3f1                	j	8000510a <exec+0x9c>
    80005340:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005344:	df843583          	ld	a1,-520(s0)
    80005348:	855a                	mv	a0,s6
    8000534a:	ffffd097          	auipc	ra,0xffffd
    8000534e:	996080e7          	jalr	-1642(ra) # 80001ce0 <proc_freepagetable>
  if(ip){
    80005352:	da0a92e3          	bnez	s5,800050f6 <exec+0x88>
  return -1;
    80005356:	557d                	li	a0,-1
    80005358:	bb4d                	j	8000510a <exec+0x9c>
    8000535a:	df243c23          	sd	s2,-520(s0)
    8000535e:	b7dd                	j	80005344 <exec+0x2d6>
    80005360:	df243c23          	sd	s2,-520(s0)
    80005364:	b7c5                	j	80005344 <exec+0x2d6>
    80005366:	df243c23          	sd	s2,-520(s0)
    8000536a:	bfe9                	j	80005344 <exec+0x2d6>
    8000536c:	df243c23          	sd	s2,-520(s0)
    80005370:	bfd1                	j	80005344 <exec+0x2d6>
  sz = sz1;
    80005372:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005376:	4a81                	li	s5,0
    80005378:	b7f1                	j	80005344 <exec+0x2d6>
  sz = sz1;
    8000537a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000537e:	4a81                	li	s5,0
    80005380:	b7d1                	j	80005344 <exec+0x2d6>
  sz = sz1;
    80005382:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005386:	4a81                	li	s5,0
    80005388:	bf75                	j	80005344 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000538a:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000538e:	e0843783          	ld	a5,-504(s0)
    80005392:	0017869b          	addiw	a3,a5,1
    80005396:	e0d43423          	sd	a3,-504(s0)
    8000539a:	e0043783          	ld	a5,-512(s0)
    8000539e:	0387879b          	addiw	a5,a5,56
    800053a2:	e8845703          	lhu	a4,-376(s0)
    800053a6:	e0e6dee3          	bge	a3,a4,800051c2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053aa:	2781                	sext.w	a5,a5
    800053ac:	e0f43023          	sd	a5,-512(s0)
    800053b0:	03800713          	li	a4,56
    800053b4:	86be                	mv	a3,a5
    800053b6:	e1840613          	addi	a2,s0,-488
    800053ba:	4581                	li	a1,0
    800053bc:	8556                	mv	a0,s5
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	a5c080e7          	jalr	-1444(ra) # 80003e1a <readi>
    800053c6:	03800793          	li	a5,56
    800053ca:	f6f51be3          	bne	a0,a5,80005340 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    800053ce:	e1842783          	lw	a5,-488(s0)
    800053d2:	4705                	li	a4,1
    800053d4:	fae79de3          	bne	a5,a4,8000538e <exec+0x320>
    if(ph.memsz < ph.filesz)
    800053d8:	e4043483          	ld	s1,-448(s0)
    800053dc:	e3843783          	ld	a5,-456(s0)
    800053e0:	f6f4ede3          	bltu	s1,a5,8000535a <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053e4:	e2843783          	ld	a5,-472(s0)
    800053e8:	94be                	add	s1,s1,a5
    800053ea:	f6f4ebe3          	bltu	s1,a5,80005360 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800053ee:	de043703          	ld	a4,-544(s0)
    800053f2:	8ff9                	and	a5,a5,a4
    800053f4:	fbad                	bnez	a5,80005366 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053f6:	e1c42503          	lw	a0,-484(s0)
    800053fa:	00000097          	auipc	ra,0x0
    800053fe:	c58080e7          	jalr	-936(ra) # 80005052 <flags2perm>
    80005402:	86aa                	mv	a3,a0
    80005404:	8626                	mv	a2,s1
    80005406:	85ca                	mv	a1,s2
    80005408:	855a                	mv	a0,s6
    8000540a:	ffffc097          	auipc	ra,0xffffc
    8000540e:	186080e7          	jalr	390(ra) # 80001590 <uvmalloc>
    80005412:	dea43c23          	sd	a0,-520(s0)
    80005416:	d939                	beqz	a0,8000536c <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005418:	e2843c03          	ld	s8,-472(s0)
    8000541c:	e2042c83          	lw	s9,-480(s0)
    80005420:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005424:	f60b83e3          	beqz	s7,8000538a <exec+0x31c>
    80005428:	89de                	mv	s3,s7
    8000542a:	4481                	li	s1,0
    8000542c:	bb95                	j	800051a0 <exec+0x132>

000000008000542e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000542e:	7179                	addi	sp,sp,-48
    80005430:	f406                	sd	ra,40(sp)
    80005432:	f022                	sd	s0,32(sp)
    80005434:	ec26                	sd	s1,24(sp)
    80005436:	e84a                	sd	s2,16(sp)
    80005438:	1800                	addi	s0,sp,48
    8000543a:	892e                	mv	s2,a1
    8000543c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000543e:	fdc40593          	addi	a1,s0,-36
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	b1c080e7          	jalr	-1252(ra) # 80002f5e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000544a:	fdc42703          	lw	a4,-36(s0)
    8000544e:	47bd                	li	a5,15
    80005450:	02e7eb63          	bltu	a5,a4,80005486 <argfd+0x58>
    80005454:	ffffc097          	auipc	ra,0xffffc
    80005458:	72c080e7          	jalr	1836(ra) # 80001b80 <myproc>
    8000545c:	fdc42703          	lw	a4,-36(s0)
    80005460:	01a70793          	addi	a5,a4,26
    80005464:	078e                	slli	a5,a5,0x3
    80005466:	953e                	add	a0,a0,a5
    80005468:	611c                	ld	a5,0(a0)
    8000546a:	c385                	beqz	a5,8000548a <argfd+0x5c>
    return -1;
  if(pfd)
    8000546c:	00090463          	beqz	s2,80005474 <argfd+0x46>
    *pfd = fd;
    80005470:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005474:	4501                	li	a0,0
  if(pf)
    80005476:	c091                	beqz	s1,8000547a <argfd+0x4c>
    *pf = f;
    80005478:	e09c                	sd	a5,0(s1)
}
    8000547a:	70a2                	ld	ra,40(sp)
    8000547c:	7402                	ld	s0,32(sp)
    8000547e:	64e2                	ld	s1,24(sp)
    80005480:	6942                	ld	s2,16(sp)
    80005482:	6145                	addi	sp,sp,48
    80005484:	8082                	ret
    return -1;
    80005486:	557d                	li	a0,-1
    80005488:	bfcd                	j	8000547a <argfd+0x4c>
    8000548a:	557d                	li	a0,-1
    8000548c:	b7fd                	j	8000547a <argfd+0x4c>

000000008000548e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000548e:	1101                	addi	sp,sp,-32
    80005490:	ec06                	sd	ra,24(sp)
    80005492:	e822                	sd	s0,16(sp)
    80005494:	e426                	sd	s1,8(sp)
    80005496:	1000                	addi	s0,sp,32
    80005498:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000549a:	ffffc097          	auipc	ra,0xffffc
    8000549e:	6e6080e7          	jalr	1766(ra) # 80001b80 <myproc>
    800054a2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054a4:	0d050793          	addi	a5,a0,208
    800054a8:	4501                	li	a0,0
    800054aa:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054ac:	6398                	ld	a4,0(a5)
    800054ae:	cb19                	beqz	a4,800054c4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054b0:	2505                	addiw	a0,a0,1
    800054b2:	07a1                	addi	a5,a5,8
    800054b4:	fed51ce3          	bne	a0,a3,800054ac <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054b8:	557d                	li	a0,-1
}
    800054ba:	60e2                	ld	ra,24(sp)
    800054bc:	6442                	ld	s0,16(sp)
    800054be:	64a2                	ld	s1,8(sp)
    800054c0:	6105                	addi	sp,sp,32
    800054c2:	8082                	ret
      p->ofile[fd] = f;
    800054c4:	01a50793          	addi	a5,a0,26
    800054c8:	078e                	slli	a5,a5,0x3
    800054ca:	963e                	add	a2,a2,a5
    800054cc:	e204                	sd	s1,0(a2)
      return fd;
    800054ce:	b7f5                	j	800054ba <fdalloc+0x2c>

00000000800054d0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054d0:	715d                	addi	sp,sp,-80
    800054d2:	e486                	sd	ra,72(sp)
    800054d4:	e0a2                	sd	s0,64(sp)
    800054d6:	fc26                	sd	s1,56(sp)
    800054d8:	f84a                	sd	s2,48(sp)
    800054da:	f44e                	sd	s3,40(sp)
    800054dc:	f052                	sd	s4,32(sp)
    800054de:	ec56                	sd	s5,24(sp)
    800054e0:	e85a                	sd	s6,16(sp)
    800054e2:	0880                	addi	s0,sp,80
    800054e4:	8b2e                	mv	s6,a1
    800054e6:	89b2                	mv	s3,a2
    800054e8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054ea:	fb040593          	addi	a1,s0,-80
    800054ee:	fffff097          	auipc	ra,0xfffff
    800054f2:	e3c080e7          	jalr	-452(ra) # 8000432a <nameiparent>
    800054f6:	84aa                	mv	s1,a0
    800054f8:	14050f63          	beqz	a0,80005656 <create+0x186>
    return 0;

  ilock(dp);
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	66a080e7          	jalr	1642(ra) # 80003b66 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005504:	4601                	li	a2,0
    80005506:	fb040593          	addi	a1,s0,-80
    8000550a:	8526                	mv	a0,s1
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	b3e080e7          	jalr	-1218(ra) # 8000404a <dirlookup>
    80005514:	8aaa                	mv	s5,a0
    80005516:	c931                	beqz	a0,8000556a <create+0x9a>
    iunlockput(dp);
    80005518:	8526                	mv	a0,s1
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	8ae080e7          	jalr	-1874(ra) # 80003dc8 <iunlockput>
    ilock(ip);
    80005522:	8556                	mv	a0,s5
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	642080e7          	jalr	1602(ra) # 80003b66 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000552c:	000b059b          	sext.w	a1,s6
    80005530:	4789                	li	a5,2
    80005532:	02f59563          	bne	a1,a5,8000555c <create+0x8c>
    80005536:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbce8c>
    8000553a:	37f9                	addiw	a5,a5,-2
    8000553c:	17c2                	slli	a5,a5,0x30
    8000553e:	93c1                	srli	a5,a5,0x30
    80005540:	4705                	li	a4,1
    80005542:	00f76d63          	bltu	a4,a5,8000555c <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005546:	8556                	mv	a0,s5
    80005548:	60a6                	ld	ra,72(sp)
    8000554a:	6406                	ld	s0,64(sp)
    8000554c:	74e2                	ld	s1,56(sp)
    8000554e:	7942                	ld	s2,48(sp)
    80005550:	79a2                	ld	s3,40(sp)
    80005552:	7a02                	ld	s4,32(sp)
    80005554:	6ae2                	ld	s5,24(sp)
    80005556:	6b42                	ld	s6,16(sp)
    80005558:	6161                	addi	sp,sp,80
    8000555a:	8082                	ret
    iunlockput(ip);
    8000555c:	8556                	mv	a0,s5
    8000555e:	fffff097          	auipc	ra,0xfffff
    80005562:	86a080e7          	jalr	-1942(ra) # 80003dc8 <iunlockput>
    return 0;
    80005566:	4a81                	li	s5,0
    80005568:	bff9                	j	80005546 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000556a:	85da                	mv	a1,s6
    8000556c:	4088                	lw	a0,0(s1)
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	45c080e7          	jalr	1116(ra) # 800039ca <ialloc>
    80005576:	8a2a                	mv	s4,a0
    80005578:	c539                	beqz	a0,800055c6 <create+0xf6>
  ilock(ip);
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	5ec080e7          	jalr	1516(ra) # 80003b66 <ilock>
  ip->major = major;
    80005582:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005586:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000558a:	4905                	li	s2,1
    8000558c:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005590:	8552                	mv	a0,s4
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	50a080e7          	jalr	1290(ra) # 80003a9c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000559a:	000b059b          	sext.w	a1,s6
    8000559e:	03258b63          	beq	a1,s2,800055d4 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800055a2:	004a2603          	lw	a2,4(s4)
    800055a6:	fb040593          	addi	a1,s0,-80
    800055aa:	8526                	mv	a0,s1
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	cae080e7          	jalr	-850(ra) # 8000425a <dirlink>
    800055b4:	06054f63          	bltz	a0,80005632 <create+0x162>
  iunlockput(dp);
    800055b8:	8526                	mv	a0,s1
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	80e080e7          	jalr	-2034(ra) # 80003dc8 <iunlockput>
  return ip;
    800055c2:	8ad2                	mv	s5,s4
    800055c4:	b749                	j	80005546 <create+0x76>
    iunlockput(dp);
    800055c6:	8526                	mv	a0,s1
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	800080e7          	jalr	-2048(ra) # 80003dc8 <iunlockput>
    return 0;
    800055d0:	8ad2                	mv	s5,s4
    800055d2:	bf95                	j	80005546 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055d4:	004a2603          	lw	a2,4(s4)
    800055d8:	00003597          	auipc	a1,0x3
    800055dc:	17058593          	addi	a1,a1,368 # 80008748 <syscalls+0x2a8>
    800055e0:	8552                	mv	a0,s4
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	c78080e7          	jalr	-904(ra) # 8000425a <dirlink>
    800055ea:	04054463          	bltz	a0,80005632 <create+0x162>
    800055ee:	40d0                	lw	a2,4(s1)
    800055f0:	00003597          	auipc	a1,0x3
    800055f4:	16058593          	addi	a1,a1,352 # 80008750 <syscalls+0x2b0>
    800055f8:	8552                	mv	a0,s4
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	c60080e7          	jalr	-928(ra) # 8000425a <dirlink>
    80005602:	02054863          	bltz	a0,80005632 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005606:	004a2603          	lw	a2,4(s4)
    8000560a:	fb040593          	addi	a1,s0,-80
    8000560e:	8526                	mv	a0,s1
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	c4a080e7          	jalr	-950(ra) # 8000425a <dirlink>
    80005618:	00054d63          	bltz	a0,80005632 <create+0x162>
    dp->nlink++;  // for ".."
    8000561c:	04a4d783          	lhu	a5,74(s1)
    80005620:	2785                	addiw	a5,a5,1
    80005622:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005626:	8526                	mv	a0,s1
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	474080e7          	jalr	1140(ra) # 80003a9c <iupdate>
    80005630:	b761                	j	800055b8 <create+0xe8>
  ip->nlink = 0;
    80005632:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005636:	8552                	mv	a0,s4
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	464080e7          	jalr	1124(ra) # 80003a9c <iupdate>
  iunlockput(ip);
    80005640:	8552                	mv	a0,s4
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	786080e7          	jalr	1926(ra) # 80003dc8 <iunlockput>
  iunlockput(dp);
    8000564a:	8526                	mv	a0,s1
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	77c080e7          	jalr	1916(ra) # 80003dc8 <iunlockput>
  return 0;
    80005654:	bdcd                	j	80005546 <create+0x76>
    return 0;
    80005656:	8aaa                	mv	s5,a0
    80005658:	b5fd                	j	80005546 <create+0x76>

000000008000565a <sys_dup>:
{
    8000565a:	7179                	addi	sp,sp,-48
    8000565c:	f406                	sd	ra,40(sp)
    8000565e:	f022                	sd	s0,32(sp)
    80005660:	ec26                	sd	s1,24(sp)
    80005662:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005664:	fd840613          	addi	a2,s0,-40
    80005668:	4581                	li	a1,0
    8000566a:	4501                	li	a0,0
    8000566c:	00000097          	auipc	ra,0x0
    80005670:	dc2080e7          	jalr	-574(ra) # 8000542e <argfd>
    return -1;
    80005674:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005676:	02054363          	bltz	a0,8000569c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000567a:	fd843503          	ld	a0,-40(s0)
    8000567e:	00000097          	auipc	ra,0x0
    80005682:	e10080e7          	jalr	-496(ra) # 8000548e <fdalloc>
    80005686:	84aa                	mv	s1,a0
    return -1;
    80005688:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000568a:	00054963          	bltz	a0,8000569c <sys_dup+0x42>
  filedup(f);
    8000568e:	fd843503          	ld	a0,-40(s0)
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	310080e7          	jalr	784(ra) # 800049a2 <filedup>
  return fd;
    8000569a:	87a6                	mv	a5,s1
}
    8000569c:	853e                	mv	a0,a5
    8000569e:	70a2                	ld	ra,40(sp)
    800056a0:	7402                	ld	s0,32(sp)
    800056a2:	64e2                	ld	s1,24(sp)
    800056a4:	6145                	addi	sp,sp,48
    800056a6:	8082                	ret

00000000800056a8 <sys_read>:
{
    800056a8:	7179                	addi	sp,sp,-48
    800056aa:	f406                	sd	ra,40(sp)
    800056ac:	f022                	sd	s0,32(sp)
    800056ae:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800056b0:	fd840593          	addi	a1,s0,-40
    800056b4:	4505                	li	a0,1
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	8c8080e7          	jalr	-1848(ra) # 80002f7e <argaddr>
  argint(2, &n);
    800056be:	fe440593          	addi	a1,s0,-28
    800056c2:	4509                	li	a0,2
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	89a080e7          	jalr	-1894(ra) # 80002f5e <argint>
  if(argfd(0, 0, &f) < 0)
    800056cc:	fe840613          	addi	a2,s0,-24
    800056d0:	4581                	li	a1,0
    800056d2:	4501                	li	a0,0
    800056d4:	00000097          	auipc	ra,0x0
    800056d8:	d5a080e7          	jalr	-678(ra) # 8000542e <argfd>
    800056dc:	87aa                	mv	a5,a0
    return -1;
    800056de:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056e0:	0007cc63          	bltz	a5,800056f8 <sys_read+0x50>
  return fileread(f, p, n);
    800056e4:	fe442603          	lw	a2,-28(s0)
    800056e8:	fd843583          	ld	a1,-40(s0)
    800056ec:	fe843503          	ld	a0,-24(s0)
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	43e080e7          	jalr	1086(ra) # 80004b2e <fileread>
}
    800056f8:	70a2                	ld	ra,40(sp)
    800056fa:	7402                	ld	s0,32(sp)
    800056fc:	6145                	addi	sp,sp,48
    800056fe:	8082                	ret

0000000080005700 <sys_write>:
{
    80005700:	7179                	addi	sp,sp,-48
    80005702:	f406                	sd	ra,40(sp)
    80005704:	f022                	sd	s0,32(sp)
    80005706:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005708:	fd840593          	addi	a1,s0,-40
    8000570c:	4505                	li	a0,1
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	870080e7          	jalr	-1936(ra) # 80002f7e <argaddr>
  argint(2, &n);
    80005716:	fe440593          	addi	a1,s0,-28
    8000571a:	4509                	li	a0,2
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	842080e7          	jalr	-1982(ra) # 80002f5e <argint>
  if(argfd(0, 0, &f) < 0)
    80005724:	fe840613          	addi	a2,s0,-24
    80005728:	4581                	li	a1,0
    8000572a:	4501                	li	a0,0
    8000572c:	00000097          	auipc	ra,0x0
    80005730:	d02080e7          	jalr	-766(ra) # 8000542e <argfd>
    80005734:	87aa                	mv	a5,a0
    return -1;
    80005736:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005738:	0007cc63          	bltz	a5,80005750 <sys_write+0x50>
  return filewrite(f, p, n);
    8000573c:	fe442603          	lw	a2,-28(s0)
    80005740:	fd843583          	ld	a1,-40(s0)
    80005744:	fe843503          	ld	a0,-24(s0)
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	4a8080e7          	jalr	1192(ra) # 80004bf0 <filewrite>
}
    80005750:	70a2                	ld	ra,40(sp)
    80005752:	7402                	ld	s0,32(sp)
    80005754:	6145                	addi	sp,sp,48
    80005756:	8082                	ret

0000000080005758 <sys_close>:
{
    80005758:	1101                	addi	sp,sp,-32
    8000575a:	ec06                	sd	ra,24(sp)
    8000575c:	e822                	sd	s0,16(sp)
    8000575e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005760:	fe040613          	addi	a2,s0,-32
    80005764:	fec40593          	addi	a1,s0,-20
    80005768:	4501                	li	a0,0
    8000576a:	00000097          	auipc	ra,0x0
    8000576e:	cc4080e7          	jalr	-828(ra) # 8000542e <argfd>
    return -1;
    80005772:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005774:	02054463          	bltz	a0,8000579c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005778:	ffffc097          	auipc	ra,0xffffc
    8000577c:	408080e7          	jalr	1032(ra) # 80001b80 <myproc>
    80005780:	fec42783          	lw	a5,-20(s0)
    80005784:	07e9                	addi	a5,a5,26
    80005786:	078e                	slli	a5,a5,0x3
    80005788:	97aa                	add	a5,a5,a0
    8000578a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000578e:	fe043503          	ld	a0,-32(s0)
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	262080e7          	jalr	610(ra) # 800049f4 <fileclose>
  return 0;
    8000579a:	4781                	li	a5,0
}
    8000579c:	853e                	mv	a0,a5
    8000579e:	60e2                	ld	ra,24(sp)
    800057a0:	6442                	ld	s0,16(sp)
    800057a2:	6105                	addi	sp,sp,32
    800057a4:	8082                	ret

00000000800057a6 <sys_fstat>:
{
    800057a6:	1101                	addi	sp,sp,-32
    800057a8:	ec06                	sd	ra,24(sp)
    800057aa:	e822                	sd	s0,16(sp)
    800057ac:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800057ae:	fe040593          	addi	a1,s0,-32
    800057b2:	4505                	li	a0,1
    800057b4:	ffffd097          	auipc	ra,0xffffd
    800057b8:	7ca080e7          	jalr	1994(ra) # 80002f7e <argaddr>
  if(argfd(0, 0, &f) < 0)
    800057bc:	fe840613          	addi	a2,s0,-24
    800057c0:	4581                	li	a1,0
    800057c2:	4501                	li	a0,0
    800057c4:	00000097          	auipc	ra,0x0
    800057c8:	c6a080e7          	jalr	-918(ra) # 8000542e <argfd>
    800057cc:	87aa                	mv	a5,a0
    return -1;
    800057ce:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057d0:	0007ca63          	bltz	a5,800057e4 <sys_fstat+0x3e>
  return filestat(f, st);
    800057d4:	fe043583          	ld	a1,-32(s0)
    800057d8:	fe843503          	ld	a0,-24(s0)
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	2e0080e7          	jalr	736(ra) # 80004abc <filestat>
}
    800057e4:	60e2                	ld	ra,24(sp)
    800057e6:	6442                	ld	s0,16(sp)
    800057e8:	6105                	addi	sp,sp,32
    800057ea:	8082                	ret

00000000800057ec <sys_link>:
{
    800057ec:	7169                	addi	sp,sp,-304
    800057ee:	f606                	sd	ra,296(sp)
    800057f0:	f222                	sd	s0,288(sp)
    800057f2:	ee26                	sd	s1,280(sp)
    800057f4:	ea4a                	sd	s2,272(sp)
    800057f6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057f8:	08000613          	li	a2,128
    800057fc:	ed040593          	addi	a1,s0,-304
    80005800:	4501                	li	a0,0
    80005802:	ffffd097          	auipc	ra,0xffffd
    80005806:	79c080e7          	jalr	1948(ra) # 80002f9e <argstr>
    return -1;
    8000580a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000580c:	10054e63          	bltz	a0,80005928 <sys_link+0x13c>
    80005810:	08000613          	li	a2,128
    80005814:	f5040593          	addi	a1,s0,-176
    80005818:	4505                	li	a0,1
    8000581a:	ffffd097          	auipc	ra,0xffffd
    8000581e:	784080e7          	jalr	1924(ra) # 80002f9e <argstr>
    return -1;
    80005822:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005824:	10054263          	bltz	a0,80005928 <sys_link+0x13c>
  begin_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	d00080e7          	jalr	-768(ra) # 80004528 <begin_op>
  if((ip = namei(old)) == 0){
    80005830:	ed040513          	addi	a0,s0,-304
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	ad8080e7          	jalr	-1320(ra) # 8000430c <namei>
    8000583c:	84aa                	mv	s1,a0
    8000583e:	c551                	beqz	a0,800058ca <sys_link+0xde>
  ilock(ip);
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	326080e7          	jalr	806(ra) # 80003b66 <ilock>
  if(ip->type == T_DIR){
    80005848:	04449703          	lh	a4,68(s1)
    8000584c:	4785                	li	a5,1
    8000584e:	08f70463          	beq	a4,a5,800058d6 <sys_link+0xea>
  ip->nlink++;
    80005852:	04a4d783          	lhu	a5,74(s1)
    80005856:	2785                	addiw	a5,a5,1
    80005858:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000585c:	8526                	mv	a0,s1
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	23e080e7          	jalr	574(ra) # 80003a9c <iupdate>
  iunlock(ip);
    80005866:	8526                	mv	a0,s1
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	3c0080e7          	jalr	960(ra) # 80003c28 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005870:	fd040593          	addi	a1,s0,-48
    80005874:	f5040513          	addi	a0,s0,-176
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	ab2080e7          	jalr	-1358(ra) # 8000432a <nameiparent>
    80005880:	892a                	mv	s2,a0
    80005882:	c935                	beqz	a0,800058f6 <sys_link+0x10a>
  ilock(dp);
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	2e2080e7          	jalr	738(ra) # 80003b66 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000588c:	00092703          	lw	a4,0(s2)
    80005890:	409c                	lw	a5,0(s1)
    80005892:	04f71d63          	bne	a4,a5,800058ec <sys_link+0x100>
    80005896:	40d0                	lw	a2,4(s1)
    80005898:	fd040593          	addi	a1,s0,-48
    8000589c:	854a                	mv	a0,s2
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	9bc080e7          	jalr	-1604(ra) # 8000425a <dirlink>
    800058a6:	04054363          	bltz	a0,800058ec <sys_link+0x100>
  iunlockput(dp);
    800058aa:	854a                	mv	a0,s2
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	51c080e7          	jalr	1308(ra) # 80003dc8 <iunlockput>
  iput(ip);
    800058b4:	8526                	mv	a0,s1
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	46a080e7          	jalr	1130(ra) # 80003d20 <iput>
  end_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	cea080e7          	jalr	-790(ra) # 800045a8 <end_op>
  return 0;
    800058c6:	4781                	li	a5,0
    800058c8:	a085                	j	80005928 <sys_link+0x13c>
    end_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	cde080e7          	jalr	-802(ra) # 800045a8 <end_op>
    return -1;
    800058d2:	57fd                	li	a5,-1
    800058d4:	a891                	j	80005928 <sys_link+0x13c>
    iunlockput(ip);
    800058d6:	8526                	mv	a0,s1
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	4f0080e7          	jalr	1264(ra) # 80003dc8 <iunlockput>
    end_op();
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	cc8080e7          	jalr	-824(ra) # 800045a8 <end_op>
    return -1;
    800058e8:	57fd                	li	a5,-1
    800058ea:	a83d                	j	80005928 <sys_link+0x13c>
    iunlockput(dp);
    800058ec:	854a                	mv	a0,s2
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	4da080e7          	jalr	1242(ra) # 80003dc8 <iunlockput>
  ilock(ip);
    800058f6:	8526                	mv	a0,s1
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	26e080e7          	jalr	622(ra) # 80003b66 <ilock>
  ip->nlink--;
    80005900:	04a4d783          	lhu	a5,74(s1)
    80005904:	37fd                	addiw	a5,a5,-1
    80005906:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000590a:	8526                	mv	a0,s1
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	190080e7          	jalr	400(ra) # 80003a9c <iupdate>
  iunlockput(ip);
    80005914:	8526                	mv	a0,s1
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	4b2080e7          	jalr	1202(ra) # 80003dc8 <iunlockput>
  end_op();
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	c8a080e7          	jalr	-886(ra) # 800045a8 <end_op>
  return -1;
    80005926:	57fd                	li	a5,-1
}
    80005928:	853e                	mv	a0,a5
    8000592a:	70b2                	ld	ra,296(sp)
    8000592c:	7412                	ld	s0,288(sp)
    8000592e:	64f2                	ld	s1,280(sp)
    80005930:	6952                	ld	s2,272(sp)
    80005932:	6155                	addi	sp,sp,304
    80005934:	8082                	ret

0000000080005936 <sys_unlink>:
{
    80005936:	7151                	addi	sp,sp,-240
    80005938:	f586                	sd	ra,232(sp)
    8000593a:	f1a2                	sd	s0,224(sp)
    8000593c:	eda6                	sd	s1,216(sp)
    8000593e:	e9ca                	sd	s2,208(sp)
    80005940:	e5ce                	sd	s3,200(sp)
    80005942:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005944:	08000613          	li	a2,128
    80005948:	f3040593          	addi	a1,s0,-208
    8000594c:	4501                	li	a0,0
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	650080e7          	jalr	1616(ra) # 80002f9e <argstr>
    80005956:	18054163          	bltz	a0,80005ad8 <sys_unlink+0x1a2>
  begin_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	bce080e7          	jalr	-1074(ra) # 80004528 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005962:	fb040593          	addi	a1,s0,-80
    80005966:	f3040513          	addi	a0,s0,-208
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	9c0080e7          	jalr	-1600(ra) # 8000432a <nameiparent>
    80005972:	84aa                	mv	s1,a0
    80005974:	c979                	beqz	a0,80005a4a <sys_unlink+0x114>
  ilock(dp);
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	1f0080e7          	jalr	496(ra) # 80003b66 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000597e:	00003597          	auipc	a1,0x3
    80005982:	dca58593          	addi	a1,a1,-566 # 80008748 <syscalls+0x2a8>
    80005986:	fb040513          	addi	a0,s0,-80
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	6a6080e7          	jalr	1702(ra) # 80004030 <namecmp>
    80005992:	14050a63          	beqz	a0,80005ae6 <sys_unlink+0x1b0>
    80005996:	00003597          	auipc	a1,0x3
    8000599a:	dba58593          	addi	a1,a1,-582 # 80008750 <syscalls+0x2b0>
    8000599e:	fb040513          	addi	a0,s0,-80
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	68e080e7          	jalr	1678(ra) # 80004030 <namecmp>
    800059aa:	12050e63          	beqz	a0,80005ae6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059ae:	f2c40613          	addi	a2,s0,-212
    800059b2:	fb040593          	addi	a1,s0,-80
    800059b6:	8526                	mv	a0,s1
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	692080e7          	jalr	1682(ra) # 8000404a <dirlookup>
    800059c0:	892a                	mv	s2,a0
    800059c2:	12050263          	beqz	a0,80005ae6 <sys_unlink+0x1b0>
  ilock(ip);
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	1a0080e7          	jalr	416(ra) # 80003b66 <ilock>
  if(ip->nlink < 1)
    800059ce:	04a91783          	lh	a5,74(s2)
    800059d2:	08f05263          	blez	a5,80005a56 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059d6:	04491703          	lh	a4,68(s2)
    800059da:	4785                	li	a5,1
    800059dc:	08f70563          	beq	a4,a5,80005a66 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059e0:	4641                	li	a2,16
    800059e2:	4581                	li	a1,0
    800059e4:	fc040513          	addi	a0,s0,-64
    800059e8:	ffffb097          	auipc	ra,0xffffb
    800059ec:	46a080e7          	jalr	1130(ra) # 80000e52 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059f0:	4741                	li	a4,16
    800059f2:	f2c42683          	lw	a3,-212(s0)
    800059f6:	fc040613          	addi	a2,s0,-64
    800059fa:	4581                	li	a1,0
    800059fc:	8526                	mv	a0,s1
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	514080e7          	jalr	1300(ra) # 80003f12 <writei>
    80005a06:	47c1                	li	a5,16
    80005a08:	0af51563          	bne	a0,a5,80005ab2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a0c:	04491703          	lh	a4,68(s2)
    80005a10:	4785                	li	a5,1
    80005a12:	0af70863          	beq	a4,a5,80005ac2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a16:	8526                	mv	a0,s1
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	3b0080e7          	jalr	944(ra) # 80003dc8 <iunlockput>
  ip->nlink--;
    80005a20:	04a95783          	lhu	a5,74(s2)
    80005a24:	37fd                	addiw	a5,a5,-1
    80005a26:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a2a:	854a                	mv	a0,s2
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	070080e7          	jalr	112(ra) # 80003a9c <iupdate>
  iunlockput(ip);
    80005a34:	854a                	mv	a0,s2
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	392080e7          	jalr	914(ra) # 80003dc8 <iunlockput>
  end_op();
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	b6a080e7          	jalr	-1174(ra) # 800045a8 <end_op>
  return 0;
    80005a46:	4501                	li	a0,0
    80005a48:	a84d                	j	80005afa <sys_unlink+0x1c4>
    end_op();
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	b5e080e7          	jalr	-1186(ra) # 800045a8 <end_op>
    return -1;
    80005a52:	557d                	li	a0,-1
    80005a54:	a05d                	j	80005afa <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a56:	00003517          	auipc	a0,0x3
    80005a5a:	d0250513          	addi	a0,a0,-766 # 80008758 <syscalls+0x2b8>
    80005a5e:	ffffb097          	auipc	ra,0xffffb
    80005a62:	ae0080e7          	jalr	-1312(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a66:	04c92703          	lw	a4,76(s2)
    80005a6a:	02000793          	li	a5,32
    80005a6e:	f6e7f9e3          	bgeu	a5,a4,800059e0 <sys_unlink+0xaa>
    80005a72:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a76:	4741                	li	a4,16
    80005a78:	86ce                	mv	a3,s3
    80005a7a:	f1840613          	addi	a2,s0,-232
    80005a7e:	4581                	li	a1,0
    80005a80:	854a                	mv	a0,s2
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	398080e7          	jalr	920(ra) # 80003e1a <readi>
    80005a8a:	47c1                	li	a5,16
    80005a8c:	00f51b63          	bne	a0,a5,80005aa2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a90:	f1845783          	lhu	a5,-232(s0)
    80005a94:	e7a1                	bnez	a5,80005adc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a96:	29c1                	addiw	s3,s3,16
    80005a98:	04c92783          	lw	a5,76(s2)
    80005a9c:	fcf9ede3          	bltu	s3,a5,80005a76 <sys_unlink+0x140>
    80005aa0:	b781                	j	800059e0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005aa2:	00003517          	auipc	a0,0x3
    80005aa6:	cce50513          	addi	a0,a0,-818 # 80008770 <syscalls+0x2d0>
    80005aaa:	ffffb097          	auipc	ra,0xffffb
    80005aae:	a94080e7          	jalr	-1388(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005ab2:	00003517          	auipc	a0,0x3
    80005ab6:	cd650513          	addi	a0,a0,-810 # 80008788 <syscalls+0x2e8>
    80005aba:	ffffb097          	auipc	ra,0xffffb
    80005abe:	a84080e7          	jalr	-1404(ra) # 8000053e <panic>
    dp->nlink--;
    80005ac2:	04a4d783          	lhu	a5,74(s1)
    80005ac6:	37fd                	addiw	a5,a5,-1
    80005ac8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005acc:	8526                	mv	a0,s1
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	fce080e7          	jalr	-50(ra) # 80003a9c <iupdate>
    80005ad6:	b781                	j	80005a16 <sys_unlink+0xe0>
    return -1;
    80005ad8:	557d                	li	a0,-1
    80005ada:	a005                	j	80005afa <sys_unlink+0x1c4>
    iunlockput(ip);
    80005adc:	854a                	mv	a0,s2
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	2ea080e7          	jalr	746(ra) # 80003dc8 <iunlockput>
  iunlockput(dp);
    80005ae6:	8526                	mv	a0,s1
    80005ae8:	ffffe097          	auipc	ra,0xffffe
    80005aec:	2e0080e7          	jalr	736(ra) # 80003dc8 <iunlockput>
  end_op();
    80005af0:	fffff097          	auipc	ra,0xfffff
    80005af4:	ab8080e7          	jalr	-1352(ra) # 800045a8 <end_op>
  return -1;
    80005af8:	557d                	li	a0,-1
}
    80005afa:	70ae                	ld	ra,232(sp)
    80005afc:	740e                	ld	s0,224(sp)
    80005afe:	64ee                	ld	s1,216(sp)
    80005b00:	694e                	ld	s2,208(sp)
    80005b02:	69ae                	ld	s3,200(sp)
    80005b04:	616d                	addi	sp,sp,240
    80005b06:	8082                	ret

0000000080005b08 <sys_open>:

uint64
sys_open(void)
{
    80005b08:	7131                	addi	sp,sp,-192
    80005b0a:	fd06                	sd	ra,184(sp)
    80005b0c:	f922                	sd	s0,176(sp)
    80005b0e:	f526                	sd	s1,168(sp)
    80005b10:	f14a                	sd	s2,160(sp)
    80005b12:	ed4e                	sd	s3,152(sp)
    80005b14:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005b16:	f4c40593          	addi	a1,s0,-180
    80005b1a:	4505                	li	a0,1
    80005b1c:	ffffd097          	auipc	ra,0xffffd
    80005b20:	442080e7          	jalr	1090(ra) # 80002f5e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b24:	08000613          	li	a2,128
    80005b28:	f5040593          	addi	a1,s0,-176
    80005b2c:	4501                	li	a0,0
    80005b2e:	ffffd097          	auipc	ra,0xffffd
    80005b32:	470080e7          	jalr	1136(ra) # 80002f9e <argstr>
    80005b36:	87aa                	mv	a5,a0
    return -1;
    80005b38:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b3a:	0a07c963          	bltz	a5,80005bec <sys_open+0xe4>

  begin_op();
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	9ea080e7          	jalr	-1558(ra) # 80004528 <begin_op>

  if(omode & O_CREATE){
    80005b46:	f4c42783          	lw	a5,-180(s0)
    80005b4a:	2007f793          	andi	a5,a5,512
    80005b4e:	cfc5                	beqz	a5,80005c06 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b50:	4681                	li	a3,0
    80005b52:	4601                	li	a2,0
    80005b54:	4589                	li	a1,2
    80005b56:	f5040513          	addi	a0,s0,-176
    80005b5a:	00000097          	auipc	ra,0x0
    80005b5e:	976080e7          	jalr	-1674(ra) # 800054d0 <create>
    80005b62:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b64:	c959                	beqz	a0,80005bfa <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b66:	04449703          	lh	a4,68(s1)
    80005b6a:	478d                	li	a5,3
    80005b6c:	00f71763          	bne	a4,a5,80005b7a <sys_open+0x72>
    80005b70:	0464d703          	lhu	a4,70(s1)
    80005b74:	47a5                	li	a5,9
    80005b76:	0ce7ed63          	bltu	a5,a4,80005c50 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	dbe080e7          	jalr	-578(ra) # 80004938 <filealloc>
    80005b82:	89aa                	mv	s3,a0
    80005b84:	10050363          	beqz	a0,80005c8a <sys_open+0x182>
    80005b88:	00000097          	auipc	ra,0x0
    80005b8c:	906080e7          	jalr	-1786(ra) # 8000548e <fdalloc>
    80005b90:	892a                	mv	s2,a0
    80005b92:	0e054763          	bltz	a0,80005c80 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b96:	04449703          	lh	a4,68(s1)
    80005b9a:	478d                	li	a5,3
    80005b9c:	0cf70563          	beq	a4,a5,80005c66 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ba0:	4789                	li	a5,2
    80005ba2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ba6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005baa:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005bae:	f4c42783          	lw	a5,-180(s0)
    80005bb2:	0017c713          	xori	a4,a5,1
    80005bb6:	8b05                	andi	a4,a4,1
    80005bb8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bbc:	0037f713          	andi	a4,a5,3
    80005bc0:	00e03733          	snez	a4,a4
    80005bc4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bc8:	4007f793          	andi	a5,a5,1024
    80005bcc:	c791                	beqz	a5,80005bd8 <sys_open+0xd0>
    80005bce:	04449703          	lh	a4,68(s1)
    80005bd2:	4789                	li	a5,2
    80005bd4:	0af70063          	beq	a4,a5,80005c74 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bd8:	8526                	mv	a0,s1
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	04e080e7          	jalr	78(ra) # 80003c28 <iunlock>
  end_op();
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	9c6080e7          	jalr	-1594(ra) # 800045a8 <end_op>

  return fd;
    80005bea:	854a                	mv	a0,s2
}
    80005bec:	70ea                	ld	ra,184(sp)
    80005bee:	744a                	ld	s0,176(sp)
    80005bf0:	74aa                	ld	s1,168(sp)
    80005bf2:	790a                	ld	s2,160(sp)
    80005bf4:	69ea                	ld	s3,152(sp)
    80005bf6:	6129                	addi	sp,sp,192
    80005bf8:	8082                	ret
      end_op();
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	9ae080e7          	jalr	-1618(ra) # 800045a8 <end_op>
      return -1;
    80005c02:	557d                	li	a0,-1
    80005c04:	b7e5                	j	80005bec <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c06:	f5040513          	addi	a0,s0,-176
    80005c0a:	ffffe097          	auipc	ra,0xffffe
    80005c0e:	702080e7          	jalr	1794(ra) # 8000430c <namei>
    80005c12:	84aa                	mv	s1,a0
    80005c14:	c905                	beqz	a0,80005c44 <sys_open+0x13c>
    ilock(ip);
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	f50080e7          	jalr	-176(ra) # 80003b66 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c1e:	04449703          	lh	a4,68(s1)
    80005c22:	4785                	li	a5,1
    80005c24:	f4f711e3          	bne	a4,a5,80005b66 <sys_open+0x5e>
    80005c28:	f4c42783          	lw	a5,-180(s0)
    80005c2c:	d7b9                	beqz	a5,80005b7a <sys_open+0x72>
      iunlockput(ip);
    80005c2e:	8526                	mv	a0,s1
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	198080e7          	jalr	408(ra) # 80003dc8 <iunlockput>
      end_op();
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	970080e7          	jalr	-1680(ra) # 800045a8 <end_op>
      return -1;
    80005c40:	557d                	li	a0,-1
    80005c42:	b76d                	j	80005bec <sys_open+0xe4>
      end_op();
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	964080e7          	jalr	-1692(ra) # 800045a8 <end_op>
      return -1;
    80005c4c:	557d                	li	a0,-1
    80005c4e:	bf79                	j	80005bec <sys_open+0xe4>
    iunlockput(ip);
    80005c50:	8526                	mv	a0,s1
    80005c52:	ffffe097          	auipc	ra,0xffffe
    80005c56:	176080e7          	jalr	374(ra) # 80003dc8 <iunlockput>
    end_op();
    80005c5a:	fffff097          	auipc	ra,0xfffff
    80005c5e:	94e080e7          	jalr	-1714(ra) # 800045a8 <end_op>
    return -1;
    80005c62:	557d                	li	a0,-1
    80005c64:	b761                	j	80005bec <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c66:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c6a:	04649783          	lh	a5,70(s1)
    80005c6e:	02f99223          	sh	a5,36(s3)
    80005c72:	bf25                	j	80005baa <sys_open+0xa2>
    itrunc(ip);
    80005c74:	8526                	mv	a0,s1
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	ffe080e7          	jalr	-2(ra) # 80003c74 <itrunc>
    80005c7e:	bfa9                	j	80005bd8 <sys_open+0xd0>
      fileclose(f);
    80005c80:	854e                	mv	a0,s3
    80005c82:	fffff097          	auipc	ra,0xfffff
    80005c86:	d72080e7          	jalr	-654(ra) # 800049f4 <fileclose>
    iunlockput(ip);
    80005c8a:	8526                	mv	a0,s1
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	13c080e7          	jalr	316(ra) # 80003dc8 <iunlockput>
    end_op();
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	914080e7          	jalr	-1772(ra) # 800045a8 <end_op>
    return -1;
    80005c9c:	557d                	li	a0,-1
    80005c9e:	b7b9                	j	80005bec <sys_open+0xe4>

0000000080005ca0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ca0:	7175                	addi	sp,sp,-144
    80005ca2:	e506                	sd	ra,136(sp)
    80005ca4:	e122                	sd	s0,128(sp)
    80005ca6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	880080e7          	jalr	-1920(ra) # 80004528 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cb0:	08000613          	li	a2,128
    80005cb4:	f7040593          	addi	a1,s0,-144
    80005cb8:	4501                	li	a0,0
    80005cba:	ffffd097          	auipc	ra,0xffffd
    80005cbe:	2e4080e7          	jalr	740(ra) # 80002f9e <argstr>
    80005cc2:	02054963          	bltz	a0,80005cf4 <sys_mkdir+0x54>
    80005cc6:	4681                	li	a3,0
    80005cc8:	4601                	li	a2,0
    80005cca:	4585                	li	a1,1
    80005ccc:	f7040513          	addi	a0,s0,-144
    80005cd0:	00000097          	auipc	ra,0x0
    80005cd4:	800080e7          	jalr	-2048(ra) # 800054d0 <create>
    80005cd8:	cd11                	beqz	a0,80005cf4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cda:	ffffe097          	auipc	ra,0xffffe
    80005cde:	0ee080e7          	jalr	238(ra) # 80003dc8 <iunlockput>
  end_op();
    80005ce2:	fffff097          	auipc	ra,0xfffff
    80005ce6:	8c6080e7          	jalr	-1850(ra) # 800045a8 <end_op>
  return 0;
    80005cea:	4501                	li	a0,0
}
    80005cec:	60aa                	ld	ra,136(sp)
    80005cee:	640a                	ld	s0,128(sp)
    80005cf0:	6149                	addi	sp,sp,144
    80005cf2:	8082                	ret
    end_op();
    80005cf4:	fffff097          	auipc	ra,0xfffff
    80005cf8:	8b4080e7          	jalr	-1868(ra) # 800045a8 <end_op>
    return -1;
    80005cfc:	557d                	li	a0,-1
    80005cfe:	b7fd                	j	80005cec <sys_mkdir+0x4c>

0000000080005d00 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d00:	7135                	addi	sp,sp,-160
    80005d02:	ed06                	sd	ra,152(sp)
    80005d04:	e922                	sd	s0,144(sp)
    80005d06:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	820080e7          	jalr	-2016(ra) # 80004528 <begin_op>
  argint(1, &major);
    80005d10:	f6c40593          	addi	a1,s0,-148
    80005d14:	4505                	li	a0,1
    80005d16:	ffffd097          	auipc	ra,0xffffd
    80005d1a:	248080e7          	jalr	584(ra) # 80002f5e <argint>
  argint(2, &minor);
    80005d1e:	f6840593          	addi	a1,s0,-152
    80005d22:	4509                	li	a0,2
    80005d24:	ffffd097          	auipc	ra,0xffffd
    80005d28:	23a080e7          	jalr	570(ra) # 80002f5e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d2c:	08000613          	li	a2,128
    80005d30:	f7040593          	addi	a1,s0,-144
    80005d34:	4501                	li	a0,0
    80005d36:	ffffd097          	auipc	ra,0xffffd
    80005d3a:	268080e7          	jalr	616(ra) # 80002f9e <argstr>
    80005d3e:	02054b63          	bltz	a0,80005d74 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d42:	f6841683          	lh	a3,-152(s0)
    80005d46:	f6c41603          	lh	a2,-148(s0)
    80005d4a:	458d                	li	a1,3
    80005d4c:	f7040513          	addi	a0,s0,-144
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	780080e7          	jalr	1920(ra) # 800054d0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d58:	cd11                	beqz	a0,80005d74 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	06e080e7          	jalr	110(ra) # 80003dc8 <iunlockput>
  end_op();
    80005d62:	fffff097          	auipc	ra,0xfffff
    80005d66:	846080e7          	jalr	-1978(ra) # 800045a8 <end_op>
  return 0;
    80005d6a:	4501                	li	a0,0
}
    80005d6c:	60ea                	ld	ra,152(sp)
    80005d6e:	644a                	ld	s0,144(sp)
    80005d70:	610d                	addi	sp,sp,160
    80005d72:	8082                	ret
    end_op();
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	834080e7          	jalr	-1996(ra) # 800045a8 <end_op>
    return -1;
    80005d7c:	557d                	li	a0,-1
    80005d7e:	b7fd                	j	80005d6c <sys_mknod+0x6c>

0000000080005d80 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d80:	7135                	addi	sp,sp,-160
    80005d82:	ed06                	sd	ra,152(sp)
    80005d84:	e922                	sd	s0,144(sp)
    80005d86:	e526                	sd	s1,136(sp)
    80005d88:	e14a                	sd	s2,128(sp)
    80005d8a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d8c:	ffffc097          	auipc	ra,0xffffc
    80005d90:	df4080e7          	jalr	-524(ra) # 80001b80 <myproc>
    80005d94:	892a                	mv	s2,a0
  
  begin_op();
    80005d96:	ffffe097          	auipc	ra,0xffffe
    80005d9a:	792080e7          	jalr	1938(ra) # 80004528 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d9e:	08000613          	li	a2,128
    80005da2:	f6040593          	addi	a1,s0,-160
    80005da6:	4501                	li	a0,0
    80005da8:	ffffd097          	auipc	ra,0xffffd
    80005dac:	1f6080e7          	jalr	502(ra) # 80002f9e <argstr>
    80005db0:	04054b63          	bltz	a0,80005e06 <sys_chdir+0x86>
    80005db4:	f6040513          	addi	a0,s0,-160
    80005db8:	ffffe097          	auipc	ra,0xffffe
    80005dbc:	554080e7          	jalr	1364(ra) # 8000430c <namei>
    80005dc0:	84aa                	mv	s1,a0
    80005dc2:	c131                	beqz	a0,80005e06 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005dc4:	ffffe097          	auipc	ra,0xffffe
    80005dc8:	da2080e7          	jalr	-606(ra) # 80003b66 <ilock>
  if(ip->type != T_DIR){
    80005dcc:	04449703          	lh	a4,68(s1)
    80005dd0:	4785                	li	a5,1
    80005dd2:	04f71063          	bne	a4,a5,80005e12 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dd6:	8526                	mv	a0,s1
    80005dd8:	ffffe097          	auipc	ra,0xffffe
    80005ddc:	e50080e7          	jalr	-432(ra) # 80003c28 <iunlock>
  iput(p->cwd);
    80005de0:	15093503          	ld	a0,336(s2)
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	f3c080e7          	jalr	-196(ra) # 80003d20 <iput>
  end_op();
    80005dec:	ffffe097          	auipc	ra,0xffffe
    80005df0:	7bc080e7          	jalr	1980(ra) # 800045a8 <end_op>
  p->cwd = ip;
    80005df4:	14993823          	sd	s1,336(s2)
  return 0;
    80005df8:	4501                	li	a0,0
}
    80005dfa:	60ea                	ld	ra,152(sp)
    80005dfc:	644a                	ld	s0,144(sp)
    80005dfe:	64aa                	ld	s1,136(sp)
    80005e00:	690a                	ld	s2,128(sp)
    80005e02:	610d                	addi	sp,sp,160
    80005e04:	8082                	ret
    end_op();
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	7a2080e7          	jalr	1954(ra) # 800045a8 <end_op>
    return -1;
    80005e0e:	557d                	li	a0,-1
    80005e10:	b7ed                	j	80005dfa <sys_chdir+0x7a>
    iunlockput(ip);
    80005e12:	8526                	mv	a0,s1
    80005e14:	ffffe097          	auipc	ra,0xffffe
    80005e18:	fb4080e7          	jalr	-76(ra) # 80003dc8 <iunlockput>
    end_op();
    80005e1c:	ffffe097          	auipc	ra,0xffffe
    80005e20:	78c080e7          	jalr	1932(ra) # 800045a8 <end_op>
    return -1;
    80005e24:	557d                	li	a0,-1
    80005e26:	bfd1                	j	80005dfa <sys_chdir+0x7a>

0000000080005e28 <sys_exec>:

uint64
sys_exec(void)
{
    80005e28:	7145                	addi	sp,sp,-464
    80005e2a:	e786                	sd	ra,456(sp)
    80005e2c:	e3a2                	sd	s0,448(sp)
    80005e2e:	ff26                	sd	s1,440(sp)
    80005e30:	fb4a                	sd	s2,432(sp)
    80005e32:	f74e                	sd	s3,424(sp)
    80005e34:	f352                	sd	s4,416(sp)
    80005e36:	ef56                	sd	s5,408(sp)
    80005e38:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005e3a:	e3840593          	addi	a1,s0,-456
    80005e3e:	4505                	li	a0,1
    80005e40:	ffffd097          	auipc	ra,0xffffd
    80005e44:	13e080e7          	jalr	318(ra) # 80002f7e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e48:	08000613          	li	a2,128
    80005e4c:	f4040593          	addi	a1,s0,-192
    80005e50:	4501                	li	a0,0
    80005e52:	ffffd097          	auipc	ra,0xffffd
    80005e56:	14c080e7          	jalr	332(ra) # 80002f9e <argstr>
    80005e5a:	87aa                	mv	a5,a0
    return -1;
    80005e5c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e5e:	0c07c263          	bltz	a5,80005f22 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e62:	10000613          	li	a2,256
    80005e66:	4581                	li	a1,0
    80005e68:	e4040513          	addi	a0,s0,-448
    80005e6c:	ffffb097          	auipc	ra,0xffffb
    80005e70:	fe6080e7          	jalr	-26(ra) # 80000e52 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e74:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e78:	89a6                	mv	s3,s1
    80005e7a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e7c:	02000a13          	li	s4,32
    80005e80:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e84:	00391793          	slli	a5,s2,0x3
    80005e88:	e3040593          	addi	a1,s0,-464
    80005e8c:	e3843503          	ld	a0,-456(s0)
    80005e90:	953e                	add	a0,a0,a5
    80005e92:	ffffd097          	auipc	ra,0xffffd
    80005e96:	02e080e7          	jalr	46(ra) # 80002ec0 <fetchaddr>
    80005e9a:	02054a63          	bltz	a0,80005ece <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005e9e:	e3043783          	ld	a5,-464(s0)
    80005ea2:	c3b9                	beqz	a5,80005ee8 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ea4:	ffffb097          	auipc	ra,0xffffb
    80005ea8:	db0080e7          	jalr	-592(ra) # 80000c54 <kalloc>
    80005eac:	85aa                	mv	a1,a0
    80005eae:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005eb2:	cd11                	beqz	a0,80005ece <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005eb4:	6605                	lui	a2,0x1
    80005eb6:	e3043503          	ld	a0,-464(s0)
    80005eba:	ffffd097          	auipc	ra,0xffffd
    80005ebe:	058080e7          	jalr	88(ra) # 80002f12 <fetchstr>
    80005ec2:	00054663          	bltz	a0,80005ece <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005ec6:	0905                	addi	s2,s2,1
    80005ec8:	09a1                	addi	s3,s3,8
    80005eca:	fb491be3          	bne	s2,s4,80005e80 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ece:	10048913          	addi	s2,s1,256
    80005ed2:	6088                	ld	a0,0(s1)
    80005ed4:	c531                	beqz	a0,80005f20 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ed6:	ffffb097          	auipc	ra,0xffffb
    80005eda:	c5a080e7          	jalr	-934(ra) # 80000b30 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ede:	04a1                	addi	s1,s1,8
    80005ee0:	ff2499e3          	bne	s1,s2,80005ed2 <sys_exec+0xaa>
  return -1;
    80005ee4:	557d                	li	a0,-1
    80005ee6:	a835                	j	80005f22 <sys_exec+0xfa>
      argv[i] = 0;
    80005ee8:	0a8e                	slli	s5,s5,0x3
    80005eea:	fc040793          	addi	a5,s0,-64
    80005eee:	9abe                	add	s5,s5,a5
    80005ef0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ef4:	e4040593          	addi	a1,s0,-448
    80005ef8:	f4040513          	addi	a0,s0,-192
    80005efc:	fffff097          	auipc	ra,0xfffff
    80005f00:	172080e7          	jalr	370(ra) # 8000506e <exec>
    80005f04:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f06:	10048993          	addi	s3,s1,256
    80005f0a:	6088                	ld	a0,0(s1)
    80005f0c:	c901                	beqz	a0,80005f1c <sys_exec+0xf4>
    kfree(argv[i]);
    80005f0e:	ffffb097          	auipc	ra,0xffffb
    80005f12:	c22080e7          	jalr	-990(ra) # 80000b30 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f16:	04a1                	addi	s1,s1,8
    80005f18:	ff3499e3          	bne	s1,s3,80005f0a <sys_exec+0xe2>
  return ret;
    80005f1c:	854a                	mv	a0,s2
    80005f1e:	a011                	j	80005f22 <sys_exec+0xfa>
  return -1;
    80005f20:	557d                	li	a0,-1
}
    80005f22:	60be                	ld	ra,456(sp)
    80005f24:	641e                	ld	s0,448(sp)
    80005f26:	74fa                	ld	s1,440(sp)
    80005f28:	795a                	ld	s2,432(sp)
    80005f2a:	79ba                	ld	s3,424(sp)
    80005f2c:	7a1a                	ld	s4,416(sp)
    80005f2e:	6afa                	ld	s5,408(sp)
    80005f30:	6179                	addi	sp,sp,464
    80005f32:	8082                	ret

0000000080005f34 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f34:	7139                	addi	sp,sp,-64
    80005f36:	fc06                	sd	ra,56(sp)
    80005f38:	f822                	sd	s0,48(sp)
    80005f3a:	f426                	sd	s1,40(sp)
    80005f3c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f3e:	ffffc097          	auipc	ra,0xffffc
    80005f42:	c42080e7          	jalr	-958(ra) # 80001b80 <myproc>
    80005f46:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f48:	fd840593          	addi	a1,s0,-40
    80005f4c:	4501                	li	a0,0
    80005f4e:	ffffd097          	auipc	ra,0xffffd
    80005f52:	030080e7          	jalr	48(ra) # 80002f7e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005f56:	fc840593          	addi	a1,s0,-56
    80005f5a:	fd040513          	addi	a0,s0,-48
    80005f5e:	fffff097          	auipc	ra,0xfffff
    80005f62:	dc6080e7          	jalr	-570(ra) # 80004d24 <pipealloc>
    return -1;
    80005f66:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f68:	0c054463          	bltz	a0,80006030 <sys_pipe+0xfc>
  fd0 = -1;
    80005f6c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f70:	fd043503          	ld	a0,-48(s0)
    80005f74:	fffff097          	auipc	ra,0xfffff
    80005f78:	51a080e7          	jalr	1306(ra) # 8000548e <fdalloc>
    80005f7c:	fca42223          	sw	a0,-60(s0)
    80005f80:	08054b63          	bltz	a0,80006016 <sys_pipe+0xe2>
    80005f84:	fc843503          	ld	a0,-56(s0)
    80005f88:	fffff097          	auipc	ra,0xfffff
    80005f8c:	506080e7          	jalr	1286(ra) # 8000548e <fdalloc>
    80005f90:	fca42023          	sw	a0,-64(s0)
    80005f94:	06054863          	bltz	a0,80006004 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f98:	4691                	li	a3,4
    80005f9a:	fc440613          	addi	a2,s0,-60
    80005f9e:	fd843583          	ld	a1,-40(s0)
    80005fa2:	68a8                	ld	a0,80(s1)
    80005fa4:	ffffc097          	auipc	ra,0xffffc
    80005fa8:	860080e7          	jalr	-1952(ra) # 80001804 <copyout>
    80005fac:	02054063          	bltz	a0,80005fcc <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fb0:	4691                	li	a3,4
    80005fb2:	fc040613          	addi	a2,s0,-64
    80005fb6:	fd843583          	ld	a1,-40(s0)
    80005fba:	0591                	addi	a1,a1,4
    80005fbc:	68a8                	ld	a0,80(s1)
    80005fbe:	ffffc097          	auipc	ra,0xffffc
    80005fc2:	846080e7          	jalr	-1978(ra) # 80001804 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fc6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fc8:	06055463          	bgez	a0,80006030 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005fcc:	fc442783          	lw	a5,-60(s0)
    80005fd0:	07e9                	addi	a5,a5,26
    80005fd2:	078e                	slli	a5,a5,0x3
    80005fd4:	97a6                	add	a5,a5,s1
    80005fd6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fda:	fc042503          	lw	a0,-64(s0)
    80005fde:	0569                	addi	a0,a0,26
    80005fe0:	050e                	slli	a0,a0,0x3
    80005fe2:	94aa                	add	s1,s1,a0
    80005fe4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005fe8:	fd043503          	ld	a0,-48(s0)
    80005fec:	fffff097          	auipc	ra,0xfffff
    80005ff0:	a08080e7          	jalr	-1528(ra) # 800049f4 <fileclose>
    fileclose(wf);
    80005ff4:	fc843503          	ld	a0,-56(s0)
    80005ff8:	fffff097          	auipc	ra,0xfffff
    80005ffc:	9fc080e7          	jalr	-1540(ra) # 800049f4 <fileclose>
    return -1;
    80006000:	57fd                	li	a5,-1
    80006002:	a03d                	j	80006030 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006004:	fc442783          	lw	a5,-60(s0)
    80006008:	0007c763          	bltz	a5,80006016 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000600c:	07e9                	addi	a5,a5,26
    8000600e:	078e                	slli	a5,a5,0x3
    80006010:	94be                	add	s1,s1,a5
    80006012:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006016:	fd043503          	ld	a0,-48(s0)
    8000601a:	fffff097          	auipc	ra,0xfffff
    8000601e:	9da080e7          	jalr	-1574(ra) # 800049f4 <fileclose>
    fileclose(wf);
    80006022:	fc843503          	ld	a0,-56(s0)
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	9ce080e7          	jalr	-1586(ra) # 800049f4 <fileclose>
    return -1;
    8000602e:	57fd                	li	a5,-1
}
    80006030:	853e                	mv	a0,a5
    80006032:	70e2                	ld	ra,56(sp)
    80006034:	7442                	ld	s0,48(sp)
    80006036:	74a2                	ld	s1,40(sp)
    80006038:	6121                	addi	sp,sp,64
    8000603a:	8082                	ret
    8000603c:	0000                	unimp
	...

0000000080006040 <kernelvec>:
    80006040:	7111                	addi	sp,sp,-256
    80006042:	e006                	sd	ra,0(sp)
    80006044:	e40a                	sd	sp,8(sp)
    80006046:	e80e                	sd	gp,16(sp)
    80006048:	ec12                	sd	tp,24(sp)
    8000604a:	f016                	sd	t0,32(sp)
    8000604c:	f41a                	sd	t1,40(sp)
    8000604e:	f81e                	sd	t2,48(sp)
    80006050:	fc22                	sd	s0,56(sp)
    80006052:	e0a6                	sd	s1,64(sp)
    80006054:	e4aa                	sd	a0,72(sp)
    80006056:	e8ae                	sd	a1,80(sp)
    80006058:	ecb2                	sd	a2,88(sp)
    8000605a:	f0b6                	sd	a3,96(sp)
    8000605c:	f4ba                	sd	a4,104(sp)
    8000605e:	f8be                	sd	a5,112(sp)
    80006060:	fcc2                	sd	a6,120(sp)
    80006062:	e146                	sd	a7,128(sp)
    80006064:	e54a                	sd	s2,136(sp)
    80006066:	e94e                	sd	s3,144(sp)
    80006068:	ed52                	sd	s4,152(sp)
    8000606a:	f156                	sd	s5,160(sp)
    8000606c:	f55a                	sd	s6,168(sp)
    8000606e:	f95e                	sd	s7,176(sp)
    80006070:	fd62                	sd	s8,184(sp)
    80006072:	e1e6                	sd	s9,192(sp)
    80006074:	e5ea                	sd	s10,200(sp)
    80006076:	e9ee                	sd	s11,208(sp)
    80006078:	edf2                	sd	t3,216(sp)
    8000607a:	f1f6                	sd	t4,224(sp)
    8000607c:	f5fa                	sd	t5,232(sp)
    8000607e:	f9fe                	sd	t6,240(sp)
    80006080:	d0dfc0ef          	jal	ra,80002d8c <kerneltrap>
    80006084:	6082                	ld	ra,0(sp)
    80006086:	6122                	ld	sp,8(sp)
    80006088:	61c2                	ld	gp,16(sp)
    8000608a:	7282                	ld	t0,32(sp)
    8000608c:	7322                	ld	t1,40(sp)
    8000608e:	73c2                	ld	t2,48(sp)
    80006090:	7462                	ld	s0,56(sp)
    80006092:	6486                	ld	s1,64(sp)
    80006094:	6526                	ld	a0,72(sp)
    80006096:	65c6                	ld	a1,80(sp)
    80006098:	6666                	ld	a2,88(sp)
    8000609a:	7686                	ld	a3,96(sp)
    8000609c:	7726                	ld	a4,104(sp)
    8000609e:	77c6                	ld	a5,112(sp)
    800060a0:	7866                	ld	a6,120(sp)
    800060a2:	688a                	ld	a7,128(sp)
    800060a4:	692a                	ld	s2,136(sp)
    800060a6:	69ca                	ld	s3,144(sp)
    800060a8:	6a6a                	ld	s4,152(sp)
    800060aa:	7a8a                	ld	s5,160(sp)
    800060ac:	7b2a                	ld	s6,168(sp)
    800060ae:	7bca                	ld	s7,176(sp)
    800060b0:	7c6a                	ld	s8,184(sp)
    800060b2:	6c8e                	ld	s9,192(sp)
    800060b4:	6d2e                	ld	s10,200(sp)
    800060b6:	6dce                	ld	s11,208(sp)
    800060b8:	6e6e                	ld	t3,216(sp)
    800060ba:	7e8e                	ld	t4,224(sp)
    800060bc:	7f2e                	ld	t5,232(sp)
    800060be:	7fce                	ld	t6,240(sp)
    800060c0:	6111                	addi	sp,sp,256
    800060c2:	10200073          	sret
    800060c6:	00000013          	nop
    800060ca:	00000013          	nop
    800060ce:	0001                	nop

00000000800060d0 <timervec>:
    800060d0:	34051573          	csrrw	a0,mscratch,a0
    800060d4:	e10c                	sd	a1,0(a0)
    800060d6:	e510                	sd	a2,8(a0)
    800060d8:	e914                	sd	a3,16(a0)
    800060da:	6d0c                	ld	a1,24(a0)
    800060dc:	7110                	ld	a2,32(a0)
    800060de:	6194                	ld	a3,0(a1)
    800060e0:	96b2                	add	a3,a3,a2
    800060e2:	e194                	sd	a3,0(a1)
    800060e4:	4589                	li	a1,2
    800060e6:	14459073          	csrw	sip,a1
    800060ea:	6914                	ld	a3,16(a0)
    800060ec:	6510                	ld	a2,8(a0)
    800060ee:	610c                	ld	a1,0(a0)
    800060f0:	34051573          	csrrw	a0,mscratch,a0
    800060f4:	30200073          	mret
	...

00000000800060fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060fa:	1141                	addi	sp,sp,-16
    800060fc:	e422                	sd	s0,8(sp)
    800060fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006100:	0c0007b7          	lui	a5,0xc000
    80006104:	4705                	li	a4,1
    80006106:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006108:	c3d8                	sw	a4,4(a5)
}
    8000610a:	6422                	ld	s0,8(sp)
    8000610c:	0141                	addi	sp,sp,16
    8000610e:	8082                	ret

0000000080006110 <plicinithart>:

void
plicinithart(void)
{
    80006110:	1141                	addi	sp,sp,-16
    80006112:	e406                	sd	ra,8(sp)
    80006114:	e022                	sd	s0,0(sp)
    80006116:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006118:	ffffc097          	auipc	ra,0xffffc
    8000611c:	a3c080e7          	jalr	-1476(ra) # 80001b54 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006120:	0085171b          	slliw	a4,a0,0x8
    80006124:	0c0027b7          	lui	a5,0xc002
    80006128:	97ba                	add	a5,a5,a4
    8000612a:	40200713          	li	a4,1026
    8000612e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006132:	00d5151b          	slliw	a0,a0,0xd
    80006136:	0c2017b7          	lui	a5,0xc201
    8000613a:	953e                	add	a0,a0,a5
    8000613c:	00052023          	sw	zero,0(a0)
}
    80006140:	60a2                	ld	ra,8(sp)
    80006142:	6402                	ld	s0,0(sp)
    80006144:	0141                	addi	sp,sp,16
    80006146:	8082                	ret

0000000080006148 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006148:	1141                	addi	sp,sp,-16
    8000614a:	e406                	sd	ra,8(sp)
    8000614c:	e022                	sd	s0,0(sp)
    8000614e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006150:	ffffc097          	auipc	ra,0xffffc
    80006154:	a04080e7          	jalr	-1532(ra) # 80001b54 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006158:	00d5179b          	slliw	a5,a0,0xd
    8000615c:	0c201537          	lui	a0,0xc201
    80006160:	953e                	add	a0,a0,a5
  return irq;
}
    80006162:	4148                	lw	a0,4(a0)
    80006164:	60a2                	ld	ra,8(sp)
    80006166:	6402                	ld	s0,0(sp)
    80006168:	0141                	addi	sp,sp,16
    8000616a:	8082                	ret

000000008000616c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000616c:	1101                	addi	sp,sp,-32
    8000616e:	ec06                	sd	ra,24(sp)
    80006170:	e822                	sd	s0,16(sp)
    80006172:	e426                	sd	s1,8(sp)
    80006174:	1000                	addi	s0,sp,32
    80006176:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006178:	ffffc097          	auipc	ra,0xffffc
    8000617c:	9dc080e7          	jalr	-1572(ra) # 80001b54 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006180:	00d5151b          	slliw	a0,a0,0xd
    80006184:	0c2017b7          	lui	a5,0xc201
    80006188:	97aa                	add	a5,a5,a0
    8000618a:	c3c4                	sw	s1,4(a5)
}
    8000618c:	60e2                	ld	ra,24(sp)
    8000618e:	6442                	ld	s0,16(sp)
    80006190:	64a2                	ld	s1,8(sp)
    80006192:	6105                	addi	sp,sp,32
    80006194:	8082                	ret

0000000080006196 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006196:	1141                	addi	sp,sp,-16
    80006198:	e406                	sd	ra,8(sp)
    8000619a:	e022                	sd	s0,0(sp)
    8000619c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000619e:	479d                	li	a5,7
    800061a0:	04a7cc63          	blt	a5,a0,800061f8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800061a4:	0023c797          	auipc	a5,0x23c
    800061a8:	ed478793          	addi	a5,a5,-300 # 80242078 <disk>
    800061ac:	97aa                	add	a5,a5,a0
    800061ae:	0187c783          	lbu	a5,24(a5)
    800061b2:	ebb9                	bnez	a5,80006208 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061b4:	00451613          	slli	a2,a0,0x4
    800061b8:	0023c797          	auipc	a5,0x23c
    800061bc:	ec078793          	addi	a5,a5,-320 # 80242078 <disk>
    800061c0:	6394                	ld	a3,0(a5)
    800061c2:	96b2                	add	a3,a3,a2
    800061c4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061c8:	6398                	ld	a4,0(a5)
    800061ca:	9732                	add	a4,a4,a2
    800061cc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800061d0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800061d4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800061d8:	953e                	add	a0,a0,a5
    800061da:	4785                	li	a5,1
    800061dc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800061e0:	0023c517          	auipc	a0,0x23c
    800061e4:	eb050513          	addi	a0,a0,-336 # 80242090 <disk+0x18>
    800061e8:	ffffc097          	auipc	ra,0xffffc
    800061ec:	0b8080e7          	jalr	184(ra) # 800022a0 <wakeup>
}
    800061f0:	60a2                	ld	ra,8(sp)
    800061f2:	6402                	ld	s0,0(sp)
    800061f4:	0141                	addi	sp,sp,16
    800061f6:	8082                	ret
    panic("free_desc 1");
    800061f8:	00002517          	auipc	a0,0x2
    800061fc:	5a050513          	addi	a0,a0,1440 # 80008798 <syscalls+0x2f8>
    80006200:	ffffa097          	auipc	ra,0xffffa
    80006204:	33e080e7          	jalr	830(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006208:	00002517          	auipc	a0,0x2
    8000620c:	5a050513          	addi	a0,a0,1440 # 800087a8 <syscalls+0x308>
    80006210:	ffffa097          	auipc	ra,0xffffa
    80006214:	32e080e7          	jalr	814(ra) # 8000053e <panic>

0000000080006218 <virtio_disk_init>:
{
    80006218:	1101                	addi	sp,sp,-32
    8000621a:	ec06                	sd	ra,24(sp)
    8000621c:	e822                	sd	s0,16(sp)
    8000621e:	e426                	sd	s1,8(sp)
    80006220:	e04a                	sd	s2,0(sp)
    80006222:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006224:	00002597          	auipc	a1,0x2
    80006228:	59458593          	addi	a1,a1,1428 # 800087b8 <syscalls+0x318>
    8000622c:	0023c517          	auipc	a0,0x23c
    80006230:	f7450513          	addi	a0,a0,-140 # 802421a0 <disk+0x128>
    80006234:	ffffb097          	auipc	ra,0xffffb
    80006238:	a92080e7          	jalr	-1390(ra) # 80000cc6 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000623c:	100017b7          	lui	a5,0x10001
    80006240:	4398                	lw	a4,0(a5)
    80006242:	2701                	sext.w	a4,a4
    80006244:	747277b7          	lui	a5,0x74727
    80006248:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000624c:	14f71c63          	bne	a4,a5,800063a4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006250:	100017b7          	lui	a5,0x10001
    80006254:	43dc                	lw	a5,4(a5)
    80006256:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006258:	4709                	li	a4,2
    8000625a:	14e79563          	bne	a5,a4,800063a4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000625e:	100017b7          	lui	a5,0x10001
    80006262:	479c                	lw	a5,8(a5)
    80006264:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006266:	12e79f63          	bne	a5,a4,800063a4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000626a:	100017b7          	lui	a5,0x10001
    8000626e:	47d8                	lw	a4,12(a5)
    80006270:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006272:	554d47b7          	lui	a5,0x554d4
    80006276:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000627a:	12f71563          	bne	a4,a5,800063a4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000627e:	100017b7          	lui	a5,0x10001
    80006282:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006286:	4705                	li	a4,1
    80006288:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000628a:	470d                	li	a4,3
    8000628c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000628e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006290:	c7ffe737          	lui	a4,0xc7ffe
    80006294:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47dbc5a7>
    80006298:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000629a:	2701                	sext.w	a4,a4
    8000629c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000629e:	472d                	li	a4,11
    800062a0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800062a2:	5bbc                	lw	a5,112(a5)
    800062a4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800062a8:	8ba1                	andi	a5,a5,8
    800062aa:	10078563          	beqz	a5,800063b4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062ae:	100017b7          	lui	a5,0x10001
    800062b2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800062b6:	43fc                	lw	a5,68(a5)
    800062b8:	2781                	sext.w	a5,a5
    800062ba:	10079563          	bnez	a5,800063c4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062be:	100017b7          	lui	a5,0x10001
    800062c2:	5bdc                	lw	a5,52(a5)
    800062c4:	2781                	sext.w	a5,a5
  if(max == 0)
    800062c6:	10078763          	beqz	a5,800063d4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    800062ca:	471d                	li	a4,7
    800062cc:	10f77c63          	bgeu	a4,a5,800063e4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800062d0:	ffffb097          	auipc	ra,0xffffb
    800062d4:	984080e7          	jalr	-1660(ra) # 80000c54 <kalloc>
    800062d8:	0023c497          	auipc	s1,0x23c
    800062dc:	da048493          	addi	s1,s1,-608 # 80242078 <disk>
    800062e0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800062e2:	ffffb097          	auipc	ra,0xffffb
    800062e6:	972080e7          	jalr	-1678(ra) # 80000c54 <kalloc>
    800062ea:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800062ec:	ffffb097          	auipc	ra,0xffffb
    800062f0:	968080e7          	jalr	-1688(ra) # 80000c54 <kalloc>
    800062f4:	87aa                	mv	a5,a0
    800062f6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800062f8:	6088                	ld	a0,0(s1)
    800062fa:	cd6d                	beqz	a0,800063f4 <virtio_disk_init+0x1dc>
    800062fc:	0023c717          	auipc	a4,0x23c
    80006300:	d8473703          	ld	a4,-636(a4) # 80242080 <disk+0x8>
    80006304:	cb65                	beqz	a4,800063f4 <virtio_disk_init+0x1dc>
    80006306:	c7fd                	beqz	a5,800063f4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006308:	6605                	lui	a2,0x1
    8000630a:	4581                	li	a1,0
    8000630c:	ffffb097          	auipc	ra,0xffffb
    80006310:	b46080e7          	jalr	-1210(ra) # 80000e52 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006314:	0023c497          	auipc	s1,0x23c
    80006318:	d6448493          	addi	s1,s1,-668 # 80242078 <disk>
    8000631c:	6605                	lui	a2,0x1
    8000631e:	4581                	li	a1,0
    80006320:	6488                	ld	a0,8(s1)
    80006322:	ffffb097          	auipc	ra,0xffffb
    80006326:	b30080e7          	jalr	-1232(ra) # 80000e52 <memset>
  memset(disk.used, 0, PGSIZE);
    8000632a:	6605                	lui	a2,0x1
    8000632c:	4581                	li	a1,0
    8000632e:	6888                	ld	a0,16(s1)
    80006330:	ffffb097          	auipc	ra,0xffffb
    80006334:	b22080e7          	jalr	-1246(ra) # 80000e52 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006338:	100017b7          	lui	a5,0x10001
    8000633c:	4721                	li	a4,8
    8000633e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006340:	4098                	lw	a4,0(s1)
    80006342:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006346:	40d8                	lw	a4,4(s1)
    80006348:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000634c:	6498                	ld	a4,8(s1)
    8000634e:	0007069b          	sext.w	a3,a4
    80006352:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006356:	9701                	srai	a4,a4,0x20
    80006358:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000635c:	6898                	ld	a4,16(s1)
    8000635e:	0007069b          	sext.w	a3,a4
    80006362:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006366:	9701                	srai	a4,a4,0x20
    80006368:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000636c:	4705                	li	a4,1
    8000636e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006370:	00e48c23          	sb	a4,24(s1)
    80006374:	00e48ca3          	sb	a4,25(s1)
    80006378:	00e48d23          	sb	a4,26(s1)
    8000637c:	00e48da3          	sb	a4,27(s1)
    80006380:	00e48e23          	sb	a4,28(s1)
    80006384:	00e48ea3          	sb	a4,29(s1)
    80006388:	00e48f23          	sb	a4,30(s1)
    8000638c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006390:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006394:	0727a823          	sw	s2,112(a5)
}
    80006398:	60e2                	ld	ra,24(sp)
    8000639a:	6442                	ld	s0,16(sp)
    8000639c:	64a2                	ld	s1,8(sp)
    8000639e:	6902                	ld	s2,0(sp)
    800063a0:	6105                	addi	sp,sp,32
    800063a2:	8082                	ret
    panic("could not find virtio disk");
    800063a4:	00002517          	auipc	a0,0x2
    800063a8:	42450513          	addi	a0,a0,1060 # 800087c8 <syscalls+0x328>
    800063ac:	ffffa097          	auipc	ra,0xffffa
    800063b0:	192080e7          	jalr	402(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    800063b4:	00002517          	auipc	a0,0x2
    800063b8:	43450513          	addi	a0,a0,1076 # 800087e8 <syscalls+0x348>
    800063bc:	ffffa097          	auipc	ra,0xffffa
    800063c0:	182080e7          	jalr	386(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    800063c4:	00002517          	auipc	a0,0x2
    800063c8:	44450513          	addi	a0,a0,1092 # 80008808 <syscalls+0x368>
    800063cc:	ffffa097          	auipc	ra,0xffffa
    800063d0:	172080e7          	jalr	370(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800063d4:	00002517          	auipc	a0,0x2
    800063d8:	45450513          	addi	a0,a0,1108 # 80008828 <syscalls+0x388>
    800063dc:	ffffa097          	auipc	ra,0xffffa
    800063e0:	162080e7          	jalr	354(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800063e4:	00002517          	auipc	a0,0x2
    800063e8:	46450513          	addi	a0,a0,1124 # 80008848 <syscalls+0x3a8>
    800063ec:	ffffa097          	auipc	ra,0xffffa
    800063f0:	152080e7          	jalr	338(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800063f4:	00002517          	auipc	a0,0x2
    800063f8:	47450513          	addi	a0,a0,1140 # 80008868 <syscalls+0x3c8>
    800063fc:	ffffa097          	auipc	ra,0xffffa
    80006400:	142080e7          	jalr	322(ra) # 8000053e <panic>

0000000080006404 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006404:	7119                	addi	sp,sp,-128
    80006406:	fc86                	sd	ra,120(sp)
    80006408:	f8a2                	sd	s0,112(sp)
    8000640a:	f4a6                	sd	s1,104(sp)
    8000640c:	f0ca                	sd	s2,96(sp)
    8000640e:	ecce                	sd	s3,88(sp)
    80006410:	e8d2                	sd	s4,80(sp)
    80006412:	e4d6                	sd	s5,72(sp)
    80006414:	e0da                	sd	s6,64(sp)
    80006416:	fc5e                	sd	s7,56(sp)
    80006418:	f862                	sd	s8,48(sp)
    8000641a:	f466                	sd	s9,40(sp)
    8000641c:	f06a                	sd	s10,32(sp)
    8000641e:	ec6e                	sd	s11,24(sp)
    80006420:	0100                	addi	s0,sp,128
    80006422:	8aaa                	mv	s5,a0
    80006424:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006426:	00c52d03          	lw	s10,12(a0)
    8000642a:	001d1d1b          	slliw	s10,s10,0x1
    8000642e:	1d02                	slli	s10,s10,0x20
    80006430:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006434:	0023c517          	auipc	a0,0x23c
    80006438:	d6c50513          	addi	a0,a0,-660 # 802421a0 <disk+0x128>
    8000643c:	ffffb097          	auipc	ra,0xffffb
    80006440:	91a080e7          	jalr	-1766(ra) # 80000d56 <acquire>
  for(int i = 0; i < 3; i++){
    80006444:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006446:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006448:	0023cb97          	auipc	s7,0x23c
    8000644c:	c30b8b93          	addi	s7,s7,-976 # 80242078 <disk>
  for(int i = 0; i < 3; i++){
    80006450:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006452:	0023cc97          	auipc	s9,0x23c
    80006456:	d4ec8c93          	addi	s9,s9,-690 # 802421a0 <disk+0x128>
    8000645a:	a08d                	j	800064bc <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000645c:	00fb8733          	add	a4,s7,a5
    80006460:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006464:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006466:	0207c563          	bltz	a5,80006490 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000646a:	2905                	addiw	s2,s2,1
    8000646c:	0611                	addi	a2,a2,4
    8000646e:	05690c63          	beq	s2,s6,800064c6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006472:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006474:	0023c717          	auipc	a4,0x23c
    80006478:	c0470713          	addi	a4,a4,-1020 # 80242078 <disk>
    8000647c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000647e:	01874683          	lbu	a3,24(a4)
    80006482:	fee9                	bnez	a3,8000645c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006484:	2785                	addiw	a5,a5,1
    80006486:	0705                	addi	a4,a4,1
    80006488:	fe979be3          	bne	a5,s1,8000647e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000648c:	57fd                	li	a5,-1
    8000648e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006490:	01205d63          	blez	s2,800064aa <virtio_disk_rw+0xa6>
    80006494:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006496:	000a2503          	lw	a0,0(s4)
    8000649a:	00000097          	auipc	ra,0x0
    8000649e:	cfc080e7          	jalr	-772(ra) # 80006196 <free_desc>
      for(int j = 0; j < i; j++)
    800064a2:	2d85                	addiw	s11,s11,1
    800064a4:	0a11                	addi	s4,s4,4
    800064a6:	ffb918e3          	bne	s2,s11,80006496 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064aa:	85e6                	mv	a1,s9
    800064ac:	0023c517          	auipc	a0,0x23c
    800064b0:	be450513          	addi	a0,a0,-1052 # 80242090 <disk+0x18>
    800064b4:	ffffc097          	auipc	ra,0xffffc
    800064b8:	d88080e7          	jalr	-632(ra) # 8000223c <sleep>
  for(int i = 0; i < 3; i++){
    800064bc:	f8040a13          	addi	s4,s0,-128
{
    800064c0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800064c2:	894e                	mv	s2,s3
    800064c4:	b77d                	j	80006472 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064c6:	f8042583          	lw	a1,-128(s0)
    800064ca:	00a58793          	addi	a5,a1,10
    800064ce:	0792                	slli	a5,a5,0x4

  if(write)
    800064d0:	0023c617          	auipc	a2,0x23c
    800064d4:	ba860613          	addi	a2,a2,-1112 # 80242078 <disk>
    800064d8:	00f60733          	add	a4,a2,a5
    800064dc:	018036b3          	snez	a3,s8
    800064e0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064e2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800064e6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064ea:	f6078693          	addi	a3,a5,-160
    800064ee:	6218                	ld	a4,0(a2)
    800064f0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064f2:	00878513          	addi	a0,a5,8
    800064f6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800064f8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064fa:	6208                	ld	a0,0(a2)
    800064fc:	96aa                	add	a3,a3,a0
    800064fe:	4741                	li	a4,16
    80006500:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006502:	4705                	li	a4,1
    80006504:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006508:	f8442703          	lw	a4,-124(s0)
    8000650c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006510:	0712                	slli	a4,a4,0x4
    80006512:	953a                	add	a0,a0,a4
    80006514:	058a8693          	addi	a3,s5,88
    80006518:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000651a:	6208                	ld	a0,0(a2)
    8000651c:	972a                	add	a4,a4,a0
    8000651e:	40000693          	li	a3,1024
    80006522:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006524:	001c3c13          	seqz	s8,s8
    80006528:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000652a:	001c6c13          	ori	s8,s8,1
    8000652e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006532:	f8842603          	lw	a2,-120(s0)
    80006536:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000653a:	0023c697          	auipc	a3,0x23c
    8000653e:	b3e68693          	addi	a3,a3,-1218 # 80242078 <disk>
    80006542:	00258713          	addi	a4,a1,2
    80006546:	0712                	slli	a4,a4,0x4
    80006548:	9736                	add	a4,a4,a3
    8000654a:	587d                	li	a6,-1
    8000654c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006550:	0612                	slli	a2,a2,0x4
    80006552:	9532                	add	a0,a0,a2
    80006554:	f9078793          	addi	a5,a5,-112
    80006558:	97b6                	add	a5,a5,a3
    8000655a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000655c:	629c                	ld	a5,0(a3)
    8000655e:	97b2                	add	a5,a5,a2
    80006560:	4605                	li	a2,1
    80006562:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006564:	4509                	li	a0,2
    80006566:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000656a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000656e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006572:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006576:	6698                	ld	a4,8(a3)
    80006578:	00275783          	lhu	a5,2(a4)
    8000657c:	8b9d                	andi	a5,a5,7
    8000657e:	0786                	slli	a5,a5,0x1
    80006580:	97ba                	add	a5,a5,a4
    80006582:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006586:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000658a:	6698                	ld	a4,8(a3)
    8000658c:	00275783          	lhu	a5,2(a4)
    80006590:	2785                	addiw	a5,a5,1
    80006592:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006596:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000659a:	100017b7          	lui	a5,0x10001
    8000659e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065a2:	004aa783          	lw	a5,4(s5)
    800065a6:	02c79163          	bne	a5,a2,800065c8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800065aa:	0023c917          	auipc	s2,0x23c
    800065ae:	bf690913          	addi	s2,s2,-1034 # 802421a0 <disk+0x128>
  while(b->disk == 1) {
    800065b2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065b4:	85ca                	mv	a1,s2
    800065b6:	8556                	mv	a0,s5
    800065b8:	ffffc097          	auipc	ra,0xffffc
    800065bc:	c84080e7          	jalr	-892(ra) # 8000223c <sleep>
  while(b->disk == 1) {
    800065c0:	004aa783          	lw	a5,4(s5)
    800065c4:	fe9788e3          	beq	a5,s1,800065b4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800065c8:	f8042903          	lw	s2,-128(s0)
    800065cc:	00290793          	addi	a5,s2,2
    800065d0:	00479713          	slli	a4,a5,0x4
    800065d4:	0023c797          	auipc	a5,0x23c
    800065d8:	aa478793          	addi	a5,a5,-1372 # 80242078 <disk>
    800065dc:	97ba                	add	a5,a5,a4
    800065de:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800065e2:	0023c997          	auipc	s3,0x23c
    800065e6:	a9698993          	addi	s3,s3,-1386 # 80242078 <disk>
    800065ea:	00491713          	slli	a4,s2,0x4
    800065ee:	0009b783          	ld	a5,0(s3)
    800065f2:	97ba                	add	a5,a5,a4
    800065f4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065f8:	854a                	mv	a0,s2
    800065fa:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065fe:	00000097          	auipc	ra,0x0
    80006602:	b98080e7          	jalr	-1128(ra) # 80006196 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006606:	8885                	andi	s1,s1,1
    80006608:	f0ed                	bnez	s1,800065ea <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000660a:	0023c517          	auipc	a0,0x23c
    8000660e:	b9650513          	addi	a0,a0,-1130 # 802421a0 <disk+0x128>
    80006612:	ffffa097          	auipc	ra,0xffffa
    80006616:	7f8080e7          	jalr	2040(ra) # 80000e0a <release>
}
    8000661a:	70e6                	ld	ra,120(sp)
    8000661c:	7446                	ld	s0,112(sp)
    8000661e:	74a6                	ld	s1,104(sp)
    80006620:	7906                	ld	s2,96(sp)
    80006622:	69e6                	ld	s3,88(sp)
    80006624:	6a46                	ld	s4,80(sp)
    80006626:	6aa6                	ld	s5,72(sp)
    80006628:	6b06                	ld	s6,64(sp)
    8000662a:	7be2                	ld	s7,56(sp)
    8000662c:	7c42                	ld	s8,48(sp)
    8000662e:	7ca2                	ld	s9,40(sp)
    80006630:	7d02                	ld	s10,32(sp)
    80006632:	6de2                	ld	s11,24(sp)
    80006634:	6109                	addi	sp,sp,128
    80006636:	8082                	ret

0000000080006638 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006638:	1101                	addi	sp,sp,-32
    8000663a:	ec06                	sd	ra,24(sp)
    8000663c:	e822                	sd	s0,16(sp)
    8000663e:	e426                	sd	s1,8(sp)
    80006640:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006642:	0023c497          	auipc	s1,0x23c
    80006646:	a3648493          	addi	s1,s1,-1482 # 80242078 <disk>
    8000664a:	0023c517          	auipc	a0,0x23c
    8000664e:	b5650513          	addi	a0,a0,-1194 # 802421a0 <disk+0x128>
    80006652:	ffffa097          	auipc	ra,0xffffa
    80006656:	704080e7          	jalr	1796(ra) # 80000d56 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000665a:	10001737          	lui	a4,0x10001
    8000665e:	533c                	lw	a5,96(a4)
    80006660:	8b8d                	andi	a5,a5,3
    80006662:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006664:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006668:	689c                	ld	a5,16(s1)
    8000666a:	0204d703          	lhu	a4,32(s1)
    8000666e:	0027d783          	lhu	a5,2(a5)
    80006672:	04f70863          	beq	a4,a5,800066c2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006676:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000667a:	6898                	ld	a4,16(s1)
    8000667c:	0204d783          	lhu	a5,32(s1)
    80006680:	8b9d                	andi	a5,a5,7
    80006682:	078e                	slli	a5,a5,0x3
    80006684:	97ba                	add	a5,a5,a4
    80006686:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006688:	00278713          	addi	a4,a5,2
    8000668c:	0712                	slli	a4,a4,0x4
    8000668e:	9726                	add	a4,a4,s1
    80006690:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006694:	e721                	bnez	a4,800066dc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006696:	0789                	addi	a5,a5,2
    80006698:	0792                	slli	a5,a5,0x4
    8000669a:	97a6                	add	a5,a5,s1
    8000669c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000669e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066a2:	ffffc097          	auipc	ra,0xffffc
    800066a6:	bfe080e7          	jalr	-1026(ra) # 800022a0 <wakeup>

    disk.used_idx += 1;
    800066aa:	0204d783          	lhu	a5,32(s1)
    800066ae:	2785                	addiw	a5,a5,1
    800066b0:	17c2                	slli	a5,a5,0x30
    800066b2:	93c1                	srli	a5,a5,0x30
    800066b4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066b8:	6898                	ld	a4,16(s1)
    800066ba:	00275703          	lhu	a4,2(a4)
    800066be:	faf71ce3          	bne	a4,a5,80006676 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800066c2:	0023c517          	auipc	a0,0x23c
    800066c6:	ade50513          	addi	a0,a0,-1314 # 802421a0 <disk+0x128>
    800066ca:	ffffa097          	auipc	ra,0xffffa
    800066ce:	740080e7          	jalr	1856(ra) # 80000e0a <release>
}
    800066d2:	60e2                	ld	ra,24(sp)
    800066d4:	6442                	ld	s0,16(sp)
    800066d6:	64a2                	ld	s1,8(sp)
    800066d8:	6105                	addi	sp,sp,32
    800066da:	8082                	ret
      panic("virtio_disk_intr status");
    800066dc:	00002517          	auipc	a0,0x2
    800066e0:	1a450513          	addi	a0,a0,420 # 80008880 <syscalls+0x3e0>
    800066e4:	ffffa097          	auipc	ra,0xffffa
    800066e8:	e5a080e7          	jalr	-422(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
