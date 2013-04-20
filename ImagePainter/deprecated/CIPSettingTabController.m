//
//  CIPSettingTabController.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-28.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPSettingTabController.h"

@interface CIPSettingTabController ()

@end

@implementation CIPSettingTabController
- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.stateMap = [NSMutableDictionary dictionaryWithCapacity:3];
        self.palette = Nil;//[[CIPPalette alloc] init];
    }
    return self;
}

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

- (ImageProcState) getSelectedState {
    ImageProcState state;
    switch (self.selectedIndex) {
        case 0:
            state = ProcPaint;
            break;
        case 1:
            state = ProcShape;
            break;
        case 2:
            state = ProcText;
            break;
        default:
            break;
    }
    return state;
}

- (ProcSubType) getMappedSubTypeFor:(ImageProcState)state {
    NSNumber *value = [self.stateMap objectForKey:[NSNumber numberWithInteger:state]];
    return [value integerValue];
}

- (void) setMapKey:(ImageProcState)state withValue:(ProcSubType)subType {
    [self.stateMap setObject:[NSNumber numberWithInteger:subType] forKey:[NSNumber numberWithInteger:state]];
    CIPSettingController *tabVC;
    int tabIdx = 0;
    switch (state) {
        case ProcPaint:
            tabIdx = 0;
            break;
        case ProcShape:
            tabIdx = 1;
            break;
        case ProcText:
            tabIdx = 2;
            break;
        default:
            break;
    }
    
    tabVC = (CIPSettingController*)[self.childViewControllers objectAtIndex:tabIdx];
    tabVC.subType = subType;
}

- (ImageProcState)getStateFromSubSetType:(ProcSubType)setType {
    ImageProcState state=ProcPaint;
    switch (setType) {
        case ProcSubSetPaint:
            state = ProcPaint;
            break;
        case ProcSubSetShape:
            state = ProcShape;
            break;
        case ProcSubSetText:
            state = ProcText;
            break;
        default:
            break;
    }
    return state;
}

- (ProcSubType)getMapedSubTypeForTabIdx:(NSUInteger) tabIndex {
    ProcSubType setType = ProcSetting + tabIndex +1;
    ImageProcState state = [self getStateFromSubSetType:setType];
    ProcSubType subType = [(NSNumber*)[self.stateMap objectForKey:[NSNumber numberWithInteger:state]] integerValue];
    return subType;
}

- (void)upMappedSubTypeFromTabIdx:(NSUInteger)tabIndex withSubType:(ProcSubType) subType{
    ProcSubType setType = ProcSetting + tabIndex +1;
    ImageProcState state = [self getStateFromSubSetType:setType];

    [self.stateMap setObject:[NSNumber numberWithInteger:subType] forKey:[NSNumber numberWithInteger:state]];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    CIPSettingController *subVC = (CIPSettingController*)[[self viewControllers] objectAtIndex:selectedIndex];
    [subVC setPalette:self.palette];
    subVC.subType = [self getMapedSubTypeForTabIdx:selectedIndex];
    [subVC updateViewWithPalette:self.palette withSubType:subVC.subType];
    [super setSelectedIndex:selectedIndex];
}

- (void) setSelectedViewController:(UIViewController *)selectedViewController{
    self.palette = [self getPaletteFromSelectedVC];
    ProcSubType subType = [self getSubTypeFromSelectedVC];
    [self upMappedSubTypeFromTabIdx:self.selectedIndex withSubType:subType];
    [super setSelectedViewController:selectedViewController];
    [(CIPSettingController*)selectedViewController updateViewWithPalette:self.palette withSubType:[self getSubTypeFromSelectedVC]];
}

- (CIPPalette*) getPaletteFromSelectedVC {
    CIPSettingController *subVC = (CIPSettingController*)self.selectedViewController; 
    return subVC.palette;
}

- (ProcSubType) getSubTypeFromSelectedVC {
    CIPSettingController *subVC = (CIPSettingController*)self.selectedViewController;
    return subVC.subType;
}

- (IBAction)goBack:(UIBarButtonItem *)sender {
    self.palette = [self getPaletteFromSelectedVC];
    ProcSubType subType = [self getSubTypeFromSelectedVC];
    [self upMappedSubTypeFromTabIdx:self.selectedIndex withSubType:subType];

    [[self delegate] tabBarController:self willEndCustomizingViewControllers:Nil changed:YES];
}

@end
