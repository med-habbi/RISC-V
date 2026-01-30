library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.riscvIsaPkg.all;

entity RvCtrlFsmDec is
  generic (
    gXlen      : integer := 32;
    gAluOpWidth: integer := 5
  );
  port (
    iClk        : in  std_logic;
    iRst        : in  std_logic;

    iInstr      : in  std_logic_vector(gXlen-1 downto 0);
    iBranchTake : in  std_logic;

    oIrEn       : out std_logic;
    oPcEn       : out std_logic;

    oAluOp      : out std_logic_vector(gAluOpWidth-1 downto 0);
    oInstType   : out std_logic_vector(2 downto 0);
    oLoadFunct3 : out std_logic_vector(2 downto 0);
    oStoreFunct3: out std_logic_vector(2 downto 0);

    oUseImmB    : out std_logic;                 -- selects ALU B: 0=rs2, 1=imm
    oRegWrite   : out std_logic;
    oMemWrite   : out std_logic;

    oWbSel      : out std_logic_vector(1 downto 0); -- 00=ALU, 01=MEM, 10=PC+4
    oPcLoad     : out std_logic;                 -- load PC with ALU result
    oAluASel    : out std_logic_vector(1 downto 0); -- 00=rs1, 01=pc, 10=zero (LUI)
    oBranchFunct3 : out std_logic_vector(2 downto 0)
  );
end entity;

architecture rtl of RvCtrlFsmDec is
  type state_t is (sFetch, sDecode, sExecute, sMem, sWb);
  signal st : state_t;

  alias opcode   : std_logic_vector(6 downto 0) is iInstr(6 downto 0);
  alias funct3   : std_logic_vector(2 downto 0) is iInstr(14 downto 12);
  alias funct7b5 : std_logic is iInstr(30);

  signal instTypeL : std_logic_vector(2 downto 0);

  signal regWriteReq : std_logic;
  signal memWriteReq : std_logic;
  signal pcLoadReq   : std_logic;
begin
  -- FSM sequencing (same as your original)
  process(iClk, iRst)
  begin
    if iRst = '1' then
      st <= sFetch;
    elsif rising_edge(iClk) then
      case st is
        when sFetch   => st <= sDecode;
        when sDecode  => st <= sExecute;
        when sExecute => st <= sMem;
        when sMem     => st <= sWb;
        when sWb      => st <= sFetch;
      end case;
    end if;
  end process;

  -- Instruction type decode
  process(opcode)
  begin
    case opcode is
      when cOpcodeRType  => instTypeL <= cInstTypeR;
      when cOpcodeIType  => instTypeL <= cInstTypeI;
      when cOpcodeLType  => instTypeL <= cInstTypeL;
      when cOpcodeSType  => instTypeL <= cInstTypeS;
      when cOpcodeBType  => instTypeL <= cInstTypeB;
      when cOpcodeJType1 => instTypeL <= cInstTypeJ; -- JAL
      when cOpcodeJType2 => instTypeL <= cInstTypeI; -- JALR treated like I-type immediate
      when cOpcodeUType1 => instTypeL <= cInstTypeU; -- LUI
      when cOpcodeUType2 => instTypeL <= cInstTypeU; -- AUIPC
      when others        => instTypeL <= cInstTypeUnknown;
    end case;
  end process;
  oInstType <= instTypeL;

  -- ALU op encoding (kept compatible with your ALU op mapping)
  process(instTypeL, funct3, funct7b5, opcode)
  begin
    oAluOp <= (others => '0');

    if instTypeL = cInstTypeR then
      oAluOp <= '0' & funct7b5 & funct3;
    elsif instTypeL = cInstTypeI and opcode /= cOpcodeJType2 then
      if funct3 = "101" then
        oAluOp <= '0' & funct7b5 & funct3; -- SRLI/SRAI
      else
        oAluOp <= "00" & funct3;           -- ADDI/SLTI/...
      end if;
    end if;
  end process;

  oBranchFunct3 <= funct3;

  -- “Raw” control intent (independent of timing state)
  process(instTypeL, funct3, opcode, iBranchTake)
  begin
    regWriteReq  <= '0';
    memWriteReq  <= '0';
    pcLoadReq    <= '0';

    oUseImmB     <= '0';
    oAluASel     <= "00";
    oWbSel       <= "00";

    oLoadFunct3  <= "010";
    oStoreFunct3 <= "010";

    case instTypeL is
      when cInstTypeR =>
        regWriteReq <= '1';
        oUseImmB    <= '0';
        oWbSel      <= "00";

      when cInstTypeI =>
        regWriteReq <= '1';
        oUseImmB    <= '1';
        oWbSel      <= "00";
        if opcode = cOpcodeJType2 then
          -- JALR: rd=pc+4, pc=rs1+imm (ALU A must be rs1)
          pcLoadReq <= '1';
          oAluASel  <= "00";
          oWbSel    <= "10";
        end if;

      when cInstTypeL =>
        regWriteReq <= '1';
        oUseImmB    <= '1';
        oWbSel      <= "01";
        oLoadFunct3 <= funct3;

      when cInstTypeS =>
        memWriteReq  <= '1';
        oUseImmB     <= '1';
        oStoreFunct3 <= funct3;

      when cInstTypeB =>
        oUseImmB  <= '1';
        oAluASel  <= "01";       -- ALU A = PC so target = PC + imm [web:114]
        pcLoadReq <= iBranchTake;

      when cInstTypeJ =>
        regWriteReq <= '1';
        oUseImmB    <= '1';
        oAluASel    <= "01";     -- ALU A = PC so target = PC + imm [web:113]
        pcLoadReq   <= '1';
        oWbSel      <= "10";     -- rd = PC+4 [web:113]

      when cInstTypeU =>
        regWriteReq <= '1';
        oUseImmB    <= '1';
        if opcode = cOpcodeUType1 then
          -- LUI: result = imm (ALU A=0, B=imm) [web:63]
          oAluASel <= "10";
        else
          -- AUIPC: result = PC + imm (ALU A=PC, B=imm) [web:63]
          oAluASel <= "01";
        end if;
        oWbSel <= "00";

      when others =>
        null;
    end case;
  end process;

  -- Timed outputs by state (Fetch/Decode/Execute/Mem/WB)
  process(st, regWriteReq, memWriteReq, pcLoadReq)
  begin
    oIrEn     <= '0';
    oPcEn     <= '0';
    oRegWrite <= '0';
    oMemWrite <= '0';
    oPcLoad   <= '0';

    case st is
      when sFetch =>
        oIrEn <= '1';
        oPcEn <= '0';

      when sDecode =>
        null;

      when sExecute =>
        oPcLoad <= '0';

      when sMem =>
        oMemWrite <= memWriteReq;

      when sWb =>
        oRegWrite <= regWriteReq;
        if pcLoadReq = '1' then
          oPcLoad <= '1';
          oPcEn   <= '0';
        else
          oPcLoad <= '0';
          oPcEn   <= '1';
        end if;
    end case;
  end process;
end architecture;
