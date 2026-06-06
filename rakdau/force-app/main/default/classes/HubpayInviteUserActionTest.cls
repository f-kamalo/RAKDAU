@IsTest
private class HubpayInviteUserActionTest {
    @IsTest
    static void testExecute_successfulInvite() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('no contact testAccRecord',businessAccRecordTypeId, false);
        testAccRecord.Hubpay_External_ID__c = 'EXT-F-001';
        insert testAccRecord;   
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, true);
        AccountContactRelation rel = [
            SELECT AccountId, Contact.Email, Contact.MobilePhone, Roles 
            FROM AccountContactRelation 
            WHERE AccountId =:testAccRecord.Id AND ContactId =:testConRecord.Id ];
        rel.Roles = 'Primary Contact';
        update rel;
        Opportunity testOppRecord = DAO_TestDataFactory.getTestOpportunity('demo opp', 'Standard Company', testAccRecord.Id, testConRecord.Id, true);
        WorkOrder testWORecord = DAO_TestDataFactory.getTestWorkOrder(testAccRecord.Id,testConRecord.Id, testOppRecord.Id, null,null, null,true);

        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock());

        HubpayInviteUserAction.Request req = new HubpayInviteUserAction.Request();
        req.accountId = testAccRecord.Id;

        Test.startTest();
        List<HubpayInviteUserAction.Result> results = HubpayInviteUserAction.execute(
            new List<HubpayInviteUserAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        HubpayInviteUserAction.Result r = results[0];
        System.assertEquals(testAccRecord.Id, r.accountId);
        System.assert(r.success, 'Expected success=true');
        System.assertEquals('https://hubpay.test/invite', r.inviteUrl);
    }

    @IsTest
    static void testExecute_successfulInvite_inviteUrlInsideDataNode() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('no contact testAccRecord',businessAccRecordTypeId, false);
        testAccRecord.Hubpay_External_ID__c = 'EXT-F-001';
        insert testAccRecord;   
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, true);
        AccountContactRelation rel = [
            SELECT AccountId, Contact.Email, Contact.MobilePhone, Roles 
            FROM AccountContactRelation 
            WHERE AccountId =:testAccRecord.Id AND ContactId =:testConRecord.Id ];
        rel.Roles = 'Primary Contact';
        update rel;
        Opportunity testOppRecord = DAO_TestDataFactory.getTestOpportunity('demo opp', 'Standard Company', testAccRecord.Id, testConRecord.Id, true);
        WorkOrder testWORecord = DAO_TestDataFactory.getTestWorkOrder(testAccRecord.Id,testConRecord.Id, testOppRecord.Id, null,null, null,true);

        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock('NESTED_SUCCESS'));

        HubpayInviteUserAction.Request req = new HubpayInviteUserAction.Request();
        req.accountId = testAccRecord.Id;

        Test.startTest();
        List<HubpayInviteUserAction.Result> results = HubpayInviteUserAction.execute(
            new List<HubpayInviteUserAction.Request>{ req }
        );
        Test.stopTest();

        System.assert(results[0].success);
        System.assertEquals('https://app.hubpay.com/invite/nested', results[0].inviteUrl);
    }

    @IsTest
    static void testExecute_alreadyInvited_409Conflict() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('no contact testAccRecord',businessAccRecordTypeId, false);
        testAccRecord.Hubpay_External_ID__c = 'EXT-F-001';   
        insert testAccRecord;
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, true);
        
        AccountContactRelation rel = [
            SELECT AccountId, Contact.Email, Contact.MobilePhone, Roles 
            FROM AccountContactRelation 
            WHERE AccountId =:testAccRecord.Id AND ContactId =:testConRecord.Id ];
        rel.Roles = 'Primary Contact';
        update rel;
        Opportunity testOppRecord = DAO_TestDataFactory.getTestOpportunity('demo opp', 'Standard Company', testAccRecord.Id, testConRecord.Id, true);
        WorkOrder testWORecord = DAO_TestDataFactory.getTestWorkOrder(testAccRecord.Id,testConRecord.Id, testOppRecord.Id, null,null, null,true);
        

        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock('INVITE_EXISTS'));

        HubpayInviteUserAction.Request req = new HubpayInviteUserAction.Request();
        req.accountId = testAccRecord.Id;

        Test.startTest();
        List<HubpayInviteUserAction.Result> results = HubpayInviteUserAction.execute(
            new List<HubpayInviteUserAction.Request>{ req }
        );
        Test.stopTest();

        System.assert(results[0].success, '409 "already exists" should be treated as success');
        System.assert(results[0].message.containsIgnoreCase('already'), 'Message should mention already invited');
    }

    @IsTest
    static void testExecute_httpError_400() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('no contact testAccRecord',businessAccRecordTypeId, false);
        testAccRecord.Hubpay_External_ID__c = 'EXT-F-001';   
        insert testAccRecord;
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, true);
        AccountContactRelation rel = [
            SELECT AccountId, Contact.Email, Contact.MobilePhone, Roles 
            FROM AccountContactRelation 
            WHERE AccountId =:testAccRecord.Id AND ContactId =:testConRecord.Id ];
        rel.Roles = 'Primary Contact';
        update rel;
        

        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock('VALIDATION_FAIL'));
        HubpayInviteUserAction.Request req = new HubpayInviteUserAction.Request();
        req.accountId = testAccRecord.Id;

        Test.startTest();
        List<HubpayInviteUserAction.Result> results = HubpayInviteUserAction.execute(
            new List<HubpayInviteUserAction.Request>{ req }
        );
        Test.stopTest();

        System.assert(!results[0].success, 'HTTP 400 should not be success');
        System.assertNotEquals(null, results[0].message);
    }

    @IsTest
    static void testExecute_httpError_500() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('no contact testAccRecord',businessAccRecordTypeId, false);
        testAccRecord.Hubpay_External_ID__c = 'EXT-F-001';
        insert testAccRecord;   
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, true);

        AccountContactRelation rel = [
            SELECT AccountId, Contact.Email, Contact.MobilePhone, Roles 
            FROM AccountContactRelation 
            WHERE AccountId =:testAccRecord.Id AND ContactId =:testConRecord.Id ];
        rel.Roles = 'Primary Contact';
        update rel;
        

        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock('EXCEPTION_TEST'));

        HubpayInviteUserAction.Request req = new HubpayInviteUserAction.Request();
        req.accountId = testAccRecord.Id;

        Test.startTest();
        List<HubpayInviteUserAction.Result> results = HubpayInviteUserAction.execute(
            new List<HubpayInviteUserAction.Request>{ req }
        );
        Test.stopTest();

        System.assert(!results[0].success);
    }

    @IsTest
    static void testExecute_successResponseMissingInviteUrl() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('no contact testAccRecord',businessAccRecordTypeId, false);
        testAccRecord.Hubpay_External_ID__c = 'EXT-F-001';  
        insert testAccRecord; 
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, true);

        AccountContactRelation rel = [
            SELECT AccountId, Contact.Email, Contact.MobilePhone, Roles 
            FROM AccountContactRelation 
            WHERE AccountId =:testAccRecord.Id AND ContactId =:testConRecord.Id ];
        rel.Roles = 'Primary Contact';
        update rel;
        Opportunity testOppRecord = DAO_TestDataFactory.getTestOpportunity('demo opp', 'Standard Company', testAccRecord.Id, testConRecord.Id, true);
        WorkOrder testWORecord = DAO_TestDataFactory.getTestWorkOrder(testAccRecord.Id,testConRecord.Id, testOppRecord.Id, null,null, null,true);
        

        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock('INVITE_fAILED'));

        HubpayInviteUserAction.Request req = new HubpayInviteUserAction.Request();
        req.accountId = testAccRecord.Id;

        Test.startTest();
        List<HubpayInviteUserAction.Result> results = HubpayInviteUserAction.execute(
            new List<HubpayInviteUserAction.Request>{ req }
        );
        Test.stopTest();

        // Should not be marked success when inviteUrl is absent
        System.assertEquals(false, results[0].success);
        System.assert(results[0].message.toLowerCase().contains('missing'),results[0].message);
    }

    @IsTest
    static void testExecute_nullRequestsList() {
        Test.startTest();
        List<HubpayInviteUserAction.Result> results = HubpayInviteUserAction.execute(null);
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(0, results.size());
    }


    @IsTest
    static void testExecute_nullAccountId() {
        HubpayInviteUserAction.Request req = new HubpayInviteUserAction.Request();
        req.accountId = null;

        Test.startTest();
        List<HubpayInviteUserAction.Result> results = HubpayInviteUserAction.execute(
            new List<HubpayInviteUserAction.Request>{ req }
        );
        Test.stopTest();

        System.assert(!results[0].success);
        System.assert(results[0].message.containsIgnoreCase('required'));
    }

    @IsTest
    static void testExecute_missingExternalAccountId() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('Test Account',businessAccRecordTypeId, true);    
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, true);

        AccountContactRelation rel = [
            SELECT AccountId, Contact.Email, Contact.MobilePhone, Roles 
            FROM AccountContactRelation 
            WHERE AccountId =:testAccRecord.Id AND ContactId =:testConRecord.Id ];
        rel.Roles = 'Primary Contact';
        update rel;
        

        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock('INVITE_EXISTS'));
        HubpayInviteUserAction.Request req = new HubpayInviteUserAction.Request();
        req.accountId = testAccRecord.Id;

        // No callout mock needed; should fail before HTTP call
        Test.startTest();
        List<HubpayInviteUserAction.Result> results = HubpayInviteUserAction.execute(
            new List<HubpayInviteUserAction.Request>{ req }
        );
        Test.stopTest();

        System.assert(!results[0].success);
        System.assert(
            results[0].message.containsIgnoreCase('external account id') ||
            results[0].message.containsIgnoreCase('not found'),
            'Message: ' + results[0].message
        );
    }

    @IsTest
    static void testExecute_primaryContactNotFound() {
       String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('no contact testAccRecord',businessAccRecordTypeId, false);
        testAccRecord.Hubpay_External_ID__c = 'EXT-F-001';  
        insert testAccRecord; 
        
        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock());

        HubpayInviteUserAction.Request req = new HubpayInviteUserAction.Request();
        req.accountId = testAccRecord.Id;


        Test.startTest();
        List<HubpayInviteUserAction.Result> results = HubpayInviteUserAction.execute(
            new List<HubpayInviteUserAction.Request>{ req }
        );
        Test.stopTest();

        System.assert(!results[0].success);
        System.assert(results[0].message.containsIgnoreCase('Primary Contact not found'));
    }

    @IsTest
    static void testExecute_primaryContactMissingEmail() {
        String businessAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();
        Account testAccRecord = DAO_TestDataFactory.getTestAccount('Test Account',businessAccRecordTypeId, false);  
        testAccRecord.Hubpay_External_ID__c = 'EXT-F-001';  
        insert testAccRecord;   
        Contact testConRecord = DAO_TestDataFactory.getTestContact('sfdctest', 'velo', testAccRecord.Id, false);
        testConRecord.Email = null;
        insert testConRecord;
        AccountContactRelation rel = [
            SELECT AccountId, Contact.Email, Contact.MobilePhone, Roles 
            FROM AccountContactRelation 
            WHERE AccountId =:testAccRecord.Id AND ContactId =:testConRecord.Id ];
        rel.Roles = 'Primary Contact';
        update rel;
        Opportunity testOppRecord = DAO_TestDataFactory.getTestOpportunity('demo opp', 'Standard Company', testAccRecord.Id, testConRecord.Id, true);
        WorkOrder testWORecord = DAO_TestDataFactory.getTestWorkOrder(testAccRecord.Id,testConRecord.Id, testOppRecord.Id, null,null, null,true);

        Test.setMock(HttpCalloutMock.class,new HubpayHttpCalloutMock());

        HubpayInviteUserAction.Request req = new HubpayInviteUserAction.Request();
        req.accountId = testAccRecord.Id;


        Test.startTest();
        List<HubpayInviteUserAction.Result> results = HubpayInviteUserAction.execute(
            new List<HubpayInviteUserAction.Request>{ req }
        );
        Test.stopTest();

        System.assert(!results[0].success);
        System.assertEquals('Primary Contact email is required.', results[0].message);
    }    
}