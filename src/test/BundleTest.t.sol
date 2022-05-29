// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

// import "ds-test/test.sol";
import "forge-std/Test.sol";

import "./mocks/MockNFT.sol";
import "../Mover.sol";

import {AccessToken} from "../AccessToken.sol";
import {LicenseAuthority} from "../AuthorityModule.sol";
import {License} from "../License.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {Factory} from "../Factory.sol";
import {Authority} from "solmate/auth/Auth.sol";

contract BundleTest is Test {
    AccessToken accessToken;
    LicenseAuthority licenseAuthority;
    License license;
    MockERC20 token;
    Factory factory;


  

    function setUp() public {
      token = new MockERC20("Mock Token", "TKN", 18);
      // license = new License("GEB", "GEB", "www.google.com"); 
      (license, licenseAuthority, accessToken) = new Factory(address(this), Authority(address(0))).deployBundle("GEB", "GEB", "www.google.com");
      // license             = new License("GEB", "GEB", "www.google.com");
      // licenseAuthority    = new LicenseAuthority(license);
      // accessToken         = new AccessToken("GEB", "GEB", "www.google.com", license);
      // authority = new LicenseAuthority(license);
      // accessToken = new AccessToken("GEB", "GEB", "", 20 days, 100, authority);
    }

    function testExample() public {
        assertTrue(true);
    }
}
