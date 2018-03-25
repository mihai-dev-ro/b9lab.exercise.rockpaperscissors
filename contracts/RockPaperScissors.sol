pragma solidity ^0.4.18;

import "./Pausable.sol";

contract RockPaperScissors is Pausable {

	enum Stage {
		Enrolling, 
		SubmittingPositions, 
		Rewarding,
		Closed
	}

	enum PositionChoice { Rock, Paper, Scissors}

	struct PlayerPosition {
		address sender;
		bytes32 committedPosition;
		PositionChoice position;
		bool isSubmitted;
		bool isEnrolled;
		bool isRewarded;
	} 

	Stage public currentStage = Stage.Enrolling;
	PlayerPosition public alice;
	PlayerPosition public bob;
	uint wager;

	event LogPlayerEnrolled(
		address indexed sender, 
		bytes32 committedPosition,
		uint value
	);
	event LogPlayerSubmittedPosition(
		address indexed sender, 
		PositionChoice position, 
		bytes32 salt
	);
	event LogRewardTransferred(address indexed sender, uint value);

	modifier isInStage(Stage _stage) {
		require (_stage == currentStage);

		_;
	}

	function nextStage() public {
		currentStage = Stage(uint(currentStage) + 1);
	}

	function RockPaperScissors(uint wagerAmount) public {
		// the wager that each placer needs to deposit
		require(wagerAmount >= 0);
		wager = wagerAmount;
	}

	function hashThat(
		PositionChoice positionChoice, 
		bytes32 salt
	) 
		public 
		view 
		returns(bytes32)
	{
		return keccak256(this, uint(positionChoice), salt);
	}

	function enrol(bytes32 positionHash) 
		public 
		payable 
		isInStage(Stage.Enrolling) 
		returns(bool successful) 
	{
		// make sure the deoosited amount is exactly the agreed value of 
		// the wager
		require(msg.value == wager);

		// get the player that hasn't erolled yet
		PlayerPosition storage player = (
			alice.isEnrolled == false ? alice : bob
		);

		// set the choices of the player
		player.sender = msg.sender;
		// make sure that the players are different 
		require(alice.sender != bob.sender);

		player.committedPosition = positionHash;
		player.isEnrolled = true;

		if (alice.isEnrolled && bob.isEnrolled) 
			// all players have been enrolled, 
			// move the game to next stage = submitting positions
			nextStage();

		LogPlayerEnrolled(msg.sender, positionHash, msg.value);

		return true;
	}

	function submitPosition(
		PositionChoice positionChoice,
		bytes32 salt
	) 
		public 
		isInStage(Stage.SubmittingPositions)
		returns(bool successful)
	{
		// make sure the player that submits is either alice or bob
		require(msg.sender == alice.sender || msg.sender == bob.sender);

		// get the player 
		PlayerPosition storage player = (
			alice.sender == msg.sender ? alice : bob
		);

		// validate the positionHash
		require(hashThat(positionChoice, salt) == player.committedPosition);

		// set the position
		player.position = positionChoice;
		player.isSubmitted = true;

		if (alice.isSubmitted && bob.isSubmitted) {
			// all the players have submitted their positions,
			// move to next stage = rewarding
			nextStage();
		}

		LogPlayerSubmittedPosition(msg.sender, positionChoice, salt);

		return true;
	}

	function greatest(
		PositionChoice a, 
		PositionChoice b
	) 
		public 
		pure 
		returns(PositionChoice) 
	{
		return (uint(a) >= uint(b) ? a: b);
	}
	function smallest(
		PositionChoice a, 
		PositionChoice b
	) 
		public 
		pure 
		returns(PositionChoice) 
	{
		return (uint(a) <= uint(b) ? a: b);
	}

	function isDraw() 
		public 
		view 
		isInStage(Stage.Rewarding) 
		returns(bool) 
	{
		return (alice.position == bob.position);
	}

	function getWinner()
		public 
		view
		isInStage(Stage.Rewarding) 
		returns(address winner)  
	{
		// if draw, then no one wins
		require(isDraw() == false);

		// distance between positions in the collection of choices
		int distance = int(uint(alice.position) - uint(bob.position));
		// if positions are in the immediate vecinity
		// i.e.: Rock-Paper or Paper-Scissors
		if (distance == 1 || distance == -1) {
			if (alice.position == greatest(alice.position, bob.position)) 
				winner = alice.sender;
			else
				winner = bob.sender;
		}

		// if positions are not close to each other 
		// i.e.: Rock - Scissors
		if (distance == 2 || distance == -2){
			if (alice.position == smallest(alice.position, bob.position)) 
				winner = alice.sender;
			else
				winner = bob.sender;
		}

		return winner; 
	}

	function reclaimWinnings() 
		public 
		isInStage(Stage.Rewarding)
		returns(bool successful) 
	{
		// make sure the player that submits is either alice or bob
		require(msg.sender == alice.sender || msg.sender == bob.sender);

		// if not draw, only the winner can reclaim the winnings
		if (!isDraw())
			require(msg.sender == getWinner());

		// get the current player
		PlayerPosition storage player = (alice.isSubmitted ? alice : bob);

		// make sure the pplayer has not been previously rewarded
		require(player.isRewarded == false);

		uint amount = this.balance;
		// if draw, then no one wins, and each rectrieves the wager	
		if (isDraw()) {
			amount = this.balance / 2;
		} 
		player.isRewarded = true;
		// move to next stage in case winner withdraws the winnings
		// or in case of draw, both players have withdrawn their share
		if (!isDraw() || (alice.isRewarded && bob.isRewarded))
			nextStage(); 

		LogRewardTransferred(msg.sender, amount);
		msg.sender.transfer(amount);

		return true;
	}

}