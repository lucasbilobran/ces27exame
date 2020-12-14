pragma solidity ^0.4.2;

contract Betting {
    
    // Owener of bettng event
    address public owner;
    uint ownerFee;
    uint contractState; // 0-valid, 1-locked or 2-finished
    uint minBetScorePossible;
    uint maxBetScorePossible;
    mapping(uint => uint) prizePoportions;
    uint maxScoreForPrize;
    

    // Model a team
    struct Team {
        uint id;
        string name;
    }
    Team team1;
    Team team2;
    
    // Model a Bet
    struct Bet {
        uint team1Score;
        uint team2Score;
    }
 
    // Model a Player
    struct Player {
      uint256 amountBet;
      Bet bet;
      uint score;
    }
    // Store accounts that have bet
    mapping(address => Player) public players;
    mapping(address => bool) public activePlayer;
    address [] playersAcc;
    
    
    
    constructor() public {
        owner = msg.sender;
        contractState = 0; // valid
        minBetScorePossible = 0;
        maxBetScorePossible = 50;
        setPrizeProportions();
        ownerFee = 2; // porcentage fot total prize
        addTeams("Brasil", "Argentina"); // (Team1, Team2) 
    }
    
    function addTeams (string _team1name, string _team2name) private {
        team1 = Team(1, _team1name);
        team2 = Team(2, _team2name);
    }
    
    function lockEvent () payable public {
        require(msg.sender == owner);
        require(contractState == 0);
        
        contractState = 1;
    }
    
    // map (score => porcentage of prize for that score category)
    function setPrizeProportions() private {
        prizePoportions[0] = 762; // 16/21 = 0.7619 
        prizePoportions[1] = 190; // 4/21  = 0.190
        prizePoportions[2] = 48;  // 1/21  = 0.0476
        maxScoreForPrize = 2;
    }
    
    function isEqual(Bet _bet, Bet winnerBet) private pure returns (bool){
        if (_bet.team1Score == winnerBet.team1Score && _bet.team2Score == winnerBet.team2Score)
            return true;
        
        return false;
    }
    
    function evaluateScore(Bet _bet, Bet winnerBet) private pure returns (uint) {
        uint score = 0;
        
        if (_bet.team1Score > winnerBet.team1Score)
            score += _bet.team1Score - winnerBet.team1Score;
        else
            score += winnerBet.team1Score - _bet.team1Score;
            
        if (_bet.team2Score > winnerBet.team2Score)
            score += _bet.team2Score - winnerBet.team2Score;
        else
            score += winnerBet.team2Score - _bet.team2Score;
        
        return score;
    }
    
    
    // Owner function only
    function endEvent(uint _finalTeam1Score, uint _finalTeam2Score) payable public {
        require(msg.sender == owner);
        require(_finalTeam1Score >= minBetScorePossible && _finalTeam2Score >= minBetScorePossible);
        require(_finalTeam1Score <= maxBetScorePossible && _finalTeam2Score <= maxBetScorePossible);
        require(contractState == 0 || contractState == 1);
        
        
        Bet memory winnerBet = Bet(_finalTeam1Score, _finalTeam2Score);
        uint256 totalPrize = 0;
        address pAcc;
        Player memory currPlayer;
        uint256 amountToTransfer = 0;
        uint256 score0Balance = 0; 
        uint256 score1Balance = 0;  
        uint256 score2Balance = 0; 
        
        
        
        for(uint i = 0; i < playersAcc.length; i++){
            pAcc = playersAcc[i];
            if (isEqual(players[pAcc].bet, winnerBet)) { // winner bet
                //players[pAcc].score = 0; // it's already zero
                score0Balance += players[pAcc].amountBet;
            }
            else { // loserbet
                players[pAcc].score = evaluateScore(players[pAcc].bet, winnerBet); 
                totalPrize += players[pAcc].amountBet;
                
                if (players[pAcc].score == 1)
                    score1Balance += players[pAcc].amountBet;
                else if (players[pAcc].score == 2)
                    score2Balance += players[pAcc].amountBet;
            }
            
        }
        
        totalPrize = (totalPrize*(100-ownerFee))/100;
        
        
        // individualPrize = betAmount + totalPrize * proportion
        for(i = 0; i < playersAcc.length; i++){
            amountToTransfer = 0;
            pAcc = playersAcc[i];
            currPlayer = players[pAcc];
            
            if (isEqual(currPlayer.bet, winnerBet))
                amountToTransfer += currPlayer.amountBet;
            
            if(currPlayer.score <= maxScoreForPrize) {
                // players[pAcc].amountBet + totalPrize*proportion
                if (currPlayer.score == 0 && score0Balance > 0) {
                    amountToTransfer += (totalPrize*prizePoportions[0]*currPlayer.amountBet)/(1000*score0Balance);
                }
                else if (currPlayer.score == 1 && score1Balance > 0) {
                    amountToTransfer += (totalPrize*prizePoportions[1]*currPlayer.amountBet)/(1000*score1Balance);
                }
                else if (currPlayer.score == 2 && score2Balance > 0) {
                    amountToTransfer += (totalPrize*prizePoportions[2]*currPlayer.amountBet)/(1000*score2Balance);
                }
                
                transferPrize(pAcc, amountToTransfer);
            }
        }
        
        // transfer the money left
        transferPrize(owner, address(this).balance);
        
        contractState = 2;
    }
    
    
    function transferPrize(address winner, uint256 prize) private {
        require(address(this).balance >= prize);
        winner.transfer(prize);
    }

    // Players Functions
    function bet(uint _team1Score, uint _team2Score) payable public {
        // require a valid score
        require(_team1Score >= minBetScorePossible && _team2Score >= minBetScorePossible);
        require(_team1Score <= maxBetScorePossible && _team2Score <= maxBetScorePossible);
        
        // require a valid active contract
        require(contractState == 0);
        
        Player memory currentPlayer;
        Bet memory currentBet = Bet(_team1Score, _team2Score);
        
        if (activePlayer[msg.sender]) {
            currentPlayer = players[msg.sender];
            if (_team1Score == currentPlayer.bet.team1Score && _team2Score == currentPlayer.bet.team2Score) {
                players[msg.sender].amountBet += msg.value;
            }
        }
        else {
            activePlayer[msg.sender] = true;
            players[msg.sender] = Player(msg.value, currentBet, 0);
            playersAcc.push(msg.sender);
        }
    
    }

    // Return total contract balance
    function getEventBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // Return team name
    function getTeamName(uint _teamId) public view returns (string) {
        if (_teamId == 1)
            return team1.name;

        return team2.name;
    }
    
    // Return team name
    function getEventState() public view returns (string) {
        if (contractState == 0)
            return "Valid";
        else if(contractState == 1)
            return "Locked";
        else 
            return "Finished";
    }
    
}