# dust-auction
Protocol for disposing of unwanted toxic assets using a Dutch auction.

Toxic assets can be bad debt, a bunch of dust on your wallets you want to get rid off at any price, or even actual physical tokenized toxic uranium in your backyard.

It's crosschain with CCIP compatible so people from other chains can buy the toxic assets.

The Dutch auction starts off and goes on for a select period of time during which the slope of the invariant curve changes (n):
<img width="317" alt="Screenshot 2024-05-04 at 2 19 42 AM" src="https://github.com/Tranquil-Flow/dust-auction/assets/11951513/1f7a6514-e82c-4c75-8a50-c35ba03dfa65">

The swap function becomes:
<img width="279" alt="Screenshot 2024-05-04 at 2 19 16 AM" src="https://github.com/Tranquil-Flow/dust-auction/assets/11951513/18f333a7-1390-4916-b7ee-88c6e64b2c5e">


As time goes on, the more you buy, the better the deal you're going to get, but you're not the only one noticing this good deal!


https://github.com/Tranquil-Flow/dust-auction/assets/11951513/4c17e12c-0a27-47f5-944c-7363d4c01270

3D view: https://www.desmos.com/3d/svmgalljva 
<img width="766" alt="Screenshot 2024-05-04 at 2 56 18 AM" src="https://github.com/Tranquil-Flow/dust-auction/assets/11951513/28607752-fcb1-415c-9995-5cd81ad13325">



CCIP purchase of toxic asset:
<img width="841" alt="Screenshot 2024-05-04 at 12 47 01 AM" src="https://github.com/Tranquil-Flow/dust-auction/assets/11951513/ebf46210-c824-465e-91db-09e8ce1cb55e">


## Future Plans
- Slippage options
- Partial fill offers when using CCIP
- Refund CCIP users when overpaying due to latency from confirmation time affecting n

Insert X, and  insert the willing to accept Y> or more amount of sheep.


## Deployment Steps
- Deploy DustAuction.sol
- Deploy CrossChainBuyer.sol
- Fund both contracts with LINK

## CCIP Supported Deployments
### Ethereum Sepolia
- DustAuction:
- CrossChainBuyer:

### Base Sepolia Testnet
- DustAuction:
- CrossChainBuyer:

### Avalanche Fuji Testnet
- DustAuction:
- CrossChainBuyer:

### BNB Smartchain Testnet Testnet
- DustAuction:
- CrossChainBuyer:

## Non-CCIP Supported Deployments
### Mantle Sepolia Testnet
- DustAuction:
- CrossChainBuyer:

### Avail Goldberg Testnet
- DustAuction:
- CrossChainBuyer:

## Acknowledgements
[Marcus Wentz](https://github.com/MarcusWentz) for their mentoring & [Front End Template](https://github.com/MarcusWentz/Web3_Get_Set_Contract_Metamask)