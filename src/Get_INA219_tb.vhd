library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Get_INA219_tb is
end Get_INA219_tb;

architecture sim of Get_INA219_tb is

    constant clk_hz : integer := 50e6; -- 50 MHz clock frequency
    constant clk_period : time := 1 sec / clk_hz;

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal sda : std_logic := 'Z'; -- Tri-state for inout
    signal scl : std_logic := 'Z'; -- Tri-state for inout
    signal str : std_logic := '0'; -- Start signal, can be controlled later
    signal data_rd : std_logic_vector(15 downto 0); -- Output data, can be monitored
    signal done : std_logic; -- Signal to indicate reading is done

begin

    clk <= not clk after clk_period / 2;

    DUT : entity work.Get_INA219
    port map (
        CLK => clk,
        RST => rst,
        SDA => sda, -- Tri-state for inout
        SCL => scl, -- Tri-state for inout
        ENA => str, -- Start signal, can be controlled later
        DONE => done, -- Signal to indicate reading is done
        DATA_RD => data_rd -- Output data, can be monitored
    );

    SEQUENCER_PROC : process
    begin
        rst <= '0';
        wait for clk_period * 2;
        rst <= '1';
        wait for clk_period * 10;
        str <= '1'; -- Trigger the start signal
        wait;
    end process;


end architecture;