# Testliste – Bajies Imbiss

## 1. Spielkern ohne Grafik (17.11.)
Öffne das Projekt in Godot (**Neues Projekt: Ordner `bajies-imbiss` im Godot-Startfenster mit „Importieren“ öffnen**), warte auf den Import (Übersetzungen werden eingelesen) und starte mit **F5** (die Hauptszene ist `scenes/diner/diner_debug.tscn`).
1. Erscheinen nach einigen Sekunden **Gäste** (Dorfbewohner) mit 👍/👎-Geschmack und Wartezeit ⏳? Siehst du links, was Bajie gerade kocht?
2. **Selbst wählen:** Klicke bei einem Gast auf ein Gericht (Knöpfe unter dem Gast). Bezahlt er mehr, als wenn Bajie nach ~3 s selbst wählt? (Münzen oben.)
3. **Markt:** Kaufe Zutaten. Geht der Vorrat nach unten, wenn Bajie kocht? Bleibt nichts hängen, wenn Zutaten fehlen (Gast wartet, geht irgendwann)?
4. **Wukongs Ausflug:** Schicke ihn los (z. B. Reisterrassen, 60 s). Kommt er zurück, mit Meldung und neuen Zutaten? **Schließe das Spiel**, während er unterwegs ist, und starte neu: Ist er danach zurück bzw. läuft die Zeit weiter?
5. **Stammgäste:** Mit dem Knopf „Test: Tempo x20“ geht es schnell. Wird ein Gast nach einigen glücklichen Besuchen Stammgast („… ist jetzt Stammgast!“), gibt es ein neues Rezept und Geschenke?
6. **Verbesserungen:** Kaufen sie sich, wirken sie (mehr Plätze, schnellerer Herd)?
7. **Offline:** Spiel kurz, schließe, warte 1–2 Minuten, starte neu: Meldung „Während du weg warst: … Gäste, +… Münzen“?
8. Fühlt sich die Mischung (selbst wählen vs. Bajie wählt) gut an? Zu schnell/zu langsam? Zu großzügig/zu geizig? (Zahlen stehen als `@export` an `DinerGame`.)
Fehlermeldungen aus der Godot-Ausgabe bitte mitschicken. Spielstand liegt in `user://diner.cfg` (löschen = neu anfangen).

## 2. Spielbildschirm (2D, Platzhalter) – 17.11.
Starte mit **F5** (Hauptszene `scenes/diner/diner_main.tscn`). Hol vorher die Änderung per Fetch/Pull.
1. Siehst du **Bajies Stand** links (🐷), oben Münzen und Stammgäste, unten Vorrat und die Reiter **Markt / Wukongs Tagesausflüge / Verbesserungen**?
2. **Gäste:** Kommt nach einigen Sekunden ein Gast auf einen Hocker rechts (kurze Pop-in-Animation)? Hat er Geschmack (👍/👎) und einen **Geduld-Balken** (grün → gelb → rot)?
3. **Gericht wählen:** Die Knöpfe unter dem Gast sind **grün** (liebt es), **gelb-grün**, **normal** oder **rot** (mag er nicht). Ist das verständlich? Wackelt Bajie beim Kochen, läuft ein Balken, steigt Dampf auf?
4. **Münzen:** Steigt beim Bezahlen ein goldenes „+Zahl“ auf? Kommen Meldungen oben (Stammgast, neues Rezept, Wukong zurück)?
5. **Reiter:** Markt kaufen, Wukong losschicken (Balken läuft), Verbesserung kaufen. Passt die Höhe des Bildes (nichts abgeschnitten, 1280 × 720 und im Vollbild)?
6. Wie sieht es aus: zu leer, zu voll, was stört? (Das ist nur der Rohbau, die Bilder kommen noch.)
Fehlermeldungen aus dem Godot-Ausgabefenster bitte mitschicken.

