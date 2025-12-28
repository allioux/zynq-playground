library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity slice is
  generic (
    width : natural := 32;
    msb   : natural := 0;
    lsb   : natural := 0
  );
  port (
    din  : in    std_logic_vector(width - 1 downto 0);
    dout : out   std_logic_vector(msb - lsb downto 0)
  );
end entity slice;

architecture behavioral of slice is

begin
  dout <= din(msb downto lsb);
end behavioral;
