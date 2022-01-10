# 期末报告
## RISCV CPU 设计
### CPU 架构设计
CPU设计的第一步便是根据对应的指令集进行CPU结构的设计，本次设计中的CPU选择的指令集为RISCV指令集。并对于其中32位整数运算指令集RV32I的部分指令进行了实现。其中指令实现参考自RISCV手册。
http://riscvbook.com/RISC-V-Reader-Chinese-v2p1

对于部分error控制和流水线控制指令，例如RV32I中的fence，ecall及csr命令以及对应的csr寄存器。在本文中并未进行实现。因此，对于该CPU，部分来自编译器的中断和流水线控制等指令可能并不能被正常执行。而除去此类指令，其他的指令均在该设计中进行了实现。并且根据课程设计要求，对于RV32I指令集中的and or xor add sub andi ori xori sw lw beq jal指令进行了详细的验证过程。

CPU设计的另一步便是流水线的设计。根据设计要求，CPU需要具有五级流水线，也就是IF,ID,EX,MEM,WB的五级流水级。然而，引入流水线的代价便是流水线执行各种指令过程中存在的诸多冲突问题。

首先，我们考虑此类流水线结构对于跳转指令的处理过程。由于根据RISCV CPU的基本调度结构，其中并不存在MIPS中的指令延时槽结构，而且RV32I指令集中存在着多种多样的比较跳转指令，因此，在指令分支的过程中，必须引入气泡或者流水线停顿使得程序能够按照正确的逻辑运行。而在本设计中，对于B-type类分支跳转指令，分支预测均为不跳转，即直接将后续的指令进行发射，而当指令需要跳转时，再将已经发射但未执行完成的指令进行清除。对于直接的跳转指令jal，jalr，也将使用对应的处理方式。

引入流水线的另一个问题便是数据冲突，当数据未被写回通用寄存器时，对于该寄存器数据的读取过程将会导致错误的计算结果。常见的处理策略为引入数据前馈或者引入流水线等待过程，本设计中采用的策略为流水线等待。也就是在对应数据准备完成之前，流水线将不再发射新的指令，并使存在冲突的指令始终停留在流水线的ID级。

因此，虽然大量的流水线冲突可能会导致CPU对于指令的处理速度降低，但这种设计使得CPU能够高效解决流水线种的数据冲突问题。
### CPU 的组成结构
首先是与CPU结构相关性较低的流水线寄存器flopenrc，总线接口dualport_bus，以及通用寄存器组ram_32x32。这些部件将作为CPU中的基础组成部件。

随后，是按照不同流水级实现各级结构。分别为IF级 riscv_if，ID级 riscv_id 和通用寄存器组riscv_reg，EX级中的riscv_alu，MEM级中的寄存器总线处理模块riscv_mem。由于WB流水级中并不需要逻辑实现，只要进行部分数据选择和连接即可，因此并没有这一模块的单独实现。

最后，是跨流水级的组成结构，首先是接受各级输出结果并对于流水线的流动过程进行控制的冲突控制级riscv_hazard。而riscv_pipeline便是最终实现的完整流水线。这一模块中实例化了冲突解决模块riscv_hazard和前面的各级结构，同时为流水线中的各种传递信息提供了对应的流水线寄存器。

至此，便可以通过DMEM和IMEM来利用该CPU来进行数据处理和其他各种操作。
### CPU 各部分的详细结构及实现策略
在CPU的设计过程中，由于对CPU的组成并不熟悉，因此在本次的设计过程中，我们从CPU的核心部件ALU开始，逐步对各组成结构进行最终的实现过程。
#### EX stage
我们首先明确alu的功能，对于该alu，既需要完成五级流水线中的运算过程，同时对于流水线中的跳转指令，由于跳转指令jalr,beq等命令中均需要对PC进行处理，并将当前地址放入通用寄存器中进行缓存。而对于其他的指令，在RV32I中，所有的指令均为32位，所以pc的变化仅为加4等简单操作，这部分由IF部分一个简单的累加器进行实现。

而在pc的处理过程中，jal相比其他命令更加特殊，由于其目的地址的运算过程不需要读取通用寄存器中的数据，因此在为了减少指令跳转引起的流水线等待时间，其目的pc的计算过程被提前至ID阶段进行，这一操作可以加快CPU在处理跳转指令时的速度。

而数据运算部分的结构相对简单，即从alu输入端口i_num1,i_num2,i_imm_num中接受输入数据，并根据opcode和funct中指定的运算要求来完成进行对应的运算。因此，这一部分的实现为一简单的casex组合逻辑，并将其运算结果在o_num端口中进行输出。

很显然，上述操作均可以使用组合逻辑来完成。因此alu模块并不需要clk和rst输入。
#### ID stage
在完成EX部分的设计后，接下来需要为EX阶段所需的数据进行准备。该部分对应于ID阶段的指令处理模块以及在这一阶段中示例化的32个通用寄存器。

很显然，通用寄存器模块不能使用时序逻辑实现，因此，在对于ram_32x32基础模块进行实现时，使用的是理想的组合逻辑，即默认输入的数据可以立刻被读出。而对于这一部分中可能存在的冲突并没有进行处理。因此，这一部分的设计可能存在一定的问题。而为了将ram_32x32存储器模块与其他外部组件进行连接，我们通过riscv_reg模块来进行这一处理过程。同时，在该模块中，我们通过override避免了对于寄存器0的读写操作，使得无论任何时候对其进行读取，读到的数据永远为0。

该模块的另一个重要组成部分便是译码模块riscv_id，该模块的输入只有IF部分传递过来的32位指令。而在这一模块中，需要根据指令的类别对于其中的数据进行识别和读取，例如用于立即数运算的立即数，需要进行数据读取的寄存器地址，进行数据读取或者写入的内存地址等。同时，多个周期后的寄存器写入信号也需要由此模块产生，随后在多个周期后通过流水线寄存器再度传递到riscv_reg模块。

通过这两个组件，我们便能够为EX阶段提供数据运算的数据以及对应的控制指令。而用于跳转运算的pc值，仍需要IF阶段来提供。

#### IF stage
IF阶段为指令的发射级，同时也是整个流水线的起点。在我们的设计中，CPU在这一阶段不对当前拿到的指令进行任何的处理，因此，这一模块需要完成的任务便是根据后续产生的控制信号来指导指令的发射。

首先需要明确后续的控制信号有哪些，首先，根据前文中对于数据冲突的分析，当发生数据冲突时，CPU需要暂停发射来等待先前运算或读取结果的写回过程。因此，IF阶段必须要有一个停顿信号来阻止指令的发射过程。

而对于跳转指令，这类指令将直接改变IF阶段进行发射的指令顺序。因此，此类指令需要提供跳转的位置来控制指令的发射过程。同时，由于两种不同跳转指令（J-type，B-type）的存在，该阶段将接受两组不同的跳转地址并按照优先级进行判断。

而当该模块未接受到上述控制指令时，直接将拿到的指令发射给下一级。

#### dual_port bus
在IF阶段，便需要设计和外部连接的接口。同时，考虑到指令ROM和RAM的相似性，决定为DMEM和IMEM设计相同的接口。因此，这一接口需要满足读操作和写操作的需求。然而，由于CPU并不会使用指令bus对于指令ROM进行写入，在IMEM中，其写操作结构会始终处于关闭状态。最终设计的接口如下所示：
```
  // read interface
  logic  rd_req, rd_gnt;
  logic  [3:0]  rd_be;
  logic  [31:0] rd_addr, rd_data;
  // write interface
  logic  wr_req, wr_gnt;
  logic  [3:0]  wr_be;
  logic  [31:0] wr_addr, wr_data;
```
通过be对于读写过程中的比特位进行控制，而req和gnt则被用于确定总线的工作状态。通过该接口，便可以进行指令和内存数据的读取过程。这一结构在IF阶段和MEM阶段得到了实际的应用。

#### MEM stage
MEM阶段负责CPU和内存之间的数据交互。在这一阶段中，需要根据指令的类型进行读写过程中的比特对齐。为了满足存储器对齐的数据读取需求，进行读取的存储器地址始终保持低两位为0。而该模块将根据读取的地址来选择合适的be值来选择对应的比特位。

同样的，对于读到的数据，也要根据be值来对数据进行处理。不同的load指令的扩展方式也不尽相同，因此，这一阶段同样需要根据指令中的funct值选择不同的行为。但RISCV指令在设计的过程中便考虑到了这一因素。对于符号数和无符号数的load指令，其差距只存在于funct3值中，因此只需要将funct3沿流水线传递到这一级即可进行正确的符号扩展过程。

在总线的设计中，预留的总线信号req和gnt表示了数据的准备状态。当请求信号req=1而gnt=0时，表示对于RAM的数据请求已经发出，但并未从RAM中读取到对应的数据，因此，这时流水线必须停下来等待RAM中的数据读取，否则一个位置来源的信号将替代RAM中读到的数据被写入到寄存器组中。这一信号o_bus_stall将会由冲突解决模块进行处理，并对于所有的流水线寄存器进行控制，以实现流水线的等待过程。
#### hazard module
前述模块设计完成后，便需要依据可能存在的数据冲突来设计hazard模块。首先对于数据冲突，常见的三种数据冲突为写后写，写后读，读后写。而对于该设计中的五级流水线，由于其写入操作均在WB阶段完成，而且并未构造具有乱序发射能力的发射组件，因此只需要考虑写后读冲突即可，其它两种冲突并不会发生。

为了避免写后读冲突，在hazard模块中，需要使用组合逻辑实时对比当前正在读取的寄存器地址和尚未被写入的寄存器地址是否一致，若存在一致的情况，则需要在流水线中引入气泡，使得存在数据冲突的指令不会被推入EX阶段。同时，IF阶段的指令发射也将进入等待状态，即此时将保持pc值不发生改变，否则将导致指令读取的错误。

跳转指令的处理方式和数据冲突的处理方式存在少许的区别，由于jal类跳转指令需要到ID阶段才能够确认跳转这一指令序列变更的存在，而对于判断类指令，则需要到EX阶段才能够知道是否需要进行跳转的过程，而此时，由于IF阶段的发射仍旧在正常执行，因此可能存在被错误发射的指令，而为了解决这一问题，我们通过流水线寄存器的清除操作将其在寄存器中对应的数据直接清空，实际的效果便是该指令并未被真正的发射出去，而只是存在一个暂时性的错误pc值。

根据上述要求，我们便可以解决这一流水线中所有可能存在的冲突问题。

#### pipeline module
最终需要进行设计的部分便是CPU的主体结构——五级流水线。同时，考虑到流水线中需要和所有阶段的模块进行连接，因此选择在该模块中对先前所有的模块进行实例化。同时，也对于WB模块进行简单的实现。

我们设计的流水线寄存器的结构如下所示：
```
module flopenrc 
#(parameter WIDTH = 8) (
  input logic clk,
  input logic rst_n,
  input logic en,
  input logic clear,
  input logic [WIDTH-1:0] d,
  output logic [WIDTH-1:0] q
);

always @(posedge clk) begin
  if(~rst_n) begin
    q <= 0;
  end else if(clear) begin
    q <= 0;
  end else if(en) begin
    q <= d;
  end
end
```
使用了一个可变宽度且具有en和clear控制位的寄存器来作为本设计中使用的流水线寄存器。其中，clear控制位对应于跳转冲突中所需的数据清楚过程，而en模块则用于数据冲突中对应的流水线停顿模块。当该控制信号为0时，寄存器继续维持上一时钟周期的输出结果，而将该周期传递过来的输出结果无视掉。通过此结构，便可以实现流水线流动过程中的控制过程。

下面给出一个流水线寄存器的实现实例：

```
  flopenrc #(7) opcodeDE(clk,rst_n,stallDE,flushDE,opcodeD,opcodeE);
```

该流水线寄存器被用于在ID和EX阶段传输opcode数据，在实现过程中，使用了特殊的线网命名标记用来区分信号对应的阶段，方便后续验证过程中对于信号数据的验证和处理。

### CPU 结构总结
由于无需其他外接的组件，因此pipeline模块便是该cpu设计的顶层模块，后续验证也使用该模块作为顶层模块进行验证。以及为了能够使CPU可以正常启动执行，在代码中设定读取的第一条指令对应的pc始终为0。
## RISCV CPU 验证
该CPU的验证过程我们分为两步来完成，分别是基于testbench的初步验证和基于UVM的高覆盖率验证。

继续使用testbench来进行初步验证的原始是根据设计要求，CPU的数据端口只有两个bus接口，而使用UVM进行验证时，其内部各种调试数据的获取较为困难，很难将错误直接映射到CPU的设计问题上。而使用testbench的初步验证过程便提供了完整的调试数据，便于针对特定的设计错误进行修改。
### 基于testbench的初步验证
当前的设计只是一个独立的CPU，而负责为其提供指令和数据存储的结构并未进行设计。因此为了能够对于CPU的行为进行简单的验证过程，我们还需要为CPU准备其他的外部结构，包括指令ROM和数据RAM。
#### 额外结构设计
为了测试结构的简单，在指令ROM和数据RAM中，均没有对于总线延时这一参数进行实现。（在非测试模块中实现这一结构需要引入额外的随机结构或者只能做成固定延时设计，由于这样的结构实现起来较为复杂且存在较多的冗余代码，因此并没有在RAM结构和ROM结构中对于这一参数进行实际的实现。）
实际对于request信号和grant信号，实现的代码如下所示：
```
assign instr_slave.rd_gnt = instr_slave.rd_req;
assign instr_slave.wr_gnt = instr_slave.wr_req;
```

##### instr_rom
instruction rom用于存储即将被发射验证的指令序列，使用简单的logic变量直接设定存储器中国存储的指令序列以及指令数目，当要获取的pc指针超出指令存储的总数时，发射的指令为全0的nop指令。这保证了不会有异常指令被发射指流水线中导致无法预测的结果。
##### ram_bus
由于bit enable信号的存在，需要对于32位的数据进行截取，因此便需要一个ram_bus结构来选择合适的数据进行输出，在这一模块中，我们使用了一种取巧的做法来实例化对应的ram结构，即对于ram的每个byte实例化一个八位的ram结构，然后根据bit enable信号选择由哪些ram进行结果的输出。而CPU连接的外部ram，和CPU中的通用寄存器实现方法相类似，我们依旧使用组合逻辑对其进行实现，即假定数据输入和数据输出之间不存在延时，方便进行数据结果的验证。

#### 验证过程
由于指令序列全部储存在instr_rom中，因此tb_top模块不需要添加太多调试信息，只需要生成时钟信号并生成初始化信号即可，而在instr_rom中放置特定的指令序列，便可以进行最终的验证过程。

在初步测试中，我们手工设置了一组具有数据冲突和循环跳转的指令序列，用来确定数据冲突和跳转冲突是否可以被正确处理，对应的指令序列如下所示，由于测试结果为较难进行分析的波形图，在这里便不再进行展示。
```
  32'h00708093,   
  // addi x1,x1,7
  32'h00710113,   
  // addi x2,x2,7
  32'h00110863,
  // beq x1,x2,16
  32'h002081b3,   
  // add  x1,x2,x3
  32'h00720213,  
  // addi x4,x4,7
  32'h00728293,   
  // addi x5,x5,7
  32'h002081b3,   
  // add  x1,x2,x3
  32'h00708093,   
  // addi x1,x1,7
  32'h00710113,   
  // addi x2,x2,7
  32'h002081b3,   
  // add  x1,x2,x3
  32'h00708093,   
  // addi x1,x1,7
  32'h00000013,   
  // addi x0,x0,0 NOP
  32'h00000013,
  // addi x0,x0,0 NOP
  32'h00710113,   
  // addi x2,x2,7
  32'h002081b3,   
  // add  x1,x2,x3
  32'h00708093,  
  // addi x1,x1,7
  32'h00710113,   
  // addi x2,x2,7
  32'h002081b3,   
  // add  x1,x2,x3
  32'hff9ff06f,   
  // jal pc -8
  32'h00708093,   
  // addi x1,x1,7
  32'h00710113,   
  // addi x2,x2,7
  32'h002081b3    
  // add  x1,x2,x3
```

经过结果检测和修正，我们基本确认了CPU在上述指令条件下的运算正确性，而在检测过程中，我们也发现，为了能够对CPU进行不同指令的高覆盖率检测，必须手动生成不同的控制指令，而且这种方法也有一定的局限性。即由于指令序列的大小限制，在跳转过程中的可能的超界情况无法在测试向量中被合理的检测到。而且手工生成测试代码的过程也十分复杂，需要参考指令集一条一条的完成从二进制至16进制指令的转换过程，上述问题限制了我们使用手工测试向量进行继续检测，因此，为了达到高覆盖率的测试，我们最终选择利用UVM测试框架对于CPU运行的正确性进行适当的检测。
### 基于UVM的高覆盖率验证
在本章节中，我们对于本次测试中搭建的UVM结构进行简要的介绍，并分析各结构对应的设计思路。
#### 测试结构设计
与基于测试向量的传统测试方法不同，在UVM的测试结构中我们并未实例化指令ROM和数据RAM，而是使用随机生成的指令和数据作为替代。因此，我们可以摆脱由于指令ROM大小和RAM数据存储空间导致的测试限制。而在验证过程中，我们采用了UVM测试框架的常见结构，即在monitor部分实现一个具有理想输出的CPU，使其接收和DUT一致的输入，并在scoreboard中对于两者的结果进行对比。


##### Top
在top模块中，我们实例化了CPU的对接IMEM和DMEM的总线接口instr_vif与mem_vif。并创建了控制用总线，以便在UVM各组件中传递时钟信号等控制信号：

```

  control_if ctrl_vif();
  dualport_bus instr_vif();
  dualport_bus mem_vif();

  //Connects the Interface to the DUT
  riscv_pipeline DUT(
    .clk(ctrl_vif.clk),
    .rst_n(ctrl_vif.rst_n),
    .i_boot_addr(ctrl_vif.i_boot_addr),
    .instr_master(instr_vif.master),
    .mem_master(mem_vif.master)
  );

```
对于IMEM和DMEM，我们依旧假设是绝对理想的，即能够立即反应读写的请求
```
  assign instr_vif.rd_gnt = instr_vif.rd_req;
  assign instr_vif.wr_gnt = instr_vif.wr_req;
  assign mem_vif.rd_gnt = mem_vif.rd_req;
  assign mem_vif.wr_gnt = mem_vif.wr_req;
```

设定了初始值，并在#20的时候为DUT传递rst_n信号 
```
  initial begin
    ctrl_vif.clk <= 1'b1;
    ctrl_vif.i_boot_addr <= 32'h0000_0000;
    ctrl_vif.rst_n <= 1'b1;
    instr_vif.rd_data <= 32'h0000_0000;
  end
  initial begin
    #10;
    ctrl_vif.rst_n = 1'b0;
    #10;
    ctrl_vif.rst_n = 1'b1;
  end

  //Clock generation
  always
    #5 ctrl_vif.clk = ~ctrl_vif.clk;
```
##### Transaction
我们将transaction分为：IMEM给予CPU的一个周期的指令输入，DMEM对其提供的读入数据，CPU对下一个指令的地址输出，以及该周期下获得的DMEM总线上的输出。

对于IMEM，将指令拆成了几个可以随机的部分：指令类型instr，源寄存器地址rs1和rs2，目的寄存器地址rd，以及立即数（分为12位短立即数imm和用于超过12位部分的imm_jal)。CPU对下一个指令的地址输出是通向IMEM的rd_addr，读的地址，也即pc寄存器的值。

通过添加Constraint，可以生成多种针对性的sequence。如果想要测试高冲突，可以设置rs1，rs2，rd在一个窄范围，如[0:3]；如果想要测试读写，可以提高读写部分的指令概率；如果想要测试极限跳转和跳转后溢出，可以对imm限定一个较极限的范围。

```
typedef enum bit[3:0] {UNKNOWN_INSTR, AND, OR, XOR, ADD, SUB, ANDI, ORI, XORI, SW, LW, BEQ, JAL} instr_e;
  rand instr_e instr;
  rand bit [11:0] imm;
  rand bit [31:12] imm_jal;
  rand bit [4:0] rs1;
  rand bit [4:0] rs2;
  rand bit [4:0] rd;

  constraint my_constraint {
    instr inside {[AND: JAL]};
    imm_jal inside {[0: 9'b1_1111_1111]};
  }
```

对于DMEM，主要提供了一个32位随机数rd_data作为从某个DMEM地址上读取的数据。此外，还要观察的对DMEM的读写正确性，此处包括了DMEM总线上读写的req请求信号，读写的地址addr以及写的数据data。针对读写，分别对两个操作的输出创建了结构体。
```
typedef struct { 
  bit req;
  bit [31:0] addr;
} mem_rd_t;

typedef struct { // 
  bit req;
  bit [31:0] addr;
  bit [31:0] data;
} mem_wr_t;
```

##### Driver
在Sequence中，我们随机生成一系列的transaction，也即输入的指令与数据信息。之后，我们从uvm_driver基类派生riscv_driver类，将Driver连接到信号接口，从Sequencer上获取抽象的指令类型、寄存器地址等，将其驱动到接口并等待 DUT的回应。
具体来说，我们需要在top模块reset完成后，在每个时钟周期里，根据RISC-V的指令格式填入完整的32位指令。举例来说，对于AND指令，我们的输入便是 {7'b0000000, rv_tx.rs2, rv_tx.rs1, 3'b111, rv_tx.rd, 7'b0110011}。生成RISC-V的32位指令后，我们通过总线输入到待测CPU上。
此外，为了数据在CPU处理的上升时钟沿保持稳定，driver模块的驱动信号是在下降时钟沿进行，即提前半个周期。
需要注意的是，在面对数据冲突的时候，流水线插入了bubble，pc值不变。但是在我们的sequence中，输入指令一直被生成，但在实际的DUT中不会被读入，这一步将在Monitor被考虑。

##### Monitor

Monitor是一个独立的模型，用于观察 DUT 与测试台的通信。Monitor是无源元件，它不会将任何信号驱动到DUT中，其目的是提取信号信息并将其转换为有意义的信息，以便由其他组件进行评估。这里我们应该观察DUT的输出，并且在DUT出现不符合预测的情况下，返回有意义信息。

Monitor应涵盖：
- 用于验证功能的 DUT 输出
- 用于功能覆盖率分析的 DUT 输入

对于此验证计划，我们创建两个不同的监视器：第一个监视器monitor_before将仅获取待测CPU的输出信息，并将结果传递到Scoreboard。第二个监视器monitor_after将获取IMEM和DMEM的输入，并预测预期结果。Scoreboard将获得此预测结果，并在两个值之间进行比较。这两个Monitor均在Top模块rst_n复位完成后开始监测。

monitor_before结构较为简单，读入CPU DUT的输出保存，并写入通往其他组件（Scoreboard）的FIFO。

```
#30;
    forever begin
      @(posedge ctrl_vif.clk)
      begin
        rv_tx.pc = instr_vif.rd_addr;
        rv_tx.mem_wr.addr = mem_vif.wr_addr;
        rv_tx.mem_rd.addr = mem_vif.rd_addr;
        rv_tx.mem_wr.req = mem_vif.wr_req;
        rv_tx.mem_rd.req = mem_vif.rd_req;
        rv_tx.mem_wr.data = mem_vif.wr_data;
        //Send the transaction to the analysis port
        mon_ap_before.write(rv_tx);
      end
```

对于monitor_after，则要检测DUT的输入端，并模拟CPU的行为对输出进行预测。为了验证的准确性，我们对于数据和指令选择了不同的测试方式，对于pc指针，由于需要验证冲突解决模块的准确性，我们需要给出实时的指针数据，从而验证CPU运行过程的正确性，如果按照指令顺序输出pc值，将导致跳转预测或是数据冲突过程中，理想CPU和DUT之间的运算差距，从而导致测试的失败。

而对于数据，由于CPU需要保证指令执行的正确性，因此，在理想CPU中，我们可以直接进行指令的运算过程，并将结果传递给scoreboard。在scoreboard接收到输出结果后，并不直接进行结果正确性的验证，而是将其放置于队列中，在几个周期后来自DUT的结果完成后，从队列中将理想结果进行取出，并判断二者是否相等。可以认为，我们只在指令发射过程中检测CPU的时序特性，而在数据输出中，我们只检测结果的输出顺序以及其正确性。



##### Scoreboard

Scoreboard是自检环境中的关键元素，它可以在功能级别验证设计的正确操作。在我们的设计中，是对Monitor中的 DUT 功能进行预测，并让Scoreboard将预测与 DUT 的响应进行比较。
在Agent中，我们创建了两个monitor，因此，我们在记分板中创建两个analysis exports，用于从两个monitor回收它们写入的transaction。在这个过程中，我们有来自两个monitor的transaction流，因此需要确保它们是同步的。通过使用 UVM FIFO，可以简单做到这一点。与port/export一样，我们使用uvm_tlm_analysis_fifo #(generic_transaction)实例化FIFO，它们已经实现了从monitor调用的相应write()函数。要访问其数据，我们只需从每个FIFO执行get()方法即可。
之后，将在运行阶段run()执行一个方法compare()，并比较两个transaction中的输出信息：pc，mem_rd，mem_wr。如果它们匹配，则意味着测试平台和 DUT 在功能上都一致，并且将返回"OK"消息。
```
  task run();
    forever beging
      before_fifo.get(tx_before);
      after_fifo.get(tx_after);
      
      compare();
    end
  endtask: run
```

#### 测试中出现的问题及修正过程
##### ram时序问题
由于最初并未对RAM的特性进行分析，最早的ram实现是寄存器式的，因此其读写之间存在一个时钟周期的间隔。而显然，在五级流水线CPU中，每级流水线之间的延时仅为一个周期，如此长的时间间隔无法让CPU正常完成对通用寄存器数据的读取和写入。例如在ID阶段中，在时钟上升沿后，从流水线寄存器中接收到需要处理的指令，首先使用组合逻辑来进行指令的译码，而译码后，才能够获得该指令所需的通用寄存器地址。而这一地址所对应的数据需要在该周期的剩余时间内完成准备并传递到流水线寄存器的左端。否则EX阶段将无法读取到来自寄存器的数据。因此，使用寄存器结构实现通用寄存器要么延长指令运算的周期，要么导致最终的结果错误。

因此，最终使用组合逻辑对于内部的通用寄存器进行实现，从而解决了这一问题。读取中的组合逻辑代码如下：

```
always_comb begin
  if (~rst_n) begin
    data_ram_cell = '{default:'0};
    o_rdata1 = 31'b0;
    o_rdata2 = 31'b0;
  end else begin
    if (i_we) begin
      data_ram_cell[i_waddr] = i_wdata;
    end
    o_rdata1 = data_ram_cell[i_raddr1];
    o_rdata2 = data_ram_cell[i_raddr2];
  end
end
```

##### hazard模块的逻辑判断问题
在所有通用寄存器中，0号寄存器是最为特殊的一个，由于其中的数据永远为0且在任何状态下不会被写入，因此需要对这一寄存器进行特殊处理。即，向0号寄存器中进行写入的操作不会引发数据冲突。同时，由于在流水线寄存器中的清零操作会将流水线寄存器中的寄存器地址设置为0，因此，如果对于0号寄存器检验数据冲突，将会导致整个流水线的停摆。在CPU的初始实现过程中，便出现了流水线停摆的情况。最初的实现代码如下：
```
  end else if ((i_src1_reg_en && i_src1_reg_addr != 5'b00000) ||
               (i_src2_reg_en && i_src2_reg_addr != 5'b00000)) begin
    if ((i_dst_reg_addrE == i_src1_reg_addr) || (i_dst_reg_addrE == i_src2_reg_addr)) begin
      // do something
    end else if ((i_dst_reg_addrM == i_src1_reg_addr) || (i_dst_reg_addrM == i_src2_reg_addr)) begin
      // do something
    end else if ((i_dst_reg_addrB == i_src1_reg_addr) || (i_dst_reg_addrB == i_src2_reg_addr)) begin
      // do something
    end else begin
      // do something
    end
```

通过UVM，我们发现，对于 add sx s0 sy 的指令类型，将会引发流水线停顿的严重问题。由于sx为正常的存储器单元，因此其存在将使此if生效，而在随后的检验过程中，由于src2_reg为0号寄存器，若冲突存在，将执行冲突解决操作，使得流水线寄存器中的目的地址变为0。由此，便导致了流水线的停顿。

而最终，我们重新梳理了代码逻辑，最终得到的代码如下所示：
```
  end else if (i_src1_reg_en && i_src1_reg_addr != 5'b00000) begin
    if (i_dst_reg_enE && i_dst_reg_addrE == i_src1_reg_addr) begin
      pipeline_stall = 4'b0111;
    end else if (i_dst_reg_enM && i_dst_reg_addrM == i_src1_reg_addr) begin
      pipeline_stall = 4'b0111;
    end else if (i_dst_reg_enB && i_dst_reg_addrB == i_src1_reg_addr) begin
      pipeline_stall = 4'b0111;
    end else if (i_src2_reg_en && i_src2_reg_addr != 5'b00000) begin
      if (i_dst_reg_enE && i_dst_reg_addrE == i_src2_reg_addr) begin
        pipeline_stall = 4'b0111;
      end else if (i_dst_reg_enM && i_dst_reg_addrM == i_src2_reg_addr) begin
        pipeline_stall = 4'b0111;
      end else if (i_dst_reg_enB && i_dst_reg_addrB == i_src2_reg_addr) begin
        pipeline_stall = 4'b0111;
      end else begin
        pipeline_stall = 4'b1111;
      end
    end else begin
      pipeline_stall = 4'b1111;
    end
  end else if (i_src2_reg_en && i_src2_reg_addr != 5'b00000) begin
    if (i_dst_reg_enE && i_dst_reg_addrE == i_src2_reg_addr) begin
      pipeline_stall = 4'b0111;
    end else if (i_dst_reg_enM && i_dst_reg_addrM == i_src2_reg_addr) begin
      pipeline_stall = 4'b0111;
    end else if (i_dst_reg_enB && i_dst_reg_addrB == i_src2_reg_addr) begin
      pipeline_stall = 4'b0111;
    end else begin
      pipeline_stall = 4'b1111;
    end
```

虽然上述代码较为冗长，但避免了由于零寄存器这一特殊寄存器导致的特殊问题。

而对于向零寄存器的写入，我们并没有类似读取过程进行跳过，而是和其他指令一样使用冲突等待，在解决冲突得到运算结果后，再将计算数据废弃掉。因此，这一类指令也可以用作该cpu中的fence类指令，即在指令执行前先将可能存在的数据冲突进行解决，且不会读入可能存在的错误结果。


