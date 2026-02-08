-- tt_um_arthfink_ddmtd_single_file.vhd
--
-- Core: timestamp-based phase detector (DDMTD-style front-end)
-- - Asynchronous clk_ref and clk_fb are synchronized into clk_sys
-- - Rising edges are detected
-- - Each rising edge latches a free-running counter timestamp
-- - On each clk_fb edge, phase_err = t_fb - t_ref (wrap-safe signed)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tt_um_arthfink_ddmtd is
  generic (
    G_COUNTER_BITS  : positive := 24;  -- free-running timestamp counter width
    G_ERR_BITS      : positive := 18;  -- output bits for signed phase error (truncated/saturated)
    G_SYNC_STAGES   : positive := 2    -- synchronizer stages for async clocks (>=2 recommended)
  );
  port (
    clk_sys     : in  std_logic;
    rst_n       : in  std_logic;

    clk_ref     : in  std_logic; -- async to clk_sys
    clk_fb      : in  std_logic; -- async to clk_sys

    phase_valid : out std_logic;
    phase_err   : out signed(G_ERR_BITS-1 downto 0);

    -- Optional debug (can be removed later)
    dbg_edge_ref : out std_logic;
    dbg_edge_fb  : out std_logic
  );
end entity;

architecture rtl of tt_um_arthfink_ddmtd is

  -- Synchronizer shift registers
  subtype t_sync is std_logic_vector(G_SYNC_STAGES-1 downto 0);
  signal ref_sync : t_sync := (others => '0');
  signal fb_sync  : t_sync := (others => '0');

  -- Edge detect (in clk_sys domain)
  signal ref_sync_d : std_logic := '0';
  signal fb_sync_d  : std_logic := '0';
  signal edge_ref   : std_logic := '0';
  signal edge_fb    : std_logic := '0';

  -- Free-running counter
  signal cnt : unsigned(G_COUNTER_BITS-1 downto 0) := (others => '0');

  -- Timestamps
  signal t_ref : unsigned(G_COUNTER_BITS-1 downto 0) := (others => '0');
  signal t_fb  : unsigned(G_COUNTER_BITS-1 downto 0) := (others => '0');

  -- Raw modular difference (unsigned wrap-around)
  signal diff_u : unsigned(G_COUNTER_BITS-1 downto 0) := (others => '0');

  -- Signed mapping of modular difference into range [-2^(N-1), +2^(N-1)-1]
  -- We interpret diff_u as a signed value in two's complement with width G_COUNTER_BITS.
  -- This effectively maps values >= 2^(N-1) to negative.
  signal diff_s : signed(G_COUNTER_BITS-1 downto 0) := (others => '0');

  -- Output register
  signal phase_err_r   : signed(G_ERR_BITS-1 downto 0) := (others => '0');
  signal phase_valid_r : std_logic := '0';

  -- Helpers
  function sat_resize_signed(x : signed; w : positive) return signed is
    variable y : signed(w-1 downto 0);
    variable xw : integer := x'length;
    -- Saturation limits for width w
    variable maxv : signed(x'length-1 downto 0);
    variable minv : signed(x'length-1 downto 0);
  begin
    -- Build limits at x width
    maxv := (others => '0');
    maxv(maxv'left downto w) := (others => '0'); -- keep as 0 above w (not strictly needed)
    -- max for width w: 0b0 111..1
    maxv := to_signed(2**(w-1)-1, xw);
    minv := to_signed(-2**(w-1), xw);

    if x > maxv then
      y := to_signed(2**(w-1)-1, w);
    elsif x < minv then
      y := to_signed(-2**(w-1), w);
    else
      y := resize(x, w);
    end if;

    return y;
  end function;

begin

  phase_err   <= phase_err_r;
  phase_valid <= phase_valid_r;

  dbg_edge_ref <= edge_ref;
  dbg_edge_fb  <= edge_fb;

  p_main : process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      if rst_n = '0' then
        ref_sync      <= (others => '0');
        fb_sync       <= (others => '0');
        ref_sync_d    <= '0';
        fb_sync_d     <= '0';
        edge_ref      <= '0';
        edge_fb       <= '0';

        cnt           <= (others => '0');
        t_ref         <= (others => '0');
        t_fb          <= (others => '0');

        diff_u        <= (others => '0');
        diff_s        <= (others => '0');

        phase_err_r   <= (others => '0');
        phase_valid_r <= '0';

      else
        -- Free-running counter
        cnt <= cnt + 1;

        -- Synchronize async clocks into clk_sys
        ref_sync <= ref_sync(ref_sync'left-1 downto 0) & clk_ref;
        fb_sync  <= fb_sync(fb_sync'left-1 downto 0) & clk_fb;

        -- Edge detect using last stage of synchronizer
        ref_sync_d <= ref_sync(ref_sync'left);
        fb_sync_d  <= fb_sync(fb_sync'left);

        edge_ref <= ref_sync(ref_sync'left) and (not ref_sync_d);
        edge_fb  <= fb_sync(fb_sync'left)  and (not fb_sync_d);

        -- Default: no new output unless fb edge arrives
        phase_valid_r <= '0';

        -- Timestamp latching
        if edge_ref = '1' then
          t_ref <= cnt;
        end if;

        if edge_fb = '1' then
          t_fb   <= cnt;

          -- Compute modular difference using latest captured t_ref
          -- diff_u = t_fb - t_ref (wrap-around on underflow)
          diff_u <= cnt - t_ref;

          -- Interpret modular difference as signed two's complement
          diff_s <= signed(cnt - t_ref);

          -- Register output (saturated/truncated to G_ERR_BITS)
          phase_err_r   <= sat_resize_signed(signed(cnt - t_ref), G_ERR_BITS);
          phase_valid_r <= '1';
        end if;

      end if;
    end if;
  end process;

end architecture;

-------------------------------------------------------------------------------
-- Testbench (kept in same file). Remove or ignore for synthesis.
-------------------------------------------------------------------------------
-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_tt_um_arthfink_ddmtd is
end entity;

architecture tb of tb_tt_um_arthfink_ddmtd is
  constant C_COUNTER_BITS : positive := 16;
  constant C_ERR_BITS     : positive := 12;

  signal clk_sys     : std_logic := '0';
  signal rst_n       : std_logic := '0';
  signal clk_ref     : std_logic := '0';
  signal clk_fb      : std_logic := '0';

  signal phase_valid : std_logic;
  signal phase_err   : signed(C_ERR_BITS-1 downto 0);

  signal dbg_edge_ref : std_logic;
  signal dbg_edge_fb  : std_logic;

  -- Clocks
  constant T_SYS : time := 10 ns;   -- 100 MHz
  constant T_REF : time := 37 ns;   -- ~27 MHz (async-ish)
  constant T_FB  : time := 41 ns;   -- ~24 MHz (async-ish)

begin

  dut : entity work.tt_um_arthfink_ddmtd
    generic map (
      G_COUNTER_BITS => C_COUNTER_BITS,
      G_ERR_BITS     => C_ERR_BITS,
      G_SYNC_STAGES  => 2
    )
    port map (
      clk_sys      => clk_sys,
      rst_n        => rst_n,
      clk_ref      => clk_ref,
      clk_fb       => clk_fb,
      phase_valid  => phase_valid,
      phase_err    => phase_err,
      dbg_edge_ref => dbg_edge_ref,
      dbg_edge_fb  => dbg_edge_fb
    );

  -- clk_sys
  p_sys : process
  begin
    clk_sys <= '0'; wait for T_SYS/2;
    clk_sys <= '1'; wait for T_SYS/2;
  end process;

  -- clk_ref (independent)
  p_ref : process
  begin
    wait for 13 ns; -- initial phase offset
    loop
      clk_ref <= '0'; wait for T_REF/2;
      clk_ref <= '1'; wait for T_REF/2;
    end loop;
  end process;

  -- clk_fb (independent)
  p_fb : process
  begin
    wait for 7 ns; -- different initial phase offset
    loop
      clk_fb <= '0'; wait for T_FB/2;
      clk_fb <= '1'; wait for T_FB/2;
    end loop;
  end process;

  -- Reset
  p_rst : process
  begin
    rst_n <= '0';
    wait for 200 ns;
    rst_n <= '1';
    wait;
  end process;

  -- Simple monitor
  p_mon : process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      if phase_valid = '1' then
        report "phase_err = " & integer'image(to_integer(phase_err));
      end if;
    end if;
  end process;

  -- Stop
  p_stop : process
  begin
    wait for 20 us;
    report "TB done." severity failure;
  end process;

end architecture;

-- synthesis translate_on
