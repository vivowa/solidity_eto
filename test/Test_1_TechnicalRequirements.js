const EquityTokenFactory = artifacts.require("./EquityTokenFactory.sol");

const _name = "TestCompany";
const _ticker = "TCO";
const _amount = 100000;
const _nominalvalue = 3;

const _txamount = 100;

contract("TestTechnicalRequirements.js", async (accounts) => {
      
    // --- Technical Test ---   
   describe("technical pre-requirements", async () => {

    it("should call a function that depends on a linked library", async () => {
    let instance = await EquityTokenFactory.deployed();
           
    let outTokenBalance = await instance.balanceOf.call(accounts[0]);
    let equityTokenBalance = outTokenBalance.toNumber();
    let outTokenBalanceEth = await instance.getBalanceOfInEth.call(accounts[0]);
    let equityTokenBalanceEth = outTokenBalanceEth.toNumber();
    
    assert.equal(equityTokenBalanceEth, 3 * equityTokenBalance, "Library function returned unexpected function, linkage may be broken");
    });

    //@Todo: it("should deploy the correct hierachy")
    //@Todo: it("should avoid under/overflow") 
  });
})
  
 // --- EquityTokenFactory Test ---
contract("EquityTokenFactory.js", async (accounts) => {
 
    describe("correct token issuance", async () => {
           
    it("should safe issuance information on blockchain", async () => {
      let instance = await EquityTokenFactory.deployed(); 
         await instance.createEquityToken(_name, _ticker, _amount, _nominalvalue, {from: accounts[0]});

      //@dev: defines event from solidity contract, starts to watch events and prints it to console
      //@notes: result is BigNumber, toNumber() improves readability
      //@notes: result.args returns all argument objects from event
      //@notes: watches also all upcoming events of defined type 
      let event1 = instance.newTokenIssuance();
      event1.watch((error, result) => {
      if (!error)
      console.log("                 event_issuance: tokenId " + result.args.tokenId.toNumber(), "totalamount " + result.args.totalamount.toNumber(), "nominalvalue " + result.args.nominalvalue.toNumber());
      });

      let event2 = instance.newShareholder();
      event2.watch((error, result) => {
      if (!error)
      console.log("                 event_shareholder: new_address " + result.args.newShareholder, "total_length_shareholder " + result.args.length.toNumber());
      });

      /*let event3 = instance.Dividend();
      event3.watch((error, result) => {
      if (!error)
      console.log("                 event_dividend: dividend " + result.args._txpercentage.toNumber());
      });

      let event4 = instance.Transfer();
      event4.watch((error, result) => {
      if (!error)
      console.log("                 event_transfer: from " + result.args._from, "to " + result.args._to, "amount " + result.args._txamount.toNumber());
      });*/
               
      let information = await instance.getInfosEquityToken.call();
      
      assert.exists(information[0,1,2,3,4],"array null or undefined");
    });

    it("should have created a random and unique id", async () => {
        let instance = await EquityTokenFactory.deployed();           
                
        let information = await instance.getInfosEquityToken.call();
        
        assert.exists(information[0],"random and unique id missing or wrong (null or undefined)");
        //@ToDo: assert.isNumber(information[0], "random and unique id missing or wrong (datatype)");
        //@ToDo: assert.lengthOf(web3.toDecimal(information[0]), 8, "random and unique id missing or wrong (length)");
      });

    it("should have a name", async () => {
      let instance = await EquityTokenFactory.deployed(); 
               
      let information = await instance.getInfosEquityToken.call();

      assert.equal(information[1], _name,"company name missing or wrong");
    });
   
    it("should have a ticker", async () => {
      let instance = await EquityTokenFactory.deployed(); 
           
      let information = await instance.getInfosEquityToken.call();

      assert.equal(information[2], _ticker,"ticker missing or wrong");
    });

    it("should put issuing amount in the first account", async () => {
      let instance = await EquityTokenFactory.deployed();

      let balance = await instance.balanceOf.call(accounts[0]);
      assert.equal(balance.valueOf(), _amount, "specific amount wasn't in the first account");
    });
    
  });
})

// --- EquityToken Test ---  
contract("EquityToken.js", async (accounts) => {
    
  describe("corrent token characteristics & transactions", async () => {

    it("should send token correctly && should update shareholder book", async () => {
      let instance = await EquityTokenFactory.deployed();

      //@dev: event watch block to catch blockchain events in this clean state contract
      let event1 = instance.newTokenIssuance();
      event1.watch((error, result) => {
      if (!error)
      console.log("                 event_issuance: tokenId " + result.args.tokenId.toNumber(), "totalamount " + result.args.totalamount.toNumber(), "nominalvalue " + result.args.nominalvalue.toNumber());
      });

      let event2 = instance.newShareholder();
      event2.watch((error, result) => {
      if (!error)
      console.log("                 event_shareholder: new_address " + result.args.newShareholder, "total_length_shareholder " + result.args.length.toNumber());
      });

      let event3 = instance.Dividend();
      event3.watch((error, result) => {
      if (!error)
      console.log("                 event_dividend: dividend " + result.args._txpercentage.toNumber());
      });

      let event4 = instance.Transfer();
      event4.watch((error, result) => {
      if (!error)
      console.log("                 event_transfer: from " + result.args._from, "to " + result.args._to, "amount " + result.args._txamount.toNumber());
      });


      //@notes: initialises a transaction, and compares lengths of shareholder book array before and after transaction 
      await instance.createEquityToken(_name, _ticker, _amount, _nominalvalue, {from: accounts[0]});
      
      const account_one = accounts[0];
      const account_two = accounts[1];
     
      let balance = await instance.balanceOf.call(account_one);
      let account_one_starting_balance = balance.toNumber();

      balance = await instance.balanceOf.call(account_two);
      let account_two_starting_balance = balance.toNumber();

      let shareholder_starting_length = await [instance.getAllAddressesEquityToken.call()].length;
      
      await instance.transfer(account_two, _txamount, {from: account_one});

      balance = await instance.balanceOf.call(account_one);
      let account_one_ending_balance = balance.toNumber();

      balance = await instance.balanceOf.call(account_two);
      let account_two_ending_balance = balance.toNumber();

      let shareholder_ending_length = await [instance.getAllAddressesEquityToken.call()].length;
    
        assert.equal(account_one_ending_balance, account_one_starting_balance - _txamount, "Amount wasn't correctly taken from the sender");
        assert.equal(account_two_ending_balance, account_two_starting_balance + _txamount, "Amount wasn't correctly sent to the receiver");
        assert.equal(shareholder_ending_length, shareholder_starting_length + 1, "Shareholder book not updated");
      });


        it("should execute transferFrom & allowance & approval transfer correctly", async () => {
     

    });

      it("should have shareholder book", async () => {
      let instance = await EquityTokenFactory.deployed();
                
      let information = await [instance.getAllAddressesEquityToken.call()];
      
      assert.exists(information,"array null or undefined");
      });

      
      //@devs: takes the transaction of before, then pays the dividend to second account
      it("should send dividends && only for company owner", async () => {
      let instance = await EquityTokenFactory.deployed();
            
      const account_one = accounts[0];
      const account_two = accounts[1];
     
      const _testdividend = 3;

      let balance = await instance.balanceOf.call(account_one);
      let account_one_starting_balance = balance.toNumber();

      balance = await instance.balanceOf.call(account_two);
      let account_two_starting_balance = balance.toNumber();
      
      await instance.payDividend(_testdividend, {from: accounts[0]});
      
      //@devs: if operation possbile test would fail twice: a) double the dividend would have been payed b) two events would be fired and watched by JS
      //await instance.payDividend(_testdividend, {from: accounts[1]});

      balance = await instance.balanceOf.call(account_one);
      let account_one_ending_balance = balance.toNumber();

      balance = await instance.balanceOf.call(account_two);
      let account_two_ending_balance = balance.toNumber();
    
        assert.equal(account_one_ending_balance, account_one_starting_balance - (_testdividend * _txamount), "Amount wasn't correctly taken from the sender");
        assert.equal(account_two_ending_balance, account_two_starting_balance + (_testdividend * _txamount), "Amount wasn't correctly sent to the receiver");
        

      });
    });
})