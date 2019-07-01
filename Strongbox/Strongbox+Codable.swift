//
//  Strongbox+Codable.swift
//  Strongbox
//
//  Created by Prince Ugwuh on 7/1/19.
//

import Foundation

extension Strongbox {
    func encode<T: Encodable>(_ encodable: T?, key: String, encoder: JSONEncoder = .init(), accessibility: CFString) throws {
        let sb = Strongbox()
        guard
            let encodable = encodable
            else { sb.archive(nil, key: key, accessibility: accessibility) ; return }
        let data = try encoder.encode(encodable)
        sb.archive(data, key: key, accessibility: accessibility)
    }
    
    func decode<T: Decodable>(forKey key: String, decoder: JSONDecoder = .init()) throws -> T? {
        let sb = Strongbox()
        guard
            let data = sb.unarchive(objectForKey: key) as? Data
            else { return nil }
        return try decoder.decode(T.self, from: data)
    }
}
