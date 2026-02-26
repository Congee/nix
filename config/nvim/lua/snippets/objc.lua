local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local fmt = require('luasnip.extras.fmt').fmt

return {
    s("imp", fmt("#import \"{}.h\"", { i(1, "file") })),
    s("Imp", fmt("#import <{}>", { i(1, "Cocoa/Cocoa.h") })),
    s("cl", fmt("@interface {} : {}\n{{\n}}\n@end\n\n@implementation {}\n- (id)init\n{{\n\tif((self = [super init]))\n\t{{\n\t\t{}\n\t}}\n\treturn self;\n}}\n@end", { i(1, "object"), i(2, "NSObject"), i(1), i(0) })),
    s("array", fmt("NSMutableArray *{} = [NSMutableArray array];", { i(1, "array") })),
    s("dict", fmt("NSMutableDictionary *{} = [NSMutableDictionary dictionary];", { i(1, "dict") })),
    s("forarray", fmt("unsigned int {}Count = [{} count];\n\nfor(unsigned int index = 0; index < {}Count; index += 1)\n{{\n\t{} {} = [{} objectAtIndex:index];\n\t{}\n}}", { i(1, "object"), i(2, "array"), i(1), i(3, "id"), i(1), i(2), i(0) })),
    s("objacc", fmt("- ({}){}\n{{\n\treturn {};\n}}\n\n- (void)set{}:({})aValue\n{{\n\t{} = [aValue retain];\n}}", { i(1, "id"), i(2, "thing"), i(2), i(2), i(1), i(2) })),
    s("sel", fmt("@selector({}:)", { i(1, "method") })),
    s("cdacc", fmt("- ({}){}\n{{\n\t[self willAccessValueForKey:@\"{}\"];\n\t{} value = [self primitiveValueForKey:@\"{}\"];\n\t[self didAccessValueForKey:@\"{}\"];\n\treturn value;\n}}\n\n- (void)set{}:({})aValue\n{{\n\t[self willChangeValueForKey:@\"{}\"];\n\t[self setPrimitiveValue:aValue forKey:@\"{}\"];\n\t[self didChangeValueForKey:@\"{}\"];\n}}", { i(1, "id"), i(2, "attribute"), i(2), i(1), i(2), i(2), i(2), i(1), i(2), i(2), i(2) })),
    s("delegate", fmt("if([{} respondsToSelector:@selector({}:)])\n\t[{} {}];\n", { i(1, "[self delegate]"), i(2, "selfDidSomething"), i(1), i(2) })),
    s("thread", fmt("[NSThread detachNewThreadSelector:@selector({}:) toTarget:{} withObject:{}]", { i(1, "method"), i(2, "aTarget"), i(3, "anArgument") })),
    s("ibo", fmt("IBOutlet {} *{};", { i(1, "NSSomeClass"), i(2, "someClass") })),
    s("I", fmt("+ (void)initialize\n{{\n\t[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:\n\t\t{}@\"value\", @\"key\",\n\t\tnil]];\n}}", { i(0) })),
    s("bind", fmt("bind:@\"{}\" toObject:{} withKeyPath:@\"{}\" options:{}", { i(1, "binding"), i(2, "observableController"), i(3, "keyPath"), i(4, "nil") })),
    s("arracc", fmt("- (void)addObjectTo{}:({})anObject\n{{\n\t[{} addObject:anObject];\n}}", { i(1, "Things"), i(2, "id"), i(3, "things") })),
    s("focus", fmt("[self lockFocus];\n{}\n[self unlockFocus];", { i(0) })),
    s("pool", fmt("NSAutoreleasePool *pool = [NSAutoreleasePool new];\n{}\n[pool drain];", { i(0) })),
    s("log", fmt("NSLog(@\"{}\", {});", { i(1), i(2) })),
    s("alert", fmt("int choice = NSRunAlertPanel(@\"{}\", @\"{}\", @\"{}\", @\"{}\", nil);\nif(choice == NSAlertDefaultReturn)\n{{\n\t{}\n}}", { i(1, "Important"), i(2, "Message"), i(3, "Continue"), i(4, "Cancel"), i(0) })),
    s("format", fmt("[NSString stringWithFormat:@\"{}\", {}]{}", { i(1), i(2), i(0) })),
    s("prop", fmt("@property ({}) {} *{};", { i(1, "retain"), i(2, "NSSomeClass"), i(3, "someClass") })),
    s("getprefs", fmt("[[NSUserDefaults standardUserDefaults] objectForKey:{}];", { i(1, "key") })),
    s("obs", fmt("[[NSNotificationCenter defaultCenter] addObserver:{} selector:@selector({}:) name:{} object:{}];", { i(1, "self"), i(3, "notificationHandler"), i(2, "NSWindowDidBecomeMainNotification"), i(4, "nil") })),
    s("responds", fmt("if ([{} respondsToSelector:@selector({}:)])\n{{\n\t[{} {}];\n}}", { i(1, "self"), i(2, "someSelector"), i(1), i(2) })),
    s("gsave", fmt("[NSGraphicsContext saveGraphicsState];\n{}\n[NSGraphicsContext restoreGraphicsState];", { i(0) })),
    s("syn", fmt("@synthesize {};", { i(1, "property") })),
    s("setprefs", fmt("[[NSUserDefaults standardUserDefaults] setObject:{} forKey:{}];", { i(1, "object"), i(2, "key") })),
    s("main", fmt("int main(int argc, char *argv[]) {{\n\t{}\n}}", { i(0, "return NSApplicationMain(argc, (const char **)argv);") })),
}
