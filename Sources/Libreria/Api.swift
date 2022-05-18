//
//  Api.swift
//
//  Created by Sferea-Lider on 21/01/22.
//

import Foundation
import MobileCoreServices


public class Api{
    private static let boundary = UUID().uuidString
    
    private static let session:URLSession = URLSession.shared
    
    public static var timeout: TimeInterval = 30
    
    
    static var isRefresing = false
    
    
    public static func request(url:URLRequest,completion: @escaping (Data?,CodeResponse) -> ()){
        //Check conection
        if !NetworkMonitor.isConnectedToNetwork(){
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                completion(nil,.not_conection)
            }
            
            return
        }
       
        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let httpURLResponse = response as? HTTPURLResponse,
                      let code = CodeResponse(rawValue: httpURLResponse.statusCode) else{
                    completion(nil,.timeout)
                    print("API: \(error?.localizedDescription ?? "")")
                    return
                }
                completion(data, code)
                
            }
        }.resume()
    }
    
    


    
    public static func makeURLRequest(url: URL,method: Method = .GET,parameters: [String:Any]? = nil,headers: [String:String]? = nil,contentType:ContentType = .json) -> URLRequest{

        var urlRequest:URLRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        var content = contentType.rawValue
        if contentType == .multipart{
            content = "\(content); boundary=\(boundary)"
        }
        
        if let headers = headers {
            urlRequest.allHTTPHeaderFields = headers
        }
    
        urlRequest.setValue(content, forHTTPHeaderField: "Content-Type")
    
        urlRequest.timeoutInterval = timeout
        if let params = parameters{
            if method == .GET{
                //TODO: Change this implementacion to betterone
                let jsonString = params.reduce("") { "\($0)\($1.0)=\($1.1)&" }.dropLast()
                let newUrl = URL(string: "\(url.absoluteString)?\(jsonString)")
                urlRequest.url = newUrl
            }
            else{
                urlRequest.httpBody =  parametersToData(parameters: params, contentType: contentType)
            }
            
        }
        return urlRequest
    }
    
    static func parametersToData(parameters: [String:Any],contentType:ContentType = .json) -> Data{
        switch contentType {
        case .json:
            return try! JSONSerialization.data(withJSONObject: parameters, options: [])
        case .form:
            let jsonString = parameters.reduce("") { "\($0)\($1.0)=\($1.1)&" }.dropLast()
            return jsonString.data(using: .utf8, allowLossyConversion: false)!
        case .multipart:
            var data = Data()
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            for param in parameters {
                guard let url = param.value as? URL else{
                    continue
                }
                data.append("Content-Disposition: form-data; name=\"\(param.key)\"; filename=\"\(url.lastPathComponent)\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: \(url.mimeType())\r\n\r\n".data(using: .utf8)!)
                if let fileData = try? Data(contentsOf: url){
                    data.append(fileData)
                }
        
            }
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            return data
        }
    }
    
    
    
 
    
    public enum Method: String{
        case GET
        case POST
        case DELETE
    
    }
    public enum ContentType: String{
        case json = "application/json"
        case form = "application/x-www-form-urlencoded"
        case multipart = "multipart/form-data"
    }
    
  
}


public enum CodeResponse: Int{
    case success = 200
    case sinContenido = 201
    case noContent = 204
    case bad_request = 400
    case idontknow = 401
    case forbiden = 403
    case not_found = 404
    case suspendido = 405
    case eliminado = 406
    case error = 409
    case precodition_failed = 412
    case error_server = 500
    case not_conection = -1001
    case timeout = -1002
    case bad_url = -1003
    case bad_decodable = -1004
    case copy_file_error = -1005
    
    
  
    
}


extension URL {
    func mimeType() -> String {
        let pathExtension = self.pathExtension
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
    var containsImage: Bool {
            let mimeType = self.mimeType()
            guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
                return false
            }
            return UTTypeConformsTo(uti, kUTTypeImage)
    }
}

