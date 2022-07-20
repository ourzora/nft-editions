# Expanded NFTs

Based on the [Zora NFT Editions](https://github.com/ourzora/nft-editions) contracts.

## What are these contracts?

1. `ExpandedNFT`
   Each drop is a unique contract.
   This allows for easy royalty collection, clear ownership of the collection, and your own contract 🎉
2. `DropCreator`
   Gas-optimized factory contract allowing you to easily + for a low gas transaction create your own drop mintable contract.
3. `SharedNFTLogic`
   Contract that includes dynamic metadata generation for your editions removing the need for a centralized server.
   imageUrl and animationUrl can be base64-encoded data-uris for these contracts totally removing the need for IPFS

## How do I create and use Expanded NFTs?

- [How do I create a new drop?](./docs/create-a-drop.md)
- [How to develop locally?](./docs/develop.md)

## Deployed

### Rinkeby

- SharedNFTLogic [0x707d795e898c32ebff02d717d8798fc1126ba001](https://rinkeby.etherscan.io/address/0x707d795e898c32ebff02d717d8798fc1126ba001)
- ExpandedNFT [0x1e6444BF4efc10e916c08410E33E5B753f0A1815](https://rinkeby.etherscan.io/address/0x1e6444BF4efc10e916c08410E33E5B753f0A1815)
- DropCreator [0x9692a6E918B8B87F4a533697E40F765e148fF334](https://rinkeby.etherscan.io/address/0x9692a6E918B8B87F4a533697E40F765e148fF334)
