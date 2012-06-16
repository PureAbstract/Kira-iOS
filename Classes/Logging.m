
#import "Logging.h"

typedef enum {
    kLogTypeInfo = 0x01,
    kLogTypeWarning = 0x02,
    kLogTypeError = 0x04,
} log_type_t;

@implementation Logger

+(Logger *)logger
{
    static Logger *instance = nil;
    if( !instance ) {
        instance = [Logger new];
    }
    return instance;
}

-(void)logMessage:(NSString *)message
{
    NSDate *date = [NSDate date];
    NSLog(@"%@ : %@",date,message);
}
@end


@implementation NSObject (logging)


-(void)log:(log_type_t)type withFormat:(NSString *)format arguments:(va_list)args
{
    // FIXME - do something with 'type'
    NSString *msg = [[NSString alloc] initWithFormat:format
                                           arguments:args];
    [[Logger logger] logMessage:msg];
    [msg release];
}

-(void)logError:(NSString *)format arguments:(va_list)arguments
{
    [self log:kLogTypeError
          withFormat:format
          arguments:arguments];
}

-(void)logError:(NSString *)format, ...
{
    va_list args;
    va_start(args,format);
    [self logError:format
         arguments:args];
    va_end(args);
}

-(void)logWarning:(NSString *)format arguments:(va_list)arguments
{
    [self log:kLogTypeWarning
          withFormat:format
          arguments:arguments];
}

-(void)logWarning:(NSString *)format, ...
{
    va_list args;
    va_start(args,format);
    [self logWarning:format
           arguments:args];
    va_end(args);
}

-(void)logInfo:(NSString *)format arguments:(va_list)arguments
{
    [self log:kLogTypeInfo
          withFormat:format
          arguments:arguments];
}

-(void)logInfo:(NSString *)format, ...
{
    va_list args;
    va_start(args,format);
    [self logInfo:format
        arguments:args];
    va_end(args);
}

@end
