/**
 * @description Invocable action: POST Hubpay users invite with Account primary contact ({@code email}, {@code fullName}, {@code role} OWNER).
 */
public with sharing class HubpayInviteUserAction {
    private static final String ROLE_OWNER = 'OWNER';

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
        @InvocableVariable(label='Invite URL' description='inviteUrl from Hubpay invite response.')
        public String inviteUrl;
    }

    /**
     * @description Outcome of invite HTTP callout without Account DML (for post-approval orchestration).
     */
    public class CalloutOutcome {
        public Boolean success;
        public String message;
        public String inviteUrl;
        public Integer httpStatusCode;
        public Boolean alreadyInvited;
    }

    @InvocableMethod(
        label='Hubpay - Invite User (Primary Contact)'
        description='POST /v1/account/users/invite with primary contact email, full name, and role OWNER; AccountId header from Hubpay external id.'
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

        List<Account> accountsToUpdate = new List<Account>();

        for (Request req : requests) {
            Result currentResult = new Result();
            currentResult.accountId = req == null ? null : req.accountId;
            currentResult.success = false;
            currentResult.message = 'Skipped';

            if (req == null || req.accountId == null) {
                currentResult.message = 'accountId is required.';
                results.add(currentResult);
                continue;
            }

            Account accountUpdate = new Account(Id = req.accountId);
            CalloutOutcome calloutOutcome = performInviteCallout(req.accountId);
            applyCalloutOutcomeToAccount(accountUpdate, calloutOutcome);
            applyCalloutOutcomeToResult(currentResult, calloutOutcome);
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
     * @description Performs invite callout only (no DML). Used by {@link HubpayGetFundingAccountsAction} post-approval orchestration.
     */
    public static CalloutOutcome performInviteCallout(Id accountId) {
        return performInviteCallout(accountId, null);
    }

    /**
     * @description Invite callout using Hubpay account UUID from webhook (avoids Account SOQL for Site Guest).
     */
    public static CalloutOutcome performInviteCallout(Id accountId, String hubpayExternalAccountId) {
        CalloutOutcome outcome = new CalloutOutcome();
        outcome.success = false;
        outcome.message = 'Skipped';

        if (accountId == null) {
            outcome.message = 'accountId is required.';
            return outcome;
        }

        String externalAccountId = String.isBlank(hubpayExternalAccountId) ? null : hubpayExternalAccountId.trim();
        if (String.isBlank(externalAccountId)) {
            Map<Id, Account> accountById = HubpayIntegrationHelper.loadAccountsByIdsSystemMode(new Set<Id>{ accountId });
            Account sourceAccount = accountById.get(accountId);
            if (sourceAccount == null) {
                outcome.message = 'Account not found.';
                return outcome;
            }
            externalAccountId = readExternalAccountId(sourceAccount);
            if (String.isBlank(externalAccountId)) {
                outcome.message = 'Missing Hubpay external account id.';
                return outcome;
            }
        }

        Map<Id, Contact> primaryContactByAccountId = HubpayIntegrationHelper.loadPrimaryContactsByAccountIdsSystemMode(
            new Set<Id>{ accountId }
        );

        try {
            Contact primaryContact = primaryContactByAccountId.get(accountId);
            if (primaryContact == null) {
                outcome.message = 'Primary Contact not found: no Service Request (WorkOrder) with a Contact is linked to this Account.';
                return outcome;
            }

            String email = primaryContact.Email == null ? null : primaryContact.Email.trim();
            if (String.isBlank(email)) {
                outcome.message = 'Primary Contact email is required.';
                return outcome;
            }

            String fullName = buildFullName(primaryContact);
            if (String.isBlank(fullName)) {
                outcome.message = 'Primary Contact name is required.';
                return outcome;
            }

            Map<String, Object> payload = new Map<String, Object>{
                'email' => email,
                'fullName' => fullName,
                'role' => ROLE_OWNER
            };

            HttpRequest request = new HttpRequest();
            request.setEndpoint(HubpayIntegrationHelper.HUBPAY_BASE_URL + HubpayIntegrationHelper.USERS_INVITE_PATH);
            request.setMethod('POST');
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(HubpayIntegrationHelper.CALL_TIMEOUT_MS);
            Http http = new Http();
            HubpayIntegrationHelper.setAuthorizationHeader(request, http);
            request.setHeader('AccountId', externalAccountId);
            request.setBody(JSON.serialize(payload));

            HttpResponse response = http.send(request);
            Integer code = response.getStatusCode();
            outcome.httpStatusCode = code;

            if (code >= 200 && code < 300) {
                outcome.inviteUrl = extractInviteUrlFromResponse(response == null ? null : response.getBody());
                if (String.isBlank(outcome.inviteUrl)) {
                    outcome.message = 'Invite succeeded (HTTP ' + code + ') but inviteUrl was missing in the response body.';
                    return outcome;
                }
                outcome.success = true;
                outcome.message = 'Hubpay user invite sent successfully.';
            } else if (isAlreadyInvitedConflict(code, response == null ? null : response.getBody())) {
                outcome.success = true;
                outcome.alreadyInvited = true;
                outcome.message = 'Hubpay user invite already exists for this email; treating as success.';
            } else {
                outcome.message = HubpayIntegrationHelper.buildErrorMessage('Invite user failed', response, null);
            }
        } catch (Exception ex) {
            outcome.message = HubpayIntegrationHelper.buildErrorMessage('Invite user exception', null, ex);
        }

        return outcome;
    }

    private static void applyCalloutOutcomeToAccount(Account accountUpdate, CalloutOutcome calloutOutcome) {
        if (accountUpdate == null || calloutOutcome == null) {
            return;
        }
        if (calloutOutcome.success) {
            HubpayIntegrationHelper.setFieldValue(accountUpdate, HubpayIntegrationHelper.FIELD_ERROR_MESSAGE, null);
            HubpayIntegrationHelper.setFieldValue(
                accountUpdate,
                HubpayIntegrationHelper.FIELD_HUBPAY_LINK,
                calloutOutcome.inviteUrl
            );
            return;
        }
        HubpayIntegrationHelper.setFieldValue(
            accountUpdate,
            HubpayIntegrationHelper.FIELD_STATUS,
            HubpayIntegrationHelper.STATUS_INTEGRATION_ERROR
        );
        HubpayIntegrationHelper.setFieldValue(
            accountUpdate,
            HubpayIntegrationHelper.FIELD_ERROR_MESSAGE,
            calloutOutcome.message
        );
    }

    private static void applyCalloutOutcomeToResult(Result currentResult, CalloutOutcome calloutOutcome) {
        if (currentResult == null || calloutOutcome == null) {
            return;
        }
        currentResult.success = calloutOutcome.success;
        currentResult.message = calloutOutcome.message;
        currentResult.inviteUrl = calloutOutcome.inviteUrl;
    }

    private static String readExternalAccountId(Account sourceAccount) {
        Object externalIdRaw = sourceAccount.get(HubpayIntegrationHelper.FIELD_EXTERNAL_ACCOUNT_ID);
        String externalAccountId = externalIdRaw == null ? null : String.valueOf(externalIdRaw).trim();
        if (String.isBlank(externalAccountId) && HubpayIntegrationHelper.getAccountFieldMap().containsKey('External_Id__c')) {
            Object hubpayExternalIdRaw = sourceAccount.get('External_Id__c');
            externalAccountId = hubpayExternalIdRaw == null ? null : String.valueOf(hubpayExternalIdRaw).trim();
        }
        return externalAccountId;
    }

    private static String buildFullName(Contact c) {
        if (c == null) {
            return null;
        }
        if (!String.isBlank(c.Name)) {
            return c.Name.trim();
        }
        String first = c.FirstName == null ? '' : c.FirstName.trim();
        String last = c.LastName == null ? '' : c.LastName.trim();
        String combined = (first + ' ' + last).trim();
        return String.isBlank(combined) ? null : combined;
    }

    /**
     * @description Hubpay returns HTTP 409 with a "pending invite already exists" conflict when the email was
     *              already invited. The user is effectively invited, so this is treated as a success outcome.
     */
    private static Boolean isAlreadyInvitedConflict(Integer statusCode, String responseBody) {
        if (statusCode != 409 || String.isBlank(responseBody)) {
            return false;
        }
        String body = responseBody.toLowerCase();
        return body.contains('already exists') || body.contains('pending invite');
    }

    private static String extractInviteUrlFromResponse(String responseBody) {
        if (String.isBlank(responseBody)) {
            return null;
        }
        try {
            Object parsed = JSON.deserializeUntyped(responseBody.trim());
            if (parsed instanceof Map<String, Object>) {
                Map<String, Object> bodyMap = (Map<String, Object>) parsed;
                String direct = stringValueFromMap(bodyMap, 'inviteUrl');
                if (String.isNotBlank(direct)) {
                    return direct;
                }
                Object dataNode = bodyMap.get('data');
                if (dataNode instanceof Map<String, Object>) {
                    return stringValueFromMap((Map<String, Object>) dataNode, 'inviteUrl');
                }
            }
        } catch (Exception ignore) {
            return null;
        }
        return null;
    }

    private static String stringValueFromMap(Map<String, Object> valueMap, String key) {
        if (valueMap == null || String.isBlank(key) || !valueMap.containsKey(key)) {
            return null;
        }
        Object raw = valueMap.get(key);
        if (raw == null) {
            return null;
        }
        String text = String.valueOf(raw).trim();
        return String.isBlank(text) ? null : text;
    }
}