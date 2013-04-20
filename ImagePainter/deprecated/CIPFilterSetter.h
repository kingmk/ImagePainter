//
//  CIPFilterSetter.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-30.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CIPFilterSetter : UIControl
@property (nonatomic) NSString *filterName;
@property (nonatomic, retain) NSMutableDictionary *params;

- (void)reloadFilterControl:(NSString*)filterName withAttrs:(NSDictionary*) filterAttrs;


- (CGFloat)getHeight;

@end
