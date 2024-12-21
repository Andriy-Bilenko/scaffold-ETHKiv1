// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WrappedToken
 * @dev ERC20 token that represents a wrapped version of another token
 */
contract WrappedToken is ERC20, Ownable {
    /// @notice The original token that this token wraps
    address public immutable originalToken;

    /// @notice The bridge contract allowed to mint and burn tokens
    address public immutable bridge;

    /**
     * @dev Constructor sets up the wrapped token details and bridge association
     * @param name The name of the wrapped token
     * @param symbol The symbol of the wrapped token
     * @param _originalToken The address of the original token
     * @param initialOwner The initial owner of this contract
     */
    constructor(
        string memory name,
        string memory symbol,
        address _originalToken,
        address initialOwner
    ) ERC20(name, symbol) Ownable(initialOwner) {
        require(_originalToken != address(0), "Invalid original token address");
        require(initialOwner != address(0), "Invalid initial owner address");

        originalToken = _originalToken;
        bridge = msg.sender; // Set the bridge as the deployer
    }

    /**
     * @dev Mints wrapped tokens
     * @param to The address to mint the tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external {
        require(msg.sender == bridge, "Only the bridge can mint");
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        _mint(to, amount);
    }

    /**
     * @dev Burns wrapped tokens
     * @param from The address to burn the tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external {
        require(msg.sender == bridge, "Only the bridge can burn");
        require(from != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        _burn(from, amount);
    }
}
