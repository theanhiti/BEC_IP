----------------------------------------------------------------------------
-- Scalar Multiplier using Binary Edward Curves (sm_bec.vhd)
--
-- Following the algorithm of Koziel et al. in https://scholarworks.rit.edu/cgi/viewcontent.cgi?article=10293&context=theses 
-- 
-- Bit-Parallel 
-----------------------------------
-- 
-----------------------------------
library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.acb_package.all;

entity sm_bec is
    port (
        clk, rst, enable: in std_logic;
        w1,z1   : in std_logic_vector(M-1 downto 0);
        w2,z2   : in std_logic_vector(M-1 downto 0);
        ki      : in std_logic;

        -- Constant parameters --
        d, inv_w0: in std_logic_vector(M-1 downto 0);

        -- Output pins --
        next_key : out std_logic;
        done     : out std_logic;
        wout, zout: out std_logic_vector(M-1 downto 0)
    );
end entity sm_bec;

architecture rtl of sm_bec is
    -- Define the States
    type st is (idle, st1, st2, st3, st4, st5, st6, st_done);
    signal current_state, next_state : st;

    -- Data registers for storage of wAdd, zAdd, wDouble, and zDouble.
    signal regA, regB, regC, regD    : std_logic_vector (M-1 downto 0);

    signal reg_key_iter              : std_logic_vector(7 downto 0);         
    signal next_round, config        : std_logic;
    signal local_enable              : std_logic;
    signal inACB_1, inACB_2, outACB  : std_logic_vector(M-1 downto 0);
    -- Control signal for next state in each key iteration. Next_round register will be high when reg_cnt = M-1 and be low when others.
    
    signal done_loop : std_logic;

    component acb is
        port (
            clk, rst, enable, config: in std_logic;
            A, B: in std_logic_vector(M-1 downto 0);
            C: out std_logic_vector(M-1 downto 0);
            done: out std_logic
        );
    end component;

begin
    U1: acb
    port map (
        clk => clk,
        rst => rst,
        enable => local_enable,
        A   => inACB_1,
        B   => inACB_2,
        C   => outACB,
        config => config,
        done => next_round
    );
    next_key <= done_loop;
    done_loop <= '1' when current_state = st_done else '0';
    wout <= regA when ((reg_key_iter = M -1) and current_state = st_done) else (others => '0');
    zout <= regB when ((reg_key_iter = M -1) and current_state = st_done) else (others => '0');
    done <= '1' when ((reg_key_iter = M -1) and current_state = st_done) else '0';
    -- local_enable <= not(next_round);
    

    shift_state: process (rst, clk)
    begin
        if (rst ='1') then
            current_state <= idle;
        elsif (rising_edge(clk)) then
            current_state <= next_state;
        end if;
    end process;

    fsm_process: process(enable, next_round)
    begin
        if enable = '1' then
            case current_state is
                when idle =>
                    if (next_round = '1') then
                        next_state <= st1;
                    else
                        next_state <= idle;
                    end if;
                when st1 =>
                    if (next_round = '1') then
                        next_state <= st2;
                    else
                        next_state <= st1;
                    end if;
                when st2 =>  
                    if (next_round = '1') then
                        next_state <= st3;
                    else
                        next_state <= st2;
                    end if;
                when st3 =>
                    if (next_round = '1') then
                        next_state <= st4;
                    else
                        next_state <= st3;
                    end if;
                when st4 =>
                    if (next_round = '1') then
                        next_state <= st5;
                    else
                        next_state <= st4;
                    end if;
                when st5 =>
                    if (next_round = '1') then
                        next_state <= st6;
                    else
                        next_state <= st5;
                    end if;
                when st6 =>
                    if (next_round = '1') then
                        next_state <= st_done;
                    else
                        next_state <= st6;
                    end if;
                when st_done =>
                    next_state <= idle;
            end case;
        else
            next_state <= idle;
        end if;
    end process;

    data_path_out_acb: process(clk, rst, enable, current_state, next_round)
    begin
        if (rst = '1') then
            regA    <= (others => '0');
            regB    <= (others => '0');
            regC    <= (others => '0');
            regD    <= (others => '0');
            
            -- wout    <= (others => '0');
            -- zout    <= (others => '0');

        elsif rising_edge (clk) then
            if (enable = '1') then
                if (next_round = '1') then
                    case current_state is
                        when idle =>
                            if (reg_key_iter = 0) then
                                if (ki = '1') then
                                    regA <= outACB;                 -- Init register in the first loop of point multiplication
                                    regB <= z1;
                                    regC <= w2;
                                    regD <= z2;
                                else
                                    regA <= w1;                 -- Init register in the first loop of point multiplication
                                    regB <= z1;
                                    regC <= outACB;
                                    regD <= z2;
                                end if;
                            else
                                if (ki = '1') then
                                    regA <= outACB;
                                else
                                    regC <= outACB;
                                end if;
                            end if;
                        when st1 =>
                            if (ki ='0') then
                                regC <= regC xor outACB;
                            else
                                regA <= regA xor outACB;
                            end if;
                        when st2 =>                  
                            if (ki = '1') then
                                regB <= outACB;
                            else
                                regD <= outACB;
                            end if;
                        when st3 =>
                            if (ki = '1') then
                                regA    <= regA xor outACB;
                                regB    <= regB xor outACB;
                            else
                                regC    <= regC xor outACB;
                                regD    <= regD xor outACB;
                            end if;
                        ------------------------
                        -- Point Doubling
                        ------------------------
                        when st4 =>
                            if (ki = '1') then
                                regC <= outACB;
                            else
                                regA <= outACB;
                            end if;
                        when st5 =>
                            if (ki = '1') then
                                regD <= outACB;
                            else
                                regB <= outACB;
                            end if;
                        when st6 =>
                            if (ki = '1') then
                                regD <= regC xor outACB;
                                -- wout <= regA;
                                -- zout <= regB;
                            else
                                regB <= regA xor outACB;
                                -- wout <= regC;
                                -- zout <= regD;
                            end if;
                            
                        when st_done =>
                        when others =>         
                    end case;
                end if;
            else
                regA <= (others => '0');
                regB <= (others => '0');
                regC <= (others => '0');
                regD <= (others => '0');
                -- wout <= (others => '0');
                -- zout <= (others => '0');
            end if;
        end if;
    end process;
    
    config <= '1' when (current_state = st3 or current_state = st6) else '0';

    data_path_in_acb: process(clk, rst, current_state, local_enable)
    begin
        if (rst = '1') then
            inACB_1 <= (others => '0');
            inACB_2 <= (others => '0');
        elsif rising_edge(clk) then
            if local_enable = '1' then
                case current_state is
                    when idle =>
                        if (reg_key_iter = 0) then
                            if(ki = '1') then
                                inACB_1 <= w1;
                                inACB_2 <= z2;
                            else
                                inACB_1 <= w2;
                                inACB_2 <= z1;
                            end if;
                        else
                            if(ki = '1') then
                                inACB_1 <= regA;
                                inACB_2 <= regD;
                            else
                                inACB_1 <= regC;
                                inACB_2 <= regB;
                            end if;
                        end if;
                    when st1 =>
                        if (ki = '1') then
                            inACB_1 <= regB;
                            inACB_2 <= regC;
                        else
                            inACB_1 <= regA;
                            inACB_2 <= regD;
                        end if;
                    when st2 =>
                        inACB_1 <= regB;            -- (z1*z2)^2
                        inACB_2 <= regD;
                    when st3 =>
                        inACB_1 <= inv_w0;
                        if (ki = '1') then
                            inACB_2 <= regA;
                        else
                            inACB_2 <= regC;
                        end if;
                    when st4 => 
                        if (ki = '1') then
                            inACB_1 <= regC;
                            inACB_2 <= regC xor regD;    
                        else
                            inACB_1 <= regA;
                            inACB_2 <= regA xor regB;
                        end if;
                    when st5 =>
                        if (ki = '1') then
                            inACB_1 <= regD;
                            inACB_2 <= regD;
                        else
                            inACB_1 <= regB;
                            inACB_2 <= regB;
                        end if;
                    when st6 =>
                        inACB_1 <= d;
                        if (ki = '1') then
                            inACB_2 <= regD;
                        else
                            inACB_2 <= regB;
                        end if;

                    when others =>
                        inACB_1 <= (others => '0');
                        inACB_2 <= (others => '0');
                end case;
            else
                inACB_1 <= (others => '0');
                inACB_2 <= (others => '0');
            end if;
        end if;
    end process;

    no_loop: process (rst, clk, enable, done_loop)
    begin
        if (rst = '1') then
            reg_key_iter <= (others => '0');
            local_enable <= '0';
        elsif rising_edge (clk) then
            if (enable = '1') then
                local_enable <= not(next_round);
                if (done_loop = '1') then
                    if (reg_key_iter < M) then
                        reg_key_iter <= reg_key_iter + 1;
                    else
                        reg_key_iter <= (others => '0');
                    end if;
                else
                    reg_key_iter <= reg_key_iter;
                end if;
            else
                local_enable <= '0';

                reg_key_iter <= (others => '0');
            end if;
        end if;
    end process;
end architecture rtl;
