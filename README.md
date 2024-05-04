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

## Front End Initialize
Run locally for testing with:

⚠️ Node.js version v16.14.2 is recommended to avoid errors running the website locally. ⚠️

   `npm install http-server`

then

   `npx http-server`

or

   `http-server`


## Deployment Steps
- Deploy CrossChainBuyer.sol
   - Call `allowlistDestinationChain`, inputting Chain Selectors for other CCIP chains
   - Transfer LINK to DustAuction to fund transfers

- Deploy DustAuction.sol on CCIP chains
   - Call `allowListDestinationAndSourceChain`, inputting Chain Selectors for other CCIP chains
   - Call `allowListSender`, inputting the contract address of DustAuction.sol for all deployed instances
   - Transfer LINK to DustAuction to fund transfers

Chain Selectors
- Fuji -> Sepolia Eth: 16015286601757825753
- Fuji -> Sepolia Base: 10344971235874465080

- Sepolia Eth -> Fuji: 14767482510784806043
- Sepolia Eth -> Sepolia Base: 10344971235874465080

- Sepolia Base -> Fuji: 14767482510784806043
- Sepolia Base -> Sepolia: 16015286601757825753

ChainIDs
- Avalanche Fuji: `43113`
- Ethereum Sepolia: `11155111`
- Base Sepolia: `84532`

Router
- Fuji: `0xF694E193200268f9a4868e4Aa017A0118C9a8177`
- Ethereum Sepolia: `0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59`
- Base Sepolia: `0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93`

LINK
- Fuji: `0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846`
- Sepolia Eth: `0x779877A7B0D9E8603169DdbD7836e478b4624789`
- Sepolia Base: `0xE4aB69C077896252FAFBD49EFD26B5D171A32410`

USDC
- Fuji: `0x5425890298aed601595a70AB815c96711a31Bc65`
- Sepolia Eth: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
- Sepolia Base: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`

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

## Non-CCIP Supported Deployments
### Mantle Sepolia Testnet
- DustAuction:

### Polygon zkEVM Cardona Testnet
- DustAuction:

## Acknowledgements
[Marcus Wentz](https://github.com/MarcusWentz) for their mentoring & [Front End Template](https://github.com/MarcusWentz/Web3_Get_Set_Contract_Metamask)