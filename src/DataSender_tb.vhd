library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DataSender_tb is
end DataSender_tb;

architecture sim of DataSender_tb is

    constant clk_hz : integer := 50e6;
    constant clk_period : time := 1 sec / clk_hz;

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal PWR : std_logic_vector(15 downto 0) := (others => '0');
    signal DUT : std_logic_vector(11 downto 0) := (others => '0');
    signal ERR : std_logic_vector(15 downto 0) := (others => '0');
    signal SEND : std_logic := '0';
    signal TX : std_logic := '1';

begin

    clk <= not clk after clk_period / 2;

    U_MAIN : entity work.DataSender
    port map (
        clk => clk,
        rst => rst,
        pwr => PWR,
        dut => DUT,
        err => ERR,
        send => SEND,
        tx => TX
    );

    SEQUENCER_PROC : process
    begin
        rst <= '0';
        SEND <= '0';
        wait for clk_period * 2;
        rst <= '1';
        wait for clk_period * 10;
        PWR <= x"3A98";  -- Example power value
        DUT <= X"FFF";  -- Example DUT value
        ERR <= x"2694";  -- Example error value
        wait for clk_period * 50;
        SEND <= '1';  -- Trigger send
        wait for clk_period * 1;
        SEND <= '0';  -- Reset send signal
        wait for 2 ms;
        SEND <= '1';  -- Trigger send again
        wait for clk_period * 1;
        SEND <= '0';  -- Reset send signal
        wait;
    end process;

end architecture;