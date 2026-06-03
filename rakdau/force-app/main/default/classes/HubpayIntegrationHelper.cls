public with sharing class HubpayIntegrationHelper {
    /**
     * @description Hubpay base URL via Named Credential.
     */
    public static final String HUBPAY_BASE_URL = 'callout:Manual_Creds_HubPay';
    public static final String AUTH_TOKEN_PATH = '/auth/token';
    public static final String CREATE_ACCOUNT_PATH = '/v1/account';
    public static final String UPDATE_PROFILE_PATH = '/v1/account/business-profile';
    /** @description POST invite user ({@code /v1/account/users/invite}). */
    public static final String USERS_INVITE_PATH = '/v1/account/users/invite';
    public static final String UPLOAD_DOCUMENT_PATH = '/v1/account/documents/upload';
    public static final String ADD_UPDATE_DOCUMENT_PATH = '/v1/account/documents';
    public static final String ACCOUNT_SUBMIT_PATH = '/v1/account/submit';
    public static final String RELATED_PARTY_PERSONS_PATH = '/v1/account/related-party/persons';
    public static final String RELATED_PARTY_CORPORATES_PATH = '/v1/account/related-party/corporates';
    public static final String FUNDING_ACCOUNTS_PATH = '/v1/funding-accounts';
    public static final String FUNDING_ACCOUNTS_CURRENCY_AED = 'AED';
    public static final String TOKEN_TYPE_BEARER = 'Bearer';
    public static final Integer CALL_TIMEOUT_MS = 120000;

    public static final String STATUS_PENDING_ACCOUNT_CREATION = 'Pending Account Creation';
    public static final String STATUS_ACCOUNT_SYNCED = 'Account Synced';
    public static final String STATUS_PENDING_PROFILE_UPDATE = 'Pending Profile Update';
    public static final String STATUS_PENDING_PROFILE_ELIGIBILITY_CHECK = 'Pending Profile Eligibility check';
    public static final String STATUS_INTEGRATION_ERROR = 'Integration_Error';
    /** @description Webhook-driven lifecycle labels; add matching picklist values on Account if missing. */
    public static final String STATUS_APPLICATION_SUBMITTED = 'Application Submitted';
    public static final String STATUS_APPLICATION_APPROVED = 'Application Approved';
    public static final String STATUS_ONBOARDED_ACTIVE = 'Onboarded';
    /** @description Account milestone when every Hubpay-linked checklist doc is Approved; Flow/automation may invoke Hubpay submit. */
    public static final String STATUS_SUBMITTED_FOR_MANUAL_REVIEW = 'Submitted For Manual Review';

    public static final String FIELD_EXTERNAL_ACCOUNT_ID = 'Hubpay_External_ID__c';
    public static final String FIELD_STATUS = 'Hubpay_Account_Opening_Status__c';
    public static final String FIELD_ERROR_MESSAGE = 'Hubpay_Integration_Error__c';
    public static final String FIELD_HUBPAY_IBAN = 'Hubpay_IBAN__c';
    public static final String FIELD_HUBPAY_LINK = 'Hubpay_Link__c';
    public static final Integer ERROR_MESSAGE_MAX_LENGTH = 255;

    /** @description Document_Checklist_Item__c Hubpay fields (webhook updates). */
    /** @description Hubpay onboarding {@code data.documentId} UUID stored on the checklist line (same API name as Account hub id field, different object). */
    public static final String DCI_FIELD_HUBPAY_EXTERNAL_ID = 'Hubpay_External_ID__c';
    public static final String DCI_FIELD_HUBPAY_DOCUMENT_STATUS = 'Hubpay_Document_Status__c';
    public static final String DCI_FIELD_DOCUMENT_DECLINE_REASON = 'Hubpay_Document_Decline_Reason__c';
    /** @description User-facing name may read "Validation Warning"; API uses underscore, not a space. */
    public static final String DCI_FIELD_DOCUMENT_VALIDATION_WARNING = 'Hubpay_Document_Validation_Warning__c';

    /** @description Picklist/value for Hubpay_Account_Opening_Status__c after signed_up webhook. */
    public static final String WEBHOOK_ACCOUNT_STATUS_PENDING_PROFILE_UPDATE = 'Pending_Profile_Update';
    public static final String WEBHOOK_ACCOUNT_STATUS_APPROVED = 'Approved';
    public static final String WEBHOOK_ACCOUNT_STATUS_REJECTED = 'Rejected';
    public static final String WEBHOOK_DCI_STATUS_APPROVED = 'Approved';
    public static final String WEBHOOK_DCI_STATUS_DECLINED = 'Declined';
    public static final String WEBHOOK_DCI_STATUS_VALIDATION_WARNINGS = 'VALIDATION_WARNINGS';

    /** @description DCI decline / validation warning fields are Text Area(255) in org. */
    public static final Integer DCI_TEXT_AREA_MAX_LENGTH = 255;

    private static Map<String, Schema.SObjectField> accountFieldMap;
    private static Map<String, Schema.SObjectField> documentChecklistItemFieldMap;
    private static String cachedAccessToken;
    private static String cachedTokenType;
    private static Datetime cachedTokenExpiresAt;

    public static final String HUBPAY_INTEGRATION_SETTING = 'HubPay';
    private static Integration_Settings__mdt cachedHubpaySettings;

    /**
     * @description Returns Account field describe map once per transaction.
     */
    public static Map<String, Schema.SObjectField> getAccountFieldMap() {
        if (accountFieldMap == null) {
            accountFieldMap = Schema.SObjectType.Account.fields.getMap();
        }
        return accountFieldMap;
    }

    /**
     * @description Document_Checklist_Item__c field map (keys lowercase per platform describe).
     */
    public static Map<String, Schema.SObjectField> getDocumentChecklistItemFieldMap() {
        if (documentChecklistItemFieldMap == null) {
            documentChecklistItemFieldMap = Schema.SObjectType.Document_Checklist_Item__c.fields.getMap();
        }
        return documentChecklistItemFieldMap;
    }

    /**
     * @description True if Document_Checklist_Item__c has this field (case-insensitive API name).
     */
    public static Boolean documentChecklistItemHasField(String fieldApiName) {
        if (String.isBlank(fieldApiName)) {
            return false;
        }
        return getDocumentChecklistItemFieldMap().containsKey(fieldApiName.toLowerCase());
    }

    /**
     * @description Assigns field on Document_Checklist_Item__c if the field exists. Does not enforce FLS (trusted webhook path + SYSTEM_MODE DML).
     */
    public static void putDocumentChecklistFieldIfPresent(SObject dciRecord, String fieldApiName, Object value) {
        if (dciRecord == null || String.isBlank(fieldApiName)) {
            return;
        }
        Schema.SObjectField tok = getDocumentChecklistItemFieldMap().get(fieldApiName.toLowerCase());
        if (tok == null) {
            return;
        }
        dciRecord.put(tok.getDescribe().getName(), value);
    }

    /**
     * @description Checks if field exists and is accessible.
     */
    public static Boolean canReadField(String fieldApiName) {
        Schema.SObjectField fieldToken = getAccountFieldMap().get(fieldApiName);
        return fieldToken != null && fieldToken.getDescribe().isAccessible();
    }

    /**
     * @description Checks if field exists and is updateable.
     */
    public static Boolean canUpdateField(String fieldApiName) {
        Schema.SObjectField fieldToken = getAccountFieldMap().get(fieldApiName);
        return fieldToken != null && fieldToken.getDescribe().isUpdateable();
    }

    /**
     * @description Reads string value safely from an SObject.
     */
    public static String getStringValue(SObject sobj, String fieldApiName) {
        if (sobj == null || !canReadField(fieldApiName)) {
            return null;
        }
        Object rawValue = sobj.get(fieldApiName);
        return rawValue == null ? null : String.valueOf(rawValue);
    }

    /**
     * @description Writes field value if field exists and is updateable.
     */
    public static void setFieldValue(SObject sobj, String fieldApiName, Object value) {
        if (sobj == null || String.isBlank(fieldApiName) || !getAccountFieldMap().containsKey(fieldApiName) || !canUpdateField(fieldApiName)) {
            return;
        }
        sobj.put(fieldApiName, value);
    }

    /**
     * @description Assigns a value to an Account field if the field exists on Account. Does not enforce FLS.
     *              Intended only for trusted server paths (e.g. Hubpay webhook after signature verification + Database.update SYSTEM_MODE).
     */
    public static void putAccountFieldIfPresent(SObject accountRecord, String fieldApiName, Object value) {
        if (accountRecord == null || String.isBlank(fieldApiName) || !getAccountFieldMap().containsKey(fieldApiName)) {
            return;
        }
        accountRecord.put(fieldApiName, value);
    }

    /**
     * @description Loads Account by Hubpay external id (SOQL {@code WITH SYSTEM_MODE} — required for Site Guest webhook user).
     */
    public static Account loadAccountByHubpayExternalIdSystemMode(String hubpayExternalId) {
        if (String.isBlank(hubpayExternalId) || !getAccountFieldMap().containsKey(FIELD_EXTERNAL_ACCOUNT_ID)) {
            return null;
        }
        List<String> queryFields = new List<String>{ 'Id', FIELD_EXTERNAL_ACCOUNT_ID };
        if (getAccountFieldMap().containsKey('External_Id__c')) {
            queryFields.add('External_Id__c');
        }
        String query =
            'SELECT ' +
            String.join(queryFields, ',') +
            ' FROM Account WHERE ' +
            FIELD_EXTERNAL_ACCOUNT_ID +
            ' = :hubpayUuid WITH SYSTEM_MODE LIMIT 1';
        String hubpayUuid = hubpayExternalId.trim();
        List<Account> rows = Database.query(query);
        return rows.isEmpty() ? null : rows[0];
    }

    /**
     * @description Loads Accounts by Id (SOQL {@code WITH SYSTEM_MODE} — Site Guest cannot use user-mode or AccessLevel-only system mode).
     */
    public static Map<Id, Account> loadAccountsByIdsSystemMode(Set<Id> accountIds) {
        Map<Id, Account> accountById = new Map<Id, Account>();
        if (accountIds == null || accountIds.isEmpty()) {
            return accountById;
        }
        List<String> queryFields = new List<String>{ 'Id' };
        if (getAccountFieldMap().containsKey(FIELD_EXTERNAL_ACCOUNT_ID)) {
            queryFields.add(FIELD_EXTERNAL_ACCOUNT_ID);
        }
        if (getAccountFieldMap().containsKey('External_Id__c')) {
            queryFields.add('External_Id__c');
        }
        String query =
            'SELECT ' + String.join(queryFields, ',') + ' FROM Account WHERE Id IN :accountIds WITH SYSTEM_MODE';
        List<Account> rows = Database.query(query);
        for (Account acc : rows) {
            if (acc != null && acc.Id != null) {
                accountById.put(acc.Id, acc);
            }
        }
        return accountById;
    }

    /**
     * @description Primary Contact for invite user, resolved from the related Service Request (WorkOrder.ContactId).
     *              Delegated to a without-sharing worker so the webhook Site Guest context can read the records
     *              (WITH SYSTEM_MODE bypasses FLS/CRUD but record-level sharing follows the class sharing keyword).
     *              Most recent Service Request wins.
     */
    public static Map<Id, Contact> loadPrimaryContactsByAccountIdsSystemMode(Set<Id> accountIds) {
        Map<Id, Contact> primaryContactByAccountId = new Map<Id, Contact>();
        if (accountIds == null || accountIds.isEmpty()) {
            return primaryContactByAccountId;
        }
        return new ServiceRequestContactResolver().resolve(accountIds);
    }

    /**
     * @description Without-sharing worker that reads the Service Request (WorkOrder) Contact for the webhook
     *              guest context, where record sharing would otherwise hide the rows.
     */
    private without sharing class ServiceRequestContactResolver {
        public Map<Id, Contact> resolve(Set<Id> accountIds) {
            Map<Id, Contact> primaryContactByAccountId = new Map<Id, Contact>();
            String serviceRequestQuery =
                'SELECT AccountId, ContactId, Contact.Email, Contact.FirstName, Contact.LastName, Contact.Name ' +
                'FROM WorkOrder ' +
                'WHERE AccountId IN :accountIds ' +
                'AND ContactId != null ' +
                'WITH SYSTEM_MODE ' +
                'ORDER BY CreatedDate DESC';
            List<WorkOrder> serviceRequests = Database.query(serviceRequestQuery);
            for (WorkOrder serviceRequest : serviceRequests) {
                if (!primaryContactByAccountId.containsKey(serviceRequest.AccountId) && serviceRequest.Contact != null) {
                    primaryContactByAccountId.put(serviceRequest.AccountId, serviceRequest.Contact);
                }
            }
            return primaryContactByAccountId;
        }
    }

    /**
     * @description Hubpay accountName must match ^[a-zA-Z0-9\s\-\.&]+$ and max 100 characters (AccountCreateRequest schema).
     */
    public static String sanitizeAccountNameForHubpay(String raw) {
        if (String.isBlank(raw)) {
            return 'Account';
        }
        String cleaned = raw.replaceAll('[^a-zA-Z0-9\\s\\-\\.&]', ' ');
        cleaned = cleaned.replaceAll('\\s+', ' ').trim();
        if (String.isBlank(cleaned)) {
            return 'Account';
        }
        return cleaned.length() > 100 ? cleaned.substring(0, 100) : cleaned;
    }

    /**
     * @description Formats phone for Hubpay create account (required, max 30 chars). Expects E.164 when possible; applies common UAE national patterns when country is AE.
     */
    public static String formatPhoneForHubpay(String phone, String countryIso2) {
        if (String.isBlank(phone)) {
            return null;
        }
        String trimmed = phone.trim();
        String digitsOnly = trimmed.replaceAll('[^0-9]', '');
        if (String.isBlank(digitsOnly)) {
            return null;
        }
        String cc = String.isBlank(countryIso2) ? 'AE' : countryIso2.trim().toUpperCase();

        if (trimmed.startsWith('+')) {
            String international = '+' + digitsOnly;
            return international.length() > 30 ? null : international;
        }

        if (digitsOnly.startsWith('971') && digitsOnly.length() >= 11 && digitsOnly.length() <= 15) {
            String international = '+' + digitsOnly;
            return international.length() > 30 ? null : international;
        }

        if ('AE'.equals(cc)) {
            if (digitsOnly.length() == 10 && digitsOnly.startsWith('05')) {
                String international = '+971' + digitsOnly.substring(2);
                return international.length() > 30 ? null : international;
            }
            if (digitsOnly.length() == 9 && digitsOnly.startsWith('5')) {
                String international = '+971' + digitsOnly;
                return international.length() > 30 ? null : international;
            }
        }

        return null;
    }

    public static String buildErrorMessage(String context, HttpResponse response, Exception ex) {
        String message;
        if (ex != null) {
            message = context + ': ' + ex.getMessage();
        } else if (response != null) {
            String body = response.getBody();
            if (String.isBlank(body)) {
                body = 'No response body';
            }
            message = context + ' (HTTP ' + response.getStatusCode() + '): ' + body;
        } else {
            message = context + ': Unknown error';
        }
        if (message != null && message.length() > ERROR_MESSAGE_MAX_LENGTH) {
            return message.substring(0, ERROR_MESSAGE_MAX_LENGTH);
        }
        return message;
    }

    /**
     * @description Returns Hubpay bearer token and caches it for the current transaction.
     */
    public static String getAccessToken(Http http) {
        if (
            String.isNotBlank(cachedAccessToken) &&
            cachedTokenExpiresAt != null &&
            cachedTokenExpiresAt > Datetime.now().addSeconds(30)
        ) {
            System.debug(LoggingLevel.INFO,
                'Hubpay auth: using cached token. tokenType=' + cachedTokenType +
                ', expiresAt=' + String.valueOf(cachedTokenExpiresAt)
            );
            return cachedAccessToken;
        }

        HttpRequest authRequest = new HttpRequest();
        authRequest.setEndpoint(HUBPAY_BASE_URL + AUTH_TOKEN_PATH);
        authRequest.setMethod('POST');
        authRequest.setHeader('Accept', 'application/json');
        authRequest.setHeader('Content-Type', 'application/json');
        authRequest.setTimeout(CALL_TIMEOUT_MS);
        authRequest.setBody(JSON.serialize(new Map<String, Object>{
            'clientId' => getHubpayClientId(),
            'clientSecret' => getHubpayClientSecret()
        }));

        HttpResponse authResponse = http.send(authRequest);
        Integer code = authResponse.getStatusCode();
        System.debug(LoggingLevel.INFO,
            'Hubpay auth response: statusCode=' + code +
            ', body=' + authResponse.getBody()
        );
        if (code < 200 || code >= 300) {
            throw new HubpayAuthException(buildErrorMessage('Hubpay token request failed', authResponse, null));
        }

        Map<String, Object> authResponseBody =
            (Map<String, Object>) JSON.deserializeUntyped(authResponse.getBody());
        String token = authResponseBody == null ? null : (String) authResponseBody.get('access_token');
        if (String.isBlank(token)) {
            throw new HubpayAuthException('Hubpay token response did not include access_token.');
        }
        token = token.trim();

        String tokenType = authResponseBody == null ? null : (String) authResponseBody.get('token_type');
        if (String.isBlank(tokenType)) {
            tokenType = TOKEN_TYPE_BEARER;
        } else {
            tokenType = tokenType.trim();
        }

        Integer expiresIn = 3600;
        Object expiresRaw = authResponseBody.get('expires_in');
        if (expiresRaw instanceof Integer) {
            expiresIn = (Integer) expiresRaw;
        } else if (expiresRaw instanceof Long) {
            expiresIn = Integer.valueOf(String.valueOf(expiresRaw));
        } else if (expiresRaw != null) {
            expiresIn = Integer.valueOf(String.valueOf(expiresRaw));
        }

        cachedAccessToken = token;
        cachedTokenType = tokenType;
        cachedTokenExpiresAt = Datetime.now().addSeconds(Math.max(30, expiresIn - 30));
        String tokenPreview = token.length() > 16 ? token.substring(0, 8) + '...' + token.substring(token.length() - 8) : token;
        System.debug(LoggingLevel.INFO,
            'Hubpay token created: tokenType=' + cachedTokenType +
            ', tokenLength=' + String.valueOf(token.length()) +
            ', tokenPreview=' + tokenPreview +
            ', expiresIn=' + String.valueOf(expiresIn) +
            ', expiresAt=' + String.valueOf(cachedTokenExpiresAt)
        );
        return cachedAccessToken;
    }

    /**
     * @description Returns HubPay integration settings from custom metadata.
     */
    private static Integration_Settings__mdt getHubpayIntegrationSettings() {
        if (cachedHubpaySettings == null) {
            cachedHubpaySettings = [
                SELECT Client_Id__c, Client_Secret__c
                FROM Integration_Settings__mdt
                WHERE DeveloperName = :HUBPAY_INTEGRATION_SETTING
                LIMIT 1
            ];
        }
        return cachedHubpaySettings;
    }

    /**
     * @description Returns HubPay client id from integration settings.
     */
    private static String getHubpayClientId() {
        Integration_Settings__mdt settings = getHubpayIntegrationSettings();
        if (settings == null || String.isBlank(settings.Client_Id__c)) {
            throw new HubpayAuthException('Missing HubPay Client ID in Integration_Settings__mdt.HubPay.');
        }
        return settings.Client_Id__c.trim();
    }

    /**
     * @description Returns HubPay client secret from integration settings.
     */
    private static String getHubpayClientSecret() {
        Integration_Settings__mdt settings = getHubpayIntegrationSettings();
        if (settings == null || String.isBlank(settings.Client_Secret__c)) {
            throw new HubpayAuthException('Missing HubPay Client Secret in Integration_Settings__mdt.HubPay.');
        }
        return settings.Client_Secret__c.trim();
    }

    /**
     * @description Sets Authorization header using current Hubpay bearer token.
     */
    public static void setAuthorizationHeader(HttpRequest request, Http http) {
        String token = getAccessToken(http);
        String tokenType = String.isBlank(cachedTokenType) ? TOKEN_TYPE_BEARER : cachedTokenType;
        request.setHeader('Authorization', tokenType + ' ' + token);
        System.debug(LoggingLevel.INFO,
            'Hubpay Authorization header set: tokenType=' + tokenType +
            ', tokenLength=' + String.valueOf(token.length())
        );
    }

    /**
     * @description Full callout URL for GET funding accounts (currency fixed to AED).
     */
    public static String buildFundingAccountsGetEndpoint() {
        return HUBPAY_BASE_URL +
            FUNDING_ACCOUNTS_PATH +
            '?currency=' +
            EncodingUtil.urlEncode(FUNDING_ACCOUNTS_CURRENCY_AED, 'UTF-8');
    }

    public class HubpayAuthException extends Exception {}
}