# Konzept: Bajies Imbiss (Arbeitstitel) – Stand 2026-11-17

**Satz für die Steam-Seite:** Bajie kocht sich durch die Reise nach Westen: Hungrige Geister, Tiere und Dämonen werden nicht besiegt, sondern satt gemacht und zu Stammgästen.

**Vorbild für den Rhythmus:** *Dave the Diver* – Tag = Zutaten holen, Abend = Imbiss führen. Cozy, gewaltfrei, mit Slapstick und Humor (Mönch schimpft, Bajie nascht mit).

## Spielablauf
- **Abend (Bajie, der Kern):** Imbissstand an einem Bergpass. Bajie kocht (läuft auch ohne Eingriff weiter, Idle), Gäste kommen, jeder hat Geschmack, Geduld und Vorgeschichte. Passendes Gericht = zufriedener Gast, mit der Zeit **Stammgast** (bringt Zutaten, schaltet Rezepte frei, hilft am Stand). Bajie isst einen Teil jedes Gerichts selbst (Upgrade begrenzt es).
- **Tag (Wukong):** Ausflüge für Zutaten. Anfangs eine **Auswahl-Karte** (Wukong losschicken, nach einigen Minuten kommt er mit Zutaten zurück), später echte kleine Ausflüge (Pfirsiche pflücken, angeln, Kräuter finden) mit Bewegung.
- **Fortschritt:** Der Stand zieht mit der Reise von Ort zu Ort (die sieben Welten als Kulisse). Spielstand, Offline-Fortschritt.
- **Zu zweit (später):** Einer Wukong (Tag), einer Bajie (Abend). Allein spielt man beide nacheinander.
- **Mönch:** Kritiker/Kommentator; seine **Geduld**-Anzeige wird zur Wartezeit-Anzeige der Gäste.

## Regeln
- Gewaltfrei und respektvoll. Kein Buddha als Objekt. Nichts aus Black Myth: Wukong, nichts aus Dave the Diver kopieren (nur das Prinzip Tag/Abend), keine erkennbaren Ghibli-Figuren (z. B. weiße gesichtslose Geister).
- KI-Inhalte auf der Steam-Seite angeben; Nutzungsrechte der Bild-/Modell-Dienste vor dem Verkauf prüfen.

## Technik
- Godot 4.7, GDScript, Spielwerte als Resources (`scenes/diner/data/*.tres`, erzeugt von `tools/gen_diner_data.py`), Logik getrennt von der Darstellung (`scripts/diner/`), damit 2D oder 3D später darübergelegt werden kann.
- **Darstellung (offen):** 2D-Bilderbuch-Stil (ChatGPT-Bild getestet, sieht sehr gut aus) oder 3D-Figuren. Entscheidung nach dem Stil-Test mit 5 freigestellten Einzelbildern (Bajie, 3 Gäste, Stand).

## Bauplan
1. **Kern ohne Grafik** (Daten, Gäste, Rezepte, Kochen, Münzen, Stammgäste, Spielstand, Offline-Fortschritt) mit einfacher Test-Oberfläche. **← hier sind wir**
2. Darstellung (2D oder 3D), erste Szene mit Stand, Bajie und Gästen.
3. Tag-Karte: Wukong auf Ausflug schicken.
4. Mehrere Orte (Welten), mehr Gäste, Erfolge, Musik, Demo.
5. Echte Tag-Ausflüge mit Bewegung, Koop.
