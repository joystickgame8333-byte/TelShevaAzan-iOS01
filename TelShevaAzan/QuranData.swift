import Foundation

struct QuranPayload: Decodable {
    let schemaVersion: Int
    let sourceName: String
    let sourceURL: String
    let pages: [QuranPage]
    let surahs: [QuranSurah]
}

struct QuranPage: Decodable, Identifiable {
    let number: Int
    let juz: Int
    let surahIDs: [Int]
    let lines: [QuranPageLine]

    var id: Int { number }
}

struct QuranPageLine: Decodable, Identifiable {
    let number: Int
    let kind: QuranPageLineKind
    let text: String

    var id: Int { number }
}

enum QuranPageLineKind: String, Decodable {
    case text
    case surah
    case bismillah
}

struct QuranSurah: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let verses: Int
    let startPage: Int
    let endPage: Int
    let revelationPlace: String

    var revelationTitle: String {
        revelationPlace == "makkah" ? "مكية" : "مدنية"
    }
}

@MainActor
final class QuranStore: ObservableObject {
    enum LoadState {
        case idle
        case loading
        case loaded(QuranPayload)
        case failed
    }

    @Published private(set) var state: LoadState = .idle

    func loadIfNeeded() {
        guard case .idle = state else { return }
        state = .loading

        guard let url = Self.resourceURL() else {
            state = .failed
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                let payload = try JSONDecoder().decode(QuranPayload.self, from: data)
                guard payload.pages.count == 604, payload.surahs.count == 114 else {
                    throw QuranDataError.incompleteData
                }

                DispatchQueue.main.async {
                    self.state = .loaded(payload)
                }
            } catch {
                DispatchQueue.main.async {
                    self.state = .failed
                }
            }
        }
    }

    func retry() {
        state = .idle
        loadIfNeeded()
    }

    private static func resourceURL() -> URL? {
        Bundle.main.url(
            forResource: "quran-pages-v1",
            withExtension: "json",
            subdirectory: "Quran"
        ) ?? Bundle.main.url(forResource: "quran-pages-v1", withExtension: "json")
    }
}

private enum QuranDataError: Error {
    case incompleteData
}
