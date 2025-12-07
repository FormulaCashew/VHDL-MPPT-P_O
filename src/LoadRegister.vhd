Library IEEE;
Use IEEE.Std_Logic_1164.all;
Use IEEE.Numeric_Std.all;

Entity LoadRegister is
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
End Entity LoadRegister;

Architecture Behavioral of LoadRegister is
Signal Qp, Qn : Std_Logic_Vector(BusWidth - 1 downto 0) := (Others => '0');
Begin
	
	Combinational : Process(Qp,LDR,DIN)
	Begin  
		if LDR = '0' then
			Qn <= Qp;
		else
			Qn <= DIN;
		end if;
		DOUT <= Qp;
	End Process Combinational;
	
	Sequential : Process(RST, CLK)
	Begin 
		if RST = '0' then
				 Qp <= (Others => '0');
		elsif CLK'event and CLK = '1' then 
			   Qp <= Qn;
		end if;
		
	End Process Sequential;
	
End Architecture Behavioral;
