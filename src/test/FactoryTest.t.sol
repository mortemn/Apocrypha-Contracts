// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

// import "ds-test/test.sol";
// import "forge-std/Test.sol";
// import "forge-std/console.sol";

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import "./mocks/MockNFT.sol";


import {Auth} from "solmate/auth/Auth.sol";
import {AccessToken} from "../AccessToken.sol";
import {AuthorityModule} from "../AuthorityModule.sol";
import {License} from "../License.sol";
import {Factory} from "../Factory.sol";
import {Authority} from "solmate/auth/Auth.sol";

// interface CheatCodes {
//     function deal(address who, uint256 newBalance) external;
//     function addr(uint256 privateKey) external returns (address);
//     function warp(uint256) external;    // Set block.timestamp
// }

contract FactoryTest is DSTestPlus {
    AccessToken accessToken;
    AuthorityModule authorityModule;
    License license;
    MockERC20 token;
    Factory factory;

    function setUp() public {
      factory = new Factory(address(this), Authority(address(0)));
    }

    function testOwners() public {
    }


    function testLicenseAuthorities() public {
    }

}
