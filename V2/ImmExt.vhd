library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ImmExt is
    port(
        instr    : in  std_logic_vector(31 downto 0);
        instType : in  std_logic_vector(1 downto 0);  -- "00":R, "01":I/L, "10":S
        immExt   : out std_logic_vector(31 downto 0)
    );
end ImmExt;

architecture Behavioral of ImmExt is
    signal imm_I : std_logic_vector(11 downto 0);
    signal imm_S : std_logic_vector(11 downto 0);
begin
    -- I-type : bits 31..20
    imm_I <= instr(31 downto 20);

    -- S-type : imm[11:5]=31..25, imm[4:0]=11..7
    imm_S <= instr(31 downto 25) & instr(11 downto 7);

    process(instType, imm_I, imm_S)
    begin
        case instType is
            when "01" =>  -- Type I / load
                if imm_I(11) = '1' then
                    immExt <= (31 downto 12 => '1') & imm_I;
                else
                    immExt <= (31 downto 12 => '0') & imm_I;
                end if;

            when "10" =>  -- Type S (store)
                if imm_S(11) = '1' then
                    immExt <= (31 downto 12 => '1') & imm_S;
                else
                    immExt <= (31 downto 12 => '0') & imm_S;
                end if;

            when others =>  -- R-type ou par défaut
                immExt <= (others => '0');
        end case;
    end process;
end Behavioral;
