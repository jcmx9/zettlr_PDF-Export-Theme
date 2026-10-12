---
# Kopfdaten für den PDF-Export "Source PDF". Leere Felder werden ignoriert.
client: ${1:Kunde}  # Kunde oder Firma: über dem Titel und in der Fußzeile
date: $CURRENT_DATE.$CURRENT_MONTH.$CURRENT_YEAR  # leer lassen = Exportdatum
subtitle: $2  # Untertitel unter dem Titel
author: $3  # Autor, steht neben dem Datum
logo: $4  # Bild neben dem Titel, Pfad relativ zur Notiz, z. B. logo.png
logo-height: ${5:20mm}  # maximale Logohöhe, Standard 20mm
next: $6  # nächster Termin, steht am Ende des PDFs
lang: ${7:de}  # de oder en: Beschriftungen und Silbentrennung
---

# ${8:Titel}

$0
