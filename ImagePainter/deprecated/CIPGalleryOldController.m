//
//  CIPFileLoadController.m
//  ImagePainter
//
//  Created by yuxinjin on 12-10-14.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPGalleryOldController.h"

extern NSString *const CIPFileAttributeName;

@interface CIPGalleryOldController ()
@property (nonatomic, retain) NSMutableArray *fileList;
@property (weak, nonatomic) IBOutlet UITableView *fileTableView;
@property (nonatomic, retain) UITextField *titleEdit;
@property (nonatomic) NSInteger rowEdit;


@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@end

@implementation CIPGalleryOldController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Load From File";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.fileList = [NSMutableArray arrayWithArray:[[CIPFileUtilities defaultFileUtils] getLayerDataList]];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonSystemItemEdit target:self action:@selector(edit:)];
    if (self.fileList.count == 0) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    self.rowEdit = -1;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setFileTableView:nil];
    [super viewDidUnload];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fileList.count;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55.0f;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *kCellIdentifier = @"cellID";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCellIdentifier];
        
		cell.accessoryType = UITableViewCellAccessoryNone;
        
        cell.textLabel.backgroundColor = [UIColor clearColor];
		cell.textLabel.opaque = NO;
		cell.textLabel.textColor = [UIColor blackColor];
		cell.textLabel.highlightedTextColor = [UIColor whiteColor];
		cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
		
		cell.detailTextLabel.backgroundColor = [UIColor clearColor];
		cell.detailTextLabel.opaque = NO;
		cell.detailTextLabel.textColor = [UIColor grayColor];
		cell.detailTextLabel.highlightedTextColor = [UIColor whiteColor];
		cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        
        UIView *selectedBackView = [[UIView alloc] initWithFrame:cell.frame];
        selectedBackView.backgroundColor = [UIColor lightGrayColor];
        cell.selectedBackgroundView = selectedBackView;
    }
    
    NSDictionary *dataDictionary = [self.fileList objectAtIndex:indexPath.row];
    NSString *fileName = [dataDictionary valueForKey:CIPFileAttributeName];
    cell.textLabel.text = fileName;
    NSDate *modTime = [dataDictionary valueForKey:NSFileModificationDate];
    cell.detailTextLabel.text = [CIPUtilities displayDate:modTime];
    UIImage *thumb = [[CIPFileUtilities defaultFileUtils] loadThumbFrom:fileName];
    cell.imageView.image = thumb;
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell =[tableView cellForRowAtIndexPath:indexPath];
    if (![self.fileTableView isEditing]) {
        NSString *fileName = cell.textLabel.text;
        self.activityIndicator = [CIPUtilities initActivityIndicator:self.navigationController.view];
        [self.activityIndicator startAnimating];
        NSThread *t = [[NSThread alloc] initWithTarget:self selector:@selector(loadLayers:) object:fileName];
        [t start];
    } else {
        if (self.rowEdit != -1) {
            [self rename];
        }
        CGRect frame = cell.textLabel.frame;
        [self.titleEdit removeFromSuperview];
        self.titleEdit = [[UITextField alloc] initWithFrame:CGRectMake(frame.origin.x+35, frame.origin.y, frame.size.width+10, frame.size.height)];
        self.titleEdit.delegate = self;
        self.titleEdit.text = [cell.textLabel.text substringToIndex:cell.textLabel.text.length-[@".layers" length]];
        self.titleEdit.font = cell.textLabel.font;
        self.titleEdit.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        cell.textLabel.text = @"";
        self.rowEdit = indexPath.row;
        [cell addSubview:self.titleEdit];
        [self.titleEdit becomeFirstResponder];
    }
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *dataDictionary = [self.fileList objectAtIndex:indexPath.row];
        NSString *fileName = [dataDictionary valueForKey:CIPFileAttributeName];
        if([[CIPFileUtilities defaultFileUtils] removeLayerDataFile:fileName]) {
            [self.fileList removeObjectAtIndex:indexPath.row];
        }

        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        if (self.fileList.count == 0) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonSystemItemEdit target:self action:@selector(edit:)];
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self rename];
    return YES;
}

- (void) loadLayers:(NSString*)loadName {
    NSArray *layers = [[CIPFileUtilities defaultFileUtils] loadLayersFrom:loadName];
    [self.delegate cipGallery:self didLoad:layers withName:[loadName substringToIndex:loadName.length-[@".layers" length]]];
    [self.activityIndicator stopAnimating];
    [self.activityIndicator removeFromSuperview];
}

- (void) rename {
    UITableViewCell *cell = [self.fileTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.rowEdit inSection:0]];
    NSString *newName = self.titleEdit.text;
    NSString *orgName = [self getNameFor:self.rowEdit];
    if (newName.length == 0) {
        newName = [self getNameFor:self.rowEdit];
    } else {
        newName = [NSString stringWithFormat:@"%@.layers", newName];
        if ([newName isEqualToString:orgName]) {
            
        } else if ([[CIPFileUtilities defaultFileUtils] renameLayerDataFile:orgName toName:newName]) {
            NSMutableDictionary *dataDictionary = [self.fileList objectAtIndex:self.rowEdit];
            [dataDictionary setValue:newName forKey:CIPFileAttributeName];
        } else {
            newName = orgName;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Rename" message:@"The new name conflicts with the name of existing file." delegate:self cancelButtonTitle:@"OK, I know." otherButtonTitles: nil];
            [alert show];
        }
    }
    
    cell.textLabel.text = newName;
    self.rowEdit = -1;
    [self.titleEdit removeFromSuperview];
}

- (NSString*) getNameFor:(NSInteger)row {
    NSMutableDictionary *dataDictionary = [self.fileList objectAtIndex:row];
    NSString *name = [dataDictionary valueForKey:CIPFileAttributeName];
    return name;
}

- (IBAction)edit:(UIBarButtonItem*)sender {
    if (![self.fileTableView isEditing]) {
        [self.fileTableView setEditing:YES animated:YES];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonSystemItemDone target:self action:@selector(edit:)];
    } else {
        [self.fileTableView setEditing:NO animated:YES];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonSystemItemEdit target:self action:@selector(edit:)];
        if (self.fileList.count == 0) {
            self.navigationItem.rightBarButtonItem.enabled = NO;
        } else if (self.rowEdit != -1) {
            [self rename];
        }
    }
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    [self dismissModalViewControllerAnimated:YES];
}

@end
