import SwiftUI

struct ContentView: View {
    @State var db: SQLiteDatabase? = nil
    @State var results: [SearchResult] = []
    @State var query: String = ""
    @FocusState var focused: Bool

    var body: some View {
        VStack {
            TextField("Artist", text: $query)
                .focused($focused)
            List(results) { result in
                Text("\(result.artist) - \(result.song) (\(result.peak))")
            }
            Spacer()
        }
        .padding()
        .onChange(of: query) {
            do {
                if query.count > 3 {
                    results = try db?.search(query: query) ?? []
                } else {
                    results = []
                }
            } catch {
                print(error)
            }
        }
        .task {
            guard let path = Bundle.main.path(forResource: "hot100", ofType: "db") else {
                print("resource not found")
                return
            }
            do {
                self.db = try SQLiteDatabase.open(path: path)
                focused = true
            } catch {
                print(error)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
