pragma solidity ^0.4.24;

contract Migrations {
  event upgradedMigrationOwner(address previousOwner, address newOwner);

  modifier onlyOwner() {
    require(msg.sender == owner, "requirement onlyOwner modifier");
    _;
  }

  constructor() public {
    owner = msg.sender;
  }
  
  address public owner;
  uint public last_completed_migration;

  // number for instantiation
  function setCompleted(uint completed) public onlyOwner {
    last_completed_migration = completed;
  }
 
  // allows to upgrade address and fires event
  function upgrade(address new_address) public onlyOwner {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
    emit upgradedMigrationOwner(owner, new_address);
  }
}

