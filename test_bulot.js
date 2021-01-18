// number of accounts that will participate in the lottery
var ACCOUNT_NUM = 10;

// sends 100 tokens from 0th account to all the other accounts
function transferTokens() {
	var fromacc = eth.accounts[0];
	
	for(var i=1; i<ACCOUNT_NUM; i++) {
    		var to = eth.accounts[i];
		erc20Contract.transfer(to, 100, {from: fromacc});
  	}
	
}

function transferEthers(fromacc, toacc, amount) {
	eth.sendTransaction({from: fromacc, to: toacc, value: web3.toWei(amount, "ether")});
}


loadScript("erc20abi.js");
loadScript("bulotabi.js");

var bulotAddress = "0x20a0dF9445E05ec9Df1223b90af2c95235E15851";
var erc20Contract = web3.eth.contract(erc20Abi).at("0x4fD98d40c34f26A65D800740bbB9043620D56EAA");

var bulotContract = web3.eth.contract(bulotAbi).at(bulotAddress);

var accountCount = eth.accounts.length;
if(accountCount < ACCOUNT_NUM) {
	for(var i=accountCount; i<ACCOUNT_NUM; i++) {
		personal.newAccount("");
	}
}

// coinbase is 0th account 
// send ethers to all accounts from 0th account
// for gas costs
personal.unlockAccount(eth.accounts[0], "", 5000000);
for(var i=1; i<ACCOUNT_NUM; i++) {
	transferEthers(eth.accounts[0], eth.accounts[i], 10);
}

for(var i=0; i<ACCOUNT_NUM; i++) {
	personal.unlockAccount(eth.accounts[i], '');
	erc20Contract.approve(bulotAddress, 10, {from: eth.accounts[i]});
}


// send tokens
transferTokens();

// in order to pass time, cretaing blocks always
var dummyInterval = setInterval(function () { 

    personal.unlockAccount(eth.accounts[1], '');
    transferEthers(eth.accounts[1], eth.accounts[0], 10);
    //console.log("DUMMY INTERVAL sent from 1");


    personal.unlockAccount(eth.accounts[0], '');
    transferEthers(eth.accounts[0], eth.accounts[1], 10);
    //console.log("DUMMY INTERVAL sent from 0");
}, 600);
// holds numbers given by participants
var user_nums = new Array();

var str1;
  // buying tickets stage
for(var i=0; i<ACCOUNT_NUM; i++) {
	erc20Contract.transfer(eth.accounts[i], 10, {from: eth.accounts[0]});
	personal.unlockAccount(eth.accounts[i], '');
	erc20Contract.approve(bulotAddress, 10, {from: eth.accounts[i] });
  var random=Math.floor(Math.random() * 50)
	user_nums.push(random);
	var hashed = bulotContract.getHash.call(random, {from: eth.accounts[i]});
	bulotContract.buyTicket(hashed, {from: eth.accounts[i]});
  //ticketNos.set(eth.accounts[i], bulotContract.getLastBoughtTicketNo(0));
	console.log("Account: ",i," is buying a ticket!");
}
// total money collected in lottery
console.log("LOTTERY COLLECTED ",bulotContract.getMoneyCollected.call(0)," IN TOTAL!");
// bool to make possible reveal stage occurs only once
// reveal stage occurs every 30 seconds
var revealFlag = false;
var revealCheck = setInterval(function () {
    if(!revealFlag){
        if (bulotContract.getCurrentLotteryNo.call()==1) {
            for(var i=0; i<ACCOUNT_NUM; i++) {
                console.log("Account: ",i," reveals her number ",user_nums[i]);
                personal.unlockAccount(eth.accounts[i], '');
                bulotContract.revealRndNumber(i, user_nums[i], {from: eth.accounts[i]});
            }
            revealFlag = true;
        } else {
            console.log("Reveal stage has not come yet")
        } 
    }
}, 30 * 1000);
// withdraw stage occurs every 40 seconds
var withdrawCheck = setInterval(function () {
    if (bulotContract.getCurrentLotteryNo.call()==2) { 
     
        for(var i=0; i<ACCOUNT_NUM; i++) {
            personal.unlockAccount(eth.accounts[i], "");
                var award = bulotContract.checkIfTicketWon.call(0, i, {from: eth.accounts[i]});
                if (award > 0) {
                    console.log("Account ", i ," won ", award," CONGRATS!!");
                    bulotContract.withdrawTicketPrize(0, i, {from: eth.accounts[i]});
                }
        }
	console.log("LOTTERY ENDS~");
        clearInterval(revealCheck);
        clearInterval(withdrawCheck);
    } else {
        console.log("Withdraw stage has not come yet")
    }
}, 40 * 1000);