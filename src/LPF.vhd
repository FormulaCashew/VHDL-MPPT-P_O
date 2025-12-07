Library IEEE;
Use IEEE.Std_logic_1164.all;
Use IEEE.Numeric_Std.all;


Entity LPF is
	PORT(
	RST : in Std_Logic;
	CLK : in Std_logic;
	STR : in Std_logic;
	XIN : in Std_logic_vector(15 downto 0);
	UOUT : out Std_logic_vector(15 downto 0)
	);
End Entity LPF; 		  

Architecture Structural of LPF is
--===================================================== Component Declarations ===============================================================================
Component LatchSR is
	PORT(
	RST : in Std_Logic;
	CLK	: in Std_Logic;
	SET : in Std_Logic;
	CLR : in Std_Logic;
	SOUT : out Std_Logic
	);
End Component LatchSR;

Component CountDown is
	GENERIC(
	
		  Ticks : integer := 10
	);
	PORT(
		RST : in Std_Logic;
		CLK : in Std_Logic;
		DEC : in Std_Logic;
		RDY : out Std_Logic
	);
End Component CountDown;

Component FreeRunCounter is 
	GENERIC(
		buswidth : integer := 8
	);
	PORT(
	RST : in Std_Logic;
	CLK : in Std_Logic;
	INC : in Std_Logic;
	CNT : out Std_Logic_Vector(buswidth-1 Downto 0)
	);
End Component FreeRunCounter;

Component LoadRegister is
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
End Component LoadRegister;	 

Component CoefficientROM is
	PORT(
	SEL : in Std_logic_vector(2 downto 0);
	QOUT: out Std_logic_vector(26 downto 0)
	
	);
End Component CoefficientROM;

component Saturation is
    port (
        DIN : in std_logic_vector(47 downto 0);
        DOUT : out std_logic_vector(10 downto 0)
    );
end component;

--===================================================== Signal Declarations ===============================================================================


Signal ENA, EOC, RSS : Std_Logic;
Signal SEL : Std_Logic_Vector(2 downto 0);
Signal EK0, EK1, EK2 : Std_Logic_Vector(15 downto 0) := (Others => '0');	 
Signal AK0, AK1, AK2 : Std_Logic_Vector(15 downto 0) := (Others => '0');	 
Signal EMUX, EMUX2 : Std_Logic_Vector(17 downto 0) := (Others => '0'); --18
Signal QMUX, QMUX2 : Std_Logic_Vector(26 downto 0) := (Others => '0'); --27
Signal MULT, MULT2 : Std_Logic_Vector(44 downto 0); --45
Signal EMUL, EMUL2 : Std_Logic_Vector(47 downto 0);
Signal RSUM, RSUM3 : Std_Logic_Vector(47 downto 0) := (Others =>'0');
Signal ACCU : Std_Logic_Vector(47 downto 0) := (Others => '0');
signal UNSAT : std_logic_vector(47 downto 0);

Begin	
	
--===================================================== Entities Intanciations ===============================================================================
													   
	U01 : latchSR Port Map(RST, CLK, STR, EOC, ENA);
	
	U02 : FreeRunCounter Generic Map (3) Port Map(ENA, CLK, '1', SEL);
	
	U03 : CountDown Generic Map(5) Port Map(ENA, CLK, '1',EOC);	
	
	-- these are the bx terms (FF)
	U04 : LoadRegister Generic Map(16) Port Map(RST, CLK, STR, XIN, EK0); -- 16.0
	U05 : LoadRegister Generic Map(16) Port Map(RST, CLK, STR, EK0, EK1);
	U06 : LoadRegister Generic Map(16) Port Map(RST, CLK, STR, EK1, EK2); 
		
	with SEL select EMUX <= --18 bit (9 div)
	Std_logic_vector(resize(signed(EK0),18)) when "000", 
	Std_logic_vector(resize(signed(EK1),18)) when "001", 
	Std_logic_vector(resize(signed(EK2),18)) when "010",
	std_logic_vector(resize(signed(AK0),18)) when "011",
	std_logic_vector(resize(signed(AK1),18)) when "100",
	(others => '0') when others;  
	
	U07 : CoefficientROM Port Map(SEL,QMUX); -- 27 bit (9 div) F11.16
	
	-- Here there is only implemented a FF loop, a FB loop needs to b added
	MULT <= Std_Logic_Vector(signed(QMUX) * signed(EMUX));	 -- 45 bit -- idk 18+11.16
	EMUL <= Std_logic_vector(resize(signed(MULT),48)); -- prevent overflow...
	RSUM <= Std_Logic_Vector(signed(EMUL) + signed(ACCU));	 

	-- these loaders are not used... yet
	U08 : LoadRegister Generic Map(16) Port Map(RST, CLK, STR, RSUM(41 downto 26), AK0); -- 16.0
	U09 : LoadRegister Generic Map(16) Port Map(RST, CLK, STR, AK0, AK1);

	U19 : LoadRegister Generic Map(48) Port Map(RST, CLK, ENA, RSUM, ACCU);	-- store sum
	U20 : LoadRegister Generic Map(16) Port Map(RST, CLK, EOC, ACCU(42 downto 27), UOUT); --update output
	
	--U22 : Saturation port map(UNSAT, UOUT);

End Architecture;
