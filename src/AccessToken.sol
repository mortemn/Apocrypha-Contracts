// SPDX-License-Identifier: AGPL-3.0-only 
pragma solidity 0.8.11;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {License} from "./License.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import{MasterNFT} from "./MasterNFT.sol";

contract AccessToken is ERC721, Auth {
    using FixedPointMathLib for uint256;
    MasterNFT masterNFT;
    License public license;
    /*//////////////////////////////////////////////////////////////
                              CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    string public baseURI;
    /// @notice Amount of time before token expires.
    uint256 public expiryTime;
    /// @notice Max supply of tokens mintable per license.
    uint256 public maxSupplyPerLicense;
    /// @notice Price of token.
    uint256 public price;
    /// @notice Total supply of token.
    uint256 public totalSupply;

    /// @notice Struct of token data.
    /// @param expiryDate Date where token expires.
    /// @param minter Address of license holder who minted the token.
    struct TokenData {
      uint256 expiryDate;
      address minter;
      uint256 licenseId;
      // uint256 licenseId;
      // address payTo = license.Owner(licenseId
    }

    /// @notice Checks if token is sold or not. 
    mapping(uint256 => bool) public isSold;

    /// @notice Emitted after a new price is set.
    /// @param newPrice New price of the token.
    event PriceUpdated(uint256 newPrice);
    /// @notice Emitted after a new expiry time is set.
    /// @param newTime New expiry time of the token.
    event ExpiryTimeUpdated(uint256 newTime); 
    /// @notice Emitted after a new max supply is set.
    /// @param newMaxSupply New max supply of the token.
    event MaxSupplyUpdated(uint256 newMaxSupply);
    /// @notice Emitted after a token is bought.
    /// @param id Id of token which was sold.
    /// @param buyer address of the buyer of the token.
    event TokenSold(uint256 id, address buyer);

    /// @notice Maps id to struct that holds info of it.
    mapping(uint256 => TokenData) public getTokenData;

    /// @notice Creates new ERC721.
    /// @param _name Name of original token.
    /// @param _symbol Symbol of original token.
    /// @param _baseURI URI of metadata.
    /// @param _authority Authority of license holders.
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _expiryTime,
        uint256 _maxSupplyPerLicense,
        uint256 _price,
        address _owner,
        Authority _authority,
        License _license,
        MasterNFT _masterNFT
    
    ) ERC721(
      // e.g. GEB Access
      string(abi.encodePacked(_name, " Access")),
      // at stands for access token.
      string(abi.encodePacked("at", _symbol))
    )
    Auth(_owner, _authority) {
      baseURI = _baseURI;
      totalSupply = 0;
      expiryTime = _expiryTime;
      maxSupplyPerLicense = _maxSupplyPerLicense;
      price = _price;
      license = _license;
      masterNFT = _masterNFT;
    } 
        
    /// @notice Mints a specified amount of tokens if msg sender is a license holder. 
    /// @param id - the id of the accessToken minted.
    /// @param to - the user that the accessToken is minted.
    function mint(uint256 id, address to) external returns (uint256) {
      require(msg.sender == address(license), "UNAUTHORISED_ADDRESS");
                
      _mint(to, id);
      totalSupply++;    
      return (id);

    }
    
    mapping(uint256 => uint256) private licenseHolderBalance; 
    /// @notice Buys a specified token Id.
    /// @param id Token Id of token that buyer wants to buy
    function buy(uint256 id, address user) external payable {
      
      require(id < totalSupply, "DOES_NOT_EXIST");
      require(msg.value == price, "INCORRECT_PRICE");
      require(isSold[id] == false, "ALREADY_SOLD");

      uint256 split = msg.value.mulDivDown(5, 10);
      
      isSold[id] = true;

      
      (bool masterNFTHolderPaid, ) = payable(address(masterNFT)).call{value: split}("");      
      (bool licenseHolderPaid, ) = payable(address(license)).call{value: split}("");
      
      require(masterNFTHolderPaid, "Failed to send to MasterNFT!");
      require(licenseHolderPaid, "Failed to send to license holder!");

      // Transfer token from license holder to buyer.
      // transferFrom(ownerOf(id), msg.sender, id);
      transferFrom(msg.sender, user, id);

      emit TokenSold(id, msg.sender);
    }

    function withdraw(uint256 licenseId) public {
        require(msg.sender == license.ownerOf(licenseId));
        uint amount = licenseHolderBalance[licenseId];

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = payable(license.ownerOf(licenseId)).call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    /// @notice Sets a new token expiry time.
    /// @param time New expiry time. 
    function setExpiryTime(uint256 time) requiresAuth public {
      expiryTime = time;

      emit ExpiryTimeUpdated(time);
    }
    
    /// @notice Sets a new max supply.
    /// @param supply New max supply.
    function setMaxSupply(uint256 supply) public requiresAuth {
      
      // New max supply has to be higher than current supply.
      require(totalSupply < supply, "SUPPLY_ALREADY_REACHED");
      maxSupplyPerLicense = supply;

      emit MaxSupplyUpdated(supply);
    }

    /// @notice Sets a new token price.
    /// @param newPrice New price.
    function setPrice(uint256 newPrice) public requiresAuth {
      
      price = newPrice;

      emit PriceUpdated(newPrice);
    }

    /// @notice Checks if a token has expired or not.
    /// @param id Id of token to be checked.
    function isExpired(uint256 id)
      public
      view
      returns (bool)
    {
      // require(ownerOf[id] != address(0), "TOKEN_DOES_NOT_EXIST");
      require(ownerOf(id) != address(0), "TOKEN_DOES_NOT_EXIST");

      TokenData memory token = getTokenData[id]; 

      if (block.timestamp >= token.expiryDate) {
        return true;
      }

      return false; 
    }

    /// @notice Checks if caller of the function has any unexpired access tokens.
    function hasAccess()
      public
      view
      returns (bool)
    {
      // if (balanceOf[msg.sender] == 0) {
      if (balanceOf(msg.sender) == 0) {
        return false;
      }
      
      unchecked {
        for (uint256 i = 1; i <= totalSupply; i++) {
          // if (ownerOf[i] == msg.sender && !isExpired(i)) {
          if (ownerOf(i) == msg.sender && !isExpired(i)) {
            return(true);
          }
        }
      }
  
      // Returns false if none of the tokens owned are within expiry date.
      return false;
    }

    function tokenURI(uint256 id)
        public
        view
        override
        returns (string memory)
    {
        // require(ownerOf[id] != address(0), "TOKEN_DOES_NOT_EXIST");
        require(ownerOf(id) != address(0), "TOKEN_DOES_NOT_EXIST");

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, string(abi.encodePacked(id)), ".json"))
                : "";
    }
}
