public with sharing class HubpayUpdateProfileAction {
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

    @InvocableMethod(label='Hubpay - Update Business Profile' description='Updates Hubpay business profile and advances Account onboarding status.' callout=true)
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
        Map<Id, Set<String>> industriesByAccountId = new Map<Id, Set<String>>();
        if (!accountIds.isEmpty()) {
            List<String> queryFields = new List<String>{ 'Id', 'Name' };
            if (HubpayIntegrationHelper.getAccountFieldMap().containsKey('External_Id__c')) {
                queryFields.add('External_Id__c');
            }
            if (HubpayIntegrationHelper.getAccountFieldMap().containsKey('Hubpay_External_ID__c')) {
                queryFields.add('Hubpay_External_ID__c');
            }
            List<String> mappedAccountFields = new List<String>{
                'Has_Bank_Account__c',
                'Years_Of_Business_Range__c',
                'Number_Of_Employees_Range__c',
                'Annual_Revenue__c',
                'Product_or_Service_Sold__c',
                'Intended_Sales_Channel__c',
                'Sales_Distribution_Channels__c',
                'Incoming_Payment_Countries__c',
                'Incoming_Payments_Monthly_Count__c',
                'Incoming_Payments_Monthly_Volume__c',
                'Outgoing_Payment_Countries__c',
                'Outgoing_Payments_Monthly_Volume__c',
                'Outgoing_Payments_Monthly_Count__c',
                'Account_Opening_Purposes__c',
                'Website',
                'Investment_Source_Of_Funds_Type__c',
                'Investment_Source_Of_Funds_Description__c'
            };
            for (String fieldName : mappedAccountFields) {
                if (HubpayIntegrationHelper.getAccountFieldMap().containsKey(fieldName)) {
                    queryFields.add(fieldName);
                }
            }
            String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Account WHERE Id IN :accountIds';
            for (SObject sobj : Database.query(query)) {
                Account acc = (Account) sobj;
                accountById.put(acc.Id, acc);
            }

            for (Business_Activity__c businessActivity : [
                SELECT Account__c, Hubpay_Category__c, Activity__r.Hubpay_Category__c
                FROM Business_Activity__c
                WHERE Account__c IN :accountIds
            ]) {
                if (!industriesByAccountId.containsKey(businessActivity.Account__c)) {
                    industriesByAccountId.put(businessActivity.Account__c, new Set<String>());
                }
                Set<String> accountIndustries = industriesByAccountId.get(businessActivity.Account__c);
                accountIndustries.addAll(splitToList(businessActivity.Hubpay_Category__c));
                if (businessActivity.Activity__r != null) {
                    accountIndustries.addAll(splitToList(businessActivity.Activity__r.Hubpay_Category__c));
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
                Object externalIdRaw = sourceAccount.get('Hubpay_External_ID__c');
                String externalAccountId = externalIdRaw == null ? null : String.valueOf(externalIdRaw).trim();
                if (String.isBlank(externalAccountId)) {
                    Object hubpayExternalIdRaw = sourceAccount.get('External_Id__c');
                    externalAccountId = hubpayExternalIdRaw == null ? null : String.valueOf(hubpayExternalIdRaw).trim();
                }
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

                Object industriesPayload = null;
                if (industriesByAccountId.containsKey(sourceAccount.Id) && !industriesByAccountId.get(sourceAccount.Id).isEmpty()) {
                    industriesPayload = new List<String>(industriesByAccountId.get(sourceAccount.Id));
                }

                Map<String, Object> payload = new Map<String, Object>{
                    'accountName' => stringOrNull(sourceAccount.Name),
                    'countryOfRegistration' => 'AE',
                    'industries' => industriesPayload,
                    'legalType' => 'LIMITED_LIABILITY_COMPANY',
                    'incorporatedInUae' => true,
                    'hasBankAccount' => booleanOrNull(sourceAccount.get('Has_Bank_Account__c')),
                    'yearsOfBusinessRange' => stringOrNull(sourceAccount.get('Years_Of_Business_Range__c')),
                    'numberOfEmployeesRange' => stringOrNull(sourceAccount.get('Number_Of_Employees_Range__c')),
                    'annualRevenue' => decimalOrNull(sourceAccount.get('Annual_Revenue__c')),
                    'website' => stringOrNull(sourceAccount.get('Website')),
                    'productOrServiceSold' => stringOrNull(sourceAccount.get('Product_or_Service_Sold__c')),
                    'intendedSalesChannel' => stringOrNull(sourceAccount.get('Intended_Sales_Channel__c')),
                    'salesDistributionChannels' => stringListOrNull(sourceAccount.get('Sales_Distribution_Channels__c')),
                    'incomingPaymentCountries' => stringListOrNull(sourceAccount.get('Incoming_Payment_Countries__c')),
                    'incomingPaymentsMonthlyVolume' => decimalOrNull(sourceAccount.get('Incoming_Payments_Monthly_Volume__c')),
                    'incomingPaymentsMonthlyCount' => integerOrNull(sourceAccount.get('Incoming_Payments_Monthly_Count__c')),
                    'outgoingPaymentCountries' => stringListOrNull(sourceAccount.get('Outgoing_Payment_Countries__c')),
                    'outgoingPaymentsMonthlyVolume' => decimalOrNull(sourceAccount.get('Outgoing_Payments_Monthly_Volume__c')),
                    'outgoingPaymentsMonthlyCount' => integerOrNull(sourceAccount.get('Outgoing_Payments_Monthly_Count__c')),
                    'accountOpeningPurposes' => stringListOrNull(sourceAccount.get('Account_Opening_Purposes__c')),
                    'investmentSourceOfFunds' => buildInvestmentSourceOfFunds(sourceAccount)
                };

                HttpRequest request = new HttpRequest();
                request.setEndpoint(HubpayIntegrationHelper.HUBPAY_BASE_URL + HubpayIntegrationHelper.UPDATE_PROFILE_PATH);
                request.setMethod('PUT');
                request.setHeader('Accept', 'application/json');
                request.setHeader('Content-Type', 'application/json');
                request.setTimeout(HubpayIntegrationHelper.CALL_TIMEOUT_MS);
                HubpayIntegrationHelper.setAuthorizationHeader(request, http);
                request.setHeader('AccountId', externalAccountId);
                request.setBody(JSON.serialize(payload));

                HttpResponse response = http.send(request);
                Integer code = response.getStatusCode();

                if (code >= 200 && code < 300) {
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_STATUS,
                        HubpayIntegrationHelper.STATUS_PENDING_PROFILE_ELIGIBILITY_CHECK
                    );
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_ERROR_MESSAGE,
                        null
                    );

                    currentResult.success = true;
                    currentResult.message = 'Hubpay business profile updated successfully.';
                } else {
                    String detailedError = HubpayIntegrationHelper.buildErrorMessage('Update profile failed', response, null);
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
                String detailedError = HubpayIntegrationHelper.buildErrorMessage('Update profile exception', null, ex);
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
            Database.SaveResult[] saveResults = Database.update(accountsToUpdate, false);
            for (Integer i = 0; i < saveResults.size(); i++) {
                Id rowId = accountsToUpdate[i].Id;
                if (!saveResults[i].isSuccess()) {
                    String dmlErrorMessage = null;
                    for (Database.Error err : saveResults[i].getErrors()) {
                        dmlErrorMessage = 'DML failed for Account ' + rowId + ': ' + err.getStatusCode() + ' - ' + err.getMessage();
                        break;
                    }
                    for (Result resultRow : results) {
                        if (resultRow != null && resultRow.accountId == rowId) {
                            resultRow.success = false;
                            resultRow.message = dmlErrorMessage;
                            break;
                        }
                    }
                }
            }
        }
        return results;
    }

    /**
     * @description Builds the {@code investmentSourceOfFunds} nested object from Account fields
     *              {@code Investment_Source_Of_Funds_Type__c} and {@code Investment_Source_Of_Funds_Description__c}.
     *              Returns {@code null} when both are blank/absent so the key serializes as null (key omitted only if Hubpay accepts that).
     */
    private static Object buildInvestmentSourceOfFunds(Account sourceAccount) {
        Map<String, Schema.SObjectField> accountFieldMap = HubpayIntegrationHelper.getAccountFieldMap();
        String fundsType = null;
        if (accountFieldMap.containsKey('Investment_Source_Of_Funds_Type__c')) {
            fundsType = stringOrNull(sourceAccount.get('Investment_Source_Of_Funds_Type__c'));
        }
        String fundsDescription = null;
        if (accountFieldMap.containsKey('Investment_Source_Of_Funds_Description__c')) {
            fundsDescription = stringOrNull(sourceAccount.get('Investment_Source_Of_Funds_Description__c'));
        }
        if (String.isBlank(fundsType) && String.isBlank(fundsDescription)) {
            return null;
        }
        return new Map<String, Object>{
            'type' => fundsType,
            'description' => fundsDescription
        };
    }

    /** @description Null or blank (after trim) → JSON null via Apex null in the payload map. */
    private static String stringOrNull(Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        String value = String.valueOf(rawValue).trim();
        return String.isBlank(value) ? null : value;
    }

    private static Boolean booleanOrNull(Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        if (rawValue instanceof Boolean) {
            return (Boolean) rawValue;
        }
        String value = String.valueOf(rawValue).trim().toLowerCase();
        if ('true'.equals(value)) {
            return true;
        }
        if ('false'.equals(value)) {
            return false;
        }
        return null;
    }

    private static Decimal decimalOrNull(Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        if (rawValue instanceof Decimal) {
            return (Decimal) rawValue;
        }
        if (rawValue instanceof Integer) {
            return Decimal.valueOf(String.valueOf((Integer) rawValue));
        }
        if (rawValue instanceof Long) {
            return Decimal.valueOf(String.valueOf((Long) rawValue));
        }
        try {
            return Decimal.valueOf(String.valueOf(rawValue).trim());
        } catch (Exception ex) {
            return null;
        }
    }

    private static Integer integerOrNull(Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        if (rawValue instanceof Integer) {
            return (Integer) rawValue;
        }
        if (rawValue instanceof Long) {
            return Integer.valueOf(String.valueOf((Long) rawValue));
        }
        if (rawValue instanceof Decimal) {
            return ((Decimal) rawValue).intValue();
        }
        try {
            return Integer.valueOf(String.valueOf(rawValue).trim());
        } catch (Exception ex) {
            return null;
        }
    }

    /** @description Null, blank, or no tokens after split → null (omit empty list so Hubpay receives null). */
    private static Object stringListOrNull(Object rawValue) {
        List<String> values = splitToList(rawValue == null ? null : String.valueOf(rawValue));
        return values.isEmpty() ? null : (Object) values;
    }

    private static List<String> splitToList(String rawValue) {
        List<String> values = new List<String>();
        if (String.isBlank(rawValue)) {
            return values;
        }
        String normalized = rawValue.replace(';', ',');
        for (String token : normalized.split(',')) {
            String trimmed = token == null ? null : token.trim();
            if (!String.isBlank(trimmed) && !values.contains(trimmed)) {
                values.add(trimmed);
            }
        }
        return values;
    }
}