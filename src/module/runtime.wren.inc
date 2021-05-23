// Please do not edit this file. It has been generated automatically
// from `src/module/runtime.wren` using `util/wren_to_c_string.py`

static const char* runtimeModuleSource =
"class Capability {\n"
"  construct new(name) {\n"
"    _name = name\n"
"    _version = 0\n"
"  }\n"
"  ==(x) { x == _name }\n"
"  toString { _name }\n"
"}\n"
"\n"
"class Runtime {\n"
"  static NAME { \"wren-console\" }\n"
"  static WREN_VERSION { \"0.4.0\" }\n"
"  static VERSION { \"0.1.99\" }\n"
"  static details {\n"
"    return {\n"
"      \"name\": Runtime.NAME,\n"
"      \"wrenVersion\": Runtime.WREN_VERSION,\n"
"      \"version\": Runtime.VERSION,\n"
"      \"capabilities\": [\n"
"        Capability.new(\"essentials\"),\n"
"        Capability.new(\"mirror\")\n"
"      ]\n"
"    }\n"
"  }\n"
"}\n"
"\n";