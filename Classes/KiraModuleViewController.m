//
//  KiraDeviceViewController.m
//  Kira
//
//  Created by Andy Sawyer on 20/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KiraModuleViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>

#import <arpa/inet.h>
//#import <sys/ioctl.h>
//#import <net/if.h>
//#import <netdb.h>


@implementation KiraModuleViewController
@synthesize device;

enum {
    kSectionCommands,
    kSectionDeviceInfo,
    kNumberOfSections
};

#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

+ (id)viewControllerForModule:(KiraModule *)device
{
    KiraModuleViewController *controller = [[KiraModuleViewController alloc] initWithStyle:UITableViewStyleGrouped];
    controller.device = device;
    [controller autorelease];
    return controller;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.title = device.address;
    _socket = [[AsyncUdpSocket alloc] initIPv4]; /* The devices don't (AFAIK!) support IPv6... */
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark -
#pragma mark Device messages
- (void)sendCmd:(const void *)cmd length:(int)length
{
    // We're just doing fire & forget here... not listening for ACK at all.
    // the device behaviour seems quite odd - it can recieve a command *from* any port (which is good),
    // but only sends ACK out if MY socket is bound to the same port number...
    [_socket sendData:[NSData dataWithBytes:cmd length:length]
               toHost:device.address
                 port:[device.port intValue]
          withTimeout:-1
                  tag:0];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return kNumberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case kSectionCommands:
            return device.bindings.count;
            break;
        case kSectionDeviceInfo:
            return device.discover.count;
            break;
        default:
            NSAssert(0,@"Invalid section index");
            break;
    }
    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    switch (indexPath.section) {
        case kSectionDeviceInfo:
            cell.textLabel.text = [device.discover objectAtIndex:indexPath.row];
            break;
        case kSectionCommands:
        {
            // This is a bit rubbish...
            NSString *key = [NSString stringWithFormat:@"%02X",indexPath.row+1];
            NSString *bind = [device.bindings objectForKey:key];
            cell.textLabel.text = bind;
        }
            break;
        default:
            NSAssert(0,@"Invalid Table Section");
            cell.textLabel.text = [NSString stringWithFormat:@"INVALID TABLE SECTION %@",indexPath];
            break;
    }
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
    */
    if (indexPath.section==kSectionCommands) {
        char buf[10];
        snprintf(buf,sizeof(buf),"cmdT%03d",indexPath.row+1);
        NSAssert(strlen(buf)==7,@"Command length error");
        [self sendCmd:buf length:7];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [_socket release];
    [device release];
    [super dealloc];
}


@end

