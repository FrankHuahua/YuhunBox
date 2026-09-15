import XCTest
@testable import YuhunBox

final class YuhunBoxTests: XCTestCase {
    func testPresetCodeRoundTrip() throws {
        let team = SampleData.teams[0]
        let code = try PresetCodeCodec.encode(team)
        let decoded = try PresetCodeCodec.decode(code)

        XCTAssertTrue(code.hasPrefix("YHX1:"))
        XCTAssertEqual(decoded.title, team.title)
        XCTAssertEqual(decoded.members, team.members)
        XCTAssertEqual(decoded.officialCode, team.officialCode)
    }

    func testInvalidPresetCodeIsRejected() {
        XCTAssertThrowsError(try PresetCodeCodec.decode("not-a-yuhunbox-code"))
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

