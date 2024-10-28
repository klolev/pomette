#include "AppleMusicScripting.h"
#include "AppleMusicScripting-Private.h"

@implementation AppleMusicMusicTrack
- (instancetype)initWithName:(NSString *)name
               andArtistName:(NSString *)artistName
                andAlbumName:(NSString *)albumName
                 andDuration:(double)duration
     andCompletionPercentage:(double)completionPercentage
                    andImage:(nullable NSImage *)image
{
    self = [super init];
    if (self) {
        self->_name = name;
        self->_artistName = artistName;
        self->_albumName = albumName;
        self->_duration = duration;
        self->_completionPercentage = completionPercentage;
        self->_image = image;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithName:@"" andArtistName:@"" andAlbumName:@"" andDuration:0 andCompletionPercentage:0 andImage:nil];
}
@end

@implementation AppleMusicApp {
    MusicApplication *application;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        application = [SBApplication applicationWithBundleIdentifier:@"com.apple.Music"];
    }
    return self;
}

- (AppleMusicMusicTrack *)currentTrack
{
    if (!application) {
        return nil;
    }
    
    MusicTrack* track = [application currentTrack];
    AppleMusicMusicTrack* result;
    if (track && track.name) {
        MusicArtwork* artwork = track.artworks.firstObject;
        
        result = [[AppleMusicMusicTrack alloc] initWithName:track.name
                                              andArtistName:track.artist
                                               andAlbumName:track.album
                                                andDuration:track.duration
                                    andCompletionPercentage:([application playerPosition] / track.duration)
                                                   andImage:artwork ? artwork.data : nil];
    }
    
    return result;
}
@end
