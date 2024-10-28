import AppKit
import AppleMusicScripting
import DiscordGameSDK

struct App {
    private static let RATE_LIMIT_TIME_PER_UPDATE: Double = 20/5
    private static let TRACK_ELAPSED_TIME_ERROR_MARGIN: TimeInterval = 5
    
    private let discordClient: DiscordClient
    private let musicApp: AppleMusicApp
    private let artworkAPI: ITunesSearchAPI
    private var lastTrack: (TrackViewModel, Date)?
    
    init(discordClient: DiscordClient) {
        self.discordClient = discordClient
        self.musicApp = AppleMusicApp()
        self.artworkAPI = .init()
    }
    
    private func updatePresence(withTrack track: TrackViewModel, andAlbumArt albumArt: String?) async {
        do {
            let timestamps = track.timestamps(fromNow: { Date.now })
            try await discordClient.update(activity: .init(timestamp: .init(start: timestamps.start,
                                                                            end: timestamps.end),
                                                           assets: albumArt.map { .init(large: .init(image: $0)) },
                                                           details: track.trackName,
                                                           state: track.artistName))
        } catch {
            print("could not update presence: \(error)")
        }
    }
    
    private func getCurrentlyPlayingTrack() -> TrackViewModel? {
        guard let track = musicApp.currentTrack() else {
            return nil
        }
        
        return .init(trackName: track.name,
                     artistName: track.artistName,
                     albumName: track.albumName,
                     completionPercentage: track.completionPercentage,
                     duration: track.duration)
    }
    
    private func shouldUpdate(withNewTrack newTrack: TrackViewModel, on date: Date) -> Bool {
        guard let (lastTrack, lastTrackDate) = lastTrack else {
            return true
        }
        
        return lastTrack.trackName != newTrack.trackName
        || lastTrack.artistName != newTrack.artistName
        || abs(lastTrack.timestamps(fromNow: { lastTrackDate }).end
            .distance(to: newTrack.timestamps(fromNow: { date }).end)) > Self.TRACK_ELAPSED_TIME_ERROR_MARGIN
    }
    
    mutating func run() async {
        while (true) {
            let now = Date.now
            if let track = getCurrentlyPlayingTrack(),
               shouldUpdate(withNewTrack: track, on: now) != false {
                var albumArt: String?
                do {
                    albumArt = try await artworkAPI.fetch(albumArtFor: track.trackName,
                                                          artistName: track.artistName,
                                                          albumName: track.albumName)
                } catch {
                    print("Error fetching artwork: \(error)")
                }
                print("updating with \(track.trackName) - \(track.artistName), \(albumArt ?? "nil")")
                await updatePresence(withTrack: track, andAlbumArt: albumArt)
                lastTrack = (track, now)
            }
            
            try! await Task.sleep(for: .seconds(Self.RATE_LIMIT_TIME_PER_UPDATE))
        }
    }
}
