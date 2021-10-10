//
//  JSONUtil.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/10.
//

import Foundation

func getJSONString<T: Encodable>(from instance: T) throws -> String {

    let jsonData = try JSONEncoder().encode(instance)
    let jsonString = String(data: jsonData, encoding: .utf8)!
    return jsonString
}

struct JSON {
    static let encoder = JSONEncoder()
}

extension Encodable {
    subscript(key: String) -> Any? {
        return dictionary[key]
    }
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSON.encoder.encode(self))) as? [String: Any] ?? [:]
    }
}
