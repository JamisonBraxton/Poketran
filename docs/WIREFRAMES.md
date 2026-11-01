# Pokétran annotated screen flows — design reference

These are textual planning sketches, **not** dated evidence of instructor-approved wireframes or an executed user test.

## 1. Teams / dashboard

```text
[ My teams                           (+) ]
[ trainer message / create team          ]
[ teams ] [ pokemon ] [ completed ]
[ search team / goal / region            ]
[ All ] [ Planning ] [ Training ] [ Done ]
[ team card: name, region, status        ]
[ team goal, progress, primary types     ]
[ new team FAB                           ]
```

Empty: show create action. Error: retry view. Team card opens team details. On wide screens a left navigation rail replaces bottom navigation.

## 2. Team editor / Pokémon editor

```text
[ Team name * ]    [ Region / theme * ]
[ Team goal *                           ]
[ Save team ]

[ Species * ] [ Nickname ] [ Type dropdown ]
[ Role ] [ Level 1–100 ]
[ Training progress slider 0..100 ]
[ Strategy notes ] [ Save Pokémon ]
```

Validation blocks incomplete/invalid records. Editors dispose their controllers. Save is disabled during an in-flight write.

## 3. Team detail & activity

```text
[ Team identity / goal / current status ]
[ Average progress          -- % ]
[ Start / Finish / Reset workflow ]
[ Roster up to six / add member ]
[ Member cards: edit, remove, progress ]
[ Local team coach ]
[ Baseline recommendation ]
[ Ranked suggestion + reason ]
[ Apply ] [ Not now ] [ Reveal ]
```

Confirmation before destructive actions. A completed team is locked until reset. Coach controls keep the user in charge of changes.

## 4. Insights / history

```text
[ Average training ] [ Fully trained ] [ Completed ]
[ Primary-type distribution bars                ]
[ Completed teams                               ]
[ Dated recent activity                         ]
```

All counts and percentages derive from saved SQLite values, not fabricated live services.

## 5. Settings

```text
[ Dark mode toggle ]
[ Show local coach toggle ]
[ Create demo team ]
[ Offline / data storage explanation ]
[ About Pokétran ]
```

Preferences use SharedPreferences; account and internet access are not required. Landscape layout and accessibility should be checked using real devices/emulators.
