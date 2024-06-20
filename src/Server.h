#pragma once

#include "common.h"
#include <lua.h>

#pragma clang assume_nonnull begin

@interface LuaException : OFException

@property(readonly) OFString *error;

- (instancetype)initWithLuaState: (lua_State *)L;

@end


@interface Server : OFObject<OFHTTPServerDelegate>

@property OFString *pagesDirectory;
@property OFString *resourcesDirectory;

@property(class, readonly) OFDictionary<OFString *, OFString *> *mimeTypes;

- (instancetype)initWithPagesDirectory: (OFString *)pagesDirectory resourcesDirectory: (OFString *)resourcesDirectory;

@end

#pragma clang assume_nonnull end
