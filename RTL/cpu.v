//Module: CPU
//Function: CPU is the top design of the processor
//Inputs:
//	clk: main clock
//	arst_n: reset 
// 	enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// 	ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// 	ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory
//Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



//not sure about zero flag, 

//branch_pc and jump_pc do not need to be pipelined i think, not 100% sure

//not sure about regular branch and jump, made by controller but used by program counter, may need to be piplined unit WB 
//and than put into program counter

//rdata_ext_2_WB may need to be output instead of rdata_ext_2, not sure!

module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[31:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[31:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [31:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[31:0]  rdata_ext_2

   );

wire              zero_flag;
wire [      31:0] branch_pc,updated_pc,updated_pc_MEM,current_pc,jump_pc,
                  instruction,instruction_EX,instruction_ID,instruction_MEM;
wire [       1:0] alu_op,alu_op_EX;
wire [       3:0] alu_control;
wire              reg_dst,reg_dst_EX,branch,mem_read,mem_read_EX,mem_read_MEM,mem_2_reg,mem_2_reg_EX,mem_2_reg_MEM,mem_2_reg_WB,
                  mem_write,mem_write_EX,mem_write_MEM,alu_src,alu_src_EX, reg_write, reg_write_EX, reg_write_MEM, reg_write_WB, jump;
wire [       4:0] regfile_waddr, regfile_waddr_MEM, regfile_waddr_WB;
wire [      31:0] regfile_wdata, dram_data,dram_data_WB,alu_out_MEM,alu_out_WB alu_out,
                  regfile_data_1, regfile_data_1_EX,regfile_data_2, regfile_data_2_EX, regfile_data_2_MEM,
                  alu_operand_2, immediate_extended_EX, immediate_extended_ID, immediate_extended_MEM;

wire signed [31:0] immediate_extended;

assign immediate_extended = $signed(instruction[15:0]);


pc #(
   .DATA_W(32)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc ),
   .jump_pc   (jump_pc   ),
   .zero_flag (zero_flag ),
   .branch    (branch    ),
   .jump      (jump      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc)
);


sram #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

control_unit control_unit(
   .opcode   (instruction_ID[31:26]),
   .reg_dst  (reg_dst           ),
   .branch   (branch            ),
   .mem_read (mem_read          ),
   .mem_2_reg(mem_2_reg         ),
   .alu_op   (alu_op            ),
   .mem_write(mem_write         ),
   .alu_src  (alu_src           ),
   .reg_write(reg_write         ),
   .jump     (jump              )
);


mux_2 #(
   .DATA_W(5)
) regfile_dest_mux (
   .input_a (instruction_EX[15:11]),
   .input_b (instruction_EX[20:16]),
   .select_a(reg_dst_EX          ),
   .mux_out (regfile_waddr     )
);

register_file #(
   .DATA_W(32)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(reg_write_WB         ),
   .raddr_1  (instruction_ID[25:21]),
   .raddr_2  (instruction_ID[20:16]),
   .waddr    (regfile_waddr_WB     ),
   .wdata    (regfile_wdata     ),
   .rdata_1  (regfile_data_1    ),
   .rdata_2  (regfile_data_2    )
);


alu_control alu_ctrl(
   .function_field (instruction_EX[5:0]),
   .alu_op         (alu_op_EX          ),
   .alu_control    (alu_control     )
);

mux_2 #(
   .DATA_W(32)
) alu_operand_mux (
   .input_a (immediate_extended_EX),
   .input_b (regfile_data_2_EX    ),
   .select_a(alu_src_EX           ),
   .mux_out (alu_operand_2     )
);


alu#(
   .DATA_W(32)
) alu(
   .alu_in_0 (regfile_data_1_EX),
   .alu_in_1 (alu_operand_2 ),
   .alu_ctrl (alu_control   ),
   .alu_out  (alu_out       ),
   .shft_amnt(instruction[10:6]),
   .zero_flag(zero_flag     ),
   .overflow (              )
);

sram #(
   .ADDR_W(10),
   .DATA_W(32)
) data_memory(
   .clk      (clk           ),
   .addr     (alu_out_MEM       ),
   .wen      (mem_write_MEM     ),
   .ren      (mem_read_MEM      ),
   .wdata    (regfile_data_2_MEM ),
   .rdata    (dram_data     ),   
   .addr_ext (addr_ext_2_MEM    ),
   .wen_ext  (wen_ext_2_MEM     ),
   .ren_ext  (ren_ext_2_MEM     ),
   .wdata_ext(wdata_ext_2_MEM   ),
   .rdata_ext(rdata_ext_2   )
);



mux_2 #(
   .DATA_W(32)
) regfile_data_mux (
   .input_a  (dram_data_WB    ),
   .input_b  (alu_out_WB      ),
   .select_a (mem_2_reg_WB     ),
   .mux_out  (regfile_wdata)
);



branch_unit#(
   .DATA_W(32)
)branch_unit(
   .updated_pc   (updated_pc_MEM        ),
   .instruction  (instruction_MEM      ),
   .branch_offset(immediate_extended_MEM),
   .branch_pc    (branch_pc         ),
   .jump_pc      (jump_pc         )
);

//Instruction Pipe
reg_arstn_en #(.DATA_W(32)) updated_instuction_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (instruction),
      .en    (enable    ),
      .dout  (instruction_ID)
   );

reg_arstn_en #(.DATA_W(32)) updated_instuction_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (instruction_ID),
      .en    (enable    ),
      .dout  (instruction_EX)
   );

reg_arstn_en #(.DATA_W(32)) updated_instuction_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (instruction_EX),
      .en    (enable    ),
      .dout  (instruction_MEM)  //used by branch unit
   );

//rdata pipe

//not sure because output???

//current_pc_pipe
reg_arstn_en #(.DATA_W(32)) updated_updated_pc_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (updated_pc),
      .en    (enable    ),
      .dout  (updated_pc_ID)
   );

reg_arstn_en #(.DATA_W(32)) updated_updated_pc_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (updated_pc_ID),
      .en    (enable    ),
      .dout  (updated_pc_EX)
   );

reg_arstn_en #(.DATA_W(32)) updated_updated_pc_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (updated_pc_EX),
      .en    (enable    ),
      .dout  (updated_pc_MEM) //used by branch unit
   );

//regfile_waddr_pipe
reg_arstn_en #(.DATA_W(5)) updated_regfile_waddr_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (regfile_waddr),
      .en    (enable    ),
      .dout  (regfile_waddr_MEM) 
   );

reg_arstn_en #(.DATA_W(5)) updated_regfile_waddr_pipe_MEM_WB(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (regfile_waddr_MEM),
      .en    (enable    ),
      .dout  (regfile_waddr_WB) //used by register file
   );

//regfile_wdata_pipe (not needed)

//regfile_data_1_pipe
reg_arstn_en #(.DATA_W(32)) updated_regfile_data_1_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (regfile_data_1),
      .en    (enable    ),
      .dout  (regfile_data_1_EX) //used by alu
   );

//regfile_data_2_pipe
reg_arstn_en #(.DATA_W(32)) updated_regfile_data_2_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (regfile_data_2),
      .en    (enable    ),
      .dout  (regfile_data_2_EX) //used by alu_operand_mux
   );

reg_arstn_en #(.DATA_W(32)) updated_regfile_data_2_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (regfile_data_2_EX),
      .en    (enable    ),
      .dout  (regfile_data_2_MEM) //used by data_memory
   );

//alu_operand_2 (not needed)

//alu_control (not needed)

//immediate_extended_pipe
reg_arstn_en #(.DATA_W(32)) updated_immediate_extended_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (immediate_extended),
      .en    (enable    ),
      .dout  (immediate_extended_ID) 
   );

reg_arstn_en #(.DATA_W(32)) updated_immediate_extended_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (immediate_extended_ID),
      .en    (enable    ),
      .dout  (immediate_extended_EX) //alu_operand_mux
   );

reg_arstn_en #(.DATA_W(32)) updated_immediate_extended_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (immediate_extended_EX),
      .en    (enable    ),
      .dout  (immediate_extended_MEM) //branch_unit
   );

//Alu_src
reg_arstn_en #(.DATA_W(4)) updated_alu_src_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (alu_src),
      .en    (enable    ),
      .dout  (alu_src_EX) //alu operand mux
   );

//Alu_op
reg_arstn_en #(.DATA_W(2)) updated_alu_op_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (alu_op),
      .en    (enable    ),
      .dout  (alu_op_EX) //alu control
   );

//reg_dst
reg_arstn_en #(.DATA_W(4)) updated_reg_dst_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (reg_dst),
      .en    (enable    ),
      .dout  (reg_dst_EX) //regfile dest mux
   );


//alu_out
reg_arstn_en #(.DATA_W(32)) updated_alu_out_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (alu_out),
      .en    (enable    ),
      .dout  (alu_out_MEM) //data memory
   );

reg_arstn_en #(.DATA_W(32)) updated_alu_out_pipe_MEM_WB(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (alu_out_MEM),
      .en    (enable    ),
      .dout  (alu_out_WB) //regfile_data_mux
   );

//memwrite
reg_arstn_en #(.DATA_W(4)) updated_memwrite_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (mem_write),
      .en    (enable    ),
      .dout  (mem_write_EX) 
   );

reg_arstn_en #(.DATA_W(4)) updated_memwrite_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (mem_write_EX),
      .en    (enable    ),
      .dout  (mem_write_MEM) //Data_memory
   );

//memwread
reg_arstn_en #(.DATA_W(4)) updated_memread_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (mem_read),
      .en    (enable    ),
      .dout  (mem_read_EX) 
   );

reg_arstn_en #(.DATA_W(4)) updated_memread_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (mem_read_EX),
      .en    (enable    ),
      .dout  (mem_read_MEM) //Data_memory
   );

//addr_ext_2
reg_arstn_en #(.DATA_W(32)) updated_add_ext_2_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (addr_ext_2),
      .en    (enable    ),
      .dout  (addr_ext_2_ID) 
   );

reg_arstn_en #(.DATA_W(32)) updated_add_ext_2_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (addr_ext_2_ID),
      .en    (enable    ),
      .dout  (addr_ext_2_EX) 
   );

reg_arstn_en #(.DATA_W(32)) updated_memread_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (addr_ext_2_EX),
      .en    (enable    ),
      .dout  (addr_ext_2_MEM) //Data_memory
   );
//wen_ext_2
reg_arstn_en #(.DATA_W(32)) updated_wen_ext_2_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (wen_ext_2),
      .en    (enable    ),
      .dout  (wen_ext_2_ID) 
   );

reg_arstn_en #(.DATA_W(32)) updated_wen_ext_2_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (wen_ext_2_ID),
      .en    (enable    ),
      .dout  (wen_ext_2_EX) 
   );
reg_arstn_en #(.DATA_W(32)) updated_wen_ext_2_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (wen_ext_2_EX),
      .en    (enable    ),
      .dout  (wen_ext_2_MEM) //Data_memory
   );

//ren_ext_2
reg_arstn_en #(.DATA_W(32)) updated_ren_ext_2_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ren_ext_2),
      .en    (enable    ),
      .dout  (ren_ext_2_ID) 
   );

reg_arstn_en #(.DATA_W(32)) updated_ren_ext_2_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ren_ext_2_ID),
      .en    (enable    ),
      .dout  (ren_ext_2_EX) 
   );
reg_arstn_en #(.DATA_W(32)) updated_ren_ext_2_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ren_ext_2_EX),
      .en    (enable    ),
      .dout  (ren_ext_2_MEM) //Data_memory
   );

//wdata_ext_2
reg_arstn_en #(.DATA_W(32)) updated_wdata_ext_2_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (wdata_ext_2),
      .en    (enable    ),
      .dout  (wdata_ext_2_ID) 
   );

reg_arstn_en #(.DATA_W(32)) updated_wdata_ext_2_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (wdata_ext_2_ID),
      .en    (enable    ),
      .dout  (wdata_ext_2_EX) 
   );
reg_arstn_en #(.DATA_W(32)) updated_wdata_ext_2_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (wdata_ext_2_EX),
      .en    (enable    ),
      .dout  (wdata_ext_2_MEM) //Data_memory
   );

//dram_data
reg_arstn_en #(.DATA_W(32)) updated_dram_data_pipe_MEM_WB(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (dram_data),
      .en    (enable    ),
      .dout  (dram_data_WB) //regfile_data_mux
   );


//Rdata_ext_2
reg_arstn_en #(.DATA_W(32)) updated_rdata_ext_2_pipe_MEM_WB(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (rdata_ext_2),
      .en    (enable    ),
      .dout  (rdata_ext_2_WB) //used as output???
   );

//mem_2_reg
reg_arstn_en #(.DATA_W(4)) updated_mem_2_reg_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (mem_2_reg),
      .en    (enable    ),
      .dout  (mem_2_reg_EX) 
   );

reg_arstn_en #(.DATA_W(4)) updated_mem_2_reg_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (mem_2_reg_EX),
      .en    (enable    ),
      .dout  (mem_2_reg_MEM) 
   );

reg_arstn_en #(.DATA_W(4)) updated_mem_2_reg_pipe_MEM_WB(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (mem_2_reg_MEM),
      .en    (enable    ),
      .dout  (mem_2_reg_WB) //regfiledatamux
   );

//regwrite
reg_arstn_en #(.DATA_W(4)) updated_reg_write_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (reg_write),
      .en    (enable    ),
      .dout  (reg_write_EX) 
   );

reg_arstn_en #(.DATA_W(4)) updated_reg_write_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (reg_write_EX),
      .en    (enable    ),
      .dout  (reg_write_MEM) 
   );

reg_arstn_en #(.DATA_W(4)) updated_reg_write_pipe_MEM_WB(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (reg_write_MEM),
      .en    (enable    ),
      .dout  (reg_write_WB) //regfiledatamux
   );



endmodule


