
#import <Foundation/Foundation.h>

@class UdpSocket;

@protocol UdpSocketRxDelegate <NSObject>
-(void)udpSocket:(UdpSocket *)socket rxError:(int)error;
-(void)udpSocketRxData:(UdpSocket *)socket;
@end

@protocol UdpSocketTxDelegate <NSObject>
-(void)udpSocket:(UdpSocket *)socket txError:(int)error;
-(void)udpSocketTxData:(UdpSocket *)socket;
@end

@interface UdpSocketPacket : NSObject {
    NSData *data_;
    NSData *address_;
    NSData *tag_;
}
@property (nonatomic,readonly) NSData *data;
@property (nonatomic,readonly) NSData *address;
@property (nonatomic,readonly) NSData *tag;
@end

@interface UdpSocket : NSObject {
    CFSocketRef socket_;
    CFSocketContext context_;
    CFRunLoopSourceRef sourceRef_;
    CFRunLoopRef runLoop_;
    NSMutableArray *recvBuf_;
    NSMutableArray *sendBuf_;
    id<UdpSocketTxDelegate> txDelegate_;
    id<UdpSocketRxDelegate> rxDelegate_;
}
@property (nonatomic,assign) id<UdpSocketTxDelegate> txDelegate;
@property (nonatomic,assign) id<UdpSocketRxDelegate> rxDelegate;
-(BOOL)enableBroadcast;
-(BOOL)bindToHost:(NSString *)host port:(UInt16)port;
-(BOOL)bindToPort:(UInt16)port;
-(void)close;

-(BOOL)send:(NSData *)data host:(NSString *)host port:(UInt16)port tag:(NSObject *)tag;

-(NSUInteger)rxQueueCount;
-(UdpSocketPacket *)peekRxQueue;
-(UdpSocketPacket *)popRxQueue;

+(NSString *)hostname:(NSData *)address;
@end
