// SDPX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract Vault {
    // we need to pass the token address to the constructor
    // create a deposit function that mints tokens to the user equal to the amount of eth the user deposited
    // create a redeem function that burns tokens from the user and sends the user ETH
    // create a way to add rewards to the vault

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Vault__RedeemFailed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IRebaseToken private immutable i_token;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposit(address indexed user, uint256 indexed amount);
    event Redeem(address indexed user, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(IRebaseToken _token) {
        i_token = _token;
    }

    /*//////////////////////////////////////////////////////////////
                                RECEIVER
    //////////////////////////////////////////////////////////////*/
    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice this allows users to deposit ETH into the vault and mint rebase tokens in return
     */
    function deposit() external payable {
        // TODO: we need to convert the ETH transferred to rebase tokens
        i_token.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice this allows users to burn rebase tokens and receive ETH from the vault in return
     * @param _tokenAmount The amount of rebase tokens to redeem
     */
    function redeem(uint256 _tokenAmount) external {
        // TODO: we need to calculate how much ETH to transfer back to the sender based on the amount of tokens they want to redeem
        i_token.burn(msg.sender, _tokenAmount);

        // this forwards all available gas, as opposed to payable(msg.sender).transfer(_tokenAmount), which only uses fixed 2300 gas
        (bool success,) = payable(msg.sender).call{value: _tokenAmount}("");
        if (!success) {
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender, _tokenAmount);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                PRIVATE
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                  INTERNAL AND PRIVATE VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                   EXTERNAL AND PUBLIC VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getRebaseTokenAddress() external view returns(address) {
        return address(i_token);
    }
}