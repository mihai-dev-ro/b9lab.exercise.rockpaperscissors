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


contract("RockPaperScissors", (accounts) => {
    const GamePositionChoice = {"Rock": 0, "Paper": 1, "Scissors": 2}; 

    let wager = web3.toWei(100, "gwei");

    before("prepare accounts", () => {
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

    describe("contract creation", () => {
        if("should reject a contract deployment transaction " + 
            "that sends value", () => {

        });

        it("should reject a contract deployment transaction with " + 
            "wager that is non-positive", 
            () => {

        });

        it("should reject a contract deployment transaction with " +
            "blockDuration that is non-positive", 
            () => {})

        it("should reject a contract deployment transaction with " + 
            "blockDuration greater than DURATION_MAX: 161280 blocks", 
            () => {

        });
    });

    describe("hashing", () => {
        before("prepare contract", () => {
            return RockPaperScissors.new(
                wagerAmount, 
                blockDuration, 
                {from: accounts[0]}
            );
        });

        it("hashing the same positionChoice & salt from 2 instances " + 
            "should not be identical", 
            () => {

        });

        it("hashing the same positionChoice with different salt value " + 
            "should not be identical", 
            () => {

        });        
    });


    describe("players enrolling", () => {
        let wagerAmount = 100;
        let blockDuration = 100;
        let alice = accounts[1];
        let bob = accounts[2];
        let carol = accounts[3];
        let alicePositionCommitedProof;
        let bobPositionCommitedProof;
        let instance;

        beforeEach("prepare contract", () => {
            return RockPaperScissors.new(
                wagerAmount, 
                blockDuration, 
                {from: accounts[0]}
            ).then(i => instance  = i);
        });

        it("should reject enrollment without depositing a wager", 
            () => {

        });

        it("should reject enrollment that sends value strictly equal " +
            "to the official wager value", 
            () => {
                
        });

        it("should not allow the same user to enroll again", () => {

        })        

        it("should emit a single event on enrollment", () => {

        });

        it("should keep the weis in the contract on enrollment", () => {

        });

        it("should not accept enrollement, once two players " + 
            "have already enrolled", () => {

        });

        it("should keep in the contract the wager and the commited position " + 
            "after a successful enrollment", () => {

        });
    });


    describe("plyers submitting position", () => {
        let wagerAmount = 100;
        let blockDuration = 100;
        let alice = accounts[1];
        let bob = accounts[2];
        let carol = accounts[3];
        let alicePosition = GamePositionChoice.Rock;
        let aliceHashingSalt = "tkugkl";
        let alicePositionCommitedProof;
        let bobPosition = GamePositionChoice.Paper;
        let bobHashingSalt = "bmkkl";
        let bobPositionCommitedProof;
        let carolPosition = GamePositionChoice.Scissors;
        let carolHashingSalt = "cccccc";
        let carolPositionCommitedProof;
        let instance;

        beforeEach("prepare contract", () => {
            return RockPaperScissors.new(
                wagerAmount, 
                blockDuration, 
                {from: accounts[0]}
            ).then(i => instance  = i);
        });

        it("should accept the position commited in enrollment", () => {

        });

        it("should reject a different position, other than the one " +
            "commited during enrollment", () => {

        });

        it("should accept just one submission of the position " + 
            "from the same user", () => {

        });

        it("should not accept submission from users other than " + 
            "those enrolled", () => {

        });

        it("should emit a single event on submitted the position", () => {

        });

        it("should not accept submission, once the two players " + 
            "have already submitted", () => {

        });

        it("should update the player state after a successful " + 
            "submission of position", () => {

        });
    });

    describe("winning position", () => {
        let wagerAmount = 100;
        let blockDuration = 100;
        let alice = accounts[1];
        let bob = accounts[2];
        let alicePosition = GamePositionChoice.Rock;
        let aliceHashingSalt = "tkugkl";
        let alicePositionCommitedProof;
        let bobPosition = GamePositionChoice.Paper;
        let bobHashingSalt = "bmkkl";
        let bobPositionCommitedProof;
        let instance;

        beforeEach("prepare contract", () => {
            return RockPaperScissors.new(
                wagerAmount, 
                blockDuration, 
                {from: accounts[0]}
            ).then(i => instance  = i);
        });

        it("should flag Rock as winner, between " + 
            "Rock & Scissiors", () => {

        });

        it("should flag Scissors as winner, between " + 
            "Scissors & Paper", () => {
            
        });

        it("should flag Paper as winner, between " + 
            "Paper & Rock", () => {
            
        });

        it("should flag as Draw, between " + 
            "Rock & Rock", () => {
            
        });    

        it("should flag as Draw, between " + 
            "Paper & Paper", () => {
            
        });    

        it("should flag as Draw, between " + 
            "Scissors & Scissors", () => {
            
        });        
    });

    define("rewarding the winner(s)", () => {
        let wagerAmount = 100;
        let blockDuration = 100;
        let alice = accounts[1];
        let bob = accounts[2];
        let alicePosition = GamePositionChoice.Rock;
        let aliceHashingSalt = "tkugkl";
        let alicePositionCommitedProof;
        let bobPosition = GamePositionChoice.Paper;
        let bobHashingSalt = "bmkkl";
        let bobPositionCommitedProof;
        let instance;

        beforeEach("prepare contract", () => {
            return RockPaperScissors.new(
                wagerAmount, 
                blockDuration, 
                {from: accounts[0]}
            ).then(i => instance  = i);
        });

        it("should reward the winning player to reclaim all winnings " + 
            "if single winner", () => {

        });

        it("should not allow the any other user other than the winner to " + 
            "get the reward", () => {
                
        });

        it("should the contract be emptied after a sucessful " + 
            "reward of winnings to the single winner", () => {

        });

        it("should the single winner receive all the contract's weis", () => {

        });

        it("should each of players get half of contract's weis in case of  " + 
            "draw", () => {

        });

        it("should update the player state after a successful " + 
            "reward transfer", () => {

        });

        it("should emit a single event on transferring the reward", () => {

        });
    });

    define("refunding", () => {
        let wagerAmount = 100;
        let blockDuration = 100;
        let alice = accounts[1];
        let bob = accounts[2];
        let alicePosition = GamePositionChoice.Rock;
        let aliceHashingSalt = "tkugkl";
        let alicePositionCommitedProof;
        let bobPosition = GamePositionChoice.Paper;
        let bobHashingSalt = "bmkkl";
        let bobPositionCommitedProof;
        let instance;

        beforeEach("prepare contract", () => {
            return RockPaperScissors.new(
                wagerAmount, 
                blockDuration, 
                {from: accounts[0]}
            ).then(i => instance  = i);
        });

        it("should allow a player to withdraw the deposited wager, " + 
            "in case the second player did not enroll in due time", () => {

        });

        it("should allow a player to withdraw the deposited wager, " + 
            "in case the second player did enroll " + 
            "but did not submit in due time", () => {

        });

        it("should allow a player to withdraw the deposited wager, " + 
            "in case the winner did not reclaim the winnings " + 
            "in due time", () => {

        });
    });
});