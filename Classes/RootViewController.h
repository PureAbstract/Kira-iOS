//
//  RootViewController.h
//  Kira
//
//  Created by Andy Sawyer on 13/06/2011.
//  Copyright 2011 Andy Sawyer. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "AsyncUdpSocket.h"
#import "UdpSocket.h"
@interface RootViewController : UITableViewController <UdpSocketTxDelegate, UdpSocketRxDelegate> {
    //AsyncUdpSocket *_udpSocket;
    UdpSocket *_socket;
    NSMutableArray *_modules;
}

@end
