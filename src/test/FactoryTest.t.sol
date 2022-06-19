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
import {MasterNFT} from "../MasterNFT.sol";
import {MasterNFTAuthorityModule} from "../MasterNFTAuthorityModule.sol";

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
    MasterNFT masterNFT;
    MasterNFTAuthorityModule masterNFTAuthorityModule;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
//   HEVM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    
    address alice = address(0xAAAA); // Alice is the author
    address bob = cheats.addr(2);
    address carol = cheats.addr(3);

    


    string name = "GEB";
    string symbol = "GEB"; 
    string baseURI = "geb.com";
    
    uint256 licenseExpiryTime =  10 days;
    uint256 licenseMaxSupply = 10; 
    uint256 licensePrice = 0.1 ether;


    uint256 accessTokenExpiryTime = 100 days ;
    uint256 accessTokenMaxSupply = 100;
    uint256 accessTokenPrice =  0.01 ether;

    function setUp() public {
      factory = new Factory(address(this), Authority(address(0)));
    }
    
    function testDeployMasterNFT() public {
      masterNFT = factory.deployMasterNFT(name, symbol, baseURI);
      assertTrue(address(masterNFT).code.length > 0);
    }

    function testDeployMasterAuthorityModule() public {
      masterNFT = factory.deployMasterNFT(name, symbol, baseURI);
      assertTrue(address(masterNFT).code.length > 0);
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      assertTrue(address(masterNFTAuthorityModule).code.length > 0);
    }

    function testDeployLicense() public {
      masterNFT = factory.deployMasterNFT(name, symbol, baseURI);
      assertTrue(address(masterNFT).code.length > 0);
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      assertTrue(address(masterNFTAuthorityModule).code.length > 0);
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule);
      assertTrue(address(license).code.length > 0);
    }

    function testDeployAuthorityModule() public {
      masterNFT = factory.deployMasterNFT(name, symbol, baseURI);
      assertTrue(address(masterNFT).code.length > 0);
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      assertTrue(address(masterNFTAuthorityModule).code.length > 0);
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule);
      assertTrue(address(license).code.length > 0);
      authorityModule = factory.deployAuthorityModule(license);
      assertTrue(address(authorityModule).code.length > 0); 
    }

    function testDeployAccessToken() public {
      masterNFT = factory.deployMasterNFT(name, symbol, baseURI);
      assertTrue(address(masterNFT).code.length > 0);
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      assertTrue(address(masterNFTAuthorityModule).code.length > 0);
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule);
      assertTrue(address(license).code.length > 0);
      authorityModule = factory.deployAuthorityModule(license);
      assertTrue(address(authorityModule).code.length > 0); 
      accessToken = factory.deployAccessToken(name, symbol, baseURI, accessTokenExpiryTime, accessTokenMaxSupply, accessTokenPrice, authorityModule);
    }



    // function testDeploy2Contracts() public {
    //   masterNFT = factory
    //   license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice);
    //   authorityModule = factory.deployAuthorityModule(license);
    // }

    // function testDeployContracts() public {
    //   license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice);
    //   authorityModule = factory.deployAuthorityModule(license);
    //   accessToken = factory.deployAccessToken(name, symbol, baseURI, 100 days, 100, 0.01 ether, authorityModule);

    //   assertTrue(factory.areContractsDeployed(license, authorityModule, accessToken));
    // }

    // function testFalseDeployContracts() public {
    //   license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice);
    //   authorityModule = factory.deployAuthorityModule(license);

    //   assertFalse(factory.areContractsDeployed(license, authorityModule, AccessToken(payable(address(0xBEEF)))));
    // }



      // +--------------------------+----------------------+--------------------------+--------------------------+------------------+------------------+
      // |         Contract         |        Owner         |   Authority at Set Up    |   Authority Should be    |  Callable by?    | Deployment Order |
      // +--------------------------+----------------------+--------------------------+--------------------------+------------------+------------------+
      // | Factory                  | msg.sender (us)      | address(0)               | address(0)               | anyone           |                1 |
      // | MasterNFT                | msg.sender (Factory) | n/a (Owned)              | n/a(Owned)               | owner            |                2 |
      // | MasterNFTAuthorityModule | msg.sender (Factory) | n/a (not Auth)           | n/a (not Auth)           | anyone           |                3 |
      // | License                  | msg.sender (Factory) | masterNFTAuthorityModule | masterNFTAuthorityModule | MasterNFT holder |                4 |
      // | AuthorityModule          | msg.sender (Factory) | n/a (not Auth)           | n/a (not Auth)           | anyone           |                5 |
      // | AccessToken              | msg.sender (Factory) | AuthorityModule          | AuthorityModule          | License holders  |                6 |
      // +--------------------------+----------------------+--------------------------+--------------------------+------------------+------------------+
      // 

    function testOwners() public {
      masterNFT = factory.deployMasterNFT(name, symbol, baseURI);
      assertTrue(address(masterNFT).code.length > 0);
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      assertTrue(address(masterNFTAuthorityModule).code.length > 0);
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule);
      assertTrue(address(license).code.length > 0);
      authorityModule = factory.deployAuthorityModule(license);
      assertTrue(address(authorityModule).code.length > 0); 
      accessToken = factory.deployAccessToken(name, symbol, baseURI, accessTokenExpiryTime, accessTokenMaxSupply, accessTokenPrice, authorityModule);

      assertEq(factory.owner(), address(this));
      assertEq(masterNFT.owner(), address(factory));
      assertEq(masterNFTAuthorityModule.owner(), address(factory));
      assertEq(license.owner(), address(factory));
      assertEq(authorityModule.owner(), address(factory));
      assertEq(accessToken.owner(), address(factory));
      
      console.log("address of this:", address(this));
      console.log("factory address:", address(factory));
      console.log("masterNFT address:", address(masterNFT));
      console.log("masterNFTAuthorityModule address:", address(masterNFTAuthorityModule));
      console.log("license address:", address(license));
      console.log("authorityModule address:", address(authorityModule));
      console.log("accessToken address:", address(accessToken));


      console.log("owner of factory:", factory.owner());
      console.log("owner of masterNFT:", masterNFT.owner());
      console.log("owner of masterNFTAuthorityModule:", masterNFTAuthorityModule.owner());
      console.log("owner of license:", license.owner());
      console.log("owner of authorityModule:", authorityModule.owner());
      console.log("owner of accessToken:", accessToken.owner()); 
    }

    function testAuthorities() public {
      masterNFT = factory.deployMasterNFT(name, symbol, baseURI);
      assertTrue(address(masterNFT).code.length > 0);
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      assertTrue(address(masterNFTAuthorityModule).code.length > 0);
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule);
      assertTrue(address(license).code.length > 0);
      authorityModule = factory.deployAuthorityModule(license);
      assertTrue(address(authorityModule).code.length > 0); 
      accessToken = factory.deployAccessToken(name, symbol, baseURI, accessTokenExpiryTime, accessTokenMaxSupply, accessTokenPrice, authorityModule);

      assertEq(address(license.authority()), address(masterNFTAuthorityModule));
      assertEq(address(accessToken.authority()), address(authorityModule));
    }

}
