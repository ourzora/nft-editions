// SPDX-License-Identifier: GPL-3.0

/**

░█▄█░▄▀▄▒█▀▒▄▀▄░░░▒░░░░█▄░█▒█▀░▀█▀░░▒██▀░█▀▄░█░▀█▀░█░▄▀▄░█▄░█░▄▀▀
▒█▒█░▀▄▀░█▀░█▀█▒░░▀▀▒░░█▒▀█░█▀░▒█▒▒░░█▄▄▒█▄▀░█░▒█▒░█░▀▄▀░█▒▀█▒▄██

 */

pragma solidity 0.8.6;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC2981, IERC165} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {SharedNFTLogic} from "./SharedNFTLogic.sol";
import {IMintableEditions} from "./IMintableEditions.sol";
//import {Media} from "./Media.sol";
import {IMarket} from "./interfaces/IMarket.sol";
import "./interfaces/IMedia.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Base64} from "base64-sol/base64.sol";
import {IPublicSharedMetadata} from "./IPublicSharedMetadata.sol";


/**
    This is a smart contract for handling dynamic contract minting.

    @dev This allows creators to mint a unique serial edition of the same media within a custom contract
   
*/
contract MintableEditions is
    ERC721,
    IMintableEditions,
    IERC2981,
    Ownable
    //Media
{
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    event PriceChanged(uint256 amount);
    event EditionSold(uint256 price, address owner);

 address public marketContract;
    // metadata
    string private description;

    // Media Urls
    // animation_url field in the metadata
    string private animationUrl;
    // Hash for the associated animation
    bytes32 private animationHash;
    // Image in the metadata
    string private imageUrl;
    // Hash for the associated image
    bytes32 private imageHash;

    // Total size of edition that can be minted
    uint256 public editionSize;
    // Current token id minted
    Counters.Counter private atEditionId;
    // Royalty amount in bps
    uint256 royaltyBPS;
    // Addresses allowed to mint edition
    mapping(address => bool) allowedMinters;

 mapping(address => EnumerableSet.UintSet) private _creatorTokens;
 
  mapping(bytes32 => bool) private _contentHashes;
    // Price for sale
    uint256 public salePrice;
    
    Counters.Counter private _tokenIdTracker;

    // Global constructor for factory
        /**
      @param _owner User that owns and can mint the edition, gets royalty and sales payouts and can update the base url if needed.
      @param _name Name of edition, used in the title as "$NAME NUMBER/TOTAL"
      @param _symbol Symbol of the new token contract
      @param _description Description of edition, used in the description field of the NFT
      @param _imageUrl Image URL of the edition. Strongly encouraged to be used, if necessary, only animation URL can be used. One of animation and image url need to exist in a edition to render the NFT.
      @param _imageHash SHA256 of the given image in bytes32 format (0xHASH). If no image is included, the hash can be zero.
      @param _animationUrl Animation URL of the edition. Not required, but if omitted image URL needs to be included. This follows the opensea spec for NFTs
      @param _animationHash The associated hash of the animation in sha-256 bytes32 format. If animation is omitted the hash can be zero.
      @param _editionSize Number of editions that can be minted in total. If 0, unlimited editions can be minted.
      @param _royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty.
      @dev Function to create a new edition. Can only be called by the allowed creator
           Sets the only allowed minter to the address that creates/owns the edition.
           This can be re-assigned or updated later
     */
    constructor(address marketContractAddr,
     address _owner,
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _animationUrl,
        bytes32 _animationHash,
        string memory _imageUrl,
        bytes32 _imageHash,
        uint256 _editionSize,
        uint256 _royaltyBPS
        ) public  ERC721(_name, _symbol) Ownable() {
        marketContract = marketContractAddr;
     //    __ERC721_init(_name, _symbol);
    //    __Ownable_init();
        // Set ownership to original sender of contract call
        transferOwnership(_owner);
        description = _description;
        animationUrl = _animationUrl;
        animationHash = _animationHash;
        imageUrl = _imageUrl;
        imageHash = _imageHash;
        editionSize = _editionSize;
        royaltyBPS = _royaltyBPS;
        // Set edition id start to be 1 not 0
        atEditionId.increment();
    }


    /*function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _animationUrl,
        bytes32 _animationHash,
        string memory _imageUrl,
        bytes32 _imageHash,
        uint256 _editionSize,
        uint256 _royaltyBPS
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        // Set ownership to original sender of contract call
        transferOwnership(_owner);
        description = _description;
        animationUrl = _animationUrl;
        animationHash = _animationHash;
        imageUrl = _imageUrl;
        imageHash = _imageHash;
        editionSize = _editionSize;
        royaltyBPS = _royaltyBPS;
        // Set edition id start to be 1 not 0
        atEditionId.increment();
    }
*/

    /// @dev returns the number of minted tokens within the edition
    function totalSupply() public view returns (uint256) {
        return atEditionId.current() - 1;
    }
    /**
        Simple eth-based sales function
        More complex sales functions can be implemented through IMintableEditions interface
     */

    /**
      @dev This allows the user to purchase a edition edition
           at the given price in the contract.
     */
    function purchase() external payable returns (uint256) {
        require(salePrice > 0, "Not for sale");
        require(msg.value == salePrice, "Wrong price");
        address[] memory toMint = new address[](1);
        toMint[0] = msg.sender;
        emit EditionSold(salePrice, msg.sender);
        return _mintEditions(toMint);
    }

    /**
      @param _salePrice if sale price is 0 sale is stopped, otherwise that amount 
                       of ETH is needed to start the sale.
      @dev This sets a simple ETH sales price
           Setting a sales price allows users to mint the edition until it sells out.
           For more granular sales, use an external sales contract.
     */
    function setSalePrice(uint256 _salePrice) external onlyOwner {
        salePrice = _salePrice;
        emit PriceChanged(salePrice);
    }

    /**
      @dev This withdraws ETH from the contract to the contract owner.
     */
    function withdraw() external onlyOwner {
        // No need for gas limit to trusted address.
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /**
      @dev This helper function checks if the msg.sender is allowed to mint the
            given edition id.
     */
    function _isAllowedToMint() internal view returns (bool) {
        if (owner() == msg.sender) {
            return true;
        }
        if (allowedMinters[address(0x0)]) {
            return true;
        }
        return allowedMinters[msg.sender];
    }

    /**
      @param to address to send the newly minted edition to
      @dev This mints one edition to the given address by an allowed minter on the edition instance.
     */
    function mintEdition(address to) external override returns (uint256) {
        require(_isAllowedToMint(), "Needs to be an allowed minter");
        address[] memory toMint = new address[](1);
        toMint[0] = to;
        return _mintEditions(toMint);
    }
    
   /* function mintEditionMarket(address creator, IMarket.BidShares memory bidShares) public{
        //require(_isAllowedToMint(), "Needs to be an allowed minter");
        
        data = getMediaData();
       
       _mintToMarket(creator,data,bidShares);

    }*/

    /**
      @param recipients list of addresses to send the newly minted editions to
      @dev This mints multiple editions to the given list of addresses.
     */
    function mintEditions(address[] memory recipients)
        external
        override
        returns (uint256)
    {
        require(_isAllowedToMint(), "Needs to be an allowed minter");
        return _mintEditions(recipients);
    }

    /**
        Simple override for owner interface.
     */
    function owner()
        public
        view
        override(Ownable, IMintableEditions)
        returns (address)
    {
        return super.owner();
    }

    /**
      @param minter address to set approved minting status for
      @param allowed boolean if that address is allowed to mint
      @dev Sets the approved minting status of the given address.
           This requires that msg.sender is the owner of the given edition id.
           If the ZeroAddress (address(0x0)) is set as a minter,
             anyone will be allowed to mint.
           This setup is similar to setApprovalForAll in the ERC721 spec.
     */
    function setApprovedMinter(address minter, bool allowed) public onlyOwner {
        allowedMinters[minter] = allowed;
    }

    /**
      @dev Allows for updates of edition urls by the owner of the edition.
           Only URLs can be updated (data-uris are supported), hashes cannot be updated.
     */
    function updateEditionURLs(
        string memory _imageUrl,
        string memory _animationUrl
    ) public onlyOwner {
        imageUrl = _imageUrl;
        animationUrl = _animationUrl;
    }

    /// Returns the number of editions allowed to mint (max_uint256 when open edition)
    function numberCanMint() public view override returns (uint256) {
        // Return max int if open edition
        if (editionSize == 0) {
            return type(uint256).max;
        }
        // atEditionId is one-indexed hence the need to remove one here
        return editionSize + 1 - atEditionId.current();
    }

    /**
        @param tokenId Token ID to burn
        User burn function for token id 
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved");
        _burn(tokenId);
    }

    /**
      @dev Private function to mint als without any access checks.
           Called by the public edition minting functions.
     */
    function _mintEditions(address[] memory recipients)
        internal
        returns (uint256)
    {
        uint256 startAt = atEditionId.current();
        uint256 endAt = startAt + recipients.length - 1;
        require(editionSize == 0 || endAt <= editionSize, "Sold out");
        while (atEditionId.current() <= endAt) {
            _mint(
                recipients[atEditionId.current() - startAt],
                atEditionId.current()
            );
            atEditionId.increment();
        }
        return atEditionId.current();
    }
    
   
        
    
   /* function _mintToMarket(
        address creator,
        MediaData memory data,
        IMarket.BidShares memory bidShares
    ) internal onlyValidURI(data.tokenURI) onlyValidURI(data.metadataURI) {
        require(data.contentHash != 0, "Media: content hash must be non-zero");
        require(
            _contentHashes[data.contentHash] == false,
            "Media: a token has already been created with this content hash"
        );
        require(
            data.metadataHash != 0,
            "Media: metadata hash must be non-zero"
        );

        uint256 tokenId = atEditionId.current();

        _safeMint(creator, tokenId);
       // _tokenIdTracker.increment();
        _setTokenContentHash(tokenId, data.contentHash);
        _setTokenMetadataHash(tokenId, data.metadataHash);
        _setTokenMetadataURI(tokenId, data.metadataURI);
        _setTokenURI(tokenId, data.tokenURI);
        _creatorTokens[creator].add(tokenId);
        _contentHashes[data.contentHash] = true;

        tokenCreators[tokenId] = creator;
        previousTokenOwners[tokenId] = creator;
        IMarket(marketContract).setBidShares(tokenId, bidShares);
    } */

    /**
      @dev Get URIs for edition NFT
      @return imageUrl, imageHash, animationUrl, animationHash
     */
    function getURIs()
        public
        view
        returns (
            string memory,
            bytes32,
            string memory,
            bytes32
        )
    {
        return (imageUrl, imageHash, animationUrl, animationHash);
    }
    
   /* function getMediaData()
    public
    view
    returns (MediaData memory mediaData)
    {
        
        bytes memory metadataJSON = sharedNFTLogic.createMetadataMedia;
       const contentHash = sha256FromBuffer(imageUrl);
       const metadataHash = sha256FromBuffer(Buffer.from(metadataJSON));
       const mediaData = constructMediaData(
    imageUrl,
    metadataURI, //??
    contentHash,
    metadataHash
  );
    }*/

    /**
        @dev Get royalty information for token
        @param _salePrice Sale price for the token
     */
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (owner() == address(0x0)) {
            return (owner(), 0);
        }
        return (owner(), (_salePrice * royaltyBPS) / 10_000);
    }

   

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            type(IERC2981).interfaceId == interfaceId ||
            ERC721.supportsInterface(interfaceId);
    }
    
     function base64Encode(bytes memory unencoded)
        public
        pure
        override
        returns (string memory)
    {
        return Base64.encode(unencoded);
    }

    /// Proxy to openzeppelin's toString function
    /// @param value number to return as a string
    function numberToString(uint256 value)
        public
        pure
        override
        returns (string memory)
    {
        return Strings.toString(value);
    }

    /// Generate edition metadata from storage information as base64-json blob
    /// Combines the media data and metadata
    /// @param name Name of NFT in metadata
    /// @param description Description of NFT in metadata
    /// @param imageUrl URL of image to render for edition
    /// @param animationUrl URL of animation to render for edition
    /// @param tokenOfEdition Token ID for specific token
    /// @param editionSize Size of entire edition to show
    function createMetadataEdition(
        string memory name,
        string memory description,
        string memory imageUrl,
        string memory animationUrl,
        uint256 tokenOfEdition,
        uint256 editionSize
    ) external pure returns (string memory) {
        string memory _tokenMediaData = tokenMediaData(
            imageUrl,
            animationUrl,
            tokenOfEdition
        );
        bytes memory json = createMetadataJSON(
            name,
            description,
            _tokenMediaData,
            tokenOfEdition,
            editionSize
        );
        return encodeMetadataJSON(json);
    }
    
    function createMetadataMedia(
        string memory name,
        string memory description,
       string memory imageUrl,
       string memory animationUrl,
        uint256 tokenOfEdition,
        uint256 editionSize
    ) external pure returns (bytes memory) {
        string memory _tokenMediaData = tokenMediaData(
            imageUrl,
            animationUrl,
            tokenOfEdition
        );
        bytes memory json = createMetadataJSON(
            name,
            description,
            _tokenMediaData,
            tokenOfEdition,
            editionSize
        );
        return json;
    }

    /// Function to create the metadata json string for the nft edition
    /// @param name Name of NFT in metadata
    /// @param description Description of NFT in metadata
    /// @param mediaData Data for media to include in json object
    /// @param tokenOfEdition Token ID for specific token
    /// @param editionSize Size of entire edition to show
    function createMetadataJSON(
        string memory name,
        string memory description,
        string memory mediaData,
        uint256 tokenOfEdition,
        uint256 editionSize
    ) public pure returns (bytes memory) {
        bytes memory editionSizeText;
        if (editionSize > 0) {
            editionSizeText = abi.encodePacked(
                "/",
                numberToString(editionSize)
            );
        }
        return
            abi.encodePacked(
                '{"name": "',
                name,
                " ",
                numberToString(tokenOfEdition),
                editionSizeText,
                '", "',
                'description": "',
                description,
                '", "',
                mediaData,
                'properties": {"number": ',
                numberToString(tokenOfEdition),
                ', "name": "',
                name,
                '"}}'
            );
    }

    /// Encodes the argument json bytes into base64-data uri format
    /// @param json Raw json to base64 and turn into a data-uri
    function encodeMetadataJSON(bytes memory json)
        public
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64Encode(json)
                )
            );
    }

    /// Generates edition metadata from storage information as base64-json blob
    /// Combines the media data and metadata
    /// @param imageUrl URL of image to render for edition
    /// @param animationUrl URL of animation to render for edition
    function tokenMediaData(
        string memory imageUrl,
        string memory animationUrl,
        uint256 tokenOfEdition
    ) public pure returns (string memory) {
        bool hasImage = bytes(imageUrl).length > 0;
        bool hasAnimation = bytes(animationUrl).length > 0;
        if (hasImage && hasAnimation) {
            return
                string(
                    abi.encodePacked(
                        'image": "',
                        imageUrl,
                        "?id=",
                        numberToString(tokenOfEdition),
                        '", "animation_url": "',
                        animationUrl,
                        "?id=",
                        numberToString(tokenOfEdition),
                        '", "'
                    )
                );
        }
        if (hasImage) {
            return
                string(
                    abi.encodePacked(
                        'image": "',
                        imageUrl,
                        "?id=",
                        numberToString(tokenOfEdition),
                        '", "'
                    )
                );
        }
        if (hasAnimation) {
            return
                string(
                    abi.encodePacked(
                        'animation_url": "',
                        animationUrl,
                        "?id=",
                        numberToString(tokenOfEdition),
                        '", "'
                    )
                );
        }

        return "";
    }
    
     /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    /*function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "No token");

        return
            createMetadataEdition(
                name(),
                description,
                imageUrl,
                animationUrl,
                tokenId,
                editionSize
            );
    }*/
}

