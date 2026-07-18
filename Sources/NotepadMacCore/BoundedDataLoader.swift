import Foundation

public enum BoundedDataLoaderError: LocalizedError, Equatable {
    case unsupportedURLScheme(url: String)
    case fileTooLarge(url: String, maxBytes: Int)
    case responseTooLarge(url: String, maxBytes: Int)
    case requestTimedOut(url: String, timeout: TimeInterval)
    case httpStatus(url: String, statusCode: Int)
    case requestFailed(url: String, reason: String)

    public var errorDescription: String? {
        switch self {
        case let .unsupportedURLScheme(url):
            "Download URL must use HTTPS or a local file URL: \(url)."
        case let .fileTooLarge(url, maxBytes):
            "Local file is too large. Maximum allowed size is \(maxBytes) bytes: \(url)."
        case let .responseTooLarge(url, maxBytes):
            "Download is too large. Maximum allowed size is \(maxBytes) bytes: \(url)."
        case let .requestTimedOut(url, timeout):
            "Download timed out after \(Int(timeout)) seconds: \(url)."
        case let .httpStatus(url, statusCode):
            "Download failed with HTTP status \(statusCode): \(url)."
        case let .requestFailed(url, reason):
            "Download failed for \(url): \(reason)."
        }
    }
}

public struct BoundedDataLoader: Sendable {
    public init() {}

    public func load(from url: URL, maxBytes: Int, timeout: TimeInterval) throws -> Data {
        if url.isFileURL {
            return try loadFile(from: url, maxBytes: maxBytes)
        }
        guard url.scheme == "https" else {
            throw BoundedDataLoaderError.unsupportedURLScheme(url: url.absoluteString)
        }
        return try BoundedHTTPDownload(url: url, maxBytes: maxBytes, timeout: timeout).run()
    }

    private func loadFile(from url: URL, maxBytes: Int) throws -> Data {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let size = attributes[.size] as? NSNumber, size.intValue > maxBytes {
            throw BoundedDataLoaderError.fileTooLarge(url: url.path, maxBytes: maxBytes)
        }
        let data = try Data(contentsOf: url)
        guard data.count <= maxBytes else {
            throw BoundedDataLoaderError.fileTooLarge(url: url.path, maxBytes: maxBytes)
        }
        return data
    }
}

private final class BoundedHTTPDownload: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let url: URL
    private let maxBytes: Int
    private let timeout: TimeInterval
    private let semaphore = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var receivedData = Data()
    private var result: Result<Data, Error>?
    private var task: URLSessionDataTask?
    private var session: URLSession?

    init(url: URL, maxBytes: Int, timeout: TimeInterval) {
        self.url = url
        self.maxBytes = maxBytes
        self.timeout = timeout
    }

    func run() throws -> Data {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        self.session = session
        let task = session.dataTask(with: url)
        self.task = task
        task.resume()

        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            task.cancel()
            session.invalidateAndCancel()
            throw BoundedDataLoaderError.requestTimedOut(url: url.absoluteString, timeout: timeout)
        }

        session.invalidateAndCancel()
        return try finalResult().get()
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        guard let httpResponse = response as? HTTPURLResponse else {
            finish(.failure(BoundedDataLoaderError.requestFailed(url: url.absoluteString, reason: "No HTTP response.")))
            completionHandler(.cancel)
            return
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            finish(.failure(BoundedDataLoaderError.httpStatus(url: url.absoluteString, statusCode: httpResponse.statusCode)))
            completionHandler(.cancel)
            return
        }
        if httpResponse.expectedContentLength > Int64(maxBytes) {
            finish(.failure(BoundedDataLoaderError.responseTooLarge(url: url.absoluteString, maxBytes: maxBytes)))
            completionHandler(.cancel)
            return
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        receivedData.append(data)
        let isTooLarge = receivedData.count > maxBytes
        lock.unlock()

        if isTooLarge {
            finish(.failure(BoundedDataLoaderError.responseTooLarge(url: url.absoluteString, maxBytes: maxBytes)))
            task?.cancel()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error, finalResultOrNil() == nil {
            finish(.failure(BoundedDataLoaderError.requestFailed(url: url.absoluteString, reason: error.localizedDescription)))
            return
        }

        lock.lock()
        let data = receivedData
        lock.unlock()
        finish(.success(data))
    }

    private func finish(_ result: Result<Data, Error>) {
        lock.lock()
        defer { lock.unlock() }
        guard self.result == nil else { return }
        self.result = result
        semaphore.signal()
    }

    private func finalResultOrNil() -> Result<Data, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return result
    }

    private func finalResult() -> Result<Data, Error> {
        finalResultOrNil() ?? .failure(BoundedDataLoaderError.requestFailed(url: url.absoluteString, reason: "No completion result."))
    }
}
