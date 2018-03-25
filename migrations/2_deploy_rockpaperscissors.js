var RockPaperScissors = artifacts.require("RockPaperScissors"); 

module.exports = function(deployer, network, accounts) {
	deployer.deploy(RockPaperScissors, 1000, {from: accounts[0]});
}