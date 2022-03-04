--========================================================================================================================
-- Copyright (c) 2015 by Bitvis AS.  All rights reserved.
-- A free license is hereby granted, free of charge, to any person obtaining
-- a copy of this VHDL code and associated documentation files (for 'Bitvis Utility Library'),
-- to use, copy, modify, merge, publish and/or distribute - subject to the following conditions:
--  - This copyright notice shall be included as is in all copies or substantial portions of the code and documentation
--  - The files included in Bitvis Utility Library may only be used as a part of this library as a whole
--  - The License file may not be modified
--  - The calls in the code to the license file ('show_license') may not be removed or modified.
--  - No other conditions whatsoever may be added to those of this License

-- BITVIS UTILITY LIBRARY AND ANY PART THEREOF ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH BITVIS UTILITY LIBRARY.
--========================================================================================================================

------------------------------------------------------------------------------------------
-- VHDL unit     : Bitvis Utility Library : protected_types_pkg
--
-- Description   : See library quick reference (under 'doc') and README-file(s)
--                 Not supported by vhdl93
------------------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;


use work.types_pkg.all;
use work.adaptations_pkg.all;
use work.string_methods_pkg.all;

package protected_types_pkg is


  type t_protected_alert_attention_counters is protected
    procedure increment(
      alert_level   : t_alert_level;
      attention    : t_attention := REGARD;  -- count, expect, ignore
      number     : natural := 1
      );
    impure function get(
      alert_level: t_alert_level;
      attention    : t_attention := REGARD
      ) return natural;
    procedure to_string(
      order  : t_order
      );
  end protected t_protected_alert_attention_counters;


end package protected_types_pkg;

--=============================================================================
--=============================================================================

package body protected_types_pkg is


--------------------------------------------------------------------------------
  type t_protected_alert_attention_counters is protected body
    variable priv_alert_attention_counters : t_alert_attention_counters;

    procedure increment(
      alert_level: t_alert_level;
      attention    : t_attention := REGARD;
      number     : natural := 1
      ) is
    begin
      priv_alert_attention_counters(alert_level)(attention) := priv_alert_attention_counters(alert_level)(attention) + number;
    end;


    impure function get(
      alert_level: t_alert_level;
      attention    : t_attention := REGARD
      ) return natural is
    begin
      return priv_alert_attention_counters(alert_level)(attention);
    end;

    procedure to_string(
      order  : t_order
      ) is
    begin
      to_string(priv_alert_attention_counters, order);
    end;

  end protected body t_protected_alert_attention_counters;



end package body protected_types_pkg;
