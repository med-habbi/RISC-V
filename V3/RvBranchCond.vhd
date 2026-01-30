library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RvBranchCond is
  generic ( gXlen : integer := 32 );
  port (
    iRs1   : in  std_logic_vector(gXlen-1 downto 0);
    iRs2   : in  std_logic_vector(gXlen-1 downto 0);
    iFunct3: in  std_logic_vector(2 downto 0);
    oTake  : out std_logic
  );
end entity;

architecture rtl of RvBranchCond is
  signal rs1S : signed(gXlen-1 downto 0);
  signal rs2S : signed(gXlen-1 downto 0);
  signal rs1U : unsigned(gXlen-1 downto 0);
  signal rs2U : unsigned(gXlen-1 downto 0);
begin
  rs1S <= signed(iRs1);
  rs2S <= signed(iRs2);
  rs1U <= unsigned(iRs1);
  rs2U <= unsigned(iRs2);

  process(iRs1, iRs2, iFunct3, rs1S, rs2S, rs1U, rs2U)
  begin
    oTake <= '0';
    case iFunct3 is
      when "000" => if iRs1 = iRs2 then oTake <= '1'; end if; -- BEQ
      when "001" => if iRs1 /= iRs2 then oTake <= '1'; end if; -- BNE
      when "100" => if rs1S < rs2S then oTake <= '1'; end if;  -- BLT
      when "101" => if rs1S >= rs2S then oTake <= '1'; end if; -- BGE
      when "110" => if rs1U < rs2U then oTake <= '1'; end if;  -- BLTU
      when "111" => if rs1U >= rs2U then oTake <= '1'; end if; -- BGEU
      when others => oTake <= '0';
    end case;
  end process;
end architecture;
