/**
 * @description Invocable action: confirms Hubpay account submission with fixed STARTER tier (PUT /v1/account/submit).
 */
public with sharing class HubpaySubmitAccountAction {
    private static final String ACCOUNT_TIER_STARTER = 'STARTER';

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

    @InvocableMethod(
        label='Hubpay - Submit Account (STARTER tier)'
        description='Calls Hubpay PUT /v1/account/submit with accountTier STARTER and AccountId header from Hubpay_External_ID__c.'
        callout=true
    )
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
        if (!accountIds.isEmpty()) {
            List<String> queryFields = new List<String>{ 'Id' };
            if (HubpayIntegrationHelper.getAccountFieldMap().containsKey(HubpayIntegrationHelper.FIELD_EXTERNAL_ACCOUNT_ID)) {
                queryFields.add(HubpayIntegrationHelper.FIELD_EXTERNAL_ACCOUNT_ID);
            }
            if (HubpayIntegrationHelper.getAccountFieldMap().containsKey('External_Id__c')) {
                queryFields.add('External_Id__c');
            }
            String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Account WHERE Id IN :accountIds';
            for (SObject sobj : Database.query(query)) {
                accountById.put(((Account) sobj).Id, (Account) sobj);
            }
        }

        Http http = new Http();
        List<Account> accountsToUpdate = new List<Account>();

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
                String externalAccountId = readExternalAccountId(sourceAccount);
                if (String.isBlank(externalAccountId)) {
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_STATUS,
                        HubpayIntegrationHelper.STATUS_INTEGRATION_ERROR
                    );
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_ERROR_MESSAGE,
                        'Hubpay external account id is missing.'
                    );
                    currentResult.message = 'Missing Hubpay external account id.';
                    accountsToUpdate.add(accountUpdate);
                    results.add(currentResult);
                    continue;
                }

                Map<String, Object> payload = new Map<String, Object>{ 'accountTier' => ACCOUNT_TIER_STARTER };

                HttpRequest request = new HttpRequest();
                request.setEndpoint(HubpayIntegrationHelper.HUBPAY_BASE_URL + HubpayIntegrationHelper.ACCOUNT_SUBMIT_PATH);
                request.setMethod('PUT');
                request.setHeader('Accept', 'application/json');
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('AccountId', externalAccountId);
                request.setTimeout(HubpayIntegrationHelper.CALL_TIMEOUT_MS);
                HubpayIntegrationHelper.setAuthorizationHeader(request, http);
                request.setBody(JSON.serialize(payload));

                HttpResponse response = http.send(request);
                Integer code = response.getStatusCode();

                if (code >= 200 && code < 300) {
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_ERROR_MESSAGE,
                        null
                    );
                    currentResult.success = true;
                    currentResult.message = 'Hubpay account submitted successfully (STARTER tier).';
                } else {
                    String detailedError = HubpayIntegrationHelper.buildErrorMessage('Account submit failed', response, null);
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
                String detailedError = HubpayIntegrationHelper.buildErrorMessage('Account submit exception', null, ex);
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

    private static String readExternalAccountId(Account sourceAccount) {
        Object primaryExternalId = sourceAccount.get(HubpayIntegrationHelper.FIELD_EXTERNAL_ACCOUNT_ID);
        String externalAccountId = primaryExternalId == null ? null : String.valueOf(primaryExternalId).trim();
        if (String.isBlank(externalAccountId) && HubpayIntegrationHelper.getAccountFieldMap().containsKey('External_Id__c')) {
            Object fallbackExternalId = sourceAccount.get('External_Id__c');
            externalAccountId = fallbackExternalId == null ? null : String.valueOf(fallbackExternalId).trim();
        }
        return externalAccountId;
    }
}