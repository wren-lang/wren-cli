import "io" for File
import "repl" for Lexer, Token
import "essentials" for Strings

class Stream {
  construct new(tokens) {
    _tokens = tokens
    _cursor = 0
  }
  isEnd { _cursor >= _tokens.count }
  next() {
    if (isEnd) return null

    advance()
    return _tokens[_cursor-1]
  }
  skip(s) {
    if (isEnd) return

    if (peek().text == s) advance()
  }
  skipWS() {
    while (peek() && peek().type == Token.whitespace) {
      advance()
    }
  }
  advance() { _cursor = _cursor + 1}
  peek() {
    if (isEnd) return null

    return _tokens[_cursor]
  }
}

class Method {
  construct new(name, klass) {
    _name = name
    _klass = klass
    _arguments = []
  }
  name { _name }
  name=(name) { _name = name }
  cName { 
    var name = Strings.downcase(_klass.name) + Strings.titlecase(_name) 
    if (name[-1] == "_") name = name[0..-2]
    if (name[-1] == "=") name = name[0..-2] + "Set"
    return name
  }
  addArgument (arg) { _arguments.add(arg) }
  arguments { _arguments }
  signature { 
    return "" +
    _name +
    (!_isProperty ? "(" : "") +
    _arguments.map { "_" }.join(",") +
    (!_isProperty ? ")" : "")
  }
  makeStatic() { _isStatic = true }
  makeProp() { _isProperty = true }
  isStatic { _isStatic }
  isProperty { _isProperty }
}

class Klass {
  construct new(name) {
    _methods = []
    _name = name
  }
  isForeign { _isForeign }
  makeForeign() { _isForeign = true }
  methods { _methods }
  name { _name }
  allocateName { Strings.downcase(name) + "Allocate" }
  finalizeName { Strings.downcase(name) + "Finalize" }
  addMethod(name) {
    var m = Method.new(name, this)
    _methods.add(m)
    return m
  }
}

class WrenSource {
  construct new(f) {
    _file = f
  }
  stream { _stream }
  moduleName { 
    return _file.split("/")[-1].replace(".wren","")
  }
  newForeign(klass) {
    stream.skipWS()
    var isStatic
    var name = stream.next().text
    if (name == "static") {
      isStatic = true
      stream.skipWS()
      name = stream.next().text
    }
    var method = klass.addMethod(name)
    if (isStatic) method.makeStatic()

    stream.skipWS()
    if (stream.peek().type == Token.line || 
      stream.peek().type == Token.leftBrace) {
      method.makeProp()
      return
    }
    if (stream.peek().type == Token.equal) {
      stream.next()
      stream.skipWS()
      method.name = "%(name)="
    }
    if (stream.peek().type == Token.leftParen) {
      stream.next()
      stream.skipWS()
      while (stream.peek().type != Token.rightParen) {
        if(stream.peek().type == "name") {
          method.addArgument(stream.peek().text)
          stream.next() 
          stream.skipWS()
          stream.skip(",")
        } else {
          stream.advance()
        }
        stream.skipWS()
      }
    }
  }
  CfuncHeaders() {
    var src = ""
    _klasses.each { |k| 
      k.methods.each { |m|
        src = src + "extern void %(m.cName)(WrenVM* vm);\n"
      }
      if (k.isForeign) {
        src = src + "extern void %(k.allocateName)(WrenVM* vm);\n" +
          "extern void %(k.finalizeName)(void* data);\n"    
      }

    }
    return src
  }
  toC() {
    var src = ""
    src = src + "MODULE(%(moduleName))\n"
    _klasses.each { |k| 
      if (k.methods.isEmpty) return
      src = src + "  CLASS(%(k.name))\n"
      if (k.isForeign) {
        src = src + "    ALLOCATE(%(k.allocateName))\n    FINALIZE(%(k.finalizeName))\n"
      }
      k.methods.each { |m|
        if (m.isStatic) {
          src = src + "    STATIC_METHOD(\"%(m.signature)\", %(m.cName))\n"
        } else {
          src = src + "    METHOD(\"%(m.signature)\", %(m.cName))\n"
        }
      }
      src = src + "  END_CLASS\n"
    }
    src = src + "END_MODULE\n"
    return src
    // System.print(src)
  }
  lex(c) {
    var l = Lexer.new(c)
    var tokens = []
    while (!l.isAtEnd) {
      tokens.add(l.readToken())
    }
    return tokens
  }
  parse() {
    var c = File.read(_file)
    _tokens = lex(c)
    _klasses = []
    _stream = Stream.new(_tokens)
    // System.print(_tokens.count)

    var i = 0
    var klass = null
    while (!stream.isEnd) {
      var token = stream.next()
      if (token.type == Token.classKeyword) {
        // System.print("class " + _tokens[i+2].text)
        stream.skipWS()
        klass = Klass.new(stream.next().text)
        _klasses.add(klass)
      }

      if (token.type == Token.foreignKeyword) {
        stream.skipWS()
        // foreign class
        if (stream.peek().type == Token.classKeyword) {
          stream.next()
          stream.skipWS()
          klass = Klass.new(stream.next().text)
          klass.makeForeign()
          _klasses.add(klass)
        } else { // foreign method
          newForeign(klass)
        }
        
      }

      i = i + 1
    }
    return this
  }
}

class Replacer {
  construct new(file, heading) {
    _file = file
    _content = File.read(_file)
    _heading = heading
  }
  replace(s) {
    var prefix = "/* START %(_heading) */"
    var suffix = "/* END %(_heading) */"
    var si = _content.indexOf(prefix)
    var ei = _content.indexOf(suffix)
    var before = _content[0..si-1]
    var after = _content[ei+suffix.count..-1]
    var rewritten = "%(before)%(prefix)\n%(s)%(suffix)%(after)"
    // System.print(rewritten)
    File.create(_file) { |file|
      file.writeBytes(rewritten)
    }
  }
}

var SRCS = [
  "src/cli/cli.wren",
  "src/module/io.wren",
  "src/module/os.wren",
  "src/module/repl.wren",
  "src/module/runtime.wren",
  "src/module/scheduler.wren",
  "src/module/timer.wren",
]

var src = SRCS.map { |x| WrenSource.new(x).parse() }
var headers = src.map { |x| x.CfuncHeaders().trim() }.where {|x| !x.isEmpty}.join("\n")
var c_code = src.map { |x| x.toC() }.join("\n")

var code = headers +  "\n\n" +
  "static ModuleRegistry coreCLImodules[] = {\n" +
  c_code +
  "SENTINEL_MODULE\n" +
  "};\n" 


Replacer.new("src/cli/modules.c","AUTOGEN: core.cli.modules").replace(code)