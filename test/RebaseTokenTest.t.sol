// SDPX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";

contract RebaseTokenTest is Test {
    error RebaseTokenTest__FailedToFundVaultRewards();

    RebaseToken private token;
    Vault private vault;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        vm.startPrank(owner);
        token = new RebaseToken();
        
        vault = new Vault(IRebaseToken(address(token)));
        token.grantMintAndBurnRole(address(vault));
        (bool success, ) = payable(address(vault)).call{value: 1 ether}("");
        if (!success) {
            revert RebaseTokenTest__FailedToFundVaultRewards();
        }

        vm.stopPrank();
    }
}