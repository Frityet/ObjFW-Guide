#include "common.h"
#include "extensions.h"

#include "Server.h"

#pragma clang assume_nonnull begin

@interface Application : OFObject<OFApplicationDelegate> @end

@implementation Application {
    Server *serverDelegate;
}

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
    __autoreleasing OFString *host = @"127.0.0.1";
    uint16_t port = 8080;
    auto showHelp = false;
    const OFOptionsParserOption opts[] = {
        {
            .longOption = @"host",
            .shortOption = 'H',
            .hasArgument = true,
        },
        {
            .longOption = @"port",
            .shortOption = 'p',
            .hasArgument = true,
        },
        {
            .longOption = @"help",
            .shortOption = 'h',
            .isSpecifiedPtr = &showHelp,
        },
        {0}
    };
    auto optionsParser = [OFOptionsParser parserWithOptions: opts];

    OFUnichar option = '\0';
    while ((option = [optionsParser nextOption])) {
        switch (option) {
            case 'h':
                break;
            case 'H':
                host = optionsParser.argument;
                break;
            case 'p':
                port = (uint16_t)optionsParser.argument.unsignedLongLongValue;
                break;

            case '?':
                [OFStdErr writeFormat: @"Unknown option: %@\n", optionsParser.lastLongOption ?: [OFString stringWithFormat: @"%lc", optionsParser.lastOption]];
                [OFStdErr writeLine: @"Try '--help' for more information."];
                [OFApplication terminateWithStatus: EXIT_FAILURE];

            case ':':
                [OFStdErr writeFormat: @"Missing argument for option: %@\n", optionsParser.lastLongOption ?: [OFString stringWithFormat: @"%lc", optionsParser.lastOption]];
                [OFStdErr writeLine: @"Try '--help' for more information."];
                [OFApplication terminateWithStatus: EXIT_FAILURE];
            default:
                break;
        }
    }

    if (showHelp) {
        [OFStdOut writeFormat: @"Usage: %@ [OPTIONS]\n", OFApplication.programName];
        [OFStdOut writeString: @"Options:\n"];
        for (size_t i = 0; i < sizeof(opts) / sizeof(opts[0]) - 1; i++) {
            if (opts[i].shortOption)
                [OFStdOut writeFormat: @"  -%c, --%@", (char)opts[i].shortOption, opts[i].longOption];
            else
                [OFStdOut writeFormat: @"  --%@", opts[i].longOption];

            if (opts[i].hasArgument)
                [OFStdOut writeString: @" <value>"];

            [OFStdOut writeString: @"\n"];
        }

        [OFApplication terminate];
    }

    auto server = [OFHTTPServer server];
    server.host = host;
    server.port = port;
    server.delegate = serverDelegate = [[Server alloc] initWithPagesDirectory: @"pages" resourcesDirectory: @"res"];
    [server start];

    LogInfo(@"Server started on port %d", (int)port);
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
int main(int argc, char *nonnil argv[])
{
    return OFApplicationMain(&argc, &argv, [[Application alloc] init]);
}
#endif

#pragma clang assume_nonnull end
