-- Ramp Generator - Goal IV (WCC) TM-035 Figure 11, Players Circuit
-- Digital model of the analog ramp: transistor Q6, 256V, (V ENABLE * !128V), R26/C8.
-- Manual: When (V ENABLE * !128V) is low, C8 charges -> ramp up. When 256V high, Q6 discharges C8 -> reset.
-- Charge enable = NOT(V_ENABLE AND V128n) = NAND(V_ENABLE, V128n) per schematic.
-- Digital model: increment once per scanline (HSYNC), not per pixel. This models the slow
-- analog RC charge that sweeps across the vertical field. RAMP_VALUE for comparators.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PlayersRampGenerator is
    Port (
        HSYNC      : in  STD_LOGIC;   -- Once per scanline (ramp steps per line, not per pixel)
        V256       : in  STD_LOGIC;
        V_ENABLE   : in  STD_LOGIC;
        V128n      : in  STD_LOGIC;   -- !128V: high in upper half, low in lower half
        RAMP_VALUE : out STD_LOGIC_VECTOR(9 downto 0)
    );
end PlayersRampGenerator;

architecture Schematic of PlayersRampGenerator is
    -- Charge when (V ENABLE * !128V) is low => charge_enable = NAND(V_ENABLE, V128n)
    signal charge_enable : STD_LOGIC;
    signal ramp_u        : UNSIGNED(9 downto 0) := (others => '0');
begin
    -- Form charge enable per schematic NAND gate
    -- High when we should charge: V_ENABLE=0 OR V128n=0 (lower half)
    -- No charge only when V_ENABLE=1 AND V128n=1 (upper half of active area)
    U_NAND_CHARGE: entity work.LS00
        port map(
            P1_A1   => V_ENABLE,
            P2_B1   => V128n,
            P3_Y1   => charge_enable,
            P4_A2   => '1', P5_B2 => '1', P6_Y2 => open,
            P9_A3   => '1', P10_B3 => '1', P11_Y4 => open, P12_A4 => '1', P13_B4 => '1',
            P8_Y3   => open
        );

    -- Ramp counter: reset when 256V high, increment on HSYNC when charge_enable
    -- Extended for defense: also increment when V256=0 so column can span full frame (allows larger INITIAL_GAP to push defensemen lower)
    process (HSYNC)
    begin
        if rising_edge(HSYNC) then
            if V256 = '1' then
                ramp_u <= (others => '0');
            elsif charge_enable = '1' or V256 = '0' then
                ramp_u <= ramp_u + 1;
            end if;
        end if;
    end process;

    RAMP_VALUE <= STD_LOGIC_VECTOR(ramp_u);
end Schematic;
