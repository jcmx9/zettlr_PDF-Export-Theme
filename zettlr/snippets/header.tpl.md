---
# Alle Felder für den PDF-Export "Source PDF". Leere Felder werden ignoriert.
client: "${1:Kunde}"  # Kunde oder Firma: über dem Titel und in der Fußzeile
title: "${2:Titel}"  # Titel des Dokuments; "#" im Text sind Abschnitte
subtitle: "$3"  # Untertitel unter dem Titel
date: $CURRENT_DATE.$CURRENT_MONTH.$CURRENT_YEAR  # leer lassen = Exportdatum
author: $4  # Autor, steht neben dem Datum
logo: $5  # Bild neben dem Titel, Pfad relativ zur Notiz, z. B. logo.png
logo-height: ${6:20mm}  # maximale Logohöhe, Standard 20mm
lang: ${7:de}  # de oder en: Beschriftungen und Silbentrennung
---

$0
