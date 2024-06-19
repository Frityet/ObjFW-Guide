#import <ObjFW/ObjFW.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

@interface LuaException : OFException

@property(readonly) OFString *error;
@property(readonly) lua_Debug debugInfo;

- (instancetype)initWithLuaState: (lua_State *)L;

@end

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

@interface OFHTTPResponse(WriteExtensions)

- (void)asyncWriteHTML: (OFString *)html code: (int)code;

@end

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

@interface ServerDelegate : OFObject<OFHTTPServerDelegate>

@property OFString *pagesDirectory;

- (instancetype)initWithPagesDirectory: (OFString *)pagesDirectory;

@end

@implementation ServerDelegate {
    lua_State *L;
}

- (instancetype)initWithPagesDirectory: (OFString *)pagesDirectory
{
    self = [super init];

    _pagesDirectory = pagesDirectory;
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
        [OFString stringWithFormat: @"local root = require('pages.root')"
                                     "local xml_gen = require('xml-generator')\n"
                                     "return function(path, env)\n"
                                     "   local ok, err = loadfile(path, 't', env)\n"
                                     "   if not ok then\n"
                                     "       return nil, err\n"
                                     "   end\n"
                                     "   local res = ok()\n"
                                     "   return tostring(root(path, unpack(res)))\n"
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
 didReceiveRequest: (nonnull OFHTTPRequest *)request
       requestBody: (nullable OFStream *)requestBody
          response: (nonnull OFHTTPResponse *)response
{
    //find the file, on the filesystem it will end in .lua
    OFString *path = [self.pagesDirectory stringByAppendingPathComponent: request.IRI.path];
    if (path.pathExtension.length == 0)
        path = [path stringByAppendingPathExtension: @"lua"];

    if (![[OFFileManager defaultManager] fileExistsAtPath: path])
        [response asyncWriteHTML: [self renderPageFromPath: @"pages/404.lua"] code: 404];
    else
        [response asyncWriteHTML: [self renderPageFromPath: path] code: 200];
}

- (void)dealloc
{
    lua_close(L);
}

@end

@interface Application : OFObject<OFApplicationDelegate> @end

@implementation Application {
    ServerDelegate *serverDelegate;
}

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
    OFHTTPServer *server = [OFHTTPServer server];
    server.host = @"127.0.0.1";
    server.port = 8080;
    server.delegate = serverDelegate = [[ServerDelegate alloc] initWithPagesDirectory: @"pages"];
    [server start];

    OFLog(@"Server started on port 8080");
}

@end


#if defined(OF_WINDOWS)
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    extern int __argc;
    extern char **__argv;
    return OFApplicationMain(&__argc, &__argv, [[Application alloc] init]);
}
#else
int main(int argc, char *argv[])
{
    return OFApplicationMain(&argc, &argv, [[Application alloc] init]);
}
#endif
