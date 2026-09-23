import XCTest
@testable import YuhunBox

final class YuhunBoxTests: XCTestCase {
    func testPresetCodeRoundTrip() throws {
        let team = SampleData.teams[0]
        let code = try PresetCodeCodec.encode(team)
        let decoded = try PresetCodeCodec.decode(code)

        XCTAssertTrue(code.hasPrefix("YHX2:"))
        XCTAssertEqual(decoded.title, team.title)
        XCTAssertEqual(decoded.members, team.members)
        XCTAssertEqual(decoded.officialCode, team.officialCode)
    }

    func testDetailedRequirementsRoundTrip() throws {
        var team = SampleData.teams[0]
        team.members[0].requirements = MemberRequirements(
            primarySet: .fortuneCat,
            slot2Main: .speed,
            slot4Main: .hpPercent,
            slot6Main: .hpPercent,
            speedMin: 165,
            effectResistMin: 40
        )

        let decoded = try PresetCodeCodec.decode(PresetCodeCodec.encode(team))
        XCTAssertEqual(decoded.members[0].requirements, team.members[0].requirements)
    }

    func testInvalidPresetCodeIsRejected() {
        XCTAssertThrowsError(try PresetCodeCodec.decode("not-a-yuhunbox-code"))
    }

    func testTenYearCatalogMarkers() {
        XCTAssertTrue(ShikigamiCatalog.records.contains { $0.name == "石长姬" && $0.rarity == .ssr })
        XCTAssertTrue(ShikigamiCatalog.records.contains { $0.name == "百羽凤凰火" && $0.rarity == .sp })
        XCTAssertFalse(ShikigamiCatalog.records.contains { $0.name == "SP不知火" })
        XCTAssertGreaterThan(ShikigamiCatalog.records.count, 150)
    }

    func testSpeedPieceRanksForFirstSpeed() {
        let fast = SoulPiece(
            set: .fortuneCat,
            slot: .two,
            level: 9,
            mainStat: SoulStat(type: .speed, value: 40),
            substats: [SoulStat(type: .speed, value: 12)]
        )
        let slow = SoulPiece(
            set: .shadow,
            slot: .two,
            level: 9,
            mainStat: SoulStat(type: .attackPercent, value: 40),
            substats: [SoulStat(type: .flatDefense, value: 10)]
        )

        let ranked = SoulAdvisor.ranked([slow, fast], for: .firstSpeed)
        XCTAssertEqual(ranked.first?.soul.id, fast.id)
        XCTAssertGreaterThan(ranked[0].score, ranked[1].score)
    }

    func testScreenshotTextCreatesDraft() {
        let draft = ScreenshotOCRService.draft(from: [
            "招财猫 2号位 +9",
            "速度 40",
            "效果抵抗 +8%",
            "生命加成 +6%"
        ])

        XCTAssertEqual(draft.set, .fortuneCat)
        XCTAssertEqual(draft.slot, .two)
        XCTAssertEqual(draft.level, 9)
        XCTAssertEqual(draft.mainStat.type, .speed)
        XCTAssertEqual(draft.substats.first?.type, .effectResist)
    }

    func testLoadoutUsesOnePiecePerSlot() {
        let suggestion = SoulAdvisor.suggestLoadout(from: SampleData.souls, for: .critOutput)
        let slots = suggestion?.pieces.map { $0.soul.slot } ?? []
        XCTAssertEqual(Set(slots).count, slots.count)
    }
}

