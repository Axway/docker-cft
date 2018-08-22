### Transfer CFT 3.3.2
	
#### Prerequisites

- Docker version >= 17.11
- Docker-compose version >= 1.17.0

#### Starting CFT

1) To start CFT, run 

   `docker-compose up`

#### Stopping CFT

Stop the containers using the following command (from the folder where docker-compose.yml file is located)
 
   `docker-compose down -v`

#### Parameters

| **Parameter** | **Description** |
| ------------- | --------------- |
| CFT_FQDN | Host Address of the local server |
| CFT_INSTANCE_ID | Name of this instance of CFT |
| CFT_INSTANCE_GROUP | Group of this instance of CFT |
| CFT_CATALOG_SIZE | Catalog size |
| CFT_COM_SIZE | Communication file size |
| CFT_PESIT_PORT | Port number of the PESiT protocol named PESITANY |
| CFT_COMS_PORT | Port number of the synchronous communication media named COMS |
| CFT_COPILOT_PORT | Port number for the Transfer CFT UI server that listens for incoming unsecured and secured (SSL) connections. |
| CFT_COPILOT_CG_PORT | Port number for the Transfer CFT UI server that is used to connect to CG. |
| CFT_RESTAPI_PORT | Port number used to connect to the REST API server |
| CFT_CG_ENABLE | Cconnectivity with Central Governance |
| CFT_CG_HOST | Host address of the Central Governance server |
| CFT_CG_PORT | Central Governance port on which the connector will connect to |
| CFT_CG_SHARED_SECRET | Shared secret needed to register to Central Governance server |
| CFT_JVM | Amount of memory that the Secure Ralay JVM will be able to use |
| CFT_KEY | Where to find the file that contains CFT key |
| CFT_CFTDIRRUNTIME | Where should be placed the CFT runtime |
