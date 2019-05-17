library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity home2_top is
    Port ( 
        rx : in STD_LOGIC;       -- ingresso per la ricezione seriale
        tx : out STD_LOGIC;      -- uscita per la trasmissione seriale
        rst : in STD_LOGIC;      -- ingresso di reset (attivo altro)
        clk : in STD_LOGIC);     -- ingresso di clock
end home2_top;

architecture Behavioral of home2_top is

    -- diciarazione del componente AXI4Stream
    COMPONENT AXI4Stream_RS232_0
        PORT (
        clk_uart : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        RS232_TX : OUT STD_LOGIC;
        RS232_RX : IN STD_LOGIC;
        m00_axis_rx_aclk : IN STD_LOGIC;
        m00_axis_rx_aresetn : IN STD_LOGIC;
        m00_axis_rx_tvalid : OUT STD_LOGIC;
        m00_axis_rx_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m00_axis_rx_tready : IN STD_LOGIC;
        s00_axis_tx_aclk : IN STD_LOGIC;
        s00_axis_tx_aresetn : IN STD_LOGIC;
        s00_axis_tx_tready : OUT STD_LOGIC;
        s00_axis_tx_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s00_axis_tx_tvalid : IN STD_LOGIC);
    END COMPONENT;
    
    -- diciarazione del componente rgb2bw
    COMPONENT rgb2bw
        PORT (
        red : in STD_LOGIC_VECTOR (7 downto 0);
        green : in STD_LOGIC_VECTOR (7 downto 0);
        blue : in STD_LOGIC_VECTOR (7 downto 0);
        bw : out STD_LOGIC_VECTOR (7 downto 0);
        clk : in STD_LOGIC);
    END COMPONENT;
    
    -- segnale di /reset (attivo basso)
    signal rstn : STD_LOGIC;
    
    -- dati ricevuti (in uscita dal ricevitore)
    signal rxdata : STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- indica che sono stati ricevuti correttamente dei dati (in uscita dal ricevitore)
    signal rxvalid : STD_LOGIC;
    -- indica al ricevitore che il blocco ad esso collegato è pronto a ricevere dei dati (in ingresso al ricevitore)
    signal rxready : STD_LOGIC;
    
    -- dati da inviare (in ingresso al trasmettitore)
    signal txdata : STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- indica al trasmettitore che sono presenti dati validi da inviare (in ingresso al trasmettitore)
    signal txvalid : STD_LOGIC;
    -- indica che il trasmettitore è pronto per l'invio di dati (in uscita dal trasmettitore)
    signal txready : STD_LOGIC;
    
    -- buffer dato rosso
    signal redbuffer : STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- buffer dato verde
    signal greenbuffer : STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- buffer dato blu
    signal bluebuffer : STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- indice del buffer utilizzato (0=rosso, 1=verde, 2=blu)
    signal buffer_index : INTEGER RANGE 0 TO 2;
    -- indica che è richiesta la trasmissione
    signal txrequested : boolean;
    
begin

    -- istanza del componente AXI4Stream_RS232_0
    com_instance : AXI4Stream_RS232_0
        PORT MAP (
            clk_uart => clk,
            rst => rst,
            RS232_TX => tx,
            RS232_RX => rx,
            m00_axis_rx_aclk => clk,
            m00_axis_rx_aresetn => rstn,
            m00_axis_rx_tvalid => rxvalid,
            m00_axis_rx_tdata => rxdata,
            m00_axis_rx_tready => rxready,
            s00_axis_tx_aclk => clk,
            s00_axis_tx_aresetn => rstn,
            s00_axis_tx_tready => txready,
            s00_axis_tx_tdata => txdata,
            s00_axis_tx_tvalid => txvalid);
            
    -- istanza del componenete rgb2bw
    rgb2bw_instance : rgb2bw
        PORT MAP (
            red => redbuffer,
            green => greenbuffer,
            blue => bluebuffer,
            bw => txdata,
            clk => clk);

    -- segnale di reset (attivo basso) per il rtx seriale
    rstn <= not rst;
    
    -- il sistema di elaboazione è realtime: sono sempre pronto a ricevere dei dati seriali
    rxready <= '1';
    
    -- processo di elaborazione
    serial_image_processor  :  process(clk)
    
    begin
    
        if rst = '1' then
            -- reset richiesto
            buffer_index        <= 0;
 
        elsif rising_edge(clk) then
        
            -- controllo se ho dati vaidi
            if (rxvalid = '1') then
                -- ho ricevuto un nuovo dato: lo devo salvare nel buffer appropriato
                if (buffer_index = 0) then
                    redbuffer <= rxdata;
                    buffer_index <= 1;
                elsif (buffer_index = 1) then
                    greenbuffer <= rxdata;
                    buffer_index <= 2;
                elsif (buffer_index = 2) then
                    bluebuffer <= rxdata;
                    buffer_index <= 0;
                    txrequested <= true;
                else
                    -- impossibile
                end if;
            end if;
            
            -- controllo se posso trasmettere
            if (txrequested = true and txready = '1') then
                -- comando di trasmissione
                txvalid <= '1';
                -- richiesta esaudita
                txrequested <= false;
            else
                -- fine trasmissione
                txvalid <= '0';
            end if; 
               
        end if;

    end process;

end Behavioral;
