pragma solidity ^0.4.13;

import './MintingERC20.sol';
import './SafeMath.sol';
import './NodePhases.sol';

contract Node is MintingERC20 {

    using SafeMath for uint256;

    NodePhases public nodePhases;

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

    function setLocked(bool _locked) public onlyOwner {
        locked = _locked;
    }

    function setNodePhases(address _nodePhases) public onlyOwner {
        nodePhases = NodePhases(_nodePhases);
    }

    function unfreeze() public onlyOwner {
        if (nodePhases != address(0) && nodePhases.isFinished(1)) {
            transferFrozen = false;
        }
    }

    function buyBack(address _address) public onlyMinters returns (uint256) {
        require(address(_address) != 0x0);

        uint256 balance = balanceOf(_address);
        setBalance(_address, 0);
        setBalance(this, balanceOf(this).add(balance));
        Transfer(_address, this, balance);

        return balance;
    }

    function transfer(address _to, uint _value) public returns (bool) {
        require(!transferFrozen);

        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(!transferFrozen);

        return super.transferFrom(_from, _to, _value);
    }

}