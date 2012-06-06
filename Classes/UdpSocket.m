
#import "UdpSocket.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>
#import <arpa/inet.h>
#import <net/if.h>
#import <CFNetwork/CFNetwork.h>

// Create an NSData representing an sockaddr_in
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
#pragma mark -
#pragma mark Properties
@synthesize data = data_;
@synthesize address = address_;
@synthesize tag = tag_;

#pragma mark -
#pragma mark Initialisation
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

#pragma mark -
#pragma mark Memory Management
-(void)dealloc {
    [data_ release];
    [address_ release];
    [tag_ release];
    [super dealloc];
}
@end



// Forward declare the callback function
static void UdpSocketCFSocketCallback( CFSocketRef socket,
                                       CFSocketCallBackType type,
                                       CFDataRef address,
                                       const void *pData,
                                       void *pInfo );

@implementation UdpSocket
#pragma mark -
#pragma mark Properties
@synthesize txDelegate = txDelegate_;
@synthesize rxDelegate = rxDelegate_;

#pragma mark -
#pragma mark Memory Management
-(void)dealloc {
    [self close];
    [sendQueue_ release];
    [super dealloc];
}

#pragma mark -
#pragma mark Initialisation
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
                                  UdpSocketCFSocketCallback,
                                  &context_ );
        // This us supposed to stop us getting continuous callbacks
        //CFSocketSetSocketFlags( socket_, kCFSocketCloseOnInvalidate );
        runLoop_ = CFRunLoopGetCurrent();
        sourceRef_ = CFSocketCreateRunLoopSource( kCFAllocatorDefault, socket_, 0 );
        CFRunLoopAddSource( runLoop_, sourceRef_, (CFStringRef)NSDefaultRunLoopMode );
        sendQueue_ = [NSMutableArray new];
    }
    return self;
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
    [sendQueue_ removeAllObjects];
    runLoop_ = NULL;
}

-(BOOL)bindToHost:(NSString *)host port:(UInt16)port
{
    NSData *addr = getHostAddress( host, port );
    if( !addr ) {
        NSLog(@"bindToHost:port - getHostAddress failed");
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
    NSLog(@"bindToHost:port - CFSocketSetAddress failed");
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

-(BOOL)canRead:(CFSocketRef)socket
{
    fd_set fds;
    FD_ZERO(&fds);
    FD_SET(CFSocketGetNative(socket), &fds);

    struct timeval timeout;
    timeout.tv_sec = 0;
    timeout.tv_usec = 0;

    return select(FD_SETSIZE, &fds, NULL, NULL, &timeout) > 0;
}

-(void)tryWrite:(CFSocketRef)socket
{
    if( sendQueue_.count < 1 ) {
        NSLog(@"tryWrite: Send buffer empty");
        return;
    }
    if( ![self canWrite:socket] ) {
        NSLog(@"tryWrite: Socket not writeable");
        return;
    }
    // Pop a packet from the queue...
    UdpSocketPacket *packet = [[sendQueue_ objectAtIndex:0] retain];
    [sendQueue_ removeObjectAtIndex:0];
    // write it
    int sent = sendto( CFSocketGetNative(socket),
                       packet.data.bytes,
                       packet.data.length,
                       0,
                       packet.address.bytes,
                       packet.address.length );
    // See what happened
    if( sent == packet.data.length ) {
        if( txDelegate_ && [txDelegate_ respondsToSelector:@selector(udpSocket:sentDataWithTag:)] ) {
            [txDelegate_ udpSocket:self
                   sentDataWithTag:packet.tag];
        }
    } else {
        // This is bad...
        [self delegateTxError:errno]; // FIXME
    }
    [packet release];
}


// Called from the callback.
-(void)onWrite:(CFSocketRef)socket
{
    [self tryWrite:socket];
}

-(BOOL)send:(NSData *)data host:(NSString *)host port:(UInt16)port tag:(NSObject *)tag;
{
    NSData *hostAddr = getHostAddress( host, port );
    if( !hostAddr ) {
        NSLog(@"%@:send - bad address",[self class]);
        return NO;
    }
    UdpSocketPacket *packet = [[UdpSocketPacket alloc] initWithData:data address:hostAddr tag:tag];
    [sendQueue_ addObject:packet];
    [packet release];
    [self tryWrite:socket_];
    return YES;
}

-(void)onRead:(CFSocketRef)socket
{
    if( ![self canRead:socket] ) {
        NSLog(@"onRead: Socket not readable");
        return;
    }
    // Recieve the packet...
    size_t size = 32768;        // Magic number
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
        [self delegateRxError:errno];
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

    [address release];
    [data release];
    if( rxDelegate_ && [rxDelegate_ respondsToSelector:@selector(udpSocket:receivedData:)] ) {
        [rxDelegate_ udpSocket:self
                  receivedData:packet];
    } else {
        // Just discard it
        NSLog(@"Discarding packet");
    }
    [packet release];
}


// TODO: These for sockaddr_in6
+(BOOL)data:(NSData *)data toSockaddr:(struct sockaddr_in*)sockaddr
{
    NSAssert( sockaddr, @"NULL sockaddr" );
    if( !sockaddr ) {
        NSLog(@"data->toSockaddr : NULL buffer" );
        return NO;
    }
    bzero( sockaddr, sizeof(*sockaddr) );
    if( data.length != sizeof(*sockaddr) ) {
        NSLog(@"data->toSockaddr : bad size");
        return NO;
    }
    [data getBytes:sockaddr length:sizeof(*sockaddr)];
    if( sockaddr->sin_family != AF_INET ) {
        NSLog(@"data->toSockaddr : Bad family");
        return NO;
    }
    return YES;
}

+(NSString *)hostname:(NSData *)data
{
    struct sockaddr_in addr;
    if( ![self data:data toSockaddr:&addr] ) {
        return nil;
    }
    char buffer[INET_ADDRSTRLEN];
    if( !inet_ntop(AF_INET, &addr.sin_addr, buffer, sizeof(buffer) ) ) {
        NSLog(@"hostname : inet_ntop failed %d",errno);
        return nil;
    }
    return [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
}

+(UInt16)port:(NSData *)data;
{
    struct sockaddr_in addr;
    if( ![self data:data toSockaddr:&addr] ) {
        return 0;
    }
    return ntohs(addr.sin_port);
}


#pragma mark -
#pragma mark Callback Method
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


#pragma mark -
#pragma mark Callback function
static void UdpSocketCFSocketCallback( CFSocketRef socket,
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
@end

