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
		bool isEnrolled;
		bool isSubmitted;
		bool isRewarded;
		uint wagerDeposited;
		uint wagerRefunded;
	} 

	uint constant DURATION_MAX = 4 * 7 * 24 * 3600 / 15; // ariund 4 weeks 

	Stage public currentStage = Stage.Enrolling;
	PlayerPosition public alice;
	PlayerPosition public bob;
	uint public wager;
	uint public lastBlock;

	event LogEnrolled(
		address indexed sender, 
		bytes32 committedPosition,
		uint value
	);
	event LogSubmittedPosition(
		address indexed sender, 
		PositionChoice position, 
		bytes32 salt
	);
	event LogReward(address indexed sender, uint value);
	event LogRefund(address indexed sender, uint value);

	modifier isInStage(Stage _stage) {
		require (_stage == currentStage);

		_;
	}

	modifier isOngoing() {
		require(hasExpired() == false);

		_;
	}

	function nextStage() public {
		currentStage = Stage(uint(currentStage) + 1);
	}

    function hasExpired() public view returns(bool) {
        return (block.number > lastBlock);
    }

	function RockPaperScissors(uint wagerAmount, uint blockDuration) public {
		// the wager that each placer needs to deposit
		require(wagerAmount >= 0);
		// the deadline after which the game expires
		require(blockDuration > 0);
		require(blockDuration <= DURATION_MAX);

        lastBlock = block.number + blockDuration;
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

	function enroll(bytes32 positionHash) 
		public 
		payable 
		isOngoing
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
		player.wagerDeposited = msg.value;

		if (alice.isEnrolled && bob.isEnrolled) 
			// all players have been enrolled, 
			// move the game to next stage = submitting positions
			nextStage();

		LogEnrolled(msg.sender, positionHash, msg.value);

		return true;
	}

	function submitPosition(
		PositionChoice positionChoice,
		bytes32 salt
	) 
		public 
		isOngoing
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

		LogSubmittedPosition(msg.sender, positionChoice, salt);

		return true;
	}

	
	function getWinners()
		public 
		view
		isInStage(Stage.Rewarding) 
		returns(address winner1, address winner2)  
	{
		// if draw, then both win
        if (alice.position == bob.position) {
            return (alice.sender, bob.sender);
        }

        if (alice.position == PositionChoice.Rock) {
            if (bob.position == PositionChoice.Scissors) 
                winner1 = alice.sender;
            else
                winner1 = bob.sender;
        }

        if (alice.position == PositionChoice.Scissors) {
            if (bob.position == PositionChoice.Paper) 
                winner1 = alice.sender;
            else
                winner1 = bob.sender;
        }

        if (alice.position == PositionChoice.Paper) {
            if (bob.position == PositionChoice.Rock) 
                winner1 = alice.sender;
            else
                winner1 = bob.sender;
        }


		return (winner1, 0x0); 
	}

	function reward() 
		public 
		isOngoing
		isInStage(Stage.Rewarding)
		returns(bool successful) 
	{
		// no more winnings to reclaim
		require(this.balance > 0);

		// make sure the game has not expired
		require(hasExpired() == false);

		uint amount;

        var (winner1, winner2) = getWinners();

        // if just one winner
		if (winner2 == 0x0) {
			// ONE WINNER: make sure only the winner can reclaim the winnings
            require(msg.sender == winner1);
            amount = this.balance;
		} else {
			// DRAW: make sure the player that submits is either alice or bob
            require(msg.sender == winner1 || msg.sender == winner2);
            amount = this.balance / 2;
		}

		// get the player 
		PlayerPosition storage player = (
			msg.sender == alice.sender ? alice : bob
		);

		// make sure the player has not been previously rewarded
		require(player.isRewarded == false);

		player.isRewarded = true;
		// move to next stage in case winner withdraws the winnings
		// or in case of draw, both players have withdrawn their share
		if ( (winner2 == 0x0) || (alice.isRewarded && bob.isRewarded))
			nextStage(); 

		LogReward(msg.sender, amount);
		msg.sender.transfer(amount);

		return true;
	}

	function requestRefund() public returns(bool successful) {
		// the game has expired, each player recovers the wager
		require(hasExpired() == true);
		// there is still money in the account
		require(this.balance > 0); 
		// the sender is one of the players
		require(msg.sender == alice.sender || msg.sender == bob.sender);
		
		// get the player 
		PlayerPosition storage player = (
			msg.sender == alice.sender ? alice : bob
		);
		// the sender has not been rewarded
		require(player.isRewarded == false);
		// the sender has deposited the wager and 
		// did not get any previous refund
		require(player.wagerDeposited > 0);
		require(player.wagerRefunded == 0);

		player.wagerRefunded = player.wagerDeposited;

		LogRefund(msg.sender, player.wagerRefunded);
		msg.sender.transfer(player.wagerRefunded);

		return true;
	}

}