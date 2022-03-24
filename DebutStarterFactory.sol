//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";
import { Base64 } from "./libraries/Base64.sol";


contract DebutStarterFactory is ERC721URIStorage {

    //DebutStarter struct
    struct DebutStarter {
        uint ID;
        string DebutStarterName;
        uint targetValue;
        uint commissionPct;
        uint ticketPrice;
        bool isLive;
        address artist;
    }

    struct Supporter {
        address supporterAddress;
        uint debutStarterID;
    }

    // NFT counters
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //Initialize with a first Debut Starter
    DebutStarter public firstDebutStarter;

    uint256 randomNumber;

    // Array of Debut Starter
    DebutStarter[] debutStarterArray;

    //DebutStarter creator
    address payable public debutStarterCreator;

    // Temporary NFT image
    string svgHolder1 = "<svg width="250" height="250" viewBox="0 0 250 250" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><rect width="250" height="250" rx="10" fill="#fff"/><g clip-path="url(#a)"><rect width="250" height="250" rx="10" fill="url(#b)"/><g filter="url(#c)"><circle cx="125" cy="125" r="99" fill="url(#d)" shape-rendering="crispEdges"/></g></g><defs><linearGradient id="b" x1="240.925" y1="132.563" x2="2.928" y2="132.971" gradientUnits="userSpaceOnUse"><stop stop-color="#C4E7E1"/><stop offset="1" stop-color="#FABFBB"/></linearGradient><clipPath id="a"><rect width="250" height="250" rx="10" fill="#fff"/></clipPath><pattern id="d" patternContentUnits="objectBoundingBox" width="1" height="1"><use xlink:href="#e" transform="translate(-.25) scale(.00313)"/></pattern><filter id="c" x="7" y="14" width="240" height="240" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dx="2" dy="9"/><feGaussianBlur stdDeviation="10.5"/><feComposite in2="hardAlpha" operator="out"/><feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0"/><feBlend in2="BackgroundImageFix" result="effect1_dropShadow_219_720"/><feBlend in="SourceGraphic" in2="effect1_dropShadow_219_720" result="shape"/></filter><image id="e" width="480" height="320" xlink:href="data:image/jpeg;base64,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"/></defs><text>";
    string svgHolder2 = "</text><text x='50%' y='70%' class='base' dominant-baseline='middle' text-anchor='middle'>";
    string svgHolder3 = "</text></svg>";

    // Array of players
    Supporter[] debutStarterSupporter;
    Supporter[] activeDebutStarterSupporter;

    // Events

    event NewDebutStarterNFTMinted(address supporter, uint256 tokenId);
    event debutStarterCollected(address supporter, uint debutStarterID);
    event debutStarterAdded(uint indexed id, string DebutStarterName, uint targetValue, uint commissionPct, uint ticketPrice, bool isLive, address artist);
    event debutStarterClosed(uint debutStarterID);

    constructor(
        uint firstDebutID,
        string memory firstDebutStarterName,
        uint firstTargetValue,
        uint firstCommissionPct,
        uint firstTicketPrice,
        bool firstIsLive,
        address firstArtist

    )
    payable  ERC721("Debut Starter NFT", "DSN")
    {
        firstDebutStarter = DebutStarter({
        ID: firstDebutID,
        DebutStarterName: firstDebutStarterName,
        targetValue: firstTargetValue,
        commissionPct: firstCommissionPct,
        ticketPrice: firstTicketPrice,
        isLive: firstIsLive,
        artist: firstArtist
        });

        debutStarterArray.push(firstDebutStarter);

        // DebutStarter Creator is the initializing account
        debutStarterCreator = payable(msg.sender);

        // Pushing the Token count to start with 1
        _tokenIds.increment();

    }

    // Get functions
    function getDebutStarter() public view returns (DebutStarter[] memory) {
        return debutStarterArray;
    }

    // Factory balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // supporters info
    function getAllSupporters() public view returns (Supporter[] memory) {
        return debutStarterSupporter;
    }

    // supporters by debut stater
    function getSupportersByDebutStarter(uint _debutStarterID) public returns (Supporter[] memory ) {

        for (uint i = 0; i < debutStarterSupporter.length; i++) {

            if (debutStarterSupporter[i].debutStarterID == _debutStarterID) {
                activeDebutStarterSupporter.push(debutStarterSupporter[i]);
            }
        }
        return activeDebutStarterSupporter;
    }


    // Function to buy a ticket and calls another function to mint the NFT
    function buySoundTrack(address from, uint debutStarterID) public payable {

        require (debutStarterArray[debutStarterID - 1].isLive, "Debut Starter is ended");
        require (debutStarterArray[debutStarterID - 1].ticketPrice == msg.value, "Price must be equal to mint price");

        debutStarterSupporter.push(Supporter(from, debutStarterID));

        // Mint
        mintSoundTrack(from, debutStarterID);

        if (address(this).balance >= debutStarterArray[debutStarterID - 1].targetValue) {
            // close this debutStarter
            closeDebutStarter(false, debutStarterID);
            emit debutStarterClosed(debutStarterID);
        }

    }

    function finalizeWinner(uint starterID) public returns (uint _starterID) {

        require (msg.sender == debutStarterCreator, "Not DebutStarter Creator");

        // withdraw commission % from pot and send to creator
        uint commissionAmount = address(this).balance * debutStarterArray[starterID - 1].commissionPct / 100;
        payCommission(commissionAmount);
        // run random ticket selector function to pick an address, emit this address
        Supporter[] memory activePlayers = getSupportersByDebutStarter(starterID);

        //TODO VRF

        payRevenue(debutStarterArray[starterID - 1].artist);


    emit debutStarterCollected(debutStarterArray[starterID - 1].artist, starterID);

        // close this ds in case not already closed
        closeDebutStarter(false, starterID);

        emit debutStarterClosed(starterID);

        return (starterID);

    }

    function random() public view returns (uint) {

        uint index = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, debutStarterSupporter.length)));
        return index;

    }

    function payCommission(uint commissionAmount) private {

        (bool sent, bytes memory data) = debutStarterCreator.call{value: commissionAmount}("");
        require(sent, "Failed to send Ether");
        getBalance();

    }

    function payRevenue(address artist) private {

        (bool sent, bytes memory data) = artist.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");

        getBalance();

    }

    function closeDebutStarter(bool newVal, uint debutStarterID) internal {
        debutStarterArray[debutStarterID - 1].isLive = newVal;
    }

    function mintSoundTrack(address supporter, uint debutStarterID) internal {
        uint256 newItemId = _tokenIds.current();

        //TODO : description
        string memory finalSvg = string(abi.encodePacked(svgHolder1, svgHolder2, "Artist: ", debutStarterArray[debutStarterID - 1].DebutStarterName, svgHolder3));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "NE1 Edition NFT ", "description": "This NFT represents a confirmed edition purchase for the Debut Starter", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(abi.encodePacked("data:application/json;base64,", json));

        _safeMint(supporter, newItemId);
        _setTokenURI(newItemId, finalTokenUri);
        _tokenIds.increment();

        emit NewDebutStarterNFTMinted(supporter, newItemId);
    }

    function openDebutStarter(
        string memory _name,
        uint _targetValue,
        uint _commissionPct,
        uint _ticketPrice,
        bool _isLive,
        address _artist
    )
    public {

        require (msg.sender == debutStarterCreator, "Unauthorized");

        uint arrayLength = debutStarterArray.length;
        /////"arrayLength:", arrayLength);

        uint newID = debutStarterArray[arrayLength - 1].ID + 1;

        /////"newID:", newID);

        DebutStarter memory ds = DebutStarter(newID, _name, _targetValue, _commissionPct, _ticketPrice, _isLive, _artist);

        debutStarterArray.push(ds);

    }

    function withdrawAllMoney() public payable {
        require (msg.sender == debutStarterCreator, "Not DebutStarter Creator");
        (bool sent, bytes memory data) = debutStarterCreator.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function destroySmartContract(address payable _to) public {
        require (msg.sender == debutStarterCreator, "Not DebutStarter Creator");
        selfdestruct(_to);
    }

    receive() external payable {}

    fallback() external payable {}
}