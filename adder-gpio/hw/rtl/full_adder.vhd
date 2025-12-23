library ieee;
  use ieee.std_logic_1164.all;

entity full_adder is
  port (
    x_in      : in    std_logic;
    y_in      : in    std_logic;
    carry_in  : in    std_logic;
    z_out     : out   std_logic;
    carry_out : out   std_logic
  );
end entity full_adder;

architecture behavioral of full_adder is
  signal xy_s     : std_logic;
  signal carry1_s : std_logic;
  signal carry2_s : std_logic;

begin

  ha1_u : entity work.half_adder(behavioral)

    port map (
      x_in  => x_in,
      y_in  => y_in,
      carry => carry1_s,
      z_out => xy_s
    );

  ha2_u : entity work.half_adder
    port map (
      x_in  => xy_s,
      y_in  => carry_in,
      carry => carry2_s,
      z_out => z_out
    );

  carry_out <= carry1_s or carry2_s;
end behavioral;
