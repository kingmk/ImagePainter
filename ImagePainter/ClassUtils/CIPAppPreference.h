//
//  CIPAppPreference.h
//  ImagePainter
//
//  Created by yuxinjin on 12-11-1.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CIPAppPreference : NSObject
@property (nonatomic) NSUInteger canvasAutoId;
@property (nonatomic) BOOL zoomSwitch;

- (NSData*) convert2JSONData;
- (void) convertFromJSONData:(NSData*)jsData;
@end
