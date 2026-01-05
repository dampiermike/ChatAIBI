//
//  TextFunctions.swift
//  ChatAIBI
//
//  Created by Mike Dampier on 1/4/26.
//

import Foundation

func maskedText(for input: String) -> String {
    //let maskChars: [Character] = Array("@#$%&")
    //guard !maskChars.isEmpty else { return String(repeating: "*", count: input.count) }
    //let masked = input.map { _ in maskChars.randomElement()! }
    //return String(masked)
    return String(repeating: "*", count: input.count)
}

