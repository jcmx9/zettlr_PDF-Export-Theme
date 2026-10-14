---
title: "${1:Titel}"           # Titelblock, Kopfzeile, PDF-Titel
subtitle: "$2"                # unter dem Titel
client: "$3"                  # klein über dem Titel
author: "$4"                  # „Datum · Autor“; mehrere: [Anna, Ben]
date: ${5:$CURRENT_YEAR-$CURRENT_MONTH-$CURRENT_DATE}  # leer: kein Datum
isodate_praefix: ${6:true}    # ISO-Datum vor dem Dateinamen
lang: ${7:de}                 # de oder en
toc: ${8:auto}                # Inhaltsverzeichnis: auto, true, false
header: "$9"                  # fester Kopfzeilentext
print_filename: ${10:true}    # Angabe links in der Fußzeile
watermark: "$11"              # z. B. ENTWURF
logo: "$12"                   # Logo nur für dieses Dokument
logo-height: ${13:20mm}       # maximale Logohöhe, bis 25mm
embed_source: ${14:true}      # Markdown-Quelle ins PDF einbetten
hard_breaks: ${15:false}      # jede Zeile bleibt eine Zeile
---

$0
