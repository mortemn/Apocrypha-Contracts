// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "ds-test/test.sol";
import "forge-std/Vm.sol";
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


interface CheatCodes {
    function deal(address who, uint256 newBalance) external;
    function addr(uint256 privateKey) external returns (address);
    function warp(uint256) external;    // Set block.timestamp
}

contract LicenseTest is Test {
    AccessToken accessToken;
    AuthorityModule authorityModule;
    License license;
    Factory factory;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    // address HEVM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
    
    address alice = address(0xAAAA); // Alice is the author
    address bob = cheats.addr(2);
    address carol = cheats.addr(3);

    string licenseName = "GEB";
    string licenseSymbol = "GEB"; 
    string licenseBaseURI = "geb.com";
    uint256 licenseExpiryTime =  10 days;
    uint256 licenseMaxSupply = 10; 
    uint256 licensePrice = 0.1 ether;


    string accessTokenName = "GEB"; 
    string accessTokenSymbol = "GEB";
    string accessTokenBaseURI = "geb.com";
    uint256 accessTokenExpiryTime = 100 days ;
    uint256 accessTokenMaxSupply = 100;
    uint256 accessTokenPrice =  0.01 ether;
    

    function setUp() public {
      factory = new Factory(address(this), Authority(address(0)));
      hoax(alice);
      license = factory.deployLicense(licenseName, licenseSymbol, licenseBaseURI, licenseExpiryTime, licenseMaxSupply, licensePrice);
      authorityModule = factory.deployAuthorityModule(license);
      accessToken = factory.deployAccessToken(accessTokenName, accessTokenSymbol, accessTokenBaseURI, accessTokenExpiryTime, accessTokenMaxSupply, accessTokenPrice, authorityModule);
      authorityModule.setAccessTokenAddress(address(accessToken));
    }

    function testAuthorCanMintLicense() public {
        // alice is the author
        // She ownes the license contract 
        assertEq(license.owner(), alice);
        // she can mint licenses 
        startHoax(alice);
        license.mint(1);
        assertEq(license.ownerOf(1), alice);    
        license.mint(1);
        assertEq(license.ownerOf(2), alice);    

    }

    function testAuthorCanSetExpiryTime() public {
        
        startHoax(alice);                               // Calling License contract as Author Alice.
        console.log(block.timestamp);                   // The time now is 1.
        uint256 expiryTime = licenseExpiryTime;                     
        license.setExpiryTime(expiryTime);              // Setting the Expiry Time.
        license.mint(1);                                // Minting 3 tokens.
        assertTrue(!license.isExpired(1));              // Not expired.
        cheats.warp(block.timestamp+expiryTime);        // Changing the time to time after the expirytime.       
        console.log(block.timestamp);                   // Time now is 10001.
        assertTrue(license.isExpired(1));               // Expired.
    }


    function testAuthorCanSetMaxSupply() public {

    }

    function testAuthorCanSetPrice() public {
        
    }

    function testExpiredLicenseHoldersCannotCallAccessTokenFunctions() public {
        
        
        console.log("time is right now:", block.timestamp);                   // The time now is 1.
        uint256 expiryTime = licenseExpiryTime;                     
        hoax(alice);
        // license.setExpiryTime(expiryTime);                              
        console.log("expiryDate:",license.getExpiryDate(1));          // returns 0 because token not minted yet 
        hoax(alice);
        license.mint(1);
        uint256 expirydate = license.getExpiryDate(1);
        console.log("expiryDate:",expirydate);
        hoax(alice);
        license.safeTransferFrom(alice, bob, 1);
        assertTrue(license.hasValidLicense(bob));
        assertEq(license.getExpiryDate(1), expiryTime + block.timestamp);
        hoax(bob);
        assertTrue(accessToken.changeFlag());
        cheats.warp(block.timestamp + expiryTime);
        hoax(bob);
        vm.expectRevert(abi.encodePacked("UNAUTHORIZED"));
        accessToken.changeFlag();
        
    }


    function testSettingExpiryTimeAfterMint() public {
        uint256 expiryTime = 2;   
        startHoax(alice);
        
        license.mint(1);
        console.log("expiry for token 1:", license.getExpiryDate(1));    // 8640000001 (10000 days)
        license.setExpiryTime(expiryTime); 
        console.log("expiry for token 1:", license.getExpiryDate(1));    // 8640000001 (10000 days) 
        
        // Once you've minted a license, you cannot change the expiry date of that license by changing the global expiry time

        license.mint(1);
        
        console.log("expiry for token 2:", license.getExpiryDate(2));    // 3 

    }


    function testCallingAccessTokenAsAuthor() public {
        
        assertEq(license.owner(), alice);
        hoax(alice);                
        accessToken.mint(1);
        
    }

    function testLicenseOwnersCanCallAccessToken() public {
        
        // alice is the author
        // She ownes the license contract 
        // she can mint licenses 
        hoax(alice);
        license.mint(2);
        hoax(alice);
        license.safeTransferFrom(alice, bob, 1);
        hoax(bob);
        console.log("bob's address:", bob);

        console.log("bob has validLicense:", license.hasValidLicense(bob));
        assertTrue(license.hasValidLicense(bob));

        console.log(address(license));
        console.log(address(authorityModule.getLicense()));
        console.log("bob has validLicense:", authorityModule.userHasLicense(bob));
        assertTrue(accessToken.changeFlag());
    
    }

    

    function testBuyLicense() public {
        hoax(alice, 0);
        license.mint(3);
        
        
        hoax(bob, 1000000 ether);
        console.log("bob's balance is:", bob.balance);
        console.log("balance of this contract:", address(this).balance);
        console.log("balance of alice:", alice.balance);
        license.buy{value:0.1 ether}();
        // assertTrue(bob.balance)
        console.log("balance of alice:", alice.balance);
        console.log("balance of this contract:", address(this).balance);
    }


    function testChangeLicensePrice() public {
        
        console.log("before price change:", license.price());
        hoax(alice);
        license.setPrice(3.14 ether);
        console.log("after price change:", license.price());
    }



}
