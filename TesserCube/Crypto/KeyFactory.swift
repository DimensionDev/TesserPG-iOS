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
    
    private enum SecretKeyHeader: String {
        case v1 = "-----BEGIN PGP PRIVATE KEY BLOCK-----"
        case v2 = "-----BEGIN PGP SECRET KEY BLOCK-----"
    }
    
    private enum SecretKeyFooter: String {
        case v1 = "-----END PGP PRIVATE KEY BLOCK-----"
        case v2 = "-----END PGP SECRET KEY BLOCK-----"
    }

    private static let keyDirectoryName = "keys"

    private init() { }

    // @deprecated, only used in database migration
    static func legacyLoadKeys() -> [String] {
        return KeyFactory.loadKeyFiles(keyType: TCKeyType.rsa)
            .compactMap { try? String(contentsOfFile: $0, encoding: .utf8) }
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

extension KeyFactory {
    public static func extractPublicKeyBlock(from armored: String) -> String? {
        guard let header = armored.range(of: "-----BEGIN PGP PUBLIC KEY BLOCK-----"),
            let footer = armored.range(of: "-----END PGP PUBLIC KEY BLOCK-----") else {
                return nil
        }
        
        return String(armored[header.lowerBound..<footer.upperBound])
    }
    
    public static func extractSecretKeyBlock(from armored: String) -> String? {
        guard let header = armored.range(of: SecretKeyHeader.v1.rawValue) ?? armored.range(of: SecretKeyHeader.v2.rawValue),
            let footer = armored.range(of: SecretKeyFooter.v1.rawValue) ?? armored.range(of: SecretKeyFooter.v2.rawValue) else {
                return nil
        }
        
        return String(armored[header.lowerBound..<footer.upperBound])
    }

}

