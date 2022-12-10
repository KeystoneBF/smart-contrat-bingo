pragma solidity >=0.5.0;

contract Bingo {
    address owner;
    uint cardPrice = 0.001 ether;
    address payable winner;

    //função para comprar cartelas (mínimo 1 e máximo 4) baseado no valor enviado na transação
    function buyCard() public {

    }

    // Função para sortear a bola da rodada
    // Somente o dono do contrato pode chamar essa função
    function raffleBall() public {

    }

    //função para criar uma nova cartela
    function _generateCard() public {

    }

    //função para verificar se houve de fato um ganhador
    function verifyWinner() public {

    }

    //função para verificar se houve um ganhador
    function withdrawPrize() public {
        
    }
}