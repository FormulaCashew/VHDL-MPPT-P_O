library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MPPT_tb is
end MPPT_tb;

architecture sim of MPPT_tb is

    constant clk_hz : integer := 50e6; -- 1 kHz clock for simulation purposes
    constant clk_period : time := 1 sec / clk_hz;

    constant clk_fs_hz: integer := 1e4; -- 10 kHz clock for simulation purposes
    constant clk_fs_period : time := 1 sec / clk_fs_hz;

    signal increase : integer := 10; -- Example increment value for DATA_RD

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal clk_fs : std_logic := '1';
    signal DATA_RD : std_logic_vector(15 downto 0) := (others => '0'); -- Example data input, replace with actual test data
    signal hi_mos : std_logic := '0';
    signal lo_mos : std_logic := '0';
    signal shtdwn : std_logic := '0';
    signal dut : std_logic_vector(11 downto 0);
    signal ena : std_logic := '0';
    signal flag : std_logic := '0'; -- Not used in this testbench
    signal done : std_logic; -- Signal to indicate that the MPPT process is done

    signal dut_prev : std_logic_vector(11 downto 0):=(others => '0');
begin

    clk <= not clk after clk_period / 2;

    UDUT : entity work.MPPT
        port map (
            CLK => clk,
            RST => rst,
            STR => clk_fs, -- Simulating a constant STR signal
            ENA => ena,
            DATA_INA => DATA_RD, -- Example data input, replace with actual test data
            ERR => open, -- Not used in this testbench
            DUT => dut, -- Not used in this testbench
            PWR => open, -- Not used in this testbench
            Hi_MOSFET => hi_mos, -- Not used in this testbench
            Lo_MOSFET => lo_mos, -- Not used in this testbench
            SHTDWN => shtdwn, -- Not used in this testbench
            DONE => done -- Signal to indicate that the MPPT process is done
        );

    CLK_FS_PRO : process -- gen a tick each clk_fs_period
    begin
        clk_fs <= '0';
        wait for clk_fs_period;
        clk_fs <= '1';
        wait for clk_period;
    end process;

    SEQUENCER_PROC : process    -- Reset sequencer
    begin
        rst <= '0';
        ena <= '0';
        wait for clk_period * 2;
        rst <= '1';
        ena <= '1';
        wait;
    end process;

    DATA_RD_PROC : process  -- Simulate data input
    variable DELTA : signed (11 downto 0):=(others => '0');
    begin
        wait for clk_fs_period * 1;
        DELTA := signed(dut)-signed(dut_prev);
        if UNSIGNED(dut) < 950 then
            if DELTA <= 0 then
                DATA_RD <= std_logic_vector(unsigned(DATA_RD) + 5); -- Cap at maximum value
            else
                DATA_RD <= std_logic_vector(unsigned(DATA_RD) - 5); -- Cap at maximum value
            end if;
        elsif UNSIGNED(dut) > 950 then
            if DELTA > 0 then
                DATA_RD <= std_logic_vector(unsigned(DATA_RD) - 1); -- Cap at maximum value
            else
                DATA_RD <= std_logic_vector(unsigned(DATA_RD) + 1); -- Cap at maximum value
            end if;
        end if;        
        dut_prev <= dut;
    end process;

end architecture;