//
//  NetworkManager.swift
//  SSLpinning_before_iOS14
//
//  Created by Lulwah Almisfer on 19/02/2024.
//
import Foundation
import CommonCrypto
class NetworkManager: NSObject {
    
    static let shared = NetworkManager()
    
    var session: URLSession!
    //  private let localPublicKey = "hBys3wbyNOi6DCnbxljICwobP0q0LS0MbSNuemhq/58="
    private let localPublicKey = "6SF7P6qyTNv5t4NzsU3v/86X+FczDXwaRGPhQnnY98M="
    
    private let rsa2048Asn1Header:[UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ]
    
    private override init() {
        super.init()
        
        session = URLSession.init(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        
    }
    
    private func sha256(data : Data) -> String {
        var keyWithHeader = Data(rsa2048Asn1Header)
        keyWithHeader.append(data)
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        
        keyWithHeader.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(keyWithHeader.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }
    
    func request<T: Decodable>(url: URLRequest?, expecting: T.Type, completion: @escaping (_ data: T?, _ error: Error?)-> ()) {
        
        guard let url else {
            print("cannot form url")
            return
        }
        
        
        
        session.dataTask(with: url) { data, response, error in
            
            if let error {
                if error.localizedDescription == "cancelled" {
                    completion(nil, NSError.init(domain: "", code: -999, userInfo: [NSLocalizedDescriptionKey:"SSL Pinning Failed"]))
                    return
                }
                completion(nil, error)
                return
            }
            
            guard let data else {
                completion(nil, NSError.init(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey:"something went wrong"]))
                print("something went wrong")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let response = try decoder.decode(T.self, from: data)
                completion(response, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
        
    }
    
    
}

extension NetworkManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        
        //Create a server trust
        guard let serverTrust = challenge.protectionSpace.serverTrust, let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            return
        }
        
        //key pinning
        if let serverPublicKey = SecCertificateCopyKey(certificate), let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) {
            
            let data: Data = serverPublicKeyData as Data
            let serverHashKey = sha256(data: data)
            
            if serverHashKey == localPublicKey {
                let credential: URLCredential = URLCredential(trust: serverTrust)
                print("Public Key pinning is successfull")
                completionHandler(.useCredential, credential)
            } else {
                print("Public Key pinning is failed")
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
        
        
        //// certificate pinning
        //        let policy = NSMutableArray()
        //         policy.add(SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString))
        //
        //         //Evaluate the certificate
        //         let isServerTrusted = SecTrustEvaluateWithError(serverTrust, nil)
        //
        //         //Local and Remote Certificate Data
        //         let remoteCertificateData: NSData = SecCertificateCopyData(certificate)
        //
        //         let pathToCertificate = Bundle.main.path(forResource: "typicode", ofType: "cer")
        //         let localCertificateData: NSData = NSData.init(contentsOfFile: pathToCertificate!)!
        //
        //         //Compare Data of both certificates
        //         if (isServerTrusted && remoteCertificateData.isEqual(to: localCertificateData as Data)) {
        //             let credential: URLCredential = URLCredential(trust: serverTrust)
        //             print("Certification pinning is successfull")
        //             completionHandler(.useCredential, credential)
        //         } else {
        //             //failure happened
        //             print("Certification pinning is failed")
        //             completionHandler(.cancelAuthenticationChallenge, nil)
        //         }
    }
}
