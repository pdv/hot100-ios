import Foundation
import SQLite3
import Combine

enum SQLiteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}

struct Track: Identifiable {
    var artist: String
    var song: String
    var peak: Int
    var id: String {
        artist + song
    }
}

struct Entry: Identifiable {
    var week: String
    var position: Int
    var id: String {
        "\(week)-\(position)"
    }
}

@Observable
class Hot100 {
    private let db: OpaquePointer?

    private init(db: OpaquePointer?) {
        self.db = db
    }

    deinit {
        sqlite3_close(self.db)
    }

    static func open() throws -> Hot100 {
        let path = Bundle.main.path(forResource: "hot100", ofType: "db")
        var db: OpaquePointer?
        if sqlite3_open(path, &db) == SQLITE_OK {
            return Hot100(db: db)
        } else {
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            let message = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.OpenDatabase(message: message)
        }
    }

    func search(query: String) throws -> [Track] {
        let statementString = """
select title, performer, min(peak_pos)
from hot100
where performer like '%' || ?1 || '%' or title like '%' || ?1 || '%'
group by 1, 2
order by 3
"""
        var statementPointer: OpaquePointer?
        defer {
            sqlite3_finalize(statementPointer)
        }
        guard sqlite3_prepare_v2(self.db, statementString, -1, &statementPointer, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.Prepare(message: message)
        }
        guard sqlite3_bind_text(statementPointer, 1, NSString(string: query).utf8String, -1, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.Bind(message: message)
        }
        var results: [Track] = []
        while sqlite3_step(statementPointer) == SQLITE_ROW {
            guard let title = sqlite3_column_text(statementPointer, 0),
                  let performer = sqlite3_column_text(statementPointer, 1) else {
                throw SQLiteError.Step(message: "missing fields")
            }
            let peak = sqlite3_column_int(statementPointer, 2)
            results.append(Track(
                artist: String(cString: performer),
                song: String(cString: title),
                peak: Int(peak)
            ))
        }
        return results
    }

    func entries(performer: String, title: String) throws -> [Entry] {
        let statementString = """
select chart_week, current_week
from hot100
where performer = ?1 and title = ?2
"""
        var statementPointer: OpaquePointer?
        defer {
            sqlite3_finalize(statementPointer)
        }
        guard sqlite3_prepare_v2(self.db, statementString, -1, &statementPointer, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.Prepare(message: message)
        }
        guard sqlite3_bind_text(statementPointer, 1, NSString(string: performer).utf8String, -1, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.Bind(message: message)
        }
        guard sqlite3_bind_text(statementPointer, 2, NSString(string: title).utf8String, -1, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.Bind(message: message)
        }
        var results: [Entry] = []
        while sqlite3_step(statementPointer) == SQLITE_ROW {
            guard let week = sqlite3_column_text(statementPointer, 0) else {
                throw SQLiteError.Step(message: "missing fields")
            }
            let position = sqlite3_column_int(statementPointer, 1)
            results.append(Entry(
                week: String(cString: week),
                position: Int(position)
            ))
        }
        return results
    }

    func chart(week: String) throws -> [Track] {
        let statementString = """
select current_week, performer, title
from hot100
where chart_week = ?
"""
        var statementPointer: OpaquePointer?
        defer {
            sqlite3_finalize(statementPointer)
        }
        guard sqlite3_prepare_v2(self.db, statementString, -1, &statementPointer, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.Prepare(message: message)
        }
        guard sqlite3_bind_text(statementPointer, 1, NSString(string: week).utf8String, -1, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.Bind(message: message)
        }
        var results: [Track] = []
        while sqlite3_step(statementPointer) == SQLITE_ROW {
            let position = sqlite3_column_int(statementPointer, 0)
            guard let artist = sqlite3_column_text(statementPointer, 1),
                  let song = sqlite3_column_text(statementPointer, 2) else {
                throw SQLiteError.Step(message: "missing fields")
            }
            results.append(Track(
                artist: String(cString: artist),
                song: String(cString: song),
                peak: Int(position)
            ))
        }
        return results
    }
}
