#import <Foundation/Foundation.h>

@interface AppleMusicMusicTrack : NSObject
@property (readonly, strong, nullable) NSImage* image;
@property (readonly, strong, nonnull) NSString* name;
@property (readonly, strong, nonnull) NSString* artistName;
@property (readonly, strong, nonnull) NSString* albumName;
@property (readonly) double duration;
@property (readonly) double completionPercentage;

- (nullable instancetype)initWithName:(nonnull NSString*) name
                        andArtistName:(nonnull NSString*) artistName
                         andAlbumName:(nonnull NSString*) albumName
                          andDuration:(double) duration
              andCompletionPercentage:(double) completionPercentage
                             andImage:(nullable NSImage*) image;
@end

@interface AppleMusicApp : NSObject
- (nullable AppleMusicMusicTrack *) currentTrack;
@end
