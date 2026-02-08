library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ddmtd_core is
  port (
    clk_sys     : in  std_logic;
    rst_n       : in  std_logic;

    clk_ref     : in  std_logic; -- async to clk_sys
    clk_fb      : in  std_logic; -- async to clk_sys

    phase_valid : out std_logic;
    phase_err   : out signed(17 downto 0);  -- fixed width for synthesis

    dbg_edge_ref : out std_logic;
    dbg_edge_fb  : out std_logic
  );
end entity;

architecture rtl of ddmtd_core is

  constant C_COUNTER_BITS : positive := 24;
  constant C_ERR_BITS     : positive := 18;
  constant C_SYNC_STAGES  : positive := 2;

  subtype t_sync is std_logic_vector(C_SYNC_STAGES-1 downto 0);

  signal ref_sync : t_sync := (others => '0');
  signal fb_sync  : t_sync := (others => '0');

  signal ref_sync_d : std_logic := '0';
  signal fb_sync_d  : std_logic := '0';
  signal edge_ref   : std_logic := '0';
  signal edge_fb    : std_logic := '0';

  signal cnt : unsigned(C_COUNTER_BITS-1 downto 0) := (others => '0');
  signal t_ref : unsigned(C_COUNTER_BITS-1 downto 0) := (others => '0');

  signal phase_err_r   : signed(C_ERR_BITS-1 downto 0) := (others => '0');
  signal phase_valid_r : std_logic := '0';

  function sat_resize_signed(x : signed; w : positive) return signed is
    variable y    : signed(w-1 downto 0);
    variable maxv : signed(x'length-1 downto 0);
    variable minv : signed(x'length-1 downto 0);
  begin
    maxv := to_signed(2**(w-1)-1, x'length);
    minv := to_signed(-2**(w-1),   x'length);

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

  process(clk_sys)
    variable diff : signed(C_COUNTER_BITS-1 downto 0);
  begin
    if rising_edge(clk_sys) then
      if rst_n = '0' then
        ref_sync <= (others => '0');
        fb_sync  <= (others => '0');
        ref_sync_d <= '0';
        fb_sync_d  <= '0';
        edge_ref <= '0';
        edge_fb  <= '0';

        cnt <= (others => '0');
        t_ref <= (others => '0');

        phase_err_r <= (others => '0');
        phase_valid_r <= '0';
      else
        cnt <= cnt + 1;

        ref_sync <= ref_sync(ref_sync'left-1 downto 0) & clk_ref;
        fb_sync  <= fb_sync(fb_sync'left-1 downto 0) & clk_fb;

        ref_sync_d <= ref_sync(ref_sync'left);
        fb_sync_d  <= fb_sync(fb_sync'left);

        edge_ref <= ref_sync(ref_sync'left) and (not ref_sync_d);
        edge_fb  <= fb_sync(fb_sync'left)  and (not fb_sync_d);

        phase_valid_r <= '0';

        if edge_ref = '1' then
          t_ref <= cnt;
        end if;

        if edge_fb = '1' then
          diff := signed(cnt - t_ref);
          phase_err_r   <= sat_resize_signed(diff, C_ERR_BITS);
          phase_valid_r <= '1';
        end if;
      end if;
    end if;
  end process;

end architecture;
