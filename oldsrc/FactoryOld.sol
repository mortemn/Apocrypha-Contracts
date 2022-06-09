// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";

import {License} from "./License.sol";
import {LicenseAuthority} from "./AuthorityModule.sol";
import {AccessToken} from "./AccessToken.sol";


/// @title Combined Factory
/// @author 
/// @notice Factory which enables deploying a Vault for any ERC20 token.
contract Factory is Auth {


    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a Factory.
    /// @param _owner The owner of the factory.
    /// @param _authority The Authority of the factory.
    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                          VAULT DEPLOYMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new Bundle is deployed.
    /// @param license The newly deployed License contract.
    /// @param licenseAuthority The new licenseAuthority deployed (might not be necessary in the long run and can be deleted)
    // it might not be necessary because there's no Auth inside the LicenseAuthority contract 
    /// @param  accessToken - the accessToken contract 
    event BundleDeployed(License license, LicenseAuthority licenseAuthority, AccessToken accessToken);

    // / @notice Deploys a new Vault which supports a specific underlying token.
    // / @dev This will revert if a Vault that accepts the same underlying token has already been deployed.
    // / @param underlying The ERC20 token that the Vault should accept.
    // / @return vault The newly deployed Vault contract which accepts the provided underlying token.
    function deployBundle(string memory name, string memory symbol, string memory baseURI) external returns (License license, LicenseAuthority licenseAuthority, AccessToken accessToken) {

        // owner of license would be the owner of msg.sender; hence Auth(msg.sender).owner
        // since the msg.sender calling the constructor of the license contract is the Factory
        // Auth(msg.sender).owner() would be the owner of the Factory 
        // This is a problem
        // We want the owner of the license to be 
        license             = new License(name, symbol, baseURI); 

        // don't think licenseAuthority is owned
        // you might think because it is not owned, 
        // technically speaking perhaps we don't need to deploy a new LicenseAuthority every time we deploy a new license
        // but this is wrong, because the LicenseAuthority contract targets one particular license
        licenseAuthority    = new LicenseAuthority(license);

        // accessToken has the same owner structure has license, which means its owner is also the owner of Factory
        accessToken         = new AccessToken(name, symbol, baseURI, license.authority());

        emit BundleDeployed(license, licenseAuthority, accessToken);

        return (license, licenseAuthority, accessToken);
    }

    /*///////////////////////////////////////////////////////////////
                            VAULT LOOKUP LOGIC
    //////////////////////////////////////////////////////////////*/

    // /// @notice Computes a Vault's address from its accepted underlying token.
    // /// @param underlying The ERC20 token that the Vault should accept.
    // /// @return The address of a Vault which accepts the provided underlying token.
    // /// @dev The Vault returned may not be deployed yet. Use isVaultDeployed to check.
    // function getVaultFromUnderlying(ERC20 underlying) external view returns (Vault) {
    //     return
    //         Vault(
    //             payable(
    //                 keccak256(
    //                     abi.encodePacked(
    //                         // Prefix:
    //                         bytes1(0xFF),
    //                         // Creator:
    //                         address(this),
    //                         // Salt:
    //                         address(underlying).fillLast12Bytes(),
    //                         // Bytecode hash:
    //                         keccak256(
    //                             abi.encodePacked(
    //                                 // Deployment bytecode:
    //                                 type(Vault).creationCode,
    //                                 // Constructor arguments:
    //                                 abi.encode(underlying)
    //                             )
    //                         )
    //                     )
    //                 ).fromLast20Bytes() // Convert the CREATE2 hash into an address.
    //             )
    //         );
    // }

    // / @notice Returns if a Vault at an address has already been deployed.
    // / @param vault The address of a Vault which may not have been deployed yet.
    // / @return A boolean indicating whether the Vault has been deployed already.
    // / @dev This function is useful to check the return values of getVaultFromUnderlying,
    /// as it does not check that the Vault addresses it computes have been deployed yet.
    function isBundleDeployed(License license, LicenseAuthority licenseAuthority, AccessToken accessToken) external view returns (bool) {
        return address(license).code.length > 0 && address(licenseAuthority).code.length > 0 && address(accessToken).code.length > 0;
    }
}
