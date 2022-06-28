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
      startHoax(alice);   // alice is the author 
      masterNFT = new MasterNFT(name, symbol, baseURI);
      assertTrue(address(masterNFT).code.length > 0);
    }

    function testDeployMasterNFTAuthorityModule() public {
      masterNFT = new MasterNFT(name, symbol, baseURI);
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      assertTrue(address(masterNFTAuthorityModule).code.length > 0);
    }

    function testDeployLicense() public {
      masterNFT = new MasterNFT(name, symbol, baseURI);
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule, masterNFT);
      assertTrue(address(license).code.length > 0);
    }

    function testDeployAuthorityModule() public {
      masterNFT = new MasterNFT(name, symbol, baseURI);
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule, masterNFT);
      assertTrue(address(license).code.length > 0);
      authorityModule = factory.deployAuthorityModule(masterNFT, license);
      assertTrue(address(authorityModule).code.length > 0); 
    }

    function testDeployAccessToken() public {
      masterNFT = new MasterNFT(name, symbol, baseURI);
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule, masterNFT);
      assertTrue(address(license).code.length > 0);
      authorityModule = factory.deployAuthorityModule(masterNFT, license);
      assertTrue(address(authorityModule).code.length > 0); 
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule, masterNFT);
    }


    function testFalseDeployContracts() public {
      masterNFT = new MasterNFT(name, symbol, baseURI);
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule, masterNFT);
      authorityModule = factory.deployAuthorityModule(masterNFT, license);
      assertFalse(factory.areContractsDeployed(license, authorityModule, AccessToken(payable(address(0xBEEF)))));
    }

    

    function testSetAuthorityModuleLicenseToken() public {
      masterNFT = new MasterNFT(name, symbol, baseURI);
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule, masterNFT);
      assertTrue(address(license).code.length > 0);
      authorityModule = factory.deployAuthorityModule(masterNFT, license);
      assertTrue(address(authorityModule).code.length > 0); 
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule, masterNFT);
      assertEq(authorityModule.owner(), address(factory));
      factory.setAuthorityModuleAccessToken(authorityModule, accessToken);
      
    }


    //   // +--------------------------+----------------------+--------------------------+--------------------------+------------------+------------------+
    //   // |         Contract         |        Owner         |   Authority at Set Up    |   Authority Should be    |  Callable by?    | Deployment Order |
    //   // +--------------------------+----------------------+--------------------------+--------------------------+------------------+------------------+
    //   // | Factory                  | msg.sender (us)      | address(0)               | address(0)               | anyone           |                1 |
    //   // | MasterNFT                | msg.sender (us)      | n/a (Owned)              | n/a(Owned)               | owner            |                2 |
    //   // | MasterNFTAuthorityModule | msg.sender (Factory) | n/a (not Auth)           | n/a (not Auth)           | anyone           |                3 |
    //   // | License                  | msg.sender (us)       | masterNFTAuthorityModule | masterNFTAuthorityModule | MasterNFT holder |                4 |
    //   // | AuthorityModule          | msg.sender (Factory) | n/a (not Auth)           | n/a (not Auth)           | anyone           |                5 |
    //   // | AccessToken              | msg.sender (Factory) | AuthorityModule          | AuthorityModule          | License holders  |                6 |
    //   // +--------------------------+----------------------+--------------------------+--------------------------+------------------+------------------+
    //   // 

    function testOwners() public {
      hoax(alice);
      masterNFT = new MasterNFT(name, symbol, baseURI);                             // Whoever calls the MasterNFT constructor is the owner of the contract. In this case it is Alice.
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);              
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule, masterNFT);  // Alice is supplied as an argument 
      authorityModule = factory.deployAuthorityModule(masterNFT, license);
      accessToken = factory.deployAccessToken(name, symbol, baseURI, accessTokenExpiryTime, accessTokenMaxSupply, accessTokenPrice, authorityModule, license, masterNFT);

      assertEq(factory.owner(), address(this));
      assertEq(masterNFT.owner(), alice);
      assertEq(masterNFTAuthorityModule.owner(), address(factory));
      assertEq(license.owner(), address(factory));
      assertEq(authorityModule.owner(), address(factory));
      assertEq(accessToken.owner(), address(factory));
      
      
      console.log("address of this:", address(this));
      console.log("factory address:", address(factory));
      console.log("masterNFT address:", address(masterNFT));
      // 
      console.log("license address:", address(license));
      console.log("authorityModule address:", address(authorityModule));
      console.log("accessToken address:", address(accessToken));
// 
// 
      console.log("owner of factory:", factory.owner());
      console.log("owner of masterNFT:", masterNFT.owner());
      console.log("owner of masterNFTAuthorityModule:", masterNFTAuthorityModule.owner());
      // 
      console.log("owner of license:", license.owner());
      console.log("owner of authorityModule:", authorityModule.owner());
      console.log("owner of accessToken:", accessToken.owner()); 
    }

    function testAuthorities() public {
      
      masterNFT = new MasterNFT(name, symbol, baseURI);
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule, masterNFT);
      authorityModule = factory.deployAuthorityModule(masterNFT, license);
      accessToken = factory.deployAccessToken(name, symbol, baseURI, accessTokenExpiryTime, accessTokenMaxSupply, accessTokenPrice, authorityModule, license, masterNFT);
      factory.setMasterNFTAuthorityModuleLicense(masterNFTAuthorityModule, license);
      factory.setAuthorityModuleAccessToken(authorityModule, accessToken);
      
      assertEq(address(license.authority()), address(masterNFTAuthorityModule));
      assertEq(address(accessToken.authority()), address(authorityModule));

      assertEq(address(masterNFTAuthorityModule.masterNFT()), address(masterNFT));
      assertEq(masterNFTAuthorityModule.license(), address(license));

      assertEq(address(authorityModule.license()), address(license));
      assertEq(authorityModule.accessToken(), address(accessToken));
      // 
      assertEq(address(accessToken.license()), address(license));
    }

}