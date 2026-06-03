/**
 * @description POST {@code /v1/account/related-party/corporates}. With {@code stakeholderDetailId}, builds body from corporate stakeholder + checklist Hubpay upload ids.
 */
public with sharing class HubpayAddCorporateShareholderAction {
    private static final String API_DEBUG_PREFIX = 'HubpayShareholderSync API corporates';

    private static final String RELATIONSHIP_PARENT = 'PARENT';
    private static final String HUBPAY_TRADE_LICENSE = 'TRADE_LICENSE';
    private static final String HUBPAY_MOA_OR_AOA = 'MEMORANDUM_OF_ASSOCIATION_OR_ARTICLES_OF_ASSOCIATION';

    private static final String FIELD_STAKEHOLDER_PERCENTAGE_SHARES = 'Percentage_of_Shares__c';

    /** @description Legacy Flow-only path when {@code stakeholderDetailId} is omitted. */
    private static final String STATIC_DOCUMENT_UPLOAD_ID = '3fa85f64-5717-4562-b3fc-2c963f66afa6';

    public class Request {
        @InvocableVariable(required=true)
        public Id accountId;

        @InvocableVariable
        public Id stakeholderDetailId;
    }

    public class Result {
        @InvocableVariable
        public Id accountId;

        @InvocableVariable
        public Id stakeholderDetailId;

        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String message;
    }

    private class CorporatePayloadContext {
        Id businessAccountId;
        String corporateName;
        Decimal sharePercentageOwned;
        String tradeLicenseHubpayId;
        String memorandumHubpayId;
        String prepareError;
    }

    @InvocableMethod(
        label='Hubpay - Add Corporate Shareholder (Related Party)'
        description='POST /v1/account/related-party/corporates. Pass stakeholderDetailId to map name, Percentage_of_Shares__c, and TRADE_LICENSE / MOA DCIs Hubpay_External_ID__c.'
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
                r.stakeholderDetailId = req == null ? null : req.stakeholderDetailId;
                r.success = false;
                r.message = 'No Account update permission.';
                results.add(r);
            }
            return results;
        }

        Set<Id> accountIds = new Set<Id>();
        Set<Id> stakeholderDetailIds = new Set<Id>();
        for (Request req : requests) {
            if (req != null && req.accountId != null) {
                accountIds.add(req.accountId);
            }
            if (req != null && req.stakeholderDetailId != null) {
                stakeholderDetailIds.add(req.stakeholderDetailId);
            }
        }

        Map<Id, Account> accountById = queryAccounts(accountIds);
        Map<Id, CorporatePayloadContext> contextByStakeholderId = buildCorporatePayloadContexts(stakeholderDetailIds, accountIds);

        Http http = new Http();
        Map<Id, Account> accountsToUpdateById = new Map<Id, Account>();

        for (Request req : requests) {
            Result currentResult = new Result();
            currentResult.accountId = req == null ? null : req.accountId;
            currentResult.stakeholderDetailId = req == null ? null : req.stakeholderDetailId;
            currentResult.success = false;
            currentResult.message = 'Skipped';

            if (req == null || req.accountId == null || !accountById.containsKey(req.accountId)) {
                currentResult.message = 'Account not found.';
                results.add(currentResult);
                continue;
            }

            Account sourceAccount = accountById.get(req.accountId);
            Account accountUpdate = new Account(Id = sourceAccount.Id);

            Map<String, Object> payload;
            if (req.stakeholderDetailId != null) {
                CorporatePayloadContext ctx = contextByStakeholderId.get(req.stakeholderDetailId);
                if (ctx == null || !String.isBlank(ctx.prepareError)) {
                    String err = ctx == null ? 'Stakeholder row not found.' : ctx.prepareError;
                    flagAccountIntegrationError(accountUpdate, err);
                    currentResult.message = err;
                    accountsToUpdateById.put(accountUpdate.Id, accountUpdate);
                    results.add(currentResult);
                    continue;
                }
                if (ctx.businessAccountId != req.accountId) {
                    String err = 'stakeholderDetailId belongs to a different Business_Account__c than accountId on the request.';
                    flagAccountIntegrationError(accountUpdate, err);
                    currentResult.message = err;
                    accountsToUpdateById.put(accountUpdate.Id, accountUpdate);
                    results.add(currentResult);
                    continue;
                }
                payload = buildPayloadFromContext(ctx);
            } else {
                payload = buildStaticCorporatePayload();
            }

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
                    accountsToUpdateById.put(accountUpdate.Id, accountUpdate);
                    results.add(currentResult);
                    continue;
                }

                HttpRequest httpReq = new HttpRequest();
                httpReq.setEndpoint(HubpayIntegrationHelper.HUBPAY_BASE_URL + HubpayIntegrationHelper.RELATED_PARTY_CORPORATES_PATH);
                httpReq.setMethod('POST');
                httpReq.setHeader('Accept', 'application/json');
                httpReq.setHeader('Content-Type', 'application/json');
                httpReq.setHeader('AccountId', externalAccountId);
                httpReq.setTimeout(HubpayIntegrationHelper.CALL_TIMEOUT_MS);
                HubpayIntegrationHelper.setAuthorizationHeader(httpReq, http);
                String jsonBody = JSON.serialize(payload);
                System.debug(
                    LoggingLevel.INFO,
                    API_DEBUG_PREFIX + ' POST ' + HubpayIntegrationHelper.RELATED_PARTY_CORPORATES_PATH + ' salesforceAccountId=' + req.accountId +
                        ' stakeholderDetailId=' + req.stakeholderDetailId
                );
                httpReq.setBody(jsonBody);

                HttpResponse response = http.send(httpReq);
                Integer code = response.getStatusCode();
                String bodySnippet = truncateBodyForLog(response == null ? null : response.getBody());

                if (code >= 200 && code < 300) {
                    System.debug(
                        LoggingLevel.INFO,
                        API_DEBUG_PREFIX + ' SUCCESS HTTP ' + code + ' salesforceAccountId=' + req.accountId + ' responseBody=' + bodySnippet
                    );
                    HubpayIntegrationHelper.setFieldValue(
                        accountUpdate,
                        HubpayIntegrationHelper.FIELD_ERROR_MESSAGE,
                        null
                    );
                    currentResult.success = true;
                    currentResult.message = 'Hubpay corporate related party submitted successfully.';
                } else {
                    System.debug(
                        LoggingLevel.ERROR,
                        API_DEBUG_PREFIX + ' FAILED HTTP ' + code + ' salesforceAccountId=' + req.accountId + ' responseBody=' + bodySnippet
                    );
                    String detailedError = HubpayIntegrationHelper.buildErrorMessage(
                        'Add corporate shareholder / related party failed',
                        response,
                        null
                    );
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
                System.debug(
                    LoggingLevel.ERROR,
                    API_DEBUG_PREFIX + ' EXCEPTION salesforceAccountId=' + req.accountId + ' ' + ex.getMessage()
                );
                String detailedError = HubpayIntegrationHelper.buildErrorMessage(
                    'Add corporate shareholder / related party exception',
                    null,
                    ex
                );
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

            accountsToUpdateById.put(accountUpdate.Id, accountUpdate);
            results.add(currentResult);
        }

        if (!accountsToUpdateById.isEmpty()) {
            update accountsToUpdateById.values();
        }

        return results;
    }

    private static Map<Id, Account> queryAccounts(Set<Id> accountIds) {
        Map<Id, Account> accountById = new Map<Id, Account>();
        if (accountIds.isEmpty()) {
            return accountById;
        }
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
        return accountById;
    }

    private static Map<Id, CorporatePayloadContext> buildCorporatePayloadContexts(Set<Id> stakeholderDetailIds, Set<Id> accountIds) {
        Map<Id, CorporatePayloadContext> out = new Map<Id, CorporatePayloadContext>();
        if (stakeholderDetailIds.isEmpty() || accountIds.isEmpty()) {
            return out;
        }

        Map<String, Schema.SObjectField> sdFields = Schema.SObjectType.Stakeholder_Detail__c.fields.getMap();
        List<String> fieldsToSelect = new List<String>{
            'Id',
            'Business_Account__c',
            'Corporate_Stakeholder__c',
            'Corporate_Stakeholder__r.Name'
        };
        if (sdFields.containsKey(FIELD_STAKEHOLDER_PERCENTAGE_SHARES.toLowerCase())) {
            fieldsToSelect.add(FIELD_STAKEHOLDER_PERCENTAGE_SHARES);
        }

        String sdSoql = 'SELECT ' + String.join(fieldsToSelect, ',') + ' FROM Stakeholder_Detail__c WHERE Id IN :stakeholderDetailIds';
        Map<Id, Stakeholder_Detail__c> sdById = new Map<Id, Stakeholder_Detail__c>((List<Stakeholder_Detail__c>) Database.query(sdSoql));

        List<Document_Checklist_Item__c> dciRows = [
            SELECT Id, Name, Stakeholder_Detail__c, Hubpay_External_ID__c, Document_Type__r.Hubpay_Api_Name__c
            FROM Document_Checklist_Item__c
            WHERE Stakeholder_Detail__c IN :stakeholderDetailIds AND Account__c IN :accountIds
        ];

        Map<Id, Map<String, String>> hubpayIdByStakeholderAndDocType = new Map<Id, Map<String, String>>();
        for (Document_Checklist_Item__c dci : dciRows) {
            if (dci.Stakeholder_Detail__c == null || dci.Document_Type__r == null) {
                continue;
            }
            String apiName = dci.Document_Type__r.Hubpay_Api_Name__c;
            if (String.isBlank(apiName)) {
                continue;
            }
            String hubpayDocId = String.isBlank(dci.Hubpay_External_ID__c) ? null : dci.Hubpay_External_ID__c.trim();
            if (String.isBlank(hubpayDocId)) {
                continue;
            }
            apiName = apiName.trim();
            if (apiName != HUBPAY_TRADE_LICENSE && apiName != HUBPAY_MOA_OR_AOA) {
                continue;
            }
            if (!hubpayIdByStakeholderAndDocType.containsKey(dci.Stakeholder_Detail__c)) {
                hubpayIdByStakeholderAndDocType.put(dci.Stakeholder_Detail__c, new Map<String, String>());
            }
            hubpayIdByStakeholderAndDocType.get(dci.Stakeholder_Detail__c).put(apiName, hubpayDocId);
        }

        for (Id sdId : stakeholderDetailIds) {
            CorporatePayloadContext ctx = new CorporatePayloadContext();
            Stakeholder_Detail__c sd = sdById.get(sdId);
            if (sd == null) {
                ctx.prepareError = 'Stakeholder_Detail__c not found for Id ' + sdId + '.';
                out.put(sdId, ctx);
                continue;
            }
            ctx.businessAccountId = sd.Business_Account__c;
            if (sd.Business_Account__c == null || !accountIds.contains(sd.Business_Account__c)) {
                ctx.prepareError = 'Stakeholder Business_Account__c is missing or not included in this Hubpay batch.';
                out.put(sdId, ctx);
                continue;
            }
            if (sd.Corporate_Stakeholder__c == null) {
                ctx.prepareError = 'Stakeholder line is not a corporate shareholder (Corporate_Stakeholder__c is blank).';
                out.put(sdId, ctx);
                continue;
            }

            ctx.corporateName = sd.Corporate_Stakeholder__r == null ? null : sd.Corporate_Stakeholder__r.Name;
            if (String.isBlank(ctx.corporateName)) {
                ctx.prepareError = 'Corporate stakeholder name is blank.';
                out.put(sdId, ctx);
                continue;
            }
            ctx.corporateName = ctx.corporateName.trim();

            ctx.sharePercentageOwned = readPercentageShares(sd);

            Map<String, String> docMap = hubpayIdByStakeholderAndDocType.get(sdId);
            if (docMap == null) {
                docMap = new Map<String, String>();
            }
            ctx.tradeLicenseHubpayId = docMap.get(HUBPAY_TRADE_LICENSE);
            ctx.memorandumHubpayId = docMap.get(HUBPAY_MOA_OR_AOA);

            List<String> missing = new List<String>();
            if (String.isBlank(ctx.tradeLicenseHubpayId)) {
                missing.add(HUBPAY_TRADE_LICENSE + ' (Document_Checklist_Item__c.Hubpay_External_ID__c)');
            }
            if (String.isBlank(ctx.memorandumHubpayId)) {
                missing.add(HUBPAY_MOA_OR_AOA + ' (Document_Checklist_Item__c.Hubpay_External_ID__c)');
            }
            if (!missing.isEmpty()) {
                ctx.prepareError =
                    'Missing Hubpay upload id(s) for corporate shareholder DCIs: ' +
                    String.join(missing, ', ') +
                    '. Upload Trade License and MOA/AOA for this shareholder before completing Document Upload.';
                out.put(sdId, ctx);
                continue;
            }

            out.put(sdId, ctx);
        }

        return out;
    }

    private static Decimal readPercentageShares(Stakeholder_Detail__c sd) {
        if (sd == null) {
            return 0;
        }
        if (!Schema.SObjectType.Stakeholder_Detail__c.fields.getMap().containsKey(FIELD_STAKEHOLDER_PERCENTAGE_SHARES.toLowerCase())) {
            return 0;
        }
        Object raw = sd.get(FIELD_STAKEHOLDER_PERCENTAGE_SHARES);
        if (raw == null) {
            return 0;
        }
        if (raw instanceof Decimal) {
            return (Decimal) raw;
        }
        try {
            return Decimal.valueOf(String.valueOf(raw));
        } catch (Exception ex) {
            return 0;
        }
    }

    private static Map<String, Object> buildPayloadFromContext(CorporatePayloadContext ctx) {
        List<Object> attachedDocuments = new List<Object>{
            new Map<String, Object>{
                'type' => HUBPAY_TRADE_LICENSE,
                'documentIds' => new List<String>{ ctx.tradeLicenseHubpayId }
            },
            new Map<String, Object>{
                'type' => HUBPAY_MOA_OR_AOA,
                'documentIds' => new List<String>{ ctx.memorandumHubpayId }
            }
        };
        return new Map<String, Object>{
            'name' => ctx.corporateName,
            'relationship' => RELATIONSHIP_PARENT,
            'sharePercentageOwned' => ctx.sharePercentageOwned,
            'attachedDocuments' => attachedDocuments
        };
    }

    private static void flagAccountIntegrationError(Account accountUpdate, String message) {
        HubpayIntegrationHelper.setFieldValue(
            accountUpdate,
            HubpayIntegrationHelper.FIELD_STATUS,
            HubpayIntegrationHelper.STATUS_INTEGRATION_ERROR
        );
        HubpayIntegrationHelper.setFieldValue(accountUpdate, HubpayIntegrationHelper.FIELD_ERROR_MESSAGE, message);
    }

    private static Map<String, Object> buildStaticCorporatePayload() {
        List<String> staticIds = new List<String>{ STATIC_DOCUMENT_UPLOAD_ID };
        List<Object> attachedDocuments = new List<Object>{
            new Map<String, Object>{
                'type' => HUBPAY_TRADE_LICENSE,
                'documentIds' => staticIds
            },
            new Map<String, Object>{
                'type' => HUBPAY_MOA_OR_AOA,
                'documentIds' => staticIds
            }
        };
        return new Map<String, Object>{
            'name' => 'Corporate',
            'relationship' => RELATIONSHIP_PARENT,
            'sharePercentageOwned' => 50,
            'attachedDocuments' => attachedDocuments
        };
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

    private static String truncateBodyForLog(String body) {
        final Integer maxChars = 2000;
        if (String.isBlank(body)) {
            return '(empty body)';
        }
        if (body.length() <= maxChars) {
            return body;
        }
        return body.substring(0, maxChars) + '...<' + String.valueOf(body.length() - maxChars) + ' more chars>';
    }
}