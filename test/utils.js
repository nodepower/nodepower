var BigNumber = require('bignumber.js');

var gasToUse = 0x47E7C4;

function receiptShouldSucceed(result) {
    return new Promise(function(resolve, reject) {
        var receipt = web3.eth.getTransaction(result.tx);

        if(result.receipt.gasUsed == gasToUse) {
            try {
                assert.notEqual(result.receipt.gasUsed, gasToUse, "tx failed, used all gas");
            }
            catch(err) {
                reject(err);
            }
        }
        else {
            console.log('gasUsed',result.receipt.gasUsed);
            resolve();
        }
    });
}

function receiptShouldFailed(result) {
    return new Promise(function(resolve, reject) {
        var receipt = web3.eth.getTransaction(result.tx);

        if(result.receipt.gasUsed == gasToUse) {
            resolve();
        }
        else {
            try {
                assert.equal(result.receipt.gasUsed, gasToUse, "tx succeed, used not all gas");
            }
            catch(err) {
                reject(err);
            }
        }
    });
}

function catchReceiptShouldFailed(err) {
    if (err.message.indexOf("invalid opcode") == -1) {
        throw err;
    }
}

function balanceShouldEqualTo(instance, address, expectedBalance, notCall) {
    return new Promise(function(resolve, reject) {
        var promise;

        if(notCall) {
            promise = instance.balanceOf(address)
                .then(function() {
                    return instance.balanceOf.call(address);
                });
        }
        else {
            promise = instance.balanceOf.call(address);
        }

        promise.then(function(balance) {
            try {
                assert.equal(balance.valueOf(), expectedBalance, "balance is not equal");
            }
            catch(err) {
                reject(err);

                return;
            }

            resolve();
        });
    });
}

function timeout(timeout) {
    return new Promise(function(resolve, reject) {
        setTimeout(function() {
            resolve();
        }, timeout * 1000);
    })
}

function getEtherBalance(_address) {
    return web3.eth.getBalance(_address);
}

function checkEtherBalance(_address, expectedBalance) {
    var balance = web3.eth.getBalance(_address);

    assert.equal(balance.valueOf(), expectedBalance.valueOf(), "address balance is not equal");
}

function getTxCost(result) {
    var tx = web3.eth.getTransaction(result.tx);

    return result.receipt.gasUsed * tx.gasPrice;
}


function getPhase(instance, id) {
    return instance.phases.call(id)
        .then(function(obj) {
            if(obj.length == 7) {
                return {
                    price: obj[0].valueOf(),
                    minInvest: obj[1].valueOf(),
                    softCap: obj[2].valueOf(),
                    hardCap: obj[3].valueOf(),
                    since: obj[4].valueOf(),
                    till: obj[5].valueOf(),
                    isSucceed: obj[6].valueOf(),
                }
            }
            if(obj.length == 3) {
                return {
                    priceShouldMultiply: obj[0].valueOf(),
                    price: obj[1].valueOf(),
                    maxAmount: obj[2].valueOf(),
                }
            }

            return {
                price: obj[0].valueOf(),
                maxAmount: obj[1].valueOf(),
            }
        });
}

function checkPhase(phase, price, minInvest, softCap, hardCap, since, till, isSucceed) {
    return new Promise(function(resolve, reject) {
        try {
            assert.equal(phase.price, price, "phase price is not equal");
            assert.equal(phase.minInvest, minInvest, "phase minInvest is not equal");
            assert.equal(phase.softCap, softCap, "phase softCap is not equal");
            assert.equal(phase.hardCap, hardCap, "phase hardCap is not equal");
            assert.equal(phase.since, since, "phase since is not equal");
            assert.equal(phase.till, till, "phase till is not equal");
            assert.equal(phase.isSucceed, isSucceed, "phase isSucceed is not equal");

            resolve();
        }
        catch(err) {
            reject(err);
        }
    });
}

module.exports = {
    receiptShouldSucceed: receiptShouldSucceed,
    receiptShouldFailed: receiptShouldFailed,
    catchReceiptShouldFailed: catchReceiptShouldFailed,
    balanceShouldEqualTo: balanceShouldEqualTo,
    timeout: timeout,
    getEtherBalance: getEtherBalance,
    checkEtherBalance: checkEtherBalance,
    getTxCost: getTxCost,
    getPhase: getPhase,
    checkPhase: checkPhase,
};