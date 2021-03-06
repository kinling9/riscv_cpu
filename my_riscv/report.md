### Initial design for EX
1. 对于一个riscv处理器设计，首先设计其使用的alu，首先明确alu的功能，对于该alu，既需要完成五级流水线中的运算过程，同时对于流水线中的跳转指令，由于跳转指令jal,jalr,beq等命令中均需要对PC进行处理，而对于其他的指令，在本设计中，所有的指令均为32位，所以pc的变化仅为加4等简单操作，这部分由ID部分一个简单的加法器进行实现。
> 对于riscv处理器，其数据存储方式为小端序，也就是高位会放在后面，对于uj格式的跳转指令jal，其30-12位实现了1-29位跳转offset的立即数的存储而立即数的第20位被存储在第31位上，参考图像为J格式指令的分划。
2. 考虑输入内容，输入内容可以分为需要进行运算的数据和控制运算种类的控制指令，运算数据较为简单，对于寄存器间的运算（包括比较运算），所需要的运算数据位通用寄存器组的对应数据，即rs1,rs2。而对于立即数运算，需要接收经过符号扩展的立即数。而对于跳转指令，则需要获得当前的pc指针。因此需要支持的主要输入数据便是上述部分。而控制指令，根据RISCV中一般的定义规则，对于R-type指令，控制指令最多，分别为opcode的7位以及12-14位的funct3以及25-31位的funct7，我们选择将这些控制指令全部输入进去，用于实现最终alu运算过程的控制。
3. 对于输出部分，首先是分支指令的跳转与否，随后是ALU的结果输出，为了将跳转指令与运算指令分开，我们为PC指针和ALU结果设置不同的输出端口。
4. 流水线的清空部分暂未进行设计，可能会使用local的rst操作来实现？该部分等到最终的五级流水线搭建完成后进行统一的测试过程

### Else design for EX
1. 对于ALU，其仅完成计算的过程，对于进位的部分并未进行运算，然而查阅部分资料，发现对于RISCV CPU，进位溢出是由软件进行检测的，因此在ALU设计的过程中无需考虑。
2. 对于J指令，由于jal，jalr均需要将跳转前的PC+4储存在寄存器rd中，该部分的输出将使用ALU的主output主输出o_num进行输出
3. 对于比较指令，由于需要同时支持有符号数和无符号数的比较过程，尝试使用verilog中定义的\$signed函数，暂不清楚该写法是否可以综合 *FIXME*
> 12/16 update fixed
4. 对于load，store指令，由于其只需要完成取数的操作过程，因此可能不需要在ALU中实现 *FIXME*
5. 对于shamt，即进行数据移位过程中的移位数，暂时决定使用immi中的数据进行数据的输入（该设计的依据是，该指令类型为I型，只是拥有与R型类似的funct7）
6. 使用verilog内建的算术右移指令实现自动的补零操作 *Need simple test* *FIXED*

### IF design
1. 对于该阶段，需要从一个非常大的内存中取获取接下来应当执行的指令，一般来说，该部分内容存储在外部设备中，CPU通过总线和外部进行交流，同时，通过总线的实现方式降低了测试的复杂度，即在测试过程中，CPU不需要对于DMEM和IMEM进行实时的放置过程，也方便了测试部件的实现。
2. *Not yet* 在测试过程中，计划采取随机的指令生成和固定随机内存的结构进行测试，为了降低测试的复杂程度，测试过程中仅对于DMEM中的数据和IMEM中获取的指针值（针对跳转指令？）进行测试，即CPU不会为测试结构准备太多的接口
3. *Not yet* 另一种测试思路是对于regfile，实例化一个外部监视模块用来实时获取数据，即实现一个含有实时输出内部所有数据的模块，然而由于数据冒险的存在，部分数据无法实时获取，相关predict模块编写较为困难
4. 总线设计，由于该CPU设计并没有多核部分，因此并不需要总线仲裁模块，只需要实现简单的总线用来连接CPU和指令内存和数据内存，同时由于主从关系固定，因此只需实现同一套接口即可，为了拓展使用范围，设置不同的工作模式
5. 指令发射部分时序可能存在问题，需要进一步查看 *FIXME*
6. 针对数据冲突问题，采取的方法为延时发射，由外接的hazard模块对于指令发射过程进行控制，通过判断后续ID，EX，MEM，WB阶段的写入地址和当前的读取地址是否一致来决定是否发射，如果发现数据冲突，则不进行发射（作为替代，发射16'b0），同时，对于x0的读写，由于不产生实际的数据变化可以直接跳过。*Not yet*

### MEM design
1. 针对流水线暂停的情况，例如总线等待，该部分需要给出停止信号使得流水线暂停，否则会产生数据丢失的问题，所有阶段在接收到该信号后进入数据保持阶段同时不将数据后推。*Not yet* 该部分的实现可能需要在外部连接的模块中进行连接和验证
2. 可能的思路，当出现此类暂停时，所有的流水线寄存器拒绝数据更新，而是保存原数据，同时IF阶段继续发射上一条指令（IF阶段前不存在流水线寄存器，因此需要自行进行处理，否则会导致指令丢失）