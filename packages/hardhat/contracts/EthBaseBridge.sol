// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./WrappedToken.sol";

/**
 * @title EthBaseBridge
 * @dev Bridge contract for transferring tokens between Ethereum and Base
 */
contract EthBaseBridge is Ownable, ReentrancyGuard {
    // Events
    event TokensLocked(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event TokensReleased(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event WrappedTokensMinted(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event WrappedTokensBurned(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    // Mapping to track locked tokens
    mapping(address => mapping(address => uint256)) public lockedTokens;

    // Mapping to track wrapped token addresses
    mapping(address => address) public wrappedTokens;

    /**
     * @dev Constructor sets the owner of the contract
     * @param initialOwner The address of the initial owner
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Creates a new wrapped token for an original token
     * @param originalToken The token to create a wrapped version for
     */
    function createWrappedToken(address originalToken) external onlyOwner {
        require(originalToken != address(0), "Invalid token address");
        require(wrappedTokens[originalToken] == address(0), "Already exists");

        string memory name = IERC20(originalToken).name();
        string memory symbol = IERC20(originalToken).symbol();

        // Create the wrapped token and set the bridge as the initial owner
        WrappedToken wToken = new WrappedToken(
            string(abi.encodePacked("Wrapped ", name)),
            string(abi.encodePacked("w", symbol)),
            originalToken,
            address(this) // The bridge becomes the initial owner
        );

        wrappedTokens[originalToken] = address(wToken);
    }

    /**
     * @dev Deposits tokens to be bridged
     * @param token The address of the token to bridge
     * @param amount The amount of tokens to bridge
     */
    function deposit(address token, uint256 amount) external nonReentrant {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");
        require(wrappedTokens[token] != address(0), "Token not supported");

        IERC20 tokenContract = IERC20(token);
        require(
            tokenContract.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        lockedTokens[token][msg.sender] += amount;

        emit TokensLocked(
            token,
            msg.sender,
            amount,
            block.timestamp
        );
    }

    /**
     * @dev Mints wrapped tokens on Base chain
     * @param token The address of the original token
     * @param user The user to receive wrapped tokens
     * @param amount The amount of tokens to mint
     */
    function mintWrappedToken(address token, address user, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");

        address wrappedTokenAddr = wrappedTokens[token];
        require(wrappedTokenAddr != address(0), "Token not supported");

        // Mint wrapped tokens to the user
        WrappedToken(wrappedTokenAddr).mint(user, amount);

        emit WrappedTokensMinted(
            token,
            user,
            amount,
            block.timestamp
        );
    }

    /**
     * @dev Burns wrapped tokens on Base chain
     * @param token The address of the original token
     * @param user The user burning tokens
     * @param amount The amount of tokens to burn
     */
    function burnWrappedToken(address token, address user, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");

        address wrappedTokenAddr = wrappedTokens[token];
        require(wrappedTokenAddr != address(0), "Token not supported");

        // Burn wrapped tokens from the user
        WrappedToken(wrappedTokenAddr).burn(user, amount);

        emit WrappedTokensBurned(
            token,
            user,
            amount,
            block.timestamp
        );
    }

    /**
     * @dev Releases original tokens back to the user
     * @param token The address of the original token
     * @param user The user to receive tokens
     * @param amount The amount of tokens to release
     */
    function releaseOriginalToken(address token, address user, uint256 amount) external onlyOwner nonReentrant {
        require(token != address(0), "Invalid token address");
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        require(
            lockedTokens[token][user] >= amount,
            "Insufficient locked tokens"
        );

        lockedTokens[token][user] -= amount;

        IERC20 tokenContract = IERC20(token);
        require(
            tokenContract.transfer(user, amount),
            "Transfer failed"
        );

        emit TokensReleased(
            token,
            user,
            amount,
            block.timestamp
        );
    }
}
