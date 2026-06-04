@isTest
global class HubpayShareholderCalloutMock implements HttpCalloutMock {
    private Boolean isSuccessMode;

    // constructor to set the mode of the mock (success or error)
    global HubpayShareholderCalloutMock(Boolean isSuccessMode) {
        this.isSuccessMode = isSuccessMode;
    }

    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        String endpoint = request.getEndpoint();

        if(endpoint.containsIgnoreCase('token') || endpoint.containsIgnoreCase('auth')) {
            // Give it a fake access token
            String tokenResponse = '{' +
                '"access_token": "fake_vip_token_12345",' +
                '"token_type": "Bearer",' +
                '"expires_in": 3600' +
            '}';
            response.setBody(tokenResponse);
            response.setStatusCode(200);
        }else{
            if(this.isSuccessMode){
                // Mock response data for corporate endpoint
                if(endpoint.containsIgnoreCase('corporates')){
                    string realhubpayResponseCorporate = '{' +
                        ' "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",' +
                        ' "name": "string",' +
                        ' "relationship": "PARENT",' +
                        ' "percentageOwned": "0",' +
                        ' "documents": [],' +
                        ' "createdAt":  ""2024-07-29T15:51:28.071Z",' +
                        '}';
                    response.setBody(realhubpayResponseCorporate);
                    response.setStatusCode(201);
                } else{
                    // Mock response data for individual endpoint
                    String realHubpayResponseIndividual = '{' +
                        ' "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",' +
                        ' "status": "NOT_SUBMITTED",' +
                        ' "fullNameAsPerId": "string",' +
		        	    ' "documents": [],' +
                        ' "authorizedSignatory": true,' +
                        ' "director": true,' +
                        ' "shareholder": true,' +
                        ' "uaeResident": true,' +
                        ' "linkedInProfileUrl": "string"' +
                        '}';
                response.setBody(realHubpayResponseIndividual);
                response.setStatusCode(201);
                }
            } else{
                response.setBody('{"message": "Invalid data format or server error"}');
                response.setStatusCode(400);
            }
        }

        return response;
    }
}