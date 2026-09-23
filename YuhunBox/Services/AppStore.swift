import Combine
import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var souls: [SoulPiece] = []
    @Published private(set) var teams: [TeamPreset] = []
    @Published var preferences = UserPreferences() {
        didSet { save() }
    }

    private let saveURL: URL
    private var isRestoring = false

    init(fileManager: FileManager = .default) {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        saveURL = documents.appendingPathComponent("yuhunbox-data.json")
        restore()
        if souls.isEmpty && teams.isEmpty {
            installSampleData()
        }
    }

    func upsert(_ soul: SoulPiece) {
        if let index = souls.firstIndex(where: { $0.id == soul.id }) {
            souls[index] = soul
        } else {
            souls.insert(soul, at: 0)
        }
        save()
    }

    func deleteSouls(at offsets: IndexSet, from visibleSouls: [SoulPiece]) {
        let ids = Set(offsets.map { visibleSouls[$0].id })
        souls.removeAll { ids.contains($0.id) }
        save()
    }

    func deleteSoul(_ soul: SoulPiece) {
        souls.removeAll { $0.id == soul.id }
        save()
    }

    func upsert(_ team: TeamPreset) {
        var updated = team
        updated.updatedAt = Date()
        if let index = teams.firstIndex(where: { $0.id == team.id }) {
            teams[index] = updated
        } else {
            teams.insert(updated, at: 0)
        }
        save()
    }

    func deleteTeam(_ team: TeamPreset) {
        teams.removeAll { $0.id == team.id }
        save()
    }

    func importTeam(_ team: TeamPreset) {
        var copy = team
        copy.id = UUID()
        copy.title += "（导入）"
        copy.updatedAt = Date()
        teams.insert(copy, at: 0)
        save()
    }

    func clearAll() {
        souls = []
        teams = []
        save()
    }

    func restoreSamples() {
        clearAll()
        installSampleData()
    }

    func exportData() throws -> Data {
        let snapshot = AppSnapshot(souls: souls, teams: teams, preferences: preferences)
        return try JSONEncoder.appEncoder.encode(snapshot)
    }

    func importData(_ data: Data) throws {
        let snapshot = try JSONDecoder.appDecoder.decode(AppSnapshot.self, from: data)
        isRestoring = true
        souls = snapshot.souls
        teams = snapshot.teams
        preferences = snapshot.preferences
        isRestoring = false
        save()
    }

    private func restore() {
        guard
            let data = try? Data(contentsOf: saveURL),
            let snapshot = try? JSONDecoder.appDecoder.decode(AppSnapshot.self, from: data)
        else { return }

        isRestoring = true
        souls = snapshot.souls
        teams = snapshot.teams
        preferences = snapshot.preferences
        isRestoring = false
    }

    private func save() {
        guard !isRestoring else { return }
        let snapshot = AppSnapshot(souls: souls, teams: teams, preferences: preferences)
        guard let data = try? JSONEncoder.appEncoder.encode(snapshot) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }

    private func installSampleData() {
        souls = SampleData.souls
        teams = SampleData.teams
        save()
    }
}

struct AppSnapshot: Codable {
    let souls: [SoulPiece]
    let teams: [TeamPreset]
    let preferences: UserPreferences
}

extension JSONEncoder {
    static var appEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return encoder
    }
}

extension JSONDecoder {
    static var appDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

enum SampleData {
    static let souls: [SoulPiece] = [
        SoulPiece(
            set: .fortuneCat,
            slot: .two,
            level: 12,
            mainStat: SoulStat(type: .speed, value: 52),
            substats: [
                SoulStat(type: .speed, value: 11),
                SoulStat(type: .effectResist, value: 8),
                SoulStat(type: .hpPercent, value: 6),
                SoulStat(type: .defensePercent, value: 3)
            ],
            isLocked: true
        ),
        SoulPiece(
            set: .shadow,
            slot: .six,
            level: 6,
            mainStat: SoulStat(type: .critDamage, value: 55),
            substats: [
                SoulStat(type: .critRate, value: 9),
                SoulStat(type: .attackPercent, value: 6),
                SoulStat(type: .speed, value: 3),
                SoulStat(type: .flatDefense, value: 5)
            ]
        ),
        SoulPiece(
            set: .snowSpirit,
            slot: .four,
            level: 9,
            mainStat: SoulStat(type: .effectHit, value: 38),
            substats: [
                SoulStat(type: .speed, value: 8),
                SoulStat(type: .hpPercent, value: 9),
                SoulStat(type: .effectResist, value: 4)
            ]
        ),
        SoulPiece(
            set: .seaMoon,
            slot: .three,
            level: 3,
            mainStat: SoulStat(type: .flatDefense, value: 24),
            substats: [
                SoulStat(type: .critRate, value: 6),
                SoulStat(type: .critDamage, value: 8),
                SoulStat(type: .attackPercent, value: 3)
            ]
        ),
        SoulPiece(
            set: .clam,
            slot: .six,
            level: 15,
            mainStat: SoulStat(type: .critRate, value: 55),
            substats: [
                SoulStat(type: .speed, value: 14),
                SoulStat(type: .hpPercent, value: 11),
                SoulStat(type: .effectResist, value: 8)
            ],
            isLocked: true
        )
    ]

    static let teams: [TeamPreset] = [
        TeamPreset(
            title: "御魂十层 · 稳定",
            scene: "御魂副本",
            members: [
                TeamMember(name: "山兔", role: "一速拉条", goal: .firstSpeed, soulPlan: "招财猫 · 速生生", speedTarget: 165),
                TeamMember(name: "座敷童子", role: "供火", goal: .survival, soulPlan: "火灵 · 生生生", speedTarget: 130),
                TeamMember(name: "晴明", role: "阴阳师", goal: .survival, soulPlan: "星 / 灭", speedTarget: nil),
                TeamMember(name: "阿修罗", role: "主输出", goal: .critDamage, soulPlan: "破势 · 攻攻爆", speedTarget: 128),
                TeamMember(name: "烬天玉藻前", role: "收尾", goal: .critOutput, soulPlan: "心眼 · 攻攻暴", speedTarget: 120)
            ],
            officialCode: "",
            notes: "示例预设：速度从上到下排列。"
        )
    ]
}

