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


contract RebaseToken is ERC20, Ownable, AccessControl {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function mint(address _to, uint256 _value, uint256 _userInterestRate) public {}

    function burn(address _from, uint256 _value) public {}

    function transfer(address _recipient, uint256 _value) public override returns (bool) {}

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {}

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                        VIEW & PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _calculateUserInterestSinceLastUpdate(address _user, uint256 principal) private view returns (uint256) {
        // It should never happen that a user has principal but has never had an update.
        // But let's assert that we have a last updated time just in case.
        if (s_lastUpdatesByUser[_user] == 0) {
            return 0;
        }

        return principal * (s_interestsRatesByUser[_user] * (block.timestamp - s_lastUpdatesByUser[_user])) / PRECISION_FACTOR;
    }

    /**
     * 
     * @param _user The user whose balance we want to check
     * @notice This returns the sum of the user's principal (tokens minted) and their accrued interest since the user last interacted with the protocol
     */
    function balanceOf(address _user) public view override returns(uint256) {
        uint256 principal = super.balanceOf(_user);
        uint256 interest = _calculateUserInterestSinceLastUpdate(_user, principal);

        return principal + interest;
    }
}