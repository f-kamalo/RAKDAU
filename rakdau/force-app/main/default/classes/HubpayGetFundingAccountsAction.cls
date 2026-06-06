/**
 * @description Invocable action: GET Hubpay funding accounts for AED
 *              ({@link https://docs.hubpay.io/docs/financial-gateway-api/get-funding-accounts}).
 *              When {@link Request#completeAccountApproval} is true, chains {@link HubpayInviteUserAction}
 *              then persists Approved status, IBAN, and invite link in a single DML (no DML between callouts).
 */
public with sharing class HubpayGetFundingAccountsAction {
    public class Request {
        @InvocableVariable(required=true label='Account Id' description='Salesforce Account with Hubpay_External_ID__c set.')
        public Id accountId;

        @InvocableVariable(
            label='Complete Account Approval'
            description='When true: GET funding accounts, POST invite user, then update Hubpay_Account_Opening_Status__c=Approved, Hubpay_IBAN__c, and Hubpay_Link__c in one DML. Used after account.approved webhook.'
        )
        public Boolean completeAccountApproval;

        @InvocableVariable(
            label='Hubpay External Account Id'
            description='Optional Hubpay accountId UUID from webhook; used to load Account with SYSTEM_MODE when Site Guest cannot query by Salesforce Id.'
        )
        public String hubpayExternalAccountId;
    }

    public class Result {
        @InvocableVariable
        public Id accountId;
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String message;
        @InvocableVariable(label='Currency' description='Query currency sent to Hubpay (always AED).')
        public String currencyCode;
        @InvocableVariable(label='Response Body' description='Raw JSON response from Hubpay on success.')
        public String responseBody;
        @InvocableVariable(label='Funding Account Count' description='Number of funding account entries parsed from JSON when possible.')
        public Integer fundingAccountCount;
        @InvocableVariable(label='Hubpay IBAN' description='accountNumber from the first funding account in the response.')
        public String hubpayIban;
        @InvocableVariable(label='Invite URL' description='inviteUrl from invite user when completeAccountApproval is true.')
        public String inviteUrl;
    }

    /**
     * @description Outcome of funding-accounts GET without Account DML.
     */
    public class FundingCalloutOutcome {
        public Boolean success;
        public String message;
        public String responseBody;
        public Integer fundingAccountCount;
        public String accountNumber;
        public Integer httpStatusCode;
    }

    @InvocableMethod(
        label='Hubpay - Get Funding Accounts (AED)'
        description='GET /v1/funding-accounts?currency=AED. Set Complete Account Approval to chain invite and persist Approved + IBAN + Hubpay_Link__c after both callouts.'
        callout=true
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        for (Request req : requests) {
            Result currentResult = new Result();
            currentResult.accountId = req == null ? null : req.accountId;
            currentResult.currencyCode = HubpayIntegrationHelper.FUNDING_ACCOUNTS_CURRENCY_AED;
            currentResult.success = false;
            currentResult.message = 'Skipped';
            currentResult.fundingAccountCount = 0;

            if (req == null || req.accountId == null) {
                currentResult.message = 'accountId is required.';
                results.add(currentResult);
                continue;
            }

            if (req.completeAccountApproval == true) {
                results.add(orchestratePostAccountApproval(req.accountId, req.hubpayExternalAccountId));
            } else {
                results.add(fetchFundingAccountsOnly(req.accountId));
            }
        }

        return results;
    }

    /**
     * @description GET funding accounts, POST invite user, then one DML for Approved + IBAN + Hubpay_Link__c.
     */
    private static Result orchestratePostAccountApproval(Id accountId, String hubpayExternalAccountId) {
        Result currentResult = new Result();
        currentResult.accountId = accountId;
        currentResult.currencyCode = HubpayIntegrationHelper.FUNDING_ACCOUNTS_CURRENCY_AED;
        currentResult.success = false;
        currentResult.fundingAccountCount = 0;

        if (accountId == null || String.isBlank(hubpayExternalAccountId)) {
            currentResult.message = 'Account id and Hubpay external account id are required.';
            persistIntegrationError(accountId, currentResult.message);
            return currentResult;
        }

        Http http = new Http();
        FundingCalloutOutcome fundingOutcome = performFundingAccountsCallout(hubpayExternalAccountId.trim(), http);
        currentResult.responseBody = fundingOutcome.responseBody;
        currentResult.fundingAccountCount = fundingOutcome.fundingAccountCount == null ? 0 : fundingOutcome.fundingAccountCount;

        if (fundingOutcome.success != true) {
            currentResult.message = fundingOutcome.message;
            persistIntegrationError(accountId, currentResult.message);
            return currentResult;
        }

        if (String.isBlank(fundingOutcome.accountNumber)) {
            currentResult.message =
                'Funding accounts retrieved but no accountNumber was found in the Hubpay response.';
            persistIntegrationError(accountId, currentResult.message);
            return currentResult;
        }

        currentResult.hubpayIban = fundingOutcome.accountNumber;

        HubpayInviteUserAction.CalloutOutcome inviteOutcome = HubpayInviteUserAction.performInviteCallout(
            accountId,
            hubpayExternalAccountId.trim()
        );
        if (inviteOutcome.success != true) {
            currentResult.message = inviteOutcome.message;
            persistIntegrationError(accountId, currentResult.message);
            return currentResult;
        }

        currentResult.inviteUrl = inviteOutcome.inviteUrl;
        persistPostApprovalSuccess(accountId, fundingOutcome.accountNumber, inviteOutcome.inviteUrl);
        currentResult.success = true;
        currentResult.message =
            'Account approved: funding account, invite user, and Account fields updated (Approved, Hubpay_IBAN__c, Hubpay_Link__c).';
        return currentResult;
    }

    /**
     * @description Funding GET callout only; returns parsed values without Account DML.
     */
    private static Result fetchFundingAccountsOnly(Id accountId) {
        Result currentResult = new Result();
        currentResult.accountId = accountId;
        currentResult.currencyCode = HubpayIntegrationHelper.FUNDING_ACCOUNTS_CURRENCY_AED;
        currentResult.success = false;
        currentResult.fundingAccountCount = 0;

        Map<Id, Account> accountById = HubpayIntegrationHelper.loadAccountsByIdsSystemMode(new Set<Id>{ accountId });
        if (!accountById.containsKey(accountId)) {
            currentResult.message = 'Account not found.';
            return currentResult;
        }

        FundingCalloutOutcome fundingOutcome = performFundingAccountsCallout(accountById.get(accountId), new Http());
        currentResult.responseBody = fundingOutcome.responseBody;
        currentResult.fundingAccountCount = fundingOutcome.fundingAccountCount == null ? 0 : fundingOutcome.fundingAccountCount;
        currentResult.message = fundingOutcome.message;
        currentResult.success = fundingOutcome.success;
        currentResult.hubpayIban = fundingOutcome.accountNumber;
        return currentResult;
    }

    /**
     * @description Performs GET /v1/funding-accounts without Account DML (loads Hubpay id from Account — Flow/interactive users).
     */
    public static FundingCalloutOutcome performFundingAccountsCallout(Account sourceAccount, Http http) {
        if (sourceAccount == null || sourceAccount.Id == null) {
            FundingCalloutOutcome outcome = new FundingCalloutOutcome();
            outcome.success = false;
            outcome.message = 'Account is required.';
            return outcome;
        }
        Map<Id, Account> accountById = HubpayIntegrationHelper.loadAccountsByIdsSystemMode(new Set<Id>{ sourceAccount.Id });
        Account loaded = accountById.get(sourceAccount.Id);
        if (loaded == null) {
            FundingCalloutOutcome outcome = new FundingCalloutOutcome();
            outcome.success = false;
            outcome.message = 'Account not found.';
            return outcome;
        }
        return performFundingAccountsCallout(readExternalAccountId(loaded), http);
    }

    /**
     * @description Performs GET /v1/funding-accounts using Hubpay account UUID (no Account SOQL — required for Site Guest webhook).
     */
    public static FundingCalloutOutcome performFundingAccountsCallout(String hubpayExternalAccountId, Http http) {
        FundingCalloutOutcome outcome = new FundingCalloutOutcome();
        outcome.success = false;
        outcome.message = 'Skipped';
        outcome.fundingAccountCount = 0;

        if (String.isBlank(hubpayExternalAccountId)) {
            outcome.message = 'Missing Hubpay external account id.';
            return outcome;
        }
        if (http == null) {
            http = new Http();
        }

        try {
            String externalAccountId = hubpayExternalAccountId.trim();

            HttpRequest request = new HttpRequest();
            request.setEndpoint(HubpayIntegrationHelper.buildFundingAccountsGetEndpoint());
            request.setMethod('GET');
            request.setHeader('Accept', 'application/json');
            request.setHeader('AccountId', externalAccountId);
            request.setTimeout(HubpayIntegrationHelper.CALL_TIMEOUT_MS);
            HubpayIntegrationHelper.setAuthorizationHeader(request, http);

            HttpResponse response = http.send(request);
            Integer statusCode = response.getStatusCode();
            outcome.httpStatusCode = statusCode;
            String body = response == null ? null : response.getBody();
            outcome.responseBody = body;

            if (statusCode >= 200 && statusCode < 300) {
                List<Object> fundingEntries = extractFundingAccountEntries(body);
                outcome.fundingAccountCount = fundingEntries.size();
                outcome.accountNumber = extractFirstAccountNumber(fundingEntries);
                outcome.success = true;
                outcome.message =
                    'Funding accounts retrieved for ' +
                    HubpayIntegrationHelper.FUNDING_ACCOUNTS_CURRENCY_AED +
                    ' (count=' +
                    outcome.fundingAccountCount +
                    ').';
            } else {
                outcome.message = HubpayIntegrationHelper.buildErrorMessage('Get funding accounts failed', response, null);
            }
        } catch (Exception ex) {
            outcome.message = HubpayIntegrationHelper.buildErrorMessage('Get funding accounts exception', null, ex);
        }

        return outcome;
    }

    private static void persistPostApprovalSuccess(Id accountId, String accountNumber, String inviteUrl) {
        if (accountId == null) {
            return;
        }
        Account accountUpdate = new Account(Id = accountId);
        HubpayIntegrationHelper.putAccountFieldIfPresent(
            accountUpdate,
            HubpayIntegrationHelper.FIELD_STATUS,
            HubpayIntegrationHelper.WEBHOOK_ACCOUNT_STATUS_APPROVED
        );
        HubpayIntegrationHelper.putAccountFieldIfPresent(
            accountUpdate,
            HubpayIntegrationHelper.FIELD_HUBPAY_IBAN,
            accountNumber
        );
        if (String.isNotBlank(inviteUrl)) {
            HubpayIntegrationHelper.putAccountFieldIfPresent(
                accountUpdate,
                HubpayIntegrationHelper.FIELD_HUBPAY_LINK,
                inviteUrl
            );
        }
        HubpayIntegrationHelper.putAccountFieldIfPresent(accountUpdate, HubpayIntegrationHelper.FIELD_ERROR_MESSAGE, null);
        persistAccountUpdate(accountUpdate);
    }

    private static void persistIntegrationError(Id accountId, String errorMessage) {
        if (accountId == null) {
            return;
        }
        Account accountUpdate = new Account(Id = accountId);
        HubpayIntegrationHelper.putAccountFieldIfPresent(
            accountUpdate,
            HubpayIntegrationHelper.FIELD_STATUS,
            HubpayIntegrationHelper.STATUS_INTEGRATION_ERROR
        );
        HubpayIntegrationHelper.putAccountFieldIfPresent(
            accountUpdate,
            HubpayIntegrationHelper.FIELD_ERROR_MESSAGE,
            errorMessage
        );
        persistAccountUpdate(accountUpdate);
    }

    private static void persistAccountUpdate(Account accountUpdate) {
        Map<String, Object> populated = accountUpdate == null ? null : accountUpdate.getPopulatedFieldsAsMap();
        if (populated == null || populated.size() <= 1) {
            return;
        }
        new AccountUpdateWorker().persist(accountUpdate);
    }

    /**
     * @description Without-sharing worker for the final Account update. The webhook Site Guest user has no
     *              record-level edit access to the Account; AccessLevel.SYSTEM_MODE bypasses CRUD/FLS but
     *              sharing follows the class sharing keyword, so the DML must run without sharing to persist.
     */
    private without sharing class AccountUpdateWorker {
        public void persist(Account accountUpdate) {
            Database.SaveResult saveResult = Database.update(accountUpdate, false, AccessLevel.SYSTEM_MODE);
            if (saveResult != null && !saveResult.isSuccess()) {
                List<String> errorMessages = new List<String>();
                for (Database.Error dmlError : saveResult.getErrors()) {
                    errorMessages.add(dmlError.getStatusCode() + ': ' + dmlError.getMessage());
                }
                System.debug(
                    LoggingLevel.ERROR,
                    'Hubpay Account update failed for ' + accountUpdate.Id + ' — ' + String.join(errorMessages, ' | ')
                );
            }
        }
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

    private static List<Object> extractFundingAccountEntries(String responseBodyText) {
        List<Object> entries = new List<Object>();
        if (String.isBlank(responseBodyText)) {
            return entries;
        }
        try {
            Object root = JSON.deserializeUntyped(responseBodyText.trim());
            if (root instanceof List<Object>) {
                return (List<Object>) root;
            }
            if (root instanceof Map<String, Object>) {
                Map<String, Object> rootMap = (Map<String, Object>) root;
                for (String key : new List<String>{ 'data', 'fundingAccounts', 'items', 'accounts' }) {
                    Object node = rootMap.get(key);
                    if (node instanceof List<Object>) {
                        return (List<Object>) node;
                    }
                }
                if (rootMap.containsKey('accountNumber')) {
                    entries.add(rootMap);
                    return entries;
                }
            }
        } catch (Exception parseEx) {
            System.debug(
                LoggingLevel.WARN,
                'HubpayGetFundingAccountsAction: could not parse funding accounts JSON — ' + parseEx.getMessage()
            );
        }
        return entries;
    }

    private static String extractFirstAccountNumber(List<Object> fundingEntries) {
        if (fundingEntries == null || fundingEntries.isEmpty()) {
            return null;
        }
        for (Object entry : fundingEntries) {
            if (!(entry instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> entryMap = (Map<String, Object>) entry;
            String accountNumber = stringValueFromMap(entryMap, 'accountNumber');
            if (String.isBlank(accountNumber)) {
                accountNumber = stringValueFromMap(entryMap, 'account_number');
            }
            if (String.isNotBlank(accountNumber)) {
                return accountNumber.trim();
            }
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