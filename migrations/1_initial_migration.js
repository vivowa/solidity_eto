var Migrations = artifacts.require("./Migrations.sol");

// First step, requires Migrations.sol and deploys contract
module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
