#include "extensions.h"

#include "common.h"
#include <ObjFW/OFStream.h>

#pragma clang assume_nonnull begin

@implementation OFHTTPResponse(WriteExtensions)

- (void)asyncWriteHTML: (OFString *)html code: (int)code
{
    self.statusCode = code;
    self.headers = @{
        @"Content-Type": @"text/html",
        @"Content-Length": [OFString stringWithFormat: @"%zu", html.UTF8StringLength + sizeof("<!DOCTYPE html>\n") - 1]
    };
    [self asyncWriteString: @"<!DOCTYPE html>\n"];
    [self asyncWriteString: html];
}

@end

@implementation OFStream(WriteExtensions)

- (void)asyncWriteFormat: (OFConstantString *)format, ...
{
    va_list arguments;
    va_start(arguments, format);
    auto string = [[OFString alloc] initWithFormat: format arguments: arguments];
    va_end(arguments);
    [self asyncWriteString: string];
}


enum {
    DATA_SIZE = 4096
};

- (void)asyncWriteFromStream: (OFStream *)stream
{
    static OFMutableDictionary<OFStream *, OFData *> *buffers = nil;
    if (buffers == nil)
        buffers = [OFMutableDictionary dictionary];

    auto data = [OFMutableData dataWithCapacity: DATA_SIZE];
    buffers[stream] = data;

    [stream asyncReadIntoBuffer: data.mutableItems length: DATA_SIZE block: ^bool(size_t bytesRead, id) {
        if (stream.isAtEndOfStream) {
            [buffers removeObjectForKey: stream];
            return false;
        }

        [self asyncWriteData: data];
        return true;
    }];
}

@end

#pragma clang assume_nonnull end

