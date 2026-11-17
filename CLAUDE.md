# CLAUDE.md – Bajies Imbiss (Arbeitstitel)

Diese Datei beschreibt das Projekt, die Regeln für die Zusammenarbeit und den Bauplan.
Lies sie zu Beginn jeder Sitzung vollständig. Wenn sich Entscheidungen ändern, aktualisiere diese Datei.

**Herkunft:** Dieses Projekt ist 2026-11-17 aus dem Spiel „Carry the Monk“ (Repo `cake-carriers`, Tragen-Spiel im Berg) hervorgegangen. Der Entwickler will an Carry the Monk vielleicht später weiterarbeiten, deshalb ist das hier ein **eigenes Projekt und Repo**. Aus dem alten Projekt stammen: Schrift mit chinesischen Zeichen, KI-Modelle (Wukong mit Skelett, Bajie, Mönch), Arbeitsweise.

---

## 1. Über den Entwickler (wichtig für deinen Arbeitsstil)

- Er hat **wenig Programmiererfahrung**. Erkläre kurz und verständlich auf **Deutsch**, was du tust und warum.
- Claude baut **am Stück** größere Schritte fertig (mit mehreren kleinen Commits); getestet und repariert wird danach gemeinsam anhand der Testliste `docs/TESTLISTE.md`.
- Sag nach jedem Schritt genau, **was er testen soll**.
- Wenn er im Godot-Editor etwas von Hand machen muss: **Klick-für-Klick-Anleitung**.
- Wenn etwas unklar ist oder es mehrere sinnvolle Wege gibt: **fragen**, statt zu raten. Bei Grafik-Wünschen vorher klären, ob Shader, Farben, Formen oder Figuren gemeint sind.
- Wenn etwas kaputtgeht: Ursache in einfachen Worten erklären, bevor du es reparierst.
- Claude kann Godot in der Cloud-Sitzung **nicht starten**; Tests macht der Entwickler. Skripte prüfst du vor jedem Push mit gdtoolkit (`gdparse`) und `tools/check_locals.py` (doppelte Variablen/Member).
- Der Entwickler holt Änderungen mit **GitHub Desktop** (Fetch/Pull).
- **F6 startet die gerade im Editor geöffnete Szene**, F5 die Hauptszene (`diner_main.tscn`). Das bei Anleitungen immer dazusagen.

---

## 2. Das Spiel in einem Satz

**Bajie kocht sich durch die Reise nach Westen: Hungrige Geister, Tiere und Dämonen werden nicht besiegt, sondern satt gemacht und zu Stammgästen.** Cozy-Idle mit Slapstick, Rhythmus wie *Dave the Diver*: **Abend = Bajie führt den Imbiss**, **Tag = Wukong holt Zutaten** (erst als Auswahl-Karte, später echte Ausflüge). Details: `docs/KONZEPT_IMBISS.md`.

**Regeln:** Gewaltfrei und respektvoll, **kein Buddha als Objekt**. Der Roman „Die Reise nach Westen“ ist gemeinfrei, **nichts** aus „Black Myth: Wukong“ übernehmen, nichts aus *Dave the Diver* kopieren (nur das Prinzip), keine erkennbaren Ghibli-Figuren. KI-Inhalte auf der Steam-Seite angeben, Nutzungsrechte der Bild-/Modell-Dienste vor dem Verkauf prüfen. Spielname vor der Steam-Seite in DPMA/EUIPO prüfen.

**Darstellung (offen):** 2D-Bilderbuch-Stil (ChatGPT-Testbild sah sehr gut aus) oder 3D-Figuren in bemalter Szene. Entscheidung nach dem Stil-Test mit fünf freigestellten Einzelbildern.

---

## 3. Technik-Stack

| Bereich | Wahl |
|---|---|
| Engine | Godot **4.7.2** (Standard), Forward+ |
| Sprache | GDScript, statische Typen (`var speed: float = 5.0`) |
| Steam | GodotSteam (später), Steam-App-ID 480 zum Testen |
| Versionsverwaltung | Git, GitHub (privat), Entwickler nutzt GitHub Desktop |

---

## 4. Projektstruktur

```
res://
├── scripts/diner/      # Spiellogik ohne Grafik (DinerGame, DinerCatalog, *_def.gd Datenklassen)
├── scenes/diner/       # Spielbildschirm (diner_main), Test-Oberfläche (diner_debug), Daten (data/*.tres, erzeugt von tools/gen_diner_data.py)
├── assets/             # fonts (mit chinesischen Zeichen), models/ki_modelle (KI-Modelle), später Bilder/Audio
├── localization/       # translations.csv (en, de, zh_CN)
├── docs/               # Konzept, Testliste (nicht exportiert)
└── tools/              # Python-Skripte, von Godot ignoriert (.gdignore)
```

---

## 5. Code-Regeln

- **Code, Variablen, Funktionen, Dateinamen und Code-Kommentare auf Englisch.** Erklärungen an den Entwickler auf Deutsch.
- `snake_case` für Variablen, Funktionen, Dateien; `PascalCase` für Klassen und Node-Namen.
- **Statische Typen** überall, wo möglich. Keine Division Ganzzahl / Ganzzahl (Godot warnt): `floori(x / 60.0)` o. ä.
- **Keine Texte direkt im Code.** Alle sichtbaren Texte über Übersetzungsschlüssel (`tr("DINER_TITLE")`) aus `localization/translations.csv` (Deutsch, Englisch, vereinfachtes Chinesisch). **Neue Schlüssel in `tools/gen_diner_data.py` eintragen** (hängt fehlende Zeilen an die CSV an). Neue chinesische Zeichen: Schrift prüfen (`assets/fonts/CakeCarriersSans.ttf` enthält ~4 300 Zeichen; Skript `make_font.py` lag im alten Projekt).
- **Spielwerte nicht hart codieren:** `@export`-Variablen oder Resource-Dateien (`scenes/diner/data`), damit sie im Editor anpassbar sind.
- Logik (`scripts/diner`) und Darstellung (Szenen) **getrennt** halten: die Darstellung zeigt nur den Zustand von `DinerGame` und ruft dessen Funktionen auf.
- In handgeschriebenen `.tscn`-Dateien brauchen exportierte Node-Verweise `node_paths=PackedStringArray(...)`; Reihenfolge der Abschnitte: ext_resource, sub_resource, Nodes.
- GDScript verbietet doppelte Namen innerhalb einer Funktion (auch Schleifenvariable vs. Variable) und doppelte Klassen-Member – `check_locals.py` findet das.
- Nach jedem funktionierenden Schritt: `git commit` mit kurzer Nachricht.

---

## 6. Kernsysteme (Stand 2026-11-17: Spielkern getestet, Spielbildschirm gebaut)

- **Daten** (`*_def.gd`, `.tres`): 8 Zutaten, 8 Gerichte (Geschmacks-Tags sweet/savory/hot/cold/spicy/hearty/light/soft/crunchy), 6 Gäste (Likes/Dislikes, Geduld, erscheinen nach N bedienten Portionen, Stammgast nach glücklichen Besuchen, Geschenke), 4 Tagesausflüge, 4 Verbesserungen.
- **`DinerGame`**: Gäste kommen und warten, der Spieler wählt ein Gericht (Bonus ×1,25) oder Bajie wählt nach 3 s selbst, Kochen, Bezahlung nach Geschmack (`taste_score`: gemochte Tags − 2 × ungemochte), Bajie nascht, Stammgäste schalten Rezepte frei, Markt, Verbesserungen, Wukongs Ausflüge in Echtzeit (laufen auch bei geschlossenem Spiel), Spielstand `user://diner.cfg`, Offline-Fortschritt (max. 12 h, Schritte à 2 s).
- **Test-Oberfläche** `scenes/diner/diner_debug.tscn` (F6): reine Steuerung ohne Grafik. **Spielbildschirm** `scenes/diner/diner_main.tscn` (Hauptszene, F5, 2D mit Platzhaltern): Bajies Stand links (wackelt beim Kochen, Fortschrittsbalken, Dampf), Gäste auf Hockern rechts (Karte mit Geschmack, Geduld-Balken, Gericht-Knöpfe grün/gelb/rot nach Geschmack, Pop-in-Animation), unten Vorrat + Reiter Markt / Wukongs Ausflüge / Verbesserungen, Meldungen oben, „+Münzen“ steigen auf. Bilder werden über Dateinamen ersetzt (`assets/art/README.md`). Knopf „Test: Tempo ×“ beschleunigt.

---

## 7. Bauplan

1. **Spielkern ohne Grafik** ✔ gebaut und vom Entwickler getestet („geht alles“, 2026-11-17).
2. Darstellung (2D oder 3D): erste Szene mit Stand, Bajie und Gästen, Hauptmenü.
3. Tag-Karte: Wukong auf Ausflug schicken (Darstellung, Rückkehr-Szene).
4. Mehrere Orte (die sieben Welten aus Carry the Monk als Kulisse), mehr Gäste/Rezepte, Musik, Erfolge, Demo.
5. Echte Tag-Ausflüge mit Bewegung, Koop (Wukong + Bajie), Steam-Anbindung, Veröffentlichung.

---

## 8. Fortschritt

- [x] Schritt 1 – Spielkern ohne Grafik (getestet 2026-11-17)
- [ ] Schritt 2 – Darstellung (2D-Bildschirm mit Platzhaltern gebaut, ungetestet; echte Bilder stehen aus)
- [ ] Schritt 3 – Tag-Karte
- [ ] Schritt 4 – Orte, Inhalte, Musik, Erfolge, Demo
- [ ] Schritt 5 – Ausflüge mit Bewegung, Koop, Steam

### Entscheidungen-Log

- 2026-11-17: Neue Richtung „Bajies Imbiss“ statt Tragen-Spiel (Gründe: Tragen-Spiele gibt es genug; Cozy-Idle wächst stark auf Steam, aber die Konkurrenz auch → eigener Haken nötig: Dämonen bekochen statt bekämpfen, Tag/Abend-Rhythmus). Der Turm bleibt im Repo `cake-carriers` (Zweig `turm-archiv`).
- 2026-11-17: Eigenes Projekt/Repo, damit Carry the Monk unverändert weiterlebt. Übernommen: Schrift, KI-Modelle (`assets/models/ki_modelle/game`), Arbeitsweise. Nicht übernommen: Turm, Physik, Netzwerk, Menü-Design (kann später aus dem alten Repo geholt werden).
- 2026-11-17: Spielkern gebaut (siehe Abschnitt 6). Offene Entscheidung: 2D-Bilderbuch oder 3D (Stil-Test mit fünf Einzelbildern aus ChatGPT steht aus).
- Aus dem alten Projekt gelernt: KI-Modelle (Tripo) mit Mixamo-Skelett lassen sich in Godot per Code animieren (`SkeletonFigure` im alten Repo, `scenes/player/skeleton_figure.gd`); Schrittlänge für Menschenmodelle ≈ 3 m pro vollem Schritt, sonst „zittern“ die Gliedmaßen. KI-Modell-Originale (je 60 MB) liegen nur im alten Repo (`tools/ki_originals`).
- 2026-11-17: Spielkern vom Entwickler getestet: „geht alles“. Erste 2D-Darstellung `diner_main` mit Emoji-Platzhaltern gebaut (Entscheidung 2D vorläufig, weil das ChatGPT-Testbild im Bilderbuch-Stil sehr gut aussah und 2D weniger Aufwand ist; 3D bleibt möglich, die Logik ist getrennt). Bilder per Dateiname austauschbar (`assets/art/`). Hauptszene jetzt `diner_main.tscn`.
