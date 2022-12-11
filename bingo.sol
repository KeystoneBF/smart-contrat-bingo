pragma solidity >=0.5.0;

contract Bingo {
    event NewCard(uint cardId, uint[25] card);
    event NewBallDrawn(uint number);

    address payable owner;
    uint cardPrice = 0.001 ether;
    address payable winner;    

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

    //função para comprar cartelas (mínimo 1 e máximo 4) baseado no valor enviado na transação
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

    // Função para sortear a bola da rodada
    // Somente o dono do contrato pode chamar essa função
    function raffleBall() external onlyOwner {
        uint luckyNumber;
        do {
            luckyNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 75;
        } while (drawnNumbers[luckyNumber] == 1);
        drawnNumbers[luckyNumber] = 1;
        emit NewBallDrawn(luckyNumber);
    }

    //função para criar uma nova cartela
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

    //função para declarar que completou a cartela
    function shoutBingo(uint _cardId) external {

    }

    //função para verificar se houve de fato um ganhador
    function verifyWinner() public {

    }

    //função para verificar se houve um ganhador
    function withdrawPrize() public {

    }
}