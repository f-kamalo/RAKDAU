@isTest
public with sharing class HubpayCreateAccountActionTest {

    // String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
    // Account testAccRecord = DAO_TestDataFactory.getTestAccount('Test Account',businessAccRecordTypeId, true);    
    // Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, true);
    @isTest
    static void testNullOrEmptyRequests() {
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock());
        // Should return an empty list without throwing
        Test.startTest();
        List<HubpayCreateAccountAction.Result> r1 =
            HubpayCreateAccountAction.execute(null);
        List<HubpayCreateAccountAction.Result> r2 =
            HubpayCreateAccountAction.execute(new List<HubpayCreateAccountAction.Request>());
        Test.stopTest();

        System.assertEquals(0, r1.size(), 'Null input should return empty list');
        System.assertEquals(0, r2.size(), 'Empty list should return empty list');
    }

    @isTest
    static void testAccountNotFound() {
        HubpayCreateAccountAction.Request req = new HubpayCreateAccountAction.Request();
        req.accountId = '001000000000001AAA'; // valid format, doesn't exist

        Test.startTest();
        List<HubpayCreateAccountAction.Result> results = HubpayCreateAccountAction.execute(
            new List<HubpayCreateAccountAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assertEquals('Account not found.', results[0].message);
    }
    @isTest
    static void testNoPrimaryContact() {
       String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
       Account acc = DAO_TestDataFactory.getTestAccount('no contact acc',businessAccRecordTypeId, true);   

       HubpayCreateAccountAction.Request req = new HubpayCreateAccountAction.Request();
       req.accountId = acc.Id;
       Test.startTest();
        List<HubpayCreateAccountAction.Result> results = HubpayCreateAccountAction.execute(
            new List<HubpayCreateAccountAction.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assert(results[0].message.contains('Primary Contact is required'), results[0].message);
    }


    @isTest
    static void testSuccess_Business_AccountUpdatedWithHubpayId() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('Test Account',businessAccRecordTypeId, true);    
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, true);
        AccountContactRelation rel = [
            SELECT AccountId, Contact.Email, Contact.MobilePhone, Roles 
            FROM AccountContactRelation 
            WHERE AccountId =:testAccRecord.Id AND ContactId =:testConRecord.Id ];
        rel.Roles = 'Primary Contact';
        update rel;

        HubpayCreateAccountAction.Request req = new HubpayCreateAccountAction.Request();
        req.accountId = testAccRecord.Id;
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock());

        Test.startTest();
        List<HubpayCreateAccountAction.Result> results = HubpayCreateAccountAction.execute(
            new List<HubpayCreateAccountAction.Request>{ req }
        );
        Test.stopTest();

        // Result assertions
        System.assertEquals(1, results.size());
        System.assertEquals(true,  results[0].success, results[0].message);
        System.assertEquals('Hubpay account created successfully.', results[0].message);
        System.assertEquals(testAccRecord.Id, results[0].accountId);

        // Verify the Account was updated with the "id" from the Hubpay response
        Id idVar = testAccRecord.Id;
        Account updated = Database.query(
            'SELECT ' + HubpayIntegrationHelper.FIELD_EXTERNAL_ACCOUNT_ID
            + ', ' + HubpayIntegrationHelper.FIELD_STATUS
            + ' FROM Account WHERE Id = :idVar'
        );
        System.assertEquals(
            'f8d7f528-87b9-426a-918d-e3f0552e88e4',
            updated.get(HubpayIntegrationHelper.FIELD_EXTERNAL_ACCOUNT_ID),
            'External Hubpay ID should be stored on Account'
        );
        System.assertEquals(
            HubpayIntegrationHelper.STATUS_ACCOUNT_SYNCED,
            updated.get(HubpayIntegrationHelper.FIELD_STATUS),
            'Status should be ACCOUNT_SYNCED'
        );
    }


    @isTest
    static void testMissingEmail() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('Test Account',businessAccRecordTypeId, true);    
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, false);
        testConRecord.Email = null;
        insert testConRecord;
        AccountContactRelation rel = [
            SELECT AccountId, Contact.Email, Contact.MobilePhone, Roles 
            FROM AccountContactRelation 
            WHERE AccountId =:testAccRecord.Id AND ContactId =:testConRecord.Id ];
        rel.Roles = 'Primary Contact';
        update rel;

        HubpayCreateAccountAction.Request req = new HubpayCreateAccountAction.Request();
        req.accountId = testAccRecord.Id;
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock());

        Test.startTest();
        List<HubpayCreateAccountAction.Result> results = HubpayCreateAccountAction.execute(
            new List<HubpayCreateAccountAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assert(results[0].message.containsIgnoreCase('email'), results[0].message);
    }

    @isTest
    static void testMissingMobilePhone() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('Test Account',businessAccRecordTypeId, true);    
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, false);
        testConRecord.MobilePhone = null;
        insert testConRecord;
        AccountContactRelation rel = [
            SELECT AccountId, Contact.Email, Contact.MobilePhone, Roles 
            FROM AccountContactRelation 
            WHERE AccountId =:testAccRecord.Id AND ContactId =:testConRecord.Id ];
        rel.Roles = 'Primary Contact';
        update rel;

        HubpayCreateAccountAction.Request req = new HubpayCreateAccountAction.Request();
        req.accountId = testAccRecord.Id;
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock());

        Test.startTest();
        List<HubpayCreateAccountAction.Result> results = HubpayCreateAccountAction.execute(
            new List<HubpayCreateAccountAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assert(results[0].message.containsIgnoreCase('MobilePhone'), results[0].message);
    }

    @isTest
    static void testMobilePhoneNonNumeric() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('Test Account',businessAccRecordTypeId, true);    
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, false);
        testConRecord.MobilePhone = 'sdfghjnbvg';
        insert testConRecord;
        AccountContactRelation rel = [
            SELECT AccountId, Contact.Email, Contact.MobilePhone, Roles 
            FROM AccountContactRelation 
            WHERE AccountId =:testAccRecord.Id AND ContactId =:testConRecord.Id ];
        rel.Roles = 'Primary Contact';
        update rel;

        HubpayCreateAccountAction.Request req = new HubpayCreateAccountAction.Request();
        req.accountId = testAccRecord.Id;
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock());

        Test.startTest();
        List<HubpayCreateAccountAction.Result> results = HubpayCreateAccountAction.execute(
            new List<HubpayCreateAccountAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assert(results[0].message.containsIgnoreCase('MobilePhone'), results[0].message);
    }

    @isTest
    static void testHttp400_SetsIntegrationError() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('Test Account',businessAccRecordTypeId, true);    
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, true);
        AccountContactRelation rel = [
            SELECT AccountId, Contact.Email, Contact.MobilePhone, Roles 
            FROM AccountContactRelation 
            WHERE AccountId =:testAccRecord.Id AND ContactId =:testConRecord.Id ];
        rel.Roles = 'Primary Contact';
        update rel;

        HubpayCreateAccountAction.Request req = new HubpayCreateAccountAction.Request();
        req.accountId = testAccRecord.Id;
        Test.setMock(HttpCalloutMock.class, new HubpayHttpCalloutMock(false));

        Test.startTest();
        List<HubpayCreateAccountAction.Result> results = HubpayCreateAccountAction.execute(
            new List<HubpayCreateAccountAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assert(
            results[0].message.containsIgnoreCase('Create account failed'),
            'Expected HTTP error message, got: ' + results[0].message
        );
        Id idVar = testAccRecord.Id;
        Account updated = Database.query(
            'SELECT ' + HubpayIntegrationHelper.FIELD_STATUS
            + ' FROM Account WHERE Id = :idVar'
        );
        System.assertEquals(
            HubpayIntegrationHelper.STATUS_INTEGRATION_ERROR,
            updated.get(HubpayIntegrationHelper.FIELD_STATUS)
        );
    }

}