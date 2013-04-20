//
//  CIPLayerOper.h
//  ImagePainter
//
//  Created by yuxinjin on 12-10-4.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CIPLayerOper : UIControl
@property (nonatomic) NSUInteger itemHeight;
@property (nonatomic) NSUInteger operTag;

- (BOOL) addOperatorItem:(NSString*)title withTag:(NSUInteger)tag;

@end
