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
import {MasterCopyAuthority, MockAuthority} from "../MasterCopyAuthority.sol";


interface CheatCodes {
    function deal(address who, uint256 newBalance) external;
    function addr(uint256 privateKey) external returns (address);
    function warp(uint256) external;    // Set block.timestamp
}

contract OutOfOrderAuthority is Authority {
    function canCall(
        address,
        address,
        bytes4
    ) public pure override returns (bool) {
        revert("OUT_OF_ORDER");
    }
}


// This test is concerned primarily with the functionality of the factory 
// In particular the possibility of settng owners and authorities 
// In reality I suspect when one deploys the new bundles, the 

contract FactoryTest is Test {
    AccessToken accessToken;
    LicenseAuthority licenseAuthority;
    License license;
    MockERC20 token;
    Factory factory;

    MasterCopyAuthority masterCopyAuthority;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
  // HEVM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D

    address alice = cheats.addr(1);
    address bob = cheats.addr(2);
    address mch = address(0xBEEF);  // mch for "masterCopyHolder"

    function setUp() public {
    
      /// @notice You've got to deploy the three contracts all at once.
      factory = new Factory(address(this), Authority(address(0)));
      
      (license, licenseAuthority, accessToken) = factory.deployBundle("GEB", "GEB", "www.google.com");
      console.log("Set up is successful!");
  
    }

    
    function testOwners() public {
      // This test is to show that the owner of the License is whoever owning the factory that deployed the License 
      // To see this, we will set the _owner variable of the new factory to be alice 

        // This implies that for the license and the accessTokens to have functional authorities, 
        // We must setup the authorities post deployment 
      
      console.log("The address of this is", address(this));
      console.log("The address of the factory is", address(factory));
      console.log("The owner of the license is:", license.owner());
      console.log("The owner of the factory is:", factory.owner());
      console.log("The owner of the AccessToken is:", accessToken.owner());
      
      assertEq(license.owner(), factory.owner());
      assertEq(license.owner(), accessToken.owner());
      assertEq(accessToken.owner(), factory.owner());
      
      assertEq(accessToken.owner(), address(this));

    }
    
    function testSettingAuthorities() public {
        // At deployment, the authority is set to be Authority(address(0))
        console.log("license.authority address: ", address(license.authority()));
        assertEq(address(license.authority()), address(0));

        // That Authority contract has no canCall function, so all the authorities set there are impotent

        // as per our design stipulations, the authority over the license contract should be controlled by however controlling the masterCopy NFT
        
        masterCopyAuthority = new MasterCopyAuthority(mch);
        license.setAuthority(masterCopyAuthority);
        
        console.log("license.authority address: ", address(license.authority()));
        console.log("MasterCopyAuthority address:", address(masterCopyAuthority));
        
        // setting owner to be the zeroAddress to get rid of the possibility of calling requiresAuth functions being called by the owner 
        license.setOwner(address(0));
        
        // let us now pretend that we are masterCopyOwner
        
        hoax(mch);
        license.updateFlag();
    }

    function testAccessTokenAuthority() public {
        
        console.log("Address control the authority of accessToken:", address(accessToken.authority()));
        console.log("Address of licenseAuthority:", address(licenseAuthority));
        assertEq(address(accessToken.authority()), address(licenseAuthority));

    }

}


contract LicenseTest is Test {
    AccessToken accessToken;
    LicenseAuthority licenseAuthority;
    License license;
    MockERC20 token;
    Factory factory;

    MasterCopyAuthority masterCopyAuthority;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
  // HEVM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D

    address alice = cheats.addr(1);
    address bob = cheats.addr(2);
    address mch = address(0xBEEF);  // mch for "masterCopyHolder"

    function setUp() public {
    
        /// @notice You've got to deploy the three contracts all at once.
        factory = new Factory(address(this), Authority(address(0)));

        (license, licenseAuthority, accessToken) = factory.deployBundle("GEB", "GEB", "www.google.com");
        
        masterCopyAuthority = new MasterCopyAuthority(mch);
        license.setAuthority(masterCopyAuthority);
        
        console.log("license.authority address: ", address(license.authority()));
        console.log("MasterCopyAuthority address:", address(masterCopyAuthority));
        
        
        license.setOwner(mch);
        
        accessToken.setOwner(mch);

        console.log("Set up is successful!");
    }

    function testNothing() public {
        assertTrue(true);
    }

    function testOwnersAndAuthorities() public {
        assertEq(address(factory.owner()), address(this));
        assertEq(address(factory.authority()), address(0));

        assertEq(address(accessToken.owner()), mch);
        assertEq(address(accessToken.authority()), address(licenseAuthority));
        
        assertEq(address(license.owner()), mch);
        // assertEq(address(license.authority()), address(masterCopyAuthority));
        console.log("license.authority address: ", address(license.authority()));
        console.log("MasterCopyAuthority address:", address(masterCopyAuthority));

    }

    function testLicenseInitialising() public {
        
        startHoax(mch);
        console.log("before, maxSupply:", license.getMaxSupply());
        license.setMaxSupply(1000);
        console.log("after, maxSupply:", license.getMaxSupply());
        license.initialize();
        console.log("initialized:", license.getInitialized());

        console.log("time now is:", block.timestamp);
      
        license.setExpiryTime(1000000000);

        uint256 id = license.mint(7);
        console.log("number of licenses minted is:", id);
        console.log("the expiry date is now:", license.expiryDate(id-1));
        console.log("token 6 is expired:", license.isExpired(id-6));
        console.log("After minting, mch has license:",license.hasValidLicense(mch));
        // console.log(address(license));

        // console.log(license.isUserAuthorized(alice, 0xa0712d68));
        console.log("price used to be:", license.getPrice());
        license.setPrice(3);
        console.log("price is now:", license.getPrice());


    }
}

