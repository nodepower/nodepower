pragma solidity ^0.4.13;

import './MintingERC20.sol';
import './SafeMath.sol';

contract Node is usingOraclize, MintingERC20 {

    using SafeMath for uint256;

    // Block token transfers till ICO end.
    bool public transferFrozen = true;

    function Node(
        uint256 _maxSupply,
        string _tokenName,
        string _tokenSymbol,
        uint8 _precision,
        bool _locked
    ) MintingERC20(0, _maxSupply, _tokenName, _precision, _tokenSymbol, false, _locked) {
        standard = 'Node 0.1';
    }

    function setLocked(bool _locked) onlyOwner {
        locked = _locked;
    }

    // Allow / disallow token transfer.
    function freezing(bool _transferFrozen) public onlyOwner {
        transferFrozen = _transferFrozen;
    }

    function refund(uint256 _amount, address _address) public onlyMinters {
        require(_amount > 0 && address(_address) == 0x0);
        transfer(_address, _amount);

        uint256 balance = balanceOf(_address);
        setBalance(_address, 0);
        setBalance(this, balanceOf(this).add(balance));
    }

    function transfer(address _to, uint _value) public returns (bool) {
        require(_value >= 0 && address(_to) != 0x0);
        require(!transferFrozen);

        return super.transfer(_to, _value);
    }

    function getPrecision() public constant returns (uint8) {
        return decimals;
    }

}