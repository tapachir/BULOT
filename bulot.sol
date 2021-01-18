pragma solidity ^0.4.26;

import "./erc20.sol";


contract BULOT {
    
    EIP20 erc20;

    // Ticket object holds required information of the ticket
    struct Ticket {
        // unique number of the ticket
        uint ticket_no;
        // hashed number which is sent with the ticket
        bytes32 hash_rnd_number;
        // address of the owner of the ticket
        address owner;
        // whether the prize of the ticket delivered or not
        bool withdrawn;
    }

    struct Lottery {
        // total money collected from this lottery object
        uint money_collected;
        // random number sent by the winner of this lottery
        uint winnerNumber;
        // array of the participated tickets in this lottery
        Ticket[] tickets;
        // mapping of the valid ticket of this lottery
        mapping(uint => Ticket) validTickets;
        // number of valid ticket in this lottery
        uint numOfValidTickets;
        // maps user addresses to unique numbers of the tickets they purchased
        mapping(address => uint[]) usersTicketNos;
    }
    // maps lotteries from their number to itself
    mapping(uint => Lottery) lotteries;
    // unusedVar is not used in the code, but without it, lottery number calculation did not work.
    // so, we keep it
    uint unusedVar = 1;
    // timestamp for creation of the lottery
    uint start;
    // address of the ERC contract
    address public contractaddr; 


    // protects from random payments - fallback function
    function() public {
        revert();
    }

    // constructor of the contract initializes address and the timestamp
    constructor(address conaddr) {
        contractaddr = conaddr; 
        start = block.timestamp;
    }

    // function enables user to buy ticket
    function buyTicket(bytes32 hash_rnd_number) public {
        // enable connection
        EIP20 contractobj = EIP20(contractaddr); 

        // transaction has to be completed before purchasing
        require(contractobj.transferFrom(msg.sender, address(this), 10), 'FAILED');
       
       // ticket object creation
        Ticket t;
        t.withdrawn = false;
        t.hash_rnd_number = hash_rnd_number;
        t.owner = msg.sender;
        // ticket no will be unique by this way
        t.ticket_no = lotteries[getCurrentLotteryNo()].tickets.length;
        lotteries[getCurrentLotteryNo()].tickets.push(t);
        
        // add the tickets of the user
        uint index = lotteries[getCurrentLotteryNo()].tickets.length - 1;
        lotteries[getCurrentLotteryNo()].usersTicketNos[msg.sender].push(index);
        // increment the total amount
        lotteries[getCurrentLotteryNo()].money_collected += 10;
    }

    function revealRndNumber(uint ticketno, uint rnd_number) public {
        
        // check if this is the time for any lottery to reveal
        require(getCurrentLotteryNo() >= 1);
            
        // only last week's lottery can be revealed
        uint revealLotteryNo = getCurrentLotteryNo() - 1;
        // take the hash of the coming number to calculate
        bytes32 hash_rnd_number = sha3(rnd_number, msg.sender);
        Ticket t = lotteries[revealLotteryNo].tickets[ticketno];
        // check whether the senders are the same
        require(t.owner == msg.sender); 
        
        // check the hash number sent in purchase is same of this one
        require(t.hash_rnd_number == hash_rnd_number);
        // xor with new coming random number
        lotteries[revealLotteryNo].winnerNumber ^= rnd_number;
        // add as valid ticket and increment valid tickets
        lotteries[revealLotteryNo].validTickets[ticketno]=t;
        lotteries[revealLotteryNo].numOfValidTickets+=1;
    }
    function getLastBoughtTicketNo(uint lottery_no) public view returns(uint) {
        // take the last ticket bought by the user
        uint index = lotteries[lottery_no].usersTicketNos[msg.sender].length - 1;
        // return number of this ticket
        return lotteries[lottery_no].usersTicketNos[msg.sender][index];
    }
    // calculates the hash function of the given number
    function getHash(uint rnd_number) public view returns(bytes32) {
        return keccak256(rnd_number);
    }
    // returns the number of the ith ticket bought by the user who is calling this func
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
    // checks whether the ticket is won or not
    function checkIfTicketWon(uint lottery_no, uint ticket_no) public view returns (uint amount) {
        // get current lottery number to compare
        uint currentLotteryNo = getCurrentLotteryNo();

        // lottery has to be finished already in order to check whether the ticket won or not
        require(lottery_no < currentLotteryNo); 
        
        // total amount of money collected in that lottery
        uint M = lotteries[lottery_no].money_collected;

        // number of winners is equal to logarithm of the total money
        uint numOfWinners = logarithm2(M);

        uint total = 0;
        
        // compare this ticket with ith winning ticket for all i = 1...ceil(log M)
        for(uint i=1; i<=numOfWinners; i++) {
            var (winning_ticket_no, winning_amount) = getIthWinningTicket(i, lottery_no);
            if (winning_ticket_no == ticket_no) {
                total += winning_amount;
            }
        }
        // total prize that this ticket has won
        return total;
    }
    // user can take the prize by this function
    function withdrawTicketPrize(uint lottery_no, uint ticket_no) public	{
        // create connection
        EIP20 contractobj = EIP20(contractaddr);
        
        // before check the ticket has won anything
        uint prize = checkIfTicketWon(lottery_no, ticket_no);
        
        require(prize > 0, "Sorry, your ticket didnt win");

        // verifies the player hasn't withdrawn his prize
        require(lotteries[lottery_no].validTickets[ticket_no].withdrawn == false, "Prize for this ticket was already withdrawn");

        require(contractobj.transfer(msg.sender, prize), "Failed to transfer prize to your account.");
        
        // label it as withdrawn after all process is done
        lotteries[lottery_no].validTickets[ticket_no].withdrawn == true;
    }
    
    function getIthWinningTicket(uint i, uint lottery_no) public view returns (uint ticket_no, uint amount) {
        // get current lottary number to compare 
        uint currentLotteryNo = getCurrentLotteryNo();
        
        // lottery has to be finished already 
        require(lottery_no < currentLotteryNo); 
        
        // total amount of money collected in that lottery
        uint M = lotteries[lottery_no].money_collected;
        
        uint numOfWinners = logarithm2(M);
        require(i <= numOfWinners);
        
        uint P;
        bytes32 hashed_winner = keccak256(lotteries[lottery_no].winnerNumber);
        // traverse all winners until the ith ticket comes
        for(uint temp=0; temp <= i-1; temp++) {
            P = M % 2;
            M = M / 2;       
            P += M;
            if(temp==(i-1)) {
                return (lotteries[lottery_no].validTickets[uint(hashed_winner) % lotteries[lottery_no].numOfValidTickets].ticket_no, P);
            }
            hashed_winner = keccak256(hashed_winner);
        }
        
        
    }
    function getValid(uint lottery_no) public view returns (uint valids) {
        return lotteries[lottery_no].numOfValidTickets;   // return lottery_no that is in the purchase period
    }
    function getCurrentLotteryNo() public view returns (uint diff) {
        return (block.timestamp-start)/(1 minutes);   // return lottery_no that is in the purchase period
    }
    // lottery no's start from 0
    // at a given time, one lottery is in purchase period, and the previous one is in the reveal period
    function getCurrentLotteryNo2() public view returns (uint lottery_no) {
        return (block.timestamp - start)/(1 weeks);   // return lottery_no that is in the purchase period

    }
    // returns total money in the given lottery
    function getMoneyCollected(uint lottery_no) public view returns (uint amount) {
        return lotteries[lottery_no].money_collected;
    }
}
