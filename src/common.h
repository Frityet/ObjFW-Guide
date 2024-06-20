#pragma once

#import <ObjFW/ObjFW.h>

#include <iso646.h>

#define $RESET 	    "\x1b[0m"
#define $BOLD 	    "\x1b[1m"
#define $FAINT 	    "\x1b[2m"
#define $ITALIC     "\x1b[3m"
#define $UNDERLINE  "\x1b[4m"
#define $BLINK 	    "\x1b[5m"

#define $INVERT     "\x1b[7m"
#define $HIDDEN     "\x1b[8m"
#define $STRIKE     "\x1b[9m"

#define $RED        "\x1b[31m"
#define $GREEN      "\x1b[32m"
#define $YELLOW     "\x1b[33m"
#define $BLUE       "\x1b[34m"
#define $MAGENTA    "\x1b[35m"
#define $CYAN       "\x1b[36m"
#define $WHITE      "\x1b[37m"

#define _EVAL(x) x
#define $EVAL(...) _EVAL(__VA_ARGS__)
#define $(...) $EVAL($##__VA_ARGS__)

#define nonnil _Nonnull
#define nillable _Nullable
#define nilptr ((void *nillable)NULL)

#pragma clang assume_nonnull begin

void LogInfo(OFConstantString *format, ...);
void LogInfoV(OFConstantString *format, va_list arguments);
void LogInfoAsync(OFConstantString *format, ...);
void LogInfoAsyncV(OFConstantString *format, va_list arguments);

void LogError(OFConstantString *format, ...);
void LogErrorV(OFConstantString *format, va_list arguments);
void LogErrorAsync(OFConstantString *format, ...);
void LogErrorAsyncV(OFConstantString *format, va_list arguments);

#pragma clang assume_nonnull end
