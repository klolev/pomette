import Foundation
import Combine
@_implementationOnly import discord_game_sdk

@MainActor
public struct DiscordClient {
    private var cancellables: Set<AnyCancellable> = []
    private var core: UnsafeMutablePointer<IDiscordCore>?
    private var events: IDiscordCoreEvents?
    
    public struct Activity: Sendable {
        public struct Timestamp: Sendable {
            public let start: Date
            public let end: Date?
            
            public init(start: Date, end: Date?) {
                self.start = start
                self.end = end
            }
        }
        
        public struct Assets: Sendable {
            public struct Asset: Sendable {
                public let text: String
                public let image: String
                
                public init(text: String = "", image: String) {
                    self.text = text
                    self.image = image
                }
            }
            
            public let largeAsset: Asset?
            public let smallAsset: Asset?

            public init(large: Asset? = nil, small: Asset? = nil) {
                self.largeAsset = large
                self.smallAsset = small
            }
        }
        
        public struct Party: Sendable {
            public let id: String
            public let size: (count: Int32, max: Int32)
            
            public init(id: String, size: (count: Int32, max: Int32)) {
                self.id = id
                self.size = size
            }
        }
        
        public let timestamp: Timestamp?
        public let assets: Assets?
        public let details: String
        public let state: String
        public let joinSecret: String
        public let party: Party?

        public init(timestamp: Timestamp? = nil,
                    assets: Assets? = nil,
                    details: String = "",
                    state: String = "",
                    joinSecret: String = "",
                    party: Party? = nil) {
            self.timestamp = timestamp
            self.assets = assets
            self.details = details
            self.state = state
            self.joinSecret = joinSecret
            self.party = party
        }
    }
    
    public enum Error: Swift.Error {
        case coreInvalidated
        case discordError(UInt32)
        case unknownError(Swift.Error)
    }
    
    public init(applicationID: Int64) throws (Error) {
        var core: UnsafeMutablePointer<IDiscordCore>?
        
        do {
            var params = DiscordCreateParams()
            DiscordCreateParamsSetDefault(&params)
            params.client_id = applicationID
            params.flags = UInt64(DiscordCreateFlags_Default.rawValue)
            
            let result = DiscordCreate(DISCORD_VERSION, &params, &core)
            guard result.rawValue == 0, let core else {
                throw Error.discordError(result.rawValue)
            }
            
            self.core = core
            
            Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink(receiveValue: update(on:))
                .store(in: &cancellables)
        } catch {
            throw error.asDiscordError
        }
    }
    
    @MainActor
    private func update(on date: Date) {
        guard let core,
              let runCallbacks = core.pointee.run_callbacks else {
            print(Error.coreInvalidated)
            return
        }
        
        let result = runCallbacks(core)
        if result.rawValue != 0 {
            print(Error.discordError(result.rawValue))
            return
        }
    }
    
    @MainActor
    public func update(activity: Activity) async throws (Error) {
        guard let core,
              let manager = core.pointee.get_activity_manager(core),
              let updateActivity = manager.pointee.update_activity else {
            throw .coreInvalidated
        }
        
        var discordActivity = activity.asDiscordActivity
        return try await attempt { updateActivity(manager, &discordActivity, $0, $1) }
    }
    
    @MainActor
    public func clearActivity() async throws (Error) {
        guard let core,
              let manager = core.pointee.get_activity_manager(core),
              let clearActivity = manager.pointee.clear_activity else {
            throw .coreInvalidated
        }
        
        return try await attempt { clearActivity(manager, $0, $1) }
    }
    
    @MainActor
    private func attempt(
        _ function: (
            UnsafeMutablePointer<CheckedContinuation<(), Swift.Error>>,
            (@convention(c) (UnsafeMutableRawPointer?, EDiscordResult) -> Void)?
        ) -> Void
    ) async throws (Error) -> Void {
        do {
            var currentContinuation: CheckedContinuation<(), Swift.Error>!
            defer { currentContinuation = nil }
            return try await withCheckedThrowingContinuation { continuation in
                currentContinuation = continuation
                function(&currentContinuation) { continuation, result in
                    guard let continuation = continuation?.load(as: CheckedContinuation<(), Error>.self) else {
                        return
                    }
                    if result.rawValue != 0 {
                        continuation.resume(throwing: Error.discordError(result.rawValue))
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            throw error.asDiscordError
        }
    }
}

fileprivate extension Error {
    var asDiscordError: DiscordClient.Error {
        if let error = self as? DiscordClient.Error {
            error
        } else {
            .unknownError(self)
        }
    }
}

extension DiscordClient.Activity {
    var asDiscordActivity: DiscordActivity {
        var activity = DiscordActivity()
        
        if let timestamp {
            activity.timestamps.start = Int64(timestamp.start.timeIntervalSince1970)
            activity.timestamps.end = (timestamp.end?.timeIntervalSince1970).map { Int64($0) } ?? 0
        }
        
        if let assets {
            var discordAssets = DiscordActivityAssets()
            if let asset = assets.largeAsset {
                if !asset.image.isEmpty {
                    write(string: asset.image, to: &discordAssets.large_image)
                }
                
                if !asset.text.isEmpty {
                    write(string: asset.text, to: &discordAssets.large_text)
                }
            }
            
            if let asset = assets.smallAsset {
                if !asset.image.isEmpty {
                    write(string: asset.image, to: &discordAssets.small_image)
                }
                
                if !asset.text.isEmpty {
                    write(string: asset.text, to: &discordAssets.small_text)
                }
            }
            
            activity.assets = discordAssets
        }
        
        if let party {
            var activityParty = DiscordActivityParty()
            write(string: party.id, to: &activityParty.id)
            activityParty.size.current_size = party.size.count
            activityParty.size.max_size = party.size.max
            
            activity.party = activityParty
        }
        
        if !joinSecret.isEmpty {
            var secrets = DiscordActivitySecrets()
            write(string: joinSecret, to: &secrets.join)
            activity.secrets = secrets
        }
        
        if !details.isEmpty {
            write(string: details, to: &activity.details)
        }
        
        if !state.isEmpty {
            write(string: state, to: &activity.state)
        }
        
        return activity
    }
}

private func write<T>(string: String, to destination: inout T) {
    _ = withUnsafeMutableBytes(of: &destination) { destination in
        string.utf8CString.withUnsafeBufferPointer { source in
            memcpy(destination.baseAddress, source.baseAddress, min(destination.count, source.count))
        }
    }
}
