#pragma once

#include "common.h"

#pragma clang assume_nonnull begin

@interface OFHTTPResponse(WriteExtensions)

- (void)asyncWriteHTML: (OFString *)html code: (int)code;

@end

@interface OFStream(WriteExtensions)

- (void)asyncWriteFormat: (OFConstantString *)format, ...;
- (void)asyncWriteFromStream: (OFStream *)stream;

@end

#pragma clang assume_nonnull end
