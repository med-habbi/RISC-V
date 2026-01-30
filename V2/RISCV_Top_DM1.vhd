library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RISCV_Top_DM1 is
  port(
    clk   : in std_logic;
    reset : in std_logic
  );
end RISCV_Top_DM1;

architecture Behavioral of RISCV_Top_DM1 is

  --------------------------------------------------------------------
  -- Composants
  --------------------------------------------------------------------
  component PC is
    port(
      clk    : in  std_logic;
      reset  : in  std_logic;
      enable : in  std_logic; -- NOUVEAU
      load   : in  std_logic;
      din    : in  std_logic_vector(31 downto 0);
      dout   : out std_logic_vector(31 downto 0)
    );
  end component;

  component imem is
    generic (
      DATA_WIDTH : natural := 32;
      ADDR_WIDTH : natural := 8;
      MEM_DEPTH  : natural := 200;
      INIT_FILE  : string := "C:/Users/mhabb/Desktop/S9/dscp/Habbi/program_DM1.hex"
    );
    port(
      clk  : in  std_logic; -- NOUVEAU
      addr : in  std_logic_vector(31 downto 0);
      inst : out std_logic_vector(31 downto 0)
    );
  end component;

  component RegistreInstruction is
    port(
      clk    : in  std_logic;
      reset  : in  std_logic;
      enable : in  std_logic;
      din    : in  std_logic_vector(31 downto 0);
      dout   : out std_logic_vector(31 downto 0)
    );
  end component;

  component controller_fsm_5 is
    port(
      clk       : in  std_logic;
      reset     : in  std_logic;
      pcenable  : out std_logic;
      rienable  : out std_logic;
      state_dbg : out std_logic_vector(2 downto 0)
    );
  end component;

  component DM is
    generic (
      ADDR_WIDTH : natural := 8;
      MEM_DEPTH  : natural := 256
    );
    port (
      addr  : in  std_logic_vector(31 downto 0);
      data  : in  std_logic_vector(31 downto 0);
      q     : out std_logic_vector(31 downto 0);
      wrMem : in  std_logic_vector(3 downto 0);
      clk   : in  std_logic
    );
  end component;

  component RegisterFile is
    port(
      clk   : in  std_logic;
      reset : in  std_logic;
      WE    : in  std_logic;
      RA    : in  std_logic_vector(4 downto 0);
      RB    : in  std_logic_vector(4 downto 0);
      RW    : in  std_logic_vector(4 downto 0);
      BusW  : in  std_logic_vector(31 downto 0);
      BusA  : out std_logic_vector(31 downto 0);
      BusB  : out std_logic_vector(31 downto 0)
    );
  end component;

  component controler is
    port(
      instr       : in  std_logic_vector(31 downto 0);
      clk         : in  std_logic;
      aluOp       : out std_logic_vector(3 downto 0);
      WriteEnable : out std_logic;
      load        : out std_logic;
      RIsel       : out std_logic;
      instType    : out std_logic_vector(1 downto 0);
      loadAcc     : out std_logic;
      wrMem       : out std_logic_vector(3 downto 0);
      reset       : in  std_logic;
      res_lsb     : in  std_logic_vector(1 downto 0)
    );
  end component;

  component ALU is
    port(
      opA   : in  std_logic_vector(31 downto 0);
      opB   : in  std_logic_vector(31 downto 0);
      aluOp : in  std_logic_vector(3 downto 0);
      res   : out std_logic_vector(31 downto 0)
    );
  end component;

  component ImmExt is
    port(
      instr    : in  std_logic_vector(31 downto 0);
      instType : in  std_logic_vector(1 downto 0);
      immExt   : out std_logic_vector(31 downto 0)
    );
  end component;

  component Mux2to1 is
    generic(DATA_WIDTH : natural := 32);
    port(
      in0    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      in1    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      sel    : in  std_logic;
      output : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  --------------------------------------------------------------------
  -- Signaux
  --------------------------------------------------------------------
  signal pc_out   : std_logic_vector(31 downto 0);
  signal pc_in    : std_logic_vector(31 downto 0);

  signal instr_imem : std_logic_vector(31 downto 0);
  signal instr_reg  : std_logic_vector(31 downto 0);

  signal pcenable  : std_logic;
  signal rienable  : std_logic;
  signal state_dbg : std_logic_vector(2 downto 0);

  signal BusA      : std_logic_vector(31 downto 0);
  signal BusB      : std_logic_vector(31 downto 0);

  signal imm_extended : std_logic_vector(31 downto 0);
  signal opB_ALU      : std_logic_vector(31 downto 0);

  signal BusW      : std_logic_vector(31 downto 0);
  signal BusW_alu  : std_logic_vector(31 downto 0);

  -- sorties "brutes" du decodeur (ton controler actuel)
  signal aluOp_d    : std_logic_vector(3 downto 0);
  signal WE_d       : std_logic;
  signal load_d     : std_logic;
  signal RIsel_d    : std_logic;
  signal instType_d : std_logic_vector(1 downto 0);
  signal loadAcc_d  : std_logic;
  signal wrMem_d    : std_logic_vector(3 downto 0);

  -- signaux réellement appliqués (gated)
  signal aluOp    : std_logic_vector(3 downto 0);
  signal WE       : std_logic;
  signal load     : std_logic;
  signal RIsel    : std_logic;
  signal instType : std_logic_vector(1 downto 0);
  signal loadAcc  : std_logic;
  signal wrMem    : std_logic_vector(3 downto 0);

  signal data_dmem : std_logic_vector(31 downto 0);

  alias rs1 : std_logic_vector(4 downto 0) is instr_reg(19 downto 15);
  alias rs2 : std_logic_vector(4 downto 0) is instr_reg(24 downto 20);
  alias rd  : std_logic_vector(4 downto 0) is instr_reg(11 downto 7);

begin

  -- Pas encore de branches dans ton squelette -> PC+4 interne, din inutilisé
  pc_in <= (others => '0');

  --------------------------------------------------------------------
  -- FSM 5 états
  --------------------------------------------------------------------
  FSM_inst : controller_fsm_5
    port map(
      clk       => clk,
      reset     => reset,
      pcenable  => pcenable,
      rienable  => rienable,
      state_dbg => state_dbg
    );

  --------------------------------------------------------------------
  -- PC avec enable
  --------------------------------------------------------------------
  PC_inst : PC
    port map(
      clk    => clk,
      reset  => reset,
      enable => pcenable,
      load   => load,     -- pour l'instant on le force à 0 plus bas
      din    => pc_in,
      dout   => pc_out
    );

  --------------------------------------------------------------------
  -- IMEM synchrone + registre d'instruction
  --------------------------------------------------------------------
  IMEM_inst : imem
    generic map(
      DATA_WIDTH => 32,
      ADDR_WIDTH => 8,
      MEM_DEPTH  => 200,
      INIT_FILE  => "C:/Users/mhabb/Desktop/S9/dscp/Habbi/program_DM1.hex"
    )
    port map(
      clk  => clk,
      addr => pc_out,
      inst => instr_imem
    );

  IR_inst : RegistreInstruction
    port map(
      clk    => clk,
      reset  => reset,
      enable => rienable,
      din    => instr_imem,
      dout   => instr_reg
    );

  --------------------------------------------------------------------
  -- Register File
  --------------------------------------------------------------------
  RegFile_inst : RegisterFile
    port map(
      clk   => clk,
      reset => reset,
      WE    => WE,
      RA    => rs1,
      RB    => rs2,
      RW    => rd,
      BusW  => BusW,
      BusA  => BusA,
      BusB  => BusB
    );

  --------------------------------------------------------------------
  -- Controler existant (décodeur)
  --------------------------------------------------------------------
  Controler_inst : controler
    port map(
      instr       => instr_reg,
      clk         => clk,
      reset       => reset,
      res_lsb     => BusW_alu(1 downto 0),
      aluOp       => aluOp_d,
      WriteEnable => WE_d,
      load        => load_d,
      RIsel       => RIsel_d,
      instType    => instType_d,
      loadAcc     => loadAcc_d,
      wrMem       => wrMem_d
    );

  --------------------------------------------------------------------
  -- Gating minimal multi-cycle (Memory / WriteBack)
  --------------------------------------------------------------------
  aluOp    <= aluOp_d;
  RIsel    <= RIsel_d;
  instType <= instType_d;

  -- Memory seulement en état MEMORY = "011"
  wrMem <= wrMem_d when state_dbg = "011" else "0000";

  -- WriteBack seulement en état WRITEBACK = "100"
  WE <= WE_d when state_dbg = "100" else '0';

  -- Sélection writeback seulement en WB (sinon BusW prend ALU)
  loadAcc <= loadAcc_d when state_dbg = "100" else '0';

  -- Pas de branches/jumps dans ce squelette -> on empêche load
  load <= '0';

  --------------------------------------------------------------------
  -- ImmExt
  --------------------------------------------------------------------
  ImmExt_inst : ImmExt
    port map(
      instr    => instr_reg,
      instType => instType,
      immExt   => imm_extended
    );

  --------------------------------------------------------------------
  -- Mux vers ALU (BusB ou immédiat)
  --------------------------------------------------------------------
  Mux_aluB : Mux2to1
    generic map(DATA_WIDTH => 32)
    port map(
      in0    => BusB,
      in1    => imm_extended,
      sel    => RIsel,
      output => opB_ALU
    );

  --------------------------------------------------------------------
  -- ALU
  --------------------------------------------------------------------
  ALU_inst : ALU
    port map(
      opA   => BusA,
      opB   => opB_ALU,
      aluOp => aluOp,
      res   => BusW_alu
    );

  --------------------------------------------------------------------
  -- Data Memory
  --------------------------------------------------------------------
  DM_inst : DM
    generic map(
      ADDR_WIDTH => 8,
      MEM_DEPTH  => 256
    )
    port map(
      addr  => BusW_alu,
      data  => BusB,
      q     => data_dmem,
      wrMem => wrMem,
      clk   => clk
    );

  --------------------------------------------------------------------
  -- Writeback
  --------------------------------------------------------------------
  Mux_wb : Mux2to1
    generic map(DATA_WIDTH => 32)
    port map(
      in0    => BusW_alu,
      in1    => data_dmem,
      sel    => loadAcc,
      output => BusW
    );

end Behavioral;
