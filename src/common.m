#include "common.h"

#include <stdarg.h>
#include <unistd.h>
#include "extensions.h"

#pragma clang assume_nonnull begin

static OFString *LogMessage(OFString *classification, OFString *message)
{
    OFDate *date = [OFDate date];
    OFString *dateString = [date localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];
#ifdef OF_HAVE_FILES
    OFString *me = OFApplication.programName.lastPathComponent;
#else
    OFString *me = OFApplication.programName;
#endif

    if (me == nil)
        me = @"?";

    return [OFString stringWithFormat: @"[%@.%03d %@(%d) - %10@] %@", dateString, date.microsecond / 1000, me, getpid(), classification, message];
}

void LogInfo(OFConstantString *format, ...)
{
    va_list arguments;
    va_start(arguments, format);
    LogInfoV(format, arguments);
    va_end(arguments);
}

void LogInfoV(OFConstantString *format, va_list arguments)
{
    auto pool = objc_autoreleasePoolPush();

    OFString *msg = [[OFString alloc] initWithFormat: format arguments: arguments];
    [OFStdOut writeLine: LogMessage(@$BOLD $BLUE "INFO" $RESET, msg)];

    objc_autoreleasePoolPop(pool);
}

void LogInfoAsync(OFConstantString *format, ...)
{
    va_list arguments;
    va_start(arguments, format);
    LogInfoAsyncV(format, arguments);
    va_end(arguments);
}

void LogInfoAsyncV(OFConstantString *format, va_list arguments)
{
	auto pool = objc_autoreleasePoolPush();

	OFString *msg = [[OFString alloc] initWithFormat: format arguments: arguments];

	[OFStdOut asyncWriteFormat: @"%@\n", LogMessage(@$BOLD $BLUE "INFO" $RESET, msg)];

	objc_autoreleasePoolPop(pool);
}

void LogError(OFConstantString *format, ...)
{
    va_list arguments;
    va_start(arguments, format);
    LogErrorV(format, arguments);
    va_end(arguments);
}

void LogErrorV(OFConstantString *format, va_list arguments)
{
    auto pool = objc_autoreleasePoolPush();

    OFString *msg = [[OFString alloc] initWithFormat: format arguments: arguments];
    [OFStdErr writeLine: LogMessage(@$BOLD $RED "ERROR" $RESET, msg)];

    objc_autoreleasePoolPop(pool);
}

void LogErrorAsync(OFConstantString *format, ...)
{
    va_list arguments;
    va_start(arguments, format);
    LogErrorAsyncV(format, arguments);
    va_end(arguments);
}

void LogErrorAsyncV(OFConstantString *format, va_list arguments)
{
    auto pool = objc_autoreleasePoolPush();

    OFString *msg = [[OFString alloc] initWithFormat: format arguments: arguments];

    [OFStdErr asyncWriteFormat: @"%@\n", LogMessage(@$BOLD $RED "ERROR" $RESET, msg)];

    objc_autoreleasePoolPop(pool);
}

#pragma clang assume_nonnull end
