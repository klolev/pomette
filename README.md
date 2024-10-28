# Pomette - _Display your Apple Music status on Discord for macOS_
Pomette is a background app that shows your currently playing Apple Music song in your Discord status, like how Spotify does it.

![image](https://github.com/user-attachments/assets/c6d99cdb-aa6e-4407-bbfc-3b924a708b5e)

## Build instructions
1. The Discord Game SDK isn't included here because it's unclear whether or not it's open-source, which means you'll have to [download it](https://dl-game-sdk.discordapp.net/3.2.1/discord_game_sdk.zip) and place it in `PROJECT_ROOT/Pomette/DiscordGameSDK/Sources/DiscordGameSDKC/discord_game_sdk.xcframework/macos-arm64/discord_game_sdk.dylib`
2. Build the project using Xcode>=16.1 `xcodebuild clean install -scheme Pomette -destination "YOUR DESTINATION"`
3. `install_name_tool -change @rpath/discord_game_sdk.dylib @executable_path/Frameworks/discord_game_sdk.dylib $BUILD_PATH/Pomette`
4. Run with DISCORD_APPLICATION_ID set in your environment to the ID of your Discord app

