import Foundation

/// Manages a WebSocket connection with keep-alive pings
@Observable
final class WebSocketService: NSObject, @unchecked Sendable {

    // MARK: - Public State

    private(set) var isConnected = false

    // MARK: - Callbacks

    var onReceiveMessage: ((URLSessionWebSocketTask.Message) -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onConnect: (() -> Void)?

    // MARK: - Private

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var pingTimer: Timer?
    private let pingInterval: TimeInterval = 15

    // MARK: - Connection waiting

    private var connectionContinuation: CheckedContinuation<Void, Error>?

    // MARK: - Public API

    /// Connects to the given WebSocket URL and waits until connected
    func connect(to url: URL) async throws {
        disconnect()

        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 30

        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        webSocketTask = session?.webSocketTask(with: url)

        AppLogger.network.info("WebSocket connecting to \(url.host ?? "unknown")...")

        // Wait for the delegate callback
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.connectionContinuation = continuation
            self.webSocketTask?.resume()

            // Timeout after 10 seconds
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [weak self] in
                if let cont = self?.connectionContinuation {
                    self?.connectionContinuation = nil
                    cont.resume(throwing: WebSocketError.connectionTimeout)
                }
            }
        }

        startListening()
        startPingTimer()
    }

    /// Sends a text message over the WebSocket
    func sendText(_ text: String) async throws {
        guard let task = webSocketTask, isConnected else {
            throw WebSocketError.notConnected
        }
        try await task.send(.string(text))
    }

    /// Sends binary data over the WebSocket
    func sendData(_ data: Data) async throws {
        guard let task = webSocketTask, isConnected else {
            throw WebSocketError.notConnected
        }
        try await task.send(.data(data))
    }

    /// Disconnects the WebSocket
    func disconnect() {
        pingTimer?.invalidate()
        pingTimer = nil

        if let cont = connectionContinuation {
            connectionContinuation = nil
            cont.resume(throwing: WebSocketError.disconnected)
        }

        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil
        isConnected = false
    }

    // MARK: - Private

    private func startListening() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let message):
                self.onReceiveMessage?(message)
                self.startListening()

            case .failure(let error):
                let nsError = error as NSError
                // Ignore "Socket is not connected" (POSIX 57) or cancellation errors during intentional disconnect
                if nsError.domain == NSPOSIXErrorDomain && nsError.code == 57 {
                    return 
                }
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    return
                }

                AppLogger.network.error("WebSocket receive error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isConnected = false
                    self.onDisconnect?(error)
                }
            }
        }
    }

    private func startPingTimer() {
        DispatchQueue.main.async {
            self.pingTimer?.invalidate()
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: self.pingInterval, repeats: true) { [weak self] _ in
                guard let self, self.isConnected else { return }
                self.webSocketTask?.sendPing { error in
                    if let error, self.isConnected {
                        AppLogger.network.warning("Ping failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketService: URLSessionWebSocketDelegate {
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        AppLogger.network.info("WebSocket connected ✅")
        DispatchQueue.main.async {
            self.isConnected = true
            self.onConnect?()
        }
        // Resume the awaiting connection
        if let cont = connectionContinuation {
            connectionContinuation = nil
            cont.resume()
        }
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        let reasonStr = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "none"
        AppLogger.network.info("WebSocket closed — code: \(closeCode.rawValue), reason: \(reasonStr)")
        DispatchQueue.main.async {
            self.isConnected = false
            self.onDisconnect?(nil)
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error {
            AppLogger.network.error("WebSocket connection failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isConnected = false
                self.onDisconnect?(error)
            }
            // Resume the awaiting connection with error
            if let cont = connectionContinuation {
                connectionContinuation = nil
                cont.resume(throwing: error)
            }
        }
    }
}

// MARK: - Errors

enum WebSocketError: LocalizedError {
    case notConnected
    case sendFailed
    case connectionTimeout
    case disconnected

    var errorDescription: String? {
        switch self {
        case .notConnected:      return "WebSocket не подключён."
        case .sendFailed:        return "Не удалось отправить сообщение."
        case .connectionTimeout: return "Время подключения истекло."
        case .disconnected:      return "WebSocket отключён."
        }
    }
}
