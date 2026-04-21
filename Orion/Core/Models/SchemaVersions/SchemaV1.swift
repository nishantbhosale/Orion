// SchemaVersions.swift — Core/Models/SchemaVersions
// All versioned schema definitions live here.
// V1 is the canonical current schema (subject as String).

import SwiftData
import Foundation

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            StudySession.self,
            GymSession.self,
            HabitLog.self,
            StreakData.self,
            BodyMetricLog.self,
            WorkoutTemplate.self,
            PRLog.self
        ]
    }
}
