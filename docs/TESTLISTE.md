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
