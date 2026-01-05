//
//  Settings.swift
//  ChatAIBI
//
//  Created by Mike Dampier on 1/1/26.
//

import Foundation
import KeychainSwift

let keychain = KeychainSwift()

// To save the user's username and password
func saveCredentials(PAT: String, accountURL: String, database: String, schema: String, agent: String) {
    keychain.set(PAT, forKey: "PAT")
    keychain.set(accountURL, forKey: "accountURL")
    keychain.set(database, forKey: "database")
    keychain.set(schema, forKey: "schema")
    keychain.set(agent, forKey: "agent")
}

// To retrieve the user's username and password
func getCredentials() -> (PAT: String?, accountURL: String?, database: String?, schema: String?, agent: String?) {
    let PAT = keychain.get("PAT")
    let URL = keychain.get("accountURL")
    let database = keychain.get("database")
    let schema = keychain.get("schema")
    let agent = keychain.get("agent")
    return (PAT, URL, database, schema, agent)
}

// To delete credentials upon logout
func deleteCredentials() {
    keychain.delete("PAT")
    keychain.delete("accountURL")
    keychain.delete("database")
    keychain.delete("schema")
    keychain.delete("agent")
}
