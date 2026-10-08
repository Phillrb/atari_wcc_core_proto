-- ATtiny84 controls bridge: FPGA board boundary, not an original TM-035 IC.
-- SPI master, mode 0, MSB first; eight bytes, high/low per ADC channel.
-- CH0=solid defense, CH1=solid forwards, CH2=checks defense, CH3=checks forwards.
-- Preserve ATtiny interrupt service time: >=100 us CS setup/inter-byte/end hold.
-- Complete valid packets are scaled/clamped and published together at VSYNC.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPIAdapter is
    generic (
        CLOCK_HZ : positive := 7142857;
        SPI_HZ : positive := 125000;
        STARTUP_CLOCKS : positive := 714286; -- 100 ms
        PAUSE_CLOCKS : positive := 715; -- >=100 us
        POLL_CLOCKS : positive := 35714; -- 5 ms with CS high
        SD_ADC_MIN : natural := 700; SD_ADC_MAX : natural := 1023;
        SF_ADC_MIN : natural := 700; SF_ADC_MAX : natural := 1023;
        CD_ADC_MIN : natural := 700; CD_ADC_MAX : natural := 1023;
        CF_ADC_MIN : natural := 700; CF_ADC_MAX : natural := 1023;
        DEF_TOP : natural := 10; DEF_BOTTOM : natural := 82;
        FWD_TOP : natural := 82; FWD_BOTTOM : natural := 154;
        SD_REVERSE : boolean := false; SF_REVERSE : boolean := false;
        CD_REVERSE : boolean := false; CF_REVERSE : boolean := false
    );
    port (
        CLK, RESETn, FRAME_SYNC : in std_logic;
        SPI_MISO : in std_logic;
        SPI_SCLK, SPI_CSn, SPI_MOSI : out std_logic;
        SOLID_DEF, SOLID_FWD, CHECKS_DEF, CHECKS_FWD : out std_logic_vector(9 downto 0);
        RAW_SD, RAW_SF, RAW_CD, RAW_CF : out std_logic_vector(9 downto 0);
        PACKET_VALID, PACKET_ERROR : out std_logic
    );
end SPIAdapter;

architecture BoardAdapter of SPIAdapter is
    constant HALF_CLOCKS : positive := (CLOCK_HZ + 2*SPI_HZ-1)/(2*SPI_HZ);
    type state_type is (BOOT, CS_SETUP, CLOCK_LOW, CLOCK_HIGH, BYTE_PAUSE, END_HOLD, IDLE);
    signal state : state_type := BOOT;
    signal delay_count : natural := 0;
    signal bit_index : natural range 0 to 63 := 63;
    signal rx : std_logic_vector(63 downto 0) := (others=>'0');
    signal miso_meta, miso_sync : std_logic := '1';
    signal reset_pipe : std_logic_vector(1 downto 0) := "00";
    signal previous_frame : std_logic := '0';
    type values is array(0 to 3) of std_logic_vector(9 downto 0);
    constant CENTRE : values := (
        std_logic_vector(to_unsigned((DEF_TOP+DEF_BOTTOM)/2,10)),
        std_logic_vector(to_unsigned((FWD_TOP+FWD_BOTTOM)/2,10)),
        std_logic_vector(to_unsigned((DEF_TOP+DEF_BOTTOM)/2,10)),
        std_logic_vector(to_unsigned((FWD_TOP+FWD_BOTTOM)/2,10)));
    signal pending, position : values := CENTRE;
    signal raw : values := (others=>(others=>'0'));
    attribute altera_attribute : string;
    attribute altera_attribute of miso_meta, miso_sync, reset_pipe : signal is
        "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";

    function scale(value, low_adc, high_adc, top_pos, bottom_pos : natural;
                   reverse_direction : boolean) return std_logic_vector is
        variable clipped, offset : natural;
    begin
        if value < low_adc then clipped := low_adc;
        elsif value > high_adc then clipped := high_adc;
        else clipped := value; end if;
        offset := ((clipped-low_adc)*(bottom_pos-top_pos)+(high_adc-low_adc)/2)/(high_adc-low_adc);
        if reverse_direction then return std_logic_vector(to_unsigned(bottom_pos-offset,10));
        else return std_logic_vector(to_unsigned(top_pos+offset,10)); end if;
    end;

    function valid_packet(packet : std_logic_vector(63 downto 0)) return boolean is
    begin
        for i in packet'range loop
            if packet(i)/='0' and packet(i)/='1' then return false; end if;
        end loop;
        for channel in 0 to 3 loop
            if packet(63-16*channel downto 58-16*channel)/="000000" then return false; end if;
        end loop;
        return true;
    end;
begin
    assert HALF_CLOCKS >= 4 report "SPI clock too fast for input synchronizer" severity failure;
    assert SD_ADC_MIN < SD_ADC_MAX and SD_ADC_MAX <= 1023 and
           SF_ADC_MIN < SF_ADC_MAX and SF_ADC_MAX <= 1023 and
           CD_ADC_MIN < CD_ADC_MAX and CD_ADC_MAX <= 1023 and
           CF_ADC_MIN < CF_ADC_MAX and CF_ADC_MAX <= 1023
        report "Invalid ADC calibration" severity failure;
    assert DEF_TOP < DEF_BOTTOM and DEF_BOTTOM <= 1023 and
           FWD_TOP < FWD_BOTTOM and FWD_BOTTOM <= 1023
        report "Invalid player travel limits" severity failure;
    SPI_MOSI <= '0'; -- Dummy bytes; ATtiny sends its ADC snapshot independently.
    SOLID_DEF<=position(0); SOLID_FWD<=position(1);
    CHECKS_DEF<=position(2); CHECKS_FWD<=position(3);
    RAW_SD<=raw(0); RAW_SF<=raw(1); RAW_CD<=raw(2); RAW_CF<=raw(3);

    process(CLK, RESETn)
    begin
        if RESETn='0' then reset_pipe<="00";
        elsif rising_edge(CLK) then reset_pipe<=reset_pipe(0)&'1'; end if;
    end process;

    process(CLK)
    begin
        if rising_edge(CLK) then
            miso_meta<=SPI_MISO; miso_sync<=miso_meta;
            PACKET_VALID<='0'; PACKET_ERROR<='0';
            if reset_pipe(1)='0' then
                state<=BOOT; delay_count<=0; bit_index<=63;
                SPI_CSn<='1'; SPI_SCLK<='0'; rx<=(others=>'0');
                pending<=CENTRE; position<=CENTRE; raw<=(others=>(others=>'0'));
                previous_frame<=FRAME_SYNC;
            else
                previous_frame<=FRAME_SYNC;
                if FRAME_SYNC='1' and previous_frame='0' then position<=pending; end if;
                case state is
                    when BOOT =>
                        if delay_count=STARTUP_CLOCKS-1 then
                            delay_count<=0; SPI_CSn<='0'; state<=CS_SETUP;
                        else delay_count<=delay_count+1; end if;
                    when CS_SETUP =>
                        if delay_count=PAUSE_CLOCKS-1 then
                            delay_count<=0; bit_index<=63; state<=CLOCK_LOW;
                        else delay_count<=delay_count+1; end if;
                    when CLOCK_LOW =>
                        if delay_count=HALF_CLOCKS-1 then
                            delay_count<=0; SPI_SCLK<='1'; rx(bit_index)<=miso_sync; state<=CLOCK_HIGH;
                        else delay_count<=delay_count+1; end if;
                    when CLOCK_HIGH =>
                        if delay_count=HALF_CLOCKS-1 then
                            delay_count<=0; SPI_SCLK<='0';
                            -- Always deliver the final falling edge: ATtiny USI
                            -- counts BOTH edges and requires all 16 per byte.
                            if bit_index=0 then state<=END_HOLD;
                            elsif bit_index mod 8=0 then bit_index<=bit_index-1; state<=BYTE_PAUSE;
                            else bit_index<=bit_index-1; state<=CLOCK_LOW; end if;
                        else delay_count<=delay_count+1; end if;
                    when BYTE_PAUSE =>
                        if delay_count=PAUSE_CLOCKS-1 then delay_count<=0; state<=CLOCK_LOW;
                        else delay_count<=delay_count+1; end if;
                    when END_HOLD =>
                        if delay_count=PAUSE_CLOCKS-1 then
                            delay_count<=0; SPI_CSn<='1'; state<=IDLE;
                            if valid_packet(rx) then
                                for c in 0 to 3 loop raw(c)<=rx(57-16*c downto 48-16*c); end loop;
                                pending(0)<=scale(to_integer(unsigned(rx(57 downto 48))),SD_ADC_MIN,SD_ADC_MAX,DEF_TOP,DEF_BOTTOM,SD_REVERSE);
                                pending(1)<=scale(to_integer(unsigned(rx(41 downto 32))),SF_ADC_MIN,SF_ADC_MAX,FWD_TOP,FWD_BOTTOM,SF_REVERSE);
                                pending(2)<=scale(to_integer(unsigned(rx(25 downto 16))),CD_ADC_MIN,CD_ADC_MAX,DEF_TOP,DEF_BOTTOM,CD_REVERSE);
                                pending(3)<=scale(to_integer(unsigned(rx(9 downto 0))),CF_ADC_MIN,CF_ADC_MAX,FWD_TOP,FWD_BOTTOM,CF_REVERSE);
                                PACKET_VALID<='1';
                            else PACKET_ERROR<='1'; end if;
                        else delay_count<=delay_count+1; end if;
                    when IDLE =>
                        if delay_count=POLL_CLOCKS-1 then
                            delay_count<=0; SPI_CSn<='0'; state<=CS_SETUP;
                        else delay_count<=delay_count+1; end if;
                end case;
            end if;
        end if;
    end process;
end BoardAdapter;
