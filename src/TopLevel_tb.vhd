library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopLevel_tb is
end TopLevel_tb;

architecture sim of TopLevel_tb is

    constant clk_hz : integer := 50e6;
    constant clk_period : time := 1 sec / clk_hz;

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal himos, lomos, shtdwn : std_logic :='0';
    signal sda, scl, tx : std_logic := '1';
    signal ena : std_logic := '0' ;

begin

    clk <= not clk after clk_period / 2;

    DUT : entity work.TopLevel
    port map (
        CLK => clk,
        RST => rst,
        Hi_MOSFET => himos,
        Lo_MOSFET => lomos,
        SHTDWN => shtdwn,
        SDA => sda,
        SCL => scl,
        TX => tx,
        ENA => ena
    );

    SEQUENCER_PROC : process
    begin
        rst <= '0';
        ena <= '0';
        wait for clk_period * 2;
        rst <= '1';
        wait for 3 us;
        ena <= '1';
        wait;
    end process;

end architecture;