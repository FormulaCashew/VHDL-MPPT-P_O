Library IEEE;
Use IEEE.Std_logic_1164.all;


Entity CoefficientROM is
	PORT(
	SEL : in Std_logic_vector(2 downto 0);
	QOUT: out Std_logic_vector(26 downto 0)
	
	);
End Entity CoefficientROM; 

Architecture DataFlow of CoefficientROM is
Begin	 
	
	COROM : process(SEL)	
	begin  
		case SEL is	-- F 11.16
		when "000" => QOUT <= "000000000010000000000000000" ; --b0
		when "001" => QOUT <= "000000000100000000000000000" ; --b1
		when "010" => QOUT <= "000000000010000000000000000" ; --b2
		when "011" => QOUT <= "111111111100001011010111100" ; -- -a1
		when "100" => QOUT <= "000000000001110101000111100" ; -- -a2
	  when OTHERS => QOUT <= "000000000000000000000000000" ;
		end case;
	end process;
	
End Architecture DataFlow;
