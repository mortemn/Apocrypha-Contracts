// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";

import {License} from "./License.sol";
import {AuthorityModule} from "./AuthorityModule.sol";
import {MasterCopyAuthority} from "./MasterCopyAuthority.sol";
import {AccessToken} from "./AccessToken.sol";


/// @title Combined Factory
/// @author 
/// @notice Factory which enables deploying a Vault for any ERC20 token.
contract Factory is Auth {
    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;


    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a Factory.
    /// @param _owner The owner of the factory.
    /// @param _authority The Authority of the factory.
    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                            CONTRACT DEPLOYMENT 
    //////////////////////////////////////////////////////////////*/

<<<<<<< HEAD
    /// @notice Emitted when a new Bundle is deployed.
    /// @param license The newly deployed License contract.
    /// @param authorityModule The new authorityModule deployed (might not be necessary in the long run and can be deleted)
    // it might not be necessary because there's no Auth inside the AuthorityModule contract 
    // event LicenseBundleDeployed(License license, AuthorityModule authorityModule);
    event LicenseBundleDeployed(License license, AuthorityModule authorityModule);
=======
    event AuthorityModuleDeployed(AuthorityModule authorityModule); 
>>>>>>> df7dba1aa062c4828536feb9db16898bf2192b60

    event LicenseDeployed(License license);

    event AccessTokenDeployed(AccessToken accessToken); 

    function deployLicense (string memory name, string memory symbol, string memory baseURI, uint256 expiryTime, uint256 maxSupply, uint256 price) external returns (License license) {
      license = new License(name, symbol, baseURI, expiryTime, maxSupply, price); 
      emit LicenseDeployed(license);
      return (license);
    }

<<<<<<< HEAD

    // function deployLicenseBundle (string memory name, string memory symbol, string memory baseURI, uint256 expiryTime, uint256 maxSupply, uint256 price, uint256 salt, address author) external returns (License license, AuthorityModule) {    

    //     // Checks what the address of license will be.
    //     License predictedLicense = getLicenseFromSalt(salt);

    //     // Deploy authority.
    //     authorityModule = new AuthorityModule(msg.sender, predictedLicense);

        

    //     license = new License{

    //       salt: bytes32(salt)
    //     } (name, symbol, baseURI, expiryTime, maxSupply, price, author); 

    //     emit LicenseBundleDeployed(license, authorityModule);
        

    //     return (license, authorityModule);
    // }


    function deployLicenseBundle (string memory name, string memory symbol, string memory baseURI, uint256 expiryTime, uint256 maxSupply, uint256 price, uint256 salt, address author) external returns (License license, AuthorityModule) {    

        // Checks what the address of license will be.
        // License predictedLicense = getLicenseFromSalt(salt);

        license = new License (name, symbol, baseURI, expiryTime, maxSupply, price, author); 

        // Deploy authority.
        authorityModule = new AuthorityModule(msg.sender, license);

    
        emit LicenseBundleDeployed(license, authorityModule);
        

        return (license, authorityModule);
=======
    function deployAuthorityModule (License license) external returns (AuthorityModule authorityModule) {
      authorityModule = new AuthorityModule(msg.sender, license);
      emit AuthorityModuleDeployed(authorityModule);
      return (authorityModule);
>>>>>>> df7dba1aa062c4828536feb9db16898bf2192b60
    }

    function deployAccessToken (string memory name, string memory symbol, string memory baseURI, uint256 expiryTime, uint256 maxSupply, uint256 price, AuthorityModule authorityModule) external returns (AccessToken accessToken) {
      accessToken = new AccessToken(name, symbol, baseURI, expiryTime, maxSupply, price, authorityModule); 
      emit AccessTokenDeployed(accessToken);
      return (accessToken);
    }

    function areContractsDeployed(License license, AuthorityModule authorityModule, AccessToken accessToken) external view returns (bool) {
      return (address(license).code.length > 0) && (address(authorityModule).code.length > 0) && (address(accessToken).code.length > 0);
    }
}
