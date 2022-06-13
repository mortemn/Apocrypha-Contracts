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
import {AuthorityModule} from "../AuthorityModule.sol";
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
    AuthorityModule authorityModule;
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
      (license, authorityModule) = factory.deployLicenseBundle("GEB", "GEB", "www.google.com", 10 days, 100, 1 ether, 69);
      console.log("Set up is successful!");
    }

    function testOwners() public {
    }


    function testLicenseAuthorities() public {
    }


    // My hypothesis was that, right now, the owner and callables of the four contracts are as follows (RN) right now: 

    // +------------------+--------------------------------------------------------------------------+----------------------------------------------------------------------------------------+
    // |     Contract     |                                  Owner                                   |                                      Callable by?                                      |
    // +------------------+--------------------------------------------------------------------------+----------------------------------------------------------------------------------------+
    // | Factory          | ALICE (artist)                                                           | Anyone                                                                                 |
    // | License          | Auth(msg.sender).owner()= owner of the factory contract, therefore Alice | those with validLicenses of that license (this has not been verified in the tests yet) |
    // | AuthorityModule | not owned                                                                | Anyone                                                                                 |
    // | AccessToken      | Auth(msg.sender).owner()= owner of the factory contract, therefore Alice | those with validLicenses of that license                                               |
    // +------------------+--------------------------------------------------------------------------+----------------------------------------------------------------------------------------+

    // In practice, we would like the structure to be (I) - ideal:

    //   +------------------+--------------------------------------+----------------------+
    //   |     Contract     |                Owner                 |     Callable by?     |
    //   +------------------+--------------------------------------+----------------------+
    //   | Factory          | Us                                   | Anyone               |
    //   | License          | Owner of MasterCopy (Artist - Alice) | Owner of MasterCopy  |
    //   | AuthorityModule | Us / Not owned                       | Anyone               |
    //   | AccessToken      | Owner of MasterCopy (Artist - Alice) | validLicense holders |
    //   | MasterCopy       | Artist                               | Artist               |
    //   +------------------+--------------------------------------+----------------------+

// My initial plan was to verify that these contracts are indeed behaving like (RN), and then I shall modify them to become like (I)

// Two observations here: 

// (1) the AuthorityModule seems to be controlling the wrong contract
// The license contract requiresAuth modifier calls the canCall function of the AuthorityModule to check if someone could call functions of the license contract
// the AuthorityModule then calls the license contract to see if the user in question has a validLicense 
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
