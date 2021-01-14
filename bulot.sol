
pragma solidity ^0.4.21;

contract BULOT {
    
    struct Ticket {
        uint ticket_no;
        bytes32 hash_rnd_number;
        address owner;
    }
    
    struct Lottery {
        uint lottery_no;
        uint money_collected;
        Ticket[] tickets;
        Ticket[] validTickets;
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
                lotteries[revealLotteryNo].validTickets.push(t);
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
    function checkIfTicketWon(uint lottery_no, uint ticket_no) public view returns (uint	amount) {
        
    }
    function withdrawTicketPrize(uint lottery_no, uint ticket_no) public	{
        
    }
    function getIthWinningTicket(uint i,	uint lottery_no) public view returns (uint ticket_no,uint amount) {
        
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
