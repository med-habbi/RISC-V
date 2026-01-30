library ieee;
use ieee.std_logic_1164.all;

package riscvIsaPkg is
  -- Opcodes (RV32I base)
  constant cOpcodeRType : std_logic_vector(6 downto 0) := "0110011";
  constant cOpcodeIType : std_logic_vector(6 downto 0) := "0010011";
  constant cOpcodeSType : std_logic_vector(6 downto 0) := "0100011";
  constant cOpcodeBType : std_logic_vector(6 downto 0) := "1100011";
  constant cOpcodeUType1 : std_logic_vector(6 downto 0) := "0110111"; -- LUI
  constant cOpcodeUType2 : std_logic_vector(6 downto 0) := "0010111"; -- AUIPC
  constant cOpcodeJType1 : std_logic_vector(6 downto 0) := "1101111"; -- JAL
  constant cOpcodeJType2 : std_logic_vector(6 downto 0) := "1100111"; -- JALR
  constant cOpcodeLType : std_logic_vector(6 downto 0) := "0000011";

  -- Internal instruction-type encoding (your control classification)
  constant cInstTypeR : std_logic_vector(2 downto 0) := "000";
  constant cInstTypeI : std_logic_vector(2 downto 0) := "001";
  constant cInstTypeS : std_logic_vector(2 downto 0) := "010";
  constant cInstTypeB : std_logic_vector(2 downto 0) := "011";
  constant cInstTypeU : std_logic_vector(2 downto 0) := "100";
  constant cInstTypeJ : std_logic_vector(2 downto 0) := "101";
  constant cInstTypeL : std_logic_vector(2 downto 0) := "110";
  constant cInstTypeUnknown : std_logic_vector(2 downto 0) := "111";
end package;
