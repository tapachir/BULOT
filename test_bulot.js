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

var bulotAddress = "0x8Ffc5B486c88e751E6d72ec95FC97b914Cb63Ae3";
var erc20Contract = web3.eth.contract(erc20Abi).at("0xAE544D99592AC6cF2170D09cB7f848d7A65B5dB0");

var bulotAddress = "0x25f7d1827347780458E41E815Ab7dffFC750A053";
var erc20Contract = web3.eth.contract(erc20Abi).at("0x2D1C5154FAa6BbE92f42bd9805b4A2eBFcb8195a");

var bulotContract = web3.eth.contract(bulotAbi).at(bulotAddress);

var accountCount = eth.accounts.length;
if(accountCount < ACCOUNT_NUM) {
	for(var i=accountCount; i<ACCOUNT_NUM; i++) {
		personal.newAccount("");
	}
}

// coinbase is 0th account 
// send ethers to all accounts from 0th account
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


var dummyInterval = setInterval(function () { 

    personal.unlockAccount(eth.accounts[1], '');
    transferEthers(eth.accounts[1], eth.accounts[0], 10);
    //console.log("DUMMY INTERVAL sent from 1");


    personal.unlockAccount(eth.accounts[0], '');
    transferEthers(eth.accounts[0], eth.accounts[1], 10);
    //console.log("DUMMY INTERVAL sent from 0");
}, 600);

var user_nums = new Array();

var str1;
  // buy ticket
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

console.log("LOTTERY COLLECTED ",bulotContract.getMoneyCollected.call(0)," IN TOTAL!");

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

var withdrawCheck = setInterval(function () {
    //console.log("type of lot no", typeof bulotContract.getCurrentLotteryNo.call());
    if (bulotContract.getCurrentLotteryNo.call()==2) { 
     
        for(var i=0; i<ACCOUNT_NUM; i++) {
            personal.unlockAccount(eth.accounts[i], "");
                var award = bulotContract.checkIfTicketWon.call(0, i, {from: eth.accounts[i]});
                if (award > 0) {
                    console.log("Account ", i ," won ", award," CONGRATS!!");
                    bulotContract.withdrawTicketPrize(0, i, {from: eth.accounts[i]});
                }
        }
        clearInterval(revealCheck);
        clearInterval(withdrawCheck);
    } else {
        console.log("Withdraw stage has not come yet")
    }

	console.log("Withdraw Period!!");

	console.log("WITHDRAW CHECK CURRENT LOT NO", bulotContract.getCurrentLotteryNo.call());
	if (bulotContract.getCurrentLotteryNo.call()==2) { 
		console.log("INSIDE WITHDRAW");
		var j = 1;
		for(var i=0; i<ACCOUNT_NUM; i++) {
			personal.unlockAccount(eth.accounts[i], "");
			var award = bulotContract.checkIfTicketWon.call(0, i, {from: eth.accounts[i]});
			console.log("award is ", award);
			if (award > 0) {
				console.log("Account ", i ," won ", award," CONGRATS!!");
				bulotContract.withdrawTicketPrize(0, i, {from: eth.accounts[i]});
				j++;
			}
		}
		clearInterval(revealCheck);
		clearInterval(withdrawCheck);
	} else {
        	console.log("Withdraw stage has not come yet!!")
    	}

}, 40 * 1000);