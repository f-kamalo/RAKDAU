@isTest
global with sharing class HubpayHttpCalloutMock implements HttpCalloutMock {
    private Boolean successTest;

    global HubpayHttpCalloutMock (){
        successTest = true;
    }

    global HubpayHttpCalloutMock (Boolean val){
        successTest = val;
    }

    global HTTPResponse respond(HTTPRequest req) {

        if(req.getEndpoint().containsIgnoreCase('token') || req.getEndpoint().containsIgnoreCase('auth')) {
            // Give it a fake access token
            String tokenResponse = '{' +
                '"access_token": "fake_vip_token_12345",' +
                '"token_type": "Bearer",' +
                '"expires_in": 3600' +
            '}';
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(tokenResponse);
            response.setStatusCode(200);
            return response;
        }else if(req.getEndpoint().containsIgnoreCase('/v1/account') && successTest == true){
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
        }else if(req.getEndpoint().containsIgnoreCase('/v1/account') && successTest == false){
            // Create a fake response
            Map<String, Object> payload = new Map<String, Object>{
                        'code' => 'validation_failed' ,
                        'message' => 'One or more fields are missing or invalid',
                        'status' => 400,
                        'timestamp' => '2025-06-10T10:15:31Z',
                        'path' => '/v1/collections/rates',
                        'errors' => new List<Object>{
                            new Map<String, Object>{
                                'field' => 'sourceCurrency',
                                'message' => 'Source currency is required'
                            }
                        },
                        'externalId' => 'AE00000001',
                        'accountStatus' => 'CREATED'
                    };
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(payload));
            res.setStatusCode(400);
            return res;
        }

    HttpResponse fallback = new HttpResponse();
    fallback.setStatusCode(404);
    fallback.setHeader('Content-Type', 'application/json');
    fallback.setBody('{"error":"Unhandled endpoint: ' + req.getEndpoint() + '"}');
    return fallback;
    }
}