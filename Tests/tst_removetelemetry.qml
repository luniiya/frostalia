import QtQuick
import QtTest
import "../Commons/Migrations"

TestCase {
  name: "RemoveTelemetry"

  Migration70 {
    id: migration
  }

  function test_removesOnlyTelemetrySetting_data() {
    return [
          {
            tag: "enabled",
            general: {
              telemetryEnabled: true,
              scaleRatio: 1.25
            }
          },
          {
            tag: "disabled",
            general: {
              telemetryEnabled: false,
              scaleRatio: 1.25
            }
          },
          {
            tag: "already removed",
            general: {
              scaleRatio: 1.25
            }
          }
        ];
  }

  function test_removesOnlyTelemetrySetting(data) {
    const settings = {
      general: data.general,
      bar: {
        position: "bottom"
      }
    };
    const logger = {
      i: function () {}
    };
    verify(migration.migrate({}, logger, settings));
    compare(settings, {
              general: {
                scaleRatio: 1.25
              },
              bar: {
                position: "bottom"
              }
            });
    verify(migration.migrate({}, logger, settings));
    compare(settings.general.scaleRatio, 1.25);
  }

  function test_missingSection() {
    const settings = {};
    verify(migration.migrate({}, {
                               i: function () {}
                             }, settings));
    compare(settings, {});
  }
}
