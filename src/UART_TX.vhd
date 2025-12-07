library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TX is
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
end UART_TX;

architecture Structural of UART_TX is
    component LatchSR is
        port (
            RST : in std_logic;
            CLK : in std_logic;
            SET : in std_logic;
            CLR : in std_logic;
            SOUT : out std_logic
        );
    end component;

    component TimCirc is
        GENERIC (
            ticks : INTEGER := 1529
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            eot : OUT STD_LOGIC
        );
    end component;

    component CountDown is 
        generic(
            Ticks : integer:= 10
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            dec : in std_logic;
            rdy : out std_logic
        );
    end component;

    component Serializer is 
        generic(
            buswidth : integer := 8
        );
        port (
            CLK : in std_logic;
            RST : in std_logic;
            DIN : in std_logic_vector(buswidth-1 downto 0);
            LDR : in std_logic;
            SHF : in std_logic;
            BOUT : out std_logic
        );
    end component;
	 
	 component RisingEdge_gen is
		 generic(
			  num_dff : integer := 4
		 );
		 port (
			  XIN : in std_logic;
			  CLK : in std_logic;
			  RST : in std_logic;
			  XRE : out std_logic
		 );
	 end component;

    component LoadRegister is
        GENERIC(
            BusWidth : Integer := 7	
        );
        PORT(
            RST : in Std_Logic;
            CLK : in Std_Logic;
            LDR : in Std_Logic;
            DIN : in Std_Logic_Vector(BusWidth - 1 downto 0);
            DOUT : out Std_Logic_Vector(BusWidth - 1 downto 0)
        );											
    End component;

constant baud_2_ticks : integer :=(source_clk/baudrate);--5233

signal d_serial : std_logic_vector(buswidth downto 0):=(others => '0');
signal deb_str : std_logic := '0';
signal n_str : std_logic:='0';
signal ENA_S : std_logic:='0';
signal EOC_S : std_logic:='0';	   
signal SYN : std_logic:='0';

signal din_buf : std_logic_vector(buswidth-1 downto 0):=(others => '0');

begin
    n_str <= not str;   --invert btn logic, not nec anymore
    d_serial <= din_buf & '0';  --concat a 0 for the start
	 leds<=din;
    rdy <= not ENA_S;
	 deb <= EOC_S;

	 U00 : RisingEdge_gen
	 generic map(
		  num_dff => 2
	 )
	 port map (
		  XIN => str,
		  CLK => clk,
		  RST => rst,
		  XRE => deb_str
	 );
	 
    U01 : LatchSR
    port map(
        RST => rst,
        CLK => clk,
        SET => deb_str,
        CLR => EOC_S,
        SOUT => ENA_S
    );

    U02 : TimCirc
    GENERIC map(
        ticks => baud_2_ticks
    )
    PORT map(
        clk => clk,
        rst => ENA_S,
        eot => SYN
    );

    U03 : CountDown
    generic map(
        Ticks => buswidth+1
    )
    port map(
        clk => clk,
        rst => ENA_S,
        dec => SYN,
        rdy => EOC_S
    );

    U0X : LoadRegister
        GENERIC map(buswidth)
        PORT map(RST, CLK, STR, din, din_buf);			


    U04 : Serializer
    generic map(
        buswidth => buswidth+1
    )
    port map(
        CLK => clk,
        RST => rst,
        DIN => d_serial,
        LDR => deb_str,
        SHF => SYN,
        BOUT => txd
    );

end architecture;