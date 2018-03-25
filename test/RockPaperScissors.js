const RockPaperScissors = artifacts.require("RockPaperScissors");
const Promise = require("bluebird");
const expectedExceptionPromise = require(
	"../utils/expected_exception_testRPC_and_geth.js"
);
web3.eth.makeSureAreUnlocked = require(
	"../utils/makeSureAreUnlocked.js"
);
web3.eth.makeSureHasAtLeast = require(
	"../utils/makeSureHasAtLeast.js"
);
Promise.promisifyAll(web3.eth, {suffix: "Promise"});


describe("RockPaperScissors", (accounts) => {

	let wager = web3.toWei(100, "gwei");

	before("should prepare accounts", () => {
        let coinbase = accounts[0];

        // we need 4 accounts 
        assert.isAtLeast(accounts.length, 4, "should be at least " + 
            "4 accounts available for testing");

        return web3.eth.makeSureAreUnlocked(
            [accounts[0], accounts[1], accounts[2], accounts[3]]
        ).then(strings => {
            return web3.eth.makeSureHasAtLeast(
                coinbase, 
                [accounts[1], accounts[2], accounts[3]],
                web3.toWei(10, "ether")
            );    
        })
    });

    beforeEach("should deploy a new instance of the contract", () => {
    	return RockPaperScissors.new(wager, {from: accounts[0]});
    });

});