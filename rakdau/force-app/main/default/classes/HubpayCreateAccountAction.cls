public with sharing class HubpayCreateAccountAction {
    public class Request {
        @InvocableVariable(required=true)
        public Id accountId;
    }

    public class Result {
        @InvocableVariable
        public Id accountId;
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Hubpay - Create Account' description='Creates account on Hubpay and updates status/external id on Account.' callout=true)
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        if (!Account.SObjectType.getDescribe().isUpdateable()) {
            for (Request req : requests) {
                Result r = new Result();
                r.accountId = req == null ? null : req.accountId;
                r.success = false;
                r.message = 'No Account update permission.';
                results.add(r);
            }
            return results;
        }

        Set<Id> accountIds = new Set<Id>();
        for (Request req : requests) {
            if (req != null && req.accountId != null) {
                accountIds.add(req.accountId);
            }
        }

        Map<Id, Account> accountById = new Map<Id, Account>();
        Map<Id, Contact> primaryContactByAccountId = new Map<Id, Contact>();
        if (!accountIds.isEmpty()) {
            List<String> baseFields = new List<String>{ 'Id', 'Name', 'RecordType.Name', 'RecordType.DeveloperName' };
            String query = 'SELECT ' + String.join(baseFields, ',') + ' FROM Account WHERE Id IN :accountIds';
            for (SObject sobj : Database.query(query)) {
                Account acc = (Account) sobj;
                accountById.put(acc.Id, acc);
            }

            for (AccountContactRelation relation : [
                SELECT AccountId, Contact.Email, Contact.MobilePhone
                FROM AccountContactRelation
                WHERE AccountId IN :accountIds
                AND ContactId != null
                AND Roles INCLUDES ('Primary Contact')
                ORDER BY CreatedDate ASC
            ]) {
                if (!primaryContactByAccountId.containsKey(relation.AccountId) && relation.Contact != null) {
                    primaryContactByAccountId.put(relation.AccountId, relation.Contact);
                }
            }
        }

        List<Account> accountsToUpdate = new List<Account>();
        Http http = new Http();

        for (Request req : requests) {
            Result currentResult = new Result();
            currentResult.accountId = req == null ? null : req.accountId;
            currentResult.success = false;
            currentResult.message = 'Skipped';

            if (req == null || req.accountId == null || !accountById.containsKey(req.accountId)) {
                currentResult.message = 'Account not found.';
                results.add(currentResult);
                continue;
            }

            Account sourceAccount = accountById.get(req.accountId);
            Account accountUpdate = new Account(Id = sourceAccount.Id);

            try {
                Contact primaryContact = primaryContactByAccountId.get(sourceAccount.Id);
                if (primaryContact == null) {
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_STATUS,
                        HubpayIntegrationHelper.STATUS_INTEGRATION_ERROR
                    );
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_ERROR_MESSAGE,
                        'Primary Contact is required in AccountContactRelation.Roles for Hubpay Create Account.'
                    );
                    currentResult.message = 'Primary Contact is required.';
                    accountsToUpdate.add(accountUpdate);
                    results.add(currentResult);
                    continue;
                }

                String primaryEmail = primaryContact.Email;
                if (String.isBlank(primaryEmail)) {
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_STATUS,
                        HubpayIntegrationHelper.STATUS_INTEGRATION_ERROR
                    );
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_ERROR_MESSAGE,
                        'Primary Contact Email is required for Hubpay Create Account.'
                    );
                    currentResult.message = 'Primary email is required.';
                    accountsToUpdate.add(accountUpdate);
                    results.add(currentResult);
                    continue;
                }

                String countryCode = 'AE';
                String hubpayPhone = String.isBlank(primaryContact.MobilePhone)
                    ? null
                    : primaryContact.MobilePhone.replaceAll('[^0-9]', '');
                if (String.isBlank(hubpayPhone)) {
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_STATUS,
                        HubpayIntegrationHelper.STATUS_INTEGRATION_ERROR
                    );
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_ERROR_MESSAGE,
                        'Primary Contact MobilePhone is required for Hubpay and must contain numbers.'
                    );
                    currentResult.message = 'Primary Contact MobilePhone is required and must contain numbers.';
                    accountsToUpdate.add(accountUpdate);
                    results.add(currentResult);
                    continue;
                }

                // Hubpay account type mapping: Freelancer record type -> INDIVIDUAL, otherwise BUSINESS.
                String accountType = 'BUSINESS';
                if (sourceAccount.RecordType != null) {
                    String recordTypeName = sourceAccount.RecordType.Name;
                    String recordTypeDeveloperName = sourceAccount.RecordType.DeveloperName;
                    if (
                        String.isNotBlank(recordTypeName) && recordTypeName.equalsIgnoreCase('Freelancer') ||
                        String.isNotBlank(recordTypeDeveloperName) && recordTypeDeveloperName.equalsIgnoreCase('Freelancer')
                    ) {
                        accountType = 'INDIVIDUAL';
                    }
                }

                // Field names match Hubpay Create Account API (application/json). accountName and phoneNumber are validated server-side.
                String accountNameForHubpay = HubpayIntegrationHelper.sanitizeAccountNameForHubpay(sourceAccount.Name);
                Map<String, Object> payload = new Map<String, Object>{
                    'accountType' => accountType,
                    'accountName' => accountNameForHubpay,
                    'email' => primaryEmail,
                    'phoneNumber' => hubpayPhone,
                    'countryCode' => countryCode,
                    'externalId' => String.valueOf(sourceAccount.Id)
                };

                HttpRequest request = new HttpRequest();
                request.setEndpoint(HubpayIntegrationHelper.HUBPAY_BASE_URL + HubpayIntegrationHelper.CREATE_ACCOUNT_PATH);
                request.setMethod('POST');
                request.setHeader('Accept', 'application/json');
                request.setHeader('Content-Type', 'application/json');
                request.setTimeout(HubpayIntegrationHelper.CALL_TIMEOUT_MS);
                HubpayIntegrationHelper.setAuthorizationHeader(request, http);
                request.setBody(JSON.serialize(payload));

                HttpResponse response = http.send(request);
                Integer code = response.getStatusCode();

                if (code >= 200 && code < 300) {
                    Map<String, Object> responseBody =
                        (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    String externalId = responseBody == null ? null : (String) responseBody.get('id');

                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_EXTERNAL_ACCOUNT_ID,
                        externalId
                    );
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_STATUS,
                        HubpayIntegrationHelper.STATUS_ACCOUNT_SYNCED
                    );
                    currentResult.success = true;
                    currentResult.message = 'Hubpay account created successfully.';
                } else {
                    String detailedError = HubpayIntegrationHelper.buildErrorMessage('Create account failed', response, null);
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_STATUS,
                        HubpayIntegrationHelper.STATUS_INTEGRATION_ERROR
                    );
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_ERROR_MESSAGE,
                        detailedError
                    );
                    currentResult.message = detailedError;
                }
            } catch (Exception ex) {
                String detailedError = HubpayIntegrationHelper.buildErrorMessage('Create account exception', null, ex);
                HubpayIntegrationHelper.setFieldValue(
                    accountUpdate,
                    HubpayIntegrationHelper.FIELD_STATUS,
                    HubpayIntegrationHelper.STATUS_INTEGRATION_ERROR
                );
                HubpayIntegrationHelper.setFieldValue(
                    accountUpdate,
                    HubpayIntegrationHelper.FIELD_ERROR_MESSAGE,
                    detailedError
                );
                currentResult.message = detailedError;
            }

            accountsToUpdate.add(accountUpdate);
            results.add(currentResult);
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }

        return results;
    }
}