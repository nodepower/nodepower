var token = artifacts.require("./Node.sol"),
    phases = artifacts.require("./NodePhases.sol"),
    allocation = artifacts.require("./NodeAllocation.sol");

var utils = require("./utils"),
    bigNumber = require('bignumber.js');

var precision = 100,
    bountyAddress = web3.eth.accounts[5],
    allocationAddress1 = web3.eth.accounts[6],
    allocationAddress2 = web3.eth.accounts[7],
    allocationAddress3 = web3.eth.accounts[8];

contract('Node', function (accounts) {
    it("deploy contracts & check contructors data", function () {
        var node, nodePhases, nodeAllocation,
        preICOSince = parseInt(new Date().getTime() / 1000),
        preICOTill = preICOSince + 2629743,
        iCOSince = parseInt(new Date().getTime() / 1000),
        iCOTill = iCOSince + 2629743;

        return token.new(
            new bigNumber(10000000).mul(precision),
            'NODE',
            'NODE',
            2,
            new bigNumber(3283559600000000),
            false
        )
            .then((instance) => {
                node = instance
            })

            .then(() => {
                    return allocation.new(
                        node.address,
                        bountyAddress,
                        [
                            allocationAddress1,
                            allocationAddress2
                        ],
                        [
                            allocationAddress1,
                            allocationAddress2,
                            allocationAddress3
                        ],
                        [
                            new bigNumber(1000000).mul(precision),
                            new bigNumber(3000000).mul(precision),
                            new bigNumber(5000000).mul(precision),
                            new bigNumber(7000000).mul(precision),
                        ]
                    )
                }
            )
            .then((instance) => {
                nodeAllocation = instance
            })
            .then(() => {
                    return phases.new(
                        node.address,
                        nodeAllocation.address,
                        new bigNumber(10).mul(precision),
                        new bigNumber(0).mul(precision),
                        new bigNumber(750000).mul(precision),
                        preICOSince,
                        preICOTill,
                        new bigNumber(10).mul(precision),
                        new bigNumber(1000000).mul(precision),
                        new bigNumber(9800000).mul(precision),
                        iCOSince,
                        iCOTill
                    )
                }
            )
    });

});