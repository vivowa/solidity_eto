var ConvertLib = artifacts.require("./ConvertLib.sol");
var EquityTokenFactory = artifacts.require("./EquityTokenFactory.sol")
var EquityToken = artifacts.require("./EquityToken.sol");
var EquityTokenTrading = artifacts.require("./EquityTokenTrading.sol");
var TokenBusinessLayer = artifacts.require("./TokenBusinessLayer.sol");
var TokenLevelGovernance = artifacts.require("./TokenLevelGovernance.sol");
var TokenProcessingLayer = artifacts.require("./TokenProcessingLayer.sol");

// @Dev: deploys all contracts and links the hierachie
module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, EquityTokenFactory);
  deployer.link(ConvertLib, EquityToken);
  deployer.link(ConvertLib, EquityTokenTrading);
  deployer.link(ConvertLib, TokenBusinessLayer);
  deployer.link(ConvertLib, TokenLevelGovernance);
  deployer.link(ConvertLib, TokenProcessingLayer);
  deployer.deploy(EquityTokenFactory);
  deployer.link(EquityTokenFactory, EquityToken);
  deployer.link(EquityTokenFactory, TokenBusinessLayer);
  deployer.link(EquityTokenFactory, TokenLevelGovernance);
  deployer.link(EquityTokenFactory, TokenProcessingLayer);
  deployer.deploy(EquityToken);
  deployer.link(EquityToken, TokenBusinessLayer);
  deployer.link(EquityToken, TokenLevelGovernance);
  deployer.link(EquityToken, TokenProcessingLayer);
  deployer.deploy(EquityTokenTrading);
  deployer.deploy(TokenBusinessLayer);
  deployer.deploy(TokenLevelGovernance);
  deployer.deploy(TokenProcessingLayer);
};
