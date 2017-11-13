pragma solidity 0.4.15;

import "./Ownable.sol";
import "./Node.sol";
import "./NodeAllocation.sol";
import "./SafeMath.sol";
import "./OraclizeAPI.sol";


contract NodePhases is usingOraclize, Ownable {

    using SafeMath for uint256;

    Node public node;

    NodeAllocation public nodeAllocation;

    Phase[] public phases;

    uint256 public constant HOUR = 3600;

    uint256 public constant DAY = 86400;

    uint256 public collectedEthers;

    uint256 public soldTokens;

    uint256 public priceUpdateAt;

    uint256 public investorsCount;

    uint256 public lastDistributedAmount;

    mapping (address => uint256) public icoEtherBalances;

    mapping (address => bool) private investors;

    event NewOraclizeQuery(string description);

    event NewNodePriceTicker(string price);

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
        uint256 _minInvest,
        uint256 _tokenPrice, //0.0032835596 ethers
        uint256 _preIcoMaxCap,
        uint256 _preIcoSince,
        uint256 _preIcoTill,
        uint256 _icoMinCap,
        uint256 _icoMaxCap,
        uint256 _icoSince,
        uint256 _icoTill
    ) {
        require(address(_node) != address(0));
        node = Node(address(_node));

        require((_preIcoSince < _preIcoTill) && (_icoSince < _icoTill) && (_preIcoTill <= _icoSince));

        require((_preIcoMaxCap < _icoMaxCap) && (_icoMaxCap < node.maxSupply()));

        phases.push(Phase(_tokenPrice, _minInvest, 0, _preIcoMaxCap, _preIcoSince, _preIcoTill, false));
        phases.push(Phase(_tokenPrice, _minInvest, _icoMinCap, _icoMaxCap, _icoSince, _icoTill, false));

        priceUpdateAt = now;

        oraclize_setNetwork(networkID_auto);
        oraclize = OraclizeI(OAR.getAddress());
    }

    function() public payable {
        require(buy(msg.sender, msg.value) == true);
    }

    function __callback(bytes32, string _result, bytes) public {
        require(msg.sender == oraclize_cbAddress());

        uint256 price = uint256(10 ** 23).div(parseInt(_result, 5));

        require(price > 0);

        for (uint i = 0; i < phases.length; i++) {
            Phase storage phase = phases[i];
            phase.price = price;
        }

        NewNodePriceTicker(_result);
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
        require(address(_node) != address(0));
        node = Node(_node);
    }

    function setNodeAllocation(address _nodeAllocation) public onlyOwner {
        require(address(_nodeAllocation) != address(0));
        nodeAllocation = NodeAllocation(_nodeAllocation);
    }

    function setPhase(
        uint8 _phaseId,
        uint256 _since,
        uint256 _till,
        uint256 _price,
        uint256 _softCap,
        uint256 _hardCap
    ) public onlyOwner returns (bool) {
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

    function sendToAddress(address _address, uint256 _tokens) public onlyOwner returns (bool) {
        return sendToAddressWithTime(_address, _tokens, now);
    }

    function sendToAddressWithTime(
        address _address,
        uint256 _tokens,
        uint256 _time
    ) public onlyOwner returns (bool) {
        if (_tokens == 0 || address(_address) == address(0) || _time == 0) {
            return false;
        }

        uint256 totalAmount = _tokens.add(getBonusAmount(_tokens, _time));

        require(totalAmount == node.mint(_address, totalAmount));

        soldTokens = soldTokens.add(totalAmount);
        increaseInvestorsCount(_address);

        return true;
    }

    function sendToAddressWithBonus(
        address _address,
        uint256 _tokens,
        uint256 _bonus
    ) public onlyOwner returns (bool) {
        if (_tokens == 0 || address(_address) == address(0) || _bonus == 0) {
            return false;
        }

        uint256 totalAmount = _tokens.add(_bonus);

        require(totalAmount == node.mint(_address, totalAmount));

        soldTokens = soldTokens.add(totalAmount);
        increaseInvestorsCount(_address);

        return true;
    }

    function getTokens() public constant returns (uint256) {
        return node.totalSupply();
    }

    function getSoldToken() public constant returns (uint256) {
        return soldTokens;
    }

    function getAllInvestors() public constant returns (uint256) {
        return investorsCount;
    }

    function getBalanceContract() public constant returns (uint256) {
        return collectedEthers;
    }

    function isSucceed(uint8 phaseId) public returns (bool) {
        if (phases.length < phaseId) {
            return false;
        }
        Phase storage phase = phases[phaseId];
        if (phase.isSucceed == true) {
            return true;
        }
        if (phase.till > now) {
            return false;
        }
        if (phase.softCap != 0 && phase.softCap > getTokens()) {
            return false;
        }
        phase.isSucceed = true;
        if (phaseId == 1) {
            allocateBounty();
        }

        return true;
    }

    function refund() public returns (bool) {
        Phase storage icoPhase = phases[1];
        if (icoPhase.till > now) {
            return false;
        }
        if (icoPhase.softCap < getTokens()) {
            return false;
        }
        if (icoEtherBalances[msg.sender] == 0) {
            return false;
        }

        uint256 refundAmount = icoEtherBalances[msg.sender];
        uint256 tokens = node.buyBack(msg.sender);
        icoEtherBalances[msg.sender] = 0;
        msg.sender.transfer(refundAmount);
        Refund(msg.sender, refundAmount, tokens);

        return true;
    }

    function isFinished(uint8 phaseId) public constant returns (bool) {
        if (phases.length < phaseId) {
            return false;
        }
        Phase storage phase = phases[phaseId];

        return (phase.isSucceed || now > phase.till);
    }

    function getCurrentPhase(uint256 _time) public constant returns (uint8) {
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

    function update() internal {
        if (oraclize_getPrice("URL") > this.balance) {
            NewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            NewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0");
        }
    }

    function buy(address _address, uint256 _value) internal returns (bool) {
        if (_value == 0) {
            return false;
        }

        uint8 currentPhase = getCurrentPhase(now);

        if (phases.length < currentPhase) {
            return false;
        }

        if (priceUpdateAt.add(HOUR) < now) {
            update();
            priceUpdateAt = now;
        }

        uint256 amount = getTokensAmount(_value, currentPhase);

        if (amount == 0) {
            return false;
        }

        amount = amount.add(getBonusAmount(amount, now));

        require(amount == node.mint(_address, amount));

        onSuccessfulBuy(_address, _value, amount, currentPhase);
        allocate(currentPhase);

        return true;
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
        if (address(_address) != address(0) && investors[_address] == false) {
            investors[_address] = true;
            investorsCount = investorsCount.add(1);
        }
    }

    function getTokensAmount(uint256 _value, uint8 _currentPhase) internal returns (uint256) {
        if (_value == 0 || phases.length < _currentPhase) {
            return 0;
        }

        Phase storage phase = phases[_currentPhase];

        uint256 amount = _value.mul(uint256(10) ** node.decimals()).div(phase.price);

        if (amount < phase.minInvest) {
            return 0;
        }

        if (getTokens().add(amount) > phase.hardCap) {
            return 0;
        }

        return amount;
    }

    function getBonusAmount(uint256 _amount, uint256 _time) internal returns (uint256) {
        uint8 currentPhase = getCurrentPhase(_time);
        if (_amount == 0 || _time == 0 || phases.length < currentPhase) {
            return 0;
        }

        if (currentPhase == 0) {
            return _amount.mul(50).div(100);
        }

        if (currentPhase == 1) {
            return getICOBonusAmount(_amount, _time);
        }

        return 0;
    }

    function getICOBonusAmount(uint256 _amount, uint256 _time) internal returns (uint256) {
        Phase storage ico = phases[1];
        if (_time.sub(ico.since) < 11 * DAY) {// 11d since ico => reward 30%;
            return _amount.mul(30).div(100);
        }
        if (_time.sub(ico.since) < 21 * DAY) {// 21d since ico => reward 20%
            return _amount.mul(20).div(100);
        }
        if (_time.sub(ico.since) < 31 * DAY) {// 31d since ico => reward 15%
            return _amount.mul(15).div(100);
        }
        if (_time.sub(ico.since) < 41 * DAY) {// 41d since ico => reward 10%
            return _amount.mul(10).div(100);
        }

        return 0;
    }

    function allocateICOEthers() internal returns (bool) {
        uint8 length = nodeAllocation.getICOLength();
        require(length > 0);

        uint256 totalAmount = this.balance;
        for (uint8 i = 0; i < length; i++) {
            uint256 amount = totalAmount.mul(nodeAllocation.getICOPercentage(i)).div(100);
            if ((i + 1) == length) {
                amount = this.balance;
            }
            if (amount > 0) {
                nodeAllocation.getICOAddress(i).transfer(amount);
            }
        }

        return true;
    }

    function allocatePreICOEthers() internal returns (bool) {
        uint8 length = nodeAllocation.getPreICOLength();
        require(length > 0);

        uint256 totalAmount = this.balance;
        for (uint8 i = 0; i < length; i++) {
            uint256 amount = totalAmount.mul(nodeAllocation.getPreICOPercentage(i)).div(100);
            if ((i + 1) == length) {
                amount = this.balance;
            }
            if (amount > 0) {
                nodeAllocation.getPreICOAddress(i).transfer(amount);
            }
        }

        return true;
    }

    function allocate(uint8 _currentPhase) internal {
        if (_currentPhase == 0) {
            allocatePreICOEthers();
        }
        if (_currentPhase == 1) {
            uint8 length = nodeAllocation.getThresholdsLength();
            require(uint8(length) > 0);

            for (uint8 j = 0; j < length; j++) {
                uint256 threshold = nodeAllocation.getThreshold(j);

                if ((threshold > lastDistributedAmount) && (soldTokens >= threshold)) {
                    allocateICOEthers();
                    lastDistributedAmount = threshold;
                }
            }
        }
    }

    function allocateBounty() internal {
        if (isFinished(1)) {
            allocateICOEthers();
            uint256 amount = node.maxSupply().mul(2).div(100);
            uint256 mintedAmount = node.mint(nodeAllocation.bountyAddress(), amount);
            require(mintedAmount == amount);
        }
    }

}