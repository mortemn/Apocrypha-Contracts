// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "ds-test/test.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
// 
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

import {Auth} from "solmate/auth/Auth.sol";
import {AccessToken} from "../AccessToken.sol";
import {AuthorityModule} from "../AuthorityModule.sol";
import {License} from "../License.sol";
import {Factory} from "../Factory.sol";
import {Authority} from "solmate/auth/Auth.sol";

interface CheatCodes {
    function deal(address who, uint256 newBalance) external;
    function addr(uint256 privateKey) external returns (address);
    function warp(uint256) external;    // Set block.timestamp
}

contract FactoryTest is Test {
    AccessToken accessToken;
    AuthorityModule authorityModule;
    License license;
    Factory factory;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
//   HEVM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    
    address alice = address(0xAAAA); // Alice is the author
    address bob = cheats.addr(2);
    address carol = cheats.addr(3);


    function setUp() public {
      factory = new Factory(address(this), Authority(address(0)));
    }

    function testDeploy2Contracts() public {
      license = factory.deployLicense("GEB", "GEB", "geb.com", 10 days, 10, 0.1 ether);
      authorityModule = factory.deployAuthorityModule(license);
    }

    function testDeployContracts() public {
      license = factory.deployLicense("GEB", "GEB", "geb.com", 10 days, 10, 0.1 ether);
      authorityModule = factory.deployAuthorityModule(license);
      accessToken = factory.deployAccessToken("GEB", "GEB", "geb.com", 100 days, 100, 0.01 ether, authorityModule);

      assertTrue(factory.areContractsDeployed(license, authorityModule, accessToken));
    }

    function testFalseDeployContracts() public {
      license = factory.deployLicense("GEB", "GEB", "geb.com", 10 days, 10, 0.1 ether);
      authorityModule = factory.deployAuthorityModule(license);

      assertFalse(factory.areContractsDeployed(license, authorityModule, AccessToken(payable(address(0xBEEF)))));
    }

    function testOwners() public {
        hoax(alice);
        license = factory.deployLicense("GEB", "GEB", "geb.com", 10 days, 10, 0.1 ether);
        authorityModule = factory.deployAuthorityModule(license);
        accessToken = factory.deployAccessToken("GEB", "GEB", "geb.com", 100 days, 100, 0.01 ether, authorityModule);

        assertEq(factory.owner(), address(this));
        assertEq(license.owner(), alice);
        assertEq(accessToken.owner(), address(this));
        
        console.log("owner of factory:", factory.owner());
        console.log("owner of license:", license.owner());
        console.log("owner of accessToken:", accessToken.owner());
        console.log("address of license:", address(license));
        console.log("address of factory:", address(factory));
        console.log("address of alice:", alice);
        console.log("address of this:", address(this));
  
    }

    function testAuthorities() public {
        hoax(alice);
        license = factory.deployLicense("GEB", "GEB", "geb.com", 10 days, 10, 0.1 ether);
        authorityModule = factory.deployAuthorityModule(license);
        accessToken = factory.deployAccessToken("GEB", "GEB", "geb.com", 100 days, 100, 0.01 ether, authorityModule);
        assertEq(address(factory.authority()), address(0));
        assertEq(address(accessToken.authority()), address(authorityModule));   
    }
}
