# Automatische Website-Veröffentlichung

Nach erfolgreichem `lint`-Workflow auf `main` holt der Server den geprüften
Commit selbst von GitHub ab (etwa alle fünf Minuten). PRs und andere Zweige
werden nicht veröffentlicht. Die Website-Dateien werden auf dem Server nicht
als Programme ausgeführt. Ein SSH-Zugang aus GitHub Actions ist nicht nötig.

Konfiguration und Betrieb liegen in `bruenus-infrastructure`, Entscheidung 0015
und `ansible/playbooks/cc-picker-pull.yml`. GitHub prüft den Quellstand;
erfolgreiche CI allein bestätigt noch keine Veröffentlichung. Der tatsächlich
aktive Commit steht unter <https://cc-picker.brue.nu/release-info.json>.

Bei fehlgeschlagener CI bleibt die bestehende Website online. Bei fehlerhafter
Übertragung oder HTTPS-Inhaltsprüfung wird kein fehlerhafter Release übernommen.
Ein neuer erfolgreicher Workflow auf `main` wird beim nächsten Abruf berücksichtigt.
Für Diagnose, erneuten Abruf oder Rückfall den Infrastruktur-Ablauf verwenden.
Der frühere SSH-Upload wurde wegen des privaten Serverzugangs abgelöst.
