//
//  Strongbox.swift
//  Strongbox
//
//  Created by Mark Granoff on 10/8/16.
//  Copyright © 2016 Hawk iMedia. All rights reserved.
//

import Foundation
import Security

public final class Strongbox {
    
    let keyPrefix: String
    private let lock = NSLock()
    private(set) public var lastStatus = errSecSuccess
    
    public init(keyPrefix: String?) {
        self.keyPrefix = keyPrefix ?? Bundle.main.bundleIdentifier ?? ""
    }

    public convenience init() {
        self.init(keyPrefix: nil)
    }
    
    /**
     Insert an object into the keychain. Pass `nil` for object to remove it from the keychain.
     
     - returns:
        Boolean indicating success or failure
     
     - parameters:
        - object: data to store. Pass `nil` to remove previous value for key
        - key: key with which to associate the stored value, or key to remove if `object` is nil
        - accessibility: keychain accessibility of item once stored
     
     */
    @discardableResult
    public func archive(_ object: Any?, key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlocked) -> Bool
    {
        guard let _=object as? NSSecureCoding else {
            // The optional is empty, so remove the key
            return remove(key: key, accessibility: accessibility)
        }

        // The lock prevents the code to be run simultaneously
        // from multiple threads which may result in crashing
        lock.lock()
        defer { lock.unlock() }
        
        let data = NSMutableData()
        let archiver: NSKeyedArchiver
        if #available(iOS 11.0, watchOSApplicationExtension 4.0, watchOS 11.0, tvOSApplicationExtension 11.0, tvOS 11.0, *) {
            archiver = NSKeyedArchiver(requiringSecureCoding: true)
        } else {
            archiver = NSKeyedArchiver(forWritingWith: data)
        }
        archiver.encode(object, forKey: key)
        archiver.finishEncoding()
        
        var result = false
        if #available(iOS 10.0, watchOSApplicationExtension 3.0, watchOS 3.0, tvOSApplicationExtension 10.0, tvOS 10.0, *) {
            result = self.set(archiver.encodedData as NSData, key: key, accessibility: accessibility)
        } else {
            result = self.set(data, key: key, accessibility: accessibility)
        }
        
        return result
    }

    @discardableResult
    public func archive<T: Encodable>(object: T?, key: String, encoder: JSONEncoder = .init(), accessibility: CFString = kSecAttrAccessibleWhenUnlocked) throws -> Bool {
        guard let object = object else { return archive(nil, key: key, accessibility: accessibility) }
        let data = try encoder.encode(object)
        return archive(data, key: key, accessibility: accessibility)
    }

    /**
     Convenience method for removing a previously stored key.
     
     - returns:
        Boolean indicating success or failure
     
     - parameters:
        - key: key for which to remove the stored value
        - accessibility: keychain accessibility of item

     */
    @discardableResult
    public func remove(key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlocked) -> Bool {
        
         // The lock prevents the code to be run simultaneously
         // from multiple threads which may result in crashing
        lock.lock()
        defer { lock.unlock() }
        
        let query = self.query()
        query[kSecAttrService] = hierarchicalKey(key)
        lastStatus = SecItemDelete(query)
        
        return lastStatus == errSecSuccess || lastStatus == errSecItemNotFound
    }
    
    /**
     Retrieve an object from the keychain.
     
     - returns:
        Re-constituted object from keychain, or nil if the key was not found. Since the method returns `Any?` it is
        the caller's responsibility to cast the result to the type expected.
     
     - parameters:
        - key: the key to use to locate the stored value
    */
    public func unarchive(objectForKey key:String) -> Any? {
        
         // The lock prevents the code to be run simultaneously
         // from multiple threads which may result in crashing
        lock.lock()
        defer { lock.unlock() }
        
        guard let data = self.data(forKey: key) else {
            return nil
        }

        let unarchiver = NSKeyedUnarchiver(forReadingWith: data as Data)
        return unarchiver.decodeObject(forKey: key)
    }

    public func unarchive<T: Decodable>(_ type: T.Type = T.self, for key: String, decoder: JSONDecoder = .init()) throws -> T? {
        guard let data = unarchive(objectForKey: key) as? Data else { return nil }
        return try decoder.decode(T.self, from: data)
    }
}

internal extension Strongbox {
    // MARK: Private functions to do all the work
    
    private func set(_ data: NSData?, key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlocked) -> Bool {
                
        let hierKey = hierarchicalKey(key)

        let dict = service()
        let entries: [AnyHashable:Any] = [kSecAttrService as AnyHashable: hierKey,
                                          kSecAttrAccessible as AnyHashable: accessibility,
                                          kSecValueData as AnyHashable: data!]
        dict.addEntries(from: entries)
        
        lastStatus = SecItemAdd(dict as CFDictionary, nil)
        if lastStatus == errSecDuplicateItem {
            let query = self.query()
            query.setObject(hierKey, forKey: kSecAttrService as! NSCopying)
            lastStatus = SecItemDelete(query as CFDictionary)
            if lastStatus == errSecSuccess {
                lastStatus = SecItemAdd(dict as CFDictionary, nil)
            }
        }
        
        return lastStatus == errSecSuccess
    }
    
    func hierarchicalKey(_ key: String) -> String {
        return keyPrefix + "." + key
    }
    
    private func query() -> NSMutableDictionary {
        let query = NSMutableDictionary()
        query[kSecClass] = kSecClassGenericPassword
        query[kSecReturnData] = kCFBooleanTrue
        
        return query
    }
    
    private func service() -> NSMutableDictionary {
        let dict = NSMutableDictionary()
        dict.setObject(kSecClassGenericPassword, forKey: kSecClass as! NSCopying)
        return dict
    }
    
    private func data(forKey key:String) -> Data? {
        let hierKey = hierarchicalKey(key)
        let query = self.query()
        query.setObject(hierKey, forKey: kSecAttrService as! NSCopying)
        
        var data: AnyObject?
        lastStatus = SecItemCopyMatching(query, &data)
        
        return data as? Data
    }
}
