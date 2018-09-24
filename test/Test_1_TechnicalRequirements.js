const EquityTokenFactory = artifacts.require("./EquityTokenFactory.sol");

contract('TestTechnicalRequirements.js', async (accounts) => {
    
    // --- Technical Test ---   
   describe("technical pre-requirements", async () => {

    it("should call a function that depends on a linked library", async () => {
    let instance = await EquityTokenFactory.deployed();
    let outTokenBalance = await (instance.getBalance.call(accounts[0]));
    let equityTokenBalance = outTokenBalance.toNumber();
    let outTokenBalanceEth = await (instance.getBalance.call(accounts[0]));
    let equityTokenEthBalance = outTokenBalanceEth.toNumber();
      assert.equal(equityTokenEthBalance, 2 * equityTokenBalance, "Library function returned unexpected function, linkage may be broken");
    });

    //@Todo: it("should deploy the correct hierachy")
    //@Todo: it("should avoid under/overflow") 
  });
  
  // --- EquityTokenFactory Test ---
    describe("correct token issuance", async () => {
      const _name = "TestCompany";
      const _ticker = "TCO";
      const _amount = 10000;
      const _nominalvalue = 7;
      const _indexEquityTokenInArray = 0;
      
      
    it("should safe issuance information on blockchain", async () => {
      let instance = await EquityTokenFactory.deployed(); 
         await instance.createEquityToken(_name, _ticker, _amount, _nominalvalue, {from: accounts[0]});
      
      //@dev: defines event from solidity contract, starts to watch events and prints it to console
      //@notes: result is BigNumber, toNumber() improves readability
      //@notes: result.args returns all argument objects from event
      //@notes: watches also all upcoming events of defined type 
      let event = instance.newTokenIssuance();
      event.watch((error, result) => {
      if (!error)
      console.log("event: tokenId " + result.args.tokenId.toNumber(), "totalamount " + result.args.totalamount.toNumber(), "nominalvalue " + result.args.nominalvalue.toNumber());
      });
          
      let information = await instance.getInfosEquityToken(_indexEquityTokenInArray, {from: accounts[0]});
      
      assert.exists(information[0,1,2,3,4],"array null or undefined");
    });

    it("should have created a random and unique id", async () => {
        let instance = await EquityTokenFactory.deployed(); 
          await instance.createEquityToken(_name, _ticker, _amount, _nominalvalue, {from: accounts[0]});
                
        let information = await instance.getInfosEquityToken(_indexEquityTokenInArray, {from: accounts[0]});
        
        assert.exists(information[0],"random and unique id missing or wrong (null or undefined)");
        //@ToDo: assert.isNumber(information[0], "random and unique id missing or wrong (datatype)");
        //@ToDo: assert.lengthOf(web3.toDecimal(information[0]), 8, "random and unique id missing or wrong (length)");
      });

    it("should have a name", async () => {
      let instance = await EquityTokenFactory.deployed(); 
          await instance.createEquityToken(_name, _ticker, _amount, _nominalvalue, {from: accounts[0]});
     
      let information = await instance.getInfosEquityToken(_indexEquityTokenInArray, {from: accounts[0]});

      assert.equal(information[1], _name,"company name missing or wrong");
    });
   
    it("should have a ticker", async () => {
      let instance = await EquityTokenFactory.deployed(); 
          await instance.createEquityToken(_name, _ticker, _amount, _nominalvalue, {from: accounts[0]});
  
      let information = await instance.getInfosEquityToken(_indexEquityTokenInArray, {from: accounts[0]});

      assert.equal(information[2], _ticker,"ticker missing or wrong");
    });

    it("should put issuing amount in the first account", async () => {
      let instance = await EquityTokenFactory.deployed();
      let balance = await instance.getBalance.call(accounts[0]);
      assert.equal(balance.valueOf(), _amount, "specific amount wasn't in the first account");
    });
    
  });

  // --- EquityToken Test ---
  describe("corrent token transactions", async ()=> {

    it("should track total distribution", async () => {
      let instance = await EquityTokenFactory.deployed();
      await instance.createEquityToken(_name, _ticker, _amount, _nominalvalue, {from: accounts[0]});
      

      let information = await instance.getDistributionEquityToken(_indexEquityTokenInArray, {from: accounts[0]});
      
      assert.exists(information[0,1,2],"array null or undefined");
    });

    it("should send token correctly + update total distribution after token transaction", async () => {
      let instance = await EquityTokenFactory.deployed();
    
      const account_one = accounts[0];
      const account_two = accounts[1];

      let _amount = 10;

      let balance = await instance.getBalance.call(account_one);
      let account_one_starting_balance = balance.toNumber();

      balance = await instance.getBalance.call(account_two);
      let account_two_starting_balance = balance.toNumber();
      
      await instance.sendToken(account_two, _amount, {from: account_one});

      balance = await instance.getBalance.call(account_one);
      let account_one_ending_balance = balance.toNumber();

      balance = await instance.getBalance.call(account_two);
      let account_two_ending_balance = balance.toNumber();
    
        assert.equal(account_one_ending_balance, account_one_starting_balance - _amount, "Amount wasn't correctly taken from the sender");
        assert.equal(account_two_ending_balance, account_two_starting_balance + _amount, "Amount wasn't correctly sent to the receiver");
        
      //assert.equal


    });

   

  });     
})