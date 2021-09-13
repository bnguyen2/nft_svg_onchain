// SPDX_License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "base64-sol/base64.sol";

contract RandomSVG is ERC721URIStorage, VRFConsumerBase {
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public tokenCounter;
    address payable public owner;

    // SVG parameters
    uint256 public maxNumberOfPaths;
    uint256 public maxNumberOfPathCommands;
    uint256 public size;
    uint256 public price;
    string[] public pathCommands;
    string[] public colors;

    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;

    event requestedRandomSVG(
        bytes32 indexed requestId,
        uint256 indexed tokenId
    );
    event CreatedUnfinishedRandomSVG(
        uint256 indexed tokenId,
        uint256 randomNumber
    );
    event CreatedRandomSVG(uint256 indexed tokenId, string tokenURI);

    constructor(
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyhash,
        uint256 _fee
    )
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
        ERC721("RandomSVG", "rsNFT")
    {
        fee = _fee;
        keyHash = _keyhash;
        tokenCounter = 0;
        price = 100000000000000000; // 0.1 ETH / MATIC / AVAX
        owner = payable(msg.sender);
        maxNumberOfPaths = 10;
        maxNumberOfPathCommands = 5;
        size = 500;
        pathCommands = ["M", "L"];
        colors = ["red", "blue", "green", "yellow", "black", "white"];
    }

    function create() public payable returns (bytes32 _requestId) {
        // blockchains are deterministic
        // oracles, Chainlink VRF (chainlink verifiable randomness function)
        require(msg.value >= price, "Need to send more ETH");
        _requestId = requestRandomness(keyHash, fee);
        requestIdToSender[_requestId] = msg.sender;
        uint256 tokenId = tokenCounter;
        requestIdToTokenId[_requestId] = tokenId;
        tokenCounter = tokenCounter + 1;
        emit requestedRandomSVG(_requestId, tokenId);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner!");
        _;
    }

    function withdraw() public payable {
        owner.transfer(address(this).balance);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber)
        internal
        override
    {
        // The Chainlink VRF has a max gas of 200,000 gas (computation units)
        address nftOwner = requestIdToSender[_requestId];
        uint256 tokenId = requestIdToTokenId[_requestId];
        _safeMint(nftOwner, tokenId);
        tokenIdToRandomNumber[tokenId] = _randomNumber;
        emit CreatedUnfinishedRandomSVG(tokenId, _randomNumber);
    }

    function finishMint(uint256 _tokenId) public {
        // check to see if it's minted and a random number is returned
        // generate some random SVG code
        // turn that into an image URI
        // use that imageURI to format into a tokenURI
        require(
            bytes(tokenURI(_tokenId)).length <= 0,
            "tokenURI is already set!"
        );
        require(tokenCounter > _tokenId, "TokenId has not been minted yet!");
        require(
            tokenIdToRandomNumber[_tokenId] > 0,
            "Need to wait for the Chainlink node to respond!"
        );
        uint256 randomNumber = tokenIdToRandomNumber[_tokenId];
        string memory svg = generateSVG(randomNumber);
        string memory imageURI = svgToImageURI(svg);
        _setTokenURI(_tokenId, formatTokenURI(imageURI));
        emit CreatedRandomSVG(_tokenId, svg);
    }

    function generateSVG(uint256 _randomNumber)
        public
        view
        returns (string memory finalSvg)
    {
        uint256 numberOfPaths = (_randomNumber % maxNumberOfPaths) + 1;
        finalSvg = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' height='",
                uint2str(size),
                "' width='",
                uint2str(size),
                "'>'"
            )
        );

        for (uint256 i = 0; i < numberOfPaths; i++) {
            uint256 newRNG = uint256(keccak256(abi.encode(_randomNumber, i)));
            string memory pathSvg = generatePath(newRNG);
            finalSvg = string(abi.encodePacked(finalSvg, pathSvg));
        }
        finalSvg = string(abi.encodePacked(finalSvg, "</svg>"));
    }

    function generatePath(uint256 _randomNumber)
        public
        view
        returns (string memory pathSvg)
    {
        uint256 numberOfPathCommands = (_randomNumber %
            maxNumberOfPathCommands) + 1;
        pathSvg = "<path d='";
        for (uint256 i = 0; i < numberOfPathCommands; i++) {
            uint256 newRNG = uint256(
                keccak256(abi.encode(_randomNumber, size + i))
            );
            string memory pathCommand = generatePathCommand(newRNG);
            pathSvg = string(abi.encodePacked(pathSvg, pathCommand));
        }
        string memory color = colors[_randomNumber % colors.length];
        pathSvg = string(
            abi.encodePacked(
                pathSvg,
                "' fill='transparent' stroke='",
                color,
                "'/>"
            )
        );
    }

    function generatePathCommand(uint256 _randomNumber)
        public
        view
        returns (string memory pathCommand)
    {
        pathCommand = pathCommands[_randomNumber % pathCommands.length];
        uint256 parameterOne = uint256(
            keccak256(abi.encode(_randomNumber, size * 2))
        ) % size;
        uint256 parameterTwo = uint256(
            keccak256(abi.encode(_randomNumber, size * 3))
        ) % size;
        pathCommand = string(
            abi.encodePacked(
                pathCommand,
                " ",
                uint2str(parameterOne),
                " ",
                uint2str(parameterTwo)
            )
        );
    }

    function svgToImageURI(string memory _svg)
        public
        pure
        returns (string memory)
    {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(_svg)))
        );
        string memory imageURI = string(
            abi.encodePacked(baseURL, svgBase64Encoded)
        );
        return imageURI;
    }

    function formatTokenURI(string memory _imageURI)
        public
        pure
        returns (string memory)
    {
        string memory baseURL = "data:application/json;base64,";

        return
            string(
                abi.encodePacked(
                    baseURL,
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "SVG NFT", ',
                                '"description": "an NFT based on SVG!", ',
                                '"attributes": "", ',
                                '"image": "',
                                _imageURI,
                                '" }'
                            )
                        )
                    )
                )
            );
    }

    // From: https://stackoverflow.com/a/65707309/11969592
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
