library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RvCpuTop is
  generic (
    gXlen      : integer := 32;
    gAddrWidth : integer := 32;
    gDepth     : integer := 100;
    gProgFile  : string  := "add_r.hex"
  );
  port (
    iClk : in std_logic;
    iRst : in std_logic
  );
end entity;

architecture rtl of RvCpuTop is
  constant cAluOpW : integer := 5;

  -- Instruction path
  signal instrFromRom : std_logic_vector(gXlen-1 downto 0);
  signal instrQ       : std_logic_vector(gXlen-1 downto 0);

  -- PC
  signal pcQ, pcPlus4 : std_logic_vector(gAddrWidth-1 downto 0);

  -- Regfile
  signal rs1Data, rs2Data : std_logic_vector(gXlen-1 downto 0);

  -- Immediate
  signal immVal : std_logic_vector(gXlen-1 downto 0);

  -- ALU
  signal aluA, aluB, aluY : std_logic_vector(gXlen-1 downto 0);

  -- Mem
  signal dmemWordIdx : std_logic_vector(gAddrWidth-1 downto 0);
  signal dmemRdWord  : std_logic_vector(gXlen-1 downto 0);
  signal dmemWrWord  : std_logic_vector(gXlen-1 downto 0);
  signal addrLo      : std_logic_vector(1 downto 0);

  -- Load
  signal loadData : std_logic_vector(gXlen-1 downto 0);

  -- WB
  signal wbData : std_logic_vector(gXlen-1 downto 0);

  -- Branch cond
  signal branchTake : std_logic;

  -- Control
  signal irEn, pcEn : std_logic;
  signal aluOp      : std_logic_vector(cAluOpW-1 downto 0);
  signal instType   : std_logic_vector(2 downto 0);
  signal loadFunct3 : std_logic_vector(2 downto 0);
  signal storeFunct3: std_logic_vector(2 downto 0);
  signal useImmB    : std_logic;
  signal regWriteEn : std_logic;
  signal memWriteEn : std_logic;
  signal wbSel      : std_logic_vector(1 downto 0);
  signal pcLoad     : std_logic;
  signal aluASel    : std_logic_vector(1 downto 0);
  signal brFunct3   : std_logic_vector(2 downto 0);

  -- Aliases for fields in latched instruction
  alias rs1 : std_logic_vector(4 downto 0) is instrQ(19 downto 15);
  alias rs2 : std_logic_vector(4 downto 0) is instrQ(24 downto 20);
  alias rd  : std_logic_vector(4 downto 0) is instrQ(11 downto 7);

  constant cZero : std_logic_vector(gXlen-1 downto 0) := (others => '0');

  -- Word index for instruction memory: PC >> 2
  signal pcWordIdx : std_logic_vector(gAddrWidth-1 downto 0);
begin
  pcWordIdx <= (others => '0') when gAddrWidth < 3 else ("00" & pcQ(gAddrWidth-1 downto 2));

  -- PC counter: next PC always comes from ALU output in this micro-arch
  uPc: entity work.RvPcCounter
    generic map ( gAddrWidth => gAddrWidth )
    port map (
      iNextPc   => aluY,
      iClk      => iClk,
      iRst      => iRst,
      iLoad     => pcLoad,
      iPcEnable => pcEn,
      oPc       => pcQ,
      oPcPlus4  => pcPlus4
    );

  -- IMEM: word-indexed ROM loaded from gProgFile
  uImem: entity work.RvImemFileRom
    generic map (
      gXlen      => gXlen,
      gAddrWidth => gAddrWidth,
      gDepth     => gDepth,
      gInitFile  => gProgFile
    )
    port map (
      iClk      => iClk,
      iWordAddr => pcWordIdx,
      oInstr    => instrFromRom
    );

  -- Instruction register (latched only in fetch)
  uIr: entity work.instrReg
    generic map ( gDataWidth => gXlen )
    port map (
      iClk    => iClk,
      iRst    => iRst,
      iEnable => irEn,
      iData   => instrFromRom,
      oData   => instrQ
    );

  -- Controller/decoder
  uCtrl: entity work.RvCtrlFsmDec
    generic map (
      gXlen       => gXlen,
      gAluOpWidth => cAluOpW
    )
    port map (
      iClk         => iClk,
      iRst         => iRst,
      iInstr       => instrQ,
      iBranchTake  => branchTake,
      oIrEn        => irEn,
      oPcEn        => pcEn,
      oAluOp       => aluOp,
      oInstType    => instType,
      oLoadFunct3  => loadFunct3,
      oStoreFunct3 => storeFunct3,
      oUseImmB     => useImmB,
      oRegWrite    => regWriteEn,
      oMemWrite    => memWriteEn,
      oWbSel       => wbSel,
      oPcLoad      => pcLoad,
      oAluASel     => aluASel,
      oBranchFunct3=> brFunct3
    );

  -- Immediate generator
  uImm: entity work.RvImmExt
    generic map ( gXlen => gXlen )
    port map (
      iInstr   => instrQ,
      iInstTyp => instType,
      oImm     => immVal
    );

  -- Regfile
  uRf: entity work.RvRegFile
    generic map ( gXlen => gXlen )
    port map (
      iRa  => rs1,
      iRb  => rs2,
      iRw  => rd,
      iWd  => wbData,
      oA   => rs1Data,
      oB   => rs2Data,
      iWe  => regWriteEn,
      iClk => iClk,
      iRst => iRst
    );

  -- Branch condition comparator uses funct3 directly
  uBr: entity work.RvBranchCond
    generic map ( gXlen => gXlen )
    port map (
      iRs1    => rs1Data,
      iRs2    => rs2Data,
      iFunct3 => brFunct3,
      oTake   => branchTake
    );

  -- ALU operand A mux (rs1 / pc / zero)
  uOpa: entity work.muxOpa
    generic map ( gDataWidth => gXlen )
    port map (
      iRs1  => rs1Data,
      iPc   => pcQ,
      iZero => cZero,
      iSel  => aluASel,
      oOut  => aluA
    );

  -- ALU operand B mux (rs2 / imm)
  uOpb: entity work.mux2to1
    generic map ( gDataWidth => gXlen )
    port map (
      iIn0 => rs2Data,
      iIn1 => immVal,
      iSel => useImmB,
      oOut => aluB
    );

  -- ALU
  uAlu: entity work.RvAluCore
    generic map (
      gXlen       => gXlen,
      gAluOpWidth => cAluOpW
    )
    port map (
      iA     => aluA,
      iB     => aluB,
      iAluOp => aluOp,
      oY     => aluY
    );

  -- Data memory addressing
  dmemWordIdx <= "00" & aluY(gAddrWidth-1 downto 2);  -- word index
  addrLo      <= aluY(1 downto 0);

  uDmem: entity work.RvDataRam
    generic map (
      gXlen      => gXlen,
      gAddrWidth => gAddrWidth,
      gDepth     => gDepth
    )
    port map (
      iWordAddr  => dmemWordIdx,
      iWriteData => dmemWrWord,
      iWe        => memWriteEn,
      iClk       => iClk,
      oReadData  => dmemRdWord
    );

  -- Store merge + load align
  uStore: entity work.RvStoreMerge
    generic map ( gXlen => gXlen )
    port map (
      iStoreData => rs2Data,
      iOldWord   => dmemRdWord,
      iAddrLo    => addrLo,
      iFunct3    => storeFunct3,
      oWriteWord => dmemWrWord
    );

  uLoad: entity work.RvLoadAlign
    generic map ( gXlen => gXlen )
    port map (
      iWord     => dmemRdWord,
      iAddrLo   => addrLo,
      iFunct3   => loadFunct3,
      oLoadData => loadData
    );

  -- Writeback mux: ALU / MEM / PC+4
  uWb: entity work.muxWb
    generic map ( gDataWidth => gXlen )
    port map (
      iAlu => aluY,
      iMem => loadData,
      iPc4 => pcPlus4,
      iSel => wbSel,
      oOut => wbData
    );
end architecture;
