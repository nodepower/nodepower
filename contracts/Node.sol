pragma solidity ^0.4.13;

import './MintingERC20.sol';
import './OraclizeAPI.sol';
import './SafeMath.sol';

contract Node is usingOraclize, MintingERC20 {

    using SafeMath for uint256;

    uint256 public priceUpdateAt;

    uint256 public tokenPrice;

    // Block token transfers till ICO end.
    bool public transferFrozen = true;

    event newOraclizeQuery(string description);

    event newNodePriceTicker(string price);

    function Node(
        uint256 _maxSupply,
        string _tokenName,
        string _tokenSymbol,
        uint8 _precision,
        uint256 _tokenPrice,//0.0032835596 ethers
        bool _locked
    ) MintingERC20(0, _maxSupply, _tokenName, _precision, _tokenSymbol, false, _locked) {
        standard = 'Node 0.1';

        tokenPrice = _tokenPrice;
        priceUpdateAt = now;

        oraclize_setNetwork(networkID_auto);
        oraclize = OraclizeI(OAR.getAddress());
    }

    function update() internal {
        if (oraclize_getPrice('URL') > this.balance) {
            newOraclizeQuery('Oraclize query was NOT sent, please add some ETH to cover for the query fee');
        } else {
            newOraclizeQuery('Oraclize query was sent, standing by for the answer..');
            oraclize_query('URL', 'json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0');
        }
    }

    function setLocked(bool _locked) onlyOwner {
        locked = _locked;
    }

    function setCurrentRate(uint256 _rate) public onlyOwner {
        require(_rate > 0);
        tokenPrice = _rate;
        priceUpdateAt = now;
    }

    // Allow / disallow token transfer.
    function freezing(bool _transferFrozen) public onlyOwner {
        transferFrozen = _transferFrozen;
    }

    function updateAndGetRate() public onlyMinters returns(uint256) {
        if (priceUpdateAt.add(3600) < now){
            update();
            priceUpdateAt = now;
        }

        return tokenPrice;
    }

    function refund(uint256 _amount, address _address) public onlyMinters {
        require(_amount > 0 && address(_address) == 0x0);
        transfer(_address, _amount);

        uint256 balance = balanceOf(_address);
        setBalance(_address, 0);
        setBalance(this, balanceOf(this).add(balance));
    }

    function __callback(bytes32, string _result, bytes) {
        require(msg.sender == oraclize_cbAddress());

        uint256 price = uint256(10 ** 23).div(parseInt(_result, 5));

        require(price > 0);
        tokenPrice = price;

        newNodePriceTicker(_result);
    }

    function transfer(address _to, uint _value) public returns (bool) {
        require(_value != 0 && address(_to) != 0x0);
        require(!transferFrozen);

        return super.transfer(_to, _value);
    }

    function getPrecision() public constant returns (uint8) {
        return decimals;
    }

}