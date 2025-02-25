
pragma solidity >=0.4.22 <0.9.0;


import "./Properties.sol";
import "./LandRegistry.sol";

contract TransferOwnerShip{

    


    Property private propertiesContract;
    LandRegistry private LandRegistryContract;



    constructor(address _landRegistryContractAddress){

        LandRegistryContract = LandRegistry(_landRegistryContractAddress);
        
        address propertiesContractAddress = LandRegistryContract.getPropertiesContract();  
        propertiesContract = Property(propertiesContractAddress);

        LandRegistryContract.setTransferOwnershipContractAddress(address(this));
    }
   

    
    


    enum SaleState {
        Active,  
        AcceptedToABuyer,
        CancelSaleBySeller,
        Success,
        DeadlineOverForPayment,
        CancelAcceptanceRequestGivenBySeller,
        RejectedAcceptanceRequestByBuyer

    }


    enum RequestedUserToASaleState {
        SentPurchaseRequest,
        CancelPurchaseRequest,

        SellerAcceptedPurchaseRequest,
        SellerRejectedPurchaseRequest,

        SellerCanceledAcceptanceRequest,
        YouRejectedAcceptanceRequest,

        ReRequestedPurchaseRequest,

        SuccessfullyTransfered
    }





    struct RequestedUser {
            address user;
            uint256 priceOffered;
            RequestedUserToASaleState state;
    }


    struct Sales {
        uint256 saleId;
        address owner;
        uint256 price;
        uint256 propertyId;
        address acceptedFor;
        uint256 acceptedPrice;
        uint256 acceptedTime;
        uint256 deadlineForPayment;
        bool paymentDone;
        SaleState state;
    }


    Sales[] private sales;



    mapping(address => uint256[]) private salesOfOwner;

    mapping(address => uint256[]) public requestedSales;


    mapping(uint256 => RequestedUser[]) requestedUsers;
        

    mapping(uint256 => uint256[]) private propertiesOnSaleByLocation;




    event PropertyOnSale(address indexed owner, uint256 indexed propertyId, uint256 saleId);

    event PurchaseRequestSent(uint256 saleId, address requestedUser, uint256 priceOffered);

    event SaleAccepted(uint256 saleId, address buyer, uint256 price, uint256 deadline);



    function convertToWei(uint256 etherValue) public pure returns (uint256) {
        return etherValue * 1 ether;
    }



    function addPropertyOnSale(
        uint256 _propertyId,
        uint256 _price
        ) public {
        
        require(msg.sender == propertiesContract.getLandDetailsAsStruct(_propertyId).owner, "Only the owner can put the property on sale.");


        uint256[] storage propertiesOnSale = propertiesOnSaleByLocation[propertiesContract.getLandDetailsAsStruct(_propertyId).locationId];
        
        propertiesOnSale.push(sales.length);


        _price = convertToWei(_price);

        Sales memory newSale = Sales({
            saleId: sales.length,
            owner: msg.sender,
            price: _price,
            propertyId: _propertyId,
            acceptedFor: address(0),
            acceptedPrice: 0,
            acceptedTime: 0,
            deadlineForPayment: 0,
            paymentDone : false,
            state : SaleState.Active

        });

        sales.push(newSale);




        salesOfOwner[msg.sender].push(newSale.saleId);

        propertiesContract.changeStateToOnSale(_propertyId, msg.sender);

        emit PropertyOnSale(msg.sender, _propertyId, newSale.saleId);
    }



    function getMySales(
        address _owner
        ) public view returns (Sales[] memory) {

        uint256[] memory saleIds = salesOfOwner[_owner];
        Sales[] memory ownerSales = new Sales[](saleIds.length);

        for (uint256 i = 0; i < saleIds.length; i++) {
            ownerSales[i] = sales[saleIds[i]];
        }

        return ownerSales;
    }



    function getRequestedUsers(
        uint256 saleId
        ) public view returns (RequestedUser[] memory) {
        return requestedUsers[saleId];
    }

    function getRequestedSales(
        address _owner
        ) public view returns (Sales[] memory) {

        uint256[] memory saleIds = requestedSales[_owner];
        Sales[] memory myRequestedSales = new Sales[](saleIds.length);

        for (uint256 i = 0; i < saleIds.length; i++) {
            myRequestedSales[i] = sales[saleIds[i]];
        }

        return myRequestedSales;
    }



    function getStatusOfPurchaseRequest(
        uint256 _saleId
        ) public view returns (RequestedUser memory) {


        bool buyerFound = false;
        uint i = 0;
        for (i = 0; i < requestedUsers[_saleId].length; i++) 
        {
            if (requestedUsers[_saleId][i].user == msg.sender) {
                buyerFound = true;
                break;
            }
        }


        if(buyerFound == true){
            return (RequestedUser({
                user:requestedUsers[_saleId][i].user,
                priceOffered:requestedUsers[_saleId][i].priceOffered, 
                state:requestedUsers[_saleId][i].state
            }));
        }
        else
        {
            return (RequestedUser({
                user:address(0),
                priceOffered:0, 
                state:RequestedUserToASaleState.SentPurchaseRequest
            }));
        }
        

    }


    function getSalesByLocation(
        uint256 locationId
        ) public view returns (Sales[] memory) {
        
            uint256[] memory saleIds = propertiesOnSaleByLocation[locationId];
            
            Sales[] memory salesGoingOnThisLocation = new Sales[](saleIds.length);

            for (uint256 i = 0; i < saleIds.length; i++) {
                salesGoingOnThisLocation[i] = sales[saleIds[i]];
            }
            return salesGoingOnThisLocation;
    }



    function sendPurchaseRequest(
        uint256 _saleId, 
        uint256 _priceOffered
        ) public {

            Sales storage sale = sales[_saleId];
            

            require(sale.propertyId != 0, "Sale does not exist");
            

            require(sale.state == SaleState.Active,"Property Not in Active State to Purchase");


            requestedUsers[sale.saleId].push(
                RequestedUser({
                user: msg.sender,
                priceOffered: convertToWei(_priceOffered),
                state: RequestedUserToASaleState.SentPurchaseRequest
            }));
            

            requestedSales[msg.sender].push(sale.saleId);


            emit PurchaseRequestSent(_saleId, msg.sender, _priceOffered);
    }



    function acceptBuyerRequest(
        uint256 _saleId,
        address _buyer,
        uint256 _price
        ) public {

            _price = convertToWei(_price);


            Sales storage sale = sales[_saleId];


            require(sale.propertyId != 0, "Sale does not exist");


            require(sale.state == SaleState.Active, "Sale is Not Active");


            require(msg.sender == propertiesContract.getLandDetailsAsStruct(sale.propertyId).owner, "Only the owner can accept the purchase request.");



            require(requestedUsers[sale.saleId].length > 0, "No buyer requests found");


            bool buyerFound = false;
            uint i = 0;
            for (i = 0; i < requestedUsers[sale.saleId].length; i++) {
                if (requestedUsers[sale.saleId][i].user == _buyer) {
                    buyerFound = true;
                    break;
                }
            }
            require(buyerFound, "Buyer not found in requested user array");

            require(_price == requestedUsers[sale.saleId][i].priceOffered, "Price sent by seller not equal to price offered by buyer");




            sale.acceptedFor = _buyer;
            sale.acceptedPrice = _price;
            sale.acceptedTime = block.timestamp;
            sale.deadlineForPayment = block.timestamp + 5 minutes;
            
            sale.state = SaleState.AcceptedToABuyer;



            requestedUsers[sale.saleId][i].state = RequestedUserToASaleState.SellerAcceptedPurchaseRequest;




            emit SaleAccepted(_saleId, _buyer, _price, sale.deadlineForPayment);
    }



    function cancelSaleBySeller(uint256 _saleId) public returns (bool){

        Sales storage sale = sales[_saleId];
        
        require(sale.owner == msg.sender, "Only property owner can cancel sale");
        require(!sale.paymentDone, "Payment has already been made");
        require(sale.state != SaleState.Success, "Successed Sale Can't be Canceled.");
        require(sale.state != SaleState.CancelSaleBySeller, "Sale is Already Cancelled");
        require(sale.state != SaleState.AcceptedToABuyer, "Accepted To Buyer,Can't Cancel Sale.Please Cancel Acceptanc First");

        sale.state = SaleState.CancelSaleBySeller;
        sale.acceptedFor = address(0);
        sale.acceptedPrice = 0;
        sale.acceptedTime = 0;
        sale.deadlineForPayment = 0;
        sale.paymentDone = false;


        propertiesContract.changeStateBackToVerificed(sale.propertyId, msg.sender);

        return true;
    }


    function reactivateSale(uint256 _saleId) public {

        Sales storage sale = sales[_saleId];

        require(sale.owner == msg.sender, "Only property owner can Re-activate");
        require(sale.state != SaleState.Active , "Sale is Already in Active State");
        require(sale.state != SaleState.CancelSaleBySeller, "Closed Sale can't be reactivated.Please Create New Sale");
        require(sale.state != SaleState.AcceptedToABuyer, "Closed Sale can't be reactivated.Please Create New Sale");
        require(sale.state != SaleState.Success, "Successed Sale can't be reactivated.");
        
        sale.state = SaleState.Active;
        sale.acceptedFor =  address(0);
        sale.acceptedPrice =  0;
        sale.acceptedTime =  0;
        sale.deadlineForPayment =  0;
        sale.paymentDone  =  false;
    }



    function rejectingAcceptanceRequestByBuyer(uint256 _saleId) public {
        Sales storage sale = sales[_saleId];

        require(sale.state == SaleState.AcceptedToABuyer || sale.state == SaleState.DeadlineOverForPayment, "Sale state does not allow cancellation");


        require(sale.acceptedFor == msg.sender, "Not Authorized to Reject Acceptance Request of Seller");

        sale.state = SaleState.RejectedAcceptanceRequestByBuyer;



        bool buyerFound = false;
        uint i = 0;
        for (i = 0; i < requestedUsers[sale.saleId].length; i++) {
            if (requestedUsers[sale.saleId][i].user == msg.sender) {
                buyerFound = true;
                break;
            }
        }


        requestedUsers[sale.saleId][i].state = RequestedUserToASaleState.YouRejectedAcceptanceRequest;


    }

    function rejectingAcceptanceRequestBySeller(uint256 _saleId) public{
        Sales storage sale = sales[_saleId];

        require(sale.state == SaleState.AcceptedToABuyer || sale.state == SaleState.DeadlineOverForPayment, "Sale state does not allow cancellation");


        require(sale.owner == msg.sender, "Not Authorized to Cancel Acceptance Request of Buyer");


        address acceptedBuyer = sale.acceptedFor;


        sale.state = SaleState.CancelAcceptanceRequestGivenBySeller;
        sale.acceptedFor = address(0);
        sale.acceptedPrice = 0;
        sale.acceptedTime = 0;
        sale.deadlineForPayment = 0;
        sale.paymentDone = false;



        bool buyerFound = false;
        uint i = 0;
        for (i = 0; i < requestedUsers[sale.saleId].length; i++) {
            if (requestedUsers[sale.saleId][i].user == acceptedBuyer) {
                buyerFound = true;
                break;
            }
        }


        requestedUsers[sale.saleId][i].state = RequestedUserToASaleState.SellerCanceledAcceptanceRequest;

    }



    function cancelPurchaseRequestSentToSeller(uint256 _saleId) public {
        
        Sales storage sale = sales[_saleId];

        require(sale.state == SaleState.Active, "Sale state does not allow cancellation");


        bool buyerFound = false;
        uint i = 0;
        for (i = 0; i < requestedUsers[sale.saleId].length; i++) {
            if (requestedUsers[sale.saleId][i].user == msg.sender) {
                buyerFound = true;
                break;
            }
        }

        require(buyerFound,"Only Requested Buyers can cancel");


        requestedUsers[sale.saleId][i].state = RequestedUserToASaleState.CancelPurchaseRequest;


    }




    function rejectPurchaseRequestOfBuyer(
        uint256 _saleId,
        address _buyer
        ) public {
        
        Sales storage sale = sales[_saleId];


        require(sale.owner == msg.sender,"Only Owner is allowed");

        require(sale.state != SaleState.CancelSaleBySeller,"Can't do operation on Canceled sale");
        require(sale.state != SaleState.Success,"Can't do operation on Closed Sale");
       

        bool buyerFound = false;
        uint i = 0;
        for (i = 0; i < requestedUsers[sale.saleId].length; i++) {
            if (requestedUsers[sale.saleId][i].user == _buyer) {
                buyerFound = true;
                break;
            }
        }

        require(buyerFound,"Buyer is not Requested to purchase");

        requestedUsers[sale.saleId][i].state = RequestedUserToASaleState.SellerRejectedPurchaseRequest;


    }



    function rerequestPurchaseRequest(
        uint256 _saleId, 
        uint256 _priceOffered
        ) public {
    
            Sales storage sale = sales[_saleId];
            

            require(sale.propertyId != 0, "Sale does not exist");
            

            require(sale.state == SaleState.Active, "Sale is Not Active");


            bool buyerFound = false;
            uint i = 0;
            for (i = 0; i < requestedUsers[sale.saleId].length; i++) {
                if (requestedUsers[sale.saleId][i].user == msg.sender) {
                    buyerFound = true;
                    break;
                }
            }


            require(buyerFound,"Buyer Not found in Requested List");


            require(requestedUsers[sale.saleId][i].state != RequestedUserToASaleState.SentPurchaseRequest,"State Not Allowed to Re-sent Purchase Request");
            require(requestedUsers[sale.saleId][i].state != RequestedUserToASaleState.SellerAcceptedPurchaseRequest,"State Not Allowed to Re-sent Purchase Request");
            require(requestedUsers[sale.saleId][i].state != RequestedUserToASaleState.ReRequestedPurchaseRequest,"State Not Allowed to Re-sent Purchase Request");
    


            requestedUsers[sale.saleId][i].state = RequestedUserToASaleState.ReRequestedPurchaseRequest;
            requestedUsers[sale.saleId][i].priceOffered = convertToWei(_priceOffered);
                        

            emit PurchaseRequestSent(_saleId, msg.sender, _priceOffered);
    }

   

    function transferOwnerShip(
        uint256 saleId
        ) public payable {

            Sales storage sale = sales[saleId];
            
            require(msg.sender == sale.acceptedFor, "Only accepted buyer can complete the sale");

            require(msg.value == sale.acceptedPrice, "Payment amount must be equal to accepted price");

            require(block.timestamp <= sale.deadlineForPayment, "Payment deadline has passed");
            


            bool buyerFound = false;
            uint i = 0;
            for (i = 0; i < requestedUsers[sale.saleId].length; i++) {
                if (requestedUsers[sale.saleId][i].user == msg.sender) {
                    buyerFound = true;
                    break;
                }
            }


            require(buyerFound,"Buyer Not found in Requested List");
            


            payable(sale.owner).transfer(msg.value);

            LandRegistryContract.transferOwnership(sale.propertyId, msg.sender);
            

           requestedUsers[sale.saleId][i].state = RequestedUserToASaleState.SuccessfullyTransfered;



            uint256 _location = propertiesContract.getLandDetailsAsStruct(sale.propertyId).locationId;

            uint256[] storage propertiesOnSale = propertiesOnSaleByLocation[_location];

            for (i = 0; i < propertiesOnSale.length; i++) {
                if (propertiesOnSale[i] == sale.saleId) {
                    propertiesOnSale[i] = propertiesOnSale[propertiesOnSale.length - 1];
                    propertiesOnSale.pop();
                    break;
                }
            }
            

            sale.state = SaleState.Success;
    }

}