//
//  CIPTextControl.h
//  ImagePainter
//
//  Created by yuxinjin on 12-10-4.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CIPTextControlDelegate;

@interface CIPTextControl : UIControl<UITextViewDelegate>
@property (nonatomic) CIPPalette *palette;

@property (nonatomic) NSString *text;
@property (nonatomic, assign) id<CIPTextControlDelegate> delegate;

- (void) updateWithText:(NSString*)text palette:(CIPPalette*)palette status:(TextControlStatus)status;
- (void) updateColor:(UIColor*) color;
- (void) setFocus;
@end

@protocol CIPTextControlDelegate <NSObject>
- (void) cipTextControlDidEditing:(CIPTextControl*)textControl withStatus:(TextControlStatus) status;
- (void) cipTextControl:(CIPTextControl*)textControl callColorPick:(UIColor*)color;

@end