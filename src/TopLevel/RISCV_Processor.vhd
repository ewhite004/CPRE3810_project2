-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- RISCV_Processor.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a skeleton of a RISCV_Processor  
-- implementation.

-- 01/29/2019 by H3::Design created.
-- 04/10/2025 by AP::Coverted to RISC-V.
-- 02/19/2026 by H3::Renamed PC and handled OVFL
-------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.RISCV_types.all;

entity RISCV_Processor is
  generic(N : integer := DATA_WIDTH);
  port(iCLK            : in std_logic;
       iRST            : in std_logic;
       iInstLd         : in std_logic;
       iInstAddr       : in std_logic_vector(N-1 downto 0);
       iInstExt        : in std_logic_vector(N-1 downto 0);
       oALUOut         : out std_logic_vector(N-1 downto 0)); -- TODO: Hook this up to the output of the ALU. It is important for synthesis that you have this output that can effectively be impacted by all other components so they are not optimized away.

end  RISCV_Processor;


architecture structure of RISCV_Processor is

  -- Required data memory signals
  signal s_DMemWr       : std_logic; -- TODO: use this signal as the final active high data memory write enable signal
  signal s_DMemAddr     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory address input
  signal s_DMemData     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input
  signal s_DMemOut      : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the data memory output
 
  -- Required register file signals 
  signal s_RegWr        : std_logic; -- TODO: use this signal as the final active high write enable input to the register file
  signal s_RegWrAddr    : std_logic_vector(4 downto 0); -- TODO: use this signal as the final destination register address input
  signal s_RegWrData    : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input
	--new regfile signals
	signal s_RegRead1,s_RegRead2:std_logic_vector(N-1 downto 0); 


  -- Required instruction memory signals
  signal s_IMemAddr     : std_logic_vector(N-1 downto 0); -- Imem in/PC out Do not assign this signal, assign to s_PC instead
  signal s_PC : std_logic_vector(N-1 downto 0); -- Pc in  TODO: use this signal as your intended final instruction memory address input.
  signal s_Inst         : std_logic_vector(N-1 downto 0); --  imem out TODO: use this signal as the instruction signal 
  --new memory signals
  signal s_PC_Increment : std_logic_vector(N-1 downto 0); -- PC+4 result of adder
  signal s_PC_Branch_sel : std_logic;
  signal s_PC_Branch_Res: std_logic_vector(N-1 downto 0):=x"00000000"; --UNIMPLEMENTED result of adder for branching intructions
  signal s_NextPC : std_logic_vector(N-1 downto 0); -- input of the PC register (PC+4 or branch target)
  signal s_DMEM_BE :std_logic_vector(4-1 downto 0);

  --new control signals
  signal s_imm_gen_res,s_ALU_B_in,s_ALU_out,s_Logical_out : std_logic_vector(N-1 downto 0);
  signal s_ALU_CONTROL_IN : std_logic_vector(4-1 downto 0);
  signal s_ALU_ZERO: std_logic;
  signal s_control_branch_EN,s_control_memRead_EN,s_control_memToReg_sel,s_control_AluSrc_sel, s_control_useImm_sel :std_logic;
  signal s_ALU_OP : std_logic_vector(2-1 downto 0); -- ALUOp from control, feeds ALUControl
  signal s_control_auipc, s_control_jal, s_control_jalr : std_logic; -- auipc / jump instruction flags from control
  signal s_branch_taken : std_logic; -- Branch AND condition, before the OR with jal
  signal s_branch_inv, s_branch_cond : std_logic; -- branch condition logic (see branch_cond below)
  signal s_NextPC_pre : std_logic_vector(N-1 downto 0); -- PC+4 / branch / jal target, before the jalr mux
  signal s_JalrTarget : std_logic_vector(N-1 downto 0); -- (rs1 + imm) with bit 0 cleared
  signal s_LoadData : std_logic_vector(N-1 downto 0); -- data memory output after byte/half select and extension
  signal s_Link : std_logic; -- jal or jalr, so rd gets PC+4
  signal s_WB_link, s_WB_auipc : std_logic_vector(N-1 downto 0); -- write back data after the link mux / after the auipc mux (feeds the useImm mux)
  signal s_PC_q, s_PC_d : std_logic_vector(N-1 downto 0); -- PC register output / input (bit 22 is stored inverted, see PC_bit22 below)

  -- Required halt signal -- for simulation
  signal s_Halt         : std_logic;  -- TODO: this signal indicates to the simulation that intended program execution has completed. (Use WFI with Opcode: 111 0011 func3: 000 and func12: 000100000101 -- func12 is imm field from I-format)

  -- Required overflow signal -- for overflow exception detection
  signal s_Ovfl         : std_logic;  -- this signal indicates an overflow exception would have been initiated

  component mem is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
          clk          : in std_logic;
          addr         : in std_logic_vector((ADDR_WIDTH-1) downto 0);
          data         : in std_logic_vector((DATA_WIDTH-1) downto 0);
          be           : in std_logic_vector (3 downto 0);   -- 4 bytes per word
          we           : in std_logic := '1';
          q            : out std_logic_vector((DATA_WIDTH -1) downto 0));
    end component;


  component Reg is
	generic(DATA_WIDTH : integer := 32);
	port(iCLK             : in std_logic;
       	iD               : in std_logic_vector(DATA_WIDTH-1 downto 0);
       	oQ               : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component;

  component adder_N is
  generic(N : integer := 16); -- Generic of type integer for input/output data width. Default value is 32.
  port(i_C          : in std_logic;
       i_A         : in std_logic_vector(N-1 downto 0);
       i_B         : in std_logic_vector(N-1 downto 0);
       o_F          : out std_logic_vector(N-1 downto 0);
	o_C : out std_logic
	);
end component;

component mux2t1_N is
  generic(N : integer := 16); -- Generic of type integer for input/output data width. Default value is 32.
  port(i_S          : in std_logic;
       i_D0         : in std_logic_vector(N-1 downto 0);
       i_D1         : in std_logic_vector(N-1 downto 0);
       o_O          : out std_logic_vector(N-1 downto 0));

end component;

component RegFile is
  port(i_CLK, RST          : in std_logic;
	i_RegWr                 : in std_logic; -- added: FIXED: regfile had no write enable
	i_WrEN_sel,i_sel_rs1,i_sel_rs2: in std_logic_vector(5-1 downto 0);
	i_DATA: in std_logic_vector(32-1 downto 0);
	o_DATA1,o_DATA2: out std_logic_vector(32-1 downto 0)
);
end component;

component control is
  port(Opcode   : in std_logic_vector(7-1 downto 0);
	auipc, jal, jalr: out std_logic; -- auipc / jump instruction flags
	ALU_Op: out std_logic_vector(2-1 downto 0); -- was: std_logic_vector(4-1 downto 0) -- FIXED: ALUControl takes a 2-bit ALUOp
       branch, MemRead, memToReg , memWrite,ALU_Src, regWrite, useImm: out std_logic
);
end component;

component imm_gen is
  port(inst_in: in std_logic_vector(32-1 downto 0);
	imm_out: out std_logic_vector(32-1 downto 0)
);
end component;

component andg2 is
  port(i_A          : in std_logic;
       i_B          : in std_logic;
       o_F          : out std_logic);
end component;

  -- added components
  component invg is
    port(
      i_A : in std_logic;
      o_F : out std_logic
    );
  end component;

  component org2 is
    port(
      i_A : in std_logic;
      i_B : in std_logic;
      o_F : out std_logic
    );
  end component;

  component xorg2 is
    port(
      i_A : in std_logic;
      i_B : in std_logic;
      o_F : out std_logic
    );
  end component;

  component load_ext is
    port(
      i_Data   : in std_logic_vector(32-1 downto 0);
      i_Addr   : in std_logic_vector(2-1 downto 0);
      i_Funct3 : in std_logic_vector(3-1 downto 0);
      o_Data   : out std_logic_vector(32-1 downto 0)
    );
  end component;

  component dffg_N is
    generic(
      N : integer := 32
    );
    port(
      i_CLK : in std_logic;
      i_RST : in std_logic;
      i_WE  : in std_logic;
      i_D   : in std_logic_vector(N-1 downto 0);
      o_Q   : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component ALUControl is
    port(
      i_ALUOp      : in std_logic_vector(1 downto 0);
      i_Funct3     : in std_logic_vector(2 downto 0);
      i_Funct7Bit  : in std_logic;
      o_ALUControl : out std_logic_vector(3 downto 0)
    );
  end component;

  component ALU is
    generic(
      N : integer := 32
    );
    port(
      i_A          : in std_logic_vector(N-1 downto 0);
      i_B          : in std_logic_vector(N-1 downto 0);
      i_ALUControl : in std_logic_vector(3 downto 0);
      o_Result     : out std_logic_vector(N-1 downto 0);
      o_Zero       : out std_logic
    );
  end component;
  
  component store_ext is
  port(
    i_Addr   : in std_logic_vector(2-1 downto 0);   -- low 2 bits of the byte address
    i_Funct3 : in std_logic_vector(3-1 downto 0);   -- load type (instruction bits 14:12)
    o_BE   : out std_logic_vector(4-1 downto 0)  -- be of DMEM
  );
end component;

  -- TODO: You may add any additional signals or components your implementation 
  --       requires below this comment

begin
  s_Ovfl <= '0'; -- RISC-V does not have hardware overflow detection.
  -- TODO: This is required to be your final input to your instruction memory. This provides a feasible method to externally load the memory module which means that the synthesis tool must assume it knows nothing about the values stored in the instruction memory. If this is not included, much, if not all of the design is optimized out because the synthesis tool will believe the memory to be all zeros.
  with iInstLd select
    s_IMemAddr <= s_PC when '0',
      iInstAddr when others;


  IMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_IMemAddr(11 downto 2),
             data => iInstExt,
             be => "1111",--hardcoded, stays
             we   => iInstLd,
             q    => s_Inst);
  
  DMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_DMemAddr(11 downto 2),
             data => s_DMemData,
             be => s_DMEM_BE,
             we   => s_DMemWr,
             q    => s_DMemOut);

  -- FIXED: the PC register had no reset (PC stayed 'U'), took s_PC as its input and drove s_IMemAddr (a second driver). It was:
  --PC_reg:Reg--PC register
  --	generic map(DATA_WIDTH =>N)
  --	port map(iCLK => iCLK,
  --       \tiD   => s_PC,
  --       \toQ   => s_IMemAddr);
  PC_reg:dffg_N--PC register (resets to 0)
	generic map(N =>N)
	port map(i_CLK => iCLK,
       	i_RST => iRST,
       	i_WE  => '1',
       	i_D   => s_PC_d, -- was: i_D   => s_NextPC, -- changed: goes through the bit 22 inverter below so the PC resets to 0x00400000
       	o_Q   => s_PC_q); -- was: o_Q   => s_PC); -- changed: s_PC is built from s_PC_q below

  PC_adder:adder_N--PC+4 incrementer
    generic map(N => N) -- Generic of type integer for input/output data width. Default value is 32.
     port map(i_C => '0',
       i_A=> s_PC, -- was: i_A=> s_IMemAddr, -- FIXED: use the PC itself (s_IMemAddr is the iInstLd mux output)
       i_B=>x"00000004",
       o_F=>s_PC_Increment
        --o_C : out std_logic
	);
  PC_Branch_adder:adder_N -- adds branch to PC instead of 4
    generic map(N => N) -- Generic of type integer for input/output data width. Default value is 32.
     port map(i_C => '0',
       i_A=> s_PC, -- was: i_A=> s_IMemAddr, -- FIXED: use the PC itself
       i_B=>s_imm_gen_res,
       o_F=>s_PC_Branch_Res
	);

  PC_branch_mux:mux2t1_N  -- select between PC+4 increment and breanch result
  generic map (N=>N) -- Generic of type integer for input/output data width. Default value is 32.
  port map(i_S => s_PC_Branch_sel,
       i_D0 => s_PC_Increment,
       i_D1 => s_PC_Branch_Res,
       o_O  => s_NextPC_pre); -- was: o_O  => s_NextPC); -- changed: the jalr mux below produces s_NextPC (earlier: was o_O => s_PC -- FIXED: mux output is the next PC, s_PC is the PC register output)

  RS2_out_mux:mux2t1_N--select between Rs2 and immidiate
  generic map (N=>N) 
  port map(i_S => s_control_AluSrc_sel,
       i_D0 => s_RegRead2,
       i_D1 => s_imm_gen_res,
       o_O  => s_ALU_B_in);

  Dmem_out_mux:mux2t1_N--select between dmem and alu result
  generic map (N=>N) -- 
  port map(i_S => s_control_memToReg_sel,
       i_D0 => s_ALU_out,
       i_D1 => s_LoadData, -- was: i_D1 => s_DMemOut, -- changed: byte/half select and extension (load_ext) for lb, lh, lbu, lhu
       o_O  => s_Logical_out); -- was: o_O  => s_PC); -- FIXED: this mux produces the register write data
  

  Registers:RegFile --register file
  port map(i_CLK=>iCLK, 
	RST=>iRST,
	i_RegWr=>s_RegWr, -- added: FIXED: regfile had no write enable
	i_WrEN_sel=>s_RegWrAddr, -- was: i_WrEN_sel=>s_Inst(11 downto 7), -- FIXED: use the required s_RegWrAddr signal (assigned below)
	i_sel_rs1=>s_Inst(19 downto 15),
	i_sel_rs2=>s_Inst(24 downto 20),
	i_DATA => s_RegWrData,
	o_DATA1=>s_RegRead1,
	o_DATA2 => s_RegRead2
  );

  andg2_branch:andg2
  port map(i_A=>s_control_branch_EN,
      	i_B=>s_branch_cond, -- was: i_B=>s_ALU_ZERO, -- changed: Zero is combined with funct3 so bne, blt, bge, bltu and bgeu work (see branch_cond below)
      	o_F=>s_branch_taken -- was: o_F=>s_PC_Branch_sel -- changed: OR with jal follows (jump_or below)
	);

  OP_control:control
  port map(Opcode=>s_Inst(6 downto 0),
	auipc=>s_control_auipc, 
	jal=>s_control_jal,
	jalr=>s_control_jalr,
	ALU_Op=>s_ALU_OP, -- was: ALU_Op=>s_ALU_CONTROL_IN, -- FIXED: goes through ALUControl, which produces s_ALU_CONTROL_IN
      	branch=>s_control_branch_EN, 
	MemRead=>s_control_memRead_EN, 
	memToReg=>s_control_memToReg_sel, 
	memWrite=>s_DMemWr,
	ALU_Src=>s_control_AluSrc_sel, 
	regWrite=>s_RegWr,
	useImm=>s_control_useImm_sel
);

immediate_generator: imm_gen
  port map(inst_in => s_Inst,
	imm_out=>s_imm_gen_res
);

use_imm_mux:mux2t1_N--select between Rs2 and immidiate
  generic map (N=>N) --
  port map(i_S => s_control_useImm_sel,
       i_D0 => s_WB_auipc, -- was: i_D0 => s_Logical_out, -- changed: link (jal/jalr) and auipc muxes follow the ALU/load mux
       i_D1 => s_imm_gen_res,
       o_O  => s_RegWrData);


  -- TODO: Ensure that s_Halt is connected to an output control signal produced from decoding the Halt instruction (Opcode: 01 0100)

  -- TODO: Implement the rest of your processor below this comment! 

  ALU_Control_Unit: ALUControl
  port map(i_ALUOp=>s_ALU_OP,
	i_Funct3=>s_Inst(14 downto 12),
	i_Funct7Bit=>s_Inst(30),
	o_ALUControl=>s_ALU_CONTROL_IN
  );

  Main_ALU: ALU
  generic map(N => N)
  port map(i_A=>s_RegRead1,
	i_B=>s_ALU_B_in,
	i_ALUControl=>s_ALU_CONTROL_IN,
	o_Result=>s_ALU_out,
	o_Zero=>s_ALU_ZERO
  );

  -- the PC resets to 0x00400000 (where RARS starts the program; auipc/jal/jalr write PC based values).
  -- dffg_N resets to all zeros, so bit 22 of the PC is stored inverted (it resets to 0, which reads as 1).
  s_PC(N-1 downto 23) <= s_PC_q(N-1 downto 23);
  s_PC(21 downto 0)   <= s_PC_q(21 downto 0);
  PC_bit22_out:invg
  port map(i_A => s_PC_q(22),
       o_F => s_PC(22));

  s_PC_d(N-1 downto 23) <= s_NextPC(N-1 downto 23);
  s_PC_d(21 downto 0)   <= s_NextPC(21 downto 0);
  PC_bit22_in:invg
  port map(i_A => s_NextPC(22),
       o_F => s_PC_d(22));

  -- branch condition, the ALU compares rs1 and rs2 (sub for beq/bne, slt for blt/bge, sltu for bltu/bgeu).
  -- beq, bge and bgeu are taken when Zero = 1; bne, blt and bltu are taken when Zero = 0.
  -- funct3(2) XOR funct3(0) is 1 for bne, blt and bltu, which flips Zero.
  branch_inv:xorg2
  port map(i_A => s_Inst(14),
       i_B => s_Inst(12),
       o_F => s_branch_inv);

  branch_cond:xorg2
  port map(i_A => s_ALU_ZERO,
       i_B => s_branch_inv,
       o_F => s_branch_cond);

  -- jal always takes the PC + imm path, so it is ORed with the branch taken signal
  jump_or:org2
  port map(i_A => s_branch_taken,
       i_B => s_control_jal,
       o_F => s_PC_Branch_sel);

  -- jalr target is (rs1 + imm) with bit 0 cleared, used instead of the PC+4 / branch / jal target
  s_JalrTarget <= s_ALU_out(N-1 downto 1) & '0';

  jalr_mux:mux2t1_N  -- select between PC+4/branch/jal and the jalr target
  generic map (N=>N)
  port map(i_S => s_control_jalr,
       i_D0 => s_NextPC_pre,
       i_D1 => s_JalrTarget,
       o_O  => s_NextPC);

  -- select the addressed byte/halfword of the loaded word and extend it (lb, lh, lbu, lhu; lw passes through)
  Load_unit:load_ext
  port map(i_Data   => s_DMemOut,
       i_Addr   => s_DMemAddr(1 downto 0),
       i_Funct3 => s_Inst(14 downto 12),
       o_Data   => s_LoadData);

  -- jal and jalr write PC+4 (the return address) to rd instead of the ALU / load result
  link_or:org2
  port map(i_A => s_control_jal,
       i_B => s_control_jalr,
       o_F => s_Link);

  Link_mux:mux2t1_N -- select between ALU/load result and PC+4
  generic map (N=>N)
  port map(i_S => s_Link,
       i_D0 => s_Logical_out,
       i_D1 => s_PC_Increment,
       o_O  => s_WB_link);

  -- auipc writes PC + imm, which the PC branch adder already computes (s_PC_Branch_Res)
  Auipc_mux:mux2t1_N  -- select between the previous write back data and PC + imm
  generic map (N=>N)
  port map(i_S => s_control_auipc,
       i_D0 => s_WB_link,
       i_D1 => s_PC_Branch_Res,
       o_O  => s_WB_auipc);
       
       --set BE of DMEM for s* commands
    store_set:store_ext
    port map(
    i_Addr  => s_DMemAddr(1 downto 0),   -- low 2 bits of the byte address
    i_Funct3 =>s_Inst(14 downto 12),  -- load type (instruction bits 14:12)
    o_BE   =>s_DMEM_BE  -- be of DMEM
  );

  -- connections for the required skeleton signals
  s_RegWrAddr <= s_Inst(11 downto 7);
  s_DMemAddr  <= s_ALU_out;
  s_DMemData  <= s_RegRead2;
  oALUOut     <= s_ALU_out;
  s_Halt      <= '1' when s_Inst = x"10500073" else '0'; -- wfi

end structure;
