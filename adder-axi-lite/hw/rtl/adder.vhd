
library ieee;
  use ieee.std_logic_1164.all;

entity adder is
  generic (
    width : positive
  );
  port (
    x_in  : in    std_logic_vector(width - 1 downto 0);
    y_in  : in    std_logic_vector(width - 1 downto 0);
    z_out : out   std_logic_vector(width - 1 downto 0)
  );
end entity adder;

architecture behavioral of adder is
  signal carry : std_logic_vector(width downto 0);

begin
  carry(0) <= '0';

  gen_adders : for i in 0 to width - 1 generate
  begin

    fa_i : entity work.full_adder(behavioral)

      port map (
        x_in      => x_in(i),
        y_in      => y_in(i),
        carry_in  => carry(i),
        z_out     => z_out(i),
        carry_out => carry(i + 1)
      );

  end generate gen_adders;

end behavioral;
