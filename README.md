Tech Stack Used:
* Flask==2.2.3 
* MongoDB
* Solidity
* Ethereum Blockchain
* Truffle
* Ganache
* Metamask

**Installation:**
The following installation commands are for Ubuntu 20.04.

Clone the repository:

git clone https://github.com/Ultracol2906/LandRegistry_Blockchain.git
Install Ganache.

Install MongoDB & Run it.

Add Metamask to your browser

Deploy Smart Contracts

5.1 Open the Ganache & Create a local Ethereum block chain.

5.2 Navigate to Smart_contracts folder and open truffle-config.js file.

5.3 Set Ganache server configuration

module.exports = {

   networks: {
   
      development: {
         host: "<Host address on which ganache running>",  // Default: localhost
         port: <Port on which ganache running>,            // Default: 7545
         network_id: "*",      
      },
   }
}          
5.4 Compile & deploy the contracts to block chaing

cd Smart_contracts/
truffle migrate
Note down account used for deploying, which looks similar to the following.
Install dependencies:

6.1 Create python's virtual environment

python3 -m venv <env_name>
6.2 Activate the virtual environment

source <env_name>/bin/activate
6.3 Install Required libraries

pip install -r python_package_requirements.txt
Deploy the Sever for Govt portal

7.1 Navigate to Server_For_Revenue_Dept folder

cd Server_For_Revenue_Dept/
7.2 Open config.json file & Set the configuration with nano or text editor.

{

   "Ganache_Url" : "<Ganache RPC Server URL>",  // default: http://127.0.0.1:7545

   "NETWORK_CHAIN_ID": <Ganache Network ID>,    // default: 5777

   "Mongo_Db_Url": "MongoDB Server URL"        //  default: mongodb://localhost:27017

   "Secret_Key": "<Set Random Security Key for flask server>",

   "Address_Used_To_Deploy_Contract": "<Account used to deploy the contracts>",

   "Admin_Password": "<Password for higher govt authority>" // default: 12345678
}
7.3 Activate the virtual environment you created in a separate terminal

source <env_name>/bin/activate
7.4 Run the flask server

python3 app.py
Deploy the Server for User portal

8.1 Activate the virtual environment you created in a separate terminal

source <env_name>/bin/activate
8.2 Navigate to Server_For_Users folder

cd Server_For_Users/
8.3 Run the flask server

python3 app.py
