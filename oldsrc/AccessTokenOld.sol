// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract AccessToken is ERC721, Auth {
    using FixedPointMathLib for uint256;


    /*//////////////////////////////////////////////////////////////
                              CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    string public baseURI;
    /// @notice Amount of time before token expires.
    uint256 public expiryTime;
    /// @notice Max supply of token.
    uint256 public maxSupply;
    /// @notice Price of token.
    uint256 public price;
    /// @notice Total supply of token.
    uint256 public totalSupply;

    /// @notice Whether the Vault has been initialized yet.
    bool public isInitialized;

    /// @notice Struct of token data.
    /// @param expiryDate Date where token expires.
    /// @param minter Address of license holder who minted the token.
    struct TokenData {
      uint256 expiryDate;
      address minter;
    }

    /// @notice Checks if token is sold or not. 
    mapping(uint256 => bool)isSold;

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

    /// @notice Emitted after the contract is initialized. 
    event Initialized();

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
        Authority _authority
    ) ERC721(
      // e.g. GEB Access
      string(abi.encodePacked(_name, " Access")),
      // at stands for access token.
      string(abi.encodePacked("at", _symbol))
    )
    Auth(Auth(msg.sender).owner(), _authority) {
      baseURI = _baseURI;
      /// Sets supply to max and disable minting until initialized.
      totalSupply = type(uint256).max;
    } 

    /// @notice Mints a specified amount of tokens if msg sender is a license holder. 
    /// @param amount Amount of tokens to be minted.
    function mint(uint256 amount) external requiresAuth {
      require(totalSupply + amount <= maxSupply, "MAX_SUPPLY_REACHED");

      // Won't overflow (New total supply is less than max supply)
      unchecked {
          for (uint256 i = 0; i < amount; i++) {
              uint256 id = totalSupply + 1;
              _mint(msg.sender, id);

              // Sets expiry date and address of minter.
              getTokenData[id].expiryDate = block.timestamp + expiryTime;
              getTokenData[id].minter = msg.sender;

              totalSupply++;
          }
      }
    }

    /// @notice Buys a specified token Id.
    /// @param id Token Id of token that buyer wants to buy
    function buy(uint256 id) external payable {
      require(id < totalSupply, "DOES_NOT_EXIST");
      require(msg.value == price, "INCORRECT_PRICE");
      require(isSold[id] == false, "ALREADY_SOLD");

      uint256 split = msg.value.mulDivDown(5, 10);
      
      // allocate half the funds to contract owner and other half to license holder who minted the token.
      payable(owner).transfer(split);
      payable(getTokenData[id].minter).transfer(split);
      
      // Transfer token from license holder to buyer.
      transferFrom(getTokenData[id].minter, msg.sender, id);
      isSold[id] = true;

      emit TokenSold(id, msg.sender);
    }
    

    /// @notice Sets a new token expiry time.
    /// @param time New expiry time. 
    function setExpiryTime(uint256 time) external {
      require(msg.sender == owner, "NOT_OWNER");
      expiryTime = time;

      emit ExpiryTimeUpdated(time);
    }

    /// @notice Sets a new max supply.
    /// @param supply New max supply.
    function setMaxSupply(uint256 supply) external {
      require(msg.sender == owner, "NOT_OWNER");
      // If the totalSupply is at uint256 max it means that it's either not initialised yet or supply already has reached max.
      require(!isInitialized, "NOT_INITIALISED"); 
      // New max supply has to be higher than current supply.
      require(totalSupply < supply, "SUPPLY_ALREADY_REACHED");
      maxSupply = supply;

      emit MaxSupplyUpdated(supply);
    }

    /// @notice Sets a new token price.
    /// @param newPrice New price.
    function setPrice(uint256 newPrice) external {
      require(msg.sender == owner, "NOT_OWNER");
      price = newPrice;

      emit PriceUpdated(newPrice);
    }

    /// @notice Initializes the contract.
    /// @dev All critical parameters must already be set before calling.
    function initialize() external {
      require(msg.sender == owner, "NOT_OWNER");
      require(!isInitialized, "ALREADY_INITIALISED");

      // Mark the Vault as initialized.
      isInitialized = true;

      totalSupply = 0;

      emit Initialized();
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

    /// TODO: return our API along with specific information about token in it e.g. expiry time.
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

    /// @dev Allows contract to receive Eth.
    receive() external payable {}
}
