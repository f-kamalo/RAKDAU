@isTest
global with sharing class HubpayHttpCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // // Optionally, only send a mock response for a specific endpoint
        // // and method.
        // System.assertEquals(HubpayIntegrationHelper.HUBPAY_BASE_URL + HubpayIntegrationHelper.CREATE_ACCOUNT_PATH, req.getEndpoint());
        // System.assertEquals('POST', req.getMethod());
        
        // Create a fake response
        Map<String, Object> payload = new Map<String, Object>{
                    'id' => 'f8d7f528-87b9-426a-918d-e3f0552e88e4' ,
                    'accountType' => 'BUSINESS',
                    'accountName' => 'ACME Co',
                    'email' => 'enquiries@acme.co',
                    'phoneNumber' => '+9771234567890',
                    'countryCode' => 'AE',
                    'externalId' => 'AE00000001',
                    'accountStatus' => 'CREATED'
                };
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(JSON.serialize(payload));
        res.setStatusCode(200);
        return res;
    }
}