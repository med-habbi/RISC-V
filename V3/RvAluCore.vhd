library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RvAluCore is
  generic (
    gXlen       : integer := 32;
    gAluOpWidth : integer := 5
  );
  port (
    iA      : in  std_logic_vector(gXlen-1 downto 0);
    iB      : in  std_logic_vector(gXlen-1 downto 0);
    iAluOp  : in  std_logic_vector(gAluOpWidth-1 downto 0);
    oY      : out std_logic_vector(gXlen-1 downto 0)
  );
end entity;

architecture rtl of RvAluCore is
  function shamtWidth(xlen : integer) return integer is
    variable w : integer := 0;
    variable v : integer := xlen-1;
  begin
    while v > 0 loop
      w := w + 1;
      v := v / 2;
    end loop;
    if w < 1 then w := 1; end if;
    return w;
  end function;

  constant cShW : integer := shamtWidth(gXlen);
  signal aluSel : std_logic_vector(3 downto 0);
  signal shamt  : natural;
begin
  aluSel <= iAluOp(3 downto 0);
  shamt  <= to_integer(unsigned(iB(cShW-1 downto 0)));

  process(iA, iB, aluSel, shamt)
    variable ltSigned   : std_logic;
    variable ltUnsigned : std_logic;
  begin
    oY <= (others => '0');

    case aluSel is
      when "0000" => -- ADD
        oY <= std_logic_vector(signed(iA) + signed(iB));

      when "1000" => -- SUB
        oY <= std_logic_vector(signed(iA) - signed(iB));

      when "0001" => -- SLL
        oY <= std_logic_vector(shift_left(unsigned(iA), shamt));

      when "0010" => -- SLT (signed)
        if signed(iA) < signed(iB) then ltSigned := '1'; else ltSigned := '0'; end if;
        oY <= (gXlen-1 downto 1 => '0') & ltSigned;

      when "0011" => -- SLTU (unsigned)
        if unsigned(iA) < unsigned(iB) then ltUnsigned := '1'; else ltUnsigned := '0'; end if;
        oY <= (gXlen-1 downto 1 => '0') & ltUnsigned;

      when "0100" => -- XOR
        oY <= iA xor iB;

      when "0101" => -- SRL (logical)
        oY <= std_logic_vector(shift_right(unsigned(iA), shamt));

      when "1101" => -- SRA (arithmetic)
        oY <= std_logic_vector(shift_right(signed(iA), shamt)); -- sign-extended by numeric_std [web:21][web:106]

      when "0110" => -- OR
        oY <= iA or iB;

      when "0111" => -- AND
        oY <= iA and iB;

      when others =>
        oY <= (others => '0');
    end case;
  end process;
end architecture;
