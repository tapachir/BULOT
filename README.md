# BULOT

1. Install Chrome Legacy extension.
2. Go to Remix. Connect to Metamask using Injected Web3 option.
3. Compile "erc20.sol" and deploy with specified parameters.
    Example: 1000000, "Turkish Lira", 0, "TL"
4. Compile "bulot.sol" and deploy with address of the erc20.sol contract.
    Example: 0x2133547373a0ff7F988321CE9830169367cb26E5

Note: All compilations should use Solidity 0.4.26.

On your computer:
5. Put the addresses of deployed contracts to the index.html file, as the values of variables "contractAddressToken" and "contractAddressBULOT".

6. Install nodejs. (https://nodejs.org/en/download/)
7. Open up a terminal and execute following commands:
   > npm install web3
   > npm install express
8. Run server with the following command:
   > node server.js
9. Go to http://localhost:3300 in your Chrome browser.
10. Enjoy BULOT.
