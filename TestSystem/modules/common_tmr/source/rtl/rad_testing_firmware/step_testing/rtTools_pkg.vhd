-------------------------------------------------------------------------------
-- Title      : rtTools_pkg
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : rtTools_pkg.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-02-29
-- Last update: 2016-05-20
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: package containing SIMULATION ONLY support functions and data
-- structures to simulate SEU/SETI in the logic components. Requires ModelSim
-- 10.3 or higher to be correctly compiled.
--
-- GENERICS: 
--   -> 'CS_MODE' defines specific simulation parameters, set to '0' to
--      disable any error generation..
--   -> 'CS_ERR_CLKS_INTERVAL' defines the average number of clocks between 
--      two errors in the unit.
--   -> 'CS_ERR_CLKS_LENGTH' defines the average number of clocks an error 
--      lasts.
--   -> 'CS_ERR_TARGET' defines which units are affected by the error, i.e.
--      the unit check whether the 'CS_ERR_WHERE_ID' matches its own 'C_ID',
--      and in case forces its output signal to generate the error.
--   -> 'C_WIDTH' defines the width of the std_logic_vector which has to be
--      affected by the error. 
--
-- PROTECTED STRUCTURES: 
--   -> 'cErr' (used only during simulation) defines specific simulation
--      parameters
--
--
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version     Author		Description
-- 2016-01-29   1.0         Piero		Created
------------------------------------------------------------------------------- 

--------------------------
-- SYNTHESIS TRANSLATE_OFF
--------------------------

-- Libraries.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;


--------------------------------------------------------------------------------
--                            Package Declaration                             --
--------------------------------------------------------------------------------
package rtTools_pkg is
	
	-- Generics.
	generic (
        CS_MODE : integer := 0;                 -- Simulation mode (0 = disable error injection).
        CS_ERR_TARGET : integer := 0;           -- Error injection target ID.
        CS_ERR_CLKS_INTERVAL : natural := 0;    -- Average clocks between errors.
        CS_ERR_CLKS_LENGTH : natural := 0;      -- Average error duration.  
        C_WIDTH : natural := 6                  -- Width of the signal to affect.
    );
	
	-- Protected (structure) 'tErr' declaration. 'tErr' is a small pseudo-error
    -- generator used to simulate SEU in the CLB output.
    type tErr is protected
         procedure reset;-- Reset the error condition to default.
         procedure clk;-- Advance the clock counter by one.                      
         impure function rndUniform(max, min: integer) return integer;    -- Generate an integer random number with uniform distribution.                   
         impure function rndNormal(avg: integer) return integer;   -- Generate an integer random number with Gaussian distribution.                   
         impure function rndBit return std_logic;               -- Returns a random bit.
         impure function rndVector return std_logic_vector;     -- Returns a 'C_WIDTH' long random vector.
         impure function rndError(input : std_logic_vector(C_WIDTH - 1 downto 0)) return std_logic_vector; -- Generates an error vector from a correct input one by swapping one random bit.
         impure function flag(target : integer) return boolean; -- Returns whether an error conditon is ongoing.                  
         function mode(target : integer) return integer;        -- Returns the current simulation mode ('CS_MODE').
    end protected tErr;
        
end rtTools_pkg;

--------------------------------------------------------------------------------
--                                Package Body                                --
--------------------------------------------------------------------------------

package body rtTools_pkg is
    
    -- Protected (structure) 'tErr' body.
    type tErr is protected body
        
        -- Local protected variables.
        variable vSeed1, vSeed2: positive;      -- Seeds used by the uniform() distribution call.  
        variable rndClksInterval : integer := CS_ERR_CLKS_INTERVAL; 
        variable rndClksLength : integer := CS_ERR_CLKS_LENGTH;
        variable clkCount : integer := 0;
        variable errFlag : boolean := false;
        variable errBitID : integer range 0 to C_WIDTH - 1 := 0;
                                            
        -- Reset the error structure to its default (no error, all counters to zero).
        procedure reset is begin
            clkCount := 0;
            errFlag := false;
        end procedure reset;
        
        -- 'rnd' generates a integer in the [min , max[ interval. The 'vSeed1' and 'vSeed2'
        -- seeds are defined as variables within the 'tErr' structure to retain their values
        -- between calls to the 'rnd' function, otherwise always the same random number
        -- would be generated.
        impure function rndUniform(max, min: integer) return integer is
            variable rndVal: real;
        begin
            uniform(vSeed1, vSeed2, rndVal);
            return integer(trunc(real(min) + rndVal * real(max - min)));
        end rndUniform;
                
        -- 'rndNormal' generates integer random numbers with a Gaussian 
        -- distribution centered on 'avg'.
        impure function rndNormal(avg: integer) return integer is
            constant C_COUNT: integer := 20;
            variable rndSum: real := 0.0;
            variable rndVal: real;
        begin
            for i in 0 to (C_COUNT - 1) loop
                uniform(vSeed1, vSeed2, rndVal);
                rndSum := rndSum + (rndVal * real(avg) * 2.0);
            end loop;
            return integer(trunc(rndSum / real(C_COUNT)));        
        end rndNormal;
        
        -- 'rndBit' generates a random bit. 
        impure function rndBit return std_logic is
        begin
            if (rndUniform(0, 9) < 5) then
                return '0';
            else
                return '1';
            end if;        
         end rndBit;
                
        -- 'rndVector' generates a 'C_WIDTH' long vector filled with pseudo-random bit values. 
        impure function rndVector return std_logic_vector is
            variable output : std_logic_vector(C_WIDTH - 1 downto 0);
        begin
            for i in 0 to (C_WIDTH - 1) loop
                output(i) := rndBit;
            end loop;
            return output;        
        end rndVector;
                
        -- 'clk' switches the error condition on and off based on the 
        -- 'CS_ERR_CLKS_INTERVAL' and 'CS_ERR_CLKS_LENGTH genercis'. 
        procedure clk is begin    
            
            -- Wait for the error condition.
            if (errFlag = false) then
                if (clkCount >= rndClksInterval) then
                    clkCount := 0;
                    errFlag := true;
                    errBitID := rndUniform(0, C_WIDTH);
                else
                    clkCount := clkCount + 1;
                end if;
            else
                -- End of error condition.
                if (clkCount >= rndClksLength) then
                    
                    -- Reset error condition flag.
                    clkCount := 0;
                    errFlag := false;
                    
                    -- Set new pseudo-random clock interval and length.
                    rndClksInterval := rndNormal(CS_ERR_CLKS_INTERVAL);
                    rndClkslength := rndNormal(CS_ERR_CLKS_LENGTH);
                
                -- On error condition, simply count.
                else
                    clkCount := clkCount + 1;
                end if;
            end if;
        end procedure clk;
        
        -- Generates a 'wrong' signal by randomly swithcing one bit of the original signal.
        -- The seed used for the random bit selection is updated at every 'errFlag' switch,
        -- so the bit affected remains the same durint an entire error period.
        impure function rndError(input : std_logic_vector(C_WIDTH - 1 downto 0)) return std_logic_vector is
            variable output : std_logic_vector(C_WIDTH - 1 downto 0);
            variable bitIdx : natural;
        begin
            output := input;     
            bitIdx := rndUniform(0, C_WIDTH);
            output(bitIdx) := not input(bitIdx);
            return output;
        end function rndError;
        
        -- Return the error status (return always false if there is no match 
        -- between 'CS_ERR_TARGET' and the 'target' input parameter.
        impure function flag(target : integer) return boolean is 
        begin
            if (target = CS_ERR_TARGET and CS_MODE /= 0) then
                return errFlag;
            else
                return false;
            end if;    
        end function flag;

        -- Return the current simulation mode. 
        function mode(target : integer) return integer is 
        begin
            return CS_MODE;
        end function mode;
                
    end protected body tErr;    
            
end package body rtTools_pkg;

-------------------------
-- SYNTHESIS TRANSLATE_ON
-------------------------
