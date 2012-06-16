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
#import "UITableView+UpdateHelper.h"
#import "Logging.h"

@implementation RootViewController

- (void)sendPacket:(const void *)bytes length:(int)length to:(NSString *)address port:(int)port
{
    if( !address )
        address = @"255.255.255.255";
    NSData *packet = [NSData dataWithBytes:bytes length:length];
    [_socket send:packet
             host:address
             port:port
              tag:nil];
}


- (void)onCmdRefresh
{
    [self sendPacket:"disD" length:4 to:nil port:30303];
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

    _socket = [UdpSocket new];
    _socket.txDelegate = self;
    _socket.rxDelegate = self;
    [_socket bindToPort:30303];
    [_socket enableBroadcast];
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
    [_socket release];
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
    [self sendPacket:"disN" length:4 to:host port:30303];
}


- (void)onHost:(NSString *)host binding:(NSString *)binding
{
    // Command binding for host.
    [self log:@"Command [%@]:[%@]",host,binding];
    int i = [self findModuleIndex:host];
    if (i < 0) {
        [self log:@"Unknown host %@",host];
        return;
    }
    KiraModule *module = [_modules objectAtIndex:i];
    [module addBinding:binding];
    [self.tableView reloadRow:i
                    inSection:0
                withAnimation:UITableViewRowAnimationNone];
}

#pragma mark -
#pragma mark Handle Network packet
-(void)onRxData:(NSData *)data address:(NSData *)address
{
    if( data.length <= 4 ) {
        [self log:@"Rx : Too short %d",data.length];
        return;
    }
    NSString *info = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
    // Note: disD, disN are discarded by length <= 4
    // if( [@"disD" isEqualToString:info] ) {
    //     [self log:@"Ignore disD"];
    //     return;
    // }
    // if( [@"disN" isEqualToString:info] ) {
    //     [self log:@"Ignore disN"];
    //     return;
    // }
    NSArray *strings = [info componentsSeparatedByString:@"\r\n"];
    NSString *header = [strings objectAtIndex:0];
    if( [@"disR" isEqualToString:header] ) {
        [self log:@"Ignore disR"];
        return;
    }
    NSString *host = [UdpSocket hostname:address];
    int count = strings.count;
    if (count==2) {
        [self log:@"got binding : %@",strings];
        [self onHost:host binding:header];
        return;
    }
    if (count>3) {
        [self log:@"got host"];
        [self onHost:host discovery:strings];
        return;
    }
    // WTF?
    [self log:@"WTF?@"];
}


#pragma mark -
#pragma mark UdpSocketTxDelegate
-(void)udpSocket:(UdpSocket *)socket txError:(int)error
{
    [self log:@"udpsocket txError %d",error];
}

-(void)udpSocket:(UdpSocket *)socket sentDataWithTag:(NSObject *)tag
{
    // Nothing to see here...
}

#pragma mark -
#pragma mark UdpSocketRxDelegate
-(void)udpSocket:(UdpSocket *)socket rxError:(int)error
{
    [self log:@"udpsocket rxError %d",error];
}

-(void)udpSocket:(UdpSocket *)socket receivedData:(UdpSocketPacket *)packet
{
    if( packet ) {
        [self onRxData:packet.data address:packet.address];
    } else {
        [self log:@"udpSocketRxData: No data?"];
    }
}

@end

