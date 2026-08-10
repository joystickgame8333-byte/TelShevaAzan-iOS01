import Combine
import Foundation

final class AdhkarProgressStore: ObservableObject {
    @Published private(set) var dailyCounts: [String: Int]
    @Published private(set) var tasbihCounts: [String: Int]

    private let defaults: UserDefaults

    private static let dailyCountsKey = "adhkar.reader.dailyCounts.v1"
    private static let dailyDateKey = "adhkar.reader.dailyDate.v1"
    private static let tasbihCountsKey = "adhkar.tasbih.counts.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        dailyCounts = Self.decodeCounts(defaults.string(forKey: Self.dailyCountsKey))
        tasbihCounts = Self.decodeCounts(defaults.string(forKey: Self.tasbihCountsKey))
        refreshDayIfNeeded()
    }

    func refreshDayIfNeeded(at date: Date = Date()) {
        let currentDay = Self.dayKey(for: date)
        guard defaults.string(forKey: Self.dailyDateKey) != currentDay else {
            return
        }

        dailyCounts = [:]
        defaults.set(currentDay, forKey: Self.dailyDateKey)
        persistDailyCounts()
    }

    func count(for item: AdhkarItem) -> Int {
        min(max(dailyCounts[item.id, default: 0], 0), item.target)
    }

    func isComplete(_ item: AdhkarItem) -> Bool {
        count(for: item) >= item.target
    }

    @discardableResult
    func increment(_ item: AdhkarItem) -> Bool {
        let oldValue = count(for: item)
        guard oldValue < item.target else { return false }

        let newValue = min(oldValue + 1, item.target)
        dailyCounts[item.id] = newValue
        persistDailyCounts()
        return newValue == item.target
    }

    func decrement(_ item: AdhkarItem) {
        let oldValue = count(for: item)
        guard oldValue > 0 else { return }
        dailyCounts[item.id] = oldValue - 1
        persistDailyCounts()
    }

    func reset(_ item: AdhkarItem) {
        dailyCounts.removeValue(forKey: item.id)
        persistDailyCounts()
    }

    func reset(_ category: AdhkarCategory) {
        for item in AdhkarLibrary.items(for: category) {
            dailyCounts.removeValue(forKey: item.id)
        }
        persistDailyCounts()
    }

    func completedItems(in category: AdhkarCategory) -> Int {
        AdhkarLibrary.items(for: category).filter(isComplete).count
    }

    func progress(in category: AdhkarCategory) -> Double {
        let items = AdhkarLibrary.items(for: category)
        guard !items.isEmpty else { return 0 }
        return Double(completedItems(in: category)) / Double(items.count)
    }

    func firstIncompleteItem(in category: AdhkarCategory) -> AdhkarItem? {
        AdhkarLibrary.items(for: category).first { !isComplete($0) }
    }

    func tasbihCount(for id: String) -> Int {
        max(tasbihCounts[id, default: 0], 0)
    }

    @discardableResult
    func incrementTasbih(id: String, target: Int) -> Bool {
        let newValue = tasbihCount(for: id) + 1
        tasbihCounts[id] = newValue
        persistTasbihCounts()
        return target > 0 && newValue.isMultiple(of: target)
    }

    func decrementTasbih(id: String) {
        let oldValue = tasbihCount(for: id)
        guard oldValue > 0 else { return }
        tasbihCounts[id] = oldValue - 1
        persistTasbihCounts()
    }

    func resetTasbih(id: String) {
        tasbihCounts.removeValue(forKey: id)
        persistTasbihCounts()
    }

    private func persistDailyCounts() {
        defaults.set(Self.encodeCounts(dailyCounts), forKey: Self.dailyCountsKey)
    }

    private func persistTasbihCounts() {
        defaults.set(Self.encodeCounts(tasbihCounts), forKey: Self.tasbihCountsKey)
    }

    private static func dayKey(for date: Date) -> String {
        let components = PrayerEngine.calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            locale: Locale(identifier: "en_US_POSIX"),
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    private static func encodeCounts(_ counts: [String: Int]) -> String {
        guard let data = try? JSONEncoder().encode(counts),
              let text = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return text
    }

    private static func decodeCounts(_ text: String?) -> [String: Int] {
        guard let text,
              let data = text.data(using: .utf8),
              let counts = try? JSONDecoder().decode([String: Int].self, from: data)
        else {
            return [:]
        }
        return counts
    }
}
