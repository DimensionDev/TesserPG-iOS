//
//  KeyFactory.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/21.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import ConsolePrint

enum TCKeyType: CaseIterable {
    case rsa
    
    var extensionName: String {
        switch self {
        case .rsa:
            return "asc"
        }
    }
}

class KeyFactory {

    private static let keyDirectoryName = "keys"

    private init() { }

    // @deprecated, only used in database migration
    static func legacyLoadKeys() -> [String] {
        var keys: [String] = []
        for keyType in TCKeyType.allCases {
            let keyFiles = KeyFactory.loadKeyFiles(keyType: keyType)
            for keyFile in keyFiles {
                if let armored = try? String(contentsOfFile: keyFile, encoding: .utf8) {
                        keys.append(armored)
                }
                
                
//                let keyRing = try? DMSPGPKeyRing(armoredKey: armored) else {
//                    continue
//                }
//
//                keys.append(TCKey(keyRing: keyRing))
            }
        }
        return keys
    }

}

private extension KeyFactory {

    @available(*, deprecated, message: "only used in database migration")
    static var keysDirectoryUrl: URL = {
        let directoryUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.sujitech.tessercube")!
        let keysDirectoryUrl = directoryUrl.appendingPathComponent(KeyFactory.keyDirectoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: keysDirectoryUrl.absoluteString) {
            try? FileManager.default.createDirectory(at: keysDirectoryUrl, withIntermediateDirectories: true, attributes: nil)
        }
        return keysDirectoryUrl
    }()

    @available(*, deprecated, message: "only used in database migration")
    static func loadKeyFiles(keyType: TCKeyType) -> [String] {
        guard let fileNames = try? FileManager.default.contentsOfDirectory(atPath: keysDirectoryUrl.path) else {
            return []
        }
        let keyFileNames = fileNames.filter {
            return ($0 as NSString).pathExtension == keyType.extensionName
        }
        return keyFileNames.map { keysDirectoryUrl.appendingPathComponent($0).path }
    }

//    @available(*, deprecated, message: "only used in database migration")
//    static func saveNewKeyFile(_ key: TCKey) throws {
//        do {
//            let armorString = key.armored
//            guard !armorString.isEmpty else {
//                throw TCError.pgpKeyError(reason: .failToSave)
//            }
//            let fileName = key.longIdentifier
//            try armorString.write(to: keysDirectoryUrl.appendingPathComponent(fileName).appendingPathExtension("asc"), atomically: true, encoding: .utf8)
//        } catch let error {
//            consolePrint(error.localizedDescription)
//            throw TCError.pgpKeyError(reason: .failToSave)
//        }
//    }

    @available(*, deprecated, message: "only used in database migration")
    static func deleteKeyFile(_ key: TCKey) {
        let fileName = key.longIdentifier
        let filePath = keysDirectoryUrl.appendingPathComponent(fileName).appendingPathExtension("asc").path
        if FileManager.default.fileExists(atPath: filePath) {
            try? FileManager.default.removeItem(atPath: filePath)
        }
    }
}
