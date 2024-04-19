import SwiftUI

struct ChartView: View {
    @Environment(Hot100.self) private var db
    @State private var tracks: [Track] = []
    var week: String
    var body: some View {
        List(tracks) { track in
            NavigationLink(destination: TrackView(track: track)) {
                Text("\(track.peak). \(track.artist) - \(track.song)")
            }
        }
        .navigationTitle(week)
        .task {
            do {
                tracks = try db.chart(week: week)
            } catch {
                tracks = []
            }
        }
    }
}

struct TrackView: View {
    @Environment(Hot100.self) private var db
    @State private var entries: [Entry] = []
    var track: Track
    var body: some View {
        List(entries) { entry in
            NavigationLink(destination: ChartView(week: entry.week)) {
                Text("\(entry.week) - \(entry.position) \(entry.position == track.peak ? "*" : "")")
            }
        }
        .navigationTitle("\(track.artist) - \(track.song)")
        .task {
            do {
                entries = try db.entries(performer: track.artist, title: track.song)
            } catch {
                entries = []
            }
        }
    }
}

struct SearchView: View {
    @Environment(Hot100.self) var db
    @State var results: [Track] = []
    @State var query: String = ""
    @FocusState var focused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Artist", text: $query)
                    .focused($focused)
                    .padding(.horizontal)
                List(results) { result in
                    NavigationLink(destination: TrackView(track: result)) {
                        Text("\(result.artist) - \(result.song) (\(result.peak))")
                    }
                }
                Spacer()
            }
        }
        .onChange(of: query) {
            do {
                if query.count > 3 {
                    results = try db.search(query: query)
                } else {
                    results = []
                }
            } catch {
                results = []
            }
        }
        .onAppear {
            focused = true
        }
    }
}
