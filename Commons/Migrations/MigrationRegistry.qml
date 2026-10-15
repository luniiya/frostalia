pragma Singleton

import QtQuick

QtObject {
  id: root

  // Map of version number to migration component
  readonly property var migrations: ({
                                       27: migration27Component,
                                       28: migration28Component,
                                       32: migration32Component,
                                       35: migration35Component,
                                       36: migration36Component,
                                       37: migration37Component,
                                       38: migration38Component,
                                       40: migration40Component,
                                       45: migration45Component,
                                       47: migration47Component,
                                       48: migration48Component,
                                       49: migration49Component,
                                       50: migration50Component,
                                       53: migration53Component,
                                       54: migration54Component,
                                       55: migration55Component,
                                       56: migration56Component,
                                       57: migration57Component,
                                       58: migration58Component,
                                       60: migration60Component,
                                       61: migration61Component,
                                       62: migration62Component,
                                       63: migration63Component,
                                       64: migration64Component,
                                       65: migration65Component,
                                       66: migration66Component,
                                       67: migration67Component
                                     })

  // Migration components
  property Component migration27Component: Migration27 {}
  property Component migration28Component: Migration28 {}
  property Component migration32Component: Migration32 {}
  property Component migration35Component: Migration35 {}
  property Component migration36Component: Migration36 {}
  property Component migration37Component: Migration37 {}
  property Component migration38Component: Migration38 {}
  property Component migration40Component: Migration40 {}
  property Component migration45Component: Migration45 {}
  property Component migration47Component: Migration47 {}
  property Component migration48Component: Migration48 {}
  property Component migration49Component: Migration49 {}
  property Component migration50Component: Migration50 {}
  property Component migration53Component: Migration53 {}
  property Component migration54Component: Migration54 {}
  property Component migration55Component: Migration55 {}
  property Component migration56Component: Migration56 {}
  property Component migration57Component: Migration57 {}
  property Component migration58Component: Migration58 {}
  property Component migration60Component: Migration60 {}
  property Component migration61Component: Migration61 {}
  property Component migration62Component: Migration62 {}
  property Component migration63Component: Migration63 {}
  property Component migration64Component: Migration64 {}
  property Component migration65Component: Migration65 {}
  property Component migration66Component: Migration66 {}
  property Component migration67Component: Migration67 {}
}
