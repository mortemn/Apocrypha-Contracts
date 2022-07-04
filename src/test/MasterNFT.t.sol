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

contract MasterNFTTest is Test {
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
    
    uint256 licenseExpiryTime = 10 days;
    uint256 licenseMaxSupply = 10; 
    uint256 licensePrice = 0.1 ether;

    uint256 accessTokenExpiryTime = 100 days ;
    uint256 accessTokenMaxSupply = 100;
    uint256 accessTokenPrice =  0.01 ether;
    
    

     function setUp() public {
        // The difference between "this" and "alice" for the purpose of our tests is that 
        // "this" is basically us. Since the owner of the factory is "this", a msg.sender, it is basically us - who created the contract 
        
        factory = new Factory(address(this), Authority(address(0)));
        hoax(alice);
        masterNFT = new MasterNFT(name, symbol, baseURI); 
        wholeAuthorityModule = factory.deployWholeAuthorityModule(masterNFT);
        license = factory.deployLicense(name, symbol, baseURI, licenseExpiryTime, licenseMaxSupply, licensePrice, wholeAuthorityModule, masterNFT);
        accessToken = factory.deployAccessToken(name, symbol, baseURI, accessTokenExpiryTime, accessTokenMaxSupply, accessTokenPrice, wholeAuthorityModule, license, masterNFT);
        factory.setWholeAuthorityModuleLicense(wholeAuthorityModule, license);
        factory.setWholeAuthorityModuleAccessToken(wholeAuthorityModule, accessToken);
        

        hoax(alice);
        masterNFT.mint(alice);

    }

    function testOwnership() public {
        assertEq(factory.owner(), address(this));
        assertEq(masterNFT.owner(), alice);
        assertEq(wholeAuthorityModule.owner(), address(factory));
        assertEq(license.owner(), address(factory));
        assertEq(accessToken.owner(), address(factory));
        
    }

    function testAuthorities() public {
        assertEq(address(license.authority()), address(wholeAuthorityModule));
        assertEq(address(accessToken.authority()), address(wholeAuthorityModule));           
        assertEq(address(wholeAuthorityModule.masterNFT()), address(masterNFT));
        assertEq(address(wholeAuthorityModule.license()), address(license));        
        assertEq(address(wholeAuthorityModule.accessToken()), address(accessToken)); 
    }
    

    function testMintMasterNFT() public {
        assertEq(masterNFT.ownerOf(1), alice);    
    }

    function testMintMasterNFTIsUnique() public {
        hoax(alice);
        vm.expectRevert("Unique Master NFT already minted!");   // once the MasterNFT is minted she cannot mint another
        masterNFT.mint(alice);        
    }

    function testMasterNFTHolderCanTransfer() public {
        hoax(alice);           
        license.mint(1); 
        
        assertEq(masterNFT.owner(), alice);     
        assertEq(masterNFT.ownerOf(1), alice);    
        assertEq(license.ownerOf(0), alice);    // Alice as holder of masterNFT she can mint licenses 
        
        
        hoax(alice);
        masterNFT.safeTransferFrom(alice, bob, 1);
        assertEq(masterNFT.owner(), bob);           // ownership of the contract is changed when the Master NFT is changed hands.
        assertEq(masterNFT.ownerOf(1), bob);        // ownership of the Master NFT is changed when the Master NFT is changed hands.
        assertFalse(masterNFT.ownerOf(1)==alice);   // Alice is no longer the owner of the Master NFT
        assertFalse(masterNFT.owner()==alice);      // Alice is no longer the owner of the masterNFT contract.

        console.log("bob's address is:", bob);

        hoax(bob);
        
        license.mint(1);        
        assertEq(license.ownerOf(1), bob);        
        assertTrue(wholeAuthorityModule.canCall(bob, address(license), ""));  
        assertFalse(wholeAuthorityModule.canCall(alice, address(license), ""));  
        
        // console.log("Alice can call", wholeAuthorityModule.canCall(alice, address(license), ""));
        // console.log("alice has masterNFT:",wholeAuthorityModule.userHasMasterNFT(alice));
        
        hoax(alice);                            // former Master NFT holders cannot call license function
        vm.expectRevert("UNAUTHORIZED");
        license.mint(1); // because Alice 

        hoax(carol);                            // random actors cannot call license functions
        vm.expectRevert("UNAUTHORIZED");
        license.mint(1);

        hoax(bob);
        vm.expectRevert("Unique Master NFT already minted!");   // once the MasterNFT is minted, Bob cannot mint another.
        masterNFT.mint(bob);
    }


    
    function testSetLicenseMaxSupply() public {
        startHoax(alice);
        assertEq(license.maxSupply(), 10);
        license.setMaxSupply(1000);
        assertEq(license.maxSupply(), 1000);
    }

    function testSettingLicenseMaxSupplyAfterMint() public {
        startHoax(alice);
        uint256 maxSupply = 100000;
        vm.expectRevert("MAX_SUPPLY_REACHED");
        license.mint(1000);
        
        license.mint(10);                   
     
        assertEq(license.totalSupply(), 10);
        assertEq(license.maxSupply(), 10);
        
        // console.log(license.maxSupply());
        
        license.setMaxSupply(maxSupply);
        console.log("max supply is:", license.maxSupply());
        
        // Unlike expiry dates, setting max supply does 
        assertEq(license.maxSupply(), 100000);
        
        license.mint(1000);
        assertEq(license.totalSupply(), 1000+10);
        
    }

    
    function testSetLicenseExpiryTime() public {
        startHoax(alice);
        console.log(block.timestamp);                   // The time now is 1.
        uint256 expiryTime = licenseExpiryTime; 
        
        assertEq(masterNFT.ownerOf(1), alice);            
        
        license.setExpiryTime(expiryTime);              // Setting the Expiry Time.
        
        license.mint(1);                                // Minting 3 tokens.
        assertTrue(!license.isExpired(0));              // Not expired.
        cheats.warp(block.timestamp+expiryTime);        // Changing the time to time after the expirytime.       
        console.log(block.timestamp);                   // Time now is 10001.
        assertTrue(license.isExpired(0));               // Expired.
    }
    
    function testSettingLicenseExpiryTimeAfterMint() public {
        startHoax(alice);
        uint256 expiryTime = 2;  
        
        license.mint(1);
        (uint256 expiryDate1,,) = license.getLicenseData(0); 
        console.log("expiry for token 1:",  expiryDate1);    // 864001 (10 days)
        
        license.setExpiryTime(expiryTime); 
        
        (uint256 expiryDate2,,) = license.getLicenseData(0); 
        console.log("expiry for token 1:", expiryDate2);    // 864001 (10 days) 
        
        // Once you've minted a license, you cannot change the expiry date of that license by changing the global expiry time

        license.mint(1);
        (uint256 expiryDate3,,) = license.getLicenseData(1);
        console.log("expiry for token 2:", expiryDate3);    // 3
        assertEq(expiryDate3, block.timestamp + expiryTime);

    }

    
    function testBuyLicense() public {
        hoax(alice,0);
        license.mint(3);
        
        hoax(bob, 100 ether);
        console.log("bob's balance:", bob.balance);
        console.log("alice's balance:", alice.balance);
        vm.expectRevert("NOT_AUTHORIZED");
        license.buy{value:0.1 ether}(1);
        
        
        hoax(alice,0);
        license.setApprovalForAll(bob, true);

        (uint256 expiryDate, address minter,) = license.getLicenseData(1);
        assertEq(minter, alice);
        
        console.log("bob's balance is:", bob.balance);
        console.log("balance of alice:", alice.balance);
        console.log("balance of masterNFT before:", address(masterNFT).balance);
        hoax(bob, 100 ether);
        license.buy{value:0.1 ether}(1);
    
        assertEq(address(masterNFT).balance, 0.1*10**18);
        assertEq(license.ownerOf(1), bob);
        assertFalse(license.ownerOf(1)==alice);
        assertEq(license.ownerOf(1), bob);
        
    }

    
    function testNeedLicenseToCallAccessTokenFunctions() public {
        hoax(alice,0);
        vm.expectRevert("NOT_MINTED");
        license.mintAccessTokens(1);
    }



    function testSetLicensePrice () public {
        hoax(alice);
        license.mint(1);
        hoax(alice);
        license.setApprovalForAll(bob, true);

        assertEq(license.price(), licensePrice);
        console.log(license.lastSold());
        hoax(bob, 100 ether);
        license.buy{value:0.1 ether}(0);
        assertEq(license.ownerOf(0), bob);
        assertEq(bob.balance, (100-0.1)*10**18);

        // if alice mints and then sets price, the price will be updated

        hoax(alice);
        license.mint(1);
        hoax(alice);
        license.setPrice(7 ether);
        assertEq(license.price(), 7 ether);
        
        hoax(bob, 100 ether);
        assertEq(license.maxSupply(), 10);
        assertEq(license.totalSupply(), 2);
        vm.expectRevert("INCORRECT_PRICE");
        license.buy{value:0.1 ether}(1);
        
        hoax(bob, 100 ether);
        license.buy{value:7 ether}(1);
        assertEq(license.ownerOf(1), bob);
        assertEq(bob.balance, (100-7)*10**18);

        // // if alice sets price and then mints, the price will be updated as well

        hoax(alice);
        license.setPrice(8 ether);
        hoax(alice);
        license.mint(1);
        assertEq(license.price(), 8 ether);

        hoax(bob, 100 ether);
        assertEq(license.maxSupply(), 10);
        assertEq(license.totalSupply(), 3);
        vm.expectRevert("INCORRECT_PRICE");
        license.buy{value:0.1 ether}(2);
        
        hoax(bob, 100 ether);
        license.buy{value:8 ether}(2);
        assertEq(license.ownerOf(2), bob);
        assertEq(bob.balance, (100-8)*10**18);
    }

    function testWithdraw() public { 
        hoax(alice);
        license.mint(1);
        hoax(alice);
        license.setApprovalForAll(bob, true);
        hoax(bob, 100 ether);
        license.buy{value:0.1 ether}(0);
        assertEq(license.ownerOf(0), bob);
        hoax(alice,0);
        masterNFT.withdraw();
        assertEq(alice.balance, 0.1 ether);
    }

    function testNonMasterNFTHolderCannotWithdraw() public { 
        hoax(alice);
        license.mint(1);
        hoax(alice);
        license.setApprovalForAll(bob, true);
        hoax(bob, 100 ether);
        license.buy{value:0.1 ether}(0);
        assertEq(license.ownerOf(0), bob);
        hoax(carol,1 ether);
        vm.expectRevert("UNAUTHORIZED");
        masterNFT.withdraw();
        assertEq(address(masterNFT).balance, 0.1 ether);
    }
}
