@isTest
public with sharing class HubpayGetFundingAccountsActionTest {
    @IsTest
    static void testEmptyRequestList() {
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>());
        Test.stopTest();
 
        System.assertEquals(0, results.size(), 'Empty list should return empty results');
    }
 
    @IsTest
    static void testNullRequestList() {
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(null);
        Test.stopTest();
 
        System.assertEquals(0, results.size(), 'Null list should return empty results');
    }

    @IsTest
    static void testNullAccountId() {
        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();
        req.accountId = null;
 
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(
            results[0].message.containsIgnoreCase('required'),
            'Null accountId should say it is required. Got: ' + results[0].message
        );
    }

     @IsTest
    static void AccountNotFound() {
        Id fakeId = '001000000000001AAA';
 
        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();
        req.accountId = fakeId;
        req.completeAccountApproval = false;
 
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(
            results[0].message.containsIgnoreCase('not found'),
            'Expected account-not-found message. Got: ' + results[0].message
        );
    }
    @IsTest
    static void missingExtId () {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, true);
        
 
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock());
 
        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();
        req.accountId = acc.Id;
        req.completeAccountApproval = false;
 
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(1, results.size());
    }
    @IsTest
    static void EmptyArrayResponse() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false);
        acc.Hubpay_External_ID__c = 'EXT-F-001';
        insert acc;
 
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock('EMPTY_BODY'));
 
        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();
        req.accountId = acc.Id;
        req.completeAccountApproval = false;
 
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req });
        Test.stopTest();
 
        
        System.assertEquals(0, results[0].fundingAccountCount);
        System.assertEquals(null, results[0].hubpayIban);
    }
    @IsTest
    static void testFundingAccountsValidationFailure() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false);
        acc.Hubpay_External_ID__c = 'EXT-F-001';
        insert acc;
 
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock('VALIDATION_FAIL'));
 
        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();
        req.accountId = acc.Id;
        req.completeAccountApproval = false;
 
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(false, results[0].success);
        System.assert(String.isNotBlank(results[0].message), 'Error message should be populated');
    }
    @IsTest
    static void testFundingAccountsException() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false);
        acc.Hubpay_External_ID__c = 'EXT-F-001';
        insert acc;
 
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock('EXCEPTION_TEST'));
 
        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();
        req.accountId = acc.Id;
        req.completeAccountApproval = false;
 
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(false, results[0].success);
        System.assert(String.isNotBlank(results[0].message), 'Error message should be populated');
    }

    @IsTest
    static void testFundingAccountsSuccess() {

        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false);
        acc.Hubpay_External_ID__c = 'EXT-F-001';
        insert acc;

        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();

        req.accountId = acc.Id;
        req.completeAccountApproval = false;

        Test.setMock( HttpCalloutMock.class,new HubpayHttpCalloutMock());

        Test.startTest();

        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req }
            );

        Test.stopTest();

        System.assertEquals(true, results[0].success);

        System.assertNotEquals(null,results[0].hubpayIban);

        System.assert(results[0].fundingAccountCount > 0);

        System.assert( results[0].message.contains('Funding accounts retrieved'));
    }

    @IsTest
    static void testPerformFundingCalloutUsingAccount() {

        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false);
        acc.Hubpay_External_ID__c = 'EXT-F-001';
        insert acc;

        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock('SUCCESS'));

        Test.startTest();

        HubpayGetFundingAccountsAction.FundingCalloutOutcome outcome =HubpayGetFundingAccountsAction.performFundingAccountsCallout(acc, new Http() );

        Test.stopTest();

        System.assertEquals( true, outcome.success);

        System.assertNotEquals( null, outcome.accountNumber);
    }

    

    @IsTest
    static void testApproval_NullHubpayExternalId() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false);
        acc.Hubpay_External_ID__c = 'EXT-F-001';
        insert acc;
 
        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();
        req.accountId = acc.Id;
        req.completeAccountApproval = true;
        req.hubpayExternalAccountId = null;
 
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(false, results[0].success);
        System.assert(
            results[0].message.containsIgnoreCase('required'),
            'Null hubpayExternalAccountId should produce required message. Got: ' + results[0].message
        );
    }
 
    @IsTest
    static void testApproval_BlankHubpayExternalId() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false);
        acc.Hubpay_External_ID__c = 'EXT-F-001';
        insert acc;
 
        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();
        req.accountId = acc.Id;
        req.completeAccountApproval = true;
        req.hubpayExternalAccountId = '   ';
 
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(false, results[0].success);
        System.assert(
            results[0].message.containsIgnoreCase('required'),
            'Blank hubpayExternalAccountId should produce required message. Got: ' + results[0].message
        );
    }
 
    @IsTest
    static void testApproval_FullSuccess() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false);
        acc.Hubpay_External_ID__c = 'EXT-F-001';
        insert acc;
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', acc.Id, true);
        Opportunity testOppRecord = DAO_TestDataFactory.getTestOpportunity('demo opp', 'Standard Company', acc.Id, testConRecord.Id, true);
        WorkOrder testWORecord = DAO_TestDataFactory.getTestWorkOrder(acc.Id,testConRecord.Id, testOppRecord.Id, null,null, null,true);
 
        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock());
 
        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();
        req.accountId = acc.Id;
        req.completeAccountApproval = true;
        req.hubpayExternalAccountId = 'hub-ext-003';
 
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].success, 'Full approval should succeed');
        System.assertEquals('AE123456789', results[0].hubpayIban);
        System.assertEquals('https://hubpay.test/invite', results[0].inviteUrl);
        System.assert(
            results[0].message.containsIgnoreCase('approved') ||
            results[0].message.containsIgnoreCase('updated'),
            'Message should confirm approval. Got: ' + results[0].message
        );
    }
 
    @IsTest
    static void testApproval_FundingGetFails() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false);
        acc.Hubpay_External_ID__c = 'EXT-F-001';
        insert acc;
 
        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock('SERVER_ERROR'));
 
        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();
        req.accountId = acc.Id;
        req.completeAccountApproval = true;
        req.hubpayExternalAccountId = 'hub-ext-004';
 
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(false, results[0].success,
            'Should fail when funding GET returns HTTP error');
        System.assert(String.isNotBlank(results[0].message));
    }
 
    @IsTest
    static void testApproval_FundingGetExceptionFails() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false);
        acc.Hubpay_External_ID__c = 'EXT-F-001';
        insert acc;
 
        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock('EXCEPTION_TEST'));
 
        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();
        req.accountId = acc.Id;
        req.completeAccountApproval = true;
        req.hubpayExternalAccountId = 'hub-ext-005';
 
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(false, results[0].success);
    }
    @IsTest
    static void testApproval_FundingSuccessButNoIban() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false);
        acc.Hubpay_External_ID__c = 'EXT-F-001';
        insert acc;
 
        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock('NOIBAN'));
 
        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();
        req.accountId = acc.Id;
        req.completeAccountApproval = true;
        req.hubpayExternalAccountId = 'hub-ext-006';
 
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(false, results[0].success,
            'Should fail when funding response has no accountNumber');
        System.assert(
            results[0].message.containsIgnoreCase('accountNumber') ||
            results[0].message.containsIgnoreCase('iban') ||
            results[0].message.containsIgnoreCase('not found'),
            'Expected IBAN-missing message. Got: ' + results[0].message
        );
    }
 
    @IsTest
    static void testApproval_InviteFails() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false);
        acc.Hubpay_External_ID__c = 'EXT-F-001';
        insert acc;
 
        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock('INVITE_fAILED'));
 
        HubpayGetFundingAccountsAction.Request req = new HubpayGetFundingAccountsAction.Request();
        req.accountId = acc.Id;
        req.completeAccountApproval = true;
        req.hubpayExternalAccountId = 'hub-ext-007';
 
        Test.startTest();
        List<HubpayGetFundingAccountsAction.Result> results =
            HubpayGetFundingAccountsAction.execute(
                new List<HubpayGetFundingAccountsAction.Request>{ req });
        Test.stopTest();
 
        System.assertEquals(false, results[0].success,
            'Should fail when invite POST returns HTTP error');
        System.assert(String.isNotBlank(results[0].message));
    }

}