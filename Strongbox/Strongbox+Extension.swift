//
//  Strongbox+Extension.swift
//  Strongbox
//
//  Created by Prince Ugwuh on 7/1/19.
//  Copyright © 2019 Carthage. All rights reserved.
//

import Foundation

// Convenience methods

extension Strongbox {
    public static func archive(_ object: Any?, key: String, accessibility: CFString) -> Bool {
        let sb = Strongbox()
        return sb.archive(object, key: key, accessibility: accessibility)
    }
    
    public static func unarchive(objectForKey key: String) -> Any? {
        let sb = Strongbox()
        return sb.unarchive(objectForKey: key)
    }
}

extension Strongbox {
    public static func encode<T: Encodable>(_ encodable: T?, key: String, accessibility: CFString) throws {
        let sb = Strongbox()
        try sb.encode(encodable, key: key, accessibility: accessibility)
    }
    
    public static func decode<T: Decodable>(objectForKey key: String) throws -> T? {
        let sb = Strongbox()
        return try sb.decode(forKey: key)
    }
}
