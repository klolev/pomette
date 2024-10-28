import Foundation

struct ITunesSearchAPI {
    fileprivate struct Response: Codable {
        struct Result: Codable {
            let artistName: String
            let trackName: String
            let collectionName: String?
            let artworkUrl100: URL
        }
        
        let resultCount: Int
        let results: [Result]
    }
    
    func fetch(albumArtFor trackName: String, artistName: String, albumName: String) async throws -> String? {
        guard let encodedTrackName = trackName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedArtistName = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?entity=musicTrack&term=\(encodedTrackName)+\(encodedArtistName)") else {
            return nil
        }
        
        let urlResponse = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(Response.self, from: urlResponse.0)
        
        return (response.results
            .first(where: { $0.artistName == artistName
                && $0.trackName == trackName
                && $0.collectionName == albumName })?
            .artworkUrl100
            .deletingLastPathComponent()
            .pathComponents
            .dropFirst(3)
            .joined(separator: "/"))
        .map { "https://a5.mzstatic.com/us/r1000/0/" + $0 }
    }
}
