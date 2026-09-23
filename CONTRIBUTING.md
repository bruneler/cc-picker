# Contributing to cc-picker

Danke für dein Interesse! Ein paar kurze Hinweise:

## Bug melden / Feature vorschlagen

Bitte als [Issue](../../issues) mit:
- verwendete Distro/Shell/Terminal-Emulator
- Ausgabe von `bash --version`, `zenity --version` (falls installiert)
- Schritte zum Reproduzieren

## Pull Requests

1. Fork erstellen, Branch von `main` abzweigen
2. Änderungen so klein und fokussiert wie möglich halten
3. Skript mit `bash -n cc-picker.sh` auf Syntaxfehler prüfen und manuell testen
4. Keine neuen hartcodierten Pfade/Benutzernamen einführen — alles, was
   system-/nutzerspezifisch ist, gehört über eine `CC_PICKER_*`-Umgebungs-
   variable mit sinnvollem automatischem Fallback

## Stil

- Reines POSIX-nahes Bash, keine Abhängigkeit von Bashisms vermeiden, die
  nicht nötig sind
- Kommentare auf Deutsch oder Englisch sind beide ok, aber innerhalb einer
  Datei bitte konsistent bleiben

## Verhaltenskodex

Sei freundlich und respektvoll. Das war's.
