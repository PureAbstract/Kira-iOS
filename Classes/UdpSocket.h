
#import <Foundation/Foundation.h>

@class UdpSocket;
@class UdpSocketPacket;

// FIXME: The errors should be more informative...
@protocol UdpSocketRxDelegate <NSObject>
-(void)udpSocket:(UdpSocket *)socket rxError:(int)error;
-(void)udpSocket:(UdpSocket *)socket receivedData:(UdpSocketPacket *)packet;
@end

@protocol UdpSocketTxDelegate <NSObject>
-(void)udpSocket:(UdpSocket *)socket txError:(int)error;
-(void)udpSocket:(UdpSocket *)socket sentDataWithTag:(NSObject *)tag;
@end


// Internal
@interface UdpSocketPacket : NSObject {
    NSData *data_;
    NSData *address_;
    NSObject *tag_;
}
@property (nonatomic,readonly) NSData *data;
@property (nonatomic,readonly) NSData *address;
@property (nonatomic,readonly) NSObject *tag;
@end

@interface UdpSocket : NSObject {
    CFSocketRef socket_;
    CFSocketContext context_;
    CFRunLoopSourceRef sourceRef_;
    CFRunLoopRef runLoop_;
    NSMutableArray *sendQueue_;
    NSMutableArray *recvQueue_;
    id<UdpSocketTxDelegate> txDelegate_;
    id<UdpSocketRxDelegate> rxDelegate_;
}
@property (nonatomic,assign) id<UdpSocketTxDelegate> txDelegate;
@property (nonatomic,assign) id<UdpSocketRxDelegate> rxDelegate;
#pragma mark -
#pragma mark The Designated Initialiser
-(id)init;

#pragma mark -
#pragma mark Socket configuration
-(BOOL)enableBroadcast;
-(BOOL)bindToHost:(NSString *)host port:(UInt16)port;
-(BOOL)bindToPort:(UInt16)port;

#pragma mark -
#pragma mark Close the socket
-(void)close;

#pragma mark -
#pragma mark Send Data
-(BOOL)send:(NSData *)data host:(NSString *)host port:(UInt16)port tag:(NSObject *)tag;

#pragma mark -
#pragma mark Utility Functions
// get a string reprsenting the hostname from an address blob
+(NSString *)hostname:(NSData *)address;
+(UInt16)port:(NSData *)address;
@end
