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
    Factory factory;

    function setUp() public {
      factory = new Factory(address(this), Authority(address(0)));
    }

    function testDeployContracts() public {
      license = factory.deployLicense("GEB", "GEB", "geb.com", 10 days, 10, 0.1 ether);  
      authorityModule = factory.deployAuthorityModule();
      accessToken = factory.deployAccessToken("GEB", "GEB", "geb.com", 100 days, 100, 0.01 ether);  

      assertTrue(factory.areContractsDeployed(license, authorityModule, accessToken));
    }

    function testFalseDeployContracts() public {
      license = factory.deployLicense("GEB", "GEB", "geb.com", 10 days, 10, 0.1 ether);  
      authorityModule = factory.deployAuthorityModule();

      assertFalse(factory.areContractsDeployed(license, authorityModule, AccessToken(payable(address(0xBEEF)))));
    }
}
