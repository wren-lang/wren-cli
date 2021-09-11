import "io" for File
import "repl" for Lexer, Token
import "essentials" for Strings

class Method {
  construct new(name, klass) {
    _name = name
    _klass = klass
    _arguments = []
  }
  name { _name }
  cName { 
    return Strings.downcase(_klass.name) + Strings.titlecase(_name) 
  }
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
  methods { _methods }
  name { _name }
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
  newForeign(klass, i) {
    i = i + 2
    var isStatic
    var name = _tokens[i].text
    if (name == "static") {
      isStatic = true
      i = i + 2
      name = _tokens[i].text
    }

    var method = klass.addMethod(name)
    if (isStatic) method.makeStatic()
    System.print("foreign %(isStatic ? "static" : "") %(name)" )
  }
  toC() {
    var src = ""

    _klasses.each { |k| 
      k.methods.each { |m|
        src = src + "extern void %(m.cName)(WrenVM* vm);\n"
      }
    }
    src = src + "\n"

    src = src + 
    """// The array of built-in modules.
ModuleRegistry essentialRegistry[] =
{"""
    src = src + "\n"

    _klasses.each { |k| 
      src = src + "  CLASS(%(k.name))\n"
      k.methods.each { |m|
        
        if (m.isStatic) {
          src = src + "    STATIC_METHOD(\"%(m.signature)\", %(m.cName))\n"
        } else {
          src = src + "    METHOD(\"%(m.signature)\", %(m.cName))\n"
        }
      }
      src = src + "  END_CLASS\n"
    }
    src = src + "};"
    System.print(src)
  }
  parse() {
    var c = File.read(_file)
    var l = Lexer.new(c)
    _tokens = []
    _klasses = []
    while (!l.isAtEnd) {
      _tokens.add(l.readToken())
    }
    System.print(_tokens.count)

    var i = 0
    var klass = null
    while (i<_tokens.count) {
      var token = _tokens[i]
      if (token.type == Token.classKeyword) {
        // System.print("class " + _tokens[i+2].text)
        klass = Klass.new(_tokens[i+2].text)
        _klasses.add(klass)
      }

      // if (token.type == Token.staticKeyword) {
      //   System.print("static " + _tokens[i+2].text)
      // }

      if (token.type == Token.foreignKeyword) {
        newForeign(klass, i)
      }

      i = i + 1
    }
    return this
  }
}
WrenSource.new("src/module/io.wren").parse().toC()