import QtQuick
import QtTest
import "../Helpers/ColorList.js" as ColorList
import "../Helpers/Debug.js" as Debug
import "../Helpers/QtObj2JS.js" as QtObj2JS
import "../Helpers/sha256.js" as Crypto

TestCase {
  name: "MiscHelpers"

  // ----- sha256 (reference values from the NIST vectors / node crypto) -----

  function test_sha256_data() {
    return [
          {
            tag: "empty",
            input: "",
            expected: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
          },
          {
            tag: "abc",
            input: "abc",
            expected: "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
          },
          {
            tag: "hello world",
            input: "Hello World",
            expected: "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e"
          },
          {
            tag: "fox",
            input: "The quick brown fox jumps over the lazy dog",
            expected: "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592"
          },
          {
            tag: "fox dot",
            input: "The quick brown fox jumps over the lazy dog.",
            expected: "ef537f25c895bfa782526529a9b63d97aa631564d5d789c2b765448c8635fb6c"
          },
          {
            tag: "55 bytes (one block)",
            input: "a".repeat(55),
            expected: "9f4390f8d30c2dd92ec9f095b65e2b9ae9b0a925a5258e241c9f1e910f734318"
          },
          {
            tag: "56 bytes (padding spills)",
            input: "a".repeat(56),
            expected: "b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a"
          },
          {
            tag: "64 bytes",
            input: "a".repeat(64),
            expected: "ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb"
          },
          {
            tag: "utf-8 incl. surrogate pair",
            input: "héllo wörld 🚀",
            expected: "29f5f135dd75f37391cd6c2b4ba87ddb705b617cb5ad611074f79d1273910967"
          }
        ];
  }

  function test_sha256(data) {
    compare(Crypto.sha256(data.input), data.expected);
  }

  function test_stringToUtf8Bytes() {
    compare(Crypto.stringToUtf8Bytes("A"), [0x41]);
    compare(Crypto.stringToUtf8Bytes("é"), [0xC3, 0xA9]);
    compare(Crypto.stringToUtf8Bytes("€"), [0xE2, 0x82, 0xAC]);
    compare(Crypto.stringToUtf8Bytes("🚀"), [0xF0, 0x9F, 0x9A, 0x80]);
  }

  function test_rightRotate() {
    compare(Crypto.rightRotate(1, 1), 0x80000000);
    compare(Crypto.rightRotate(0x80000000, 31), 1);
    compare(Crypto.rightRotate(0x12345678, 8), 0x78123456);
  }

  // ----- Debug.stringify -----

  function test_stringify_plain() {
    compare(Debug.stringify({
                              "a": 1,
                              "b": [1, 2]
                            }), '{"a":1,"b":[1,2]}');
  }

  function test_stringify_circular() {
    var a = {
      "x": 1
    };
    a.self = a;
    compare(Debug.stringify(a), '{"x":1,"self":"[Circular ~]"}');

    var root = {
      "child": {}
    };
    root.child.parent = root.child;
    compare(Debug.stringify(root), '{"child":{"parent":"[Circular ~.child]"}}');
  }

  function test_stringify_customReplacers() {
    var a = {};
    a.me = a;
    compare(Debug.stringify(a, null, 0, function () {
      return "loop";
    }), '{"me":"loop"}');
    compare(Debug.stringify({
                              "n": 2
                            }, function (k, v) {
                              return k === "n" ? v * 10 : v;
                            }), '{"n":20}');
  }

  // ----- QtObj2JS -----

  function test_qtObjectToPlainObject_primitives() {
    compare(QtObj2JS.qtObjectToPlainObject(null), null);
    compare(QtObj2JS.qtObjectToPlainObject(undefined), undefined);
    compare(QtObj2JS.qtObjectToPlainObject(5), 5);
    compare(QtObj2JS.qtObjectToPlainObject("s"), "s");
    compare(QtObj2JS.qtObjectToPlainObject(true), true);
  }

  function test_qtObjectToPlainObject_nested() {
    var input = {
      "name": "bar",
      "list": [1,
        {
          "id": "Clock"
        }
      ],
      "empty": [],
      "fn": function () {},
      "widthChanged": 1,
      "objectName": "x"
    };
    var out = QtObj2JS.qtObjectToPlainObject(input);
    compare(out.name, "bar");
    compare(out.list.length, 2);
    compare(out.list[1].id, "Clock");
    compare(out.empty.length, 0);
    verify(!("fn" in out));
    verify(!("widthChanged" in out));
    verify(!("objectName" in out));
  }

  function test_qtObjectToPlainObject_arrayLike() {
    var arrayLike = {
      "length": 2,
      "0": "a",
      "1": "b"
    };
    compare(QtObj2JS.qtObjectToPlainObject(arrayLike), ["a", "b"]);
  }

  function test_qtObjectToPlainObject_colorLike() {
    var colorLike = {
      "r": 1,
      "g": 0.5,
      "b": 0,
      "a": 1,
      "valid": true,
      "toString": undefined
    };
    compare(QtObj2JS.qtObjectToPlainObject(colorLike), "#ff8000");
  }

  // ----- ColorList -----

  function test_colorList_wellFormed() {
    var list = ColorList.colors;
    verify(list.length > 50);
    var seen = {};
    for (var i = 0; i < list.length; i++) {
      var entry = list[i];
      verify(typeof entry.name === "string" && entry.name.length > 0, "entry " + i + " has a name");
      verify(typeof entry.color === "string" && entry.color.length > 0, entry.name + " has a color");
      verify(!seen[entry.name], "duplicate name " + entry.name);
      seen[entry.name] = true;
      verify(Qt.colorEqual(entry.color, entry.color.toLowerCase()), entry.name);
      verify(Qt.color(entry.color).a === 1 || entry.color === "transparent", entry.name + " parses as a color");
    }
  }
}
