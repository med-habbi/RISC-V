library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.riscvIsaPkg.all;

entity RvImmExt is
  generic ( gXlen : integer := 32 );
  port (
    iInstr   : in  std_logic_vector(gXlen-1 downto 0);
    iInstTyp : in  std_logic_vector(2 downto 0);
    oImm     : out std_logic_vector(gXlen-1 downto 0)
  );
end entity;

architecture rtl of RvImmExt is
  signal immU : unsigned(gXlen-1 downto 0);
begin
  process(iInstr, iInstTyp)
  begin
    immU <= (others => '0');

    case iInstTyp is
      when cInstTypeI | cInstTypeL =>
        immU(11 downto 0) <= unsigned(iInstr(31 downto 20));
        if iInstr(31) = '1' then immU(gXlen-1 downto 12) <= (others => '1'); end if;

      when cInstTypeS =>
        immU(4 downto 0)  <= unsigned(iInstr(11 downto 7));
        immU(11 downto 5) <= unsigned(iInstr(31 downto 25));
        if iInstr(31) = '1' then immU(gXlen-1 downto 12) <= (others => '1'); end if;

      when cInstTypeB =>
        -- B-immediate: imm[12|10:5|4:1|11|0] with imm[0]=0, sign from instr[31] [web:110]
        immU(0)           <= '0';
        immU(4 downto 1)  <= unsigned(iInstr(11 downto 8));
        immU(10 downto 5) <= unsigned(iInstr(30 downto 25));
        immU(11)          <= iInstr(7);
        immU(12)          <= iInstr(31);
        if iInstr(31) = '1' then immU(gXlen-1 downto 13) <= (others => '1'); end if;

      when cInstTypeJ =>
        -- J-immediate: imm[20|10:1|11|19:12|0] with imm[0]=0
        immU(0)            <= '0';
        immU(10 downto 1)  <= unsigned(iInstr(30 downto 21));
        immU(11)           <= iInstr(20);
        immU(19 downto 12) <= unsigned(iInstr(19 downto 12));
        immU(20)           <= iInstr(31);
        if iInstr(31) = '1' then immU(gXlen-1 downto 21) <= (others => '1'); end if;

      when cInstTypeU =>
        immU(gXlen-1 downto 12) <= unsigned(iInstr(31 downto 12));
        immU(11 downto 0)       <= (others => '0');

      when others =>
        immU <= (others => '0');
    end case;
  end process;

  oImm <= std_logic_vector(immU);
end architecture;
