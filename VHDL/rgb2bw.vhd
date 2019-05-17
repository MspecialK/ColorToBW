library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rgb2bw is
    Port (
        red : in STD_LOGIC_VECTOR (7 downto 0);     -- ingresso canale rosso
        green : in STD_LOGIC_VECTOR (7 downto 0);   -- ingresso canale verde
        blue : in STD_LOGIC_VECTOR (7 downto 0);    -- ingresso canale blu
        bw : out STD_LOGIC_VECTOR (7 downto 0);     -- uscita bianco nero
        clk : in STD_LOGIC);                        -- clock
end rgb2bw;

architecture Behavioral of rgb2bw is
begin
    process (clk)
        -- variabile di somma. massimo = 43*3*255=32895 quindi 16 bit necessari.
        -- uso una variabile per poter scrivere il codice in modo "sequenziale" (più leggibile)
        variable sum : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
        
    begin
        if rising_edge(clk) then
            -- devo eseguire la media aritmetica dei segnali r,g,b.
            -- si vuole evitare di eseguire una divisione (elevato uso di risorse)
            -- Una possibile soluzione (approssimata) è quella di sommare i dati,
            -- moltiplicare la somma ottenuta per 43, ed infine dividere per 128 (usando shift)
            -- la soluzione è ovviamente approssimata (equivale a dividere per circa 2.977), ma
            -- restituisce risultati accettabili per il raggiungimento dello scopo prefissato
            sum := (others => '0');
            sum := std_logic_vector(unsigned(sum) + (unsigned(red)));
            sum := std_logic_vector(unsigned(sum) + (unsigned(green)));
            sum := std_logic_vector(unsigned(sum) + (unsigned(blue)));
            sum := std_logic_vector(unsigned(sum(9 downto 0)) * to_unsigned(43,6));
            -- devo controllare di non aver superato il limite di 128*255 = 32640
            -- ottimizzo: controllo solo il bit 15. Se pari a 1, ho sicuramente superato il limite (sarei oltre 32767).
            -- i valori da 32640 a 32767 compresi non danno problemi: i bit da 7 a 14 sono sempre tutti 1
            if (sum(15) = '1') then
                -- in questo caso il risultato deve essere 11111111 indipendentemente dal valore di sum
                bw <= (others => '1');   
            else
                -- sono sotto il limite massimo:
                -- eseguo la "divisione per 128" cioè lo shift, mettendo il risultato nel registro di uscita
                bw <= sum(14 downto 7);                
            end if;  

        end if;
    end process;

end Behavioral;
