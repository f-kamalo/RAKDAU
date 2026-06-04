

@isTest
public with sharing class HubpayUpdateProfileActionTest {

    private static Account buildTestAccount(String externalId) {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false);   
 
        // Set external-id fields only when they exist on the org schema
        Map<String, Schema.SObjectField> fieldMap = HubpayIntegrationHelper.getAccountFieldMap();
        if (fieldMap.containsKey('hubpay_external_id__c')) {
            acc.put('Hubpay_External_ID__c', externalId);
        } else if (fieldMap.containsKey('external_id__c')) {
            acc.put('External_Id__c', externalId);
        }
        if (fieldMap.containsKey('has_bank_account__c'))
            acc.put('Has_Bank_Account__c', true);
        if (fieldMap.containsKey('years_of_business_range__c'))
            acc.put('Years_Of_Business_Range__c', 'TWO_TO_FIVE');
        if (fieldMap.containsKey('number_of_employees_range__c'))
            acc.put('Number_Of_Employees_Range__c', 'ONE_TO_TEN');
        if (fieldMap.containsKey('annual_revenue__c'))
            acc.put('Annual_Revenue__c', 500000);
        if (fieldMap.containsKey('product_or_service_sold__c'))
            acc.put('Product_or_Service_Sold__c', 'Software');
        if (fieldMap.containsKey('intended_sales_channel__c'))
            acc.put('Intended_Sales_Channel__c', 'ONLINE');
        if (fieldMap.containsKey('sales_distribution_channels__c'))
            acc.put('Sales_Distribution_Channels__c', 'SOCIAL_MEDIA');
        if (fieldMap.containsKey('incoming_payment_countries__c'))
            acc.put('Incoming_Payment_Countries__c', 'AE;US');
        if (fieldMap.containsKey('incoming_payments_monthly_count__c'))
            acc.put('Incoming_Payments_Monthly_Count__c', 50);
        if (fieldMap.containsKey('incoming_payments_monthly_volume__c'))
            acc.put('Incoming_Payments_Monthly_Volume__c', 100000);
        if (fieldMap.containsKey('outgoing_payment_countries__c'))
            acc.put('Outgoing_Payment_Countries__c', 'KE;MR');
        if (fieldMap.containsKey('outgoing_payments_monthly_volume__c'))
            acc.put('Outgoing_Payments_Monthly_Volume__c', 80000);
        if (fieldMap.containsKey('outgoing_payments_monthly_count__c'))
            acc.put('Outgoing_Payments_Monthly_Count__c', 30);
        if (fieldMap.containsKey('account_opening_purposes__c'))
            acc.put('Account_Opening_Purposes__c', 'PAYROLL,SUPPLIER_PAYMENTS');
        if (fieldMap.containsKey('investment_source_of_funds_type__c'))
            acc.put('Investment_Source_Of_Funds_Type__c', 'PERSONAL');
        if (fieldMap.containsKey('investment_source_of_funds_description__c'))
            acc.put('Investment_Source_Of_Funds_Description__c', 'Operating revenue from sales');
 
        insert acc;
        return acc;
    }

    @isTest
    static void testNullOrEmptyRequests() {
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock());
        // Should return an empty list without throwing
        Test.startTest();
        List<HubpayUpdateProfileAction.Result> r1 =
            HubpayUpdateProfileAction.execute(null);
        List<HubpayUpdateProfileAction.Result> r2 =
            HubpayUpdateProfileAction.execute(new List<HubpayUpdateProfileAction.Request>());
        Test.stopTest();

        System.assertEquals(0, r1.size(), 'Null input should return empty list');
        System.assertEquals(0, r2.size(), 'Empty list should return empty list');
    }
    @isTest
    static void testAccountNotFound() {
        HubpayUpdateProfileAction.Request req = new HubpayUpdateProfileAction.Request();
        req.accountId = '001000000000001AAA'; // valid format, doesn't exist

        Test.startTest();
        List<HubpayUpdateProfileAction.Result> results = HubpayUpdateProfileAction.execute(
            new List<HubpayUpdateProfileAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assertEquals('Account not found.', results[0].message);
    }

    @IsTest
    static void testMissingExternalId() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, true);
 
        HubpayUpdateProfileAction.Request req = new HubpayUpdateProfileAction.Request();
        req.accountId = acc.Id;
 
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock());
        Test.startTest();
        List<HubpayUpdateProfileAction.Result> results =
            HubpayUpdateProfileAction.execute(new List<HubpayUpdateProfileAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(
            results[0].message.containsIgnoreCase('external') ||
            results[0].message.containsIgnoreCase('missing'),
            'Expected error about missing external ID, got: ' + results[0].message
        );
    }


    @IsTest
    static void testSuccessfulUpdate() {
        Account acc = buildTestAccount('EXT-001');
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', acc.Id, true);
        Opportunity testOppRecord = DAO_TestDataFactory.getTestOpportunity('demo opp', 'Standard Company', acc.Id, testConRecord.Id, true);
        Activity_Group__c actGrpStd = DAO_TestDataFactory.getTestActivityGroup('Accounting', DAO_Constants.LICENSE_TYPE_STANDARD_COMPANY, true, true);
        Sub_Activity__c subActStd = DAO_TestDataFactory.getTestSubActivity('Accounting',DAO_Constants.LICENSE_TYPE_STANDARD_COMPANY, '00001ij', true, false, actGrpStd.Id,  true);
        
        //Create Business Activity
        DAO_TestDataFactory.getTestBusinessActivity(DAO_Constants.LICENSE_TYPE_STANDARD_COMPANY, actGrpStd.Id, subActStd.Id, testOppRecord.AccountId, testOppRecord.Id, null, true);
 
        HubpayUpdateProfileAction.Request req = new HubpayUpdateProfileAction.Request();
        req.accountId = acc.Id;
 
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock());
        Test.startTest();
        List<HubpayUpdateProfileAction.Result> results =
            HubpayUpdateProfileAction.execute(new List<HubpayUpdateProfileAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].success, 'Expected success on 200 response.');
        System.assertEquals(acc.Id, results[0].accountId);
    }

    @IsTest
    static void testHttp400Response() {
        Account acc = buildTestAccount('EXT-002');
 
        HubpayUpdateProfileAction.Request req = new HubpayUpdateProfileAction.Request();
        req.accountId = acc.Id;
 
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock('VALIDATION_FAIL'));
        Test.startTest();
        List<HubpayUpdateProfileAction.Result> results =
            HubpayUpdateProfileAction.execute(new List<HubpayUpdateProfileAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(
            String.isNotBlank(results[0].message),
            'Error message should be populated on 400.'
        );
    }

    @IsTest
    static void testHttp500Response() {
        Account acc = buildTestAccount('EXT-003');
 
        HubpayUpdateProfileAction.Request req = new HubpayUpdateProfileAction.Request();
        req.accountId = acc.Id;
 
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock('EXCEPTION_TEST'));
        Test.startTest();
        List<HubpayUpdateProfileAction.Result> results =
            HubpayUpdateProfileAction.execute(new List<HubpayUpdateProfileAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(false, results[0].success);
    }

    @IsTest
    static void testNoUpdatePermission() {
        Profile minAccessProfile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        
        User restrictedUser = DAO_TestDataFactory.getTestUser('test user', 'lname',null, minAccessProfile.Id , null, null, true);

        // 3. Run the test context as that restricted user
        System.runAs(restrictedUser) {
            HubpayUpdateProfileAction.Request req = new HubpayUpdateProfileAction.Request();
            req.accountId = '001000000000000AAA'; 

            Test.startTest();
            List<HubpayUpdateProfileAction.Result> results =
                HubpayUpdateProfileAction.execute(
                    new List<HubpayUpdateProfileAction.Request>{ req }
                );
            Test.stopTest();

            // 4. Assertions ensuring the early return block executed successfully
            System.assertNotEquals(null, results, 'Results list should not be null');
            System.assertEquals(1, results.size(), 'Should process the request');
            System.assertEquals(false, results[0].success, 'Success flag must be false');
            System.assertEquals('No Account update permission.', results[0].message, 'Should return the exact OLS security message');
        }
    }

}


