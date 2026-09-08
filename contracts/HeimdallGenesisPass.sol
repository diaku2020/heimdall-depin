// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Heimdall Genesis Hardware Pass (Strictly Capped to 10 Worldwide)
 * @notice Official ERC-721 Hardware Entitlement & Access Pass for the Heimdall Ambient Spatial DePIN Network on Base L2.
 * 
 * TOKENOMICS & DEFLATIONARY ENGINE:
 * - Total Max Supply: 10 Tokens (HARD-CAPPED FOREVER).
 * - Token #1: The 1-of-1 Sovereign Master ("The Grand Bubble 11D Manifold")
 *            Mint Price: 25,000 $RNR.
 *            Entitlement: 5 Years of 100% FREE Physical Prototypes delivered to the holder.
 * - Tokens #2 - #10: Genesis Collector Passes (11D Quasicrystal Series)
 *            Mint Price: 5,000 $RNR.
 *            Entitlement: Lifetime Exclusive Access to the Secret Annual Prototype Store.
 * 
 * VALUE RECYCLING FLYWHEEL:
 * - 50% of incoming $RNR is permanently burned to 0x000...dEaD (shrinking circulating supply).
 * - 50% of incoming $RNR is recycled directly to active Heimdall DePIN node miners.
 * - ZERO tokens come from the founder's stash.
 */

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract HeimdallGenesisPass {
    string public constant name = "Heimdall Genesis Hardware Pass";
    string public constant symbol = "11D-PASS";

    // Strictly 10 NFTs Max
    uint256 public constant MAX_SUPPLY = 10;
    uint256 public constant MASTER_PRICE_RNR = 25_000 * 10**18;
    uint256 public constant COLLECTOR_PRICE_RNR = 5_000 * 10**18;

    // $RNR Token on Base L2
    IERC20 public immutable rnrToken;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    address public owner;
    address public minerRewardDistributor;
    
    uint256 public totalSupply;
    bool public masterMinted;
    uint256 public collectorMintedCount; // Up to 9

    // ERC-721 State
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Hardware Entitlement Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event SovereignMasterMinted(address indexed recipient, uint256 indexed tokenId, string entitlement);
    event CollectorPassMinted(address indexed recipient, uint256 indexed tokenId, uint256 editionNum);
    event TokensBurnedAndRecycled(uint256 burnedAmount, uint256 recycledAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "HeimdallPass: Caller is not owner");
        _;
    }

    constructor(address _rnrTokenAddress, address _minerRewardDistributor) {
        require(_rnrTokenAddress != address(0), "Invalid RNR address");
        require(_minerRewardDistributor != address(0), "Invalid distributor address");
        owner = msg.sender;
        rnrToken = IERC20(_rnrTokenAddress);
        minerRewardDistributor = _minerRewardDistributor;
    }

    // --- Minting Functions ---

    /**
     * @notice Mint the 1-of-1 Sovereign Master (Token #1).
     * @dev Reverts if already minted. Burns 50% of RNR, recycles 50% to miners.
     */
    function mintSovereignMaster() external {
        require(!masterMinted, "HeimdallPass: 1-of-1 Sovereign Master already minted");
        masterMinted = true;
        totalSupply += 1;
        uint256 tokenId = 1;

        _processPayment(MASTER_PRICE_RNR);
        _mint(msg.sender, tokenId);

        emit SovereignMasterMinted(
            msg.sender, 
            tokenId, 
            "ENTITLEMENT: 5 YEARS OF FREE PHYSICAL PROTOTYPES DISPATCHED ANNUALLY"
        );
    }

    /**
     * @notice Mint one of the 9 Genesis Collector Passes (Tokens #2 - #10).
     * @dev Reverts if all 9 editions have been minted. Burns 50% of RNR, recycles 50% to miners.
     */
    function mintCollectorPass() external {
        require(collectorMintedCount < 9, "HeimdallPass: All 9 Collector Passes already minted");
        collectorMintedCount += 1;
        totalSupply += 1;
        uint256 tokenId = 1 + collectorMintedCount; // Token IDs 2 through 10

        _processPayment(COLLECTOR_PRICE_RNR);
        _mint(msg.sender, tokenId);

        emit CollectorPassMinted(msg.sender, tokenId, collectorMintedCount);
    }

    function _processPayment(uint256 totalCost) internal {
        uint256 half = totalCost / 2;
        // 50% burned permanently to dead address
        require(rnrToken.transferFrom(msg.sender, BURN_ADDRESS, half), "HeimdallPass: Burn transfer failed");
        // 50% recycled directly to node miner distribution pool
        require(rnrToken.transferFrom(msg.sender, minerRewardDistributor, half), "HeimdallPass: Miner recycle transfer failed");
        emit TokensBurnedAndRecycled(half, half);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "Cannot mint to zero address");
        _owners[tokenId] = to;
        _balances[to] += 1;
        emit Transfer(address(0), to, tokenId);
    }

    // --- Hardware Entitlement & Access Gate Verifiers ---

    /**
     * @notice Checks if the given account holds the 1-of-1 Sovereign Master pass.
     * @return bool True if holding Token #1 (qualifies for 5 years of free physical prototypes).
     */
    function hasFiveYearFreePrototypeEntitlement(address account) external view returns (bool) {
        return _owners[1] == account;
    }

    /**
     * @notice Checks if the given account is authorized to purchase from the Secret Annual Prototype Store.
     * @return bool True if holding any of the 10 passes (Token #1 through #10).
     */
    function canAccessPrototypeStore(address account) external view returns (bool) {
        if (_balances[account] == 0) return false;
        for (uint256 i = 1; i <= 10; i++) {
            if (_owners[i] == account) return true;
        }
        return false;
    }

    // --- ERC-721 Standard View Methods ---

    function ownerOf(uint256 tokenId) external view returns (address) {
        address tokenOwner = _owners[tokenId];
        require(tokenOwner != address(0), "Token does not exist");
        return tokenOwner;
    }

    function balanceOf(address account) external view returns (uint256) {
        require(account != address(0), "Zero address query");
        return _balances[account];
    }

    function tokenURI(uint256 tokenId) external pure returns (string memory) {
        require(tokenId >= 1 && tokenId <= 10, "Invalid tokenId");
        if (tokenId == 1) {
            return "data:application/json;utf8,{\"name\":\"Heimdall Sovereign Master (1-of-1)\",\"description\":\"5 Years of 100% Free Physical Prototypes dispatched directly from the RandRTech laboratory. Strictly 1 of 1 worldwide.\",\"attributes\":[{\"trait_type\":\"Tier\",\"value\":\"Sovereign Master\"},{\"trait_type\":\"Supply\",\"value\":\"1 of 1\"},{\"trait_type\":\"Hardware Entitlement\",\"value\":\"5 Years Free Physical Prototypes\"}]}";
        } else {
            return "data:application/json;utf8,{\"name\":\"Heimdall Collector Pass\",\"description\":\"Lifetime exclusive access to the Secret Annual Prototype Store (1 experimental run released once a year). Strictly limited to 9 passes worldwide.\",\"attributes\":[{\"trait_type\":\"Tier\",\"value\":\"Quasicrystal Pass\"},{\"trait_type\":\"Supply\",\"value\":\"9 Editions Worldwide\"},{\"trait_type\":\"Hardware Entitlement\",\"value\":\"Lifetime Secret Prototype Store Access\"}]}";
        }
    }

    // Admin configuration
    function setMinerRewardDistributor(address _newDistributor) external onlyOwner {
        require(_newDistributor != address(0), "Invalid distributor");
        minerRewardDistributor = _newDistributor;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner");
        owner = _newOwner;
    }
}
