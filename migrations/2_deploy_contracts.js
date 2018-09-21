var ConvertLib = artifacts.require("./ConvertLib.sol");
var EquityTokenFactory = artifacts.require("./EquityTokenFactory.sol")
var EquityToken = artifacts.require("./EquityToken.sol");

// deploys all contracts and links the hierachie
module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, EquityTokenFactory);
  deployer.link(ConvertLib, EquityToken);
  deployer.deploy(EquityTokenFactory);
  deployer.link(EquityTokenFactory, EquityToken);
  deployer.deploy(EquityToken);
};
