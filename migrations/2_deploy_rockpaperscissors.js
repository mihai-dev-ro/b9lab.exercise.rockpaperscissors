var RockPaperScissors = artifacts.require("RockPaperScissors"); 

module.exports = function(deployer, network, accounts) {
	deployer.deploy(RockPaperScissors, 100, 100, {from: accounts[0]});
}