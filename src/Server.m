#include "Server.h"

#include <lauxlib.h>
#include <lualib.h>

#include "extensions.h"

#pragma clang assume_nonnull begin

@implementation LuaException

- (instancetype)initWithLuaState: (lua_State *)L
{
    self = [super init];

    // lua_getinfo(L, "nSl", &_debugInfo); sigsegv, id ont know why!
    _error = [OFString stringWithUTF8String: lua_tostring(L, -1)];
    // lua_getstack(L, 1, &_debugInfo);

    return self;
}

- (OFString *)description
{
    // return [OFString stringWithFormat: @"Lua error at %s:%d: %s", _debugInfo.short_src, _debugInfo.currentline, _error];
    return [OFString stringWithFormat: @"Lua error: %s", _error];
}

@end


@implementation Server {
    lua_State *L;
}

static OFDictionary<OFString *, OFString *> *mimeTypeCache;

+ (void)initialize
{
    mimeTypeCache = @{
        @"html": @"text/html",
        @"css": @"text/css",
        @"js": @"application/javascript",
        @"json": @"application/json",
        @"xml": @"application/xml",
        @"png": @"image/png",
        @"jpg": @"image/jpeg",
        @"jpeg": @"image/jpeg",
        @"gif": @"image/gif",
        @"svg": @"image/svg+xml",
        @"ico": @"image/x-icon",
        @"webp": @"image/webp",
        @"woff": @"font/woff",
        @"woff2": @"font/woff2",
        @"ttf": @"font/ttf",
        @"otf": @"font/otf",
        @"eot": @"font/eot",
        @"mp3": @"audio/mpeg",
        @"wav": @"audio/wav",
        @"ogg": @"audio/ogg",
        @"mp4": @"video/mp4",
        @"webm": @"video/webm",
        @"pdf": @"application/pdf",
        @"zip": @"application/zip",
        @"tar": @"application/x-tar",
        @"gz": @"application/gzip",
        @"bz2": @"application/x-bzip2",
        @"7z": @"application/x-7z-compressed",
        @"rar": @"application/x-rar-compressed",
        @"exe": @"application/x-msdownload",
        @"doc": @"application/msword",
        @"docx": @"application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        @"xls": @"application/vnd.ms-excel",
        @"xlsx": @"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        @"ppt": @"application/vnd.ms-powerpoint",
        @"pptx": @"application/vnd.openxmlformats-officedocument.presentationml.presentation",
        @"txt": @"text/plain",
        @"rtf": @"application/rtf",
        @"csv": @"text/csv",
        @"tsv": @"text/tab-separated-values",
        @"md": @"text/markdown",
        @"sh": @"application/x-sh",
        @"c": @"text/x-c",
        @"cpp": @"text/x-c++",
        @"h": @"text/x-c-header",
        @"hpp": @"text/x-c++-header",
        @"java": @"text/x-java",
        @"cs": @"text/x-csharp",
        @"py": @"text/x-python",
        @"rb": @"text/x-ruby",
        @"lua": @"text/x-lua",
        @"wasm": @"application/wasm",
        @"mjs": @"application/javascript",
        @"cjs": @"application/javascript",
    };
}

+ (OFDictionary<OFString *, OFString *> *)mimeTypes
{ return mimeTypeCache; }

- (instancetype)initWithPagesDirectory: (OFString *)pagesDirectory resourcesDirectory:(nonnull OFString *)resourcesDirectory
{
    self = [super init];

    _pagesDirectory = pagesDirectory;
    _resourcesDirectory = resourcesDirectory;
    L = luaL_newstate();
    luaL_openlibs(L);

    auto res = luaL_dostring(L,
        "local xml_gen = require('xml-generator')\n"
        "return setmetatable({\n"
        "    require = require,\n"
        "    yield = coroutine.yield,\n"
        "    xml_gen = xml_gen,\n"
        "    xml = xml_gen.xml\n"
        "}, { __index = xml_gen.xml })"
    );
    if (res != LUA_OK)
        @throw [[LuaException alloc] initWithLuaState: L];

    lua_setfield(L, LUA_REGISTRYINDEX, "root_metatable");

    return self;
}

- (OFString *)renderPageFromPath: (OFString *)path
{
    auto res = luaL_dostring(L,
        [OFString stringWithFormat: @"local tmpl = require('pages.template')"
                                     "local xml_gen = require('xml-generator')\n"
                                     "return function(path, env)\n"
                                     "   local ok, err = loadfile(path, 't', env)\n"
                                     "   if not ok then\n"
                                     "       return nil, err\n"
                                     "   end\n"
                                     "   local res = ok()\n"
                                     "   return tostring(tmpl(path, unpack(res)))\n"
                                     "end"].UTF8String);
    if (res != LUA_OK)
        @throw [[LuaException alloc] initWithLuaState: L];

    //get the function
    lua_pushvalue(L, -1);

    //path arg
    lua_pushstring(L, path.UTF8String);
    //env arg
    lua_getfield(L, LUA_REGISTRYINDEX, "root_metatable");

    res = lua_pcall(L, 2, 1, 0);
    if (res != LUA_OK)
        @throw [[LuaException alloc] initWithLuaState: L];

    OFString *result = [OFString stringWithUTF8String: lua_tostring(L, -1)];
    lua_pop(L, 1);

    return result;
}

- (void)    server: (OFHTTPServer *)server
 didReceiveRequest: (OFHTTPRequest *)request
       requestBody: (OFStream *nillable)requestBody
          response: (OFHTTPResponse *)response
{
    auto ext = request.IRI.path.pathExtension;
    //check the `resourcesDirectory` directory for static files
    if (![ext isEqual: @""]) {
        OFString *path = [self.resourcesDirectory stringByAppendingPathComponent: request.IRI.path];
        if (![[OFFileManager defaultManager] fileExistsAtPath: path]) {
            [response asyncWriteHTML: [self renderPageFromPath: @"pages/404.lua"] code: 404];
            LogErrorAsync(@"\x1b[31m404\x1b[0m %@", request.IRI.path);
        } else {
            response.statusCode = 200;
            response.headers = @{
                @"Content-Type": [OFString stringWithFormat: @"%@", Server.mimeTypes[ext] ?: @"application/octet-stream"],
                @"Content-Length": [OFString stringWithFormat: @"%lu", (unsigned long)[[OFFileManager defaultManager] attributesOfItemAtPath: path].fileSize]
            };
            auto f = [OFFile fileWithPath: path mode: @"r"];
            [response asyncWriteFromStream: f];
            LogInfoAsync(@"\x1b[32m200\x1b[0m %@", request.IRI.path);
        }
        return;
    }

    //find the file, on the filesystem it will end in .lua
    OFString *path = [self.pagesDirectory stringByAppendingPathComponent: request.IRI.path];
    if (path.pathExtension.length == 0)
        path = [path stringByAppendingPathExtension: @"lua"];

    if (![[OFFileManager defaultManager] fileExistsAtPath: path]) {
        [response asyncWriteHTML: [self renderPageFromPath: @"pages/404.lua"] code: 404];
        LogErrorAsync(@"\x1b[31m404\x1b[0m %@", request.IRI.path);
    } else {
        OFTimeInterval start = OFDate.date.timeIntervalSince1970;
        auto s = [self renderPageFromPath: path];
        OFTimeInterval elapsed = OFDate.date.timeIntervalSince1970 - start;

        [response asyncWriteHTML: s code: 200];
        LogInfoAsync(@"\x1b[32m200\x1b[0m %@ (%.3fms)", request.IRI.path, elapsed * 1000);
    }
}

- (void)dealloc
{
    lua_close(L);
}

@end

#pragma clang assume_nonnull end
