import Foundation
import SQLite3

enum SQLiteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}

struct SearchResult: Identifiable {
    var artist: String
    var song: String
    var peak: Int
    var id: String {
        artist + song
    }
}

class SQLiteDatabase {
    private let db: OpaquePointer?

    private init(db: OpaquePointer?) {
        self.db = db
    }

    deinit {
        sqlite3_close(self.db)
    }

    static func open(path: String) throws -> SQLiteDatabase {
        var db: OpaquePointer?
        if sqlite3_open(path, &db) == SQLITE_OK {
            return SQLiteDatabase(db: db)
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

    func search(query: String) throws -> [SearchResult] {
        let statementString = """
select title, performer, max(peak_pos)
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
        var results: [SearchResult] = []
        while sqlite3_step(statementPointer) == SQLITE_ROW {
            guard let title = sqlite3_column_text(statementPointer, 0),
                  let performer = sqlite3_column_text(statementPointer, 1) else {
                throw SQLiteError.Step(message: "missing fields")
            }
            let peak = sqlite3_column_int(statementPointer, 2)
            results.append(SearchResult(
                artist: String(cString: performer),
                song: String(cString: title),
                peak: Int(peak)
            ))
        }
        return results
    }
}
