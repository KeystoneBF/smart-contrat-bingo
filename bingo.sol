// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

contract Bingo {
    event GameStart(string message);
    event GameOver(address winnerAddress);
    event YouWin(address indexed userAddress);
    event YouDidNotWin(address indexed userAddress);
    event NewCard(uint cardId, uint[] card);
    event NewBallDrawn(uint number);

    address payable owner;
    address payable winner;
    uint cardPrice = 0.0003 ether;
    bool started = false;
    uint nonce = 0;

    uint[] public numbers;
    uint[75] public drawnNumbers;
    uint[][] public cards;

    mapping (uint => address) public cardToOwner;
    mapping (address => uint) public ownerCardCount;
    address[] public users;

    constructor() {
        owner =  payable(msg.sender);
        for(uint i=0; i < 75; i++) {
            numbers.push(i + 1);
        }
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Somente o dono do contrato pode chamar essa funcao!");
        _;
    }

    modifier onlyWinner {
        require(msg.sender == winner, "Somente o vencedor do bingo pode chamar essa funcao!");
        _;
    }

    modifier onlyOwnerOf(uint _cardId) {
        require(msg.sender == cardToOwner[_cardId], "Voce so pode verificar cartelas de sua posse!");
        _;
    }

    // função que verifica se o usuário é o dono do contrato
    function isOwner() external view returns(bool) {
        return (msg.sender == owner);
    }

    // função que permite ao dono do contrato mudar o preço da cartela
    function setCardPrice(uint _price) external onlyOwner {
        cardPrice = _price;
    }

    // função para comprar cartelas (mínimo 1 e máximo 4) baseado no valor enviado na transação
    function buyCard() external payable {
        require(msg.value >= cardPrice, "Valor insuficiente!");
        uint quantity = msg.value / cardPrice;
        require(quantity + ownerCardCount[msg.sender] <= 4, "Voce nao pode ter mais de 4 cartelas!");
        require(started == false, "Voce nao pode comprar cartelas depois que o bingo comecou!");

        for (uint i = 0; i < quantity ; i++) {
            _generateCard();
            ownerCardCount[msg.sender]++;
        }
        users.push(msg.sender);
        uint change = msg.value % cardPrice;
        payable(msg.sender).transfer(change);
    }

    // função para resetar a quantidade de cartelas do usuário
    function restartCardCounter() external {
        ownerCardCount[msg.sender] = 0;
    }

    // função para sortear a bola da rodada
    // somente o dono do contrato pode chamar essa função
    function raffleBall() external onlyOwner {
        if(started == false) {
            started = true;
            emit GameStart("Bingo has started!");
        }
        uint random = numbers[uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % numbers.length];
        uint drawnBall = numbers[random];
        nonce++;
        numbers.pop();
        drawnNumbers[drawnBall - 1] = 1;

        emit NewBallDrawn(drawnBall);
    }

    // função para retornar os números sorteados
    function getDrawnNumbers() public view returns (uint[] memory) {
        uint[] memory result = new uint[](75);
        uint counter = 0;
        for (uint i = 0; i < 75; i++) {
            if (drawnNumbers[i] == 1) {
                result[counter] = i + 1;
                counter++;
            }
        }
        return result;
    }

    // função para criar uma nova cartela
    function _generateCard() private {
        uint[] memory lastGeneratedCard = new uint[](25);
        uint[] memory cardNumbers = new uint[](75);
        for (uint i = 0; i < 75; i++) {
            cardNumbers[i] = i + 1;
        }
        for (uint i = 0; i < cardNumbers.length; i++) {
            uint n = i + uint(keccak256(abi.encodePacked(block.timestamp))) % (cardNumbers.length - i);
            uint temp = cardNumbers[n];
            cardNumbers[n] = cardNumbers[i];
            cardNumbers[i] = temp;
        }
        for (uint k = 0; k < 25 ; k++) {
            lastGeneratedCard[k] = cardNumbers[k];
        }
        cards.push(lastGeneratedCard);

        uint id = cards.length - 1;
        cardToOwner[id] = msg.sender;
        emit NewCard(id, lastGeneratedCard);
    }

    // função para retornar as cartelas de um usuário
    /// @dev retorna um array com os ids das cartelas do usuário
    /// @dev a partir do id você pode pegar cada cartela depois, afinal o array cards é público
    function getCardsByOwner(address _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](ownerCardCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < cards.length; i++) {
            if (cardToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    // função para retornar os números de uma cartela a partir do seu Id
    function getCardById(uint _cardId) external view returns(uint[] memory) {
        return cards[_cardId];
    }

    // função para declarar que completou a cartela
    function shoutBingo(uint _cardId) external onlyOwnerOf(_cardId) {
        uint[] memory nums = getDrawnNumbers();
        uint counter = 0;
        for (uint i = 0; i < 75; i++) {
            if (nums[i] == 0) {
                break;
            }
            counter++;
        }
        require(counter >= 25, "Ainda nao foram sorteados numeros o suficiente para haver um ganhador!");
        if(_isWinner(_cardId)) {
            winner = payable(msg.sender);
            emit YouWin(msg.sender);
            emit GameOver(msg.sender);
        }
        emit YouDidNotWin(msg.sender);
    }

    // função para verificar se houve de fato um ganhador
    /// @dev Essa função está como pública por enquanto por motivos de teste, o certo é privada
    function _isWinner(uint _cardId) public view returns(bool) {
        uint[] memory card = cards[_cardId];
        for(uint i = 0; i < card.length; i++) {
            uint index = card[i] - 1;
            if(drawnNumbers[index] == 0) {
                return false;
            }
        }
        return true;
    }

    // função para o ganhador retirar seu prêmio
    /// @dev Por enquanto o prêmio está como 50% do valor arrecadado
    function withdrawPrize() public onlyWinner {
        winner.transfer(address(this).balance / 2);
    }

    //função para reiniciar o bingo
    function restartBingo() external onlyOwner {
        started = false;
        nonce = 0;
        delete cards;
        delete drawnNumbers;
        winner = payable(address(0));
        for (uint i = 0; i < cards.length; i++) {
            delete cardToOwner[i];
        }
        for (uint j = 0; j < users.length; j++) {
            if(ownerCardCount[users[j]] != 0){
                ownerCardCount[users[j]] = 0;
            }
        }
        delete users;
        owner.transfer(address(this).balance);
    }
}