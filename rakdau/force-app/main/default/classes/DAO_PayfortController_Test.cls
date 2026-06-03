/*********************************************************************************************************************************
* @Class Name		: DAO_PayfortController_Test
* @Description		: Test class for DAO_PayfortController
* @Author			: Yuvraj Singh (Horizontal)
* @Date				: 25/09/2023
* Revision Log  	: V1.0 Created 
*					: V1.1 Honey Agarwal (Horizontal) updated testDataSetup(), initiatePaymentRequestTest(), updatePaymentDetailsTest_ReturnsTrue()
*					: V1.2 Yash Pareek (Horizontal) updated updatePaymentDetailsTest_ReturnsTrue RAKDAO 2761
*********************************************************************************************************************************/
@isTest
public with sharing class DAO_PayfortController_Test {
    //********************************************************************************
    //* Method      : testDataSetup
    //* Description : This method loads initial test data
    //* @Params	    : none
    //* @Returns    : void
    //*********************************************************************************/
    @testSetup
    public static void testDataSetup() {
        // Create Admin User
        Id adminProfileId = [SELECT Id From Profile Where Name = 'System Administrator'].Id;
        User adminUser = DAO_TestDataFactory.getTestUser('Admin',  'User', NULL, adminProfileId, NULL, NULL, true);
        
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('Test Account', businessAccRecordTypeId, true);        
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, true);
        
        // Create Portal User
        Id portalProfileId = [SELECT Id From Profile WHERE Name = 'RAK DAO Community Login User'].Id;
        User portalUser = DAO_TestDataFactory.getTestUser('Portal', 'User', NULL, portalProfileId, NULL, testConRecord.Id, true);

        Opportunity testOppRecord = DAO_TestDataFactory.getTestOpportunity('demo opp', 'Standard Company', testAccRecord.Id, testConRecord.Id, false);
        testOppRecord.Amount = 200;
        insert testOppRecord;
        
        //To create test work plan template, work step template
        WorkPlanTemplate testWorkPlanTemplate = DAO_TestDataFactory.getTestWorkPlanTemplate('Standard Company Plan Template', DAO_Constants.LICENSE_TYPE_STANDARD_COMPANY, 1, true); 
        testWorkPlanTemplate.Type__c = 'Incorporation';
        update testWorkPlanTemplate;
        WorkStepTemplate testWorkStepTemplate = DAO_TestDataFactory.getTestWorkStepTemplate('Payment', 'Payment','test step header', 'test step icon', 'test step sub header', true); 
        WorkPlanTemplateEntry testWorkPlanTemplateEntry = DAO_TestDataFactory.getTestWorkPlanTemplateEntry(1, testWorkPlanTemplate.Id, testWorkStepTemplate.Id, true); 
        
        //Create Test Products
        Product2 product = DAO_TestDataFactory.getTestProduct('Workspace Product', DAO_Constants.PRODUCT_FAMILY_WORKSPACE, NULL, true);
        PricebookEntry pEntry = DAO_TestDataFactory.getTestPriceBookEntry(2.0, product.Id, true);
        
        //Create Activity, Activity Group 
        Activity_Group__c actGrpStd = DAO_TestDataFactory.getTestActivityGroup('Accounting', DAO_Constants.LICENSE_TYPE_STANDARD_COMPANY, true, true);
        Sub_Activity__c subActStd = DAO_TestDataFactory.getTestSubActivity('Accounting',DAO_Constants.LICENSE_TYPE_STANDARD_COMPANY, '00001ij', true, false, actGrpStd.Id,  true);
        
        //Create Business Activity
        DAO_TestDataFactory.getTestBusinessActivity(DAO_Constants.LICENSE_TYPE_STANDARD_COMPANY, actGrpStd.Id, subActStd.Id, testOppRecord.AccountId, testOppRecord.Id, null, true);
        
        // Add Products to Opportunity 
        OpportunityLineItem oppLineItem = DAO_TestDataFactory.getTestOpportunityLineItem(1, 1.0, testOppRecord.Id, product.Id, true);
        
        //Qualify Opportunity
        testOppRecord.StageName = DAO_Constants.OPPORTUNITY_STAGE_QUALIFIED;
        testOppRecord.Inventory_Amount__c = 3000;
        update testOppRecord;  
        
        User portalUserRec = [SELECT Id, ContactId, AccountId FROM User WHERE ContactId =: testConRecord.Id LIMIT 1];
        WorkOrder workOrderRecord = [SELECT Id FROM WorkOrder];
        
        Payment__c testPayment = DAO_TestDataFactory.getTestPayment(testOppRecord.Id, testConRecord.Id, workOrderRecord.Id, portalUserRec.AccountId, true);
        testPayment.RD_Effective_Amount__c = 200.00;
        update testPayment;
        
        System.runAs(adminUser) {
            PermissionSet permissionSetRecord = [SELECT Id
                                                 FROM PermissionSet
                                                 WHERE Name = 'RAK_DAO_Community_Login_User_Permissions' LIMIT 1];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = portalUser.Id;
            psa.PermissionSetId = permissionSetRecord.Id;
            insert psa;
        }
    }
    
    //********************************************************************************
    //* Method		:	initiatePaymentRequestTest
    //* Description	:	Receive a map of <String, String> for Payment request according to payment record related to user's account.
    //* Parameters	: 	None
    //* Returns		:	void
    //* Added by     :  Maryann Thomas (Horizontal)
    //*********************************************************************************/
    @isTest
    public static void initiatePaymentRequestTest() {
        Id portalProfileId = [SELECT Id FROM Profile Where Name = 'RAK DAO Community Login User'].Id;
        User portalUser = [SELECT Id, ContactId, AccountId FROM User WHERE ProfileId =: portalProfileId AND IsActive = true AND Contact.FirstName = 'sfdctest' LIMIT 1];
        String testWorkOrderRecordId = [SELECT Id FROM WorkOrder WHERE AccountId =: portalUser.AccountId LIMIT 1].Id;

        // Ensure payment record exists and is linked to the WorkOrder, and has RD_Effective_Amount__c set to prevent NullPointerException
        // Query payment record linked to the WorkOrder (Service_Request__c) to match what the controller queries via getPaymentRecord
        List<Payment__c> paymentRecords = [SELECT Id, Name, Amount__c, RD_Effective_Amount__c, Service_Request__c, Status__c FROM Payment__c WHERE Service_Request__c =: testWorkOrderRecordId AND Status__c != 'Paid'];
        
        Payment__c paymentRecord;
        if (paymentRecords.isEmpty()) {
            // If no payment exists for this WorkOrder, query by Account and update Service_Request__c
            List<Payment__c> accountPayments = [SELECT Id, Name, Amount__c, RD_Effective_Amount__c, Service_Request__c, Status__c FROM Payment__c WHERE Account__c =: portalUser.AccountId AND Status__c != 'Paid' LIMIT 1];
            if (accountPayments.isEmpty()) {
                // If no payment exists at all, create one
                Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId =: portalUser.AccountId LIMIT 1];
                Contact con = [SELECT Id FROM Contact WHERE AccountId =: portalUser.AccountId LIMIT 1];
                paymentRecord = DAO_TestDataFactory.getTestPayment(opp.Id, con.Id, testWorkOrderRecordId, portalUser.AccountId, true);
                // Set RD_Effective_Amount__c on the newly created payment
                paymentRecord.RD_Effective_Amount__c = 100.00;
                update paymentRecord;
            } else {
                paymentRecord = accountPayments[0];
                paymentRecord.Service_Request__c = testWorkOrderRecordId;
            }
        } else {
            paymentRecord = paymentRecords[0];
        }
        
        // Ensure RD_Effective_Amount__c is set to prevent NullPointerException (must be > 0)
        // This is critical because the controller does: paymentRecord?.RD_Effective_Amount__c>0
        // which will throw NPE if RD_Effective_Amount__c is null
        if (paymentRecord.RD_Effective_Amount__c == null || paymentRecord.RD_Effective_Amount__c <= 0) {
            paymentRecord.RD_Effective_Amount__c = 100.00;
        }
        update paymentRecord;
        
        Integration_Settings__mdt payfortConfig = Integration_Settings__mdt.getInstance('Payfort_API');
        
        Test.startTest();
        System.runAs(portalUser) {
            Map<String,String> requestParametersMap = DAO_PayfortController.initiatePaymentRequest(null, testWorkOrderRecordId);
            Assert.areEqual('POST',requestParametersMap.get('method'), 'An unexpected error occured');
            Assert.areEqual(payfortConfig.Endpoint__c, requestParametersMap.get('endpoint'), 'An unexpected error occured');
            Assert.areEqual(64, requestParametersMap.get('signature').length(), 'An unexpected error occured');
            Assert.areEqual(paymentRecord?.Name, requestParametersMap.get('merchant_extra'), 'An unexpected error occured');
            Assert.areEqual(true, requestParametersMap.get('merchant_reference').startsWith(paymentRecord?.Name), 'An unexpected error occured');
            Assert.areEqual(payfortConfig?.Merchant_Identifier__c, requestParametersMap.get('merchant_identifier'), 'An unexpected error occured');
            Assert.areEqual('rakdao.com' + DAO_APIConstants.PAYFORT_REDIRECTION_PAGE_URL + testWorkOrderRecordId, requestParametersMap.get('return_url'), 'An unexpected error occured');
            Assert.areEqual(DAO_APIConstants.DEFAULT_LANGUAGE, requestParametersMap.get('language'), 'An unexpected error occured');
            Assert.areEqual(DAO_APIConstants.DEFAULT_CURRENCY, requestParametersMap.get('currency'), 'An unexpected error occured');
            Assert.areEqual(DAO_APIConstants.PAYFORT_PAYMENT_COMMAND, requestParametersMap.get('command'), 'An unexpected error occured');
            Assert.areEqual(payfortConfig?.Access_Code__c, requestParametersMap.get('access_code'), 'An unexpected error occured');
            Assert.areEqual(paymentRecord?.Id, requestParametersMap.get('merchant_extra1'), 'An unexpected error occured');
        }
        Test.stopTest();
    }
    
    //********************************************************************************
    //* Method		:	updatePaymentDetailsTest_ReturnsTrue
    //* Description	:	Check Payment, Opportunity and WorkOrder record updated according to data sent
    //* Parameters	: 	None
    //* Returns		:	void
    //* Added by     :  Maryann Thomas (Horizontal)
    //*********************************************************************************/
    @isTest
    public static void updatePaymentDetailsTest_ReturnsTrue() {
        Id portalProfileId = [SELECT Id FROM Profile Where Name = 'RAK DAO Community Login User'].Id;
        User portalUser = [SELECT Id, ContactId, AccountId FROM User WHERE ProfileId =: portalProfileId AND IsActive = true AND Contact.FirstName = 'sfdctest' LIMIT 1];
        Payment__c paymentRec = [SELECT Id, Name FROM Payment__c WHERE Account__c =: portalUser.AccountId LIMIT 1 ];
        
        Map<String,String> requestParametersMap = new Map<String,String>();
        requestParametersMap.put('merchant_extra1', paymentRec.Id);
        requestParametersMap.put('payment_option', 'Visa');
        requestParametersMap.put('card_holder_name', 'Test User');
        requestParametersMap.put('card_number', '1234 5677 7876 2515');
        requestParametersMap.put('expiry_date', '1212');
        requestParametersMap.put('token_name', 'dwoipddwo');
        requestParametersMap.put('customer_ip', '103.87.58.176');
        requestParametersMap.put('fort_id', '169996200011957290');
        requestParametersMap.put('response_code', '14000');
        requestParametersMap.put('response_message', 'Success');
        requestParametersMap.put('resultCode', 'Complete');
        requestParametersMap.put('status', 'Paid');
        Test.startTest();
        System.runAs(portalUser) {
            Boolean response = DAO_PayfortController.updatePaymentDetails(requestParametersMap);
            Test.stopTest();
            
            Payment__c paymentRecord = [SELECT Id, 
                                        Name, 
                                        Service_Request__c, 
                                        Opportunity__c, TnC_Accepted__c, 
                                        Payment_Method__c, Payment_Token__c, 
                                        IP_Address__c, 
                                        Payment_Gateway__c,
                                        Reference_Number__c, 
                                        Reference_Details__c, 
                                        Gateway_Result_Code__c, 
                                        Gateway_Result_Code_Description__c, 
                                        Payment_Date__c, 
                                        Payment_Result_Code__c, Status__c
                                        FROM Payment__c 
                                        WHERE Account__c =: portalUser.AccountId LIMIT 1 ];
            
            WorkOrder serviceReq = [SELECT Id, External_Status__c, Status FROM WorkOrder WHERE Id=:paymentRecord.Service_Request__c];
                        
            Assert.areEqual(true, paymentRecord.TnC_Accepted__c, 'An unexpected error occured');
            Assert.areEqual(DAO_APIConstants.PAYMENT_MODE_CARD, paymentRecord.Payment_Method__c, 'An unexpected error occured');
            Assert.areEqual('dwoipddwo', paymentRecord.Payment_Token__c, 'An unexpected error occured');
            Assert.areEqual('103.87.58.176', paymentRecord.IP_Address__c, 'An unexpected error occured');
            Assert.areEqual(DAO_APIConstants.PAYMENT_GATEWAY_PAYFORT, paymentRecord.Payment_Gateway__c, 'An unexpected error occured');
            Assert.areEqual('169996200011957290', paymentRecord.Reference_Number__c, 'An unexpected error occured');
            Assert.areEqual(NULL, paymentRecord.Reference_Details__c, 'An unexpected error occured');
            Assert.areEqual('14000', paymentRecord.Gateway_Result_Code__c, 'An unexpected error occured');
            Assert.areEqual('Success', paymentRecord.Gateway_Result_Code_Description__c, 'An unexpected error occured');
            Assert.areEqual(Date.today(), paymentRecord.Payment_Date__c, 'An unexpected error occured');
            Assert.areEqual('Complete', paymentRecord.Payment_Result_Code__c, 'An unexpected error occured');
            
            Assert.areEqual(true, response);
        }
    }
    
    //********************************************************************************
    //* Method		:	updatePaymentDetailsTest_ReturnsFalse
    //* Description	:	Check updatePaymentDetailsTest reurns false if empty map is sent as parameter
    //* Parameters	: 	None
    //* Returns		:	void
    //* Added by     :  Maryann Thomas (Horizontal)
    //*********************************************************************************/
    @isTest
    public static void updatePaymentDetailsTest_ReturnsFalse() {
        Map<String,String> requestParametersMap = new Map<String,String>();
        Test.startTest();
        Boolean response = DAO_PayfortController.updatePaymentDetails(requestParametersMap);
        Test.stopTest();
        Assert.areEqual(false, response, 'An unexpected error occured');
    }
    @isTest
    public static void testInitiatePaymentRequestURL_Success() {
        // Step 1: Setup mock data for Payment record
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'testing', LastName = 'Test Contact', AccountId = testAccount.Id, Email = 'testuser@example.com');
        insert testContact;

        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', AccountId = testAccount.Id, CloseDate = Date.today(), StageName = 'Prospecting', Amount = 100.00);
        insert testOpportunity;

        WorkOrder serviceRequest = new WorkOrder(Opportunity__c = testOpportunity.Id);
        insert serviceRequest;

        Payment__c paymentRecord = new Payment__c(
            Service_Request__c = serviceRequest.Id,
            RD_Effective_Amount__c = 100.00,
            Payer__c = testContact.Id,
            Opportunity__c = testOpportunity.Id,
            Account__c = testAccount.Id,
            Status__c = 'Draft'
        );
        insert paymentRecord;

        // Step 2: Mocking the callout using Test.setMock()
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Step 3: Call the initiatePaymentRequestURL method with serviceRequestId
        Test.startTest();
        String paymentLink = DAO_PayfortController.initiatePaymentRequestURL(paymentRecord.Service_Request__c, null);
        Test.stopTest();

        // Step 4: Assertions
        // Verify that the returned payment link matches the expected mocked value
        System.assertEquals('https://mock-api.com/payment-link', paymentLink, 'Payment link should match the expected mocked value.');

        // Verify that the Payment record has been updated with the payment link and expiry date
        Payment__c updatedPayment = [SELECT RD_Fiat_Payment_Link__c, RD_Fiat_Payment_Link_Expiry__c FROM Payment__c WHERE Id = :paymentRecord.Id];
        System.assertEquals('https://mock-api.com/payment-link', updatedPayment.RD_Fiat_Payment_Link__c, 'Payment link should be updated correctly.');
        System.assertNotEquals(null, updatedPayment.RD_Fiat_Payment_Link_Expiry__c, 'Payment link expiry should be set.');
    }
    
    @isTest
    public static void testInitiatePaymentRequestURL_WithPaymentRecordId() {
        // Step 1: Setup mock data for Payment record (wallet top-up scenario without service request)
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'testing', LastName = 'Test Contact', AccountId = testAccount.Id, Email = 'testuser@example.com');
        insert testContact;

        Payment__c paymentRecord = new Payment__c(
            Service_Request__c = null,
            RD_Effective_Amount__c = 100.00,
            RD_Wallet_Top_Up_Amount__c = 100.00,
            RD_Payment_Category__c = 'Top-Up',
            Payment_Method__c = 'Payment Link',
            Payer__c = testContact.Id,
            Account__c = testAccount.Id,
            Status__c = 'Draft'
        );
        insert paymentRecord;

        // Step 2: Mocking the callout using Test.setMock()
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Step 3: Call the initiatePaymentRequestURL method with paymentRecordId
        Test.startTest();
        String paymentLink = DAO_PayfortController.initiatePaymentRequestURL(null, paymentRecord.Id);
        Test.stopTest();

        // Step 4: Assertions
        // Verify that the returned payment link matches the expected mocked value
        System.assertEquals('https://mock-api.com/payment-link', paymentLink, 'Payment link should match the expected mocked value when using paymentRecordId.');

        // Verify that the Payment record has been updated with the payment link and expiry date
        Payment__c updatedPayment = [SELECT RD_Fiat_Payment_Link__c, RD_Fiat_Payment_Link_Expiry__c FROM Payment__c WHERE Id = :paymentRecord.Id];
        System.assertEquals('https://mock-api.com/payment-link', updatedPayment.RD_Fiat_Payment_Link__c, 'Payment link should be updated correctly when using paymentRecordId.');
        System.assertNotEquals(null, updatedPayment.RD_Fiat_Payment_Link_Expiry__c, 'Payment link expiry should be set when using paymentRecordId.');
    }

    @isTest
    public static void testInitiatePaymentRequestURL_ExpiredPaymentLink() {
        // Step 1: Setup mock data for Payment record with existing payment link
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'testing', LastName = 'Test Contact', AccountId = testAccount.Id, Email = 'testuser@example.com');
        insert testContact;

        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', AccountId = testAccount.Id, CloseDate = Date.today(), StageName = 'Prospecting', Amount = 100.00);
        insert testOpportunity;

        WorkOrder serviceRequest = new WorkOrder(Opportunity__c = testOpportunity.Id);
        insert serviceRequest;

        Payment__c paymentRecord = new Payment__c(
            Service_Request__c = serviceRequest.Id,
            RD_Fiat_Payment_Link__c = 'https://mock-api.com/old-link',
            RD_Fiat_Payment_Link_Expiry__c = Date.today().addDays(-1), // Expired link
            RD_Effective_Amount__c = 100.00,
            Payer__c = testContact.Id,
            Opportunity__c = testOpportunity.Id,
            Account__c = testAccount.Id,
            Status__c = 'Draft'
        );
        insert paymentRecord;

        // Step 2: Mocking the callout using Test.setMock()
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Step 3: Call the initiatePaymentRequestURL method with serviceRequestId
        Test.startTest();
        String paymentLink = DAO_PayfortController.initiatePaymentRequestURL(paymentRecord.Service_Request__c, null);
        Test.stopTest();

        // Step 4: Assertions
        System.assertEquals('https://mock-api.com/payment-link', paymentLink, 'Payment link should be updated to the new link.');
    }
    
    @isTest
    public static void testInitiatePaymentRequestURL_ValidExistingLink() {
        // Step 1: Setup mock data for Payment record with valid existing payment link
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'testing', LastName = 'Test Contact', AccountId = testAccount.Id, Email = 'testuser@example.com');
        insert testContact;

        Payment__c paymentRecord = new Payment__c(
            Service_Request__c = null,
            RD_Fiat_Payment_Link__c = 'https://mock-api.com/existing-link',
            RD_Fiat_Payment_Link_Expiry__c = Date.today().addDays(5), // Valid link
            RD_Effective_Amount__c = 100.00,
            RD_Wallet_Top_Up_Amount__c = 100.00,
            RD_Payment_Category__c = 'Top-Up',
            Payment_Method__c = 'Payment Link',
            Payer__c = testContact.Id,
            Account__c = testAccount.Id,
            Status__c = 'Draft'
        );
        insert paymentRecord;

        // Step 2: Call the initiatePaymentRequestURL method with paymentRecordId
        Test.startTest();
        String paymentLink = DAO_PayfortController.initiatePaymentRequestURL(null, paymentRecord.Id);
        Test.stopTest();

        // Step 3: Assertions
        // Should return the existing valid link without making a callout
        System.assertEquals('https://mock-api.com/existing-link', paymentLink, 'Should return existing valid payment link without generating new one.');
    }

    // Mock HTTP response generator class for simulating the API response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"payment_link": "https://mock-api.com/payment-link"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    
    @isTest
    public static void testCreatePaymentLink_Success() {
        // Step 1: Setup mock data for Payment record
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'testing', LastName = 'Test Contact', AccountId = testAccount.Id, Email = 'testuser@example.com');
        insert testContact;

        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', AccountId = testAccount.Id, CloseDate = Date.today(), StageName = 'Prospecting', Amount = 100.00);
        insert testOpportunity;

        WorkOrder serviceRequest = new WorkOrder(Opportunity__c = testOpportunity.Id);
        insert serviceRequest;

        Payment__c paymentRecord = new Payment__c(
            Service_Request__c = serviceRequest.Id,
            RD_Effective_Amount__c = 100.00,
            Payer__c = testContact.Id,
            Opportunity__c = testOpportunity.Id,
            Account__c = testAccount.Id,
            Status__c = 'Draft'
        );
        insert paymentRecord;

        // Step 2: Mocking the callout using Test.setMock()
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Step 3: Call the initiatePaymentRequestURL method
        Test.startTest();
        
        // Prepare the Invocable input
        DAO_PayfortController.GeneratorRequest req = new DAO_PayfortController.GeneratorRequest();
        req.opportunity = testOpportunity;
        req.contact = testContact;

        List<DAO_PayfortController.GeneratorRequest> requests = new List<DAO_PayfortController.GeneratorRequest>{ req };
		DAO_PayfortController.createPaymentLink(requests);
        
        Test.stopTest();
    }
}