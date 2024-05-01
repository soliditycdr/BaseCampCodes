// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin ERC721 contract
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";

// Interface for interacting with a submission contract
interface ISubmission {
    // Struct representing a Devo
    struct Devo {
        address author; // Address of the Devo author
        string line1; // First line of the Devo
        string line2; // Second line of the Devo
        string line3; // Third line of the Devo
    }

    // Function to mint a new Devo
    function mintDevo(
        string memory _line1,
        string memory _line2,
        string memory _line3
    ) external;

    // Function to get the total number of Devos
    function counter() external view returns (uint256);

    // Function to share a Devo with another address
    function shareDevo(uint256 _id, address _to) external;

    // Function to get Devos shared with the caller
    function getMySharedDevos() external view returns (Devo[] memory);
}

// Contract for managing Devo NFTs
contract DevoNFT is ERC721, ISubmission {
    Devo[] public Devos; // Array to store Devos
    mapping(address => mapping(uint256 => bool)) public sharedDevos; // Mapping to track shared Devos
    uint256 public DevoCounter; // Counter for total Devos minted

    // Constructor to initialize the ERC721 contract
    constructor() ERC721("DevoNFT", "Devo") {
        DevoCounter = 1; // Initialize Devo counter
    }

    string salt = "value"; // A private string variable

    // Function to get the total number of Devos
    function counter() external view override returns (uint256) {
        return DevoCounter;
    }

    // Function to mint a new Devo
    function mintDevo(
        string memory _line1,
        string memory _line2,
        string memory _line3
    ) external override {
        // Check if the Devo is unique
        string[3] memory DevosStrings = [_line1, _line2, _line3];
        for (uint256 li = 0; li < DevosStrings.length; li++) {
            string memory newLine = DevosStrings[li];
            for (uint256 i = 0; i < Devos.length; i++) {
                Devo memory existingDevo = Devos[i];
                string[3] memory existingDevoStrings = [
                    existingDevo.line1,
                    existingDevo.line2,
                    existingDevo.line3
                ];
                for (uint256 eHsi = 0; eHsi < 3; eHsi++) {
                    string memory existingDevoString = existingDevoStrings[
                        eHsi
                    ];
                    if (
                        keccak256(abi.encodePacked(existingDevoString)) ==
                        keccak256(abi.encodePacked(newLine))
                    ) {
                        revert DevoNotUnique();
                    }
                }
            }
        }

        // Mint the Devo NFT
        _safeMint(msg.sender, DevoCounter);
        Devos.push(Devo(msg.sender, _line1, _line2, _line3));
        DevoCounter++;
    }

    // Function to share a Devo with another address
    function shareDevo(uint256 _id, address _to) external override {
        require(_id > 0 && _id <= DevoCounter, "Invalid Devo ID");

        Devo memory DevoToShare = Devos[_id - 1];
        require(DevoToShare.author == msg.sender, "NotYourDevo");

        sharedDevos[_to][_id] = true;
    }

    // Function to get Devos shared with the caller
    function getMySharedDevos()
        external
        view
        override
        returns (Devo[] memory)
    {
        uint256 sharedDevoCount;
        for (uint256 i = 0; i < Devos.length; i++) {
            if (sharedDevos[msg.sender][i + 1]) {
                sharedDevoCount++;
            }
        }

        Devo[] memory result = new Devo[](sharedDevoCount);
        uint256 currentIndex;
        for (uint256 i = 0; i < Devos.length; i++) {
            if (sharedDevos[msg.sender][i + 1]) {
                result[currentIndex] = Devos[i];
                currentIndex++;
            }
        }

        if (sharedDevoCount == 0) {
            revert NoDevosShared();
        }

        return result;
    }

    // Custom errors
    error DevoNotUnique(); // Error for attempting to mint a non-unique Devo
    error NotYourDevo(); // Error for attempting to share a Devo not owned by the caller
    error NoDevosShared(); // Error for no Devos shared with the caller
}
