//
//  CIPAppPreference.m
//  ImagePainter
//
//  Created by yuxinjin on 12-11-1.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//


NSString *const JSKEY_CANVAS_AUTOID = @"canvasAutoId";
NSString *const JSKEY_ZOOM_SWITCH = @"zoomSwitch";

#import "CIPAppPreference.h"

@implementation CIPAppPreference

- (id) init {
    self = [super init];
    if (self) {
        self.canvasAutoId = 0;
        self.zoomSwitch = YES;
    }
    return self;
}

- (NSData*) convert2JSONData {
    NSMutableDictionary *jObj = [NSMutableDictionary dictionaryWithCapacity:1];
    [jObj setValue:[NSNumber numberWithUnsignedInteger:self.canvasAutoId] forKey:JSKEY_CANVAS_AUTOID];
    [jObj setValue:[NSNumber numberWithBool:self.zoomSwitch] forKey:JSKEY_ZOOM_SWITCH];
    return [NSJSONSerialization dataWithJSONObject:jObj options:NSJSONWritingPrettyPrinted error:Nil];
}

- (void) convertFromJSONData:(NSData *)jsData {
    NSDictionary *jObj = [NSJSONSerialization JSONObjectWithData:jsData options:NSJSONReadingAllowFragments error:Nil];
    self.canvasAutoId = [(NSNumber*)[jObj valueForKey:JSKEY_CANVAS_AUTOID] unsignedIntegerValue];
    self.zoomSwitch = [(NSNumber*)[jObj valueForKey:JSKEY_ZOOM_SWITCH] boolValue];
}
@end
