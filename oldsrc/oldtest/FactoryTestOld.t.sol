// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

// import "ds-test/test.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./mocks/MockNFT.sol";
import "../Mover.sol";

import {Auth} from "solmate/auth/Auth.sol";
import {AccessToken} from "../AccessToken.sol";
import {LicenseAuthority} from "../AuthorityModule.sol";
import {License} from "../License.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {Factory} from "../Factory.sol";
import {Authority} from "solmate/auth/Auth.sol";

interface CheatCodes {
    function deal(address who, uint256 newBalance) external;
    function addr(uint256 privateKey) external returns (address);
    function warp(uint256) external;    // Set block.timestamp
}


contract FactoryTest is Test {
    AccessToken accessToken;
    LicenseAuthority licenseAuthority;
    License license;
    MockERC20 token;
    Factory factory;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
  // HEVM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D

    address alice = cheats.addr(1);
    address bob = cheats.addr(2);

    function setUp() public {
      
      // license = new License("GEB", "GEB", "www.google.com"); 
      // hoax(alice);
      /// @notice You've got to deploy the three contracts all at once.
      factory = new Factory(address(alice), Authority(alice));
      (license, licenseAuthority, accessToken) = factory.deployBundle("GEB", "GEB", "www.google.com");
      console.log("Set up is successful!");
  
    }

    function testOwners() public {
      // This test is to show that the owner of the License is whoever owning the factory that deployed the License 
      // To see this, we will set the _owner variable of the new factory to be alice 
      // First deployment: from "this" address
      // The owner of the license contract is the 
      assertEq(license.owner(), factory.owner());
      console.log("license.owner():", license.owner());
      // And the owner of the AccessToken is also the owner of the factory contract
      assertEq(accessToken.owner(), accessToken.owner());
      console.log("accessToken.owner():", accessToken.owner());
      // And the owner of the factory is alice 
      assertEq(factory.owner(), alice);
      console.log("factory.owner():", factory.owner());
      console.log("Alice address:", alice);
      
    }

    function testLicenseAuthorities() public {
      hoax(alice);
      console.log("alice has license:", license.hasValidLicense(alice));
      assertTrue(Authority(address(license)).canCall(alice, address(license), 0xa0712d68));
      // license.setMaxSupply(100);
      assertEq(license.getMaxSupply(),100);
      console.log("license.getMaxSupply() is:", license.getMaxSupply());
      // license.initialize();
      // license.mint(1);

      // Functions of the AccessToken should be only by those with the LicenseToken
      assertTrue(Authority(address(accessToken)).canCall(alice, address(accessToken), ""));
    
    }


    // In sense, right now, the owner and callables of the four contracts are: 
                        // owner                                                                      callable by?
    // Factory          : ALICE                                                                       ANYONE
    // License          : Auth(msg.sender).owner()= owner of the factory contract, therefore Alice    those with validLicenses of that license 
    // LicenseAuthority : not owned                                                                   ANYONE 
    // AccessToken      : Auth(msg.sender).owner()= owner of the factory contract, therefore Alice    those with validLicenses of that license 

          
}
