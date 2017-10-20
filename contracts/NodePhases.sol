pragma solidity ^0.4.13;


import './Ownable.sol';
import './Node.sol';
import './NodeAllocation.sol';
import './SafeMath.sol';

contract NodePhases is Ownable {

    using SafeMath for uint256;

    Node public node;

    NodeAllocation public nodeAllocation;

    Phase[] public phases;

    uint8 public currentPhase;
    uint256 public investorsAmount;
    uint256 public collectedEthers;
    uint256 public soldTokens;

    event Refund(address holder, uint256 ethers, uint256 tokens);

    mapping (address => uint256) public icoEtherBalances;

    struct Phase {
        uint256 price;
        uint256 minInvest;
        uint256 softCap;
        uint256 hardCap;
        uint256 since;
        uint256 till;
        bool isSucceed;
    }

    modifier onlyNodeContracts() {
        require( (msg.sender == address(node)) || (msg.sender == address(nodeAllocation)));
        _;
    }

    function NodePhases(
        address _node,
        address _nodeAllocation,

        uint256 _minPreICOInvest,
        uint256 _preIcoMinCap,
        uint256 _preIcoMaxCap,
        uint256 _preIcoSince,
        uint256 _preIcoTill,

        uint256 _minIcoInvest,
        uint256 _icoMinCap,
        uint256 _icoMaxCap,
        uint256 _icoSince,
        uint256 _icoTill

    ) {
        require(address(_node) != 0x0 && address(_nodeAllocation) != 0x0);
        node = Node(address(_node));
        nodeAllocation = NodeAllocation(address(_nodeAllocation));

        require((_preIcoSince < _preIcoTill) && (_icoSince < _icoTill) && (_preIcoTill < _icoSince));

        require((_preIcoMaxCap < _icoMaxCap) && (_icoMaxCap < node.maxSupply()));

        phases.push(Phase(node.tokenPrice(), _minPreICOInvest, _preIcoMinCap, _preIcoMaxCap, _preIcoSince, _preIcoTill, false));
        phases.push(Phase(node.tokenPrice(), _minIcoInvest, _icoMinCap, _icoMaxCap, _icoSince, _icoTill, false));

        investorsAmount = 0;
        collectedEthers = 0;
        soldTokens = 0;
    }

    function updatePrices() internal {
        uint256 value = node.updateAndGetRate();
        for (uint i = 0; i < phases.length; i++) {
            Phase storage phase = phases[i];
            phase.price = value;
        }
    }

    function buy(address _address, uint256 _value) internal returns (bool) {
        if (_value == 0) {
            return false;
        }

        if (setCurrentPhase(now) == false) {
            return false;
        }

        updatePrices();

        uint256 amount = getTokensAmount(_value);

        if (amount == 0) {
            return false;
        }

        amount = amount.add(getBonusAmount(amount, now));

        bool status = (amount != node.mint(_address, amount));

        if (status) {
            onSuccessfulBuy(_address, _value, amount);
            nodeAllocation.allocate();
        }

        return status;
    }

    function onSuccessfulBuy(address _address, uint256 _value, uint256 _amount) internal {
        collectedEthers = collectedEthers.add(_value);
        soldTokens = soldTokens.add(_amount);
        increaseInvestorsAmount();

        if (currentPhase == 1) {
            icoEtherBalances[_address] = icoEtherBalances[_address].add(_value);
        }
    }

    function increaseInvestorsAmount() internal {
        investorsAmount = investorsAmount.add(1);
    }

    function getTokensAmount(uint256 _value) internal returns (uint256) {
        if (_value == 0 || phases.length < currentPhase) {
            return uint256(0);
        }

        Phase storage phase = phases[currentPhase];

        uint256 amount = _value.mul(uint256(10) ** node.getPrecision()).div(phase.price);

        if (amount < phase.minInvest) {
            return uint256(0);
        }

        if (getTokens().add(amount) > phase.hardCap) {
            return uint256(0);
        }

        return amount;
    }

    function getBonusAmount(uint256 _amount, uint256 time) internal returns (uint256) {
        Phase storage phase = phases[currentPhase];

        if (phase.since < time && phase.till > time) {
            if (currentPhase == 0) {
                return _amount.mul(50).div(100);
            }

            if (currentPhase == 1) {
                if (time.sub(phase.since) < 950400) {// 11d since ico => reward 30%;
                    return _amount.mul(30).div(100);
                }
                else if (time.sub(phase.since) < 1814400) {// 21d since ico => reward 20%
                    return _amount.mul(20).div(100);
                }
                else if (time.sub(phase.since) < 2678400) {// 31d since ico => reward 15%
                    return _amount.mul(15).div(100);
                }
                else if (time.sub(phase.since) < 3542400) {// 41d since ico => reward 10%
                    return _amount.mul(10).div(100);
                }
            }
        }

        return uint256(0);
    }

    function setNode(address _node) public onlyOwner {
        node = Node(_node);
    }

    function setNodeAllocation(address _nodeAllocation) public onlyOwner {
        nodeAllocation = NodeAllocation(_nodeAllocation);
    }

    function setPhase(uint8 _phaseId, uint256 _since, uint256 _till, uint256 _price, uint256 _softCap, uint256 _hardCap) public onlyOwner returns (bool) {
        require( (phases.length > _phaseId) && (_price > 0) );
        require( (_till > _since) && (_since > 0) );
        require( (node.maxSupply() > _hardCap) && (_hardCap > _softCap)  && (_softCap >= 0) );

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

        if (setCurrentPhase(now) == false) {
            return false;
        }

        uint256 totalAmount = _tokens.add(getBonusAmount(_tokens, now));

        if (getTokens().add(totalAmount) > node.maxSupply()) {
            return false;
        }

        bool status = (totalAmount != node.mint(_address, totalAmount));

        if (status) {
            increaseInvestorsAmount();
        }

        return status;
    }

    function sendToAddressWithTime(address _address, uint256 _tokens, uint256 _time) public onlyOwner returns (bool) {
        if (_tokens < 1 || address(_address) == 0x0 || _time < 1) {
            return false;
        }

        if (setCurrentPhase(_time) == false) {
            return false;
        }

        uint256 totalAmount = _tokens.add(getBonusAmount(_tokens, _time));

        if (getTokens().add(totalAmount) > node.maxSupply()) {
            return false;
        }

        bool status = (totalAmount != node.mint(_address, totalAmount));

        if (status) {
            increaseInvestorsAmount();
        }

        return status;
    }
    //todo check uint256 _bonus - % or amount
    function sendToAddressWithBonus(address _address, uint256 _tokens, uint256 _bonus) public onlyOwner returns (bool) {
        if (_tokens < 1 || address(_address) == 0x0 || _bonus < 1) {
            return false;
        }

        uint256 totalAmount = _tokens.add(_bonus);

        if (getTokens().add(totalAmount) > node.maxSupply()) {
            return false;
        }

        bool status = (totalAmount != node.mint(_address, totalAmount));

        if (status) {
            increaseInvestorsAmount();
        }

        return status;
    }

    function setCurrentPhase(uint256 time) public onlyNodeContracts returns (bool) {
        for (uint8 i = 0; i < phases.length; i++) {
            Phase storage phase = phases[i];
            if (phase.since > time) {
                continue;
            }

            if (phase.till < time) {
                continue;
            }
            currentPhase = i;

            return true;
        }

        return false;
    }

    function mint(address _addr, uint256 _amount) public onlyNodeContracts returns (uint256) {
        return node.mint(_addr, _amount);
    }

    function maxSupply() public constant returns (uint256) {
        return node.maxSupply();
    }

    function getTokens() public constant returns (uint256) {
        return node.totalSupply();
    }

    function getAllInvestors() public constant returns (uint256) {
        return investorsAmount;
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
            nodeAllocation.allocateBounty();
        }

        return true;
    }

    function refund() public returns (bool) {
        Phase storage icoPhase = phases[1];
        if (icoPhase.till > now) {
            return false;
        }
        if (icoPhase.till < now && icoPhase.softCap <= getTokens()) {
            return false;
        }
        if (icoEtherBalances[msg.sender] == 0) {
            return false;
        }
        uint256 refundAmount = icoEtherBalances[msg.sender];
        node.refund(refundAmount, msg.sender);
        icoEtherBalances[msg.sender] = 0;

        return true;
    }

    function() payable {
        bool status = buy(msg.sender, msg.value);
        require(status == true);
    }
}