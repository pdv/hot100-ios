import SwiftUI

@main
struct Hot100App: App {
    @State var db: Hot100? = nil
    var body: some Scene {
        WindowGroup {
            if let db = db {
                SearchView()
                    .environment(db)
            } else {
                ProgressView().task {
                    db = try! .open()
                }
            }
        }
    }
}
