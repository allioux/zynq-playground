library ieee;
  use ieee.std_logic_1164.all;

entity half_adder is
  port (
    x_in  : in    std_logic;
    y_in  : in    std_logic;
    z_out : out   std_logic;
    carry : out   std_logic
  );
end entity half_adder;

architecture behavioral of half_adder is

begin
  z_out <= x_in xor y_in;
  carry <= x_in and y_in;
end behavioral;
