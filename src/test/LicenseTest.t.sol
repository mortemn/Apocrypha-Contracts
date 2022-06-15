// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

import {Auth} from "solmate/auth/Auth.sol";
import {AccessToken} from "../AccessToken.sol";
import {AuthorityModule} from "../AuthorityModule.sol";
import {License} from "../License.sol";
import {Factory} from "../Factory.sol";
import {Authority} from "solmate/auth/Auth.sol";

contract FactoryTest is DSTestPlus {
    AccessToken accessToken;
    AuthorityModule authorityModule;
    License license;
    Factory factory;

    function setUp() public {
      factory = new Factory(address(this), Authority(address(0)));
      license = factory.deployLicense("GEB", "GEB", "geb.com", 10 days, 10, 0.1 ether);
      authorityModule = factory.deployAuthorityModule(license);
      accessToken = factory.deployAccessToken("GEB", "GEB", "geb.com", 100 days, 100, 0.01 ether, authorityModule);
    }
}
