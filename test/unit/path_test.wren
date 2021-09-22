// nontest
import "wren-assert/Assert" for Assert
import "wren-testie/testie" for Testie
import "../../src/cli/path" for Path

class TestNormalize {
  construct new() {}
  expectNormalize(a,b) {
    var normalized = Path.new(a).normalize.toString
    var error = "`%(a)` should normalize to `%(b)`\n      Got `%(normalized)` instead."
    Assert.equal(normalized, b, error)
  }
  run() {
    // Simple cases.
    expectNormalize("", ".")
    expectNormalize(".", ".")
    expectNormalize("..", "..")
    expectNormalize("a", "a")
    expectNormalize("/", "/")
    
    // Collapses redundant separators.
    expectNormalize("a/b/c", "a/b/c")
    expectNormalize("a//b///c////d", "a/b/c/d")
    
    // Eliminates "." parts, except one at the beginning.
    expectNormalize("./", ".")
    expectNormalize("/.", "/")
    expectNormalize("/./", "/")
    expectNormalize("./.", ".")
    expectNormalize("a/./b", "a/b")
    expectNormalize("a/.b/c", "a/.b/c")
    expectNormalize("a/././b/./c", "a/b/c")
    expectNormalize("././a", "./a")
    expectNormalize("a/./.", "a")
    
    // Eliminates ".." parts.
    expectNormalize("..", "..")
    expectNormalize("../", "..")
    expectNormalize("../../..", "../../..")
    expectNormalize("../../../", "../../..")
    expectNormalize("/..", "/")
    expectNormalize("/../../..", "/")
    expectNormalize("/../../../a", "/a")
    expectNormalize("a/..", ".")
    expectNormalize("a/b/..", "a")
    expectNormalize("a/../b", "b")
    expectNormalize("a/./../b", "b")
    expectNormalize("a/b/c/../../d/e/..", "a/d")
    expectNormalize("a/b/../../../../c", "../../c")
    
    // Does not walk before root on absolute paths.
    expectNormalize("..", "..")
    expectNormalize("../", "..")
    expectNormalize("/..", "/")
    expectNormalize("a/..", ".")
    expectNormalize("../a", "../a")
    expectNormalize("/../a", "/a")
    expectNormalize("/../a", "/a")
    expectNormalize("a/b/..", "a")
    expectNormalize("../a/b/..", "../a")
    expectNormalize("a/../b", "b")
    expectNormalize("a/./../b", "b")
    expectNormalize("a/b/c/../../d/e/..", "a/d")
    expectNormalize("a/b/../../../../c", "../../c")
    expectNormalize("a/b/c/../../..d/./.e/f././", "a/..d/.e/f.")
    
    // Removes trailing separators.
    expectNormalize("./", ".")
    expectNormalize(".//", ".")
    expectNormalize("a/", "a")
    expectNormalize("a/b/", "a/b")
    expectNormalize("a/b///", "a/b")
    
    expectNormalize("foo/bar/baz", "foo/bar/baz")
    expectNormalize("foo", "foo")
    expectNormalize("foo/bar/", "foo/bar")
    expectNormalize("./foo/././bar/././", "./foo/bar")
  }
}


Testie.new("Path") { |it, skip|

  it.should("should normalize") {
    TestNormalize.new().run()
  }
  it.should("detect root") {
    Assert.ok(Path.new("/").isRoot)
    Assert.ok(Path.new("C:\\").isRoot)
    Assert.ok(Path.new("E:").isRoot)
    Assert.ok(Path.new("Z:\\").isRoot)
    Assert.ok(!Path.new("Z::").isRoot)
    Assert.ok(!Path.new("/bob").isRoot)
  }
  it.should("navigate paths") {
    Assert.equal(Path.new("/").up().toString, "/")
    Assert.equal(Path.new("/bob").up().toString, "/")
    Assert.equal(Path.new("/bob/").up().toString, "/")
    Assert.equal(Path.new("/bob/smith").up().toString, "/bob")
  }
  it.should("join") {
    Assert.equal(Path.new("/").join("bob").toString, "/bob")
    Assert.equal(Path.new("a/b/c").join("d").toString, "a/b/c/d")
    Assert.equal(Path.new("a/b/c").join("./d").toString, "a/b/c/d")
    Assert.equal(Path.new("a/b/c").join("../d").toString, "a/b/d")
    Assert.equal(Path.new("a/b/c").join("../../d").toString, "a/d")
    Assert.equal(Path.new("a/b/c").join("../../../d").toString, "d")
    Assert.equal(Path.new(".").join("../testie").toString, "../testie")
    Assert.equal(Path.new(".").join("..").toString, "..")
    Assert.equal(Path.new(".").join("../../..").toString, "../../..")
  }
  it.should("dirname") {
    Assert.equal(Path.new("/a/b/c").dirname.toString, "/a/b")
    Assert.equal(Path.new("/a/b/c/").dirname.toString, "/a/b/c")
    Assert.equal(Path.new("/").dirname.toString, "/")
    Assert.equal(Path.new("a").dirname.toString, ".")
    Assert.equal(Path.new("/a").dirname.toString, "/")
  }
  it.should("split") {
    Assert.deepEqual(Path.split("c:"),["c:"])
    Assert.deepEqual(Path.split("c:\\"),["c:",""])
    Assert.deepEqual(Path.split("c:\\bob\\smith"),["c:","bob","smith"])
    Assert.deepEqual(Path.split("c:\\bob\\smith\\"),["c:","bob","smith",""])
  }
  it.should("windows") {
    Assert.equal(Path.new("c:\\bob\\smith").up().toString, "c:\\bob")
    Assert.equal(Path.new("c:\\bob\\smith").dirname.toString, "c:\\bob")
    Assert.equal(Path.new("c:\\").dirname.toString, "c:")
    Assert.equal(Path.new("c:\\bob\\ellis").join("./smith").toString, "c:\\bob\\ellis\\smith")
    Assert.equal(Path.new("c:\\bob\\ellis").join("../smith").toString, "c:\\bob\\smith")
    Assert.equal(Path.new("c:\\bob\\ellis").join("../..").toString, "c:")
    Assert.equal(Path.new("c:").join("a/b").toString, "c:\\a\\b")
  }
}.run()
