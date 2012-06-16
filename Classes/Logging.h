
@interface Logger : NSObject

+(Logger *)logger;
-(void)logMessage:(NSString *)msg;
@end

@interface NSObject (Logging)
-(void)logWithFormat:(NSString *)format arguments:(va_list)args NS_FORMAT_FUNCTION(1,0);
-(void)log:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
@end
