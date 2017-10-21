pragma solidity ^0.4.13;


import './Ownable.sol';
import './Node.sol';
import './NodeAllocation.sol';
import './SafeMath.sol';
import './OraclizeAPI.sol';

contract NodePhases is usingOraclize, Ownable {

    using SafeMath for uint256;

    Node public node;

    NodeAllocation public nodeAllocation;

    Phase[] public phases;

    uint256 public collectedEthers;

    uint256 public soldTokens;

    uint256 public priceUpdateAt;

    uint256 public investorsCount;

    mapping (address => uint256) public icoEtherBalances;

    mapping (address => bool) private investors;

    event newOraclizeQuery(string description);

    event newNodePriceTicker(string price);

    event Refund(address holder, uint256 ethers, uint256 tokens);

    struct Phase {
        uint256 price;
        uint256 minInvest;
        uint256 softCap;
        uint256 hardCap;
        uint256 since;
        uint256 till;
        bool isSucceed;
    }

    function NodePhases(
        address _node,
        uint256 _minPreICOInvest,
        uint256 _preIcoTokenPrice, //0.0032835596 ethers
        uint256 _preIcoMinCap,
        uint256 _preIcoMaxCap,
        uint256 _preIcoSince,
        uint256 _preIcoTill,
        uint256 _minIcoInvest,
        uint256 _icoTokenPrice, //0.0032835596 ethers
        uint256 _icoMinCap,
        uint256 _icoMaxCap,
        uint256 _icoSince,
        uint256 _icoTill
    ) {
        require(address(_node) != 0x0);
        node = Node(address(_node));

        require((_preIcoSince < _preIcoTill) && (_icoSince < _icoTill) && (_preIcoTill < _icoSince));

        require((_preIcoMaxCap < _icoMaxCap) && (_icoMaxCap < node.maxSupply()));

        phases.push(Phase(_preIcoTokenPrice, _minPreICOInvest, _preIcoMinCap, _preIcoMaxCap, _preIcoSince, _preIcoTill, false));
        phases.push(Phase(_icoTokenPrice, _minIcoInvest, _icoMinCap, _icoMaxCap, _icoSince, _icoTill, false));

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

    function buy(address _address, uint256 _value) internal returns (bool) {
        if (_value == 0) {
            return false;
        }

        uint8 currentPhase = getCurrentPhase(now);

        if (phases.length <= currentPhase) {
            return false;
        }

        if (priceUpdateAt.add(3600) < now) {
            update();
            priceUpdateAt = now;
        }

        uint256 amount = getTokensAmount(_value, currentPhase);

        if (amount == 0) {
            return false;
        }

        amount = amount.add(getBonusAmount(amount, now));

        bool status = (amount != node.mint(_address, amount));

        if (status) {
            onSuccessfulBuy(_address, _value, amount, currentPhase);
            nodeAllocation.allocate(currentPhase);
        }

        return status;
    }

    function onSuccessfulBuy(address _address, uint256 _value, uint256 _amount, uint8 _currentPhase) internal {
        collectedEthers = collectedEthers.add(_value);
        soldTokens = soldTokens.add(_amount);
        increaseInvestorsCount(_address);

        if (_currentPhase == 1) {
            icoEtherBalances[_address] = icoEtherBalances[_address].add(_value);
        }
    }

    function increaseInvestorsCount(address _address) internal {
        if (address(_address) != 0x0 && investors[_address] == false) {
            investors[_address] = true;
            investorsCount = investorsCount.add(1);
        }
    }

    function getTokensAmount(uint256 _value, uint8 _currentPhase) internal returns (uint256) {
        if (_value == 0 || phases.length <= _currentPhase) {
            return uint256(0);
        }

        Phase storage phase = phases[_currentPhase];

        uint256 amount = _value.mul(uint256(10) ** node.decimals()).div(phase.price);

        if (amount < phase.minInvest) {
            return uint256(0);
        }

        if (getTokens().add(amount) > phase.hardCap) {
            return uint256(0);
        }

        return amount;
    }

    function getBonusAmount(uint256 _amount, uint256 _time) internal returns (uint256) {
        if (_amount == 0 || _time == 0) {
            return uint256(0);
        }
        uint8 currentPhase = getCurrentPhase(_time);
        if (phases.length <= currentPhase) {
            return uint256(0);
        }

        if (currentPhase == 0) {
            return _amount.mul(50).div(100);
        } else if (currentPhase == 1) {
            Phase storage ICO = phases[1];
            if (_time.sub(ICO.since) < 950400) {// 11d since ico => reward 30%;
                return _amount.mul(30).div(100);
            } else if (_time.sub(ICO.since) < 1814400) {// 21d since ico => reward 20%
                return _amount.mul(20).div(100);
            } else if (_time.sub(ICO.since) < 2678400) {// 31d since ico => reward 15%
                return _amount.mul(15).div(100);
            } else if (_time.sub(ICO.since) < 3542400) {// 41d since ico => reward 10%
                return _amount.mul(10).div(100);
            }
        }

        return uint256(0);
    }

    function __callback(bytes32, string _result, bytes) {
        require(msg.sender == oraclize_cbAddress());

        uint256 price = uint256(10 ** 23).div(parseInt(_result, 5));

        require(price > 0);

        for (uint i = 0; i < phases.length; i++) {
            Phase storage phase = phases[i];
            phase.price = price;
        }

        newNodePriceTicker(_result);
    }

    function setCurrentRate(uint256 _rate) public onlyOwner {
        require(_rate > 0);
        for (uint i = 0; i < phases.length; i++) {
            Phase storage phase = phases[i];
            phase.price = _rate;
        }
        priceUpdateAt = now;
    }

    function setNode(address _node) public onlyOwner {
        node = Node(_node);
    }

    function setNodeAllocation(address _nodeAllocation) public onlyOwner {
        nodeAllocation = NodeAllocation(_nodeAllocation);
    }

    function setPhase(uint8 _phaseId, uint256 _since, uint256 _till, uint256 _price, uint256 _softCap, uint256 _hardCap) public onlyOwner returns (bool) {
        require((phases.length > _phaseId) && (_price > 0));
        require((_till > _since) && (_since > 0));
        require((node.maxSupply() > _hardCap) && (_hardCap > _softCap) && (_softCap >= 0));

        Phase storage phase = phases[_phaseId];

        if (phase.isSucceed == true) {
            return false;
        }
        phase.since = _since;
        phase.till = _till;
        phase.price = _price;
        phase.softCap = _softCap;
        phase.hardCap = _hardCap;

        return true;
    }
    //todo check modifiyer - onlyOwner or other
    function sendToAddress(address _address, uint256 _tokens) public onlyOwner returns (bool) {
        if (_tokens == 0 || address(_address) == 0x0) {
            return false;
        }

        uint256 totalAmount = _tokens.add(getBonusAmount(_tokens, now));

        if (getTokens().add(totalAmount) > node.maxSupply()) {
            return false;
        }

        bool status = (totalAmount != node.mint(_address, totalAmount));

        if (status) {
            increaseInvestorsCount(_address);
        }

        return status;
    }

    function sendToAddressWithTime(address _address, uint256 _tokens, uint256 _time) public onlyOwner returns (bool) {
        if (_tokens == 0 || address(_address) == 0x0 || _time == 0) {
            return false;
        }

        uint256 totalAmount = _tokens.add(getBonusAmount(_tokens, _time));

        if (getTokens().add(totalAmount) > node.maxSupply()) {
            return false;
        }

        bool status = (totalAmount != node.mint(_address, totalAmount));

        if (status) {
            increaseInvestorsCount(_address);
        }

        return status;
    }

    function sendToAddressWithBonus(address _address, uint256 _tokens, uint256 _bonus) public onlyOwner returns (bool) {
        if (_tokens == 0 || address(_address) == 0x0 || _bonus == 0) {
            return false;
        }

        uint256 totalAmount = _tokens.add(_bonus);

        if (getTokens().add(totalAmount) > node.maxSupply()) {
            return false;
        }

        bool status = (totalAmount != node.mint(_address, totalAmount));

        if (status) {
            increaseInvestorsCount(_address);
        }

        return status;
    }

    function getCurrentPhase(uint256 _time) public returns (uint8) {
        if (_time == 0) {
            return uint8(phases.length);
        }
        for (uint8 i = 0; i < phases.length; i++) {
            Phase storage phase = phases[i];
            if (phase.since > _time) {
                continue;
            }

            if (phase.till < _time) {
                continue;
            }

            return i;
        }

        return uint8(phases.length);
    }

    function getTokens() public constant returns (uint256) {
        return node.totalSupply();
    }

    function getAllInvestors() public constant returns (uint256) {
        return investorsCount;
    }

    function getBalanceContract() public constant returns (uint256) {
        return collectedEthers;
    }

    function isSucceed(uint8 phaseId) public returns (bool) {
        if (phases.length <= phaseId) {
            return false;
        }

        Phase storage phase = phases[phaseId];

        if (phase.isSucceed == true) {
            return true;
        }

        if (phase.softCap != 0 && phase.softCap > getTokens()) {
            return false;
        }

        phase.isSucceed = true;
        if (phaseId == 1) {
            nodeAllocation.allocateBounty();
        }

        return true;
    }

    function refund() public returns (bool) {
        Phase storage icoPhase = phases[1];
        if (icoPhase.till > now) {
            return false;
        }
        if (icoPhase.softCap <= getTokens()) {
            return false;
        }
        if (icoEtherBalances[msg.sender] == 0) {
            return false;
        }
        uint256 refundAmount = icoEtherBalances[msg.sender];
        node.refund(refundAmount, msg.sender);
        icoEtherBalances[msg.sender] = 0;
        msg.sender.transfer(refundAmount);

        return true;
    }

    function isFinished(uint8 phaseId) public constant returns (bool) {
        if (phases.length <= phaseId) {
            return false;
        }
        Phase storage phase = phases[phaseId];

        return (phase.isSucceed || now > phase.till);
    }

    function() payable {
        bool status = buy(msg.sender, msg.value);
        require(status == true);
    }
}