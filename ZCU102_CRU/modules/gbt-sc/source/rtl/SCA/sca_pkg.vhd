-------------------------------------------------------
--! @file
--! @author Julian Mendez <julian.mendez@cern.ch> (CERN - EP-ESE-BE)
--! @date April, 2017
--! @version 1.0
--! @brief SCA control - SCA Package (types and CRC func.)
-------------------------------------------------------

--! Include the IEEE VHDL standard library
library ieee;
--! Use STD_Logic to define vector types
use ieee.std_logic_1164.all;

--! @brief SCA control - SCA Package (types and CRC func.)
--! @details 
--! The SCA package defines new types and array required to
--! handle the communication with the SCA. It defines also
--! a couple of function needed to compute the HDLC frame
--! CRC.
package SCA_PKG is

    -- Types & Subtypes
    subtype reg2    is std_logic_vector(1 downto 0);		--! Subtype: bus of 2 bits (IC and EC lines)
    subtype reg8    is std_logic_vector(7 downto 0);		--! Subtype: bus of 8 bits (Bytes)
    subtype reg16   is std_logic_vector(15 downto 0);		--! Subtype: bus of 16 bits (Used for the CRC computing)
    subtype reg32   is std_logic_vector(31 downto 0);		--! Subtype: bus of 32 bits (Used for the data)

    type reg8_arr   is array(integer range <>) of reg8;		--! Type: array of bytes
    type reg16_arr  is array(integer range <>) of reg16;	--! Type: array of 16 bits buses
    type reg2_arr   is array(integer range <>) of reg2;		--! Type: array of 2 bits buses
    type reg32_arr  is array(integer range <>) of reg32;	--! Type: array of 32 bits buses

    -- Functions
	--! Reverse function is used to reverse the CRC before sending it. The standard
	--! requires to send the 16 bits from the LSB to the MSB.
    function reverse_v (
        a: in std_logic_vector)
    return std_logic_vector;

	--! nextCRC16_D8 function compute the 16 bits CRC, using the new byte to be sent
	--! and the current CRC value.
    function nextCRC16_D8 (
        Data: std_logic_vector(7 downto 0);
        crc:  std_logic_vector(15 downto 0))
    return std_logic_vector;

end SCA_PKG;

--! @brief SCA control - SCA Package body (describes func.)
--! @details 
--! The SCA package body implements the reverse and nextCRC16_D8
--! functions available via the SCA_PKG package.
package body SCA_PKG is

    -- Vector reverse function
	--! Reverse function is used to reverse the CRC before sending it. The standard
	--! requires to send the 16 bits from the LSB to the MSB.
    function reverse_v (
        a: in std_logic_vector)
    return std_logic_vector is
    
        variable result: std_logic_vector(a'RANGE);
        alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
      
    begin    
        for i in aa'RANGE loop
            result(i) := aa(i);
        end loop;
      
        return result;      
    end;
    
    -- CRC16 - 8bits data
	--! nextCRC16_D8 function compute the 16 bits CRC, using the new byte to be sent
	--! and the current CRC value.
    function nextCRC16_D8 (
        Data: std_logic_vector(7 downto 0);
        crc:  std_logic_vector(15 downto 0))
    return std_logic_vector is
    
        variable d:      std_logic_vector(7 downto 0);
        variable c:      std_logic_vector(15 downto 0);
        variable newcrc: std_logic_vector(15 downto 0);
        
    begin
    
        d := Data;
        c := crc;
        
        newcrc(0) := d(4) xor d(0) xor c(8) xor c(12);
        newcrc(1) := d(5) xor d(1) xor c(9) xor c(13);
        newcrc(2) := d(6) xor d(2) xor c(10) xor c(14);
        newcrc(3) := d(7) xor d(3) xor c(11) xor c(15);
        newcrc(4) := d(4) xor c(12);
        newcrc(5) := d(5) xor d(4) xor d(0) xor c(8) xor c(12) xor c(13);
        newcrc(6) := d(6) xor d(5) xor d(1) xor c(9) xor c(13) xor c(14);
        newcrc(7) := d(7) xor d(6) xor d(2) xor c(10) xor c(14) xor c(15);
        newcrc(8) := d(7) xor d(3) xor c(0) xor c(11) xor c(15);
        newcrc(9) := d(4) xor c(1) xor c(12);
        newcrc(10) := d(5) xor c(2) xor c(13);
        newcrc(11) := d(6) xor c(3) xor c(14);
        newcrc(12) := d(7) xor d(4) xor d(0) xor c(4) xor c(8) xor c(12) xor c(15);
        newcrc(13) := d(5) xor d(1) xor c(5) xor c(9) xor c(13);
        newcrc(14) := d(6) xor d(2) xor c(6) xor c(10) xor c(14);
        newcrc(15) := d(7) xor d(3) xor c(7) xor c(11) xor c(15);
        
        return newcrc;
        
    end nextCRC16_D8;

end SCA_PKG;