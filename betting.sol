pragma solidity ^0.4.2;

contract Betting {
    
    // Owener of bettng event
    address public owner;
    
    // Model a team
     struct Team {
         uint id;
         string name;
         uint256 amount;
     }
     // Store Team Count
    uint public teamCount;
    // Store accounts that have bet
    mapping(uint => Team) public teams;
    
    // Model a Player
    struct Player {
      uint256 amountBet;
      uint teamSelected;
    }
    // Store accounts that have bet
    mapping(address => Player) public players;
    mapping(address => bool) public activePlayers;
    address [] playersAcc;
    
    
    constructor() public {
        owner = msg.sender;
        addTeam("Brasil");
        addTeam("Argentina");
    }
    
    function addTeam (string _name) private {
        teamCount ++;
        teams[teamCount] = Team(teamCount, _name, 0);
    }
    
    function teamsExist (uint _id) public view returns (bool) {
        return _id > 0 && _id <= teamCount;
    }
    
    // Owner function only
    function endEvent(uint winnerTeamId) payable public {
        require(msg.sender == owner);
        
        uint256 winnerTeamAmount = teams[winnerTeamId].amount;
        uint256 totalPrize = 0;
        address pAcc;
        uint256 proportion;
        
        for(uint256 i = 1; i <= teamCount; i++){
            if (teams[i].id != winnerTeamId)
                totalPrize += teams[i].amount;
        }
        
        // individualPrize = betAmount + totalPrize * proportion
        for(i = 0; i < playersAcc.length; i++){
            pAcc = playersAcc[i];
            if(players[pAcc].teamSelected == winnerTeamId){
                proportion = players[pAcc].amountBet/winnerTeamAmount;
                transferPrize(pAcc, players[pAcc].amountBet + totalPrize*proportion);
            }
        }
        
        // Delete everything
        //for(i = 1; i <= teamCount; i++){
        //    teams[i].amount = 0;
        //}
        // TODO: search how to destroy contract
        
    }
    
    
    function transferPrize(address winner, uint256 prize) private {
        require(address(this).balance >= prize);
        winner.transfer(prize);
    }

    // Players Functions
    function bet(uint _teamIdSelected) payable public {
        // require a valid team
        require(teamsExist(_teamIdSelected));
        
        teams[_teamIdSelected].amount += msg.value;
        
        // update player information
        if(activePlayers[msg.sender]) 
            players[msg.sender].amountBet += msg.value;
        else {
            players[msg.sender].amountBet = msg.value;
            activePlayers[msg.sender] = true;
            players[msg.sender].teamSelected = _teamIdSelected;
            // save playersAcc
            playersAcc.push(msg.sender);
        }
            

    }

    // Return total amount of bets
    function getEventBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // Return team name
    function getTeamName(uint _teamId) public view returns (string) {
        return teams[_teamId].name;
    }
    
    // Return team amount
    function getTeamAmount(uint _teamId) public view returns (uint256) {
        return teams[_teamId].amount;
    }
}