import Foundation

extension String {
    func appendLine(toFileURL: URL) throws {
        try (self + "\n").append(toFileURL: toFileURL)
    }

    func append(toFileURL: URL) throws {
        let data = self.data(using: .utf8)!
        try data.append(toFileURL: toFileURL)
    }
}

extension Data {
    func append(toFileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: toFileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: toFileURL, options: .atomic)
        }
    }
}

extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmssZZZZZ"
        return formatter
    }()
}

extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}

class SubDataFile {
    private var url: URL?

    init(_ type: String, serial: String) {
        let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last! as URL
        let fileName = createDataFileName(serial, type: type)
        self.url = dir.appendingPathComponent(fileName).appendingPathExtension("csv") as URL
    }

    func write(_ content: String) {
        do {
            if self.url != nil {
                try content.appendLine(toFileURL: self.url!)
            }
        } catch {}
    }

    private func createDataFileName(_ serial: String, type: String) -> String {
        return type + "-" + serial + "-" + Date().iso8601
    }
}
