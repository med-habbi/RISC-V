library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RISCV_Top_RILS is
    port(
        clk   : in std_logic;
        reset : in std_logic
    );
end RISCV_Top_RILS;

architecture Behavioral of RISCV_Top_RILS is

    --------------------------------------------------------------------
    -- Déclaration des composants
    --------------------------------------------------------------------
    component PC is
        port(
            clk   : in  std_logic;
            reset : in  std_logic;
            load  : in  std_logic;
            din   : in  std_logic_vector(31 downto 0);
            dout  : out std_logic_vector(31 downto 0)
        );
    end component;

    component imem is
        generic (
            DATA_WIDTH : natural := 32;
            ADDR_WIDTH : natural := 8;
            MEM_DEPTH  : natural := 200;
            INIT_FILE  : string := "C:/Users/mhabb/Desktop/S9/dscp/Habbi/program_RILS.hex"
        );
        port(
            addr : in  std_logic_vector(31 downto 0);
            inst : out std_logic_vector(31 downto 0)
        );
    end component;

    component dmem is
        generic (
            DATA_WIDTH : natural := 32;
            ADDR_WIDTH : natural := 8;
            MEM_DEPTH  : natural := 200;
            INIT_FILE  : string := ""
        );
        port (
            addr    : in  std_logic_vector(31 downto 0);
            din     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            dout    : out std_logic_vector(DATA_WIDTH-1 downto 0);
            WE      : in  std_logic;
            clk     : in  std_logic
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
            memWE       : out std_logic
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

    component SM is
        port(
            data   : in  std_logic_vector(31 downto 0);  -- rs2
            q      : in  std_logic_vector(31 downto 0);  -- mot actuel DMEM
            funct3 : in  std_logic_vector(2 downto 0);   -- sb/sh/sw
            addrLSB: in  std_logic_vector(1 downto 0);   -- bits bas adresse
            dataOut: out std_logic_vector(31 downto 0)   -- mot modifié
        );
    end component;

    --------------------------------------------------------------------
    -- Signaux internes
    --------------------------------------------------------------------
    signal pc_out       : std_logic_vector(31 downto 0);
    signal pc_in        : std_logic_vector(31 downto 0);
    signal instr        : std_logic_vector(31 downto 0);

    signal BusA         : std_logic_vector(31 downto 0);
    signal BusB         : std_logic_vector(31 downto 0);

    signal imm_extended : std_logic_vector(31 downto 0);
    signal opB_ALU      : std_logic_vector(31 downto 0);

    signal BusW         : std_logic_vector(31 downto 0);  -- writeback final
    signal BusW_alu     : std_logic_vector(31 downto 0);  -- résultat ALU

    signal aluOp        : std_logic_vector(3 downto 0);
    signal WE           : std_logic;
    signal load         : std_logic;
    signal RIsel        : std_logic;
    signal instType     : std_logic_vector(1 downto 0);
    signal loadAcc      : std_logic;
    signal memWE        : std_logic;

    signal data_dmem    : std_logic_vector(31 downto 0);  -- sortie DMEM
    signal data_dmem_in : std_logic_vector(31 downto 0);  -- entrée DMEM

    alias rs1    : std_logic_vector(4 downto 0) is instr(19 downto 15);
    alias rs2    : std_logic_vector(4 downto 0) is instr(24 downto 20);
    alias rd     : std_logic_vector(4 downto 0) is instr(11 downto 7);
    alias funct3 : std_logic_vector(2 downto 0) is instr(14 downto 12);

begin

    --------------------------------------------------------------------
    -- Program Counter
    --------------------------------------------------------------------
    PC_inst : PC port map(
        clk   => clk,
        reset => reset,
        load  => load,
        din   => pc_in,
        dout  => pc_out
    );

    -- Ici on n’implémente pas les branches, donc pc_in constant
    pc_in <= (others => '0');

    --------------------------------------------------------------------
    -- Instruction Memory
    --------------------------------------------------------------------
    IMEM_inst : imem
        generic map(
            DATA_WIDTH => 32,
            ADDR_WIDTH => 8,
            MEM_DEPTH  => 200,
            INIT_FILE  => "C:/Users/mhabb/Desktop/S9/dscp/Habbi/program_RILS.hex"
        )
        port map(
            addr => pc_out,
            inst => instr
        );

    --------------------------------------------------------------------
    -- Register File
    --------------------------------------------------------------------
    RegFile_inst : RegisterFile port map(
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
    -- Controler
    --------------------------------------------------------------------
    Controler_inst : controler port map(
        instr       => instr,
        clk         => clk,
        aluOp       => aluOp,
        WriteEnable => WE,
        load        => load,
        RIsel       => RIsel,
        instType    => instType,
        loadAcc     => loadAcc,
        memWE       => memWE
    );

    --------------------------------------------------------------------
    -- Immédiats
    --------------------------------------------------------------------
    ImmExt_inst : ImmExt port map(
        instr    => instr,
        instType => instType,
        immExt   => imm_extended
    );

    --------------------------------------------------------------------
    -- Sélection de l’opérande B de l’ALU (registre ou immédiat)
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
    ALU_inst : ALU port map(
        opA   => BusA,
        opB   => opB_ALU,
        aluOp => aluOp,
        res   => BusW_alu
    );

    --------------------------------------------------------------------
    -- Data Memory
    --------------------------------------------------------------------
    DMEM_inst : dmem
        generic map(
            DATA_WIDTH => 32,
            ADDR_WIDTH => 8,
            MEM_DEPTH  => 200,
            INIT_FILE  => ""
        )
        port map(
            addr => BusW_alu,      -- adresse calculée (rs1 + imm)
            din  => data_dmem_in,  -- mot préparé par SM
            dout => data_dmem,
            WE   => memWE,
            clk  => clk
        );

    --------------------------------------------------------------------
    -- Store Manager (SM) pour sb/sh/sw
    --------------------------------------------------------------------
    SM_inst : SM
        port map(
            data    => BusB,                     -- valeur à stocker (rs2)
            q       => data_dmem,                -- mot courant en mémoire
            funct3  => funct3,                   -- sb/sh/sw
            addrLSB => BusW_alu(1 downto 0),     -- position dans le mot
            dataOut => data_dmem_in              -- mot modifié à écrire
        );

    --------------------------------------------------------------------
    -- Mux de writeback : ALU ou DMEM (lw)
    --------------------------------------------------------------------
    Mux_wb : Mux2to1
        generic map(DATA_WIDTH => 32)
        port map(
            in0    => BusW_alu,   -- résultat ALU (R, I, S adresse)
            in1    => data_dmem,  -- donnée chargée (lw)
            sel    => loadAcc,    -- 1 : lw, 0 : résultat ALU
            output => BusW
        );

end Behavioral;
