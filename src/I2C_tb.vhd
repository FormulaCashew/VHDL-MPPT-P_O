library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity I2C_tb is
end I2C_tb;

architecture sim of I2C_tb is

    constant clk_hz : integer := 50e6; -- I2C clock frequency in Hz
    constant clk_period : time := 1 sec / clk_hz;

    constant i2c_clk_hz : integer := 50e5; -- I2C clock frequency in Hz
    constant i2c_clk_period : time := 1 sec / i2c_clk_hz;

    signal clk : std_logic := '1';
    signal i2c_clk : std_logic := '1'; -- I2C clock input
    signal rst : std_logic := '1';
    signal i2c_address : std_logic_vector(6 downto 0) := "1000000"; -- I2C Address
    signal i2c_data : std_logic_vector(15 downto 0) := (others => '0'); -- Data to write
    signal i2c_reg : std_logic_vector(7 downto 0) := "00000000"; -- Register address to write to
    signal i2c_rw : std_logic := '0'; -- 0 Write, 1 Read
    signal str : std_logic := '0'; -- Enable signal to start I2C operation
    signal sda : std_logic := '1'; -- Serial Data/Address
    signal scl : std_logic := '1'; -- Serial Clock
    signal i2c_busy : std_logic; -- 1 Busy, 0 Waiting for response
    signal data_read : std_logic_vector(15 downto 0); -- Data read from I2C

begin

    clk <= not clk after clk_period / 2;
    i2c_clk <= not i2c_clk after i2c_clk_period / 2; -- Using the same clock for I2C

    DUT : entity work.I2C_sim(Behavioral)
    port map (
        clk => clk,
        I2C_CLK => i2c_clk, -- Using the same clock for I2C
        rst => rst,
        I2C_ADDRESS => i2c_address,
        I2C_DATA => i2c_data,
        I2C_REG => i2c_reg,
        I2C_RW => i2c_rw,
        STR => str,
        SDA => sda,
        SCL => scl,
        I2C_BUSY => i2c_busy,
        DATA_READ => data_read
    );

    SEQUENCER_PROC : process
    begin
        rst <= '0';
        wait for clk_period * 2;
        rst <= '1';
        i2c_rw <= '1'; -- Set to read operation
        i2c_address <= "1000000"; -- Example I2C address (7 bits)
        i2c_reg <= X"04"; -- Example register address
        i2c_data <= x"1000"; -- Example data to write
        wait for clk_period * 5;
        str <= '1'; -- Enable signal to start I2C operation
        wait for i2c_clk_period * 2;
        str <= '0'; -- Disable signal
        wait;
    end process;

end architecture;