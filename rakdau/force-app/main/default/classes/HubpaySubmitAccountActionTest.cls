@isTest
public with sharing class HubpaySubmitAccountActionTest {
    private static Account createAccountWithExternalId(String externalId) {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, false); 
        HubpayIntegrationHelper.setFieldValue(
            acc,
            HubpayIntegrationHelper.FIELD_EXTERNAL_ACCOUNT_ID,
            externalId
        );
        insert acc;
        return acc;
    }
 
    @IsTest
    static void testEmptyRequestList() {
        Test.startTest();
        List<HubpaySubmitAccountAction.Result> results =
            HubpaySubmitAccountAction.execute(new List<HubpaySubmitAccountAction.Request>());
        Test.stopTest();
 
        System.assertEquals(0, results.size(), 'Empty input should return empty results');
    }
 
    @IsTest
    static void testNullRequestList() {
        Test.startTest();
        List<HubpaySubmitAccountAction.Result> results =
            HubpaySubmitAccountAction.execute(null);
        Test.stopTest();
 
        System.assertEquals(0, results.size(), 'Null input should return empty results');
    }
 
    @IsTest
    static void testAccountNotFound() {
         
        Id accountId = '001000000000001AAA';
        HubpaySubmitAccountAction.Request req = new HubpaySubmitAccountAction.Request();
        req.accountId = accountId;
 
        Test.startTest();
        List<HubpaySubmitAccountAction.Result> results =
            HubpaySubmitAccountAction.execute(
                new List<HubpaySubmitAccountAction.Request>{ req }
            );
        Test.stopTest();
 
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assertEquals('Account not found.', results[0].message);
    }
 
    @IsTest
    static void testMissingExternalAccountId() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, true); 

        HubpaySubmitAccountAction.Request req = new HubpaySubmitAccountAction.Request();
        req.accountId = acc.Id;
 
        Test.startTest();
        List<HubpaySubmitAccountAction.Result> results =
            HubpaySubmitAccountAction.execute(
                new List<HubpaySubmitAccountAction.Request>{ req }
            );
        Test.stopTest();
 
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(
            results[0].message.containsIgnoreCase('Missing Hubpay external account id') ||
            results[0].message.containsIgnoreCase('missing'),
            'Message should indicate missing external id. Got: ' + results[0].message
        );
    }
 
    @IsTest
    static void testSuccessfulSubmit() {
        Account acc = createAccountWithExternalId('EXT-001');

        HubpaySubmitAccountAction.Request req = new HubpaySubmitAccountAction.Request();
        req.accountId = acc.Id;
 
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock());
 
        Test.startTest();
        List<HubpaySubmitAccountAction.Result> results =
            HubpaySubmitAccountAction.execute(
                new List<HubpaySubmitAccountAction.Request>{ req }
            );
        Test.stopTest();
 
        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].success,
            'Expected success=true on 200 response');
        System.assert(
            results[0].message.containsIgnoreCase('submitted') ||
            results[0].message.containsIgnoreCase('success'),
            'Message should confirm submission. Got: ' + results[0].message
        );
        System.assertEquals(acc.Id, results[0].accountId);
    }
 
    @IsTest
    static void testHttpErrorResponse() {
        Account acc = createAccountWithExternalId('EXT-002');
        HubpaySubmitAccountAction.Request req = new HubpaySubmitAccountAction.Request();
        req.accountId = acc.Id;

        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock('VALIDATION_FAIL'));
 
        Test.startTest();
        List<HubpaySubmitAccountAction.Result> results =
            HubpaySubmitAccountAction.execute(
                new List<HubpaySubmitAccountAction.Request>{ req }
            );
        Test.stopTest();
 
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success,
            'Expected success=false on 400 response');
        System.assert(
            String.isNotBlank(results[0].message),
            'Error message should be populated on failure'
        );
    }
    @IsTest
    static void testCalloutException() {
        Account acc = createAccountWithExternalId('EXT-002');
        HubpaySubmitAccountAction.Request req = new HubpaySubmitAccountAction.Request();
        req.accountId = acc.Id;

        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock('EXCEPTION_TEST'));
 
        Test.startTest();
        List<HubpaySubmitAccountAction.Result> results =
            HubpaySubmitAccountAction.execute(
                new List<HubpaySubmitAccountAction.Request>{ req }
            );
        Test.stopTest();
 
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success,
            'Expected success=false when callout throws');
        System.assert(
            results[0].message.containsIgnoreCase('exception') ||
            results[0].message.containsIgnoreCase('timed out') ||
            String.isNotBlank(results[0].message),
            'Exception message should be propagated. Got: ' + results[0].message
        );
    }
}