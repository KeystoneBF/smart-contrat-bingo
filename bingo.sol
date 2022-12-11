// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

contract Bingo {
    event GameStart(string message);
    event GameOver(address winner);
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
    mapping (address => uint) ownerCardCount;

    constructor() {
        owner =  payable(msg.sender);
        for(uint i=0; i < 75; i++) {
            numbers[i] = i + 1;
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
        require(started == false);

        for (uint i = 0; i < quantity ; i++) {
            _generateCard();
            ownerCardCount[msg.sender]++;
        }

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

    // função auxiliar para sortear um número de um array passado como parâmetro
    function _raffeNumber(uint[] memory _array) private returns(uint) {
        uint random = _array[uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % _array.length];
        uint luckyNumber = _array[random];
        nonce++;
        return luckyNumber;
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
    function shoutBingo(uint _cardId) external onlyOwnerOf(_cardId) returns(bool) {
        if(_isWinner(cards[_cardId])) {
            winner = payable(msg.sender);
            emit GameOver(msg.sender);
            return true;
        }
        return false;
    }

    // função para verificar se houve de fato um ganhador
    function _isWinner(uint[] memory _card) private view returns(bool) {
        for(uint i = 0; i < _card.length; i++) {
            uint index = _card[i];
            if(drawnNumbers[index - 1] == 0) {
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
        owner.transfer(address(this).balance);
    }
}