var ConvertLib = artifacts.require("./ConvertLib.sol");
var SafeMath = artifacts.require("./SafeMath.sol");
var EquityTokenFactory = artifacts.require("./EquityTokenFactory.sol")

// @Dev: deploys all contracts and links the hierachie
module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.deploy(SafeMath);
  deployer.link(ConvertLib, EquityTokenFactory);
  deployer.link(SafeMath, EquityTokenFactory);
  deployer.deploy(EquityTokenFactory);
  };
