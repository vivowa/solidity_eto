var ConvertLib = artifacts.require("./ConvertLib.sol");
var EquityToken = artifacts.require("./EquityToken.sol");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, EquityToken);
  deployer.deploy(EquityToken);
};
