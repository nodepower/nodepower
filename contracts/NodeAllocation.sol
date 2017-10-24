pragma solidity ^0.4.13;


import './Ownable.sol';
import './SafeMath.sol';


contract NodeAllocation is Ownable {

    using SafeMath for uint256;

    PreICOAllocation[] public preIcoAllocation;

    ICOAllocation[] public icoAllocation;

    uint256[] public distributionThresholds;

    address public bountyAddress;

    struct PreICOAllocation {
        uint8 percentage;
        address destAddress;
    }

    struct ICOAllocation {
        uint8 percentage;
        address destAddress;
    }

    function NodeAllocation(
        address _bountyAddress, //2%
        address[] _preICOAddresses, //according - 3% and 97%
        address[] _ICOAddresses, //according - 3% 47% and 50%
        uint256[] _distributionThresholds
    ) {
        require((address(_bountyAddress) != 0x0) && _distributionThresholds.length > 0);

        bountyAddress = _bountyAddress;
        distributionThresholds = _distributionThresholds;

        require(setPreICOAllocation(_preICOAddresses) == true);
        require(setICOAllocation(_ICOAddresses) == true);
    }

    function setPreICOAllocation(address[] _addresses) internal returns (bool) {
        if (_addresses.length < 2) {
            return false;
        }
        preIcoAllocation.push(PreICOAllocation(3, _addresses[0]));
        preIcoAllocation.push(PreICOAllocation(97, _addresses[1]));

        return true;
    }

    function setICOAllocation(address[] _addresses) internal returns (bool) {
        if (_addresses.length < 3) {
            return false;
        }
        icoAllocation.push(ICOAllocation(3, _addresses[0]));
        icoAllocation.push(ICOAllocation(47, _addresses[1]));
        icoAllocation.push(ICOAllocation(50, _addresses[2]));

        return true;
    }

    function getPreICOAddress(uint8 _id) public returns (address)  {
        PreICOAllocation storage allocation = preIcoAllocation[_id];

        return allocation.destAddress;
    }

    function getPreICOPercentage(uint8 _id) public returns (uint8) {
        PreICOAllocation storage allocation = preIcoAllocation[_id];

        return allocation.percentage;
    }

    function getPreICOLength() public returns (uint8) {
        return uint8(preIcoAllocation.length);
    }

    function getICOAddress(uint8 _id) public returns (address) {
        ICOAllocation storage allocation = icoAllocation[_id];

        return allocation.destAddress;
    }

    function getICOPercentage(uint8 _id) public returns (uint8) {
        ICOAllocation storage allocation = icoAllocation[_id];

        return allocation.percentage;
    }

    function getICOLength() public returns (uint8) {
        return uint8(icoAllocation.length);
    }

    function getThreshold(uint8 _id) public returns (uint256) {
        return uint256(distributionThresholds[_id]);
    }

    function getThresholdsLength() public returns (uint8) {
        return uint8(distributionThresholds.length);
    }

}