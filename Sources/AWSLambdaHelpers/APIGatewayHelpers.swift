//
//  APIGateway+Extras.swift
//  
//
//  Created by Bill Gestrich on 11/13/21.
//

import Foundation
import AWSLambdaEvents
import NIO

extension APIGateway.Request {

    func getBody<T: Decodable>(bodyType: T.Type) -> Result<T, Error> {
        
        guard let body = body else {
            return .failure(APIGatewayHelperError.general("No Body."))
        }
        
        guard let data = body.data(using: .utf8)  else {
            return .failure(APIGatewayHelperError.general("Could not convert body to Data."))
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(bodyType, from: data)
            return .success(response)
        } catch (let exc) {
            return .failure(APIGatewayHelperError.general("Could not convert data to \(bodyType) \(exc)"))
        }
    }
    
    func getBody<T: Decodable>(bodyType: T.Type, eventLoop: EventLoop) -> EventLoopFuture<T> {
        let bodyResult = getBody(bodyType: bodyType)
        switch bodyResult {
        case .success(let success):
            return eventLoop.makeSucceededFuture(success)
        case .failure(let error):
            return eventLoop.makeFailedFuture(error)
        }
    }
    
    func stringDictionary() -> [String: String]? {
        guard let body = self.body else {
            return nil
        }
        
        guard let data = body.data(using: .utf8)  else {
            return nil
        }
        
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
            return nil
        }
        
        return dict
    }
}

public extension APIGateway.Response {
    
    func decode<T: Decodable>(type: T.Type) -> T? {
        guard let data = body?.data(using: .utf8) else {
            print("Could not convert to data")
            return nil
        }
        
        return try? JSONDecoder().decode(type, from: data)
    }
}

public extension Encodable {
    
    func apiGatewayFuture(eventLoop: EventLoop) -> EventLoopFuture<APIGateway.Response> {
        return apiGatewayFuture(eventLoop: eventLoop, status: .ok)
    }
    
    func apiGatewayFuture(eventLoop: EventLoop, status: HTTPResponseStatus) -> EventLoopFuture<APIGateway.Response> {
        let jsonEncoder = JSONEncoder()
        let jsonData = try! jsonEncoder.encode(self)
        let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
        let resp = APIGateway.Response(statusCode: status, headers: ["Content-Type": "application/json"], body: jsonString)
        let future = eventLoop.makeSucceededFuture(resp)
        return future
    }
    
    func toAPIGatewayResponse() -> Result<APIGateway.Response, Error> {
        
        guard let jsonData = try? JSONEncoder().encode(self) else {
            return .failure(APIGatewayHelperError.general("Could not convert object to json data"))
        }
        
        let jsonString = String(data: jsonData, encoding: .utf8)
        let resp = APIGateway.Response(statusCode: .ok, headers: ["Content-Type": "application/json"], body: jsonString)
        return .success(resp)
    }
    
    func toAPIGatewayTestRequest(methodName: String) -> APIGateway.Request? {
        do {
            let json = apiGatewayTestJSON(methodName: methodName, postBody: self)
            let apiGatewayRequestData = try JSONSerialization.data(withJSONObject: json as Any, options: .prettyPrinted)
            return try? JSONDecoder().decode(APIGateway.Request.self, from: apiGatewayRequestData)
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
}

public extension EventLoopFuture where Value: Encodable {
    func apiGatewayFuture() -> EventLoopFuture<APIGateway.Response> {
        return self.flatMap { value in
            return value.apiGatewayFuture(eventLoop: self.eventLoop)
        }
    }
}

public func apiGatewayTestJSON<T>(methodName: String, postBody:T) -> [String: Any]? where T:Encodable{
    
    guard let bodyData = try? JSONEncoder().encode(postBody) else {
        print("Could not convert object to JSON Data")
        return nil
    }
    
    guard let bodyString = String(data: bodyData, encoding: .utf8) else {

        return nil
    }

    return [
        "body": bodyString,
        "resource": "/{proxy+}",
        "path": "/path/to/apps",
        "httpMethod": "POST",
        "isBase64Encoded": false,
        "queryStringParameters": [
          "foo": "bar"
        ],
        "multiValueQueryStringParameters": [
          "foo": [
            "bar"
          ]
        ],
        "pathParameters": [
          "proxy": "/path/to/apps"
        ],
        "stageVariables": [
          "baz": "qux"
        ],
        "headers": [
          "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
          "Accept-Encoding": "gzip, deflate, sdch",
          "Accept-Language": "en-US,en;q=0.8",
          "Cache-Control": "max-age=0",
          "CloudFront-Forwarded-Proto": "https",
          "CloudFront-Is-Desktop-Viewer": "true",
          "CloudFront-Is-Mobile-Viewer": "false",
          "CloudFront-Is-SmartTV-Viewer": "false",
          "CloudFront-Is-Tablet-Viewer": "false",
          "CloudFront-Viewer-Country": "US",
          "Host": "1234567890.execute-api.us-east-1.amazonaws.com",
          "Upgrade-Insecure-Requests": "1",
          "User-Agent": "Custom User Agent String",
          "Via": "1.1 08f323deadbeefa7af34d5feb414ce27.cloudfront.net (CloudFront)",
          "X-Amz-Cf-Id": "cDehVQoZnx43VYQb9j2-nvCh-9z396Uhbp027Y2JvkCPNLmGJHqlaA==",
          "X-Forwarded-For": "127.0.0.1, 127.0.0.2",
          "X-Forwarded-Port": "443",
          "X-Forwarded-Proto": "https"
        ],
        "multiValueHeaders": [
          "Accept": [
            "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
          ],
          "Accept-Encoding": [
            "gzip, deflate, sdch"
          ],
          "Accept-Language": [
            "en-US,en;q=0.8"
          ],
          "Cache-Control": [
            "max-age=0"
          ],
          "CloudFront-Forwarded-Proto": [
            "https"
          ],
          "CloudFront-Is-Desktop-Viewer": [
            "true"
          ],
          "CloudFront-Is-Mobile-Viewer": [
            "false"
          ],
          "CloudFront-Is-SmartTV-Viewer": [
            "false"
          ],
          "CloudFront-Is-Tablet-Viewer": [
            "false"
          ],
          "CloudFront-Viewer-Country": [
            "US"
          ],
          "Host": [
            "0123456789.execute-api.us-east-1.amazonaws.com"
          ],
          "Upgrade-Insecure-Requests": [
            "1"
          ],
          "User-Agent": [
            "Custom User Agent String"
          ],
          "Via": [
            "1.1 08f323deadbeefa7af34d5feb414ce27.cloudfront.net (CloudFront)"
          ],
          "X-Amz-Cf-Id": [
            "cDehVQoZnx43VYQb9j2-nvCh-9z396Uhbp027Y2JvkCPNLmGJHqlaA=="
          ],
          "X-Forwarded-For": [
            "127.0.0.1, 127.0.0.2"
          ],
          "X-Forwarded-Port": [
            "443"
          ],
          "X-Forwarded-Proto": [
            "https"
          ]
        ],
        "requestContext": [
          "accountId": "123456789012",
          "resourceId": "123456",
          "stage": "prod",
          "requestId": "c6af9ac6-7b61-11e6-9a41-93e8deadbeef",
          "requestTime": "09/Apr/2015:12:34:56 +0000",
          "requestTimeEpoch": 1428582896000,
          "identity": [
            "cognitoIdentityPoolId": nil,
            "accountId": nil,
            "cognitoIdentityId": nil,
            "caller": nil,
            "accessKey": nil,
            "sourceIp": "127.0.0.1",
            "cognitoAuthenticationType": nil,
            "cognitoAuthenticationProvider": nil,
            "userArn": nil,
            "userAgent": "Custom User Agent String",
            "user": nil
          ],
          "path": "/prod/path/to/app/\(methodName)",
          "resourcePath": "/{proxy+}",
          "httpMethod": "POST",
          "apiId": "1234567890",
          "protocol": "HTTP/1.1"
        ]
      ]

}


public enum APIGatewayHelperError: Error {
    case general(String)
}


//public extension Dictionary where Key == String, Value: Encodable {
//    func apiGatewayFuture(context: Lambda.Context) -> EventLoopFuture<APIGateway.Response> {
//        let jsonEncoder = JSONEncoder()
//        let jsonData = try! jsonEncoder.encode(self)
//        let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
//        let resp = APIGateway.Response(statusCode: .ok, headers: ["Content-Type": "application/json"], body: jsonString)
//        let future = context.eventLoop.makeSucceededFuture(resp)
//        return future
//    }
//}
//
//public extension Array where Element: Encodable {
//    func apiGatewayFuture(context: Lambda.Context) -> EventLoopFuture<APIGateway.Response> {
//        let jsonEncoder = JSONEncoder()
//        let jsonData = try! jsonEncoder.encode(self)
//        let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
//        let resp = APIGateway.Response(statusCode: .ok, headers: ["Content-Type": "application/json"], body: jsonString)
//        let future = context.eventLoop.makeSucceededFuture(resp)
//        return future
//    }
//}
