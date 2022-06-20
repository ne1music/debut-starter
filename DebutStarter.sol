//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./libraries/IERC2981.sol";
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract debutStarter_eth is ERC721Enumerable, ERC721URIStorage, VRFConsumerBaseV2 {

    struct DebutStarter {
        string debutStarterName;
        uint ticketPrice;
        bool isLive;
        address artist;
        uint max_supply;
    }

    enum Edition{
        legendary,
        unique,
        rare,
        uncommon,
        artist
    }

    struct Royalty {
        address recipient;
        uint256 salePrice;
    }

    struct Supporter {
        address supporterAddress;
        Edition tokens;
    }

    // NFT counters
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => Royalty) internal _royalties;

    // DebutStarter info
    DebutStarter debutStarterInfo;

    //DebutStarter creator
    address payable public debutStarterCreator;
    uint256 public constant royaltiesPercentage = 2;

    // Array of supporters
    Supporter[] supporters;
    address private _royaltiesReceiver;
    uint256 public constant legendary_max = 4 + 1;
    uint256 public constant unique_max = 16 + 1;
    uint256 public constant rare_max = 32 + 1;
    uint256 public MAX_SUPPLY;

    // VRF ID
    uint64 public RQ_ID = 4397;

    address public oracle;
    uint256[] public random;
    bytes32 public reqId;
    uint32 numWords;

    function requestRandomWords() external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function getRandom() public view returns (uint256) {
        return random[0];
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        random = randomWords;
    }

    function addConsumer(address consumerAddress) external onlyOwner {
        // Add a consumer contract to the subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
    }
    function createNewSubscription() private onlyOwner {
        // Create a subscription with a new subscription ID.
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumers[0]);
    }
    // Events

    event NewDebutStarterNFTMinted(address supporter, string tokenURI);
    event debutStarterCollected(address supporter);
    event debutStarterAdded(uint indexed id, string DebutStarterName, uint commissionPct, uint ticketPrice, bool isLive, address artist);
    event debutStarterClosed();

    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Rinkeby coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 1000000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;
    uint256 public s_requestId;
    address s_owner;
    uint256 public createTime;


    constructor(
        string memory _debutStarterName,
        string memory _debutStarterSymbol,
        uint _ticketPrice,
        bool _isLive,
        address _artist,
        uint _max_supply
    )
    payable ERC721(_debutStarterName, _debutStarterSymbol)
    VRFConsumerBaseV2(vrfCoordinator)
    {
        debutStarterInfo = DebutStarter({
        debutStarterName: _debutStarterName,
        ticketPrice: _ticketPrice,
        isLive: _isLive,
        artist: _artist,
        max_supply: _max_supply
        });

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = RQ_ID;
        createTime = block.timestamp;

        MAX_SUPPLY = _max_supply;
        numWords = 2;
        // DebutStarter Creator is the initializing account
        debutStarterCreator = payable(msg.sender);
    }

    // Contract balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getStatus() public view returns (bool) {
        return debutStarterInfo.isLive;
    }

    function _setTokenRoyalty(uint256 tokenId, address recipient, uint256 salePrice) internal {
        //This is so expected 'value' will be at most 10,000 which is 100%
        require(salePrice <= 10000, "ERC2981Royalities: Too high");
        //How can I set the recipient to use the array of _payees and _shares here?
        _royalties[tokenId] = Royalty(recipient, salePrice);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        if(_royalties[tokenId].recipient != address(0)) {
            return (_royalties[tokenId].recipient, salePrice * _royalties[tokenId].salePrice / 10000);
        }
        Royalty memory royalty = _royalties[tokenId];
        if(royalty.recipient != address(0) && royalty.salePrice != 0) {
            return (royalty.recipient, (salePrice * royalty.salePrice) / 10000);
        }
        return (address(0), 0);
    }

    // Function to buy a ticket and calls another function to mint the NFT
    function buySoundTrack(address supporter, uint256 tokenId, string memory tokenURI_) public payable {

        require(totalSupply() <= MAX_SUPPLY, "All tokens minted");
        require (debutStarterInfo.ticketPrice == msg.value, "Price must be equal to mint price");

        uint256 newItemId = _tokenIds.current();

        Supporter memory newSupporter = Supporter(supporter, Edition.uncommon);
        supporters.push(newSupporter);

        supporters[newItemId].supporterAddress = supporter;
        _safeMint(supporter, newItemId);
        _setTokenURI(newItemId, tokenURI_);
        _tokenIds.increment();

        emit NewDebutStarterNFTMinted(supporter, tokenURI_);

        if (totalSupply() <= MAX_SUPPLY){
            closeDebutStarter(false);
            emit debutStarterClosed();
        }
    }

    function finalizeWinner() public{

        require(random[0] != 0,'random number isnt ready');
        string memory hash = "https://ne1musio.io/";

        debutStarterInfo.isLive = false;
        uint n = debutStarterInfo.max_supply;
        for (uint256 i = 1; i < n ; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(random[0], block.timestamp))) % (supporters.length - i);

            Supporter memory temp = supporters[n];
            supporters[n] = supporters[i];
            supporters[i] = temp;
        }

        supporters[0].tokens = Edition.artist;

        for(uint i=0; i<legendary_max; i++){//4
            supporters[i].tokens = Edition.legendary;
            _setTokenURI(i, hash + '/legendary');
        }
        for(uint i=legendary_max; i<legendary_max + unique_max; i++){ // 4 16
            supporters[i].tokens = Edition.unique;
            _setTokenURI(i, hash + '/unique');
        }
        for(uint i=legendary_max + unique_max; i<legendary_max + unique_max + rare_max; i++){ //32
            supporters[i].tokens = Edition.rare;
            _setTokenURI(i, hash + '/rare');
        }
        for(uint i=legendary_max + unique_max + rare_max; i<MAX_SUPPLY; i++){
            _setTokenURI(i, hash + '/uncommon');
            supporters[i].tokens = Edition.uncommon;
        }
        payRevenue(debutStarterInfo.artist);
        emit debutStarterCollected(debutStarterInfo.artist);
        emit debutStarterClosed();

    }

    function getEdition(uint256 tokenId) public view returns (Edition tokens) {
        return supporters[tokenId].tokens;
    }

    function payRevenue(address artist) private {

        (bool sent, bytes memory data) = artist.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");

        getBalance();

    }

    function closeDebutStarter(bool newVal) internal {
        debutStarterInfo.isLive = newVal;
    }

    /** Overrides ERC-721's _baseURI function */
    function _baseURI() internal view override returns (string memory) {
        return "https://ne1musio.io/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal override(ERC721, ERC721Enumerable) {
        require(!( (to == debutStarterInfo.artist) && (s_owner != from) && (createTime < block.timestamp - 180 days)), 'artist can transfer after 180 days' );
        super._beforeTokenTransfer(from, to, amount);
    }

    function _burn(uint256 tokenId)
    internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function royaltiesReceiver() external returns(address) {
        return _royaltiesReceiver;
    }

    function setRoyaltiesReceiver(address newRoyaltiesReceiver)
    external onlyOwner {
        require(newRoyaltiesReceiver != _royaltiesReceiver); // dev: Same address
        _royaltiesReceiver = newRoyaltiesReceiver;
    }

    /// @notice Informs callers that this contract supports ERC2981
    function supportsInterface(bytes4 interfaceId)
    public view override(ERC721, ERC721Enumerable)
    returns (bool) {
        return interfaceId == type(IERC2981).interfaceId ||
    super.supportsInterface(interfaceId);
    }

    /// @notice Returns all the tokens owned by an address
    /// @param _owner - the address to query
    /// @return ownerTokens - an array containing the ids of all tokens
    ///         owned by the address
    function tokensOfOwner(address _owner) external view
    returns(uint256[] memory ownerTokens ) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            for (uint256 i=0; i<tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    function tokenURI(uint256 tokenId)
    public view override(ERC721, ERC721URIStorage)
    returns (string memory) {
        return super.tokenURI(tokenId);
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    receive() external payable {}
    fallback() external payable {}
}
