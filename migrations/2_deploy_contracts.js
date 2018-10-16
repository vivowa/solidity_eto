var ConvertLib = artifacts.require("./ConvertLib.sol");
var SafeMath = artifacts.require("./SafeMath.sol");
var EquityTokenFactory = artifacts.require("./EquityTokenFactory.sol")
var EquityToken = artifacts.require("./EquityToken.sol");
var EquityTokenTrading = artifacts.require("./EquityTokenTrading.sol")

// @Dev: deploys all contracts and links the hierachie
module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.deploy(SafeMath);
  deployer.link(ConvertLib, EquityTokenFactory);
  deployer.link(SafeMath, EquityTokenFactory);
  deployer.link(ConvertLib, EquityToken);
  deployer.link(ConvertLib, EquityTokenTrading);
  deployer.deploy(EquityTokenFactory);
  deployer.link(EquityTokenFactory, EquityToken);
  deployer.deploy(EquityToken);
};
