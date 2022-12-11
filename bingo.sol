pragma solidity >=0.5.0;

contract Bingo {
    event GameStart(string message);
    event GameOver(string message);
    event NewCard(uint cardId, uint[25] card);
    event NewBallDrawn(uint number);

    address payable owner;
    address payable winner;
    uint cardPrice = 0.001 ether;

    uint[75] public drawnNumbers;
    uint[25][] public cards;
    uint[25] lastGeneratedCard;

    mapping (uint => address) public cardToOwner;
    mapping (address => uint) ownerCardCount;

    constructor() {
        owner =  payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can call this function!");
        _;
    }

    modifier onlyWinner {
        require(msg.sender == winner, "Only the bingo winner can call this function!");
        _;
    }

    modifier onlyOwnerOf(uint _cardId) {
        require(msg.sender == cardToOwner[_cardId]);
        _;
    }

    // função para comprar cartelas (mínimo 1 e máximo 4) baseado no valor enviado na transação
    function buyCard() external payable {
        require(msg.value >= cardPrice, "Insufficient amount!");
        uint quantity = msg.value / cardPrice;
        require(quantity + ownerCardCount[msg.sender] <= 4, "You cannot have more than 4 cards");

        for (uint i = 0; i < quantity ; i++) {
            _generateCard();
        }

        uint change = msg.value % cardPrice;
        payable(msg.sender).transfer(change);
    }

    // função para sortear a bola da rodada
    // somente o dono do contrato pode chamar essa função
    function raffleBall() external onlyOwner {
        uint luckyNumber;
        do {
            luckyNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 75;
        } while (drawnNumbers[luckyNumber] == 1);
        drawnNumbers[luckyNumber] = 1;
        emit NewBallDrawn(luckyNumber);
    }

    // função para criar uma nova cartela
    function _generateCard() private {
        uint counter = 0;
        for (uint column = 0; column < 5; column++) {
            for (uint line = 0; line < 5; line++) {
                uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 15 + 15 * column;
                lastGeneratedCard[counter] = random;
                counter++;
            }
        }
        cards.push(lastGeneratedCard);

        uint id = cards.length - 1;
        cardToOwner[id] = msg.sender;
        ownerCardCount[msg.sender]++;
        emit NewCard(id, lastGeneratedCard);
    }

    // função para declarar que completou a cartela
    function shoutBingo(uint _cardId) external onlyOwnerOf(_cardId) {
        if(_isWinner(cards[_cardId])) {
            winner = payable(msg.sender);
            emit GameOver("BINGO!");
        }
    }

    // função para verificar se houve de fato um ganhador
    function _isWinner(uint[25] memory _card) private view returns(bool) {
        bool result = true;
        for(uint i = 0; i < _card.length; i++) {
            uint index = _card[i];
            if(drawnNumbers[index] == 0) {
                result = false;
            }
        }
        return result;
    }

    // função para o ganhador retirar seu prêmio
    /// @dev Por enquanto o prêmio está como 100% do valor arrecadado
    function withdrawPrize() public onlyWinner {
        winner.transfer(address(this).balance);
    }
}