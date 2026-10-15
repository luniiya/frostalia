import QtQuick
import QtTest
import "../Helpers/AdvancedMath.js" as AdvancedMath

TestCase {
  name: "AdvancedMath"

  function test_angleConversion() {
    fuzzyCompare(AdvancedMath.toRadians(180), Math.PI, 1e-12);
    fuzzyCompare(AdvancedMath.toDegrees(Math.PI / 2), 90, 1e-12);
    fuzzyCompare(AdvancedMath.toDegrees(AdvancedMath.toRadians(37)), 37, 1e-12);
  }

  function test_constants() {
    compare(AdvancedMath.constants.PI, Math.PI);
    compare(AdvancedMath.constants.E, Math.E);
    compare(AdvancedMath.constants.SQRT2, Math.SQRT2);
  }

  function test_evaluate_data() {
    return [
          {
            tag: "addition",
            expr: "2+3",
            expected: 5
          },
          {
            tag: "precedence",
            expr: "2+3*4",
            expected: 14
          },
          {
            tag: "parentheses",
            expr: "(2+3)*4",
            expected: 20
          },
          {
            tag: "whitespace",
            expr: " 10 / 4 ",
            expected: 2.5
          },
          {
            tag: "modulo",
            expr: "10%3",
            expected: 1
          },
          {
            tag: "negative",
            expr: "-5+2",
            expected: -3
          },
          {
            tag: "power operator",
            expr: "2^10",
            expected: 1024
          },
          {
            tag: "power of group",
            expr: "2^(1+2)",
            expected: 8
          },
          {
            tag: "pow",
            expr: "pow(3,2)",
            expected: 9
          },
          {
            tag: "sqrt",
            expr: "sqrt(16)",
            expected: 4
          },
          {
            tag: "cbrt",
            expr: "cbrt(27)",
            expected: 3
          },
          {
            tag: "abs",
            expr: "abs(-7)",
            expected: 7
          },
          {
            tag: "floor",
            expr: "floor(2.7)",
            expected: 2
          },
          {
            tag: "ceil",
            expr: "ceil(2.1)",
            expected: 3
          },
          {
            tag: "round",
            expr: "round(2.5)",
            expected: 3
          },
          {
            tag: "trunc",
            expr: "trunc(-2.7)",
            expected: -2
          },
          {
            tag: "min",
            expr: "min(4,2,8)",
            expected: 2
          },
          {
            tag: "max",
            expr: "max(4,2,8)",
            expected: 8
          },
          {
            tag: "log10",
            expr: "log(1000)",
            expected: 3
          },
          {
            tag: "uppercase",
            expr: "SQRT(81)",
            expected: 9
          }
        ];
  }

  function test_evaluate(data) {
    fuzzyCompare(AdvancedMath.evaluate(data.expr), data.expected, 1e-9);
  }

  function test_evaluate_constantsAndTranscendental() {
    fuzzyCompare(AdvancedMath.evaluate("pi"), Math.PI, 1e-12);
    fuzzyCompare(AdvancedMath.evaluate("e"), Math.E, 1e-12);
    fuzzyCompare(AdvancedMath.evaluate("ln(e)"), 1, 1e-12);
    fuzzyCompare(AdvancedMath.evaluate("exp(0)"), 1, 1e-12);
    fuzzyCompare(AdvancedMath.evaluate("sin(0)"), 0, 1e-12);
    fuzzyCompare(AdvancedMath.evaluate("cos(pi)"), -1, 1e-12);
    fuzzyCompare(AdvancedMath.evaluate("atan2(1,1)"), Math.PI / 4, 1e-12);
    fuzzyCompare(AdvancedMath.evaluate("tanh(0)"), 0, 1e-12);
  }

  function test_evaluate_degreeTrig() {
    fuzzyCompare(AdvancedMath.evaluate("sind(90)"), 1, 1e-12);
    fuzzyCompare(AdvancedMath.evaluate("cosd(180)"), -1, 1e-12);
    fuzzyCompare(AdvancedMath.evaluate("tand(45)"), 1, 1e-12);
  }

  function test_evaluate_random() {
    var r = AdvancedMath.evaluate("random()");
    verify(r >= 0 && r < 1);
  }

  function test_evaluate_rejectsUnsafeInput_data() {
    return [
          {
            tag: "identifier",
            expr: "alert(1)"
          },
          {
            tag: "property access",
            expr: "Math.PI"
          },
          {
            tag: "string",
            expr: "'a'"
          },
          {
            tag: "assignment",
            expr: "x=1"
          },
          {
            tag: "semicolon",
            expr: "1;2"
          },
          {
            tag: "brackets",
            expr: "[1]"
          },
          {
            tag: "empty",
            expr: ""
          }
        ];
  }

  function test_evaluate_rejectsUnsafeInput(data) {
    var threw = false;
    try {
      AdvancedMath.evaluate(data.expr);
    } catch (e) {
      threw = true;
      verify(String(e.message).indexOf("Evaluation failed") === 0, e.message);
    }
    verify(threw, "expected '" + data.expr + "' to be rejected");
  }

  function test_evaluate_rejectsNonFiniteResults() {
    var inputs = ["1/0", "sqrt(-1)", "0/0"];
    for (var i = 0; i < inputs.length; i++) {
      var threw = false;
      try {
        AdvancedMath.evaluate(inputs[i]);
      } catch (e) {
        threw = true;
      }
      verify(threw, inputs[i] + " should throw");
    }
  }

  function test_formatResult() {
    compare(AdvancedMath.formatResult(5), "5");
    compare(AdvancedMath.formatResult(-12), "-12");
    compare(AdvancedMath.formatResult(0.1 + 0.2), "0.3");
    compare(AdvancedMath.formatResult(2.5), "2.5");
    compare(AdvancedMath.formatResult(1.5e-7), "1.500000e-7");
    compare(AdvancedMath.formatResult(1.23456789e20 + 0.5), "123456789000000000000"); // integer path
    compare(AdvancedMath.formatResult(1e16 + 0.5), "10000000000000000");
  }

  function test_getAvailableFunctions() {
    var list = AdvancedMath.getAvailableFunctions();
    verify(list.length > 0);
    verify(list.some(s => s.indexOf("sqrt") !== -1));
  }
}
