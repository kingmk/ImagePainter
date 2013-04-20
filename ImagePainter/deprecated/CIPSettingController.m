//
//  CIPSettingController.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-28.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPSettingController.h"

@interface CIPSettingController ()

@end

@implementation CIPSettingController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateViewWithPalette:(CIPPalette *)palette withSubType:(ProcSubType) subType{
    self.palette = palette;
    self.subType = subType;
}



- (IBAction)clickPreview:(CIPDrawView*)sender {
    ProcSubType subType = sender.type;
    [self setSubType:subType];
}
@end
