//
//  Strongbox.swift
//  Strongbox
//
//  Created by Mark Granoff on 10/8/16.
//  Copyright © 2016 Hawk iMedia. All rights reserved.
//

import Foundation
import Security

class Strongbox: NSObject {
    
    let keyPrefix: String
    var lastStatus = errSecSuccess
    
    override init() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            self.keyPrefix = bundleIdentifier
        } else {
            self.keyPrefix = ""
        }
        super.init()
    }
    
    init(keyPrefix: String) {
        self.keyPrefix = keyPrefix
        super.init()
    }
    
    func archive(_ object: Any?, key: String) -> Bool {
        return self.archive(object, key: key, accessibility: kSecAttrAccessibleWhenUnlocked)
    }
    
    func archive(_ object: Any?, key: String, accessibility: CFString) -> Bool {
        guard let _=object as? NSSecureCoding else {
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
    
    func unarchive(objectForKey key:String) -> Any? {
        guard let data = self.data(forKey: key) else {
            return nil
        }

        let unarchiver = NSKeyedUnarchiver(forReadingWith: data as Data)
        if let object = unarchiver.decodeObject(forKey: key) { return object }
        
        return nil
    }

    // MARK: Private functions to do all the work
    
    internal func set(_ data: NSMutableData?, key: String, accessibility: CFString) -> Bool {
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
    
    internal func hierarchicalKey(_ key: String) -> String {
        return keyPrefix + "." + key
    }
    
    internal func query() -> NSMutableDictionary {
        let query = NSMutableDictionary()
        query[kSecClass] = kSecClassGenericPassword
        query[kSecReturnData] = kCFBooleanTrue
        
        return query
    }
    
    internal func service() -> NSMutableDictionary {
        let dict = NSMutableDictionary()
        dict.setObject(kSecClassGenericPassword, forKey: kSecClass as! NSCopying)
        return dict
    }
    
    internal func data(forKey key:String) -> Data? {
        let hierKey = hierarchicalKey(key)
        let query = self.query()
        query.setObject(hierKey, forKey: kSecAttrService as! NSCopying)
        
        var data: AnyObject?
        lastStatus = SecItemCopyMatching(query, &data)
        
        return data as! Data?
    }

}
