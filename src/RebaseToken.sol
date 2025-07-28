// SDPX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";


/**
* @title RebaseToken
* @author Miguel Mota (inspired by Ciara Nightingale's course at https://github.com/Cyfrin/foundry-cross-chain-rebase-token-cu/tree/main)
* @notice This is a cross-chain rebase token that incentivises users to deposit into a vault and gain interest in rewards.
* @notice The interest rate in the smart contract can only decrease 
* @notice Each user will have their own interest rate that is the global interest rate at the time of depositing.
*/
contract RebaseToken is ERC20, Ownable, AccessControl {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error RebaseToken__InterestRateCanOnlyDecrease(uint256 originalValue, uint256 newValue);
    
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 public s_interestRate = 5e10;  // 5e-6 percent interest per second with e18 precision
    mapping(address user => uint256 interestRate) private s_interestsRatesByUser;
    mapping(address user => uint256 updatedAt) private s_lastUpdatesByUser;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event InterestRateUpdated(uint256 indexed newInterestRate);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() Ownable(msg.sender) ERC20("RebaseToken", "RBT") {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function setInterestRate(uint256 _newInterestRate) external {
        if (_newInterestRate >= s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateUpdated(_newInterestRate);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function mint(address _to, uint256 _value) public onlyOwner {
        _mintAccruedInterest(_to);
        _mint(_to, _value);
    }

    function burn(address _from, uint256 _value) public onlyOwner {}

    function transfer(address _recipient, uint256 _value) public override onlyOwner returns (bool) {}

    function transferFrom(address _from, address _to, uint256 _value) public override onlyOwner returns (bool) {}

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * Updates the user's current interest rate, and keeps track of the timestamp of the change
     * @param _user The user that is interacting with the protocol
     */
    function _updateUserInterestRate(address _user) private {
        s_lastUpdatesByUser[_user] = block.timestamp;
        s_interestsRatesByUser[_user] = s_interestRate;
    }

    /**
     * @dev adds the accrued interest of the user to the principal balance. This function mints the user's accrued interest since they last transferred or bridged tokens.
     * @param _user the address of the user for which the interest is being minted
     *
     */
    function _mintAccruedInterest(address _user) private {
        uint256 principal = super.balanceOf(_user);
        uint256 balanceWithInterest = balanceOf(_user);
        uint256 amountToMint = balanceWithInterest - principal;
        
        _updateUserInterestRate(_user);
        _mint(_user, amountToMint);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW & PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @param _user The user whose accrued interest to calculate, since they last interacted with the protocol
     * @notice The interest value is calculated as a linear function of the elapsed time since the last update for the user, multiplied by the user's interest rate
     * @return The accumulated interest value since the last update relative to the user's principal
     */
    function _calculateUserInterestSinceLastUpdate(address _user) private view returns (uint256) {
        // It should never happen that a user has principal but has never had an update.
        // But let's assert that we have a last updated time just in case.
        if (s_lastUpdatesByUser[_user] == 0) {
            return 0;
        }

        return (s_interestsRatesByUser[_user] * (block.timestamp - s_lastUpdatesByUser[_user]));
    }

    /**
     * 
     * @param _user The user whose balance we want to check
     * @notice This returns the sum of the user's principal (tokens minted) and their accrued interest since the user last interacted with the protocol
     */
    function balanceOf(address _user) public view override returns(uint256) {
        uint256 principal = super.balanceOf(_user);
        uint256 interest = _calculateUserInterestSinceLastUpdate(_user);

        return principal + principal * interest / PRECISION_FACTOR;
    }
}