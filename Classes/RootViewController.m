//
//  RootViewController.m
//  Kira
//
//  Created by Andy Sawyer on 13/06/2011.
//  Copyright 2011 Andy Sawyer. All rights reserved.
//

#import "RootViewController.h"
#import "KiraModule.h"
#import "KiraModuleViewController.h"

@interface UITableView (UpdateHelper)
- (void)reloadRow:(int)row inSection:(int)section;
- (void)insertRow:(int)row inSection:(int)section;
@end

@implementation UITableView (UpdateHelper)
- (void)reloadRow:(int)row inSection:(int)section
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:section];
    [self reloadRowsAtIndexPaths:[NSArray arrayWithObject:path]
                withRowAnimation:UITableViewRowAnimationFade];
}

- (void)insertRow:(int)row inSection:(int)section
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:section];
    [self insertRowsAtIndexPaths:[NSArray arrayWithObject:path]
                withRowAnimation:UITableViewRowAnimationFade];
}

@end




@implementation RootViewController

- (void)sendPacket:(const void *)bytes length:(int)length to:(NSString *)address port:(int)port
{
    if( !address )
        address = @"255.255.255.255";
    NSData *packet = [NSData dataWithBytes:bytes length:length];
    [_udpSocket sendData:packet
                  toHost:address
                    port:port
             withTimeout:10.0
                     tag:0];
}


- (void)onCmdRefresh
{
    [self sendPacket:"disD" length:4 to:nil port:30303];
    /*
    NSData *packet = [NSData dataWithBytes:"disD" length:4];
    [_udpSocket sendData:packet
                  toHost:@"255.255.255.255"
                    port:30303
             withTimeout:10.0
                     tag:0];
     */
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.title = @"Modules";

    _modules = [NSMutableArray new];
    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                             target:self
                                                                             action:@selector(onCmdRefresh)];
    self.navigationItem.leftBarButtonItem = refresh;
    [refresh release];

    _udpSocket = [[AsyncUdpSocket alloc] initIPv4];
    [_udpSocket setDelegate:self];
    NSError *err = NULL;
    [_udpSocket bindToPort:30303 error:&err];
    [_udpSocket enableBroadcast:TRUE error:&err];
    [_udpSocket receiveWithTimeout:-1 tag:0];
    [self onCmdRefresh];
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
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int n = _modules.count;
    return n;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    // Configure the cell.
    int n = _modules.count;
    KiraModule *module = [_modules objectAtIndex:indexPath.row];
    cell.textLabel.text = module.name;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@:%@ (%d)",module.address,module.port,module.bindings.count];
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


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
    if( _modules.count > 0 ) {
        KiraModule *module = [_modules objectAtIndex:indexPath.row];
        KiraModuleViewController *controller = [KiraModuleViewController viewControllerForModule:module];
        [self.navigationController pushViewController:controller animated:YES];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [_udpSocket release];
    [_modules release];
    [super dealloc];
}



#pragma mark -
#pragma mark Handle various socket messages
- (int)findModuleIndex:(NSString *)host
{
    for (int i = 0; i < _modules.count; ++i) {
        KiraModule *module = [_modules objectAtIndex:i];
        if ([module.address isEqualToString:host]) {
            return i;
        }
    }
    return -1;
}

- (void)onHost:(NSString *)host discovery:(NSArray *)strings
{
    // host probably == objectAtIndex:1
    KiraModule *module = [[KiraModule alloc] initWithDiscovery:strings];
    int i = [self findModuleIndex:host];
    if (i < 0) {
        [_modules addObject:module];
        [self.tableView insertRow:_modules.count-1 inSection:0];
    } else {
        [_modules replaceObjectAtIndex:i withObject:module];
        [self.tableView reloadRow:i inSection:0];
    }
    [module release];
    /*
    [_udpSocket sendData:[NSData dataWithBytes:"disN" length:4]
                  toHost:host
                    port:30303
             withTimeout:10.0
                     tag:1];
     */
    [self sendPacket:"disN" length:4 to:host port:30303];
}


- (void)onHost:(NSString *)host binding:(NSString *)binding
{
    // Command binding for host.
    NSLog(@"Command [%@]:[%@]",host,binding);
    int i = [self findModuleIndex:host];
    if (i < 0) {
        NSLog(@"Unknown host %@",host);
        return;
    }
    KiraModule *module = [_modules objectAtIndex:i];
    [module addBinding:binding];
    [self.tableView reloadRow:i inSection:0];
}

#pragma mark -
#pragma mark AsyncUdpSocketDelegate


- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    // This is interesting. Maybe...
}


/**
 * Called when the socket has received the requested datagram.
 *
 * Due to the nature of UDP, you may occasionally receive undesired packets.
 * These may be rogue UDP packets from unknown hosts,
 * or they may be delayed packets arriving after retransmissions have already occurred.
 * It's important these packets are properly ignored, while not interfering with the flow of your implementation.
 * As an aid, this delegate method has a boolean return value.
 * If you ever need to ignore a received packet, simply return NO,
 * and AsyncUdpSocket will continue as if the packet never arrived.
 * That is, the original receive request will still be queued, and will still timeout as usual if a timeout was set.
 * For example, say you requested to receive data, and you set a timeout of 500 milliseconds, using a tag of 15.
 * If rogue data arrives after 250 milliseconds, this delegate method would be invoked, and you could simply return NO.
 * If the expected data then arrives within the next 250 milliseconds,
 * this delegate method will be invoked, with a tag of 15, just as if the rogue data never appeared.
 *
 * Under normal circumstances, you simply return YES from this method.
 **/
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    if (data.length<=4) {
        return NO;
    }
    NSString *info = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
    if ([info isEqualToString:@"disD"]) {
        // Probably our own discover packet...
        return NO;
    }
    if ([info isEqualToString:@"disN"]) {
        // Our own enquire
        return NO;
    }

    NSArray *strings = [info componentsSeparatedByString:@"\r\n"];
    NSString *header = [strings objectAtIndex:0];

    if ([@"disR" isEqualToString:header]) {
        // It's a response, but not the one we care about...
        return NO;
    }

    int count = [strings count];
    if (count==2) {
        [self onHost:host binding:header];
        return NO;
    }
    if (count>3) {
        [self onHost:host discovery:strings];
        return NO;
    }
    // WTF?
    NSLog(@"WTF?");
    return NO;
}
@end

