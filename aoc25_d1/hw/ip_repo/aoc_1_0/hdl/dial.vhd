library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity dial is
  port (
    clk       : in    std_logic;
    rst       : in    std_logic;
    start     : in    std_logic;
    size      : in    std_logic_vector(31 downto 0);
    bram_dout : in    std_logic_vector(31 downto 0);
    done_o    : out   std_logic;
    part1_o   : out   std_logic_vector(31 downto 0);
    part2_o   : out   std_logic_vector(31 downto 0);
    bram_en   : out   std_logic;
    bram_addr : out   std_logic_vector(31 downto 0);
    bram_we   : out   std_logic_vector(3 downto 0)
  );
end entity dial;

architecture behavioral of dial is

  type state_t is (idle, wait_data, processing, done);

  signal state     : state_t;
  signal idx       : natural;
  signal next_addr : unsigned(31 downto 0);
  signal position  : signed(31 downto 0);
  signal part1     : unsigned(31 downto 0);
  signal part2     : unsigned(31 downto 0);

begin

  proc_a : process (clk) is

    variable new_position  : signed(31 downto 0);
    variable zeros_crossed : signed(31 downto 0);

  begin

    if rising_edge(clk) then
      state     <= state;
      idx       <= idx;
      next_addr <= next_addr;
      position  <= position;
      part1     <= part1;
      part2     <= part2;

      if (rst = '1') then
        state <= idle;
      else

        case state is

          when idle =>

            idx       <= 0;
            next_addr <= to_unsigned(4, 32);
            position  <= to_signed(50, 32);
            part1     <= (others => '0');
            part2     <= (others => '0');
            bram_we   <= (others => '0');
            bram_addr <= (others => '0');
            bram_en   <= '0';

            if (start = '1') then
              done_o  <= '0';
              bram_en <= '1';
              state   <= wait_data;
            end if;

          -- Wait one clock cycle before reading bram_dout
          when wait_data =>

            bram_addr <= std_logic_vector(next_addr);
            next_addr <= next_addr + 4;
            state     <= processing;

          when processing =>

            if (idx >= unsigned(size)) then
              state <= done;
            else
              new_position  := (position + signed(bram_dout)) mod 100;
              zeros_crossed := abs((position + signed(bram_dout)) / 100);

              bram_addr <= std_logic_vector(next_addr);
              bram_en   <= '1';
              idx       <= idx + 1;
              next_addr <= next_addr + 4;
              position  <= new_position;

              if (new_position = 0) then
                part1 <= part1  + 1;
              end if;

              if (position > 0 and position + signed(bram_dout) <= to_signed(0, 32)) then
                part2 <= part2 + unsigned(zeros_crossed) + 1;
              else
                part2 <= part2 + unsigned(zeros_crossed);
              end if;
            end if;

          when done =>

            part1_o <= std_logic_vector(part1);
            part2_o <= std_logic_vector(part2);
            bram_en <= '0';
            done_o  <= '1';
            state   <= idle;

        end case;

      end if;
    end if;

  end process proc_a;

end architecture behavioral;
