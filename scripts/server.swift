// Hebrew voice server for Claude Code (macOS).
// WebSocket server + Apple SFSpeechRecognizer in a single binary.
// No external dependencies — uses Network.framework + Speech.framework.

import Foundation
import Network
import Speech
import AppKit

let PORT: UInt16 = 19876

// MARK: - WAV helpers

func createWav(_ pcm: Data) -> Data {
    var w = Data(count: 44)
    func put(_ offset: Int, _ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { w.replaceSubrange(offset..<offset+4, with: $0) } }
    func put16(_ offset: Int, _ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { w.replaceSubrange(offset..<offset+2, with: $0) } }
    w.replaceSubrange(0..<4, with: "RIFF".data(using: .ascii)!)
    put(4, UInt32(36 + pcm.count))
    w.replaceSubrange(8..<12, with: "WAVE".data(using: .ascii)!)
    w.replaceSubrange(12..<16, with: "fmt ".data(using: .ascii)!)
    put(16, 16); put16(20, 1); put16(22, 1)
    put(24, 16000); put(28, 32000); put16(32, 2); put16(34, 16)
    w.replaceSubrange(36..<40, with: "data".data(using: .ascii)!)
    put(40, UInt32(pcm.count))
    w.append(pcm)
    return w
}

// MARK: - Speech recognition

func transcribe(_ pcm: Data, completion: @escaping (String) -> Void) {
    guard !pcm.isEmpty else { return completion("") }
    let dur = String(format: "%.1f", Double(pcm.count) / 32000.0)
    print("[voice] \(dur)s → Apple STT")

    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("hv-\(ProcessInfo.processInfo.globallyUniqueString).wav")
    try? createWav(pcm).write(to: tmp)

    guard let rec = SFSpeechRecognizer(locale: Locale(identifier: "he-IL")), rec.isAvailable else {
        try? FileManager.default.removeItem(at: tmp)
        return completion("")
    }
    let req = SFSpeechURLRecognitionRequest(url: tmp)
    req.shouldReportPartialResults = false
    if rec.supportsOnDeviceRecognition { req.requiresOnDeviceRecognition = true }

    rec.recognitionTask(with: req) { result, _ in
        try? FileManager.default.removeItem(at: tmp)
        let text = result?.isFinal == true ? result!.bestTranscription.formattedString : ""
        if !text.isEmpty { print("[voice] \"\(text)\"") }
        completion(text)
    }
}

// MARK: - WebSocket server

func sendJSON(_ conn: NWConnection, _ dict: [String: String]) {
    guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return }
    let meta = NWProtocolWebSocket.Metadata(opcode: .text)
    let ctx = NWConnection.ContentContext(identifier: "ws", metadata: [meta])
    conn.send(content: data, contentContext: ctx, isComplete: true, completion: .idempotent)
}

class Session {
    var chunks: [Data] = []
    var closed = false

    func receive(_ conn: NWConnection) {
        conn.receiveMessage { [self] data, ctx, _, error in
            guard let data = data, error == nil else { return }
            let meta = ctx?.protocolMetadata(definition: NWProtocolWebSocket.definition) as? NWProtocolWebSocket.Metadata

            switch meta?.opcode {
            case .binary:
                if !closed { chunks.append(data) }
            case .text:
                handleText(conn, data)
            default: break
            }
            receive(conn)
        }
    }

    func handleText(_ conn: NWConnection, _ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        if type == "KeepAlive" { return }
        if type == "CloseStream" && !closed {
            closed = true
            sendJSON(conn, ["type": "TranscriptText", "data": ""])
            let pcm = chunks.reduce(Data()) { $0 + $1 }
            chunks = []
            transcribe(pcm) { text in
                if !text.isEmpty { sendJSON(conn, ["type": "TranscriptText", "data": text]) }
                sendJSON(conn, ["type": "TranscriptEndpoint"])
            }
        }
    }
}

func startServer() {
    let params = NWParameters.tcp
    let ws = NWProtocolWebSocket.Options()
    params.defaultProtocolStack.applicationProtocols.insert(ws, at: 0)

    guard let listener = try? NWListener(using: params, on: NWEndpoint.Port(rawValue: PORT)!) else {
        print("[voice] Failed to start on port \(PORT)")
        return
    }

    listener.newConnectionHandler = { conn in
        print("[voice] Connected")
        let session = Session()
        conn.start(queue: .main)
        session.receive(conn)
    }
    listener.start(queue: .main)
    print("[voice] Hebrew voice server on ws://127.0.0.1:\(PORT) (Apple STT)")
}

// MARK: - App entry (needed for macOS TCC permission)

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ n: Notification) {
        if SFSpeechRecognizer.authorizationStatus() == .authorized {
            startServer()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        startServer()
                    } else {
                        print("[voice] Speech Recognition denied. Grant in System Settings > Privacy > Speech Recognition.")
                        NSApp.terminate(nil)
                    }
                }
            }
        }
    }
}

let delegate = AppDelegate()
app.delegate = delegate
app.run()
