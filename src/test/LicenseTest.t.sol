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

import {License} from "../License.sol";
import {Factory} from "../Factory.sol";
import {Authority} from "solmate/auth/Auth.sol";
import {MasterNFT} from "../MasterNFT.sol";
import {WholeAuthorityModule} from "../WholeAuthorityModule.sol";


interface CheatCodes {
    function deal(address who, uint256 newBalance) external;
    function addr(uint256 privateKey) external returns (address);
    function warp(uint256) external;    // Set block.timestamp
}

contract LicenseTest is Test {
    AccessToken accessToken;
    License license;
    Factory factory;
    MasterNFT masterNFT;
    WholeAuthorityModule wholeAuthorityModule;

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
        wholeAuthorityModule = factory.deployWholeAuthorityModule(masterNFT);
        license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, wholeAuthorityModule, masterNFT);
        accessToken = factory.deployAccessToken(name, symbol, baseURI, accessTokenExpiryTime, accessTokenMaxSupply, accessTokenPrice, wholeAuthorityModule, license, masterNFT);
        factory.setWholeAuthorityModuleLicense(wholeAuthorityModule, license);
        factory.setWholeAuthorityModuleAccessToken(wholeAuthorityModule, accessToken);
        factory.setAccessTokenOfLicense(license, accessToken);
        hoax(alice);
        masterNFT.mint(alice, alice, 10);
        hoax(alice);
        license.mint(1);
        
    }

    function testTransferLicense() public {
        assertEq(license.ownerOf(0), alice);    // Alice as holder of masterNFT she can mint licenses 
        hoax(alice);
        license.safeTransferFrom(alice, bob, 0);
        assertEq(license.ownerOf(0), bob);        // ownership of the Master NFT is changed when the Master NFT is changed hands.
        assertEq(license.owner(), address(factory));
    }

    function testMintAccessToken() public {
      hoax(alice);                                  
      license.mintAccessTokens(0);                              // Alice has already been given a license in the setUp
      assertEq(license.licenseToAccessTokenBalance(0), 100);    // 100 is the max supply of accesstokens each license can mint 
      assertEq(accessToken.balanceOf(address(license)), 100);
    
      hoax(alice);
      license.mint(1);                             // We now mint a license.
      hoax(alice);
      license.safeTransferFrom(alice, bob, 1);     // Which we then send to Bob.
      assertEq(license.ownerOf(1), bob);
      hoax(bob);
      license.mintAccessTokens(1);
      assertEq(license.licenseToAccessTokenBalance(1), 100);   // 100 is the max supply of accesstokens each license can mint 
    }


    function testTransferLicenseAfterMintingAccessToken() public {
       
        hoax(alice);                                  
        license.mintAccessTokens(0);                              // Alice has already been given a license in the setUp
        assertEq(license.licenseToAccessTokenBalance(0), 100);    // 100 is the max supply of accesstokens each license can mint 
        assertEq(accessToken.balanceOf(address(license)), 100);            
        hoax(alice);
        license.transferFrom(alice, bob, 0);
        assertEq(license.ownerOf(0), bob);        // ownership of the Master NFT is changed when the Master NFT is changed hands.
        assertEq(license.owner(), address(factory));
        assertEq(accessToken.balanceOf(address(license)), 100);

    }

    function testBuyAccessTokenFromLicense() public {
        hoax(alice);
        license.mintAccessTokens(0);
        assertEq(license.licenseToAccessTokenBalance(0), 100);    // 100 is the max supply of accesstokens each license can mint 
        assertEq(accessToken.balanceOf(address(license)), 100);
        assertEq(accessToken.ownerOf(1), address(license));
        assertEq(accessToken.ownerOf(12), address(license));
        assertEq(accessToken.ownerOf(99), address(license));
        
        hoax(alice, 0);
        
        console.log(0, license.getAccessToken(0,0));
        console.log(1, license.getAccessToken(0,1));
        console.log(2, license.getAccessToken(0,2));
        console.log(20, license.getAccessToken(0,20));
        console.log(99, license.getAccessToken(0,99));
        
        console.log("the no. of accessTokens left:", license.getAmountLeft(1));

        hoax(bob);
            
        license.buyAccessToken{value: 0.01 ether}(0);
    
        console.log("the no. of accessTokens left:", license.getAmountLeft(1));
            
        console.log(0, license.getAccessToken(0,0));
        console.log(1, license.getAccessToken(0,1));
        console.log(2, license.getAccessToken(0,2));
        console.log(20, license.getAccessToken(0,20));
        console.log(98, license.getAccessToken(0,98));

        assertEq(address(masterNFT).balance, 0.01 ether/2);
        assertEq(license.withdrawableBalance(0), 0.01 ether/2);
        // 
        console.log(address(license));
        console.log(accessToken.ownerOf(99));
        assertEq(address(masterNFT).balance, 0.01 ether/2);
        hoax(alice);
        license.withdraw(0);
        assertEq(license.withdrawableBalance(0),0);
    }

    
    function testSetAccessTokenMaxSupply() public {
        hoax(alice);
        license.mintAccessTokens(0);
        assertEq(accessToken.balanceOf(address(license)), 100);
        
        hoax(alice);
        masterNFT.safeTransferFrom(alice, bob, 1);  // Bob now holds the masterNFT.
        assertEq(masterNFT.owner(), bob);           // ownership of the contract is changed when the Master NFT is changed hands.
        assertEq(masterNFT.ownerOf(1), bob);        // ownership of the Master NFT is changed when the Master NFT is changed hands.
        
        
        hoax(bob);    
        license.mint(1);                              // Bob mints 1 license to himself.
        
        assertEq(license.ownerOf(0), alice);
        assertEq(license.ownerOf(1), bob);
        
        
        console.log(wholeAuthorityModule.masterNFT().ownerOf(1));
        console.log(bob);
        hoax(bob);
        accessToken.setMaxSupply(1000);                   // Bob sets the max supply of access tokens each license can mint.
        console.log(accessToken.maxSupplyPerLicense());
        assertEq(accessToken.maxSupplyPerLicense(), 1000);
        hoax(bob);

        license.mintAccessTokens(1);
        assertEq(accessToken.balanceOf(address(license)), 1000+100);
        
        hoax(bob);
        vm.expectRevert("LICENSE_ALREADY_USED");
        license.mintAccessTokens(1);

        hoax(alice);
        vm.expectRevert("UNAUTHORIZED");
        accessToken.setMaxSupply(10000);
    }

    function testLicensesCannotBeUsedTwice() public {
      assertEq(license.ownerOf(0), alice);
      hoax(alice);
      console.log(address(license));
      license.mintAccessTokens(0);
      
      
      assertEq(accessToken.balanceOf(address(license)), 100);
      assertEq(license.getAmountLeft(0), 100);
    //   
      hoax(alice);
      license.safeTransferFrom(alice, bob, 0);
      hoax(bob);
      vm.expectRevert("LICENSE_ALREADY_USED");
      license.mintAccessTokens(0);
    }

        
    function testSetAccessTokenExpiryTime() public {
        startHoax(alice);                           
        console.log(block.timestamp);               
        uint256 expiryTime = 1000;     
        accessToken.setExpiryTime(expiryTime);      
        assertEq(license.ownerOf(0), alice);

        
        
        
        license.mintAccessTokens(0);
        (uint256 expiryDate,,) = accessToken.getTokenData(0);
        console.log(expiryDate);
        // assertFalse(accessToken.isExpired(0));
        // cheats.warp(block.timestamp+expiryTime);    
        // console.log(block.timestamp);
        // assertTrue(accessToken.isExpired(0)); 
    }
    

    function testLicenseTransferPreserveAllRights() public {
        hoax(alice);
        license.safeTransferFrom(alice, bob, 0);
        assertFalse(wholeAuthorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("setMaxSupply(uint256)"))));
        assertFalse(wholeAuthorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("setExpiryTime(uint256)"))));
        assertFalse(wholeAuthorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("setPrice(uint256)"))));
        assertFalse(wholeAuthorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("mint(uint256)"))));
        assertFalse(wholeAuthorityModule.canCall(address(license), address(accessToken), bytes4(abi.encodeWithSignature("mint(uint256)"))));
        
        assertFalse(wholeAuthorityModule.canCall(alice,  address(accessToken), bytes4(abi.encodeWithSignature("mint(uint256)"))));
    }

    function testLicenseSalePreserveAllRights() public {
        hoax(alice);
        license.setApprovalForAll(bob, true);
        hoax(bob, 100 ether);
        license.buy{value:0.1 ether}(0);
        assertFalse(wholeAuthorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("setMaxSupply(uint256)"))));
        assertFalse(wholeAuthorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("setExpiryTime(uint256)"))));
        assertFalse(wholeAuthorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("setPrice(uint256)"))));
        assertFalse(wholeAuthorityModule.canCall(bob, address(accessToken), bytes4(abi.encodeWithSignature("mint(uint256)"))));
        assertFalse(wholeAuthorityModule.canCall(address(license), address(accessToken), bytes4(abi.encodeWithSignature("mint(uint256)"))));

        assertFalse(wholeAuthorityModule.canCall(alice,  address(accessToken), bytes4(abi.encodeWithSignature("mint(uint256)"))));
    }
    

   

    // function testBuyDegenerateAccessTokenPath1() public {
      
    //   // 1. The license holder mints accessTokens
    //   hoax(alice);
    //   accessToken.mint(1);
    //   assertEq(accessToken.ownerOf(1), alice);
    //   assertEq(accessToken.ownerOf(2), alice);
    //   assertEq(accessToken.ownerOf(100), alice);
      
      
    // //   2. She then sells the license 
    //   hoax(alice);
    //   license.setApprovalForAll(bob, true);
    //   hoax(bob);
    //   license.buy{value:0.1 ether}(1);
    

    // //   assertEq(accessToken.ownerOf(1),   bob);
    // //   assertEq(accessToken.ownerOf(2),   bob);
    // //   assertEq(accessToken.ownerOf(100), bob);

    // //   3. The new owner offers the accessTokens for sale
    // //   hoax(bob);
    // //   accessToken.setApprovalForAll(carol, true);
    // //   
    // //   4. Someone buys it
    // //   hoax(carol);
    // //   assertEq(accessToken.ownerOf(1), bob);
    // // //   accessToken.buy{value:0.01 ether}(1);

    // }
    
    

}
