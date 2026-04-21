// OrionMigrationPlan.swift — Core/Models/SchemaVersions
// No staged migrations needed. The old store will be handled by
// the fault-tolerant container setup in OrionApp.swift.

import SwiftData

enum OrionMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] { [] }
}
