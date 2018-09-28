module.exports = {
		networks: {
		    development: {
		      host: "127.0.0.1",
		      port: 8545,
					network_id: "*", // Match any network id
					gas: 0xfffffffff,
					gasprice: 1,
		    }
		  }
};
