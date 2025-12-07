library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DataSender is
    -- whole entity is supposed to take about 2.4 ms to send the data, considering maximum values, if not may take longer
    port (
        CLK : in std_logic;
        RST : in std_logic;
        PWR : in std_logic_vector(15 downto 0); -- max considered 0d99999
        DUT : in std_logic_vector(11 downto 0); -- max considered 0xFFF
        ERR : in std_logic_vector(15 downto 0); -- max considered 0d9999
        DISP1 : out std_logic_vector(6 downto 0);
        DISP2 : out std_logic_vector(6 downto 0);
        DISP3 : out std_logic_vector(6 downto 0);
        DISP4 : out std_logic_vector(6 downto 0);
        SEND : in std_logic;
        TX : out std_logic;
        BUSY : out std_logic
    );
end DataSender;

architecture Structural of DataSender is
    ---------------------------------------------------- Component Declarations ---------------------------------------------------
    component UART_TX is
        generic(
            buswidth : integer:=8;
            baudrate : integer:=115200;
            source_clk : integer:= 50_000_000
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            din : in std_logic_vector(buswidth-1 downto 0);
            leds : out std_logic_vector(buswidth-1 downto 0);
            str : in std_logic;
            txd : out std_logic;
            deb : out std_logic;
            rdy : out std_logic
        );
    end component;

    component LoadRegister is
        generic(
            BusWidth : integer := 8
        );
        port (
            RST : in std_logic;
            CLK : in std_logic;
            LDR : in std_logic; -- Load signal
            DIN : in std_logic_vector(BusWidth - 1 downto 0); -- Data input
            DOUT : out std_logic_vector(BusWidth - 1 downto 0) -- Data output
        );
    end component;

    component LatchSR is
        port (
            RST : in Std_Logic;
            CLK	: in Std_Logic;
            SET : in Std_Logic;
            CLR : in Std_Logic;
            SOUT : out Std_Logic
        );
    End Component;

    component CountUp is
        generic(
            upto : integer := 24
        );
        port (
            CLK : in std_logic;
            RST : in std_logic;
            ENI : in std_logic;
            CNT : out integer range 0 to upto;
            ENO : out std_logic
        );
    end component;

    component Bin_to_dec is
        generic(
            bus_width : integer:= 16
        );
        port (
            CLK : in std_logic;
            RST : in std_logic;
            STR : in std_logic;
            DIN : in std_logic_vector(bus_width-1 downto 0);
            ONE : out std_logic_vector(3 downto 0);
            TEN : out std_logic_vector(3 downto 0);
            HUN : out std_logic_vector(3 downto 0);
            THO : out std_logic_vector(3 downto 0);
            ToTHO : out std_logic_vector(3 downto 0);
            HoTHO : out std_logic_vector(3 downto 0);
            BUSY : out std_logic;
            EOC : out std_logic
        );
    end component;

    component dec_to_ascii is
        port (
            DEC : in std_logic_vector(3 downto 0);
            ASCII : out std_logic_vector(7 downto 0)
        );
    end component;

    component BCD_2_segments is
        port (
            BCD : in std_logic_vector(3 downto 0);
            SEG : out std_logic_vector(6 downto 0)
        );
    end component;

    ---------------------------------------------------- Signal Declarations ---------------------------------------------------
    constant P_ASCII : std_logic_vector(7 downto 0) := X"50"; -- 'P'
    constant W_ASCII : std_logic_vector(7 downto 0) := X"57"; -- 'W'
    constant R_ASCII : std_logic_vector(7 downto 0) := X"52"; -- 'R'

    constant E_ASCII : std_logic_vector(7 downto 0) := X"45"; -- 'E'

    constant D_ASCII : std_logic_vector(7 downto 0) := X"44"; -- 'D'
    constant U_ASCII : std_logic_vector(7 downto 0) := X"55"; -- 'U'
    constant T_ASCII : std_logic_vector(7 downto 0) := X"54"; -- 'T'

    constant COLON_ASCII : std_logic_vector(7 downto 0) := X"3A";
    constant COMMA_ASCII : std_logic_vector(7 downto 0) := X"2C";

    constant LF_ASCII : std_logic_vector(7 downto 0) :=  X"0A"; -- New Line
    constant CR_ASCII : std_logic_vector(7 downto 0) := X"0D"; -- Carriage Return

    -------------------------------------- Signals -----------------------------------
    signal SEL :  integer range 0 to 23 := 0; -- Selector for the data to be sent
    signal DATA_UART : std_logic_vector(7 downto 0):=(others => '0'); -- Data to be sent over UART
    signal DUT_INT : std_logic_vector(15 downto 0):=(others => '0'); -- Internal signal for DUT
    signal CLR : std_logic:='0'; -- Clear signal for the latch
    signal SEND_DATA : std_logic:='0'; -- Internal send signal
    signal RDY : std_logic:='0'; -- Ready signal from UART
    signal SOUT : std_logic:='0'; -- Output from the latch

    signal RDY_PREV : std_logic:='0';
    signal SEND_PREV : std_logic:='0'; -- Previous state of SEND signal for edge detection
    signal RED_SEND : std_logic:='0'; -- Signal to trigger the sending process
    signal RED_RDY : std_logic:='0'; -- Signal to indicate that the sender is busy
    signal FED_RDY : std_logic:='0';

    signal ONES : std_logic_vector(3 downto 0):=(others => '0'); -- Ones place for decimal conversion
    signal TENS : std_logic_vector(3 downto 0):=(others => '0'); -- Tens place for decimal conversion
    signal HUND : std_logic_vector(3 downto 0):=(others => '0'); -- Hundreds place for decimal conversion
    signal THOU : std_logic_vector(3 downto 0):=(others => '0'); -- Thousands place for decimal conversion
    signal ToTHO : std_logic_vector(3 downto 0):=(others => '0'); -- Ten thousands place for decimal conversion
    signal HoTHO : std_logic_vector(3 downto 0):=(others => '0'); -- Hundred thousands place for decimal conversion
    signal EOC : std_logic; -- End of conversion signal
    signal CONV_BUSY : std_logic;

    signal PWR_BUFFER : std_logic_vector(15 downto 0) := (others => '0'); -- Buffer for PWR data
    signal ERR_BUFFER : std_logic_vector(15 downto 0) := (others => '0'); -- Buffer for ERR data
    signal DUT_BUFFER : std_logic_vector(11 downto 0) := (others => '0'); -- Buffer for DUT data
    signal ERR_ABS : std_logic_vector(15 downto 0) := (others => '0');

    signal IN_DEC : std_logic_vector(3 downto 0):=(others => '0');  -- input as a vector w values 1-9
    signal DEC_ASCII : std_logic_vector(7 downto 0):=(others => '0');   -- output from dataflow in ascii

    signal DTC : std_logic_vector(15 downto 0); -- Data to be converted to decimal
    signal SBTD : std_logic:='0';
    signal state : integer := 0; -- State variable for the FSM
    constant IDLE : integer := 0; -- Idle state for the FSM
    constant SEND_P : integer := 1; -- State to send P data
    constant SEND_W : integer := 2; -- State to send W data
    constant SEND_R : integer := 3; -- State to send R data
    constant SEND_COLON : integer := 4; -- State to send colon
    constant SEND_D : integer := 5; -- State to send D data

    type BCD_type is array (0 to 3) of std_logic_vector(3 downto 0);
    signal BCD_disp : BCD_type := (others => (others => '0')); 
    type DISP_type is array (0 to 3) of std_logic_vector(6 downto 0);
    signal SEG_disp : DISP_type := (others => (others => '0')); 


begin

    DUT_INT <= std_logic_vector(resize(unsigned(DUT_BUFFER), 16)); -- Extend DUT to 16 bits
    
    U_CONV : Bin_to_dec
        generic map (
            bus_width => 16 -- Adjusted to match the data width of PWR and ERR
        )
        port map (
            CLK => CLK,
            RST => RST,
            STR => SBTD, -- Trigger conversion
            DIN => DTC, -- Data input for PWR
            ONE => ONES, 
            TEN => TENS, 
            HUN => HUND, 
            THO => THOU, 
            ToTHO => ToTHO, 
            HoTHO => HoTHO, 
            BUSY => CONV_BUSY, -- End of conversion
            EOC => EOC
        );

    DISP_GEN : for i in 0 to 3 generate
        DISP_i : BCD_2_segments 
        port map(BCD_disp(i), SEG_disp(i));
    end generate;

    DISP1 <= SEG_disp(0);
    DISP2 <= SEG_disp(1);
    DISP3 <= SEG_disp(2);
    DISP4 <= SEG_disp(3);

    FSM_PROC : process(CLK,RST) -- FSM that sends the whole data trail, could be changed to some data shifters, latches
    begin
        if RST = '0' then
            state <= 0;
            DATA_UART <= (others => '0');
            DTC <= (others => '0');
        elsif rising_edge(CLK) then
            case state is
                when 0 =>
                    CLR <= '0';
                    if RED_SEND='1' then
                        DATA_UART <= P_ASCII;
                        SEND_DATA <= '1';
                    end if;
                    if FED_RDY='1' then
                        state <= state+1;
                        DTC <= PWR_BUFFER;
                        SEND_DATA <= '0';
                    end if;
                when 1 => 
                    SBTD <= '1';
                    if RED_RDY='1' then
                        DATA_UART <= W_ASCII;
                        SEND_DATA <= '1';
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                    end if;
                when 2 => 
                    SBTD <= '0';
                    if RED_RDY='1' then
                        DATA_UART <= R_ASCII;
                        SEND_DATA <= '1';
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                    end if;
                when 3 => 
                    if RED_RDY='1' then
                        DATA_UART <= COLON_ASCII;
                        SEND_DATA <= '1';
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        IN_DEC <= ToTHO;
                        BCD_disp(0) <= ONES;
                        BCD_disp(1) <= TENS;
                        BCD_disp(2) <= HUND;
                        BCD_disp(3) <= THOU;
                    end if;
                when 4 => --hold while conversion
                    if CONV_BUSY='0' then
                        state <= 5;
                    end if;
                when 5 => 
                    if RDY='1' then
                        DATA_UART <= DEC_ASCII; -- 2 cycles to take effect
                        SEND_DATA <= '1';
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        IN_DEC <= THOU;
                        
                    end if;
                when 6 =>   -- sending  thousand digit pwr 
                    if RED_RDY='1' then
                        DATA_UART <= DEC_ASCII; -- 2 cycles to take effect
                        SEND_DATA <= '1';
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        IN_DEC <= HUND;
                    end if;
                when 7 => -- sending hundreds
                    if RED_RDY='1' then
                        DATA_UART <= DEC_ASCII;
                        SEND_DATA <= '1';
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        IN_DEC <= TENS;
                    end if;
                when 8 => -- sending tens
                    if RED_RDY='1' then
                        DATA_UART <= DEC_ASCII;
                        SEND_DATA <= '1';
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        IN_DEC <= ONES;
                    end if;
                when 9 => -- sending units
                    if RED_RDY='1' then
                        DATA_UART <= DEC_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                        DTC <= ERR_ABS; -- prepare next conversion
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                    end if;
                when 10 => 
                    if RED_RDY='1' then
                        DATA_UART <= COMMA_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                        SBTD <= '1';        -------
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                    end if;
                when 11 => 
                    if RED_RDY='1' then
                        DATA_UART <= E_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        SBTD <= '0';        --------
                        state <= state+1;
                    end if;
                when 12 => 
                    if RED_RDY='1' then
                        DATA_UART <= R_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                    end if;
                when 13 => 
                    if RED_RDY='1' then
                        DATA_UART <= R_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= 32;
                    end if;
                when 32 => 
                    if CONV_BUSY='0' then
                        state <= 14;
                    end if;
                when 14 => 
                    if RED_RDY='1' then
                        DATA_UART <= COLON_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        if (ERR(15)='1') then
                            state <= 31;
                            IN_DEC <= "1110";
                        else
                            state <= state+1;
                            IN_DEC <= THOU;
                        end if;
                    end if;
                when 31 => 
                    if RED_RDY='1' then
                        DATA_UART <= DEC_ASCII;
                        SEND_DATA <= '1';
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= 15;
                        IN_DEC <= THOU;
                    end if;
                when 15 => 
                    if RED_RDY='1' then
                        DATA_UART <= DEC_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        IN_DEC <= HUND;
                    end if;
                when 16 => 
                    if RED_RDY='1' then
                        DATA_UART <= DEC_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        IN_DEC <= TENS;
                    end if;
                when 17 => 
                    if RED_RDY='1' then
                        DATA_UART <= DEC_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        IN_DEC <= ONES;
                    end if;
                when 18 => 
                    if RED_RDY='1' then
                        DATA_UART <= DEC_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        DTC <= DUT_INT;
                    end if;
                when 19 => 
                    if RED_RDY='1' then
                        DATA_UART <= COMMA_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                    end if;
                when 20 => 
                    if RED_RDY='1' then
                        DATA_UART <= D_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                        SBTD <= '1';
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        SBTD <= '0';
                    end if;
                when 21 => 
                    if RED_RDY='1' then
                        DATA_UART <= U_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                    end if;
                when 22 => 
                    if RED_RDY='1' then
                        DATA_UART <= T_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' and CONV_BUSY='0' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        IN_DEC <= THOU;
                    end if;
                when 23 => 
                    if RED_RDY='1' then
                        DATA_UART <= COLON_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                    end if;
                when 24 => 
                    if RED_RDY='1' then
                        DATA_UART <= DEC_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        IN_DEC <= HUND;
                    end if;
                when 25 => 
                    if RED_RDY='1' then
                        DATA_UART <= DEC_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        IN_DEC <= TENS;
                    end if;
                when 26 => 
                    if RED_RDY='1' then
                        DATA_UART <= DEC_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                        IN_DEC <= ONES;
                    end if;
                when 27 => 
                    if RED_RDY='1' then
                        DATA_UART <= DEC_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                    end if;
                when 28 => 
                    if RED_RDY='1' then
                        DATA_UART <= LF_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                    end if;
                when 29 => 
                    if RED_RDY='1' then
                        DATA_UART <= CR_ASCII;
                        SEND_DATA <= '1'; -- 2 clk to take effect
                    end if;
                    if FED_RDY='1' then
                        SEND_DATA <= '0';
                        state <= state+1;
                    end if;
                when others => 
                    DTC <= (others => '0');
                    SEND_DATA <= '0';
                    state <= 0;
                    CLR <= '1';
            end case;
        end if;
    end process;

    U_DTA : dec_to_ascii    -- simple bin decimal to ascii table 
    port map(
        DEC => IN_DEC,
        ASCII => DEC_ASCII
    );

    RED_PROC : process(CLK, RST)    -- to detect different edges
    begin
        if RST = '0' then
            SEND_PREV <= '0';
				RDY_PREV <= '0';
        elsif rising_edge(CLK) then
            SEND_PREV <= SEND; -- Update previous state of SEND
            RDY_PREV <= RDY; -- Update previous state of RDY
        end if;
    end process;
    RED_SEND <= '1' when SEND = '1' and SEND_PREV = '0' else '0'; -- Trigger RED_SEND on rising edge of SEND
    RED_RDY <= '1' when RDY = '1' and RDY_PREV = '0' else '0'; -- Trigger RED_RDY on rising edge of RDY
    FED_RDY <= '1' when RDY = '0' and RDY_PREV = '1' else '0';

    LAT_proc : process(CLK, RST) -- For busy signal
    begin
        if RST = '0' then
            SOUT <= '0'; -- Reset latch signal
        elsif rising_edge(CLK) then
            if RED_SEND='1' then
                SOUT <= '1'; -- Set latch signal when SEL is reset
            elsif CLR = '1' then
                SOUT <= '0'; -- Clear latch signal when CLR is high
            end if;
        end if;
    end process;
    BUSY <= SOUT; -- Indicate that the sender is busy

    ----------------- Buffers for storing data before sending -----------------------------------------------
    U_PWRBUF : LoadRegister
        generic map(
            BusWidth => 16
        )
        port map(
            RST => RST,
            CLK => CLK,
            LDR => RED_SEND, -- Load signal
            DIN => PWR, -- Data input for PWR
            DOUT => PWR_BUFFER -- Data output for PWR
        );
    
    ERR_ABS <= std_logic_vector(ABS(signed(ERR_BUFFER)));
    U_ERRBUF : LoadRegister
        generic map(
            BusWidth => 16
        )
        port map (
            RST => RST,
            CLK => CLK,
            LDR => RED_SEND, -- Load signal
            DIN => ERR, -- Data input for ERR
            DOUT => ERR_BUFFER -- Data output for ERR
        );
    
    U_DUTBUF : LoadRegister
        generic map(
            BusWidth => 12
        )
        port map (
            RST => RST,
            CLK => CLK,
            LDR => RED_SEND, -- Load signal
            DIN => DUT, -- Data input for DUT
            DOUT => DUT_BUFFER -- Data output for DUT
        );

    U_UART :  UART_TX -- UART Comm entity
        generic map (
            buswidth => 8,
            baudrate => 115200,
            source_clk => 50_000_000
        )
        port map (
            clk => CLK,
            rst => SOUT,
            din => DATA_UART,
            leds => open, 
            str => SEND_DATA, -- Trigger to send data
            txd => TX, -- Transmit data
            deb => open, 
            rdy => RDY 
        );                        
    

end architecture;