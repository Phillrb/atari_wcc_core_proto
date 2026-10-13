library IEEE;
use IEEE.STDLOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_pot_reader is
    generic (
        SYS_CLK_FREQ : integer := 50_000_000; -- 50 MHz Cyclone II Onboard Oscillator
        SPI_SCLK_FREQ: integer := 1_000_000    -- 1 MHz SPI Clock output
    );
    port (
        clk        : in  std_logic;
        reset_n    : in  std_logic;
        
        -- SPI Physical Interface
        sclk       : out std_logic;
        cs_n       : out std_logic;
        miso       : in  std_logic;
        
        -- Unpacked 10-bit Potentiometer Output Registers
        pot0       : out std_logic_vector(9 downto 0);
        pot1       : out std_logic_vector(9 downto 0);
        pot2       : out std_logic_vector(9 downto 0);
        pot3       : out std_logic_vector(9 downto 0);
        data_valid : out std_logic
    );
end entity spi_pot_reader;

architecture Behavioral of spi_pot_reader is

    -- SCLK Generator Constant (Divider creates half-period toggles)
    constant SCLK_DIV : integer := SYS_CLK_FREQ / (2 * SPI_SCLK_FREQ);

    -- State Machine
    type state_type is (IDLE, ASSERT_CS, TRANSFER, LATCH_DATA, DESELECT);
    signal state : state_type := IDLE;

    -- Internal Counters & Registers
    signal clk_cnt   : integer range 0 to SCLK_DIV := 0;
    signal spi_clk   : std_logic := '0';
    signal bit_idx   : integer range 0 to 7 := 7;
    signal byte_idx  : integer range 0 to 7 := 0;
    signal rx_shift  : std_logic_vector(7 downto 0) := (others => '0');

    -- Storage Array for 8 Received Bytes (High/Low byte per channel)
    type byte_array is array (0 to 7) of std_logic_vector(7 downto 0);
    signal raw_bytes : byte_array := (others => (others => '0'));

begin

    sclk <= spi_clk when (state = TRANSFER) else '0';

    -- State Machine & SPI Logic
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state      <= IDLE;
            cs_n       <= '1';
            spi_clk    <= '0';
            clk_cnt    <= 0;
            bit_idx    <= 7;
            byte_idx   <= 0;
            data_valid <= '0';
            
        elsif rising_edge(clk) then
            
            case state is

                when IDLE =>
                    cs_n       <= '1';
                    spi_clk    <= '0';
                    data_valid <= '0';
                    byte_idx   <= 0;
                    clk_cnt    <= 0;
                    state      <= ASSERT_CS;

                when ASSERT_CS =>
                    cs_n <= '0'; -- Select ATtiny84 Slave
                    if clk_cnt = SCLK_DIV - 1 then
                        clk_cnt <= 0;
                        bit_idx <= 7;
                        state   <= TRANSFER;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when TRANSFER =>
                    -- SCLK Generation Divider
                    if clk_cnt = SCLK_DIV - 1 then
                        clk_cnt <= 0;
                        spi_clk <= not spi_clk;

                        -- Sample MISO on Rising Edge of SCLK
                        if spi_clk = '0' then
                            rx_shift(bit_idx) <= miso;
                            
                            if bit_idx = 0 then
                                bit_idx <= 7;
                                raw_bytes(byte_idx) <= rx_shift(7 downto 1) & miso; -- Catch final bit
                                
                                if byte_idx = 7 then
                                    state <= LATCH_DATA;
                                else
                                    byte_idx <= byte_idx + 1;
                                end if;
                            else
                                bit_idx <= bit_idx - 1;
                            end if;
                        end if;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when LATCH_DATA =>
                    data_valid <= '1';
                    cs_n       <= '1';
                    spi_clk    <= '0';
                    state      <= DESELECT;

                when DESELECT =>
                    data_valid <= '0';
                    -- Guard time: hold CS HIGH before starting next sequence
                    if clk_cnt = SCLK_DIV * 4 then
                        clk_cnt <= 0;
                        state   <= IDLE;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

            case;
        end if;
    end process;

    -- Reconstruct 10-bit ADC values from 8-bit Byte pairs
    pot0 <= raw_bytes(0)(1 downto 0) & raw_bytes(1);
    pot1 <= raw_bytes(2)(1 downto 0) & raw_bytes(3);
    pot2 <= raw_bytes(4)(1 downto 0) & raw_bytes(5);
    pot3 <= raw_bytes(6)(1 downto 0) & raw_bytes(7);

end architecture Behavioral;