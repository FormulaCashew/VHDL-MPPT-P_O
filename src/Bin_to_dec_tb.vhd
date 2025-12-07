library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Bin_to_dec_tb is
end Bin_to_dec_tb;

architecture sim of Bin_to_dec_tb is

    constant clk_hz : integer := 50e6; -- 50 MHz clock for simulation purposes
    constant clk_period : time := 1 sec / clk_hz;

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal STR : std_logic := '0'; -- Start signal, not used in this testbench
    signal DIN : std_logic_vector(15 downto 0) := (others => '0'); -- Example data input, 5678
    signal ONE : std_logic_vector(3 downto 0);
    signal TEN : std_logic_vector(3 downto 0);
    signal HUN : std_logic_vector(3 downto 0);
    signal THO : std_logic_vector(3 downto 0);
    signal ToTHO : std_logic_vector(3 downto 0);
    signal HoTHO : std_logic_vector(3 downto 0);
    signal BUSY : std_logic; -- End of conversion signal, not used in this test
    signal EOC : std_logic;

    signal flag : std_logic:='0';
begin

    clk <= not clk after clk_period / 2;

    DUT : entity work.Bin_to_dec
        generic map (
            bus_width => 16
        )
    port map (
        clk => clk,
        rst => rst,
        str => STR,
        din => DIN,
        one => ONE,
        ten => TEN,
        hun => HUN,
        tho => THO,
        totho => ToTHO,
        hotho => HoTHO,
        busy => BUSY,
        EOC => eoc
    );

    SEQUENCER_PROC : process
    begin
        rst <= '0';
        wait for clk_period * 2;
        rst <= '1';
        wait for clk_period * 3;
        DIN <= X"F70F"; -- Load 5678 in binary
        wait;
    end process;

    SEQ_PROC : process
    begin
        wait for clk_period * 10;
        str <= '1';
        wait for clk_period * 1;
        str <= '0';
        wait for 230 us;
    end process;

end architecture;