//
//  ContentView.swift
//  ChatAIBI
//
//  Created by Mike Dampier on 12/28/25.
//

import SwiftUI
import Charts


struct SettingsView: View {
    // Focusable fields for SettingsView
    private enum Field: Hashable {
        case PAT
        case accountURL
        case database
        case schema
        case agent
    }
    @StateObject private var sseManager = SSEManager()
    @State private var showStatusAlert = false
    @State private var statusMessage: String = ""
    @State private var PAT: String = ""
    @State private var accountURL: String = ""
    @State private var database: String = ""
    @State private var schema: String = ""
    @State private var agent: String = ""
    @State private var sensitiveText: String = "This is some sensitive information."
    @State private var isSensitiveModeOn: Bool = true
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss
    
    func submitText() {
            //print("Text entered: \(textInput)")
            focusedField = nil // Collapse the keyboard
        }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                
                HStack(spacing: 8) {
                    Text("Enter your PAT")
                        .foregroundStyle(.white)
                    Toggle(isOn: $isSensitiveModeOn) {
                        EmptyView()
                    }
                    .labelsHidden()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                
                // Shared container
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.05, green: 0.10, blue: 0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    
                    if isSensitiveModeOn {
                        // Masked text
                        VStack(alignment: .leading, spacing: 0) {
                            Text(maskedText(for: PAT))
                                .foregroundStyle(.white)
                                .textSelection(.enabled)
                                .padding(8)
                                .font(.title2)
                            Spacer(minLength: 0) // allows top pinning while filling space
                        }
                        .frame(maxWidth: .infinity, minHeight: 88)
                    } else {
                        // Editable text
                        TextEditor(text: $PAT)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(.white)
                            .padding(8)
                            .frame(minHeight: 88)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 40, maxHeight: .infinity)
                .padding(.horizontal)
                .contentShape(Rectangle())
                .onTapGesture {
#if canImport(UIKit)
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                    to: nil, from: nil, for: nil)
#endif
                }
                .onAppear {
                    PAT = getCredentials().PAT ?? ""
                }
                
                Text("Enter Account/Server URL")
                    .foregroundStyle(.white)
                
                TextEditor(text: $accountURL)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 14, maxHeight: 88)
                    .padding(8) // inner padding to keep text away from the border
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                    .scrollContentBackground(.hidden)
                    .background(Color(red: 0.05, green: 0.10, blue: 0.25))
                    .foregroundStyle(.white)
                    .cornerRadius(8) // Clip the TextEditor's background
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2) // The custom border color and width
                    )
                //.clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .onTapGesture {
#if canImport(UIKit)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                        to: nil, from: nil, for: nil)
#endif
                    }
                    .onAppear() {
                        accountURL = getCredentials().accountURL ?? ""
                    }
                Text("Enter Agent Database")
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                
                TextField("Database Name…", text: $database)
                    .textFieldStyle(.plain)
                    .background(Color(red: 0.05, green: 0.10, blue: 0.25))
                    .foregroundStyle(.white)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .onTapGesture {
#if canImport(UIKit)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                        to: nil, from: nil, for: nil)
#endif
                    }
                    .onAppear {
                        if database.isEmpty {
                            database = getCredentials().database ?? ""
                        }
                    }
                Text("Enter Agent Schema")
                    .foregroundStyle(.white)
                
                TextField("Schema Name…", text: $schema)
                    .textFieldStyle(.plain)
                    .background(Color(red: 0.05, green: 0.10, blue: 0.25))
                    .foregroundStyle(.white)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .onTapGesture {
#if canImport(UIKit)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                        to: nil, from: nil, for: nil)
#endif
                    }
                    .onAppear {
                        if schema.isEmpty {
                            schema = getCredentials().schema ?? ""
                        }
                    }
                Text("Enter Agent Name")
                    .foregroundStyle(.white)
                
                TextField("Agent Name…", text: $agent)
                    .textFieldStyle(.plain)
                    .background(Color(red: 0.05, green: 0.10, blue: 0.25))
                    .foregroundStyle(.white)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .onTapGesture {
#if canImport(UIKit)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                        to: nil, from: nil, for: nil)
#endif
                    }
                    .onAppear {
                        if agent.isEmpty {
                            agent = getCredentials().agent ?? ""
                        }
                    }
                HStack {
                    Button("Save") {
                        saveCredentials(PAT: PAT, accountURL: accountURL, database: database, schema: schema, agent: agent)
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .buttonStyle(.bordered) // Adds a system-defined border and background
                    .tint(.indigo)
                    
                    Button("Test") {
                        Task {
                            let connectionStatus = await sseManager.testConnect(PAT: PAT, accountURL: accountURL, database: database, schema: schema, agent: agent)
                            await MainActor.run {
                                statusMessage = connectionStatus
                                showStatusAlert.toggle()
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .buttonStyle(.bordered) // Adds a system-defined border and background
                    .tint(.indigo)
                    
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .alert("Status", isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(statusMessage)
        }
        .background(Color(red: 0.05, green: 0.10, blue: 0.25))
        .navigationBarBackButtonHidden(true)
    }
    
}
    

struct ContentView: View {
    @StateObject private var sseManager = SSEManager()
    @State private var showStatusAlert = false
    @State private var statusMessage: String = ""
    @State private var userQuestion: String = ""
    @State private var displayQuestion: String = ""
    @State private var finalAnswer: String = ""
    @State private var isConnecting = false
    @State private var isThinking: Bool = true
    @State private var isShowing: Bool = false
    @State private var isExpandable: Bool = false
    @State private var isChartExpandable: Bool = false
    @State private var isChart: Bool = false
    @State private var status: String = ""
    
    func submitAction(historicalQuestion: String? = nil) {
        status = "Analyzing Request..."
        isShowing = false
        if historicalQuestion != nil {
            userQuestion = historicalQuestion!
        }
        let trimmed = userQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if userQuestion != "Explain this dataset?" {
            sseManager.userQuestionHistory.append(trimmed)
        }
        displayQuestion = "You: \(userQuestion)"
        sseManager.thinkingMessages = ""
        sseManager.receivedMessages.removeAll()
        sseManager.chartData.removeAll()
        sseManager.chartMark = ""
        isShowing = true
        isThinking = true
        isConnecting = true
        isExpandable = false
        isChartExpandable = false
        isChart = false
        sseManager.connectToSSE(userQuestion: trimmed)
        userQuestion = ""
        
        // Dismiss keyboard
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
        #endif
        
    }
    
    // Determine an appropriate abbreviation scale (Percent/K/M/B) based on current chart data
    func currentAbbreviationScale() -> (mode: String, suffix: String, divisor: Double) {
        let maxValue = sseManager.chartData.map { $0.value }.max() ?? 0
        let minValue = sseManager.chartData.map { $0.value }.min() ?? 0
        // Treat datasets that look like percentages (0.0 ... 1.0) as percent
        if maxValue <= 1.0, minValue >= 0.0 {
            return ("percent", "%", 1)
        }
        switch maxValue {
        case 1_000_000_000...:
            return ("number", "B", 1_000_000_000)
        case 1_000_000...:
            return ("number", "M", 1_000_000)
        case 1_000...:
            return ("number", "K", 1_000)
        default:
            return ("number", "", 1)
        }
    }

    // Formats a single numeric value using the current scale (percent or abbreviated number)
    func formatAbbreviated(_ value: Double) -> String {
        let scale = currentAbbreviationScale()
        if scale.mode == "percent" {
            // Show as percent with one fractional digit (e.g., 16.2%)
            return value.formatted(.percent.precision(.fractionLength(1)))
        } else {
            let scaled = value / scale.divisor
            let formatted = scaled.formatted(.number.precision(.fractionLength(1)))
            return scale.suffix.isEmpty ? formatted : "\(formatted)\(scale.suffix)"
        }
    }
    
    func shortenLabel(_ s: String, maxChars: Int = 8) -> String {
        if s.count <= maxChars { return s }
        let prefixPart = String(s.prefix(maxChars))
        return prefixPart + "…"
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            Menu {
                ForEach(sseManager.userQuestionHistory, id: \.self) { item in
                    Button(action: {
                        print("Tapped: \(item)")
                        submitAction(historicalQuestion: item)
                    }) {
                        Text(item)
                    }
                }
            } label: {
                Label("", systemImage: "line.horizontal.3")
            }
            .foregroundColor(Color(.white))
            .font(.system(size: 20))
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                Text("chat").foregroundColor(.blue).font(.title2)
                Text("ai/bi").foregroundColor(.white).font(.title2)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(Color(.white))
                    .font(.system(size: 20))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    @ViewBuilder
    private var thinkingView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(sseManager.thinkingMessages)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.05, green: 0.10, blue: 0.25))
                        .foregroundStyle(.white)
                        .padding(8)
                        .lineLimit(nil)
                    Color.clear
                        .frame(height: 1)
                        .id("BOTTOM_ANCHOR")
                }
            }
            .frame(minHeight: 150, maxHeight: .infinity)
            .clipped()
            .onChange(of: sseManager.thinkingMessages) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("BOTTOM_ANCHOR", anchor: .bottom)
                }
            }
            .onAppear {
                proxy.scrollTo("BOTTOM_ANCHOR", anchor: .bottom)
            }
        }
    }

    @ViewBuilder
    private var chartHeaderView: some View {
        HStack {
            Button(action: { isChart.toggle() }) {
                Image(systemName: "arrow.right.circle")
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isChart ? 90 : 0))
            }
            Text(sseManager.chartTitle)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var chartContentView: some View {
        if sseManager.chartMark == "point" {
            
            Chart {
                ForEach(sseManager.chartData) { datum in
                    PointMark(
                        x: .value(sseManager.chartXaxisLabel, datum.category),
                        y: .value(sseManager.chartYaxisLabel, datum.value)
                    )
                    .symbolSize((datum.size ?? 30))
                    .foregroundStyle(by: .value("Group", datum.colorCategory ?? ""))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let s = value.as(String.self) {
                            Text(shortenLabel(s, maxChars: 7))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(formatAbbreviated(v))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        } else if sseManager.chartMark == "bar" {
            Chart {
                ForEach(sseManager.chartData) { datum in
                    BarMark(
                        x: .value(sseManager.chartXaxisLabel, datum.category),
                        y: .value(sseManager.chartYaxisLabel, datum.value)
                    )
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let s = value.as(String.self) {
                            Text(shortenLabel(s, maxChars: 7))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(formatAbbreviated(v))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        } else if sseManager.chartMark == "line" {
            Chart {
                ForEach(sseManager.chartData) { datum in
                    LineMark(
                        x: .value(sseManager.chartXaxisLabel, datum.category),
                        y: .value(sseManager.chartYaxisLabel, datum.value)
                    )
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let s = value.as(String.self) {
                            Text(shortenLabel(s, maxChars: 7))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(formatAbbreviated(v))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        } else if sseManager.chartMark == "arc" {
            Chart {
                ForEach(sseManager.chartData) { datum in
                    SectorMark(
                        angle: .value(sseManager.chartYaxisLabel, datum.value),
                        innerRadius: .ratio(0.0)
                    )
                    .foregroundStyle(by: .value(sseManager.chartXaxisLabel, datum.category))
                    .annotation(position: .overlay) {
                        Text(formatAbbreviated(datum.value))
                            .foregroundStyle(.white)
                            .font(.caption)
                    }
                }
            }
            .chartLegend(.hidden)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                headerView
                
                //Display user question
                Text(displayQuestion)
                    .frame(maxWidth: .infinity, alignment: .leading) // left-justify content
                    .background(Color(red: 0.05, green: 0.10, blue: 0.25))
                    .foregroundStyle(.white)
                    .padding(8)
                    //.overlay(
                    //    RoundedRectangle(cornerRadius: 8)
                    //        .stroke(Color.blue, lineWidth: 2)
                    //)
                    .lineLimit(nil)
                    //.padding(.horizontal)
                
                //Show progress and create button for collapsible "Thinking" section
                HStack {
                    if isConnecting {
                        ProgressView("Connecting…")
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .padding(.vertical, 8)
                            .labelsHidden()
                    } else {
                        if isExpandable {
                            Button(action: {
                                isShowing = !isShowing
                            }) {
                                if !isShowing {
                                    Image(systemName: "arrow.right.circle")
                                        .foregroundStyle(.white)
                                } else {
                                    Image(systemName: "arrow.right.circle")
                                        .foregroundStyle(.white)
                                        .rotationEffect(.degrees(90))
                                }
                            }
                        }
                        
                    }
                    Text(status)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                //Thinking response
                if isShowing {
                    thinkingView
                }
                
                //Button for Chart Section
                if isChartExpandable {
                    chartHeaderView
                }
                //Chart section of response
                if isChart {
                    chartContentView
                }
               
                //Final Message
                if !isShowing {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                // Join all received messages into a single text blob separated by blank lines
                                Color.clear
                                    .frame(height: 1)
                                    .id("FINAL_TOP_ANCHOR")
                                let fullText = sseManager.receivedMessages.joined(separator: "\n\n")
                                Text(fullText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(red: 0.05, green: 0.10, blue: 0.25))
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .lineLimit(nil)
                                // Invisible anchor at the bottom
                                Color.clear
                                    .frame(height: 1)
                                    .id("FINAL_BOTTOM_ANCHOR")
                            }
                        }
                        .frame(minHeight: 150, maxHeight: .infinity)
                        .clipped()
                        .onAppear {
                            proxy.scrollTo("FINAL_TOP_ANCHOR", anchor: .top)
                        }
                        .onChange(of: sseManager.receivedMessages) { _, _ in
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("FINAL_TOP_ANCHOR", anchor: .top)
                            }
                        }
                    }
                }

                HStack {
                    if isConnecting {
                        Button {
                              sseManager.cancel()
                              isConnecting = false
                              //status = "Cancelled"
                          } label: {
                              Label("", systemImage: "stop.circle")
                                  .labelStyle(.titleAndIcon)
                          }
                          .buttonStyle(.bordered)
                          .tint(.red)
                    }
                    TextField("", text: $userQuestion, prompt: Text("Ask a question...")
                        .foregroundStyle(.gray))
                        .textFieldStyle(.plain)
                        .background(Color(red: 0.05, green: 0.10, blue: 0.25))
                        .foregroundStyle(.white)
                        .padding(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                        .onSubmit {
                            submitAction()
                        }
                    
                    
                    Button(action: {
                        submitAction()
                    }) {
                        Image(systemName: "paperplane.circle")
                            .rotationEffect(.degrees(-45))
                            .foregroundColor(Color(.gray))
                            .font(.system(size: 30))
                    }
                }
            }
            .onChange(of: sseManager.statusMessage) { _, newValue in
                if !newValue.isEmpty {
                    status = sseManager.statusMessage
                }
            }
            .onChange(of: sseManager.receivedMessages) { _, newValue in
                if !newValue.isEmpty {
                    isConnecting = false
                    isShowing = false
                    if !sseManager.chartMark.isEmpty {
                        isChart = true
                        isChartExpandable = true
                    }
                    isExpandable = true
                    finalAnswer = sseManager.receivedMessages.last ?? ""
                    //sseManager.receivedMessages
                    status = "Show Details"
                }
            }
            .padding()
            .background(Color(red: 0.05, green: 0.10, blue: 0.25))
        }
        
    }
    
}

#Preview ("ContentView") {
    ContentView()
}

#Preview ("SetingsView") {
    SettingsView()
}

