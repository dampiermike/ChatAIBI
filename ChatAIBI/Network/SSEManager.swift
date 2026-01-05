//
//  SSEManager.swift
//  ChatAIBI
//
//  Created by Mike Dampier on 12/30/25.
//

import Foundation
import EventSource
import Combine
import Charts
import SwiftUI

class SSEManager: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    @Published var receivedMessages: [String] = []
    @Published var conversationHistory: [String] = []
    @Published var userQuestionHistory: [String] = ["Explain this dataset?"]
    @Published var chartData: [ChartDatum] = []
    @Published var chartTitle: String = ""
    @Published var chartXaxisLabel: String = ""
    @Published var chartYaxisLabel: String = ""
    @Published var chartMark: String = ""
    @Published var chartSize: Int = 30
    @Published var thinkingMessages: String = ""
    @Published var statusMessage: String = ""
    // Holds the currently streaming response so we can show it as a single list item
    private var currentStreamBuffer: String = ""
    private var eventStatusString: String = ""
    
    private var task: Task<Void, Never>? // async task for streaming
    
    func cancel() {
        task?.cancel()
        task = nil
        DispatchQueue.main.async { [weak self] in
            //self?.statusMessage = "Cancelled"
            self?.objectWillChange.send()
        }
    }

    func testConnect(PAT: String, accountURL: String, database: String, schema: String, agent: String) async -> String {
        let baseURL = "https://\(accountURL)/api/v2/databases/\(database)/schemas/\(schema)/agents/\(agent)"
        var returnStatus = "No agent found"
        var httpStatus = ""
       
        //print(baseURL)
        //print(PAT)
        
        guard let url = URL(string: baseURL) else { return returnStatus }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("PROGRAMMATIC_ACCESS_TOKEN", forHTTPHeaderField: "X-Snowflake-Authorization-Token-Type")
        request.setValue("Bearer \(PAT)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct AgentResponse: Codable {
            let agent_spec: String
            let name: String
            let database_name: String
            let schema_name: String
            let owner: String
            let created_on: String
        }
        
        //Task {
            do {
                let (_,response) = try await URLSession.shared.data(for: request)
                
                if let http = response as? HTTPURLResponse {
                    httpStatus = String(http.statusCode)
                    //print("HTTP status: \(httpStatus)")
                    if http.statusCode == 200 {
                        returnStatus = "Connection Successful"
                    } else {
                        returnStatus = "Connection Unsuccessful: \(httpStatus)"
                    }
                } else {
                    returnStatus = "Connection Unsuccessful: \(httpStatus)"
                }
            } catch {
                returnStatus = "Connection Unsuccessful"
            }
        
        return returnStatus
        
    }
    
    //adding a comment so I can commit - this is a test
    
    // SSEManager.swift (place near connectToSSE or as a private helper)
    private func messageFromRoot(_ root: Root) -> [String: Any] {
        var contents: [[String: Any]] = []

        // Include thinking text if you want the model to see prior chain-of-thought.
        // Many systems discourage sending raw thinking back; you can remove this block if needed.
        for item in root.content {
            switch item {
            case .thinking(let think):
                /*
                contents.append([
                    "type": "text",
                    "text": think.thinking.text
                */
                let thought = think
            case .toolResult(let tr):
                // If you want to include tool results context, add either the text or a JSON summary.
                if let json = tr.tool_result.content?.first?.json {
                    if let text = json.text, !text.isEmpty {
                        contents.append([
                            "type": "text",
                            "text": text
                        ])
                    } else if let sql = json.sql {
                        contents.append([
                            "type": "text",
                            "text": "Tool result SQL: \(sql)"
                        ])
                    } else if let rs = json.result_set?.data {
                        // Summarize data if needed
                        contents.append([
                            "type": "text",
                            "text": "Tool result contained \(rs.count) rows."
                        ])
                    }
                }
            case .text(let t):
                contents.append([
                    "type": "text",
                    "text": t.text
                ])
            case .toolUse, .unknown:
                break
            }
        }

        // Fallback if no content extracted
        if contents.isEmpty {
            contents = [["type": "text", "text": ""]]
        }

        return [
            "role": "assistant",
            "content": contents
        ]
    }
    
    func connectToSSE(userQuestion: String) {
        self.cancel()
        //disconnect()
        let apiKey = getCredentials().PAT ?? ""
        let accountURL = getCredentials().accountURL ?? ""
        let database = getCredentials().database ?? ""
        let schema = getCredentials().schema ?? ""
        let agent = getCredentials().agent ?? ""
        
        let baseURL = "https://\(accountURL)/api/v2/databases/\(database)/schemas/\(schema)/agents/\(agent):run"
       
        //print(baseURL)
        //print(apiKey)
        
        guard let url = URL(string: baseURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("PROGRAMMATIC_ACCESS_TOKEN", forHTTPHeaderField: "X-Snowflake-Authorization-Token-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct EncodableContent: Codable {
            let type: String
            let text: String
        }
        struct EncodableMessage: Codable {
            let role: String
            let content: [EncodableContent]
        }
        struct EncodableRequest: Codable {
            let messages: [EncodableMessage]
        }
        
        let encodable = EncodableRequest(
            messages: [
                EncodableMessage(
                    role: "user",
                    content: [EncodableContent(type: "text", text: userQuestion)]
                )
            ]
        )
        
        var messagesArray: [[String: Any]] = []

        for raw in self.conversationHistory {
            do {
                let root = try decodeRoot(from: raw)
                let msg = messageFromRoot(root)
                messagesArray.append(msg)
            } catch {
                // If a prior turn fails to decode, skip it rather than fail the whole request
                print("Failed to decode prior turn: \(error)")
            }
        }

        // 2) Append the new user message at the end
        messagesArray.append([
            "role": "user",
            "content": [
                [
                    "type": "text",
                    "text": userQuestion
                ]
            ]
        ])

        // 3) Encode the full request body as JSON
        let bodyDict: [String: Any] = ["messages": messagesArray]
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: bodyDict, options: [])
        } catch {
            print("Failed to encode request body: \(error)")
            return
        }

        request.httpBody = jsonData

        /* Optional: For debugging
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Request JSON: \(jsonString)")
        }*/
        
        // Kick off the stream in a single Task
        task = Task { [weak self] in
   
            guard let self else { return }
            do {
                // Start SSE stream
                let eventSource = EventSource()
                let dataTask = eventSource.dataTask(for: request)
                let decoder = JSONDecoder()
                
                struct ResponseStatus: Codable {
                    var message: String
                    var status: String
                }
                
                struct Thinking: Codable {
                    var content_index: Int
                    var text: String
                }
                
                for await event in dataTask.events() {
                    if Task.isCancelled { break }
                    switch event {
                    case .open:
                        eventStatusString = "open"
                    case .error(let error):
                        print("error: \(String(describing: error))")
                    case .closed:
                        eventStatusString = "closed"
                    case .event(let inner):
                        guard let eventName = inner.event, let dataString = inner.data else {
                            print("Missing event name or data")
                            continue
                        }
                        if eventName.contains("response.status") {
                            do {
                                if let data = dataString.data(using: .utf8) {
                                    let jsonLine = try decoder.decode(ResponseStatus.self, from: data)
                                    self.statusMessage = jsonLine.message
                                    self.objectWillChange.send()
                                    //print(jsonLine.status)
                                }
                            } catch {
                                print("decode error: \(error)")
                            }
                        }
                        if eventName.contains("response.thinking.delta") {
                            do {
                                if let data = dataString.data(using: .utf8) {
                                    let jsonLine = try decoder.decode(Thinking.self, from: data)
                                    //print(jsonLine.text)
                                    await MainActor.run {
                                        self.thinkingMessages += jsonLine.text
                                        self.objectWillChange.send()
                                    }
                                }
                            } catch {
                                print("decode error: \(error)")
                            }
                        }
                        if eventName == "response" {
                            let eventData = dataString
                            await MainActor.run {
                                self.conversationHistory.append(eventData)
                                //print(self.conversationHistory)
                                let finalText = parseFinalResults(json: eventData)
                                
                                if self.receivedMessages.isEmpty {
                                    // No first entry; put final in the first
                                    self.receivedMessages.append(finalText)
                                } else {
                                    // Replace the second entry with the final text
                                    self.receivedMessages[0] = finalText
                                }
                                //self.receivedMessages += finalText
                                self.objectWillChange.send()
                            }
                        }
                        if eventName == "response.chart" {
                            let eventData = dataString
                            print(eventData)
                            await MainActor.run {
                                do {
                                    let spec = try parseChartSpec(from: eventData) // or from: jsonString
                                    self.chartData = spec.data
                                    for datum in spec.data {
                                        print("Category: \(datum.category), Value: \(datum.value), Color: \(datum.colorCategory), Size: \(datum.size), datum.xValue: \(datum.xValue), data.yValue: \(datum.yValue)")
                                    }
                                    print(spec.title, spec.xTitle, spec.yTitle)
                                    print(spec.mark)
                                    self.chartTitle = spec.title ?? "Untitiled Chart"
                                    self.chartXaxisLabel = spec.xTitle ?? "X-axis"
                                    self.chartYaxisLabel = spec.yTitle ?? "Y-axis"
                                    self.chartMark = spec.mark ?? "bar"

                                } catch {
                                    // handle parse errors
                                }
                                self.objectWillChange.send()
                            }
                        }
                    }
                }
            }
            self.task = nil
        }
    }
}

