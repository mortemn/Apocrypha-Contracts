// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "ds-test/test.sol";

import {AccessToken} from "../AccessToken.sol";
import {LicenseAuthority} from "../AuthorityModule.sol";
import {License} from "../License.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

contract ContractTest is DSTest {
    AccessToken accessToken;
    LicenseAuthority authority;
    License license;
    MockERC20 token;

    function setUp() public {
      token = new MockERC20("Mock Token", "TKN", 18);
      license = new License("GEB", "GEB", "www.google.com"); 
      // authority = new LicenseAuthority(license);
      // accessToken = new AccessToken("GEB", "GEB", "", 20 days, 100, authority);
    }

    function testExample() public {
        assertTrue(true);
    }
}
