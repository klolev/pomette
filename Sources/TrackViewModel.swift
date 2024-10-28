import Foundation

struct TrackViewModel {
    let trackName: String
    let artistName: String
    let albumName: String
    let completionPercentage: Double
    let duration: TimeInterval
    
    func timestamps(fromNow now: () -> Date) -> (start: Date, end: Date) {
        let now = now()
        let timeElapsed = duration * completionPercentage
        
        let start = now.addingTimeInterval(-timeElapsed)
        let end = start.addingTimeInterval(duration)
        
        return (start, end)
    }
}
