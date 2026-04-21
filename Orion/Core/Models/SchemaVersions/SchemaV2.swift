// SchemaV2.swift — Core/Models/SchemaVersions
// Schema version 2.0.0 — StudySession.subject changed from enum raw value to human-readable String

import SwiftData
import Foundation

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            StudySession.self,   // live model — subject is now plain String display name
            GymSession.self,
            HabitLog.self,
            StreakData.self
        ]
    }
}
