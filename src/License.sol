// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {MasterNFT} from "./MasterNFT.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {AccessToken} from "./AccessToken.sol";



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
    MasterNFT masterNFT;
    AccessToken public accessToken;
    

    /// @notice Struct of license data.
    /// @param expiryDate Date where license expires.
    /// @param minter Address of license holder who minted the token.
    struct LicenseData {
      uint256   expiryDate;
      address   minter;
      uint256   accessTokenMaxSupply;
      uint256[]  accessTokensHeld;
    }

    struct TokenData {
      uint256 expiryDate;
      address minter;
      uint256 licenseId;
    }

    function getAccessToken(uint256 licenseId, uint256 index) view public returns (uint256 id) {
      uint256[] memory accessTokensHeld = getLicenseData[licenseId].accessTokensHeld;
      uint256 tokenId = accessTokensHeld[index];
      return tokenId;
    }

    function getAmountLeft(uint256 licenseId) view public returns (uint256 amountLeft) {
      uint256[] memory accessTokensHeld = getLicenseData[licenseId].accessTokensHeld;
      amountLeft = accessTokensHeld.length;
      return amountLeft;
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

    event Log(string func, address sender, uint256 value, bytes data);

    event AccessTokenSet (AccessToken accessToken); 

    /// @notice Maps id to struct that holds info of it.
    mapping(uint256 => LicenseData) public getLicenseData;

    mapping(uint256 => uint256) public licenseToAccessTokenBalance;

    mapping(uint256 => bool) public licenseUsed;

    mapping(uint256 => TokenData) public getTokenData;


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _expiryTime,
        uint256 _maxSupply,
        uint256 _price,
        address _owner,
        Authority _authority,
        MasterNFT _masterNFT
    ) ERC721(
      // e.g. GEB Access
      string(abi.encodePacked(_name, " License")),
      // at stands for access token
      string(abi.encodePacked("l", _symbol))
    ) Auth(_owner, _authority) {
    
      baseURI = _baseURI;
      lastSold = 1;
      totalSupply = 0;
      expiryTime = _expiryTime;
      maxSupply = _maxSupply;
      price = _price;
      masterNFT = _masterNFT;
    } 
    

    function setAccessToken(AccessToken _accessToken) public {
      require(msg.sender == owner, "NOT_OWNER");
      accessToken = _accessToken;
      emit AccessTokenSet(accessToken);
    }
    
    function mintAccessTokens (uint256 licenseId) public {

      require(msg.sender == ownerOf(licenseId), "NOT_OWNER_OF_LICENSEID");
      require(licenseUsed[licenseId] != true, "LICENSE_ALREADY_USED");
  
      uint256[] memory accessTokensHeld = new uint256[](accessToken.maxSupplyPerLicense());
      // uint256[] storage accessTokensHeld;

      unchecked {

          uint256 accessTokensToBeMinted = accessToken.maxSupplyPerLicense();

          for (uint256 i = 0; i < accessTokensToBeMinted; i++ ) {
              
              uint256 id = accessToken.mint(licenseId, address(this));
              
              accessTokensHeld[i] = id;
          }
      }
      getLicenseData[licenseId].accessTokensHeld = accessTokensHeld;
      licenseToAccessTokenBalance[licenseId] = accessToken.maxSupplyPerLicense();
      licenseUsed[licenseId] = true; 
    }

    function buyAccessToken(uint256 licenseId) payable public {
      
      uint256[] storage accessTokensHeld = getLicenseData[licenseId].accessTokensHeld;
      uint256 id = accessTokensHeld[accessTokensHeld.length-1];

      accessToken.buy{value: msg.value}(id, msg.sender);
      accessTokensHeld.pop();

      getLicenseData[licenseId].accessTokensHeld = accessTokensHeld;
      withdrawableBalance[licenseId] += msg.value/2;
    }

    mapping (uint256 => uint256) public withdrawableBalance;


    function withdraw(uint256 licenseId) public {

        require(msg.sender == ownerOf(licenseId), "NOT_OWNER_OF_LICENSE");

        // get the amount of Ether stored in this contract
        uint amount = withdrawableBalance[licenseId];

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = ownerOf(licenseId).call{value: amount}("");
        require(success, "Failed to send Ether");
        withdrawableBalance[licenseId] = 0;
    }
    

    /// @notice Mints a specified amount of licenses if msg sender is a masterNFT holder. 
    /// @param amount Amount of Licenses to be minted.
    function mint(uint256 amount) public requiresAuth {
      require(totalSupply + amount <= maxSupply, "MAX_SUPPLY_REACHED");

      // Won't overflow (New total supply is less than max supply)
      unchecked {
          for (uint256 i = 0; i < amount; i++) {
              uint256 id = totalSupply;
              _mint(msg.sender, id);

              // Sets expiry date and address of minter.
              getLicenseData[id].expiryDate = block.timestamp + expiryTime;
              getLicenseData[id].minter = msg.sender;
              getLicenseData[id].accessTokenMaxSupply;
              
              totalSupply++;
          }
      }
    }
    
    /// @notice Buys a specified token Id.
    function buy(uint256 licenseId) external payable {

      require(lastSold <= totalSupply, "MAX_SUPPLY_REACHED");
      require(msg.value == price, "INCORRECT_PRICE");
      require(isSold[licenseId] == false, "ALREADY_SOLD");

      (bool sent, ) = payable(address(masterNFT)).call{value:msg.value}("");

      require(sent, "Failed to send Ether!");

      transferFrom(ownerOf(licenseId), msg.sender, licenseId);
      emit TokenSold(lastSold, msg.sender);
        
      lastSold++;
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 licenseId
    ) public override {
        require(from == _ownerOf[licenseId], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[licenseId],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[licenseId] = to;

        delete getApproved[licenseId];
        
        emit Transfer(from, to, licenseId);
    }


    /// @notice Checks if user has any valid licenses, returns true if they have.
    /// @param user Address of user that is checked.
    function hasValidLicense(address user)
      public
      view
      returns (bool)
    {
      
      if (balanceOf(user) == 0) {
        return false;
      }

      unchecked {
        for (uint256 i = 0; i < totalSupply; i++) {
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
    function setExpiryTime(uint256 time) public requiresAuth {
      expiryTime = time;

      emit ExpiryTimeUpdated(time);
    }

    /// @notice Sets a new max supply.
    /// @param supply New max supply.
    function setMaxSupply(uint256 supply) public requiresAuth {
      // New max supply has to be higher than current supply.
      require(totalSupply < supply, "SUPPLY_ALREADY_REACHED");
      maxSupply = supply;

      emit MaxSupplyUpdated(supply);
    }
    
    // function getMaxSupply() public view returns (uint256 supply) {
    //   return maxSupply;
    // }

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

      if (block.timestamp >= getLicenseData[id].expiryDate) {
        return true;
      }

      return false; 
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

    receive() external payable {
      emit Log("receive", msg.sender, msg.value, ""); 
    }

    fallback() external payable {
      emit Log("fallback", msg.sender, msg.value, msg.data);
    }
}
