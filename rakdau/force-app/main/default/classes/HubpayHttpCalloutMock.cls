@isTest
global with sharing class HubpayHttpCalloutMock implements HttpCalloutMock {
    public enum MockMode {
        SUCCESS,
        VALIDATION_FAIL,
        EXCEPTION_TEST,
        AUTH_FAIL,
        SERVER_ERROR,
        EMPTY_BODY,
        INVITE_fAILED,
        NOIBAN,
        INVITE_EXISTS,
        NESTED_SUCCESS
    }

    private MockMode mode;

    global HubpayHttpCalloutMock (){
        mode = MockMode.SUCCESS;
    }

    global HubpayHttpCalloutMock (String modeName){
        this.mode = MockMode.valueOf(modeName);
    }

    global HTTPResponse respond(HTTPRequest req) {
        if(req.getEndpoint().containsIgnoreCase('token') || req.getEndpoint().containsIgnoreCase('auth')) {
            // Give it a fake access token
            String tokenResponse = '{' +
                '"access_token": "fake_vip_token_12345",' +
                '"token_type": "Bearer",' +
                '"expires_in": 3600' +
            '}';
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(tokenResponse);
            res.setStatusCode(200);
            return res;
        }else if(req.getEndpoint().containsIgnoreCase('invite')){
            if(mode == MockMode.SUCCESS){
                HttpResponse res = new HttpResponse();

                Map<String,Object> payload =
                    new Map<String,Object>{
                        'inviteUrl' => 'https://hubpay.test/invite'
                    };

                res.setStatusCode(200);
                res.setHeader('Content-Type','application/json');
                res.setBody(JSON.serialize(payload));

                return res;
            }else if(mode == MockMode.VALIDATION_FAIL){
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
                        }
                    };
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody(JSON.serialize(payload));
                res.setStatusCode(400);
                return res;
            }else if(mode == MockMode.EXCEPTION_TEST){
                throw new CalloutException('Simulated callout failure');
            }else if(mode == MockMode.INVITE_EXISTS){
                
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('pending invite already exists');
                res.setStatusCode(409);
                return res;
            }else if(mode == MockMode.INVITE_fAILED){
                Map<String, Object> payload = new Map<String, Object>{
                        'id' => 'f8d7f528-87b9-426a-918d-e3f0552e88e4' ,
                        'accountType' => 'BUSINESS',
                        'accountName' => 'ACME Co',
                        'accountNumber'=>'AE123456789',
                        'currency'=>'AED'
                    };
                HttpResponse res = new HttpResponse();
                res.setStatusCode(200);
                res.setBody(JSON.serialize(payload));
                return res;
            }else if(mode == MockMode.NESTED_SUCCESS){
                Map<String,Object> data = new Map<String,Object>{
                    'inviteUrl' => 'https://app.hubpay.com/invite/nested'
                };

                Map<String,Object> payload = new Map<String,Object>{
                    'data' => data
                };

                HttpResponse res = new HttpResponse();
                res.setStatusCode(200);
                res.setHeader('Content-Type','application/json');
                res.setBody(JSON.serialize(payload));
                return res;
            }
            return null;
        }
        else{
            if(mode == MockMode.SUCCESS){
                Map<String, Object> payload = new Map<String, Object>{
                        'id' => 'f8d7f528-87b9-426a-918d-e3f0552e88e4' ,
                        'accountType' => 'BUSINESS',
                        'accountName' => 'ACME Co',
                        'accountNumber'=>'AE123456789',
                        'currency'=>'AED',
                        'inviteUrl' => 'https://hubpay.test/invite',
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
            }else if(mode == MockMode.VALIDATION_FAIL){
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
                        }
                    };
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody(JSON.serialize(payload));
                res.setStatusCode(400);
                return res;
            }else if(mode == MockMode.EXCEPTION_TEST){
                throw new CalloutException('Simulated callout failure');
            }else if(mode == MockMode.SERVER_ERROR){
                HttpResponse res = new HttpResponse();
                res.setStatusCode(500);
                res.setBody('{"message":"Internal server error"}');
                return res;
            }else if(mode == MockMode.EMPTY_BODY){
                HttpResponse res = new HttpResponse();
                res.setStatusCode(500);
                res.setBody('');
                return res;
            }else if(mode == MockMode.INVITE_fAILED){
                Map<String, Object> payload = new Map<String, Object>{
                        'id' => 'f8d7f528-87b9-426a-918d-e3f0552e88e4' ,
                        'accountType' => 'BUSINESS',
                        'accountName' => 'ACME Co',
                        'accountNumber'=>'AE123456789',
                        'currency'=>'AED'
                    };
                HttpResponse res = new HttpResponse();
                res.setStatusCode(200);
                res.setBody(JSON.serialize(payload));
                return res;
            }else if(mode == MockMode.NOIBAN){
                Map<String, Object> payload = new Map<String, Object>{
                        'id' => 'f8d7f528-87b9-426a-918d-e3f0552e88e4' ,
                        'accountType' => 'BUSINESS',
                        'accountName' => 'ACME Co',
                        'currency'=>'AED',
                        'inviteUrl' => 'https://hubpay.test/invite'
                    };
                HttpResponse res = new HttpResponse();
                res.setStatusCode(200);
                res.setBody(JSON.serialize(payload));
                return res;
            }
        HttpResponse fallback = new HttpResponse();
        fallback.setStatusCode(404);
        fallback.setHeader('Content-Type', 'application/json');
        fallback.setBody('{"error":"Unhandled endpoint: ' + req.getEndpoint() + '"}');
        return fallback;
        }
    
    }
}
