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
import {MasterNFT} from "../MasterNFT.sol";
import {MasterNFTAuthorityModule} from "../MasterNFTAuthorityModule.sol";


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
    MasterNFT masterNFT;
    MasterNFTAuthorityModule masterNFTAuthorityModule;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    // address HEVM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
    
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
      hoax(alice);
      masterNFT = new MasterNFT(name, symbol, baseURI); 
      masterNFTAuthorityModule = factory.deployMasterNFTAuthorityModule(masterNFT);
      license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, masterNFTAuthorityModule, masterNFT);
      authorityModule = factory.deployAuthorityModule(masterNFT, license);
      accessToken = factory.deployAccessToken(name, symbol, baseURI, accessTokenExpiryTime, accessTokenMaxSupply, accessTokenPrice, authorityModule, license, masterNFT);
      factory.setMasterNFTAuthorityModuleLicense(masterNFTAuthorityModule, license);
      factory.setAuthorityModuleAccessToken(authorityModule, accessToken);
      
      hoax(alice);
      masterNFT.mint(alice);
      hoax(alice);
      license.mint(1);
    }

    function testTransferLicense() public {
        assertEq(license.ownerOf(1), alice);    // Alice as holder of masterNFT she can mint licenses 
        hoax(alice);
        license.safeTransferFrom(alice, bob, 1);
        assertEq(license.ownerOf(1), bob);        // ownership of the Master NFT is changed when the Master NFT is changed hands.
        assertEq(license.owner(), address(factory));
    }

    function testMintAccessToken() public {
      hoax(alice);                                  
      accessToken.mint(1);                         // Alice has already been given a license in the setUp
      assertEq(accessToken.balanceOf(alice), 100); // 100 is the max supply of accesstokens each license can mint 
      

      hoax(alice);
      license.mint(1);                             // We now mint a license.
      hoax(alice);
      license.safeTransferFrom(alice, bob, 2);     // Which we then send to Bob.
      assertEq(license.ownerOf(2), bob);
      hoax(bob);
      accessToken.mint(2);                         // And Bob can now mint accessTokens. 
      assertEq(accessToken.balanceOf(bob), 100);   // 100 is the max supply of accesstokens each license can mint 
    }

    
    function testSetAccessTokenMaxSupply() public {
        hoax(alice);
        accessToken.mint(1);                          // Alice mints out 100 accessTokens 
        assertEq(accessToken.balanceOf(alice), 100);
        
        hoax(alice);
        masterNFT.safeTransferFrom(alice, bob, 1);  // Bob now holds the masterNFT.
        assertEq(masterNFT.owner(), bob);           // ownership of the contract is changed when the Master NFT is changed hands.
        assertEq(masterNFT.ownerOf(1), bob);        // ownership of the Master NFT is changed when the Master NFT is changed hands.
        
        
        hoax(bob);    
        license.mint(1);                              // Bob mints 1 license to himself.
        
        assertEq(license.ownerOf(1), alice);
        assertEq(license.ownerOf(2), bob);
        
        
        console.log(authorityModule.masterNFT().ownerOf(1));
        console.log(bob);
        hoax(bob);
        accessToken.setMaxSupply(1000);                   // Bob sets the max supply of access tokens each license can mint.
        console.log(accessToken.maxSupplyPerLicense());
        assertEq(accessToken.maxSupplyPerLicense(), 1000);
        hoax(bob);

        accessToken.mint(2);
        assertEq(accessToken.balanceOf(bob), 1000);
        
        hoax(bob);
        vm.expectRevert("LICENSE_ALREADY_USED");
        accessToken.mint(2);

        hoax(alice);
        vm.expectRevert("UNAUTHORIZED");
        accessToken.setMaxSupply(10000);
    }

    function testLicensesCannotBeUsedTwice() public {
      hoax(alice);
      accessToken.mint(1);
      assertEq(accessToken.balanceOf(alice), 100);
      hoax(alice);
      license.safeTransferFrom(alice, bob, 1);
      hoax(bob);
      vm.expectRevert("LICENSE_ALREADY_USED");
      accessToken.mint(1);
    }

        
    function testSetAccessTokenExpiryTime() public {
        startHoax(alice);                           
        console.log(block.timestamp);               
        uint256 expiryTime = 1000;     
        accessToken.setExpiryTime(expiryTime);      
        assertTrue(authorityModule.userHasLicense(alice));
        assertEq(license.ownerOf(1), alice);
        accessToken.mint(1);                        
        assertTrue(!accessToken.isExpired(1));          
        cheats.warp(block.timestamp+expiryTime);    
        console.log(block.timestamp);         
        assertTrue(accessToken.isExpired(1));           
    }
    
    function testSettingLicenseExpiryTimeAfterMint() public {
        uint256 expiryTime = 2;  

        startHoax(alice);
        (uint256 expiryDate1,,) = license.getLicenseData(1); 
        console.log("expiry for token 1:",  expiryDate1);    // 864001 (10 days)
        
        license.setExpiryTime(expiryTime); 
        
        (uint256 expiryDate2,,) = license.getLicenseData(1); 
        console.log("expiry for token 1:", expiryDate2);    // 864001 (10 days) 
        
        // Once you've minted a license, you cannot change the expiry date of that already minted license by changing the global expiry time
        // But, you can change the expiry dates of future yet-to-be minted licenses.

        license.mint(1);
        (uint256 expiryDate3,,) = license.getLicenseData(2);
        console.log("expiry for token 2:", expiryDate3);    // 3
        assertEq(expiryDate3, block.timestamp + expiryTime);

    }

    function testLicenseTransferPreserveAllRights() public {
        hoax(alice);
        license.safeTransferFrom(alice, bob, 1);
        assertFalse(authorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("setMaxSupply(uint256)"))));
        assertFalse(authorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("setExpiryTime(uint256)"))));
        assertFalse(authorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("setPrice(uint256)"))));
        assertTrue(authorityModule.canCall(bob,  address(accessToken), bytes4(abi.encodeWithSignature("mint(uint256)"))));
        
        assertFalse(authorityModule.canCall(alice,  address(accessToken), bytes4(abi.encodeWithSignature("mint(uint256)"))));
    }

    function testLicenseSalePreserveAllRights() public {
        hoax(alice);
        license.setApprovalForAll(bob, true);
        hoax(bob, 100 ether);
        license.buy{value:0.1 ether}(1);
        assertFalse(authorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("setMaxSupply(uint256)"))));
        assertFalse(authorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("setExpiryTime(uint256)"))));
        assertFalse(authorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("setPrice(uint256)"))));
        assertTrue(authorityModule.canCall(bob,  address(accessToken), bytes4(abi.encodeWithSignature("mint(uint256)"))));

        assertFalse(authorityModule.canCall(alice,  address(accessToken), bytes4(abi.encodeWithSignature("mint(uint256)"))));
    }
    

    function testBuyAccessToken() public {
        assertEq(license.ownerOf(1), alice);
        
        hoax(alice,0 );
        accessToken.mint(1);
        assertEq(accessToken.balanceOf(alice), 100);
        
        hoax(alice, 0);
        accessToken.setApprovalForAll(bob, true);
        
        hoax(bob, 100 ether);
        accessToken.buy{value:0.01 ether}(1);
        assertEq(address(masterNFT).balance, 0.01 ether/2);
        assertEq(alice.balance, 0.01 ether/2);
        
        assertEq(accessToken.ownerOf(1), bob);
        
    }

    function testBuyDegenerateAccessTokenPath1() public {
      
    //   // 1. The license holder mints accessTokens
    //   hoax(alice);
    //   accessToken.mint(1);

    //   // 2. She then sells the license 
    //   hoax(alice);
    //   license.setApprovalForAll(bob, true);
    //   hoax(bob);
    //   license.buy{value:0.1 ether}(1);

    //   // // 3. The new owner offers the accessTokens for sale
    //   hoax(bob);
    //   accessToken.setApprovalForAll(carol, true);
      
    //   // // 4. Someone buys it
    //   hoax(carol);
    //   assertEq(accessToken.ownerOf(1), bob);
    // //   accessToken.buy{value:0.01 ether}(1);

    }
    
    

}