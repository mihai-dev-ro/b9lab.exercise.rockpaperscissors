pragma solidity ^0.4.18;

import "./Pausable.sol";

contract RockPaperScissors is Pausable {

	enum Stage {
		Enrolling, 
		SubmittingPositions
	}

	enum PositionChoice { Rock, Paper, Scissors}

	struct PlayerPosition {
		address sender;
        uint wagerDeposited;
        uint wagerRefunded;
		bytes32 committedPosition;
		PositionChoice position;
		bool isEnrolled;
		bool isSubmitted;
	} 

	uint constant DURATION_MAX = 4 * 7 * 24 * 3600 / 15; // ariund 4 weeks 

    // stage of the current round of the game
	Stage public currentStage = Stage.Enrolling;
	// the official wager for any round of the game 
    uint public wager;
    // duration of any round of the game
    uint public duration;
    // deadline for the current rpund
    uint public lastBlock;
    // players in the curret round of the game
    PlayerPosition[2] public players;
    // kees the balances of all players
    mapping(address => uint) public balanceOf;

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
	event LogWithdraw(address indexed sender, uint value);
	event LogRefund(address indexed sender, uint value);

	modifier isInStage(Stage _stage) {
		require (_stage == currentStage);

		_;
	}

	modifier isOngoingRound() {
		require(hasExpired() == false);

		_;
	}

	function nextStage() public {
        if (currentStage == Stage.SubmittingPositions) 
            reset();
        else
		  currentStage = Stage(uint(currentStage) + 1);
	}

    function reset() public {
        currentStage = Stage.Enrolling;
        lastBlock = block.number + duration;
        delete players;
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

		wager = wagerAmount;
        duration = blockDuration;
        lastBlock = block.number + blockDuration;
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

    function getWinners()
        public 
        view
        returns(address winner1, address winner2)  
    {
        // if draw, then both win
        if (players[0].position == players[1].position) {
            return (players[0].sender, players[1].sender);
        }

        if (players[0].position == PositionChoice.Rock) {
            if (players[1].position == PositionChoice.Scissors) 
                winner1 = players[0].sender;
            else
                winner1 = players[1].sender;
        }

        if (players[0].position == PositionChoice.Scissors) {
            if (players[1].position == PositionChoice.Paper) 
                winner1 = players[0].sender;
            else
                winner1 = players[1].sender;
        }

        if (players[0].position == PositionChoice.Paper) {
            if (players[1].position == PositionChoice.Rock) 
                winner1 = players[0].sender;
            else
                winner1 = players[1].sender;
        }


        return (winner1, 0x0); 
    }

	function enroll(bytes32 positionHash) 
		public 
		payable
        onlyIfRunning 
		isOngoingRound
		isInStage(Stage.Enrolling) 
		returns(bool successful) 
	{
		// make sure the deoosited amount is exactly the agreed value of 
		// the wager
		require(msg.value == wager);

		// get the player that hasn't erolled yet
		PlayerPosition storage player = (
			players[0].isEnrolled == false ? players[0] : players[1]
		);

		// set the choices of the player
		player.sender = msg.sender;
		// make sure that the players are different 
		require(players[0].sender != players[1].sender);

		player.committedPosition = positionHash;
		player.isEnrolled = true;
		player.wagerDeposited = msg.value;

		if (players[0].isEnrolled && players[1].isEnrolled) 
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
        onlyIfRunning
		isOngoingRound
		isInStage(Stage.SubmittingPositions)
		returns(bool successful)
	{
		// make sure the player that submits is either alice or bob
		require(msg.sender == players[0].sender || 
            msg.sender == players[1].sender);

		// get the player 
		PlayerPosition storage player = (
			players[0].sender == msg.sender ? players[0] : players[1]
		);

		// validate the positionHash
		require(hashThat(positionChoice, salt) == player.committedPosition);

		// set the position
		player.position = positionChoice;
		player.isSubmitted = true;
        LogSubmittedPosition(msg.sender, positionChoice, salt);

        // if both players had sumitted their position,
        // execute the game rules and distribute the winnings
		if (players[0].isSubmitted && players[1].isSubmitted) {
			// ditribute the total wager to the winner(s)
            uint totalWager = players[0].wagerDeposited + 
                players[1].wagerDeposited;
            
            var (winner1, winner2) = getWinners();
            if (winner2 == 0x0) {
                // single winner
                balanceOf[winner1] += totalWager;
                // set the isRewarded flag
            } else {
                // both winners, each get half
                balanceOf[winner1] += totalWager / 2;
                balanceOf[winner2] += totalWager / 2;
            }

            // round ended
			// reset the game
			reset();
		}

		return true;
	}

	function withdraw() 
		public
        onlyIfRunning 
		returns(bool successful) 
	{
		
        // should have weis
        require(balanceOf[msg.sender] > 0);

        // optimistic accounting
        uint amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;

        // event
        LogWithdraw(msg.sender, amount);

        // sending the weis
		msg.sender.transfer(amount);

		return true;
	}

	function requestRefund() 
        public
        onlyIfRunning 
        returns(bool successful) 
    {
		// the round has expired, each player recovers the wager
		require(hasExpired() == true);
		// there is weis in the game
        require(players[0].wagerDeposited + players[1].wagerDeposited > 0); 
		// the sender is one of the players
		require(msg.sender == players[0].sender || 
            msg.sender == players[1].sender);
		
		// get the player 
		PlayerPosition storage player = (
			msg.sender == players[0].sender ? players[0] : players[1]
		);
		// the sender has deposited the wager and 
		// did not get any previous refund
		require(player.wagerDeposited > 0);
		require(player.wagerRefunded == 0);

		player.wagerRefunded = player.wagerDeposited;

        // reset if all the refunds in the current round have been processed
        if(  
            (players[0].wagerRefunded == players[0].wagerDeposited) 
            &&
            (players[1].wagerRefunded == players[1].wagerDeposited)
        ) 
        {
            reset();
        }

		LogRefund(msg.sender, player.wagerRefunded);
		msg.sender.transfer(player.wagerRefunded);

		return true;
	}

}