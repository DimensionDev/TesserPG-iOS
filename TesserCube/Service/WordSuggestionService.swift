//
//  WordSuggestionService.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-8-13.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import WordSuggestion
import RealmSwift
import ConsolePrint

final class WordSuggestionService {

    let realm: Realm? = {
        var config = Realm.Configuration()
        let realmName = "WordPredictor_default"
        config.fileURL = TCDBManager.dbDirectoryUrl.appendingPathComponent("\(realmName).realm")
        config.objectTypes = [NGram1.self, NGram2.self, NGram3.self, NGram4.self]
        try? FileManager.default.createDirectory(at: config.fileURL!.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)

        do {
            return try Realm(configuration: config)
        } catch {
            consolePrint(error.localizedDescription)
            return nil
        }
    }()

    private(set) var wordPredictor: WordPredictor?

    // MARK: - Singleton
    public static let shared = WordSuggestionService()

    private init() {
        guard let ngramPath = WordPredictor.NgramPath.default, let realm = realm else {
            return
        }
        wordPredictor = WordPredictor(ngramPath: ngramPath, realm: realm)
    }

}
