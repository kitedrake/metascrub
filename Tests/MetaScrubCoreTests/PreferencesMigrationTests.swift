import Foundation
import Testing
@testable import MetaScrubCore

/// Settings saved under the earlier bundle ID are carried over once, without overwriting anything newer.
@Suite struct PreferencesMigrationTests {
    @Test func copiesMissingKeysOnceAndKeepsNewerOnes() throws {
        let old = "test.metascrub.old.\(UUID().uuidString)"
        let new = "test.metascrub.new.\(UUID().uuidString)"
        let earlier = try #require(UserDefaults(suiteName: old))
        let defaults = try #require(UserDefaults(suiteName: new))
        defer {
            earlier.removePersistentDomain(forName: old)
            defaults.removePersistentDomain(forName: new)
        }
        earlier.setPersistentDomain(["destinationMode": "folder", "outputFolder": "/tmp/out", "skipReplaceConfirmation": true],
                                    forName: old)
        defaults.set("replace", forKey: "destinationMode")

        #expect(PreferencesMigration.carryOver(from: old, into: defaults) == 2)
        #expect(defaults.string(forKey: "destinationMode") == "replace")
        #expect(defaults.string(forKey: "outputFolder") == "/tmp/out")
        #expect(defaults.bool(forKey: "skipReplaceConfirmation"))

        // A second launch copies nothing, even if the old copy of the app changed its settings since.
        earlier.setPersistentDomain(["outputFolder": "/tmp/elsewhere"], forName: old)
        defaults.removeObject(forKey: "outputFolder")
        #expect(PreferencesMigration.carryOver(from: old, into: defaults) == 0)
        #expect(defaults.object(forKey: "outputFolder") == nil)
        // The earlier app's own settings stay where they were.
        #expect(UserDefaults(suiteName: old)?.string(forKey: "outputFolder") == "/tmp/elsewhere")
    }

    @Test func nothingToCarryOverStillMarksItDone() throws {
        let new = "test.metascrub.new.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: new))
        defer { defaults.removePersistentDomain(forName: new) }
        #expect(PreferencesMigration.carryOver(from: "test.metascrub.none.\(UUID().uuidString)", into: defaults) == 0)
        #expect(defaults.string(forKey: "PreferencesCarriedOverFrom") != nil)
    }
}
