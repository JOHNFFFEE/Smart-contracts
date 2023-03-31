// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
/// @author Blockchain Knowledge Team
/// @title Demo Contract
contract DemoContract 
{
    uint storedData;
    
    /// Store `x`.
    /// @param x the new value to store
    /// @dev stores the number in the state variable `storedData`
    function set(uint x) public 
    {
        storedData = x;
    }
    /// Return the stored value.
    /// @dev retrieves the value of the state variable `storedData`
    /// @return the stored value
    function get() public view returns (uint) 
    {
        return storedData;
    }
}