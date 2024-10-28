import Foundation

@main
struct Main {
    static func main() async throws {
        let applicationID = Int64(ProcessInfo.processInfo.environment["DISCORD_APPLICATION_ID"]!)
        var app = try App(discordClient: .init(applicationID: applicationID!))
        await app.run()
    }
}
