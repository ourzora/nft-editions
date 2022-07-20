# How do I create a new drop?

## How do I create a new contract?

### Directly on the blockchain:

1. Find/Deploy the `DropCreator` contract
2. Call `createDrop` in `DropCreator` with the given arguments to create a new drop contract:

- ArtistWallet: `address` The address of the create of the drop. Used for paying royalties.
- Name:  `string` Token Name Symbol (shows in etherscan).
- Symbol: `string` Symbol of the Token (shows in etherscan).
- Description: `string` Description of the Token (shows in the NFT description).
- Animation URL: `string` IPFS/Arweave URL of the animation (video, webpage, audio, etc).
- Animation Hash: `SHA256` Hash of the animation, 0x0 if no animation url provided.
- Image URL: `string` IPFS/Arweave URL of the image (image/, gifs are good for previewing images).
- Image Hash: `SHA256` Hash of the image, 0x0 if no image url provided.
- Drop Size: `uint256` The number of editions in this drop, if set to 0, the drop is not capped/limited.
- VIP Mint Limit: `uint256` The number of the editions a VIP can mint when minting is restricted to VIP.
- Member Mint Limit: `uint256` The number of the editions a member can mint when minting is restricted to members.
- BPS Royalty: `uint256` In [Basis points][bps] (BPS). 500 = 5%, 1000 = 10%, so on and so forth, set to 0 for no on-chain royalty (not supported by all marketplaces).
- BPS Split: `uint256` In [Basis points][bps] (BPS). 500 = 5%, 1000 = 10%, so on and so forth, set to 0 for no on-chain royalty (not supported by all marketplaces).

## How do I sell/distribute editions?

Now that you have a drop, there are multiple options for lazy-minting and sales:

1. To sell editions for ETH you can call `setVIPSalePrice`, `setMembersSalePrice` or `setSalePrice`. All three prices can be set at once with `setSalePrices`. All prices are given in wei.
2. To allow certain accounts to mint `setApprovedMinter(address, approved)` and `setApprovedVIPMinters(address, approved)`.
3. To mint yourself to a list of addresses you can call `mintEditions(addresses[])` to mint an edition to each address in the list.

[bps]: https://www.investopedia.com/terms/b/basispoint.asp
