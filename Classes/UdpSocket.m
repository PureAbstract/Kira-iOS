
#import "UdpSocket.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>
#import <arpa/inet.h>

//#import <sys/ioctl.h>
#import <net/if.h>



#import <CFNetwork/CFNetwork.h>


static NSData *getInAddr( in_addr_t address, UInt16 port ) {
    struct sockaddr_in addr;
    bzero( &addr, sizeof(addr) );
    addr.sin_len = sizeof(struct sockaddr_in);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = address;
    return [NSData dataWithBytes:&addr length:sizeof(addr)];
}

static NSData *getHostAddress( NSString *host, UInt16 port ) {

    if( !host || ( host.length == 0 ) ) {
        return getInAddr( INADDR_ANY, port );
    }

    if( [host isEqualToString:@"loopback"] || [host isEqualToString:@"localhost"] ) {
        return getInAddr( INADDR_LOOPBACK, port );
    }

    // Do a lookup...
    NSString *sPort = [NSString stringWithFormat:@"%hu",port];
    struct addrinfo hint;
    bzero( &hint, sizeof(hint) );
    hint.ai_family = AF_INET;
    // hint.ai_socktype = SOCK_DGRAM;
    // hint.ai_protocol = IPPROTO_UDP;
    struct addrinfo *results = 0;
    int error = getaddrinfo( [host UTF8String], [sPort UTF8String], &hint, &results );
    if( error ) {
        NSLog(@"getaddrinfo [%@:%@] failed: %d - %s",host,sPort,error,gai_strerror(error));
        return nil;
    }
    NSData *rv = nil;
    for( struct addrinfo *p = results ; p ; p = p->ai_next ) {
        if( p->ai_family == AF_INET ) {
            rv = [NSData dataWithBytes:p->ai_addr length:p->ai_addrlen];
            break;
        }
    }
    freeaddrinfo( results );
    if( !rv ) {
        NSLog(@"getHostAddress(%@,%@) - failed?",host,sPort);
    }

    return rv;
}

@implementation UdpSocketPacket
@synthesize data = data_;
@synthesize address = address_;
@synthesize tag = tag_;
-(id)initWithData:(NSData *)data address:(NSData *)address tag:(NSObject *)tag
{
    NSAssert( data, @"null data" );
    NSAssert( address, @"null address" );
    self = [super init];
    if( self ) {
        data_ = [data retain];
        address_ = [address retain];
        tag_ = [tag retain];
    }
    return self;
}

-(void)dealloc {
    [data_ release];
    [address_ release];
    [tag_ release];
    [super dealloc];
}
@end



@interface UdpSocket (internal)
-(void)doCallback:(CFSocketCallBackType)type
           socket:(CFSocketRef)socket
          address:(CFDataRef)address
             data:(const void *)data;
@end

@implementation UdpSocket
@synthesize txDelegate = txDelegate_;
@synthesize rxDelegate = rxDelegate_;

static void theCFSocketCallback( CFSocketRef socket,
                                 CFSocketCallBackType type,
                                 CFDataRef address,
                                 const void *pData,
                                 void *pInfo )
{
    UdpSocket *udp = (UdpSocket *)pInfo;
    [udp retain];
    [udp doCallback:type
             socket:socket
            address:address
               data:pData];
    [udp release];
}



-(void)dealloc {
    [self close];
    [recvBuf_ release];
    [sendBuf_ release];
    [super dealloc];
}

-(void)close
{
    if( sourceRef_ ) {
        CFRunLoopRemoveSource( runLoop_, sourceRef_, (CFStringRef)NSDefaultRunLoopMode );
        CFRelease( sourceRef_ );
        sourceRef_ = NULL;
    }
    if( socket_ ) {
        CFSocketInvalidate( socket_ );
        CFRelease( socket_ );
        socket_ = NULL;
    }
    [recvBuf_ removeAllObjects];
    [sendBuf_ removeAllObjects];
    runLoop_ = NULL;
}

-(id)init {
    self = [super init];
    if( self ) {
        bzero( &context_, sizeof( context_ ) );
        context_.version = 0;
        context_.info = self;
        context_.retain = nil;
        context_.release = nil;
        context_.copyDescription = nil;
        socket_ = CFSocketCreate( kCFAllocatorDefault,
                                  PF_INET,
                                  SOCK_DGRAM,
                                  IPPROTO_UDP,
                                  kCFSocketReadCallBack | kCFSocketWriteCallBack,
                                  theCFSocketCallback,
                                  &context_ );
        // This us supposed to stop us getting continuous callbacks
        //CFSocketSetSocketFlags( socket_, kCFSocketCloseOnInvalidate );
        runLoop_ = CFRunLoopGetCurrent();
        sourceRef_ = CFSocketCreateRunLoopSource( kCFAllocatorDefault, socket_, 0 );
        CFRunLoopAddSource( runLoop_, sourceRef_, (CFStringRef)NSDefaultRunLoopMode );
        recvBuf_ = [NSMutableArray new];
        sendBuf_ = [NSMutableArray new];
    }
    return self;
}

-(BOOL)bindToHost:(NSString *)host port:(UInt16)port
{
    NSData *addr = getHostAddress( host, port );
    if( !addr ) {
        return NO;
    }
    // enable reuseaddr
    int on = 1;
    setsockopt( CFSocketGetNative(socket_), SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on) );
    // bind
    CFSocketError err = CFSocketSetAddress( socket_, (CFDataRef)addr );
    if( err == kCFSocketSuccess ) {
        return YES;
    }
    return NO;
}

-(BOOL)bindToPort:(UInt16)port
{
    return [self bindToHost:nil port:port];
}

-(BOOL)enableBroadcast
{
    int on = 1;
    int err = setsockopt( CFSocketGetNative(socket_), SOL_SOCKET, SO_BROADCAST, &on, sizeof(on) );
    return ( err == 0 );
}


-(void)delegateRxError:(int)error
{
    if( rxDelegate_ && [rxDelegate_ respondsToSelector:@selector(udpSocket:rxError:)] ) {
        [rxDelegate_ udpSocket:self rxError:error];
    }
}
-(void)delegateTxError:(int)error
{
    if( txDelegate_ && [txDelegate_ respondsToSelector:@selector(udpSocket:txError:)] ) {
        [txDelegate_ udpSocket:self txError:error];
    }
}

-(BOOL)canWrite:(CFSocketRef)socket
{
    fd_set fds;
    FD_ZERO(&fds);
    FD_SET(CFSocketGetNative(socket), &fds);
	
    struct timeval timeout;
    timeout.tv_sec = 0;
    timeout.tv_usec = 0;
	
    return select(FD_SETSIZE, NULL, &fds, NULL, &timeout) > 0;
}

-(void)forceWrite:(CFSocketRef)socket
{
    if( sendBuf_.count < 1 ) {
        NSLog(@"forceWrite: Send buffer empty");
        return;
    }
    if( ![self canWrite:socket] ) {
        NSLog(@"forceWrite: Socket not writeable");
        return;
    }
    UdpSocketPacket *packet = [[sendBuf_ objectAtIndex:0] retain];
    [sendBuf_ removeObjectAtIndex:0];
    // write the packet
    int sent = sendto( CFSocketGetNative(socket),
                       packet.data.bytes,
                       packet.data.length,
                       0,
                       packet.address.bytes,
                       packet.address.length );
    if( sent == packet.data.length ) {
        // TODO: Can we schedule this to run later?
        if( txDelegate_ && [rxDelegate_ respondsToSelector:@selector(udpSocketTxData:)] ) {
            [txDelegate_ udpSocketTxData:self];
        }
    } else {
        // This is bad...
        [self delegateTxError:-1]; // FIXME
    }
    [packet release];
}


-(void)onWrite:(CFSocketRef)socket
{
    [self forceWrite:socket];
}

-(BOOL)send:(NSData *)data host:(NSString *)host port:(UInt16)port tag:(NSObject *)tag;
{
    NSData *hostAddr = getHostAddress( host, port );
    if( !hostAddr ) {
        NSLog(@"%@:send - bad address",[self class]);
        return NO;
    }
    UdpSocketPacket *packet = [[UdpSocketPacket alloc] initWithData:data address:hostAddr tag:tag];
    [sendBuf_ addObject:packet];
    [packet release];
    [self forceWrite:socket_];
    return YES;
}

-(void)onRead:(CFSocketRef)socket
{
    // Recieve the packet...
    size_t size = 8192;         // Magic number
    void *buf = malloc( size );
    struct sockaddr_in addr;
    bzero( &addr, sizeof(addr) );
    socklen_t len = sizeof(addr);
    int result = recvfrom( CFSocketGetNative(socket),
                           buf,
                           size,
                           0,
                           (struct sockaddr *)&addr,
                           &len );
    if( result < 0 ) {
        NSLog(@"Receive failed %d",result);
        free(buf);
        [self delegateRxError:result]; // FIXME
        return;
    }
    // Try and realloc...
    if( result < size ) {
        // realloc(0) is often equivalent to free. We don't want that...
        void *p = realloc( buf, ( result > 0 ) ? result : 1 );
        if( p ) {
            buf = p;
        } else {
            // realloc failed; just use buf as-is.
        }
    }

    NSData *data = [[NSData alloc] initWithBytesNoCopy:buf
                                                length:result
                                          freeWhenDone:YES];
    NSData *address = [[NSData alloc] initWithBytes:&addr length:len];
    UdpSocketPacket *packet = [[UdpSocketPacket alloc] initWithData:data
                                                    address:address
                                                        tag:nil];

    [recvBuf_ addObject:packet]; // TODO: The address
    if( rxDelegate_ && [rxDelegate_ respondsToSelector:@selector(udpSocketRxData:)] ) {
        [rxDelegate_ udpSocketRxData:self];
    }
    [packet release];
    [address release];
    [data release];
}

-(NSUInteger)rxQueueCount
{
    return recvBuf_.count;
}

-(UdpSocketPacket *)peekRxQueue
{
    if( recvBuf_.count ) {
        return [recvBuf_ objectAtIndex:0];
    }
    return nil;
}

-(UdpSocketPacket *)popRxQueue
{
    if( recvBuf_.count ) {
        UdpSocketPacket *packet = [[recvBuf_ objectAtIndex:0] retain];
        [recvBuf_ removeObjectAtIndex:0];
        return [packet autorelease];
    }
    return nil;
}

+(NSString *)hostname:(NSData *)data
{
    struct sockaddr_in addr;
    if( data.length != sizeof(addr) ) {
        NSLog(@"hostname : bad size");
        return nil;
    }
    [data getBytes:&addr length:sizeof(addr)];
    char addrBuf[INET_ADDRSTRLEN];
    if( !inet_ntop(AF_INET, &addr.sin_addr, addrBuf, sizeof(addrBuf) ) ) {
        NSLog(@"hostname : inet_ntop failed");
        return nil;
    }
    return [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
}

@end


@implementation UdpSocket (internal)
-(void)doCallback:(CFSocketCallBackType)type
           socket:(CFSocketRef)socket
          address:(CFDataRef)address
             data:(const void *)data
{
    NSAssert( socket == socket_, @"Invalid socket" );
    switch( type )
        {
        case kCFSocketReadCallBack:
            [self onRead:socket];
            break;
        case kCFSocketWriteCallBack:
            [self onWrite:socket];
            break;
        case kCFSocketNoCallBack:
        case kCFSocketAcceptCallBack:
        case kCFSocketDataCallBack:
        case kCFSocketConnectCallBack:
        default:
            NSLog(@"Unexpected socket callback 0x%02x",type);
            break;
        }
}
@end
