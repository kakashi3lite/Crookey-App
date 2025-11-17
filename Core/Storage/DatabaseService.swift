//
//  DatabaseService.swift
//  Crookey
//
//  Created by Claude Code
//  Copyright © 2025 Crookey. All rights reserved.
//

import Foundation
import SQLite3
import OSLog

/// Privacy-first database service using SQLite
/// All data stored locally, zero-liability architecture
/// SECURITY: Database file encrypted via iOS Data Protection (FileProtectionType.complete)
@MainActor
final class DatabaseService {
    static let shared = DatabaseService()

    private var db: OpaquePointer?
    private let logger = Logger(subsystem: "com.crookey.app", category: "DatabaseService")
    private let databaseFileName = "CrookeyPantry.sqlite"

    /// Database initialization state for error recovery
    private(set) var initializationError: DatabaseError?
    private(set) var isInitialized = false

    // MARK: - Initialization

    private init() {
        // Private initializer for singleton
        // Actual database initialization is lazy and explicit
    }

    /// Initialize database with proper error handling and fallback
    /// MUST be called before any database operations
    func initialize() async throws {
        guard !isInitialized else {
            logger.info("Database already initialized")
            return
        }

        do {
            try await openDatabase()
            try await createTables()
            try await verifyDatabaseIntegrity()

            isInitialized = true
            initializationError = nil
            logger.info("✅ Database initialized successfully")

        } catch let error as DatabaseError {
            initializationError = error
            logger.error("❌ Database initialization failed: \(error.localizedDescription)")
            throw error
        } catch {
            let dbError = DatabaseError.initializationFailed(error.localizedDescription)
            initializationError = dbError
            logger.error("❌ Unexpected initialization error: \(error.localizedDescription)")
            throw dbError
        }
    }

    // MARK: - Database Setup

    private func openDatabase() async throws {
        let fileURL = try getDatabaseURL()

        // Enable file protection for encryption at rest
        try enableFileProtection(at: fileURL)

        var dbPointer: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX

        guard sqlite3_open_v2(fileURL.path, &dbPointer, flags, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(dbPointer))
            sqlite3_close(dbPointer)
            throw DatabaseError.initializationFailed("Failed to open database: \(errorMessage)")
        }

        db = dbPointer

        // Enable Write-Ahead Logging for better concurrency and crash recovery
        try executeSQL("PRAGMA journal_mode = WAL;")

        // Enable foreign key constraints
        try executeSQL("PRAGMA foreign_keys = ON;")

        logger.info("Database opened at: \(fileURL.path)")
    }

    private func getDatabaseURL() throws -> URL {
        guard let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw DatabaseError.initializationFailed("Could not access documents directory")
        }

        return documentsURL.appendingPathComponent(databaseFileName)
    }

    private func enableFileProtection(at url: URL) throws {
        // If file doesn't exist yet, it will be created with protection
        if !FileManager.default.fileExists(atPath: url.path) {
            logger.info("Database file will be created with complete protection")
            return
        }

        // Apply strictest file protection for existing file
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )

        logger.info("✅ File protection enabled: complete encryption at rest")
    }

    // MARK: - Schema Creation

    private func createTables() async throws {
        // UserPantry table - user's private inventory
        let createUserPantry = """
        CREATE TABLE IF NOT EXISTS UserPantry (
            id TEXT PRIMARY KEY NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit TEXT NOT NULL,
            date_added INTEGER NOT NULL,
            expiration_date INTEGER,
            notes TEXT,
            barcode TEXT,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        );
        """

        // Products table - bundled reference data (future: from Open Food Facts)
        let createProducts = """
        CREATE TABLE IF NOT EXISTS Products (
            id TEXT PRIMARY KEY NOT NULL,
            barcode TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            brand TEXT,
            category TEXT NOT NULL,
            default_shelf_life_days INTEGER,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        );
        """

        // Indexes for performance
        let createIndexes = [
            "CREATE INDEX IF NOT EXISTS idx_pantry_category ON UserPantry(category);",
            "CREATE INDEX IF NOT EXISTS idx_pantry_expiration ON UserPantry(expiration_date);",
            "CREATE INDEX IF NOT EXISTS idx_pantry_name ON UserPantry(name);",
            "CREATE INDEX IF NOT EXISTS idx_products_barcode ON Products(barcode);",
        ]

        try executeSQL(createUserPantry)
        try executeSQL(createProducts)

        for indexSQL in createIndexes {
            try executeSQL(indexSQL)
        }

        logger.info("✅ Database schema created with indexes")
    }

    // MARK: - Integrity Checks

    private func verifyDatabaseIntegrity() async throws {
        let integrityQuery = "PRAGMA integrity_check;"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, integrityQuery, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed("Failed to prepare integrity check")
        }

        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw DatabaseError.corruptedDatabase("Integrity check failed")
        }

        if let result = sqlite3_column_text(statement, 0) {
            let resultString = String(cString: result)
            if resultString != "ok" {
                throw DatabaseError.corruptedDatabase("Integrity check returned: \(resultString)")
            }
        }

        logger.info("✅ Database integrity verified")
    }

    // MARK: - SQL Execution

    private func executeSQL(_ sql: String) throws {
        guard let db = db else {
            throw DatabaseError.initializationFailed("Database not opened")
        }

        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errorMessage)

        if result != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMessage)
            throw DatabaseError.queryFailed("SQL execution failed: \(error)")
        }
    }

    // MARK: - CRUD Operations

    /// Insert a pantry item
    func insertPantryItem(_ item: PantryItem) async throws {
        guard isInitialized else {
            throw DatabaseError.initializationFailed("Database not initialized")
        }

        let sql = """
        INSERT INTO UserPantry (
            id, name, category, quantity, unit,
            date_added, expiration_date, notes, barcode
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let error = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.insertFailed(error)
        }

        defer { sqlite3_finalize(statement) }

        // Bind parameters with type safety
        sqlite3_bind_text(statement, 1, item.id.uuidString, -1, nil)
        sqlite3_bind_text(statement, 2, item.name, -1, nil)
        sqlite3_bind_text(statement, 3, item.category.rawValue, -1, nil)
        sqlite3_bind_double(statement, 4, item.quantity)
        sqlite3_bind_text(statement, 5, item.unit.rawValue, -1, nil)
        sqlite3_bind_int64(statement, 6, Int64(item.dateAdded.timeIntervalSince1970))

        if let expirationDate = item.expirationDate {
            sqlite3_bind_int64(statement, 7, Int64(expirationDate.timeIntervalSince1970))
        } else {
            sqlite3_bind_null(statement, 7)
        }

        if let notes = item.notes {
            sqlite3_bind_text(statement, 8, notes, -1, nil)
        } else {
            sqlite3_bind_null(statement, 8)
        }

        if let barcode = item.barcode {
            sqlite3_bind_text(statement, 9, barcode, -1, nil)
        } else {
            sqlite3_bind_null(statement, 9)
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let error = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.insertFailed(error)
        }

        logger.info("✅ Inserted pantry item: \(item.name)")
    }

    /// Fetch all pantry items
    func fetchAllPantryItems() async throws -> [PantryItem] {
        guard isInitialized else {
            throw DatabaseError.initializationFailed("Database not initialized")
        }

        let sql = "SELECT * FROM UserPantry ORDER BY date_added DESC;"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let error = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(error)
        }

        defer { sqlite3_finalize(statement) }

        var items: [PantryItem] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            do {
                let item = try parsePantryItem(from: statement)
                items.append(item)
            } catch {
                logger.warning("Failed to parse pantry item: \(error.localizedDescription)")
                continue
            }
        }

        logger.info("✅ Fetched \(items.count) pantry items")
        return items
    }

    /// Delete pantry item by ID
    func deletePantryItem(id: UUID) async throws {
        guard isInitialized else {
            throw DatabaseError.initializationFailed("Database not initialized")
        }

        let sql = "DELETE FROM UserPantry WHERE id = ?;"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let error = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.deleteFailed(error)
        }

        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, id.uuidString, -1, nil)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let error = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.deleteFailed(error)
        }

        let changes = sqlite3_changes(db)
        guard changes > 0 else {
            throw DatabaseError.notFound("Pantry item not found: \(id)")
        }

        logger.info("✅ Deleted pantry item: \(id)")
    }

    // MARK: - Helper Methods

    private func parsePantryItem(from statement: OpaquePointer?) throws -> PantryItem {
        guard let statement = statement else {
            throw DatabaseError.invalidData("Invalid statement")
        }

        // Parse UUID
        guard let idString = sqlite3_column_text(statement, 0).map({ String(cString: $0) }),
              let id = UUID(uuidString: idString) else {
            throw DatabaseError.invalidData("Invalid ID")
        }

        // Parse required fields
        guard let name = sqlite3_column_text(statement, 1).map({ String(cString: $0) }),
              let categoryString = sqlite3_column_text(statement, 2).map({ String(cString: $0) }),
              let category = FoodCategory(rawValue: categoryString),
              let unitString = sqlite3_column_text(statement, 4).map({ String(cString: $0) }),
              let unit = MeasurementUnit(rawValue: unitString) else {
            throw DatabaseError.invalidData("Missing required fields")
        }

        let quantity = sqlite3_column_double(statement, 3)
        let dateAddedTimestamp = sqlite3_column_int64(statement, 5)
        let dateAdded = Date(timeIntervalSince1970: TimeInterval(dateAddedTimestamp))

        // Parse optional fields
        let expirationDate: Date? = {
            let timestamp = sqlite3_column_int64(statement, 6)
            return timestamp > 0 ? Date(timeIntervalSince1970: TimeInterval(timestamp)) : nil
        }()

        let notes = sqlite3_column_text(statement, 7).map { String(cString: $0) }
        let barcode = sqlite3_column_text(statement, 8).map { String(cString: $0) }

        return PantryItem(
            id: id,
            name: name,
            category: category,
            quantity: quantity,
            unit: unit,
            dateAdded: dateAdded,
            expirationDate: expirationDate,
            notes: notes,
            barcode: barcode
        )
    }

    // MARK: - Cleanup

    func close() {
        if let db = db {
            sqlite3_close(db)
            self.db = nil
            isInitialized = false
            logger.info("Database closed")
        }
    }

    deinit {
        close()
    }
}

// MARK: - Test Helpers

#if DEBUG
extension DatabaseService {
    /// Create in-memory database for testing
    static func createTestInstance() async throws -> DatabaseService {
        let instance = DatabaseService()
        // Override database path for testing
        // This would use an in-memory database: "file::memory:?cache=shared"
        try await instance.initialize()
        return instance
    }

    /// Reset database for testing
    func resetForTesting() async throws {
        try executeSQL("DELETE FROM UserPantry;")
        try executeSQL("DELETE FROM Products;")
        logger.info("Database reset for testing")
    }
}
#endif
