//
//  Strongbox.swift
//  Strongbox
//
//  Created by Mark Granoff on 10/8/16.
//  Copyright © 2016 Hawk iMedia. All rights reserved.
//

import Foundation
import Security

public class Strongbox {
    
    let keyPrefix: String
    public var lastStatus = errSecSuccess
    
    public init() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            self.keyPrefix = bundleIdentifier
        } else {
            self.keyPrefix = ""
        }
    }
    
    public init(keyPrefix: String) {
        self.keyPrefix = keyPrefix
    }
    
    /**
     Insert an object into the keychain. Pass `nil` for object to remove it from the keychain.
     
     **Note:** This is a convenience method that calls `archive(_:key:accessibility)` passing
     `kSecAttrAccessibleWhenUnlocked` for the last argument. If you require different keychain
     accessibility, call the other method directly passing the accessibility leve you require.

     - returns:
        Boolean indicating success or failure
     
     - parameters:
        - object: data to store. Pass `nil` to remove previous value for key
        - key: key with which to associated stored value, or key to remove if `object` is nil
     
     */
    public func archive(_ object: Any?, key: String) -> Bool {
        return self.archive(object, key: key, accessibility: kSecAttrAccessibleWhenUnlocked)
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
    public func archive(_ object: Any?, key: String, accessibility: CFString) -> Bool {
        guard
            let _=object as? NSSecureCoding
            else {
            // The optional is empty, so remove the key
            
            let query = self.query()
            query[kSecAttrService] = hierarchicalKey(key)
            lastStatus = SecItemDelete(query)
            
            return lastStatus == errSecSuccess || lastStatus == errSecItemNotFound
        }
        
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(object, forKey: key)
        archiver.finishEncoding()
        
        return self.set(data, key: key, accessibility: accessibility)
    }
    
    /**
     Retrieve an object from the keychain.
     
     - returns:
        Re-constituted object from keychain, or nil if the key was not found. Since the method returns `Any?` it is
        the caller's responsibility to cast the result to the type expected.
     
     - parameters:
        - key: the key to use to locate the stored value
    */
    public func unarchive(objectForKey key: String) -> Any? {
        guard
            let data = self.data(forKey: key)
            else { return nil }

        let unarchiver = NSKeyedUnarchiver(forReadingWith: data as Data)
        if let object = unarchiver.decodeObject(forKey: key) { return object }
        
        return nil
    }

    // MARK: Private functions to do all the work
    
    func set(_ data: NSMutableData?, key: String, accessibility: CFString) -> Bool {
        let hierKey = hierarchicalKey(key)

        let dict = service()
        let entries: [AnyHashable: Any] = [kSecAttrService as AnyHashable: hierKey,
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
    
    func query() -> NSMutableDictionary {
        let query = NSMutableDictionary()
        query[kSecClass] = kSecClassGenericPassword
        query[kSecReturnData] = kCFBooleanTrue
        
        return query
    }
    
    func service() -> NSMutableDictionary {
        let dict = NSMutableDictionary()
        dict.setObject(kSecClassGenericPassword, forKey: kSecClass as! NSCopying)
        return dict
    }
    
    func data(forKey key: String) -> Data? {
        let hierKey = hierarchicalKey(key)
        let query = self.query()
        query.setObject(hierKey, forKey: kSecAttrService as! NSCopying)
        
        var data: AnyObject?
        lastStatus = SecItemCopyMatching(query, &data)
        
        return data as? Data
    }

}
