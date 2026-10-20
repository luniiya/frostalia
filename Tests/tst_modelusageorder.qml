import QtQuick
import QtTest
import "../Helpers/ModelUsageOrder.js" as ModelUsageOrder

TestCase {
  name: "ModelUsageOrder"

  function test_orderedIds_data() {
    return [
          { tag: "empty keeps default", order: [], expected: ModelUsageOrder.defaultOrder },
          { tag: "missing setting keeps default", order: undefined, expected: ModelUsageOrder.defaultOrder },
          { tag: "full custom order", order: ["zen", "gemini", "claude", "codex", "openrouter", "copilot"],
            expected: ["zen", "gemini", "claude", "codex", "openrouter", "copilot"] },
          { tag: "partial order appends the rest", order: ["gemini"],
            expected: ["gemini", "claude", "codex", "copilot", "openrouter", "zen"] },
          { tag: "unknown ids are ignored", order: ["nope", "codex"],
            expected: ["codex", "claude", "copilot", "gemini", "openrouter", "zen"] }
        ];
  }

  function test_orderedIds(data) {
    compare(ModelUsageOrder.orderedIds(data.order), data.expected);
  }

  function test_sortByOrderSortsObjects() {
    const items = [{ providerId: "claude" }, { providerId: "codex" }, { providerId: "gemini" }];
    const sorted = ModelUsageOrder.sortByOrder(items, ["gemini", "claude"], item => item.providerId);
    compare(sorted.map(item => item.providerId), ["gemini", "claude", "codex"]);
    compare(items[0].providerId, "claude");
  }

  function test_moved() {
    compare(ModelUsageOrder.moved([], 3, 0), ["gemini", "claude", "codex", "copilot", "openrouter", "zen"]);
    compare(ModelUsageOrder.moved(["zen"], 0, 5), ["claude", "codex", "copilot", "gemini", "openrouter", "zen"]);
  }

  function test_movedOutOfRangeIsNoop() {
    compare(ModelUsageOrder.moved([], -1, 2), ModelUsageOrder.defaultOrder);
    compare(ModelUsageOrder.moved([], 0, 6), ModelUsageOrder.defaultOrder);
  }
}
