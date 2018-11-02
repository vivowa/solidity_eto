var ConvertLib = artifacts.require("./ConvertLib.sol");
var SafeMath = artifacts.require("./SafeMath.sol");
var EquityTokenFactory = artifacts.require("./EquityTokenFactory.sol")
var EquityToken = artifacts.require("./EquityToken.sol")
var EquityTokenTransaction = artifacts.require("./EquityTokenTransaction.sol")
var EquityTokenTransactionHelper = artifacts.require("./EquityTokenTransaction.sol")

// @Dev: deploys all contracts and links the hierachie
module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.deploy(SafeMath);
  deployer.link(SafeMath, EquityTokenFactory);
  deployer.deploy(EquityTokenFactory);
  deployer.link(ConvertLib, EquityToken);
  deployer.link(SafeMath, EquityToken);
  deployer.link(EquityTokenFactory, EquityToken);
  deployer.deploy(EquityToken);
  deployer.link(ConvertLib, EquityTokenTransaction);
  deployer.link(SafeMath, EquityTokenTransaction);
  deployer.link(EquityTokenFactory, EquityTokenTransaction);
  deployer.link(EquityToken, EquityTokenTransaction);
  deployer.deploy(EquityTokenTransaction);
  deployer.link(ConvertLib, EquityTokenTransactionHelper);
  deployer.link(SafeMath, EquityTokenTransactionHelper);
  deployer.link(EquityTokenFactory, EquityTokenTransactionHelper);
  deployer.link(EquityToken, EquityTokenTransactionHelper);
  deployer.link(EquityTokenTransaction, EquityTokenTransactionHelper);
  deployer.deploy(EquityTokenTransactionHelper);
  
  };
