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

final class WordSuggestionService {

    // swiftlint:disable force_try
    let realm: Realm = {
        var config = Realm.Configuration()
        let realmName = "WordPredictor_default"
        config.fileURL = TCDBManager.dbDirectoryUrl.appendingPathComponent("\(realmName).realm")
        config.objectTypes = [NGram1.self, NGram2.self, NGram3.self, NGram4.self]
        try? FileManager.default.createDirectory(at: config.fileURL!.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)

        return try! Realm(configuration: config)
    }()

    lazy private(set) var wordPredictor = WordPredictor(ngramPath: WordPredictor.NgramPath.default!, realm: realm)
    // swiftlint:enable force_try

    // MARK: - Singleton
    public static let shared = WordSuggestionService()

    private init() {

    }

}
