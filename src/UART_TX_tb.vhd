library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TX_tb is
end UART_TX_tb;

architecture sim of UART_TX_tb is

    constant clk_hz : integer := 50e6;
    constant clk_period : time := 1 sec / clk_hz;

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal din : std_logic_vector(7 downto 0);
    signal leds : std_logic_vector(7 downto 0);
    signal str :std_logic;
    signal txd : std_logic;
    signal deb : std_logic;
    signal rdy : std_logic;

begin

    clk <= not clk after clk_period / 2;

    DUT : entity work.UART_TX
    port map (
        CLK => clk,
        rst => rst,
        din => din,
        leds => leds,
        str => str,
        txd => txd,
        deb => deb,
        rdy => rdy
    );

    SEQUENCER_PROC : process
    begin
        rst <= '0';
        wait for clk_period * 2;
        rst <= '1';
        din <= X"AA";
        wait for clk_period * 10;
        str <= '1';
        wait for clk_period * 1;
        str <= '0';
        din <= (others => '0');
        wait for 87 us;
        str <= '1';
        wait for clk_period * 1;
        str <= '0';
        wait;
    end process;

end architecture;