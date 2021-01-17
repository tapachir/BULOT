// number of accounts that will participate in the lottery
var ACCOUNT_NUM = 10;

// sends 100 tokens from 0th account to all the other accounts
function transferTokens() {
	var fromacc = eth.accounts[0];
	console.log("TRANSFER TOKENS1");
	for(var i=1; i<ACCOUNT_NUM; i++) {
    		var to = eth.accounts[i];
		erc20Contract.transfer(to, 100, {from: fromacc});
  	}
	console.log("TRANSFER TOKENS2");
}

function transferEthers(fromacc, toacc, amount) {
	eth.sendTransaction({from: fromacc, to: toacc, value: web3.toWei(amount, "ether")});
}


loadScript("erc20abi.js");
loadScript("bulotabi.js");

var bulotAddress = "0xCdE434211ed04ccf9B6ce83344E8410fFBDF5D43";
var erc20Contract = web3.eth.contract(erc20Abi).at("0xe8c6f4161F9959C5B02117C35C5dA92b9BCfB717");

var bulotContract = web3.eth.contract(bulotAbi).at(bulotAddress);

console.log("CURRENT LOT NO", bulotContract.getCurrentLotteryNo.call());

var accountCount = eth.accounts.length;
if(accountCount < ACCOUNT_NUM) {
	for(var i=accountCount; i<ACCOUNT_NUM; i++) {
		personal.newAccount("");
	}
}
console.log("CURRENT LOT NO", bulotContract.getCurrentLotteryNo.call());

// coinbase is 0th account 
// send ethers to all accounts from 0th account
personal.unlockAccount(eth.accounts[0], "", 5000000);
for(var i=1; i<ACCOUNT_NUM; i++) {
	transferEthers(eth.accounts[0], eth.accounts[i], 10);
}

console.log("CURRENT LOT NO", bulotContract.getCurrentLotteryNo.call());

for(var i=0; i<ACCOUNT_NUM; i++) {
	personal.unlockAccount(eth.accounts[i], '');
	erc20Contract.approve(bulotAddress, 10, {from: eth.accounts[i]});
}

console.log("CURRENT LOT NO", bulotContract.getCurrentLotteryNo.call());

// send tokens
transferTokens();

console.log("CURRENT LOT NO", bulotContract.getCurrentLotteryNo.call());

var dummyInterval = setInterval(function () { 

    personal.unlockAccount(eth.accounts[1], '');
    transferEthers(eth.accounts[1], eth.accounts[0], 10);
    //console.log("DUMMY INTERVAL sent from 1");


    personal.unlockAccount(eth.accounts[0], '');
    transferEthers(eth.accounts[0], eth.accounts[1], 10);
    //console.log("DUMMY INTERVAL sent from 0");
}, 600);


console.log("CURRENT LOT NO", bulotContract.getCurrentLotteryNo.call());
console.log("BUYING TICKETS!!");

var user_nums = new Array();

var str1;
  // buy ticket
for(var i=0; i<ACCOUNT_NUM; i++) {
	erc20Contract.transfer(eth.accounts[i], 10, {from: eth.accounts[0]});
	personal.unlockAccount(eth.accounts[i], '');
	erc20Contract.approve(bulotAddress, 10, {from: eth.accounts[i] });
	user_nums.push(i);
	var hashed = bulotContract.getHash.call(i, {from: eth.accounts[i]});
	bulotContract.buyTicket(hashed, {from: eth.accounts[i]});
  //ticketNos.set(eth.accounts[i], bulotContract.getLastBoughtTicketNo(0));
	console.log("Account: ",i," is buying a ticket!! Their hash number is: ",hashed);
	
	console.log("CURRENT LOT NO", bulotContract.getCurrentLotteryNo.call());
}


console.log("REVEAL BEGIN");
var revealFlag = false;
var revealCheck = setInterval(function () {
    if(!revealFlag){
	console.log("REVEAL CHECK CURRENT LOT NO", bulotContract.getCurrentLotteryNo.call());
        if (bulotContract.getCurrentLotteryNo.call()==1) {
		console.log("INSIDE REVEAL");
            for(var i=0; i<ACCOUNT_NUM; i++) {
                console.log("Account: ",i," reveals her number ",user_nums[i]);
                personal.unlockAccount(eth.accounts[i], '');
                bulotContract.revealRndNumber(i, user_nums[i], {from: eth.accounts[i]});
            }
            revealFlag = true;
        } else {
            console.log("Reveal stage has not come yet!!")
        } 
    }
}, 30 * 1000);

console.log("REVEAL END");

console.log("WITHDRAW BEGIN");
var withdrawCheck = setInterval(function () {
    console.log("Withdraw Period!!");
    console.log("WITHDRAW CHECK CURRENT LOT NO", bulotContract.getCurrentLotteryNo.call());
    //console.log("type of lot no", typeof bulotContract.getCurrentLotteryNo.call());
    if (bulotContract.getCurrentLotteryNo.call()==2) { 
      console.log("INSIDE WITHDRAW");
        for(var i=0; i<ACCOUNT_NUM; i++) {
	    console.log("withdraw for account ", i);
            personal.unlockAccount(eth.accounts[i], "");
	    console.log("account is unlocked ", i);
            // This is how log2 is taken in geth console ???
	    var logOfMoney = Math.log(ACCOUNT_NUM*10) / Math.log(2);
	    console.log("logOfMoney ", logOfMoney);
	    console.log("Math.ceil(logOfMoney) ", Math.ceil(logOfMoney));
            for (var j = 0; j < Math.ceil(logOfMoney); j++) { 
	    	console.log("inside inner for loop, j is ", j);
                var award = bulotContract.checkIfTicketWon.call(0, i, {from: eth.accounts[i]});
	    	console.log("award is ", award);
                if (award > 0) {
                    console.log("Account ", i ," won ", award," CONGRATS!! She is ", j," th winner:)");
                    bulotContract.withdrawTicketPrize(0, i, {from: eth.accounts[i]});
                }
		else {
		    console.log("Sorry, account ", i ," did not win. Maybe next time!");
		}
            }
        }
        clearInterval(revealCheck);
        clearInterval(withdrawCheck);
    } else {
        console.log("Withdraw stage has not come yet!!")
    }


}, 40 * 1000);
console.log("WITHDRAW END");