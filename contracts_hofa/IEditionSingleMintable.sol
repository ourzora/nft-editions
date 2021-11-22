// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

interface IEditionSingleMintable {
  function mintEdition(address to) external returns (uint256);
  function mintEditions(address[] memory to) external returns (uint256);

 // function mintEditionMarket(address, IMarket.BidShares memory) public;
  function numberCanMint() external view returns (uint256);
  
  function owner() external view returns (address);
   /// @param unencoded bytes to base64-encode
    function base64Encode(bytes memory unencoded)
        external
        pure
        returns (string memory);

    /// Encodes the argument json bytes into base64-data uri format
    /// @param json Raw json to base64 and turn into a data-uri
    function encodeMetadataJSON(bytes memory json)
        external
        pure
        returns (string memory);

    /// Proxy to openzeppelin's toString function
    /// @param value number to return as a string
    function numberToString(uint256 value)
        external
        pure
        returns (string memory);
}