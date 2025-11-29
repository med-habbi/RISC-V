library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controler is 
    port(
        instr       : in  std_logic_vector(31 downto 0);
        clk         : in  std_logic;
        reset       : in  std_logic;               -- <<< IMPORTANT
        res_lsb     : in  std_logic_vector(1 downto 0);  -- <<< IMPORTANT

        aluOp       : out std_logic_vector(3 downto 0);
        WriteEnable : out std_logic;
        load        : out std_logic;
        RIsel       : out std_logic;
        instType    : out std_logic_vector(1 downto 0);
        loadAcc     : out std_logic;
        wrMem       : out std_logic_vector(3 downto 0)
    );
end controler;


architecture Behavioral of controler is

    alias opcode : std_logic_vector(6 downto 0) is instr(6 downto 0);
    alias funct3 : std_logic_vector(2 downto 0) is instr(14 downto 12);
    alias funct7 : std_logic_vector(6 downto 0) is instr(31 downto 25);

    constant ALU_ADD  : std_logic_vector(3 downto 0) := "0000";
    constant ALU_SUB  : std_logic_vector(3 downto 0) := "0001";
    constant ALU_SLL  : std_logic_vector(3 downto 0) := "0010";
    constant ALU_SLT  : std_logic_vector(3 downto 0) := "0011";
    constant ALU_SLTU : std_logic_vector(3 downto 0) := "0100";
    constant ALU_XOR  : std_logic_vector(3 downto 0) := "0101";
    constant ALU_SRL  : std_logic_vector(3 downto 0) := "0110";
    constant ALU_SRA  : std_logic_vector(3 downto 0) := "0111";
    constant ALU_OR   : std_logic_vector(3 downto 0) := "1000";
    constant ALU_AND  : std_logic_vector(3 downto 0) := "1001";

begin

    process(instr, opcode, funct3, funct7, res_lsb, reset)
    begin
        if reset = '1' then
            -- Tout à zéro pendant le reset
            aluOp       <= ALU_ADD;
            WriteEnable <= '0';
            load        <= '0';
            RIsel       <= '0';
            instType    <= "00";
            loadAcc     <= '0';
            wrMem       <= "0000";

        else
            -- valeurs par défaut (aucune écriture)
            aluOp       <= ALU_ADD;
            WriteEnable <= '0';
            load        <= '0';
            RIsel       <= '0';
            instType    <= "00";
            loadAcc     <= '0';
            wrMem       <= "0000";

            ----------------------------------------------------------------
            -- Type R : opcode = 0110011
            ----------------------------------------------------------------
            if opcode = "0110011" then
                WriteEnable <= '1';        -- écriture registre
                RIsel       <= '0';
                instType    <= "00";
                loadAcc     <= '0';
                wrMem       <= "0000";     -- pas d'écriture mémoire

                case funct3 is
                    when "000" =>
                        if funct7 = "0000000" then
                            aluOp <= ALU_ADD;
                        elsif funct7 = "0100000" then
                            aluOp <= ALU_SUB;
                        end if;
                    when "001" => aluOp <= ALU_SLL;
                    when "010" => aluOp <= ALU_SLT;
                    when "011" => aluOp <= ALU_SLTU;
                    when "100" => aluOp <= ALU_XOR;
                    when "101" =>
                        if funct7 = "0000000" then
                            aluOp <= ALU_SRL;
                        elsif funct7 = "0100000" then
                            aluOp <= ALU_SRA;
                        end if;
                    when "110" => aluOp <= ALU_OR;
                    when "111" => aluOp <= ALU_AND;
                    when others => null;
                end case;

            ----------------------------------------------------------------
            -- Type I arith/logic : opcode = 0010011
            ----------------------------------------------------------------
            elsif opcode = "0010011" then
                WriteEnable <= '1';
                RIsel       <= '1';
                instType    <= "01";       -- immédiat I
                loadAcc     <= '0';
                wrMem       <= "0000";

                case funct3 is
                    when "000" => aluOp <= ALU_ADD;   -- ADDI
                    when "010" => aluOp <= ALU_SLT;   -- SLTI
                    when "011" => aluOp <= ALU_SLTU;  -- SLTIU
                    when "100" => aluOp <= ALU_XOR;   -- XORI
                    when "110" => aluOp <= ALU_OR;    -- ORI
                    when "111" => aluOp <= ALU_AND;   -- ANDI
                    when "001" => aluOp <= ALU_SLL;   -- SLLI
                    when "101" =>
                        if funct7 = "0000000" then
                            aluOp <= ALU_SRL;         -- SRLI
                        elsif funct7 = "0100000" then
                            aluOp <= ALU_SRA;         -- SRAI
                        end if;
                    when others => null;
                end case;

            ----------------------------------------------------------------
            -- Type I load : opcode = 0000011  (lw)
            ----------------------------------------------------------------
            elsif opcode = "0000011" then
                -- lw rd, imm(rs1)
                WriteEnable <= '1';        -- écriture registre rd
                RIsel       <= '1';        -- opB = imm
                instType    <= "01";       -- format I
                loadAcc     <= '1';        -- writeback depuis DM
                wrMem       <= "0000";     -- pas d'écriture mémoire
                aluOp       <= ALU_ADD;    -- adresse = rs1 + imm

            ----------------------------------------------------------------
            -- Type S : stores (sb, sh, sw), opcode = 0100011
            ----------------------------------------------------------------
            elsif opcode = "0100011" then
                -- sb/sh/sw rs2, imm(rs1)
                WriteEnable <= '0';        -- pas d'écriture registre
                RIsel       <= '1';        -- adresse = rs1 + imm
                instType    <= "10";       -- format S
                loadAcc     <= '0';
                aluOp       <= ALU_ADD;

                -- génération de wrMem selon funct3 (sb/sh/sw) ET res_lsb (= adr[1:0])
                case funct3 is

                    --------------------------------------------------------
                    -- sb : un seul octet, sélectionné avec res_lsb
                    --------------------------------------------------------
                    when "000" =>  -- sb
                        case res_lsb is
                            when "00" => wrMem <= "0001";  -- byte 0 (addr+0)
                            when "01" => wrMem <= "0010";  -- byte 1 (addr+1)
                            when "10" => wrMem <= "0100";  -- byte 2 (addr+2)
                            when others => wrMem <= "1000";-- byte 3 (addr+3)
                        end case;

                    --------------------------------------------------------
                    -- sh : 16 bits, 2 octets consécutifs
                    --  adr[1:0] = 00 -> bytes 0 et 1
                    --  adr[1:0] = 10 -> bytes 2 et 3
                    --------------------------------------------------------
                    when "001" =>  -- sh
                        if res_lsb(1) = '0' then
                            wrMem <= "0011";          -- octets 0 et 1
                        else
                            wrMem <= "1100";          -- octets 2 et 3
                        end if;

                    --------------------------------------------------------
                    -- sw : 32 bits, 4 octets
                    --------------------------------------------------------
                    when "010" =>  -- sw
                        wrMem <= "1111";

                    when others =>
                        wrMem <= "0000";
                end case;

            end if;
        end if;
    end process;

end Behavioral;
