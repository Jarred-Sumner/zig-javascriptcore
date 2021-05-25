const std = @import("std");
const testing = std.testing;

const js = @import("./JavascriptCore.zig");

var allocator = std.heap.c_allocator;

fn logFromJavascript(
    ctx: js.JSContextRef,
    function: js.JSObjectRef,
    this: js.JSObjectRef,
    argument_count: usize,
    _arguments: [*c]const js.JSValueRef,
    except: [*c]js.JSValueRef,
) callconv(.C) js.JSValueRef {
    const args = _arguments[0..argument_count];
    var input: js.JSStringRef = js.JSValueToStringCopy(ctx, args[0], null);

    var buffer = allocator.alloc(u8, js.JSStringGetMaximumUTF8CStringSize(input)) catch unreachable;
    defer allocator.free(buffer);

    const string_length = js.JSStringGetUTF8CString(input, buffer.ptr, buffer.len);
    const string = buffer[0..string_length];

    var stdout = std.io.getStdOut();

    stdout.writeAll(string) catch {};

    return js.JSValueMakeUndefined(ctx);
}

export fn sayHello() void {
    var context_group: js.JSContextGroupRef = js.JSContextGroupCreate();
    var global_context: js.JSGlobalContextRef = js.JSGlobalContextCreateInGroup(context_group, null);
    var global_object: js.JSObjectRef = js.JSContextGetGlobalObject(global_context);
    var log_function_name: js.JSStringRef = js.JSStringCreateWithUTF8CString("log"[0.. :0]);
    var function: js.JSObjectRef = js.JSObjectMakeFunctionWithCallback(global_context, log_function_name, logFromJavascript);
    var log_call_statement: js.JSStringRef = js.JSStringCreateWithUTF8CString("log('Hello from JavaScript inside Zig');"[0.. :0]);
    js.JSObjectSetProperty(global_context, global_object, log_function_name, function, js.kJSPropertyAttributeNone, null);
    const ret = js.JSEvaluateScript(global_context, log_call_statement, null, null, 1, null);

    js.JSGlobalContextRelease(global_context);
    js.JSContextGroupRelease(context_group);
    js.JSStringRelease(log_function_name);
    js.JSStringRelease(log_call_statement);
}

pub fn main() anyerror!void {
    sayHello();
}

test "basic add functionality" {
    sayHello();
}
