library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Get_INA219 is
    generic(
        SAMPLE_FREQ : integer := 100 --in hz
    );
    port (
        CLK : in std_logic;
        RST : in std_logic;
        SDA : inout std_logic;
        SCL : inout std_logic;
        ENA : in std_logic; -- Start signal to initiate reading
        DONE : out std_logic; -- Signal to indicate reading is done
        DATA_RD : out std_logic_vector(15 downto 0) -- Data read from INA219
    );
end Get_INA219;

architecture Structural of Get_INA219 is

    component TimCirc is
        generic (
            ticks : INTEGER := 1529
        );
        port (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            eot : OUT STD_LOGIC
        );
    end component;

    component LatchSR is
        port (
            RST : in std_logic;
            CLK : in std_logic;
            SET : in std_logic;
            CLR : in std_logic;
            SOUT : out std_logic
        );
    end component;

    component i2c_master IS
        GENERIC(
            input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
            bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
        PORT(
            clk       : IN     STD_LOGIC;                    --system clock
            reset_n   : IN     STD_LOGIC;                    --active low reset
            ena       : IN     STD_LOGIC;                    --latch in command
            addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
            rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
            data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
            busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
            data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
            ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
            sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
            scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
    END component;

    constant TICKS : integer := 50_000_000 / SAMPLE_FREQ;
    -------------------------------------------------------------------------------------
    constant INA219_ADDR : std_logic_vector(6 downto 0) := "1000000"; -- INA219 I2C address
    constant INA219_PWR_REG : std_logic_vector(7 downto 0) := X"03"; -- Power register address
	constant INA219_CALIB : std_logic_vector(7 downto 0) := X"05"; -- Calibration register address
    constant INA219_CALIB_VALUE : std_logic_vector(15 downto 0) := X"082C"; --X"08A5";6% err -- Calibration value for INA219
    -------------------------------------------------------------------------------------

    signal ED : std_logic := '0'; -- Signal to trigger reading
    signal STR : std_logic := '0';

    signal BUSY_PREV : std_logic := '0'; -- Busy fed detector
    signal LAT : std_logic := '0'; -- Latch signal for reading
    signal DATA_RD_INT : std_logic_vector(15 downto 0) := (others => '0'); -- Output data read from INA219

    signal ENA_I2C : std_logic := '0'; -- Signal to indicate sending data
    signal RW : std_logic := '1'; -- Read operation (1 for read, 0 for write) 
    signal DATA : std_logic_vector(7 downto 0) := (others => '0'); -- Data read from INA219
    signal data_wr : std_logic_vector(7 downto 0) := (others => '0'); -- Data to write to INA219
    signal BUSY : std_logic := '0'; -- Signal to indicate if the I2C bus is busy
    signal ACK_ERR: std_logic := '0'; -- Acknowledge error signal

begin

    U_TIM : TimCirc
        generic map (
            ticks => TICKS -- Adjust this value based on your clock frequency and desired timing
        )
        port map (
            clk => CLK,
            rst => ENA,
            eot => STR -- End of transaction signal
        );

    U_I2C : i2c_master
        GENERIC map(
            input_clk => 50_000_000, --input clock speed from user logic in Hz
            bus_clk => 400_000   --speed the i2c bus (scl) will run at in Hz
             )        
          PORT map(
            clk => CLK,                  --system clock
            reset_n => RST,                    --active low reset
            ena => ENA_I2C,                       --latch in command
            addr => INA219_ADDR, --address of target slave
            rw  => RW,                    --'0' is write, '1' is read
            data_wr => data_wr, --data to write to slave
            busy => BUSY,                    --indicates transaction in progress
            data_rd => DATA, --data read from slave
            ack_error => ACK_ERR,                    --flag if improper acknowledge from slave
            sda => SDA,                    --serial data output of i2c bus
            scl => SCL);                   


    FSM_PROC : process(CLK,RST)
    variable BUSY_CNT : integer range 0 to 7 := 0; -- Counter for busy state
    begin
        if RST = '0' then
            ENA_I2C <= '0';
            BUSY_CNT := 0;
            DONE <= '0';
            BUSY_PREV <= '0';
            DATA_RD_INT <= (others => '0'); -- Reset data read
        elsif CLK='1' and CLK'event then
            if BUSY_PREV = '1' and BUSY = '0' then
                BUSY_CNT := BUSY_CNT + 1; -- Increment busy counter
            end if;
            BUSY_PREV <= BUSY; -- Capture the busy state
            case BUSY_CNT is
                when 0 => 
                    DONE <= '0'; -- Reset done signal
					RW <= '0'; -- Write Register address
                    if(STR = '1') then
                        ENA_I2C <= '1'; -- Enable I2C operation
                        data_wr <= INA219_CALIB; -- Set the calibration register address
                    end if;
                    if BUSY='1' then -- If busy, prepare to write calibration value
                        data_wr <= INA219_CALIB_VALUE(15 downto 8); -- Set the calibration value
                    end if;
                when 1 =>  -- Ended write reg, send calibration value pt 1
                    DONE <= '0'; -- Reset done signal
                    if ACK_ERR = '0' then -- Check for acknowledge error
                        ENA_I2C <= '1'; -- Start I2C read operation
                        RW <= '0'; -- Set to read operation
                    else
                        ENA_I2C <= '0'; -- Disable I2C operation if error}
                        BUSY_CNT := 0; -- Reset busy counter
                    end if;
                    if BUSY='1' then -- next process is write second part of calibration value
                        data_wr <= INA219_CALIB_VALUE(7 downto 0); -- Write second part of calibration value
                        RW <= '0'; -- Set to write operation
                    end if;
                when 2 => -- Ended write calibration value pt 1, send pt 2
                    DONE <= '0'; -- Reset done signal
                    if ACK_ERR = '0' then -- Check for acknowledge error
                        ENA_I2C <= '1'; -- Enable I2C operation
                    else
                        ENA_I2C <= '0'; -- Disable I2C operation if error
                        BUSY_CNT := 0; -- Reset busy counter
                    end if;
                    if BUSY='1' then -- while writing pt 2 of calibration value, prepare to write power register for read
                        data_wr <= INA219_PWR_REG; -- Set the power register address
                        ENA_I2C <= '0'; -- Disable I2C operation
                        DATA_RD_INT <= (others => '0'); -- Reset internal data read
                        DATA_RD <= (others => '0'); -- Reset output data
                    end if;
                when 3 => -- To get another start
                    ENA_I2C <= '1'; -- Enable I2C operation
                    if BUSY='1' then -- If busy, prepare to write power register
                        data_wr <= (others => '0'); -- Clear data write buffer
                        RW <= '1'; -- Set to read operation
                    end if;
                    DONE <= '0'; -- Reset done signal
                when 4 => -- Ended write calibration value pt 2, write power register
                    DONE <= '0'; -- Reset done signal
                    if ACK_ERR = '0' then -- Check for acknowledge error
                        ENA_I2C <= '1'; -- Enable I2C operation
                        DATA_RD_INT(15 downto 8) <= DATA; -- Output the read data
                    else
                        ENA_I2C <= '0'; -- Disable I2C operation if error
                        DONE <= '0'; -- Reset done signal
                        BUSY_CNT := 0; -- Reset busy counter
                        DATA_RD <= (others => '0'); -- Reset output data
                        DATA_RD_INT <= (others => '0'); -- Reset internal data read
                    end if;
                when 5 => -- Ended write power register, starting read
                    --DONE <= '1'; -- Reset done signal
                    if ACK_ERR = '0' then -- Check for acknowledge error
                        RW <= '0'; -- leave it in write mode for next operation
                        DATA_RD_INT(7 downto 0) <= DATA; -- Output the read data
                        ENA_I2C <= '0'; -- Enable I2C operation
                    else -- Acknowledge error
                        ENA_I2C <= '0'; -- Disable I2C operation if error
                        DATA_RD <= (others => '0'); -- Reset output data
                        DONE <= '0'; -- Set done signal to indicate reading is complete
                        DATA_RD_INT <= (others => '0'); -- Reset internal data read
                        BUSY_CNT := 0; -- Reset busy counter
                    end if;
                when 6 => 
                    if unsigned(DATA_RD_INT)< 8000 then
                        DATA_RD <= DATA_RD_INT(15 downto 0); -- Assign the read data to output, mult by 2
                        DONE <= '1'; -- Reset done signal
                    else 
                        DONE <= '0'; -- Reset done signal
                    end if;
                    BUSY_CNT := 7;
                when others =>
                    ENA_I2C <= '0'; -- Disable I2C operation
                    DONE <= '0'; -- Reset done signal
                    BUSY_CNT := 0;
            end case;
        end if;
    end process;

end architecture;