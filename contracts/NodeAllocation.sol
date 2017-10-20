pragma solidity ^0.4.13;

import './Ownable.sol';
import './NodePhases.sol';
import './SafeMath.sol';

contract NodeAllocation is Ownable {

    using SafeMath for uint256;

    NodePhases public nodePhases;

    PreICOAllocation[] preIcoAllocation;

    ICOAllocation[] icoAllocation;

    uint256[] public distributionThresholds;

    uint256 public lastDistributedAmount;

    address public bountyAddress;

    struct PreICOAllocation {
        uint8 percentage;
        address destrAddress;
    }

    struct ICOAllocation {
        uint8 percentage;
        address destrAddress;
    }

    modifier onlyNode() {
        require(msg.sender == address(nodePhases));
        _;
    }

    function NodeAllocation(
        address _nodePhases,
        address _bountyAddress,//2%
        address[] _preICOAddresses,//according - 3% and 97%
        address[] _ICOAddresses,//according - 3% 47% and 50%
        uint256[] _distributionThresholds
    ) {
        require( (address(_nodePhases) != 0x0) && (address(_bountyAddress) != 0x0) && _distributionThresholds.length > 0 );
        nodePhases = NodePhases(address(_nodePhases));

        bountyAddress = _bountyAddress;
        distributionThresholds = _distributionThresholds;
        lastDistributedAmount = 0;

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
        preIcoAllocation.push(PreICOAllocation(3, _addresses[0]));
        preIcoAllocation.push(PreICOAllocation(47, _addresses[1]));
        preIcoAllocation.push(PreICOAllocation(50, _addresses[2]));

        return true;
    }

    function allocateICOEthers() internal {
        uint256 amount = nodePhases.getBalanceContract();

        for (uint8 i = 0; i < icoAllocation.length; i++) {
            ICOAllocation storage allocation = icoAllocation[i];
            if (i + 1 == preIcoAllocation.length) {
                allocation.destrAddress.transfer(nodePhases.balance);
            } else {
                allocation.destrAddress.transfer(amount.mul(allocation.percentage).div(100));
            }
        }
    }

    function setNodePhases(address _nodePhases) public onlyOwner {
        nodePhases = NodePhases(_nodePhases);
    }

    function allocate() public onlyNode {
        require(nodePhases.setCurrentPhase(now) == true);

        if (nodePhases.currentPhase() == 0) {
            require(uint8(preIcoAllocation.length) > 0);

            uint256 amount = nodePhases.getBalanceContract();

            for (uint8 i = 0; i < preIcoAllocation.length; i++) {
                PreICOAllocation storage allocation = preIcoAllocation[i];
                if (i + 1 == preIcoAllocation.length) {
                    allocation.destrAddress.transfer(nodePhases.balance);
                } else {
                    allocation.destrAddress.transfer(amount.mul(allocation.percentage).div(100));
                }
            }
        }

        if (nodePhases.currentPhase() == 1) {
            require(uint8(distributionThresholds.length) > 0);

            for (uint8 j = 0; i < distributionThresholds.length; i++) {
                if ((distributionThresholds[j] > lastDistributedAmount) && (nodePhases.soldTokens() >= distributionThresholds[j])) {
                    lastDistributedAmount = distributionThresholds[j];
                    allocateICOEthers();
                }
            }
        }
    }

    function allocateBounty() public onlyNode  {
        allocateICOEthers();
        uint256 mintedAmount = nodePhases.mint(bountyAddress, nodePhases.maxSupply().mul(2).div(100));

        require(mintedAmount == nodePhases.maxSupply().mul(2).div(100));
    }

}