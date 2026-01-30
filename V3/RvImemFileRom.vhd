library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity RvImemFileRom is
  generic (
    gXlen      : integer := 32;
    gAddrWidth : integer := 32;
    gDepth     : integer := 100;
    gInitFile  : string  := "add_r.hex"
  );
  port (
    iClk      : in  std_logic;
    iWordAddr : in  std_logic_vector(gAddrWidth-1 downto 0); -- word index
    oInstr    : out std_logic_vector(gXlen-1 downto 0)
  );
end entity;

architecture rtl of RvImemFileRom is
  type mem_t is array (0 to gDepth-1) of std_logic_vector(gXlen-1 downto 0);

  function hexCharToNibble(c : character) return std_logic_vector is
  begin
    case c is
      when '0' => return "0000";
      when '1' => return "0001";
      when '2' => return "0010";
      when '3' => return "0011";
      when '4' => return "0100";
      when '5' => return "0101";
      when '6' => return "0110";
      when '7' => return "0111";
      when '8' => return "1000";
      when '9' => return "1001";
      when 'A' | 'a' => return "1010";
      when 'B' | 'b' => return "1011";
      when 'C' | 'c' => return "1100";
      when 'D' | 'd' => return "1101";
      when 'E' | 'e' => return "1110";
      when 'F' | 'f' => return "1111";
      when others => return "0000";
    end case;
  end function;

  impure function initMem(filename : string) return mem_t is
    file f : text open read_mode is filename;
    variable l : line;
    variable s : string(1 to 8);
    variable ok : boolean;
    variable tmp : mem_t := (others => (others => '0'));
  begin
    for i in 0 to gDepth-1 loop
      exit when endfile(f);
      readline(f, l);
      read(l, s, ok);
      if ok then
        for j in 1 to 8 loop
          tmp(i)((32 - (j-1)*4 - 1) downto (32 - j*4)) := hexCharToNibble(s(j));
        end loop;
      end if;
    end loop;
    return tmp;
  end function;

  signal rom : mem_t := initMem(gInitFile);
begin
  process(iClk)
    variable idx : integer;
  begin
    if rising_edge(iClk) then
      idx := to_integer(unsigned(iWordAddr));
      if idx >= 0 and idx < gDepth then
        oInstr <= rom(idx);
      else
        oInstr <= (others => '0');
      end if;
    end if;
  end process;
end architecture;
