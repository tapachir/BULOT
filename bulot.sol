
pragma solidity ^0.4.21;

contract BULOT {

    struct Ticket {
        uint ticket_no;
        bytes32 hash_rnd_number;
        address owner;
        bool withdrawn = false;
    }

    struct Lottery {
        uint lottery_no;
        uint money_collected;
        uint winnerNumber;
        Ticket[] tickets;
        mapping(uint => Ticket) validTickets;
        uint start;
        StageTypes stage;
        mapping(address => uint[]) usersTicketNos;
    }
    // tickets: 0    1 2 3 4
    //          a    b a
    // usersTicketNos a -> 0,2
    // b -> 1
    address constant erc20 = 0xd9145CCE52D386f254917e481eB44e9943F39138;
    uint stagePeriod = 2 weeks;
    enum StageTypes {PURCHASE, REVEAL}
    Lottery[] lotteries;
    uint start;
    uint lottery_no = 0;

    function() {
        //TODO
    }


    constructor() {
        Lottery l;
        l.lottery_no = 0;
        l.money_collected = 0;
        l.start = now;
        l.stage = StageTypes.PURCHASE;

        lotteries.push(l);

        start = now;
    }

    // purchase: 1 2 3 4
    // reveal: 1 2 3
    // winner: (1,2,3)

    // buy
    // reveal
    // decide winners
    // withdrawTicketPrize

    function buyTicket(bytes32 hash_rnd_number) public {
        // check if current lottery no -> ended

        require(erc20.call(bytes4(keccak256("transferFrom(address, address, uint)")), msg.sender, this, 10));
        Ticket t;
        t.ticket_no =
        lotteries[getCurrentLotteryNo()].tickets.push(t);

        uint index = lotteries[getCurrentLotteryNo()].tickets.length - 1;
        lotteries[getCurrentLotteryNo()].usersTicketNos[msg.sender].push(index);
        lotteries[getCurrentLotteryNo()].money_collected += 10;
    }

    function revealRndNumber(uint ticketno, uint rnd_number) public {
        uint revealLotteryNo = getCurrentLotteryNo() - 1;
        if(revealLotteryNo >= 0) {
            bytes32 hash_rnd_number = sha3(rnd_number, msg.sender);
            Ticket t = lotteries[revealLotteryNo].tickets[ticketno];
            if(t.hash_rnd_number == hash_rnd_number) {
                t.owner = msg.sender;
                // xor with new coming random number
                lotteries[revealLotteryNo].winnerNumber ^= rnd_number;
                lotteries[revealLotteryNo].validTickets[ticketno]=t;
            }
        }
    }
    function getLastBoughtTicketNo(uint lottery_no) public view returns(uint) {
        uint index = lotteries[lottery_no].usersTicketNos[msg.sender].length - 1;
        return lotteries[lottery_no].usersTicketNos[msg.sender][index];
    }
    function getIthBoughtTicketNo(uint i,uint lottery_no) public view returns(uint) {
        return lotteries[lottery_no].usersTicketNos[msg.sender][i];
    }
    // source: https://ethereum.stackexchange.com/a/30168
    // calculates ceiling of log_2
    function logarithm2(uint x) public pure returns (uint y){
        assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }
    }
    function checkIfTicketWon(uint lottery_no, uint ticket_no) public view returns (uint	amount) {
        // get current lottary number to compare
        uint currentLotteryNo = getCurrentLotteryNo();

        // lottery has to be finished already in order to check whether the ticket won or not
        require(_lotteryNo < currentLotteryNo);

        // total amount of money collected in that lottery
        uint M = lotteries[lottery_no].money_collected;

        uint numOfWinners = logarithm2(M);

        uint P;
        bytes32 hashed_winner = keccak256(lotteries[lottery_no].winnerNum);
        // traverse all winners until the ticket asked comes
        // calculate P(i)
        for(uint i=0; i <= numOfWinners; i++) {
            P = M % 2;
            M = M / 2;
            P += M;
            if(lotteries[lottery_no].validTickets[ticket_no].owner==lotteries[lottery_no].validTickets[uint(hashed_winner) % lotteries[lottery_no].validTickets.length].owner) {
                return P;
            }
            hashed_winner = keccak256(hashed_winner);
        }
        return 0;


    }
    function withdrawTicketPrize(uint lottery_no, uint ticket_no) public	{
      uint prize = checkIfTicketWon(lottery_no, ticket_no);
      require(prize > 0, "Sorry, your ticket didnt win")

      require(withdrawedTicketPrize)

// verifies the player hasn't withdrawn his prize
      require(lotteries[lottery_no].validTickets[ticket_no].withdrawn == false, "Prize for this ticket was already withdrawn");


      require(erc20.call(bytes4(keccak256("transfer(address, uint)")), msg.sender, prize),
      "Failed to transfer prize to your account.");

      lotteries[lottery_no].validTickets[ticket_no].withdrawn == true,


    }
    function getIthWinningTicket(uint i,	uint lottery_no) public view returns (uint ticket_no,uint amount) {
        // TODO

    }
    // lottery no's start from 0
    // at a given time, one lottery is in purchase period, and the previous one is in the reveal period
    function getCurrentLotteryNo() public view returns (uint lottery_no) {
        return (now - start)/(1 weeks);   // return lottery_no that is in the purchase period

    }
    function getMoneyCollected(uint lottery_no) public view returns (uint amount) {
        return lotteries[lottery_no].money_collected;
    }
}
