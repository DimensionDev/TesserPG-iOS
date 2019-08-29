//
//  PGPUserIDTranslator.swift
//  TesserCube
//
//  Created by jk234ert on 8/28/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//


import Foundation

public struct DMSPGPUserIDTranslator {
    
    public var userID: String
    public var name: String?
    public var email: String?
    public var comment: String?
    
    public init(userID: String) {
        self.userID = userID
        (self.name, self.email, self.comment) = DMSPGPUserIDTranslator.extractMeta(from: userID)
    }
    
    public init(name: String?, email: String?, comment: String?) {
        userID = DMSPGPUserIDTranslator.buildUserID(name: name, email: email, comment: comment)
        self.name = name
        self.email = email
        self.comment = comment
    }
    
}

public extension DMSPGPUserIDTranslator {
    
    static func buildUserID(name: String?, email: String?, comment: String?) -> String {
        if name == nil, comment == nil {
            return email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        
        var userID = ""
        let name = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        var comment = comment?.trimmingCharacters(in: .whitespacesAndNewlines)
        var email = email?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let name = name, name.hasSuffix(")") {
            comment = comment ?? ""
        }
        
        var bracketedComment: String? {
            return comment.flatMap { "(\($0))" }
        }
        var bracketedEmail: String? {
            return email.flatMap { "<\($0)>"}
        }
        
        return [name, bracketedComment, bracketedEmail].compactMap { $0 }.joined(separator: " ")
    }
    
    static func extractMeta(from userID: String) -> (name: String?, email: String?, comment: String?) {
        var userID = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        var email, comment, name: String?
        
        // parse <email>
        if userID.hasSuffix(">"),
            let leftIndex = userID.range(of: "<", options: .backwards)?.lowerBound {
            email = String(userID[leftIndex...].dropFirst().dropLast())
            
            userID = String(userID[..<leftIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // parse (comment)
        if userID.hasSuffix(")"),
            let leftIndex = userID.range(of: "(", options: .backwards)?.lowerBound {
            comment = String(userID[leftIndex...].dropFirst().dropLast())
            
            userID = String(userID[..<leftIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // check singleton email case
        if email == nil, comment == nil, userID.contains("@") {
            email = userID
        } else {
            name = userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : userID.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return (name: name, email: email, comment: comment)
    }
    
}
