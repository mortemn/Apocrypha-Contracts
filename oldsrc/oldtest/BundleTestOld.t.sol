// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.11;

// // import "ds-test/test.sol";
// import "forge-std/Test.sol";
// import "forge-std/console.sol";

// import "./mocks/MockNFT.sol";
// import "../Mover.sol";

// import {Auth} from "solmate/auth/Auth.sol";
// import {AccessToken} from "../AccessToken.sol";
// import {LicenseAuthority} from "../AuthorityModule.sol";
// import {License} from "../License.sol";
// import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
// import {Factory} from "../Factory.sol";
// import {Authority} from "solmate/auth/Auth.sol";

// interface CheatCodes {
//     function deal(address who, uint256 newBalance) external;
//     function addr(uint256 privateKey) external returns (address);
//     function warp(uint256) external;    // Set block.timestamp
// }


// contract BundleTest is Test {
//     AccessToken accessToken;
//     LicenseAuthority licenseAuthority;
//     License license;
//     MockERC20 token;
//     Factory factory;

//     CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
//   // HEVM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D

//     address alice = cheats.addr(1);
//     address bob = cheats.addr(2);



//     function setUp() public {
//       token = new MockERC20("Mock Token", "TKN", 18);
//       // license = new License("GEB", "GEB", "www.google.com"); 
//       // hoax(alice);
//       /// @notice You've got to deploy the three contracts all at once.
//       // (license, licenseAuthority, accessToken) = new Factory(address(this), Authority(alice)).deployBundle("GEB", "GEB", "www.google.com");
      
//       (license, licenseAuthority, accessToken) = new Factory(
//                                                             address(alice),
//                                                             Authority(alice)
//                                                             ).deployBundle("GEB", "GEB", "www.google.com");
//       console.log("set up is successful!");
//     }


//     // In sense, right now, the owner and callables of the four contracts are: 
//                         // owner                                                                      callable by?
//     // Factory          : ALICE                                                                       ANYONE
//     // License          : Auth(msg.sender).owner()= owner of the factory contract, therefore Alice    those with validLicenses of that license 
//     // LicenseAuthority : not owned                                                                   ANYONE 
//     // AccessToken      : Auth(msg.sender).owner()= owner of the factory contract, therefore Alice    those with validLicenses of that license 

//     function testFactoryOwner() public {
//       console.log("Owner of this factory contract is:", address(this).owner());
//     }

//     function testOwners() public {
//       console.log("License's owner is:", license.owner());
//       console.log("Alice's address:", alice);
//       assertEq(license.owner(), alice);
//       // console.log(ownerOf(licenseAuthority));
//       // console.log(accessToken.owner());
      
      
      
      
//     }

//     function testCanCall() public {
//       hoax(alice);
      
      
      
//       console.log("the balance of alice is", license.balanceOf(alice));
//       console.log("the license is initialised:", license.isInitialized());
//       hoax(alice);
//       // license.initialize();
//       console.log("the license is initialised:", license.isInitialized());
//       console.log("the owner of license is:", license.owner());
//       console.log("and the address of alice is:", address(alice));
//       // license.setPrice(1);
//       // license.setExpiryTime(1000000000);
//       // license.setMaxSupply(100);


//       // license.isOwner(alice);
//       license.mint(1);

//       assertTrue(licenseAuthority.canCall(alice, address(license), 0xa0712d68));
//       console.log("Alice can call:", licenseAuthority.canCall(alice, address(license), 0xa0712d68));
//       assertTrue(licenseAuthority.canCall(bob, address(license), 0xa0712d68));
//       console.log("Bob can call:", licenseAuthority.canCall(bob, address(license), 0xa0712d68));
//       // assertTrue(license.hasValidLicense(alice));
//     }

//     function testExample() public {
//         assertTrue(true);
//     }


// }
