//
//  CIPFileUtilities.h
//  ImagePainter
//
//  Created by yuxinjin on 12-10-12.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^SaveImageCompletion)(NSError *error);

@interface CIPFileUtilities : NSObject
+ (CIPFileUtilities*) defaultFileUtils;

- (void) savePalette:(CIPPalette*)palette;
- (CIPPalette*) loadPalette;

- (void) saveAppPref:(CIPAppPreference*)appPref;
- (CIPAppPreference*) loadAppPref;

- (NSArray*)getLayerDataList;
- (BOOL)existLayerDataFile:(NSString*)fileName;
- (void) saveLayers:(NSArray*)layers nameAs:(NSString*)saveName withThumb:(UIImage*)thumb;
- (NSArray*)loadLayersFrom:(NSString*)loadName;
- (UIImage*)loadThumbFrom:(NSString*)loadName;

- (BOOL)renameLayerDataFile:(NSString*)name toName:(NSString*)rename;
- (BOOL)removeLayerDataFile:(NSString*)removeName;

- (void)saveImage:(UIImage*)image withCompletionBloc:(SaveImageCompletion)completionBlock;
@end
