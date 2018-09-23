pragma solidity ^0.4.24;

contract Migrations {
  
  modifier onlyOwner() {
    require(msg.sender == owner, "requirement onlyOwner modifier");
    _;
  }

  constructor() public {
    owner = msg.sender;
  }
  
  address public owner;

  uint public last_completed_migration;

  // https://medium.com/@blockchain101/demystifying-truffle-migrate-21afbcdf3264
  function setCompleted(uint completed) public onlyOwner {
    last_completed_migration = completed;
  }
 
  // https://medium.com/@blockchain101/demystifying-truffle-migrate-21afbcdf3264
  function upgrade(address new_address) public onlyOwner {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
    }
}

