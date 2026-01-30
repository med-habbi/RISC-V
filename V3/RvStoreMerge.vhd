library ieee;
use ieee.std_logic_1164.all;

entity RvStoreMerge is
  generic ( gXlen : integer := 32 );
  port (
    iStoreData  : in  std_logic_vector(gXlen-1 downto 0); -- rs2
    iOldWord    : in  std_logic_vector(gXlen-1 downto 0); -- memory word read
    iAddrLo     : in  std_logic_vector(1 downto 0);
    iFunct3     : in  std_logic_vector(2 downto 0);
    oWriteWord  : out std_logic_vector(gXlen-1 downto 0)
  );
end entity;

architecture rtl of RvStoreMerge is
  signal merged : std_logic_vector(31 downto 0);
begin
  process(iStoreData, iOldWord, iAddrLo, iFunct3)
  begin
    merged <= iOldWord;

    case iFunct3(1 downto 0) is
      when "00" => -- SB
        case iAddrLo is
          when "00" => merged(7 downto 0)    <= iStoreData(7 downto 0);
          when "01" => merged(15 downto 8)   <= iStoreData(7 downto 0);
          when "10" => merged(23 downto 16)  <= iStoreData(7 downto 0);
          when others => merged(31 downto 24)<= iStoreData(7 downto 0);
        end case;

      when "01" => -- SH
        if iAddrLo(1) = '0' then
          merged(15 downto 0)  <= iStoreData(15 downto 0);
        else
          merged(31 downto 16) <= iStoreData(15 downto 0);
        end if;

      when "10" => -- SW
        merged <= iStoreData;

      when others =>
        merged <= iOldWord;
    end case;

    oWriteWord <= merged;
  end process;
end architecture;