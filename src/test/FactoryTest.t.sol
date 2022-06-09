// SPDX-License-Identifier: UNLICENSED

// The BundleTest is old. 
// This is the test that I am using to build
pragma solidity 0.8.11;

// import "ds-test/test.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./mocks/MockNFT.sol";


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
      assertEq(license.owner(), alice);
      assertEq(accessToken.owner(), alice);
      console.log("factory.owner():", factory.owner());
      console.log("Alice address:", alice);
      
    }


    function testLicenseAuthorities() public {
      hoax(alice);
      
      console.log("alice can call the license contract:", license.hasValidLicense(alice));
      
      // console.log("alice has license:", license.hasValidLicense(alice));
      // assertTrue(LicenseAuthority(address(license)).canCall(alice, address(license), 0xa0712d68));
      // license.setMaxSupply(100);
      assertEq(license.getMaxSupply(),100);
      console.log("license.getMaxSupply() is:", license.getMaxSupply());
      // license.initialize();
      // license.mint(1);

      // Functions of the AccessToken should be only by those with the LicenseToken
      assertTrue(Authority(address(accessToken)).canCall(alice, address(accessToken), ""));
    
    }


    // My hypothesis was that, right now, the owner and callables of the four contracts are as follows (RN) right now: 

    // +------------------+--------------------------------------------------------------------------+----------------------------------------------------------------------------------------+
    // |     Contract     |                                  Owner                                   |                                      Callable by?                                      |
    // +------------------+--------------------------------------------------------------------------+----------------------------------------------------------------------------------------+
    // | Factory          | ALICE (artist)                                                           | Anyone                                                                                 |
    // | License          | Auth(msg.sender).owner()= owner of the factory contract, therefore Alice | those with validLicenses of that license (this has not been verified in the tests yet) |
    // | LicenseAuthority | not owned                                                                | Anyone                                                                                 |
    // | AccessToken      | Auth(msg.sender).owner()= owner of the factory contract, therefore Alice | those with validLicenses of that license                                               |
    // +------------------+--------------------------------------------------------------------------+----------------------------------------------------------------------------------------+

    // In practice, we would like the structure to be (I) - ideal:

    //   +------------------+--------------------------------------+----------------------+
    //   |     Contract     |                Owner                 |     Callable by?     |
    //   +------------------+--------------------------------------+----------------------+
    //   | Factory          | Us                                   | Anyone               |
    //   | License          | Owner of MasterCopy (Artist - Alice) | Owner of MasterCopy  |
    //   | LicenseAuthority | Us / Not owned                       | Anyone               |
    //   | AccessToken      | Owner of MasterCopy (Artist - Alice) | validLicense holders |
    //   | MasterCopy       | Artist                               | Artist               |
    //   +------------------+--------------------------------------+----------------------+

// My initial plan was to verify that these contracts are indeed behaving like (RN), and then I shall modify them to become like (I)

// Two observations here: 

// (1) the LicenseAuthority seems to be controlling the wrong contract
// The license contract requiresAuth modifier calls the canCall function of the LicenseAuthority to check if someone could call functions of the license contract
// the LicenseAuthority then calls the license contract to see if the user in question has a validLicense 
// This appears wrong to me. validLicense holders should have rights to call the functions of the AccessToken (to mint AccessTokens), not to call the functions of the license itself
// That right is reserved for the MasterCopy holder. 

// (2) To test my hypothesis as to whether the contracts are really behaving like (RN), we need to check who's the contracts callable by. 
// As per the contract set up, it is not possible to call the contracts 
// For Alice to call the License contract, she needs to have a validLicense
// But for her to have a valid license, she needs to be minted one
// But the mint function is guarded by the requiresAuth modifier - so she can't call the function

// I suppose this can be done by calling the setAuthority() function on the license contract, but I haven't tried that out yet. 

// Final remark, aside from (1), (correct me if my interpretation is wrong) - the complicated authorities can be set straight not by rewriting the contracts but by calling the apppropriate setAuthority() functions. 



  

          
}
