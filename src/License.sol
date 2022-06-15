// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {ERC721} from "solmate/tokens/ERC721.sol";
<<<<<<< HEAD
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {Owned} from "solmate/auth/Owned.sol";


=======
import {Owned} from "solmate/auth/Owned.sol";

>>>>>>> df7dba1aa062c4828536feb9db16898bf2192b60
contract License is ERC721, Owned {

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

    /// @notice Gets expiry date of token.
    mapping(uint256 => uint256) public getExpiryDate;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _expiryTime,
        uint256 _maxSupply,
<<<<<<< HEAD
        uint256 _price,
        address _author
=======
        uint256 _price
>>>>>>> df7dba1aa062c4828536feb9db16898bf2192b60
    ) ERC721(
      // e.g. GEB Access
      string(abi.encodePacked(_name, " License")),
      // at stands for access token
      string(abi.encodePacked("l", _symbol))
<<<<<<< HEAD
    )
    Owned(_author) {
=======
    ) Owned(msg.sender) { // the Auth(msg.sender) assumes msg.sender is a contract, and is communicating with it through the Auth interface
>>>>>>> df7dba1aa062c4828536feb9db16898bf2192b60
      baseURI = _baseURI;
      lastSold = 1;
      totalSupply = 0;
      expiryTime = _expiryTime;
      maxSupply = _maxSupply;
      price = _price;
    } 


    /// @notice Mints a specified amount of tokens if msg sender is a license holder. 
    /// @param amount Amount of tokens to be minted.
    function mint(uint256 amount) external onlyOwner {
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
      // require(msg.value => price, "INCORRECT_PRICE");
      
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

    

    /// @notice Sets a new token expiry time.
    /// @param time New expiry time. 
<<<<<<< HEAD
    function setExpiryTime(uint256 time) external onlyOwner {
=======
    function setExpiryTime(uint256 time) external {
>>>>>>> df7dba1aa062c4828536feb9db16898bf2192b60
      expiryTime = time;

      emit ExpiryTimeUpdated(time);
    }

    /// @notice Sets a new max supply.
    /// @param supply New max supply.
<<<<<<< HEAD
    function setMaxSupply(uint256 supply) external onlyOwner {
=======
    function setMaxSupply(uint256 supply) external {
>>>>>>> df7dba1aa062c4828536feb9db16898bf2192b60
      // New max supply has to be higher than current supply.
      require(totalSupply < supply, "SUPPLY_ALREADY_REACHED");
      maxSupply = supply;

      emit MaxSupplyUpdated(supply);
    }
    
    function getMaxSupply() public view returns (uint256 supply) {
      return maxSupply;
    }

    /// @notice Sets a new token price.
    /// @param newPrice New price.
<<<<<<< HEAD
    function setPrice(uint256 newPrice) external onlyOwner {
=======
    function setPrice(uint256 newPrice) external {
>>>>>>> df7dba1aa062c4828536feb9db16898bf2192b60
      price = newPrice;

      emit PriceUpdated(newPrice);
    }

    function getPrice() public view returns (uint256) {
      return price;
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


    function checkExpiryDate(uint256 id) public view returns (uint256) {
      uint256 expiryDate = getExpiryDate[id];
      return expiryDate;
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(ownerOf(tokenId) != address(0), "TOKEN_DOES_NOT_EXIST");

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, string(abi.encodePacked(tokenId)), ".json"))
                : "";
    }

    /// @dev Allows contract to receive Eth.
    receive() external payable {}

    function changeFlag() public onlyOwner returns (bool) {
      return (true);
    }
}
