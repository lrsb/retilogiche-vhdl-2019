library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity project_reti_logiche is
    port (
        i_clk, i_start, i_rst : in std_logic;
        i_data                : in std_logic_vector(7 downto 0);
        o_address             : out std_logic_vector(15 downto 0);
        o_done, o_en, o_we    : out std_logic;
        o_data                : out std_logic_vector(7 downto 0)
    );
end entity;

architecture behavioral of project_reti_logiche is
    type t_state is (fs, w_clock, r_mask, r_x, r_y, done);
    signal state : t_state := fs;
begin
    process (i_clk, i_start, i_rst, state)
    variable step : natural range 0 to 8;
    variable i_mask, o_mask, c_x, c_y, x : std_logic_vector(7 downto 0);
    variable min_distance : natural range 0 to 511;
    begin
        if i_rst = '1' then
            state <= w_clock;
            step := 8;
            min_distance := 511;
            o_address <= (others => '0');
            o_done <= '0';
            o_en <= '0';
            o_we <= '0';
        elsif i_start = '0' then o_done <= '0';
        elsif falling_edge(i_clk) and state /= fs then
            o_en <= '1';
            case state is
                when w_clock => state <= r_mask;
                when r_mask =>
                    if unsigned(i_data and std_logic_vector(signed(i_data) - 1)) = 0 then
                        o_data <= i_data;
                        o_address <= std_logic_vector(to_unsigned(19, 16));
                        o_we <= '1';
                        state <= done;
                    else
                        i_mask := i_data;
                        o_address <= std_logic_vector(to_unsigned(17, 16));
                        state <= r_x;
                    end if;
                when r_x =>
                    if step < 8 then x := i_data;
                    else c_x := i_data;
                    end if;
                    o_address <= std_logic_vector(to_unsigned(step * 2 + 2, 16));
                    state <= r_y;
                when r_y =>
                    if step < 8 then
                        if abs(to_integer(unsigned(x)) - to_integer(unsigned(c_x))) + abs(to_integer(unsigned(i_data)) - to_integer(unsigned(c_y))) < min_distance then
                            min_distance := abs(to_integer(unsigned(x)) - to_integer(unsigned(c_x))) + abs(to_integer(unsigned(i_data)) - to_integer(unsigned(c_y)));
                            o_mask := std_logic_vector(to_unsigned(2 ** step, 8));
                        elsif abs(to_integer(unsigned(x)) - to_integer(unsigned(c_x))) + abs(to_integer(unsigned(i_data)) - to_integer(unsigned(c_y))) = min_distance then o_mask(step) := '1';
                        end if;
                        if step < 7 then step := step + 1;
                        else step := 8;
                        end if;
                    else
                        c_y := i_data;
                        step := 0;
                    end if;
                    for i in 0 to 6 loop
                        if step < 8 and i_mask(step) = '0' then step := step + 1;
                        else exit;
                        end if;
                    end loop;
                    if step < 8 then
                        o_address <= std_logic_vector(to_unsigned(step * 2 + 1, 16));
                        state <= r_x;
                    else
                        o_data <= o_mask;
                        o_address <= std_logic_vector(to_unsigned(19, 16));
                        o_we <= '1';
                        state <= done;
                    end if;
                when done =>
                    state <= w_clock;
                    step := 8;
                    min_distance := 511;
                    o_address <= (others => '0');
                    o_done <= '1';
                    o_en <= '0';
                    o_we <= '0';
                when others =>
            end case;
        end if;
    end process;
end architecture;
