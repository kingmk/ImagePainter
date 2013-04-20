//
//  CIPFileUtilities.m
//  ImagePainter
//
//  Created by yuxinjin on 12-10-12.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//
NSString *const FILE_PREF_PALETTE = @"prefPalette.js";
NSString *const FILE_PREF_APPLICATION = @"prefApp.js";
NSString *const CIPFileAttributeName = @"CIPFileName";
NSString *const ALBUM_NAME = @"Processed";

#import "CIPFileUtilities.h"

@interface CIPFileUtilities()
@property(nonatomic) NSString *palettePath;
@property(nonatomic) NSString *appPrefPath;
@property(nonatomic) NSString *layerDataPath;
@property(nonatomic, retain) ALAssetsLibrary *library;
@end

@implementation CIPFileUtilities

static CIPFileUtilities *fUtils;

+ (CIPFileUtilities*) defaultFileUtils {
    if (!fUtils) {
        fUtils = [[CIPFileUtilities alloc] init];
    }
    
    return fUtils;
}

- (id) init {
    self = [super init];
    if (self) {
        NSString *prefPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
        prefPath = [prefPath stringByAppendingPathComponent:@"Preferences"];
        self.palettePath = [prefPath stringByAppendingPathComponent:FILE_PREF_PALETTE];
        self.appPrefPath = [prefPath stringByAppendingPathComponent:FILE_PREF_APPLICATION];
        
        NSString *docPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        self.layerDataPath = [docPath stringByAppendingPathComponent:@"layerData"];
        self.library = [[ALAssetsLibrary alloc] init];
    }
    return self;
}

- (void) savePalette:(CIPPalette*)palette{
    NSData *data = [palette convert2JSONData];
    [data writeToFile:self.palettePath atomically:YES];
}

- (CIPPalette*) loadPalette {
    CIPPalette *palette = [[CIPPalette alloc] init];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:self.palettePath]) {
        NSData *data = [NSData dataWithContentsOfFile:self.palettePath];
        [palette convertFromJSONData:data];
    }
    return palette;
}

- (void) saveAppPref:(CIPAppPreference*)appPref {
    NSData *data = [appPref convert2JSONData];
    [data writeToFile:self.appPrefPath atomically:YES];
}

- (CIPAppPreference*) loadAppPref {
    CIPAppPreference *appPref = [[CIPAppPreference alloc] init];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:self.appPrefPath]) {
        NSData *data = [NSData dataWithContentsOfFile:self.appPrefPath];
        [appPref convertFromJSONData:data];
    }
    return appPref;
}

- (NSArray*) getLayerDataList {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *filePathes = [fm contentsOfDirectoryAtPath:self.layerDataPath error:Nil];
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:filePathes.count];
    for (NSString *filePath in filePathes) {
        NSString *path = [self.layerDataPath stringByAppendingPathComponent:filePath];
        NSMutableDictionary *attr = [NSMutableDictionary dictionaryWithDictionary:[fm attributesOfItemAtPath:path error:Nil]];
        [attr setValue:filePath forKey:CIPFileAttributeName];
        [result addObject:attr];
    }
    return [result sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDate *d1 = [(NSMutableDictionary*)obj1 valueForKey:NSFileModificationDate];
        NSDate *d2 = [(NSMutableDictionary*)obj2 valueForKey:NSFileModificationDate];
        return [d2 compare:d1];
    }];
}

- (BOOL)existLayerDataFile:(NSString*)fileName {
    if (![fileName hasSuffix:@".layers"]) {
        fileName = [fileName stringByAppendingString:@".layers"];
    }
    NSString *dataFilePath = [self.layerDataPath stringByAppendingPathComponent:fileName];
    return [[NSFileManager defaultManager] fileExistsAtPath:dataFilePath];
}

- (void) saveLayers:(NSArray*)layers nameAs:(NSString*)saveName withThumb:(UIImage *)thumb{
    NSUInteger count = layers.count;
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:1<<24];
    NSUInteger thumbL = 0;
    if (thumb != Nil) {
        NSData *thumbData = UIImagePNGRepresentation(thumb);
        thumbL = thumbData.length;
        [data appendBytes:&thumbL length:sizeof(thumbL)];
        [data appendData:thumbData];
    } else {
        [data appendBytes:&thumbL length:sizeof(thumbL)];
    }
    
    [data appendBytes:&count length:sizeof(count)];

    for (CIPPaintLayer *layer in layers) {
        NSData *layerData = [layer convert2LayerData];
        NSUInteger layerL = layerData.length;
        [data appendBytes:&layerL length:sizeof(layerL)];
        [data appendData:layerData];
    }
    if (![saveName hasSuffix:@".layers"]) {
        saveName = [saveName stringByAppendingString:@".layers"];
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:self.layerDataPath]) {
        [fm createDirectoryAtPath:self.layerDataPath withIntermediateDirectories:YES attributes:Nil error:Nil];
    }
    
    NSString *dataFilePath = [self.layerDataPath stringByAppendingPathComponent:saveName];
    [fm createFileAtPath:dataFilePath contents:data attributes:Nil];
}

- (NSArray*) loadLayersFrom:(NSString *)loadName {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dataFilePath = [self.layerDataPath stringByAppendingPathComponent:loadName];
    if (![fm fileExistsAtPath:dataFilePath]) {
        return Nil;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:dataFilePath];
    NSUInteger thumbL;
    [data getBytes:&thumbL length:sizeof(thumbL)];
    
    NSUInteger count;
    NSUInteger l = sizeof(count);
    NSUInteger offset = sizeof(thumbL)+thumbL;
    [data getBytes:&count range:NSMakeRange(offset, l)];
    offset += l;
    
    NSMutableArray *layers = [[NSMutableArray alloc] initWithCapacity:count+1];
    for (int i=0; i<count; i++) {
        NSUInteger size;
        l = sizeof(size);
        [data getBytes:&size range:NSMakeRange(offset, l)];
        offset += l;
        
        l = size;
        CIPPaintLayer *layer = [CIPPaintLayer createLayerFromData:[data subdataWithRange:NSMakeRange(offset, l)]];
        offset += l;
        [layers addObject:layer];
    }
    
    return layers;
}

- (UIImage*)loadThumbFrom:(NSString *)loadName {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dataFilePath = [self.layerDataPath stringByAppendingPathComponent:loadName];
    if (![fm fileExistsAtPath:dataFilePath]) {
        return Nil;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:dataFilePath];
    NSUInteger thumbL;
    [data getBytes:&thumbL length:sizeof(thumbL)];
    NSData *thumbData = [data subdataWithRange:NSMakeRange(sizeof(thumbL), thumbL)];
    
    return [UIImage imageWithData:thumbData];
}

- (BOOL)renameLayerDataFile:(NSString*)name toName:(NSString*)rename {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dataFilePath = [self.layerDataPath stringByAppendingPathComponent:name];
    NSString *newDataFilePath = [self.layerDataPath stringByAppendingPathComponent:rename];
    
    if (![fm fileExistsAtPath:dataFilePath] || [fm fileExistsAtPath:newDataFilePath]) {
        return NO;
    }
    return [fm moveItemAtPath:dataFilePath toPath:newDataFilePath error:Nil];
}

- (BOOL) removeLayerDataFile:(NSString *)removeName {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dataFilePath = [self.layerDataPath stringByAppendingPathComponent:removeName];
    
    if (![fm fileExistsAtPath:dataFilePath]) {
        return NO;
    }
    return [fm removeItemAtPath:dataFilePath error:Nil];
}

- (void) saveImage:(UIImage *)image withCompletionBloc:(SaveImageCompletion)completionBlock{
    NSData *data = UIImagePNGRepresentation(image);
    image = [UIImage imageWithData:data];
    [self.library writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error != nil) {
            completionBlock(error);
            return;
        }
        [self addToAppAlbumWithAssetURL:assetURL withCompletionBlock:completionBlock];
    }];

}

- (void) addToAppAlbumWithAssetURL:(NSURL*)assetURL withCompletionBlock:(SaveImageCompletion) completionBlock {
    __block BOOL albumFound = NO;
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if ([ALBUM_NAME compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
            albumFound = YES;
            [self.library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                [group addAsset:asset];
                completionBlock(nil);
            } failureBlock:completionBlock];
        }
        
        if (group == nil && albumFound == NO) {
            __weak ALAssetsLibrary *weakLib = self.library;
            [self.library addAssetsGroupAlbumWithName:ALBUM_NAME resultBlock:^(ALAssetsGroup *group) {
                [weakLib assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                    [group addAsset:asset];
                    completionBlock(nil);
                } failureBlock:completionBlock];
            } failureBlock:completionBlock];
        }
    } failureBlock:completionBlock];
}
@end
