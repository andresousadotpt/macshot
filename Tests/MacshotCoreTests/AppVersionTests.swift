import XCTest
@testable import MacshotCore

final class AppVersionTests: XCTestCase {
    func testMarketingVersionIsNonEmpty() {
        XCTAssertFalse(AppVersion.marketing.isEmpty)
    }
}
