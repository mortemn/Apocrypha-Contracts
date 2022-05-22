// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth} from "solmate/auth/Auth.sol";


contract License is ERC721, Auth {

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
    /// @notice Token id of the token which was last sold.
    uint256 public lastSold;

    /// @notice Whether the Vault has been initialized yet.
    bool public isInitialized;

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

    /// @notice Gets expiry date of token.
    mapping(uint256 => uint256) public getExpiryDate;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(
      // e.g. GEB Access
      string(abi.encodePacked(_name, " License")),
      // at stands for access token
      string(abi.encodePacked("l", _symbol))
    )
    Auth(Auth(msg.sender).owner(), Auth(msg.sender).authority()) {
      baseURI = _baseURI;
      /// Sets supply to max and disable minting until initialized.
      totalSupply = type(uint256).max;
      lastSold = 1;
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
              getExpiryDate[id] = block.timestamp + expiryTime;

              totalSupply++;
          }
      }
    }

    /// @notice Buys a specified token Id.
    function buy() external payable {
      require(lastSold < totalSupply, "MAX_SUPPLY_REACHED");
      require(msg.value == price, "INCORRECT_PRICE");
      
      // allocate half the funds to contract owner and other half to license holder who minted the token.
      payable(owner).transfer(msg.value);
      
      emit TokenSold(lastSold, msg.sender);
      lastSold++;
    }

    /// @notice Checks if user has any valid licenses, returns true if they have.
    /// @param user Address of user that is checked.
    function hasValidLicense(address user)
      public
      view
      returns (bool)
    {
      // if (balanceOf[user] == 0) {
      if (balanceOf(user) == 0) {
        return false;
      }

      unchecked {
        for (uint256 i = 1; i <= totalSupply; i++) {
          // if (ownerOf[i] == user && !isExpired(i)) {
          if (ownerOf(i) == user && !isExpired(i)) {
            return(true);
          }
        }
      }
  
      // Returns false if none of the tokens owned are within expiry date.
      return false;
    }

    /// @notice Initializes the contract.
    /// @dev All critical parameters must already be set before calling.
    function initialize() external requiresAuth {
      require(!isInitialized, "ALREADY_INITIALISED");

      // Mark the Vault as initialized.
      isInitialized = true;

      totalSupply = 0;

      emit Initialized();
    }

    /// @notice Sets a new token expiry time.
    /// @param time New expiry time. 
    function setExpiryTime(uint256 time) external requiresAuth {
      expiryTime = time;

      emit ExpiryTimeUpdated(time);
    }

    /// @notice Sets a new max supply.
    /// @param supply New max supply.
    function setMaxSupply(uint256 supply) external requiresAuth {
      // If the totalSupply is at uint256 max it means that it's either not initialised yet or supply already has reached max.
      require(!isInitialized, "NOT_INITIALISED"); 
      // New max supply has to be higher than current supply.
      require(totalSupply < supply, "SUPPLY_ALREADY_REACHED");
      maxSupply = supply;

      emit MaxSupplyUpdated(supply);
    }

    /// @notice Sets a new token price.
    /// @param newPrice New price.
    function setPrice(uint256 newPrice) external requiresAuth {
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

      if (block.timestamp >= getExpiryDate[id]) {
        return true;
      }

      return false; 
    }
    
    /// TODO: return our API along with specific information about token in it e.g. expiry time.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // require(ownerOf[tokenId] != address(0), "TOKEN_DOES_NOT_EXIST");
        require(ownerOf(tokenId) != address(0), "TOKEN_DOES_NOT_EXIST");

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, string(abi.encodePacked(tokenId)), ".json"))
                : "";
    }

    /// @dev Allows contract to receive Eth.
    receive() external payable {}
}
