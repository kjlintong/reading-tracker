import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class SDe extends S {
  SDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Readnest';

  @override
  String get navShelf => 'Shelf';

  @override
  String get addBookSheetTitle => 'Ein Buch hinzufügen';

  @override
  String get addBookManualTitle => 'Manuell eingeben';

  @override
  String get addBookManualDesc => 'Geben Sie den Titel ein und schreiben Sie selbst — kein Konto oder Datei erforderlich.';

  @override
  String get navStats => 'Statistik';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get supportDev => 'Unterstütze den Entwickler';

  @override
  String get supportDevDesc => 'Jede Funktion ist kostenlos nutzbar, ohne Werbung und ohne In-App-Käufe. Wenn die App Ihnen beim Lesen hilft, können Sie mir einen Kaffee kaufen — völlig optional, und nichts ändert sich so oder so.';

  @override
  String get openTipPage => 'Kaufen Sie mir einen Kaffee · Ko-fi';

  @override
  String get openTipDomestic => 'Unterstützung · Afdian (China)';

  @override
  String get openTipForeign => 'Unterstützung · Ko-fi (International)';

  @override
  String get about => 'Über';

  @override
  String get aboutDesc => 'Entwicklerdetails und verwandte Links.';

  @override
  String get appIntroPage => 'Über diese App';

  @override
  String get developerHomepage => 'Website für Entwickler';

  @override
  String get privacyPolicy => 'Datenschutz';

  @override
  String get reportDeleteConfirm => 'Diesen Bericht löschen? Dies kann nicht rückgängig gemacht werden.';

  @override
  String get reportDelete => 'Löschen';

  @override
  String appVersionLabel({required String version}) {
    return 'Version @@PH0@@';
  }

  @override
  String get goodreadsImport => 'Goodreads / Library CSV-Import';

  @override
  String get goodreadsImportDesc => 'Importieren Sie eine Bibliotheks-CSV, die aus Goodreads und ähnlichen Diensten exportiert wurde (Titel, Autor, Bewertung, Regalstatus).';

  @override
  String get goodreadsImportEmpty => 'Keine \"Titel\" -Spalte in der CSV gefunden';

  @override
  String get openLibraryImport => 'Bibliotheks- / Google Books-Suchimport öffnen';

  @override
  String get openLibraryImportDesc => 'Öffentliche Kataloge nach Titel oder ISBN durchsuchen und mit angereicherten Metadaten (Autor, Verlag, Cover) importieren.';

  @override
  String get catalogSearchTitle => 'Katalog &amp; Suche';

  @override
  String get catalogSearchHint => 'Geben Sie einen Titel oder eine ISBN ein';

  @override
  String get catalogSearchAction => 'Suche';

  @override
  String get catalogSearchInitial => 'Öffentliche Kataloge in Google Books und Open Library durchsuchen. Ausgewählte Bücher werden mit Autor, Verlag, Umschlag und Seitenzahl hinzugefügt.';

  @override
  String get catalogNoResult => 'Keine passenden Bücher gefunden — versuchen Sie es mit einem anderen Schlüsselwort.';

  @override
  String catalogSearchFailed({required Object e}) {
    return 'Suche fehlgeschlagen: @@PH0@@';
  }

  @override
  String get imageUploadConsentTitle => 'Screenshot des Bücherregals an den KI-Dienst senden?';

  @override
  String get imageUploadConsentBody => 'Damit die KI Ihren gesamten Regal-Screenshot lesen kann, wird dieses Bild an den KI-Dienst gesendet, den Sie in den Einstellungen konfiguriert haben (ein Dritter). Es enthält keinen Notiztext, aber Buchtitel und Einbände. Diesen Upload zulassen?';

  @override
  String get allow => 'Erlauben';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get s_178329ba => 'WeRead-API-Schlüssel nicht konfiguriert';

  @override
  String get s_dd204792 => 'G';

  @override
  String get s_ad86a5ca => 'LLM-API-Schlüssel nicht konfiguriert';

  @override
  String get s_8a853cbe => 'Füllen Sie es unter Einstellungen → LLM aus';

  @override
  String get s_7d704c88 => 'Angewählter Typ:';

  @override
  String get s_4508cedd => 'Tippe auf „Modelle abrufen“, um eines aus der verfügbaren Liste deines Kontos auszuwählen.';

  @override
  String get s_1b5140db => 'Nur gültige json ausgeben — kein erklärender Text, keine Markdown-Codeblöcke.';

  @override
  String s_c94c96fc({required Object apiError}) {
    return 'Der Modelldienst hat einen Fehler zurückgegeben: @@PH0@@';
  }

  @override
  String s_3b43c7c4({required Object head}) {
    return 'RAW-Antwort: @@PH0 @ @@@NL @ @ Überprüfen Sie zuerst die Adresse und den Modellnamen unter Einstellungen → LLM mit \"Modelle abrufen\". Auch ein unbezahltes Guthaben oder ein Modell, das nicht aktiviert ist, wird hier landen.';
  }

  @override
  String get s_231cf54a => 'Die Antwort des Modells konnte nicht analysiert werden';

  @override
  String s_90747d4c({required Object head}) {
    return 'RAW-Antwort: @ @ PH0 @ @@@ NL @ @Das Gateway gab eine nicht standardmäßige Struktur zurück. Versuchen Sie es mit einem anderen Modell oder Protokoll. Wenn Sie uns diesen Rohtext senden, können wir auch Unterstützung dafür hinzufügen.';
  }

  @override
  String get s_9d9714af => 'Die Nachricht ist leer und kann nicht gesendet werden';

  @override
  String get s_f44ff25c => 'Das Modell hat diese Anfrage abgelehnt';

  @override
  String get s_cad5bf6e => 'Der Inhalt wurde als unangemessen gekennzeichnet. Formulieren Sie es um oder versuchen Sie es mit einem anderen Modell.';

  @override
  String get s_0f7b54a1 => 'API Key ist nicht konfiguriert.';

  @override
  String get s_345e9547 => 'Geben Sie den Schlüssel ein, bevor Sie Modelle abrufen';

  @override
  String get s_3a5d4cca => 'Der Dienst hat eine leere Modellliste zurückgegeben';

  @override
  String s_cea80527({required Object apiError}) {
    return 'Modelle konnten nicht abgerufen werden: @@PH0@@';
  }

  @override
  String get s_4674d953 => 'Sie können den Modellnamen manuell eingeben';

  @override
  String s_749fc40e({required Object raw}) {
    return 'RAW-Antwort: @@PH0@@';
  }

  @override
  String get s_8add575d => 'Dieser Dienst bietet keinen Endpunkt für die Modellliste (404)';

  @override
  String get s_53fb436d => 'Geben Sie einfach den Modellnamen ein, z. B. deepseek-chat / claude-sonnet-5';

  @override
  String get s_438a5695 => 'Kein Modellname eingegeben';

  @override
  String get s_1da90e20 => 'Tippen Sie zuerst auf „Modelle abrufen“ oder geben Sie eine ein';

  @override
  String get s_2abb6b8a => 'Antwort mit zwei Zeichen: OK';

  @override
  String get s_ad736a74 => 'Sie sind Buchkatalogisierungsassistent. Nur json ausgeben, keine Erklärungen.';

  @override
  String s_4304f539({required Object author, required Object title, required Object vocab}) {
    return 'Bekannter Titel \"@@PH0@@\"@@PH1@@.\nBitte füllen Sie Folgendes aus:@ @ NL @ @- categoryPrimary: must be one of: @ @ PH2 @@@ @ NL @ @- description: a neutral 80–150 character summary of the book\'s content, stating facts without evaluation@ @ NL @ @- tags: 3–5 keyword tags\n- authors: an array if the author can be determined, otherwise an empty array\nOutput format: @@PH3@@';
  }

  @override
  String get s_cbe8aa6b => 'Sie sind ein Leseprofilanalytiker. Nur json ausgeben, keine Erklärungen.';

  @override
  String s_3864d3b4({required Object summary}) {
    return 'Here is my reading data (JSON):\n$summary\n\nGive me 10 personality tags, each 2–6 words, like the nicknames a book club gives people.\nRequirements:\n1. Every tag must be supported by the data above — don\'t make things up\n2. Style reference: Learning Is My Joy / In Tune with Nature / Beauty Above All / Erudite Across the Ages / The Lonely Sage\n3. Don\'t use empty words like \"reader\", \"enthusiast\" or \"aficionado\"\n4. No explanations, no markdown code blocks\nOutput format: {\"tags\":[\"tag1\",\"tag2\"]}';
  }

  @override
  String get s_99acf9a4 => 'Sie sind ein persönlicher Leseberater. Analysieren Sie die Daten objektiv, vermeiden Sie vages Lob und weisen Sie auf die strukturellen Probleme hin, die übersehen werden.';

  @override
  String s_46e5ebef({required Object host}) {
    return 'Zeitüberschreitung der Verbindung: @ @ PH0 @@ konnte nicht innerhalb von 20 Sekunden erreicht werden';
  }

  @override
  String get s_3c836870 => 'Überprüfen Sie das Netzwerk oder die Basis-URL; einige ausländische Dienste benötigen einen Proxy vom chinesischen Festland';

  @override
  String get s_84264711 => 'Zeitüberschreitung';

  @override
  String get s_225ed2e1 => 'Die Upstream-Verbindung ist instabil; versuchen Sie es später erneut';

  @override
  String get s_b265cf86 => 'Zeitüberschreitung der Antwort: Das Modell reagierte nicht innerhalb von 180 Sekunden';

  @override
  String get s_cc12eea3 => 'Probieren Sie ein schnelleres Modell aus oder verkürzen Sie den Berichtszeitraum und versuchen Sie es erneut';

  @override
  String get s_d711b259 => 'Validierung des HTTPS-Zertifikats fehlgeschlagen';

  @override
  String get s_4722b0f8 => 'Wechseln Sie für einen selbst gehosteten oder Intranet-Endpunkt zu einem vertrauenswürdigen Zertifikat';

  @override
  String get s_07a2b144 => 'Antrag storniert';

  @override
  String s_8ae0b0e4({required Object host}) {
    return 'Netzwerk nicht erreichbar: kann keine Verbindung zu @@PH0@@ herstellen';
  }

  @override
  String get s_0a9425b8 => '① Überprüfen Sie das Netzwerk des Telefons; ② stellen Sie sicher, dass die Basis-URL vollständig ist (einschließlich /v1); ③ überprüfen Sie, ob der Dienst einen Proxy benötigt; ④ ein lokaler Dienst (Ollama) ist vom Telefon aus nicht über den lokalen Host des Computers erreichbar';

  @override
  String get s_554d5235 => 'Die Verbindung wurde unterbrochen';

  @override
  String get s_020fe21a => 'Normalerweise eine blockierte Netzwerkberechtigung oder ein Proxy oder eine Firewall, die die Verbindung abbricht; Klartext-HTTP wird möglicherweise auch nicht unterstützt. Versuchen Sie es später erneut oder wechseln Sie das Netzwerk.';

  @override
  String get s_dfde23b1 => 'Netzwerkanfrage fehlgeschlagen. ';

  @override
  String get s_2ae4f5fe => 'Überprüfen Sie die Basis-URL, die Proxy-Einstellungen und das Netzwerk';

  @override
  String s_d6ac5952({required Object detail}) {
    return 'Anfrage abgelehnt (400)@@PH0@@';
  }

  @override
  String get s_cb980461 => 'Höchstwahrscheinlich ist der Modellname falsch oder das Modell unterstützt die aktuellen Parameter nicht';

  @override
  String s_d9775d22({required Object detail}) {
    return 'Authentifizierung fehlgeschlagen (401)@@PH0@@';
  }

  @override
  String get s_c4198142 => 'Der API-Schlüssel ist ungültig oder abgelaufen — kopieren Sie einen neuen';

  @override
  String get s_e06ab1cc => 'Unasureichender Kontostand';

  @override
  String s_05b3ec8b({required Object detail}) {
    return 'Keine Berechtigung (403)@@PH0@@';
  }

  @override
  String get s_f00f6ff2 => 'Der Schlüssel hat keine Berechtigung, dieses Modell aufzurufen, oder das Konto ist nicht verifiziert/aktiviert';

  @override
  String s_016f7576({required Object detail}) {
    return 'Endpunkt oder Modell nicht gefunden (404)@@PH0@@';
  }

  @override
  String get s_a8aa2c59 => 'Prüfen Sie, ob die Basis-URL bis /v1 ausgefüllt ist; verwenden Sie \"Modelle abrufen\", um den Modellnamen zu erhalten';

  @override
  String s_9688a257({required Object detail}) {
    return 'Ungültige Parameter (422)@@PH0@@';
  }

  @override
  String get s_1b3daaa3 => 'Preis begrenzt (429)';

  @override
  String get s_2a564df1 => 'Versuchen Sie es in Kürze erneut oder aktualisieren Sie Ihr Abo';

  @override
  String s_6627221e({required int? code}) {
    return 'Serverfehler (@@PH0@@)';
  }

  @override
  String get s_2fe391dd => 'Ein Problem auf der Gegenseite; versuchen Sie es später erneut';

  @override
  String s_679e6c2e({required Object code, required Object detail}) {
    return 'Anfrage fehlgeschlagen@@PH0@@@@PH1@@';
  }

  @override
  String get s_0cf0a499 => 'Leerer Antwortkörper';

  @override
  String get s_9ed7e745 => 'Netzwerkanforderung fehlgeschlagen. Überprüfen Sie das Netzwerk des Telefons und die Basis-URL unter Einstellungen → LLM.';

  @override
  String get s_2ad3b6ba => 'OpenAI-kompatibel';

  @override
  String get s_e2213e87 => 'Geben Sie die Basis-URL bis /v1 ein, z. B. https://api.deepseek.com/v1';

  @override
  String get s_17a4ba0f => 'Die Basis-URL lautet in der Regel https://api.anthropic.com (ohne /v1)';

  @override
  String get s_f1ea3335 => 'SenseNova';

  @override
  String get s_e522fe39 => 'Qwen';

  @override
  String get s_7e12f8b4 => 'Zhipu GLM';

  @override
  String get s_c3d30bc2 => 'Moonshot Kimi';

  @override
  String get s_8e941e27 => 'SiliconFlow';

  @override
  String get s_c800478c => 'Ollama (lokal)';

  @override
  String get s_0babfa89 => 'nicht leere Zeichenfolge';

  @override
  String get s_e74f752c => 'Lesetage sind Tage, die manuell als gelesen erfasst werden';

  @override
  String s_9ea3cbae({required Object year}) {
    return 'Lesezeit und -tage stammen aus der @@PH0@@ Jahresstatistik von WeRead (Ganzjahresbasis)';
  }

  @override
  String get s_f676228c => 'WeRead liefert nur Jahreszahlen, so dass Lesetage für diesen Bereich nicht genau angegeben werden können; die Zeit wird in Monatsgranularität aggregiert';

  @override
  String get s_06225788 => 'Nicht bewertet';

  @override
  String s_89cfaca8({required Object i}) {
    return '@@PH0@@ Sterne';
  }

  @override
  String get s_e7a2db51 => 'Zu jeder Zeit';

  @override
  String s_a87cfcc9({required Object y}) {
    return 'PH 0';
  }

  @override
  String s_62654321({required Object n}) {
    return 'Letzte @@PH0@@ Monate';
  }

  @override
  String get s_41f3af95 => 'Lesezeit und -tage werden in Monats-/Jahresgranularität aggregiert';

  @override
  String get s_e8a43314 => 'Starte dein nächstes Buch und diese Liste erhält ihre erste Nummer.';

  @override
  String get s_af03278c => 'Das Regal ist noch leer — hier beginnt jede Lesehistorie.';

  @override
  String s_f53eead8({required Object streak}) {
    return '@@PH0@@ aufeinanderfolgende Lesetage — der Rhythmus hat sich durchgesetzt.';
  }

  @override
  String s_ff1565a3({required Object streak}) {
    return 'Eine @@PH0@@-Tagessträhne — lass sie heute nicht kaputt gehen.';
  }

  @override
  String s_1736f17e({required Object streak}) {
    return '@@PH0@@ Tage hintereinander — eine Gewohnheit, die mehr wert ist als jede Leseliste.';
  }

  @override
  String s_9a3fb5e5({required Object finished}) {
    return '@@PH0@@ Bücher fertig — tausche Geschwindigkeit gegen Rhythmus und du gehst weiter.';
  }

  @override
  String s_9d430ad3({required Object finished}) {
    return '@@PH0@@ Bücher beendet. Schauen Sie sich ab und zu an, welche wirklich stecken geblieben sind.';
  }

  @override
  String s_597f7c05({required Object finished}) {
    return '@@PH0@@ Bücher, die auf dieser Strecke beendet wurden — jeder zählt.';
  }

  @override
  String s_1c87153f({required Object finished}) {
    return '@@PH0@@ Bücher abgeschlossen. Nimm eines, das du bereits als Nächstes begonnen hast.';
  }

  @override
  String s_41db17b9({required Object minutes}) {
    return '@@PH0@@ Minuten auf dieser Strecke lesen — machen Sie eine halbe Stunde zur täglichen Gewohnheit und das sind 180 Stunden pro Jahr.';
  }

  @override
  String s_6a57c553({required Object minutes}) {
    return '@@PH0@@ Minuten bereits protokolliert. Fügen Sie noch heute etwas hinzu?';
  }

  @override
  String get s_152a88d7 => 'Ihr Regal ist fertig — beginnen Sie die heutigen zehn Minuten mit einer leichten Kurzgeschichte.';

  @override
  String get s_795806c0 => 'Wählen Sie ein Buch aus, das Sie bereits begonnen haben — zehn Minuten zählen als Gewinn.';

  @override
  String get s_aa51bf46 => 'Sie müssen nicht viel auf einmal lesen — das Öffnen eines Buches zählt heute.';

  @override
  String get s_363c6a0c => 'Allgemein';

  @override
  String get s_420a7ac1 => 'Lernen ist meine Freude';

  @override
  String get s_bcd278a6 => 'Persönliches Wachstum';

  @override
  String s_3702d226({required Object cat, required Object pct}) {
    return '@@PH0@@ persönliche Wachstumsbücher · @@PH1@@';
  }

  @override
  String get s_6672b3fa => 'Romantisch und poetisch';

  @override
  String get s_d422d33c => 'Literatur';

  @override
  String s_40ba4ecb({required Object cat, required Object pct}) {
    return '@@PH0@@ Literaturbücher · @@PH1@@';
  }

  @override
  String get s_ea2eaec4 => 'Der einsame Weise';

  @override
  String get s_5da32671 => 'Philosophie';

  @override
  String s_0f80a135({required Object cat, required Object pct}) {
    return '@@PH0@@ Philosophiebücher · @@PH1@@';
  }

  @override
  String get s_111ec0f6 => 'Lehren aus der Geschichte ziehen';

  @override
  String get s_07f288e9 => 'Geschichte';

  @override
  String s_abeb8e3d({required Object cat, required Object pct}) {
    return '@@PH0@@ Geschichtsbücher · @@PH1@@';
  }

  @override
  String get s_5e336507 => 'Sieht nach innen';

  @override
  String get s_4307c7a8 => 'Psychologie';

  @override
  String s_cfce6d52({required Object cat, required Object pct}) {
    return '@@PH0@@ Psychologiebücher · @@PH1@@';
  }

  @override
  String get s_d5e26f37 => 'Tech-Elite';

  @override
  String get s_8612fa7f => 'Datenverarbeitung';

  @override
  String s_d6bdf44e({required Object cat, required Object pct}) {
    return '@@PH0@@ Computerbücher · @@PH1@@';
  }

  @override
  String get s_00dcb308 => 'Schönheit vor allem';

  @override
  String get s_b31e932c => 'Kunst';

  @override
  String s_aee18737({required Object cat, required Object pct}) {
    return '@@PH0@@ Kunstbücher · @@PH1@@';
  }

  @override
  String get s_2ddd554c => 'Rational und praktisch';

  @override
  String get s_56734d39 => 'Volkswirtschaftslehre';

  @override
  String get s_5974bf24 => 'Geschäft';

  @override
  String s_066faf9c({required Object cat, required Object toStringAsFixed}) {
    return '@@PH0@@ Wirtschaftsbücher · @@PH1@@%';
  }

  @override
  String get s_d574ffeb => 'Weltlich weise';

  @override
  String get s_086ac5bf => 'Sozialwissenschaften';

  @override
  String s_5a276724({required Object cat, required Object pct}) {
    return '@@PH0@@ sozialwissenschaftliche Bücher · @@PH1@@';
  }

  @override
  String get s_d81bab36 => 'Unersättlich neugierig';

  @override
  String get s_41fa5c70 => 'Populärwissenschaftliche Literatur';

  @override
  String get s_fcc3102d => 'technik';

  @override
  String s_76c118d0({required Object n}) {
    return '@@PH0@@ populärwissenschaftliche und technische Bücher';
  }

  @override
  String get s_2b65326c => 'Lernt von anderen';

  @override
  String get s_f85fa7d4 => 'Biografie';

  @override
  String s_b2e9db16({required Object cat, required Object pct}) {
    return '@@PH0@@ Biographien · @@PH1@@';
  }

  @override
  String get s_9e49409c => 'Ein gesunder Lebensstil';

  @override
  String get s_c21b69a8 => 'Medizin';

  @override
  String s_1dd31356({required Object cat}) {
    return '@@PH0@@ Medizin & Gesundheitsbücher';
  }

  @override
  String get s_77e32253 => 'Pragmatischer Kreditnehmer';

  @override
  String get s_0323f1bb => 'Recht';

  @override
  String s_82364cc8({required Object cat}) {
    return '@@PH0@@ Gesetzbücher';
  }

  @override
  String get s_ea038731 => 'Selbstverliebt';

  @override
  String get s_dbb1c112 => 'Comic';

  @override
  String get s_6398a679 => 'Bücher nur für Kinder';

  @override
  String s_a1b1d26a({required Object cat}) {
    return '@@PH0@@ Comics und Kinderbücher';
  }

  @override
  String get s_94f8d7c2 => 'Entspannungsübungen im Einklang mit der Natur';

  @override
  String get s_30412ad5 => 'Konfession';

  @override
  String s_d00fbfe6({required Object cat}) {
    return '@@PH0@@ Religionsbücher';
  }

  @override
  String get s_52c36d65 => 'Weiß, wie man lebt';

  @override
  String get s_06e23c48 => 'Sonstige';

  @override
  String s_e3a3f18e({required Object cat, required Object pct}) {
    return '@@PH0@@ Lifestyle-Bücher · @@PH1@@';
  }

  @override
  String get s_dc2e94c1 => 'Lehrer im Herzen';

  @override
  String get s_235af603 => 'Bildung';

  @override
  String s_be73b4a0({required Object cat, required Object pct}) {
    return '@@PH0@@ Bildungsbücher · @@PH1@@';
  }

  @override
  String get s_7ea6e8a9 => 'Gelehrt im Wandel der Zeiten';

  @override
  String s_938fd6ec({required Object categoryKinds}) {
    return 'Ihre Bibliothek umfasst @@PH0@@ Kategorien — ein bisschen von allem';
  }

  @override
  String get s_41a09d04 => 'Tiefenschärfe';

  @override
  String s_c61130ac({required Object categoryKinds, required Object total}) {
    return '@@PH0@@ Bücher fallen nur in die Kategorien @ @ PH1 @ @';
  }

  @override
  String get s_431dc47d => 'Beender';

  @override
  String s_a7b097f6({required Object finished, required Object toStringAsFixed, required Object total}) {
    return 'Abschlussrate @@PH0@@% (@@PH1@@/@@PH2@@)';
  }

  @override
  String get s_6b51050c => 'Tsundoku-Meister';

  @override
  String s_55413cd8({required Object finished, required Object wish}) {
    return '@@PH0@@ lesen wollen, aber nur @@PH1@@ beendet';
  }

  @override
  String get s_e60e931c => 'Schneidet Verluste schnell';

  @override
  String s_b3549d21({required Object abandoned, required Object toStringAsFixed}) {
    return '@@PH0@@ drop · @@PH1@@% — du legst fest, was dich nicht packt';
  }

  @override
  String get s_4be15f8c => 'Serienanlasser';

  @override
  String s_b0a853cf({required Object stalled}) {
    return '@@PH0@@ Bücher in Bearbeitung, aber unter 15 %';
  }

  @override
  String get s_10b9bddd => 'Sanfter Geist';

  @override
  String s_6a469e36({required Object ratedCount, required Object toStringAsFixed}) {
    return 'Deine von @@PH0@@ bewerteten Bücher im Durchschnitt @@PH1@@';
  }

  @override
  String get s_e67694db => 'Scharfzüngiger Kritiker';

  @override
  String s_30c4cecf({required Object ratedCount, required Object toStringAsFixed}) {
    return 'Deine von @@PH0@@ bewerteten Bücher sind nur durchschnittlich @@PH1@@';
  }

  @override
  String get s_fe4567e4 => 'Starke Meinungen';

  @override
  String s_b1d69175({required Object toStringAsFixed}) {
    return 'Rating-Standardabweichung @ @ PH0 @ @ — Gut und Böse liegen weit auseinander';
  }

  @override
  String get s_fbad19d5 => 'Erneute Besuche und Erneuerungen';

  @override
  String s_8d62979c({required Object reread}) {
    return '@@PH0@@ Bücher zweimal oder öfter gelesen';
  }

  @override
  String get s_54302bb2 => 'Immersiver Reader';

  @override
  String s_bc9dbced({required Object round}) {
    return '@@PH0@@ Minuten pro aktivem Tag im Durchschnitt';
  }

  @override
  String get s_e9eddf51 => 'Digital Native';

  @override
  String s_df5bbdba({required Object toStringAsFixed, required Object weread}) {
    return '@@PH0@@ von WeRead · @@PH1@@%';
  }

  @override
  String get s_ce6517f9 => 'Papier und Digital';

  @override
  String s_75c2fd5a({required Object libraryCount, required Object paper}) {
    return 'plus @@PH0@@ geliehene und @@PH1@@ Papierbücher';
  }

  @override
  String get s_8cac22b7 => 'Reads with Ears';

  @override
  String s_72b826e9({required Object audio}) {
    return '@@PH0@@ Hörbücher';
  }

  @override
  String get s_7caeab27 => 'Visueller Reader';

  @override
  String s_a5a44a39({required Object comic}) {
    return '@@PH0@@ Comics';
  }

  @override
  String s_0e59d960({required Object m, required Object y}) {
    return '@@PH0@@/@@PH1@@';
  }

  @override
  String s_1a2e873e({required Object month}) {
    return 'Monat @@PH0@@';
  }

  @override
  String s_5583162a({required Object e}) {
    return 'Bildvorverarbeitung fehlgeschlagen; Verwendung des Originalbildes: @@PH0@@';
  }

  @override
  String s_628c2132({required Object e}) {
    return 'Konvertierung in JPEG fehlgeschlagen: @@PH0@@';
  }

  @override
  String get s_ebf4bdfb => 'Parieren der Layout-Struktur...';

  @override
  String get s_ba1038b1 => 'Bereinigen der Erkennungsergebnisse mit dem LLM...';

  @override
  String get s_6292a274 => 'Titel werden überprüft...';

  @override
  String get s_427e1f0d => 'G';

  @override
  String get s_af041a1b => 'Titel abgeschlossen';

  @override
  String s_988dd5cb({required Object reason}) {
    return '@@PH0@@, Titel abgeschlossen';
  }

  @override
  String get s_a746d189 => '[、,，;/]';

  @override
  String s_a4ec75fd({required Object e, required Object title}) {
    return '\"@@PH0@@\": @@PH1@@';
  }

  @override
  String get s_d2bbf7ce => 'Multimodale Erkennung';

  @override
  String get s_381ca835 => 'Dies ist ein Screenshot eines Regals oder einer Leseliste';

  @override
  String get s_fce28e56 => 'Dies ist ein Screenshot des Umschlags oder der Detailseite eines einzelnen Buches';

  @override
  String s_ba5425c5({required Object n, required Object scene}) {
    return '$scene.\n\nOutput a JSON array only, each item shaped like:\n{\"title\":\"title\",\"author\":\"author\",\"progress\":a number from 0-100 or null,\"status\":\"one of unread/reading/finished or null\",\"confidence\":a number from 0-1}\n\nRequirements:\n1. Only output books that are **actually visible** in the image; don\'t add books you assume should be there;\n2. Ignore UI text (filters, search, sort, All, Shelf, N books, etc.);\n3. Copy titles exactly as shown, including ones cut off by an ellipsis — don\'t complete them yourself;\n4. Leave author as an empty string if it can\'t be read; don\'t guess;\n5. Only fill in author when it really is written in the image.\n$n';
  }

  @override
  String get s_951042c3 => 'Sie extrahieren Informationen aus Screenshots des Bücherregals. Geben Sie nur ein JSON-Array ohne erklärenden Text aus.';

  @override
  String get s_29dbdb32 => 'LLM-Bereinigung';

  @override
  String get s_9cd6567e => 'Ein Foto eines Buchdeckels oder eines Buchrückens';

  @override
  String get s_a6db1cf4 => 'Ein Screenshot des Regals einer E-Book-App';

  @override
  String s_43fca769({required Object ocrText, required Object scene}) {
    return 'Below are the text lines OCR\'d from $scene, in top-to-bottom order.\n\nExtract the **real book titles** from them, ignoring all UI text (search box, filters, categories, status bar, page numbers, chapter headings, buttons, statistics).\n\nRules:\n1. Only output books that actually appear in the image. Don\'t add books you assume should be there.\n2. If a title is truncated by an ellipsis in the UI (for example \"Deep…\"), complete it into the full title.\n3. progress takes an integer percentage from 0–100; leave it an empty string if it can\'t be read. Note that \"0.8%\" is 0.8, not 80.\n4. status must be one of \"unread / reading / finished / dropped\"; leave it an empty string if it can\'t be read.\n5. Only fill in author when it clearly appears in the image; otherwise leave it blank. Don\'t guess.\n6. Skip lines you\'re unsure about. Better to miss one book than to add a fake one.\n\nOutput a JSON array only, with elements shaped like:\n[{\"title\":\"\",\"author\":\"\",\"progress\":\"\",\"status\":\"\",\"confidence\":0.0}]\n\nOCR text lines:\n\"\"\"\n$ocrText\n\"\"\"';
  }

  @override
  String get s_cbb756f7 => 'G';

  @override
  String get s_95222176 => 'Ungelesen';

  @override
  String get s_5a833930 => 'Want to Read [Will ich lesen]';

  @override
  String get s_b9bf9b53 => 'Lesen';

  @override
  String get s_be5492a5 => 'Lese ich momentan';

  @override
  String get s_44c14529 => 'Beendete Lektüre';

  @override
  String get s_0872b5b7 => 'Abgeschlossen';

  @override
  String get s_300a32bd => 'Abgeschlossen';

  @override
  String get s_0f4d9c68 => 'Abgeworfen (in Shelved zusammengeführt)';

  @override
  String get s_7675d229 => '\\s*(著|编著|译|著译)\$';

  @override
  String get s_285bb37e => '[，。 ；、 ？！：）」』]\$';

  @override
  String get s_8f936d11 => '(著|编著 |译 |著译)\$';

  @override
  String get s_d0c345ec => '[（《 ·“]\$';

  @override
  String get s_2d3c83a7 => '[）》」』 ”]\$';

  @override
  String get s_0686f279 => 'Größter Text auf dem Cover';

  @override
  String get s_5514105a => 'Sekundärer Covertext';

  @override
  String get s_174faffb => 'Enthält Chinesisch';

  @override
  String get s_b13a1237 => 'Hat Fortschritt oder Status';

  @override
  String get s_24745e9d => 'Hat Autor';

  @override
  String get s_0cedc3f4 => 'Angemessene Länge';

  @override
  String get s_5bdfa6ae => 'Zu kurz';

  @override
  String get s_58171266 => 'Zu lang';

  @override
  String get s_1e8c236b => 'Spalten linksbündig';

  @override
  String get s_89ac54fb => 'Cover-Schriftzug';

  @override
  String get s_132a750b => 'Zu kurzes Englisch';

  @override
  String get s_6af25a96 => '[，。 ；、 ？！]\$';

  @override
  String get s_a335b25f => 'Satz-ende Satzzeichen';

  @override
  String get s_885dd894 => '％';

  @override
  String get s_620b459e => '《';

  @override
  String get s_150c7508 => '》';

  @override
  String get s_67df3afd => 'Hat Titelmarken';

  @override
  String get s_5a09ed37 => 'Chinesisch';

  @override
  String get s_6b631636 => 'Sieht aus wie ein englisches UI-Wort';

  @override
  String get s_1dd3f274 => 'Angrenzende Linie';

  @override
  String get s_f547232b => ', zusammengeführter Zeilenumbruch';

  @override
  String get s_fc39b00e => 'huazuar';

  @override
  String get s_eba88d83 => 'Regalboden';

  @override
  String get s_b6fe7962 => 'Ebook';

  @override
  String get s_c7673d27 => 'Papier';

  @override
  String get s_02a1a8ed => 'Hörbuch ';

  @override
  String get s_fe152225 => 'WeRead';

  @override
  String get s_2032cbd7 => 'iReader Select';

  @override
  String get s_12ed007e => 'JD Read';

  @override
  String get s_570bb7c8 => 'BOOX';

  @override
  String get s_36bfef2d => 'Bibliothek';

  @override
  String get s_4139f3b5 => 'Anleitung';

  @override
  String get s_88cdd7e4 => 'Markiert';

  @override
  String get s_6abc44a8 => 'Gedankenfrage';

  @override
  String get s_67585b8a => 'Wiederholung';

  @override
  String get s_96009a7e => 'Lesebericht';

  @override
  String s_4343b7b3({required Object join}) {
    return 'Generieren im Hintergrund: @@PH0@@';
  }

  @override
  String s_a6c57a43({required Object ok}) {
    return 'Automatisch generierte Reports';
  }

  @override
  String s_f71dea06({required Object failed, required Object ok}) {
    return '@ @ PH0 @ @ generiert, fehlgeschlagen @ @ PH1 @ @ (Sie können es manuell erneut versuchen)';
  }

  @override
  String s_e93308dd({required Object latencyMs, required Object model}) {
    return 'Verbunden · @@PH0@@ · @@PH1@@ ms';
  }

  @override
  String get s_d2a3748e => 'Das Modell gab leeren Inhalt zurück';

  @override
  String get s_3abdc334 => 'Das Modell unterstützt möglicherweise nicht die aktuellen Parameter, oder die Inhaltsfilterung wurde ausgelöst. Versuchen Sie es mit einem anderen Modell.';

  @override
  String get s_cc72f973 => 'Kein LLM-Schlüssel konfiguriert. Füllen Sie unter Einstellungen → LLM eine aus und testen Sie zuerst die Verbindung';

  @override
  String get s_9e51ce93 => 'Kein Modell ausgewählt. Gehen Sie zu Einstellungen → LLM und verwenden Sie \"Modelle abrufen\", um eines auszuwählen';

  @override
  String get s_c6e18e89 => 'In diesem Zeitraum stimmen keine Bücher überein; versuchen Sie es mit einem anderen';

  @override
  String get s_8bb45b34 => 'Berichtsperiode';

  @override
  String get s_8bd59fb2 => 'Wählen Sie einen jährlichen oder monatlichen Bericht';

  @override
  String get s_53bea04d => 'Abgelegt nach Kalenderjahr / Monat; einmal generiert, können Sie es jederzeit erneut besuchen. Der aktuelle Monatsbericht wird erst im nächsten Monat generiert.';

  @override
  String get s_1f048ed9 => 'Testverfahren';

  @override
  String get s_38fb1115 => 'Prüfanschluß';

  @override
  String get s_a14e36dc => 'Generieren… (langer Text dauert etwa eine Minute)';

  @override
  String get s_b36c173d => 'Bericht erstellen';

  @override
  String get s_c94ade95 => 'Sendet die Buchliste dieses Zeitraums (Titel / Autor / Kategorie / Bewertung) und aggregierte Statistiken, damit der Bericht bestimmte Bücher benennen kann; Notiztext und Hervorhebungen werden nicht hochgeladen.';

  @override
  String get s_5e05e92a => 'Enthalten';

  @override
  String s_be9a1551({required Object total}) {
    return '@@PH0@@ Bücher';
  }

  @override
  String s_ce115766({required Object finished}) {
    return '@@PH0@@ Bücher';
  }

  @override
  String s_8b46a11f({required Object reading}) {
    return '@@PH0@@ Bücher';
  }

  @override
  String s_81e94993({required Object wish}) {
    return '@@PH0@@ Bücher';
  }

  @override
  String get s_09b589b4 => 'Durchschnittliche Bewertung ';

  @override
  String s_0825e123({required Object label}) {
    return 'Inhalt des Berichts · @@PH0@@';
  }

  @override
  String get s_049eca89 => 'Alles kopieren';

  @override
  String get s_50bf9961 => 'Bericht in Zwischenablage kopiert';

  @override
  String get s_772cbfcf => 'Automatisch generieren';

  @override
  String get s_01955ddf => 'Wenn aktiviert, ergänzt das Öffnen der App Fehlendes: den Monatsbericht des letzten Monats und den Jahresbericht des Vorjahres (erzeugt beim ersten Öffnen im neuen Jahr).';

  @override
  String get s_b2a52a3d => 'Automatische Generierung fehlt';

  @override
  String get s_b233138e => 'Jahresbericht (Vorjahr)';

  @override
  String get s_877b864d => 'Einmal im Monat';

  @override
  String get s_a3dfa2a6 => 'Vergangene Berichte';

  @override
  String get s_66772db6 => 'Lesedaten exportieren';

  @override
  String get s_6b198f0b => 'Export abgebrochen';

  @override
  String s_a101fbdd({required Object counts, required Object saved}) {
    return 'Exportiert nach: @@PH0@@\n\n@@PH1@@';
  }

  @override
  String s_6ec2d38e({required Object e}) {
    return 'Export fehlgeschlagen: @@PH0@@';
  }

  @override
  String get s_c699263b => 'Wählen Sie eine Sicherungsdatei';

  @override
  String s_e34bdbcb({required Object e}) {
    return 'Diese Datei konnte nicht gelesen werden: @@PH0@@';
  }

  @override
  String get s_1dedeaa2 => 'Dies ist keine von dieser App exportierte Sicherungsdatei (fehlende Formatmarkierung oder neuer als die aktuelle App)';

  @override
  String get s_103c5811 => 'Diese Datei enthält keine wiederherstellbaren Daten';

  @override
  String get s_674a7957 => 'Jetzt wiederherstellen';

  @override
  String s_94094e0d({required Object length}) {
    return 'Dadurch werden die Daten dieses Geräts mit dem Backup überschrieben:\n@ @NL@@@PH0@@\n@ @ @ NL @ @Datensätze mit dem gleichen Namen werden vollständig überschrieben — Wiederherstellen bedeutet \"zum Zeitpunkt des Backups zurückkehren\", ohne Zusammenführen auf Feldebene. Bücher, die nach der Sicherung hinzugefügt wurden, werden nicht gelöscht.';
  }

  @override
  String get s_a0451c97 => 'Abbrechen';

  @override
  String get s_ec7085ab => 'Wiederherstellen';

  @override
  String s_2296b134({required Object counts, required Object first}) {
    return 'Wiederherstellung abgeschlossen@@PH0@@\n\n@@PH1@@';
  }

  @override
  String s_e669bac1({required Object e}) {
    return 'Wiederherstellung fehlgeschlagen: @@PH0@@';
  }

  @override
  String s_7c0be1cd({required int? books}) {
    return '@@PH0@@ Bücher';
  }

  @override
  String s_dd2321ce({required int? notes}) {
    return '@@PH0@@ Notizen';
  }

  @override
  String s_d48aa751({required int? reading_logs}) {
    return '@@PH0@@ Leseprotokolle';
  }

  @override
  String s_d044717e({required int? llm_reports}) {
    return '@@PH0@@ KI-Berichte';
  }

  @override
  String s_f4d248a7({required int? settings}) {
    return '@@PH0@@ Einstellungseinträge';
  }

  @override
  String get s_8719bf89 => 'Datenexport & -wiederherstellung';

  @override
  String get s_8fe27f12 => 'Was exportiert wird';

  @override
  String get s_5d9af0a7 => 'Ein vollständiger JSON-Snapshot: Bücher, Notizen, Leseprotokolle, KI-Berichte und Einstellungen. Es wird als einzelne Datei gespeichert — verwenden Sie es, um es auf einem anderen Gerät wiederherzustellen.';

  @override
  String get s_582f4cb6 => 'Als JSON-Datei exportieren';

  @override
  String get s_091ad5f4 => 'Einstellungen wiederherstellen';

  @override
  String get s_3a36f742 => 'Wählen Sie eine zuvor exportierte .json-Datei. Datensätze mit dem gleichen Namen werden im Ganzen überschrieben, nicht Feld für Feld zusammengeführt — das bedeutet \"zum Zeitpunkt der Sicherung zurückgehen\", nicht \"die Gewerkschaft übernehmen\".';

  @override
  String get s_6f9ab88c => 'Wählen Sie eine Sicherungsdatei und stellen Sie sie wieder her';

  @override
  String get s_f24f63da => 'Diese Notiz löschen';

  @override
  String get s_ecbd7449 => 'Löschen';

  @override
  String get s_f98a79dc => 'Anmerkung hinzufügen';

  @override
  String get s_05712ea1 => 'Notiz bearbeiten';

  @override
  String get s_e3fdcb7e => 'Ein Zitat, ein Gedanke oder eine Bewertung...';

  @override
  String get s_c8d8fada => 'Kapitel/Seite';

  @override
  String get s_f80f4749 => 'Optional';

  @override
  String get s_abfe9512 => 'Speichern';

  @override
  String get s_a647c2e0 => 'Dieses Buch existiert nicht oder wurde gelöscht';

  @override
  String s_154ada37({required Object join}) {
    return 'Autor: @@PH0@@';
  }

  @override
  String s_904feb6c({required Object join}) {
    return 'Übersetzer: @@PH0@@';
  }

  @override
  String s_1e4c61f8({required Object publisher}) {
    return 'Herausgeber: @@PH0@@';
  }

  @override
  String s_bf93bf6d({required Object first}) {
    return 'Veröffentlicht: @@PH0@@';
  }

  @override
  String s_def61e8c({required Object categoryPrimary}) {
    return 'Kategorie: @@PH0@@';
  }

  @override
  String get s_d9bdf56b => 'Status';

  @override
  String s_94b27e86({required Object toStringAsFixed}) {
    return 'Fortschritt @@PH0@@%';
  }

  @override
  String get s_8331377a => 'Bewertung';

  @override
  String get s_205eb716 => 'Kurzdarstellung';

  @override
  String get s_b5e2aa8a => 'Notiere, worum es in diesem Buch geht';

  @override
  String get s_3ec1ca86 => 'Wiederholung';

  @override
  String get s_aa5a5d3e => 'Ihre Gedanken und Bewertungen';

  @override
  String s_fb47d52b({required Object length}) {
    return 'Anmerkungen · @@PH0@@';
  }

  @override
  String get s_18dd30c5 => 'Noch keine Notizen. Notieren Sie sich eine Notiz, wenn Ihnen etwas auffällt — es wird für Ihr Jahr im Rückblick wesentlich sein.';

  @override
  String get s_4b7d48f2 => 'Beschreibung';

  @override
  String s_5e52b06a({required String? dueAt}) {
    return 'Fällig: @@PH0@@';
  }

  @override
  String get s_ad207008 => 'Bearbeiten';

  @override
  String get s_f5d99c16 => '、';

  @override
  String get s_65983593 => 'Der Titel darf nicht leer sein';

  @override
  String get s_1f0939bc => '[,，、;；]';

  @override
  String get s_6c7a6cc5 => 'Buchung bearbeiten';

  @override
  String get s_31e2aa97 => 'Ein Buch manuell hinzufügen';

  @override
  String get s_eda73905 => 'Änderungen speichern';

  @override
  String get s_71b10e99 => 'Zum Regal hinzufügen';

  @override
  String get s_2dae8ba5 => 'Wählen Sie eine lokale Deckung';

  @override
  String get s_5be7901d => 'Cover festlegen';

  @override
  String get s_a59912dd => 'Deckel entnehmen';

  @override
  String get s_e2b6c0de => 'Anrede *';

  @override
  String get s_22760472 => 'Verfasser';

  @override
  String get s_5f70e9dd => 'Autoren durch Komma trennen';

  @override
  String get s_759fb403 => 'Status';

  @override
  String get s_da1c08d9 => 'Format';

  @override
  String get s_5ce4e16d => 'Löschen';

  @override
  String get s_b0d7b0de => 'Description summary';

  @override
  String get s_d0dd45ac => 'Kategorien werden auf ein kontrolliertes Vokabular normalisiert — die Eingabe von „Business & Motivation“ wird ebenfalls zu „Business“, sodass Statistiken nicht in zwei separate Buckets aufgeteilt werden.';

  @override
  String get s_b32f0afe => 'Kategorie';

  @override
  String get s_87635298 => 'Optional';

  @override
  String get s_5aa23087 => 'keine';

  @override
  String s_573b6694({required Object e}) {
    return 'Etwas ist schief gelaufen: ';
  }

  @override
  String get s_28690759 => 'Bild wird verbessert...';

  @override
  String get s_d5155b2d => 'Kein Titel erkannt; versuchen Sie es mit einem anderen Bild';

  @override
  String get s_e20dac78 => 'Lesen des Bildes mit einem multimodalen Modell...';

  @override
  String get s_5fea0487 => 'Das multimodale Modell konnte keinen Titel aus diesem Bild lesen. Überprüfen Sie, ob das ausgewählte Modell Bildeingaben akzeptiert (Nur-Text-Modelle lehnen sie vollständig ab), oder setzen Sie Einstellungen → Screenshot-Erkennung Erkennungsmodus → zurück auf \"Auto\", um auf OCR auf dem Gerät zurückzugreifen.';

  @override
  String get s_cdda9381 => 'Multimodal gab nichts zurück; auf On-Device-OCR zurückgreifen...';

  @override
  String get s_b85e4cbc => 'Bild-Upload nicht erlaubt; Rückfall auf On-Device-OCR…';

  @override
  String get s_a9698571 => 'Text wird erkannt...';

  @override
  String get s_7ef6b42d => 'In diesem Bild wurde kein Text gefunden. Probiere einen anderen Blickwinkel aus, gestalte den Text schärfer oder mache einfach einen Screenshot (Screenshots sind sauberer als Fotos).';

  @override
  String get s_319b9488 => 'Kein titelähnlicher Text gefunden. Wenn es sich um eine Innenseite handelt, steht der Titel normalerweise nicht darauf — versuche es mit „Regal-Screenshot importieren“ oder fotografiere stattdessen das Cover.';

  @override
  String get s_37588c9c => 'Aus diesem Bild konnte kein Titel gelesen werden. Versuchen Sie, die umgebende Benutzeroberfläche zuzuschneiden, und versuchen Sie es erneut.';

  @override
  String get s_04a1b347 => 'Titel';

  @override
  String get s_a9fe3793 => 'Keine \"Titel\" -Spalte in der CSV gefunden';

  @override
  String get s_3db59388 => 'Fortschritt';

  @override
  String get s_9e160a69 => 'Herausgeber';

  @override
  String s_d4b7c3c7({required Object length}) {
    return 'Parsed @@PH0@@ Bücher. Importieren?';
  }

  @override
  String get s_649320a3 => 'Ihr WeRead-Regal wird gelesen...';

  @override
  String get s_e53774ba => 'Das Regal ist leer oder die API hat keine Daten zurückgegeben';

  @override
  String s_8151aa42({required Object length}) {
    return 'Ihr WeRead-Regal enthält @@PH0@@ Bücher. Importieren?';
  }

  @override
  String get s_9b37038a => 'Metadaten werden vervollständigt und gespeichert...';

  @override
  String s_c4f36bd6({required Object added, required Object duplicated, required Object failed}) {
    return 'Import abgeschlossen: @@PH0@@ hinzugefügt, @@PH1@@ aktualisiert@@PH2@@';
  }

  @override
  String get s_28ab46d9 => 'Noch keine WeRead-Bücher auf diesem Gerät — synchronisieren Sie zuerst das Regal';

  @override
  String get s_6d61442b => 'Lesefortschritt wird synchronisiert...';

  @override
  String s_a26c53db({required Object length, required Object updated}) {
    return 'Aktualisierter Lesefortschritt für @@PH0@@ von @@PH1@@ Büchern';
  }

  @override
  String get s_3a0cf870 => 'Die Verbindung wurde unterbrochen. Überprüfen Sie Ihr Netzwerk und versuchen Sie es erneut.';

  @override
  String get s_1cbe2507 => 'Bestätigen';

  @override
  String get s_1df9fbd5 => 'Import';

  @override
  String get s_874053cb => 'WeRead API-Schlüssel';

  @override
  String get s_58652b51 => 'Scannen Sie den QR-Code in WeChat, um weread.qq.com/r/weread-skills,@ @ NL @ @ zu öffnen, und kopieren Sie dann den auf der Seite angezeigten Schlüssel (er beginnt mit \"wrk-\"). Der Schlüssel wird nur auf diesem Gerät gespeichert.';

  @override
  String get s_cb2558f7 => 'Regal-Screenshot importieren';

  @override
  String get s_24b715f3 => 'Wählen Sie einen Screenshot Ihres Regals und lesen Sie den Titel und den Fortschritt jeder Zelle. Die Ergebnisse können deaktiviert sein — überprüfen Sie dies vor dem Speichern.';

  @override
  String get s_4f062f79 => 'Regalfoto importieren';

  @override
  String get s_6e464c0e => 'Fotografieren Sie ein Cover, einen Rücken oder eine Seite; der Titel wird erkannt und der Rest der Metadaten ausgefüllt. Die Ergebnisse können deaktiviert sein — überprüfen Sie dies vor dem Speichern.';

  @override
  String get s_a5452d46 => 'Regal aus Kanälen synchronisieren';

  @override
  String get s_d40e2a14 => 'Liest Ihr Regal und Ihren Lesestatus über die offizielle API Ihrer konfigurierten Kanäle — keine Screenshots erforderlich. WeRead wird heute unterstützt; weitere Kanäle sind auf dem Weg.';

  @override
  String get s_af94a367 => 'Lesefortschritt';

  @override
  String get s_59d2efab => 'Ruft den Leseprozentsatz und die kumulierte Zeit jedes Buches ab. Einige Channel Shelf-Endpunkte lassen den Fortschritt aus, daher ist eine separate Anfrage pro Buch erforderlich.';

  @override
  String get s_fa52186c => 'CSV /Notion-Import';

  @override
  String get s_2c78f2b8 => 'Ein-Klick-Migration von einem Notion CSV-Export: Spaltennamen werden automatisch erkannt und benutzerdefinierte Felder bleiben erhalten.';

  @override
  String get s_238b14fc => 'Wird bearbeitet...';

  @override
  String s_ed4b0551({required Object length}) {
    return '$length Bücher konnten nicht importiert werden';
  }

  @override
  String s_ec50ebde({required Object length}) {
    return '…und $length mehr';
  }

  @override
  String get s_18307d56 => 'Manuell hinzufügen';

  @override
  String s_cc0eef03({required Object length}) {
    return '$length books recognized';
  }

  @override
  String get s_0f466d7a => 'Alle auswählen';

  @override
  String get s_42b2fafa => 'Alle abwählen';

  @override
  String s_7feb7674({required Object keptLines, required Object repairedTitles, required Object totalLines, required Object usedLlm}) {
    return 'Read $totalLines lines of text, kept $keptLines books$usedLlm$repairedTitles';
  }

  @override
  String get s_4d52323f => 'Elemente, die als \"abgeschlossen\" oder \"abgeleitet\" gekennzeichnet sind, sind nicht wörtlich aus dem Bild zu entnehmen — bitte überprüfen Sie sie vor dem Import. Du kannst auf einen beliebigen Titel oder Autor tippen, um ihn zu bearbeiten.';

  @override
  String get s_0f40975c => 'Manuell hinzufügen (durch OCR übersehen)';

  @override
  String s_fdc0acd1({required Object length}) {
    return 'Import the $length selected';
  }

  @override
  String get s_4443bd2c => 'Das Originalbild wurde abgeschnitten';

  @override
  String s_7af46a28({required Object progressPercent}) {
    return 'Fortschritt $progressPercent%';
  }

  @override
  String s_4737de25({required Object toStringAsFixed}) {
    return 'Vertrauen $toStringAsFixed%';
  }

  @override
  String s_2df91ffc({required Object rawText}) {
    return 'Originalbild: $rawText';
  }

  @override
  String get s_7bbe0f10 => 'Autor (optional) ';

  @override
  String get s_bd13cf0b => 'Nur dieses löschen;';

  @override
  String get s_c048f107 => 'Statistikbereich';

  @override
  String get s_89c61e4a => 'Gesamt Bücher';

  @override
  String get s_9da15a74 => 'Statusaufschlüsselung';

  @override
  String get s_130a42ae => 'Kategorie-Aufschlüsselung';

  @override
  String get s_98f42577 => 'Aufschlüsselung der Quelle';

  @override
  String get s_5e8ebbe6 => 'Formataufschlüsselung';

  @override
  String get s_5182e58a => 'Durchschnittliche Bewertung ';

  @override
  String get s_50bcc778 => 'Bücher bewertet';

  @override
  String get s_59c5e73a => 'Lesezeit (Minuten)';

  @override
  String get s_48529b9f => 'Tage mit Leseaktivität';

  @override
  String get s_7be1388c => 'Kein LLM-Schlüssel konfiguriert. Füllen Sie eines unter Einstellungen → LLM aus, um es zu generieren.';

  @override
  String get s_992d7786 => 'Das Modell hat keine verwendbaren Tags zurückgegeben; versuchen Sie es mit einem anderen Modell';

  @override
  String get s_eead3bcd => 'Mit diesem Set ersetzen?';

  @override
  String s_b9da6464({required Object length, required Object length_1}) {
    return 'Your current $length tags will be replaced with these $length_1. You can still edit or delete them one by one afterwards.';
  }

  @override
  String get s_89829921 => 'Wechseln';

  @override
  String get s_0f8acec9 => 'Ersetzt durch die Haupt-Tags';

  @override
  String get s_93aebfd1 => 'Dieses Tag ist oben bereits aufgeführt';

  @override
  String get s_bca518fd => 'Zu den Haupt-Tags hinzugefügt';

  @override
  String s_284dfaab({required Object text}) {
    return 'Removed \"$text\"';
  }

  @override
  String get s_8eb8d18d => 'Tag bearbeiten';

  @override
  String get s_35c48d07 => 'Dies ist ein Tag, den Sie selbst geschrieben haben; es gibt keine automatische Grundlage dafür.';

  @override
  String get s_724386f0 => 'Schlagwort hinzufügen';

  @override
  String get s_fdd8c684 => 'Tags, die Sie selbst schreiben, sind nicht validiert und werden nicht durch Neuberechnung überschrieben.';

  @override
  String get s_7b328e58 => 'Auf Standard zurücksetzen?';

  @override
  String get s_b9a4d4ef => 'Ihre manuellen Bearbeitungen werden gelöscht und die Tags werden erneut aus Ihrer aktuellen Bibliothek abgeleitet.';

  @override
  String get s_0fcef2c8 => 'Wiederhergestellt für Tags, die aus Ihrer Bibliothek abgeleitet wurden';

  @override
  String get s_e97565e5 => 'Mein Leseprofil';

  @override
  String s_783e43af({required Object e}) {
    return 'Das Freigabebild konnte nicht generiert werden: $e';
  }

  @override
  String get s_14f92b04 => 'Share-Bild generieren';

  @override
  String get s_a17c4e02 => 'Auf deinen Fotos gespeichert';

  @override
  String s_3f81d5b6({required Object e}) {
    return 'Konnte nicht speichern: $e';
  }

  @override
  String get s_c6d1e7a3 => 'Öffnen: Das Bild ist bereit. ';

  @override
  String get s_b8e4c9a1 => 'Bild speichern';

  @override
  String get s_51ebc0d1 => 'Neuberechnen';

  @override
  String get s_6c64acc5 => 'Meine Lese-Persönlichkeits-Tags';

  @override
  String s_03bf36af({required Object length}) {
    return 'Abgeleitet aus $length Büchern';
  }

  @override
  String get s_a789d74f => 'Alle Tags wurden gelöscht. Tippe unten auf „Hinzufügen“, um deine eigenen zu schreiben, oder setze sie auf die Standardeinstellung zurück und lasse sie von der App erneut ableiten.';

  @override
  String get s_a1d885c1 => 'Hinzufügen';

  @override
  String get s_64bff158 => 'Tippen Sie auf ein Tag, um es umzubenennen oder zu löschen. Bei aus Regeln abgeleiteten Tags sind die Zahlen dahinter im Bearbeitungsdialog sichtbar.';

  @override
  String get s_84bf2c49 => 'Generieren';

  @override
  String get s_5a251fee => 'Generieren Sie ein weiteres Set mit KI';

  @override
  String get s_18be3bbe => 'Auf Standard zurücksetzen';

  @override
  String get s_7ae84af3 => 'Lese Präferenzen';

  @override
  String s_aeed65e7({required Object length}) {
    return '$length Kategorien';
  }

  @override
  String get s_f2a9e2a4 => 'Die Fläche des Kreises ist proportional zur Anzahl der Bücher (daher ist der Radius die Quadratwurzel der Zählung — wobei die Zählung direkt verwendet wird, da der Radius Unterschiede übertreiben und in die Irre führen würde).';

  @override
  String s_abd0dab0({required Object stamp}) {
    return 'KI generiert · $stamp';
  }

  @override
  String get s_7ea8e671 => 'Haupt-Tags ersetzen';

  @override
  String get s_d1a58b2f => 'Tippen Sie auf ein einzelnes Tag, um es den Haupt-Tags hinzuzufügen, oder ersetzen Sie das gesamte Set. Dieser Satz wird vom Modell aus aggregierten Statistiken generiert, so dass seine Grundlage weniger explizit ist als die regelbasierte.';

  @override
  String get s_a38881a0 => 'Noch keine Bücher in diesem Sortiment';

  @override
  String get s_20fde694 => 'Versuchen Sie es mit einem anderen Zeitraum oder importieren Sie zuerst einige Bücher';

  @override
  String get s_9fe34cff => 'Noch keine Kategoriedaten';

  @override
  String s_d9579b73({required Object bookCount, required Object rangeLabel}) {
    return '$rangeLabel · $bookCount Bücher';
  }

  @override
  String get s_bfc50de8 => 'Persönlichkeits-Tags';

  @override
  String get s_ab5cc063 => 'Lese Präferenzen';

  @override
  String get s_9de44e0f => 'Lese-Tracker · Mein Regal';

  @override
  String get s_20a63774 => 'Statistikbereich wählen';

  @override
  String get s_d507abff => 'i.O.';

  @override
  String get s_ff31410d => 'Angepasst …';

  @override
  String get s_72cca1f6 => 'Konfiguration lokal gespeichert';

  @override
  String s_b6477017({required Object name}) {
    return 'Ausgefüllt in $name; der API-Schlüssel wird weiterhin benötigt';
  }

  @override
  String get s_533f5118 => 'Modellliste wird abgerufen...';

  @override
  String s_648219b9({required Object id}) {
    return 'Ausgewähltes Modell: $id';
  }

  @override
  String s_baf95794({required Object length}) {
    return '$length -Modelle verfügbar (keine ausgewählt)';
  }

  @override
  String get s_e37cab47 => 'Testen der Verbindung';

  @override
  String s_c17c1a05({required Object latencyMs, required Object model, required Object reply}) {
    return 'Verbunden · $model\nTook $latencyMs ms; das Modell antwortete \"$reply\"';
  }

  @override
  String get s_5df0d12b => 'WeRead-Schlüssel wird überprüft…';

  @override
  String s_bd245b07({required Object n}) {
    return 'Der Schlüssel ist gültig; das Regal hat derzeit $n Bücher';
  }

  @override
  String s_73f89115({required Object host}) {
    return 'Can\'t reach $host\nCheck your network, whether the base URL is complete (including /v1), and whether the service needs a proxy';
  }

  @override
  String get s_9038e16e => 'Der Endpunkt ist abgelaufen (180 Sekunden)';

  @override
  String s_e0710bf5({required Object e, required int? statusCode}) {
    return 'Service zurückgegeben $statusCode: $e';
  }

  @override
  String s_24d6c7ae({required Object name}) {
    return 'Anfrage fehlgeschlagen: $name';
  }

  @override
  String get s_4d3eb2b3 => 'Suchen nach Modellen';

  @override
  String s_17d94005({required Object length}) {
    return '$length insgesamt';
  }

  @override
  String get s_a48ae43a => 'Durch Klicken auf einen Vorschlag wird der Modellname in';

  @override
  String get s_b5c7b82d => 'Einstellungen';

  @override
  String get s_bc90fa59 => 'Wird verwendet, um Ihr Regal und den Lesefortschritt zu synchronisieren. Scannen Sie den QR-Code, um weread.qq.com/r/weread-skills zu öffnen und einen zu erhalten.';

  @override
  String get s_e44e9f26 => 'Lizenzschlüssel verifizieren';

  @override
  String get s_75bf6943 => '/LLM)';

  @override
  String get s_9e8f6691 => 'Wird für Metadaten-Fallback, die Bereinigung der Screenshot-Erkennung und das Lesen von Berichten verwendet.';

  @override
  String get s_cc3c9556 => 'Anbieter-Voreinstellungen';

  @override
  String get s_9021b9f9 => 'Wenn Sie eine auswählen, geben Sie die Adresse und das Modell ein';

  @override
  String get s_1fd51aaa => 'Modellname';

  @override
  String get s_209e1f28 => 'Verwenden Sie \"Modelle abrufen\", um aus der Liste auszuwählen, die Ihr Konto tatsächlich hat';

  @override
  String get s_ab135d7c => 'Modelle abrufen';

  @override
  String get s_a46a5664 => 'Prüfanschluß';

  @override
  String get s_e4f7e107 => 'Schlüssel anzeigen';

  @override
  String get s_b13be56e => 'Schlüssel ausblenden';

  @override
  String get s_9ac01f6b => 'Test und Abrufen speichern beide zuerst Ihre Eingaben.';

  @override
  String get s_0001747c => 'Screenshot-Erkennung';

  @override
  String get s_3f5cbdbf => 'Legt fest, wie gut Foto- und Screenshot-Importe erkannt werden.';

  @override
  String get s_9130a4ed => 'Bildverbesserungsvorverarbeitung';

  @override
  String get s_b79fc99c => 'Vergrößert und schärft das Bild zuerst, so dass kleine Titel besser erkannt werden.';

  @override
  String get s_9695a603 => 'Verwenden Sie den LLM, um die Erkennungsergebnisse zu bereinigen';

  @override
  String get s_267118b5 => 'Lassen Sie den LLM die anerkannten Titel bereinigen. Benötigt einen LLM-Schlüssel und verwendet Token.';

  @override
  String get s_6d7e1f9f => 'Erkennungsmodus';

  @override
  String get s_ed144a76 => 'Auto (multimodal zuerst, fällt auf das Gerät zurück)';

  @override
  String get s_c7bab837 => 'Multimodaler LLM liest das Bild direkt';

  @override
  String get s_d8f3da2a => 'OCR auf dem Gerät (offline, kostenlos)';

  @override
  String get s_f22e4cd2 => 'Die On-Device-OCR funktioniert offline, kann aber Titel übersehen; das multimodale Modell liest das Layout, benötigt aber ein Netzwerk und kann eines erfinden. \"Auto\" verwendet beides.';

  @override
  String get s_67677b3d => 'Daten';

  @override
  String get s_d596ba9b => 'Exportieren Sie die gesamte Datenbank als json, um sie auf ein anderes Gerät zu verschieben. Eine Neuinstallation beginnt mit einem leeren Regal; fügen Sie Bücher über die Registerkarte Importieren hinzu, um loszulegen.';

  @override
  String get s_39239742 => 'Ein-Tipp-Export/ Wiederherstellung';

  @override
  String get s_3c21597a => 'Alle Änderungen werden automatisch in der Datenbank dieses Geräts gespeichert — kein manuelles Speichern erforderlich.';

  @override
  String get s_68885a92 => 'Schlüssel werden nur in der Datenbank dieses Geräts gespeichert; sie werden niemals mit der App gebündelt oder hochgeladen.';

  @override
  String get s_9b3c95d4 => 'Kürzlich aktualisiert';

  @override
  String get s_97428491 => 'Vor kurzem gelesen';

  @override
  String get s_8f38c041 => 'Bestbewertete';

  @override
  String get s_50a7317f => 'Die meisten Fortschritte';

  @override
  String get s_b5538557 => 'Titel A-Z';

  @override
  String s_e3cd14ba({required Object title}) {
    return 'Added \"$title\"';
  }

  @override
  String get s_296fc9b4 => 'Shelf';

  @override
  String get s_a444b428 => 'Sortieren';

  @override
  String get s_fa0a5cdd => 'Zur Liste wechseln';

  @override
  String get s_cb4a4231 => 'Zum Abdeckgitter wechseln';

  @override
  String get s_78966c42 => 'Titel / Autor / Herausgeber suchen';

  @override
  String get s_8ed41c6c => 'Keine Bücher entsprechen diesen Filtern';

  @override
  String get s_bd33274a => 'Noch keine Bücher — fügen Sie einige aus dem Import-Tab hinzu';

  @override
  String s_0cd6d0f8({required Object length}) {
    return '$length Bücher';
  }

  @override
  String s_ff7e02df({required Object finished, required Object reading}) {
    return '$reading Lesen · $finished Lesen';
  }

  @override
  String get s_68022ee7 => 'Alle';

  @override
  String get s_542b67cc => 'Mehr Filter';

  @override
  String get s_ec977df0 => 'Quelle';

  @override
  String get s_50d471b2 => 'Zurücksetzen';

  @override
  String get s_37361909 => 'Sichtbarkeit des Diagramms';

  @override
  String get s_b1288e4a => 'Alle anzeigen';

  @override
  String get s_6b2b7015 => 'Alle verstecken';

  @override
  String get s_e91a9228 => 'Zeigen Sie nur die Diagramme an, die Ihnen wichtig sind; blenden Sie den Rest aus.';

  @override
  String get s_fe93ef35 => 'Anwenden';

  @override
  String get s_0d65fca2 => '[《》「」]';

  @override
  String s_9380d869({required int? daysUntilDue}) {
    return 'Fällig in $daysUntilDue Tagen';
  }

  @override
  String get s_0e13c16f => 'Statistik';

  @override
  String get s_3ad4c4c8 => 'Leseprofil';

  @override
  String s_7c6c253b({required Object label}) {
    return 'Dieser Zeitraum · $label';
  }

  @override
  String get s_88c0b751 => 'Wird dem Abschluss- oder Aktivitätsdatum jedes Buches zugeordnet';

  @override
  String get s_50ba5fd5 => 'Bücher';

  @override
  String get s_cc4556af => 'Bücher hinzugefügt';

  @override
  String get s_3509a9f8 => '-Tage';

  @override
  String get s_a7e9ff0f => 'pts';

  @override
  String get s_58d90b89 => 'Aktuelles Regal';

  @override
  String get s_c3bb899b => 'Snapshot-Zahlen, unbeeinflusst vom obigen Zeitfilter';

  @override
  String get s_563edd9d => 'Gesamt Bücher';

  @override
  String get s_0d8d3eb3 => 'Lesesträhne';

  @override
  String get s_4ab30c5b => 'Angefangen, aber ins Stocken geraten';

  @override
  String s_b563f985({required Object label}) {
    return 'Struktur · $label';
  }

  @override
  String s_a7e09561({required Object length}) {
    return '$length books included';
  }

  @override
  String get s_c6cc650b => 'Statusaufschlüsselung';

  @override
  String get s_8137585d => 'Top 8 Kategorien';

  @override
  String s_f92480e2({required Object length}) {
    return '$length Kategorien';
  }

  @override
  String get s_50feb68a => 'Lesen pro Monat';

  @override
  String get s_750a3b1c => 'Noch keine Leseaktivität in diesem Bereich';

  @override
  String get s_4d7dd157 => 'Monatliche Lesezeit';

  @override
  String get s_5a78dc03 => 'Wird nach dem Import der jährlichen WeRead-Statistiken angezeigt';

  @override
  String get s_5b37ad6b => 'Bewertungsverteilung';

  @override
  String s_3c0e984b({required Object toStringAsFixed, required Object unratedCount}) {
    return 'Durchschnittlich $toStringAsFixed · $unratedCount unbewertet';
  }

  @override
  String get s_3c1cb8ee => 'Aktuell keine Bewertungen ';

  @override
  String get s_01d886c7 => 'Fortschrittsverteilung';

  @override
  String s_ecf53f5a({required Object readingInRange}) {
    return '$readingInRange in Bearbeitung';
  }

  @override
  String get s_faf98ba4 => 'In diesem Sortiment sind keine Bücher in Bearbeitung';

  @override
  String s_77030fdc({required Object length}) {
    return '$length -Plattformen';
  }

  @override
  String s_cea9cf70({required Object first}) {
    return '$first';
  }

  @override
  String s_c4e530bb({required Object first, required Object last}) {
    return '$first–$last';
  }

  @override
  String s_00fbaae1({required Object scope, required Object toStringAsFixed}) {
    return '$scope · $toStringAsFixed h insgesamt';
  }

  @override
  String s_e7b115df({required Object join}) {
    return 'WeRead yearly statistics only cover $join, so this chart is drawn by calendar year; the finished-books chart above uses the most recent 12 months.';
  }

  @override
  String s_9ef861db({required Object name, required Object toInt}) {
    return '$name@NL@@$toInt Bücher';
  }

  @override
  String s_2cf3ef4e({required Object i, required Object toInt}) {
    return '$i · $toInt Bücher';
  }

  @override
  String s_e241a8ef({required Object i, required Object toStringAsFixed}) {
    return '$i · $toStringAsFixed h';
  }

  @override
  String get s_1597bc27 => 'KI-Lesebericht';

  @override
  String s_5024726e({required Object reportCount}) {
    return '$reportCount archiviert · nach Jahr / Monat abgelegt, jederzeit erneut besuchen';
  }

  @override
  String get s_73f01b82 => 'Generieren Sie eine jährliche / monatliche Lesezusammenfassung; öffnen Sie eine, um sie zu erstellen';

  @override
  String get s_530f5951 => 'Ansicht';

  @override
  String get s_d51cd7ae => 'Erstellen';

  @override
  String get s_f8525cf2 => 'Noch keine Daten vorhanden';

  @override
  String s_854a34ca({required Object author}) {
    return ', von $author';
  }

  @override
  String s_edf331af({required Object detail}) {
    return ': $detail';
  }

  @override
  String s_50018e2c({required Object hint}) {
    return '\nZusätzlicher Kontext: $hint\n';
  }

  @override
  String s_a537d6ac({required Object first}) {
    return '(gesichert auf $first)';
  }

  @override
  String s_acd7a061({required Object failed}) {
    return ', $failed fehlgeschlagen';
  }

  @override
  String get s_da4d4d27 => '· mit dem LLM aufgeräumt';

  @override
  String s_af735e5a({required Object repairedTitles}) {
    return '· abgeschlossene $repairedTitles verkürzte Titel';
  }

  @override
  String get navNotes => 'Aufzeichnungen';

  @override
  String get notesViewByTime => 'Nach Zeit';

  @override
  String get notesViewByBook => 'Nach Buch';

  @override
  String get notesFilterByBook => 'Filtern nach';

  @override
  String get notesAllBooks => 'Alle Bücher';

  @override
  String get notesBookMissing => 'Buch entfernt';

  @override
  String notesOverview({required int count, required int books}) {
    return '$count Notizen · in $books Büchern';
  }

  @override
  String notesMoreCount({required int count}) {
    return '$count mehr';
  }

  @override
  String get notesEmptyTitle => 'Es gibt noch keine Notizen';

  @override
  String get notesEmptyDesc => 'Öffnen Sie ein beliebiges Buch und fügen Sie unten auf der Detailseite ein Highlight oder einen Gedanken hinzu — sie werden hier gesammelt.';

  @override
  String get notesEmptyFilteredTitle => 'Noch keine Notizen für dieses Buch';

  @override
  String get notesEmptyFilteredDesc => 'Wähle ein anderes Buch aus oder lösche den Filter, um den Rest zu sehen.';

  @override
  String get notesClearFilter => 'Filter löschen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageDesc => 'Wählen Sie die von der App verwendete Sprache aus. Die Standardeinstellung ist Ihre Systemeinstellung.';

  @override
  String get settingsLanguageSystem => 'Systemstandard';

  @override
  String get settingsCategoryPick => 'Kategorie auswählen';

  @override
  String get settingsCategoryEmpty => 'Keine Kategorien mehr — füge eine hinzu oder stelle die Standardwerte wieder her.';

  @override
  String get langZh => '简体中文';

  @override
  String get langEn => 'Deutsch';

  @override
  String get langDe => 'Deutsch';

  @override
  String get langFr => 'Français';

  @override
  String get langEs => 'Español';

  @override
  String get settingsAppearance => 'Aussehen';

  @override
  String get settingsAppearanceDesc => 'Wählen Sie ein Thema und einen hellen oder dunklen Modus.';

  @override
  String get statusWishHint => 'Noch nicht gestartet.';

  @override
  String get statusReadingHint => 'Wird gerade gelesen. Erreicht 100 % Fortschritt, wird es automatisch abgeschlossen.';

  @override
  String get statusFinishedHint => 'Fertig. Schieben Sie den Fortschritt auf 100% und er wird automatisch markiert.';

  @override
  String get statusShelvedHint => 'Angefangen, aber vorerst nicht geplant, weiterzumachen. Wechseln Sie zurück zu Lesen, um es wieder aufzunehmen.';

  @override
  String get borrowTitle => 'huazuar';

  @override
  String get borrowDesc => 'Markieren Sie das Buch als geliehen, mit einem Kreditgeber und einem Fälligkeitsdatum.';

  @override
  String get borrowFlag => 'Dieses Buch ist geliehen';

  @override
  String get borrowFrom => 'Entliehen von';

  @override
  String get borrowFromHint => 'z. B. Stadtbibliothek, ein Kollege';

  @override
  String get borrowDue => 'Fälligkeitsdatum';

  @override
  String get borrowDueUnset => 'Nicht eingestellt';

  @override
  String borrowDueIn({required int days}) {
    return '$days Tage bis zur Fälligkeit';
  }

  @override
  String borrowOverdue({required int days}) {
    return 'Überfällig um $days Tage';
  }

  @override
  String get borrowClearDue => 'Datum entfernen';

  @override
  String get borrowReturn => 'Als Zurückgegeben markieren';

  @override
  String get borrowReturnDesc => 'Dies löscht das Kreditkennzeichen, den Kreditgeber und das Fälligkeitsdatum und storniert die Rücksendeerinnerung.';

  @override
  String get borrowReturned => 'Als zurückgegeben markiert';

  @override
  String get statusSectionTitle => 'ICQ-Status wird gelesenComment';

  @override
  String get planSectionTitle => 'Lesepläne';

  @override
  String get planSectionDesc => 'Legen Sie ein Ziel fest, das Sie tatsächlich einhalten können. Pläne bleiben auf diesem Gerät.';

  @override
  String get planEmpty => 'Noch keine Pläne. Fangen Sie klein an — 20 Minuten pro Tag.';

  @override
  String get planAdd => 'Neuer Tarif';

  @override
  String get planEdit => 'Plan bearbeiten';

  @override
  String get planKindDaily => 'Täglich';

  @override
  String get planKindFinishBook => 'Ein Buch fertigstellen';

  @override
  String get planKindDailyDesc => 'Legen Sie eine tägliche Lesezeit fest; beurteilt nach Ihrem täglichen Durchschnitt.';

  @override
  String get planKindFinishBookDesc => 'Wählen Sie ein Buch und eine Frist. Das Erreichen von 100 % schließt es ab.';

  @override
  String get planDailyTarget => 'Tägliches Ziel';

  @override
  String planMinutesUnit({required int n}) {
    return '$n min';
  }

  @override
  String get planPickBook => 'Wähle ein Buch aus';

  @override
  String get planDueLabel => 'Termin';

  @override
  String get planDueUnset => 'Nicht eingestellt';

  @override
  String get planRemind => 'Erinnere mich vor Ablauf der Frist';

  @override
  String get planRemindOff => 'Wenn Sie diese Option aktivieren, wird um Benachrichtigungsberechtigung gebeten. Die Erinnerung storniert sich selbst, sobald der Plan fertig ist.';

  @override
  String get planTitleLabel => 'Name (optional)';

  @override
  String get planTitleHint => 'Lasse das Feld leer, um die Standardrate zu verwenden.';

  @override
  String get planSave => 'Speichern';

  @override
  String get planDelete => 'Entwurf löschen';

  @override
  String get planDeleteConfirm => 'Diesen Plan löschen? Ihre Leseaufzeichnungen sind nicht betroffen.';

  @override
  String get planMarkDone => 'Markiere als erledigt';

  @override
  String get planAchieved => 'Archiviert';

  @override
  String get planMarkToday => 'Heute lesen';

  @override
  String get planDoneToday => 'Für heute';

  @override
  String get planDailyCycleHint => 'Jeder Tag ist ein Neuanfang — ankreuzen zählt nur für heute, und die Erinnerung kommt morgen wieder.';

  @override
  String get planReminderUnavailable => 'Das System konnte die Erinnerung nicht planen (Stromsparen könnte sie blockiert haben). Ihr Plan wurde noch gespeichert.';

  @override
  String planProgressDaily({required String current, required String target}) {
    return 'Tagesdurchschnitt $current / $target min';
  }

  @override
  String planProgressBook({required int current}) {
    return 'Fortschritt $current% · Ziel 100%';
  }

  @override
  String planDaysLeft({required int days}) {
    return '$days days left';
  }

  @override
  String planOverdue({required int days}) {
    return 'Überfällig um $days Tage';
  }

  @override
  String planStreak({required int n}) {
    return '$n-tägige Check-in-Strähne';
  }

  @override
  String get planDueToday => 'Heute fällig';

  @override
  String get planBookGone => 'Das Zielbuch ist nicht mehr in Ihrem Regal';

  @override
  String get planDoneSection => 'Abgeschlossen';

  @override
  String get planReminderDenied => 'Benachrichtigungsberechtigung wurde verweigert, daher können keine Erinnerungen zugestellt werden. Aktivieren Sie es in den Systemeinstellungen.';

  @override
  String get planReminderDailyTitle => 'Das heutige Leseziel ist noch nicht erreicht';

  @override
  String planReminderDailyBody({required int minutes}) {
    return 'Ihr Ziel ist $minutes Minuten — es ist noch Zeit.';
  }

  @override
  String get planReminderBookTitle => 'Eine Leseschlusszeit steht bevor';

  @override
  String planReminderBookBody({required int days}) {
    return 'Your plan is due in $days days. A good time to finish it.';
  }

  @override
  String get settingsPlanReminder => 'Leseerinnerungen';

  @override
  String get reportSettings => 'Report-Einstellungen';

  @override
  String get reportBackfill => 'Fehlende Berichte generieren';

  @override
  String get reportNothingToBackfill => 'Jeder Bericht, der existieren sollte, ist bereits hier.';

  @override
  String get planCheckedIn => 'Als heute gelesen markiert. Deine Serie zählt ab heute neu.';

  @override
  String planCheckedInStreak({required int n}) {
    return 'Erledigt — $n Tage in Folge.';
  }

  @override
  String get planCheckinUndone => 'Die heutige Eintragung wurde rückgängig gemacht.';

  @override
  String get planFinishedToast => 'Plan erfüllt. Die Fristerinnerung wurde storniert.';

  @override
  String reportAutoDone({required int count}) {
    return '$count neue Berichte automatisch erstellt — siehe unten.';
  }

  @override
  String get reportAutoNothingDone => 'Es gab keine Berichte zu erstellen.';

  @override
  String get reportAutoNoticeTitle => 'Dein Lesebericht ist fertig';

  @override
  String get planRemindDailyWhen => 'Erinnert täglich um 21:00 Uhr; morgen wieder.';

  @override
  String get planRemindBookWhen => 'Erinnert einmalig um 21:00 Uhr, drei Tage vor der Frist.';

  @override
  String get reportHistoryEmpty => 'Noch keine Berichte. Wählen Sie einen Zeitraum aus und erstellen Sie unten Ihren ersten.';

  @override
  String get reportNoKey => 'Kein Modell konfiguriert, daher können keine Berichte generiert werden. Fügen Sie zuerst einen Schlüssel in den Einstellungen hinzu.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsBrightness => 'Hell oder dunkel';

  @override
  String get brightnessSystem => 'Nach-\nanlage';

  @override
  String get brightnessLight => 'Licht';

  @override
  String get brightnessDark => 'Dunkel';

  @override
  String get themeGreen => 'Grün';

  @override
  String get themeInk => 'Druckfarbe';

  @override
  String get themeBlue => 'Blue';

  @override
  String get themePlum => 'Pflaume';

  @override
  String get themeLagoon => 'Lagune';

  @override
  String get themeBerry => 'Beere';

  @override
  String get settingsChannels => 'Verbundene Services';

  @override
  String get settingsChannelsDesc => 'Synchronisieren Sie Ihr Regal und machen Sie Fortschritte von anderen Leseplattformen. WeRead wird heute unterstützt; weitere Plattformen werden hinzugefügt, wenn sie ihre APIs öffnen.';

  @override
  String get settingsChannelsHint => 'Schlüssel werden nur im Systemschlüsselbund dieses Geräts gespeichert und niemals hochgeladen.';

  @override
  String get settingsChannelAddHint => 'Weitere Dienstleistungen sind auf dem Weg.';

  @override
  String get importAccuracyTitle => 'Die Ergebnisse können ungenau sein';

  @override
  String get importAccuracyDesc => 'Titel und Autoren werden durch OCR- und KI-Modelle abgeleitet, sodass sie ein Wort falsch lesen oder das falsche Buch auswählen können. Bitte vor dem Speichern überprüfen.';

  @override
  String get importFromImageTitle => 'Aus Screenshot importieren';

  @override
  String get importFromImageDesc => 'Wählen Sie einen Screenshot Ihres Regals und erkennen Sie die Bücher darauf.';

  @override
  String get importFromCameraTitle => 'Import per Kamera';

  @override
  String get importFromCameraDesc => 'Machen Sie ein Foto von Ihrem Regal und erkennen Sie die Bücher darauf.';

  @override
  String get insights => 'Insights';

  @override
  String get insightsDesc => 'Ihr langfristiges Leseprofil sowie Berichte nach Monat und Jahr.';

  @override
  String get chronology => 'Timeline';

  @override
  String get chronologyDesc => 'Ihre Lektüre Monat für Monat. Tippe auf eine Karte, um das Buch zu öffnen.';

  @override
  String get chronologyEmpty => 'In diesem Jahr ist noch nichts fertiggestellt oder in Arbeit.';

  @override
  String get chronologyFinished => 'Abgeschlossen';

  @override
  String get chronologyReading => 'Lesen';

  @override
  String get chronologyShelved => 'Regalboden';

  @override
  String get chronologyWish => 'Want to Read [Will ich lesen]';

  @override
  String chronologyMore({required int n}) {
    return '$n more — den ganzen Monat anzeigen';
  }

  @override
  String get reportStyle => '„Report Style“';

  @override
  String get reportStyleDesc => 'Wählen Sie den Ton und die Struktur der generierten Berichte oder schreiben Sie Ihre eigene Eingabeaufforderung.';

  @override
  String get reportStyleRational => 'Einfache Fakten';

  @override
  String get reportStyleRationalDesc => 'Gibt die Daten objektiv an: kein Lob, kein Anstupsen, klar aufgeschlüsselt.';

  @override
  String get reportStyleWarm => 'Herzliche Ermutigung';

  @override
  String get reportStyleWarmDesc => 'Erkennt Ihre Konsequenz an und gibt sanft Ratschläge.';

  @override
  String get reportStyleDirect => 'KLARTEXT.';

  @override
  String get reportStyleDirectDesc => 'Nennt die Probleme ohne zu erweichen, für Leser, die es schlicht haben wollen.';

  @override
  String get reportStyleConcise => 'Kurz';

  @override
  String get reportStyleConciseDesc => 'Nur die Schlussfolgerungen, so kurz wie möglich.';

  @override
  String get reportStyleCustom => 'Angepasst';

  @override
  String get reportStyleCustomDesc => 'Schreiben Sie die Eingabeaufforderung selbst und steuern Sie genau, wie Berichte gelesen werden.';

  @override
  String get reportStyleCustomHint => 'z. B. Sprechen Sie mit mir in der zweiten Person, wie ein Freund, der meine Lektüre kommentiert.';

  @override
  String get reportReadMore => 'Vollständiger Bericht';

  @override
  String get reportNoContent => '(dieser Bericht hat keinen Fließtext)';

  @override
  String get s_9f2c1d4e => 'Überblick';

  @override
  String get s_0f2b6c1a => 'Lesen dieses Zeitraums';

  @override
  String get s_7d1a4e35 => 'regalaufbau';

  @override
  String get s_3c58b0d2 => 'Lesegewohnheiten';

  @override
  String get s_4b7e2a19 => 'Nennenswerte Bücher';

  @override
  String get s_6e39f7c4 => '- Profil';

  @override
  String get s_1a8d53f6 => 'Was als nächstes zu lesen ist';

  @override
  String get s_2f9d1a4b => 'Schlagwörter';

  @override
  String get s_5c7e3d81 => 'Noch keine Schlagwörter';

  @override
  String s_3e8f5b26({required Object title}) {
    return '»$title« löschen?';
  }

  @override
  String get s_7d4c2e91 => 'Leseprotokolle und Pläne werden mitgelöscht. Deine Notizen bleiben erhalten – sie stehen weiter in der Rubrik „Notizen“. Das lässt sich nicht rückgängig machen.';

  @override
  String s_1f6a8d37({required Object title}) {
    return '»$title« gelöscht';
  }

  @override
  String get s_4b2c9e58 => 'Kategorien';

  @override
  String get s_8d3f6a12 => 'Kategorien hinzufügen, umbenennen oder entfernen. Bücher einer entfernten Kategorie wandern nach »Nicht kategorisiert«.';

  @override
  String get s_2c8b5d09 => 'Kategoriename';

  @override
  String get s_9f4e7a35 => 'Der Kategoriename darf nicht leer sein';

  @override
  String get s_7a2d6c81 => 'Diese Kategorie gibt es bereits';

  @override
  String s_5e9c1b47({required Object name}) {
    return '»$name« hinzugefügt';
  }

  @override
  String s_3b7f2d64({required Object name}) {
    return '»$name« gelöscht';
  }

  @override
  String s_8c4a1e92({required Object name}) {
    return 'Kategorie »$name« löschen?';
  }

  @override
  String s_1d7b3f08({required Object count}) {
    return '$count Bücher darin wandern nach »Nicht kategorisiert«.';
  }

  @override
  String get s_6a9e4c27 => 'Umbenennen';

  @override
  String get s_2f5d8b13 => 'Standardkategorien wiederherstellen';

  @override
  String get s_4e1c7a69 => 'Standardkategorien wiederhergestellt';

  @override
  String get s_9c3f5d21 => 'Eigen';

  @override
  String s_9d2e7f13({required Object name, required Object count}) {
    return 'Umbenannt in »$name«; $count Bücher aktualisiert';
  }

  @override
  String get themeBgStarfield => 'Sternenhimmel';

  @override
  String get themeBgMist => 'Bergnebel';

  @override
  String get themeBgMoss => 'Moosgarten';

  @override
  String get themeBgDusk => 'Abendlicht';

  @override
  String get themeBgCat => 'Katzenruhe';

  @override
  String get themeBgDog => 'Hundewiese';

  @override
  String get s_2f8a1c47 => 'Textur';

  @override
  String get checkUpdate => 'Nach Updates suchen';

  @override
  String get checkUpdateDesc => 'Prüfen, ob eine neuere Version vorliegt – wenn ja, steht hier, was sich geändert hat.';

  @override
  String get checkingForUpdate => 'Wird geprüft…';

  @override
  String get updateUpToDate => 'Du hast bereits die neueste Version';

  @override
  String updateUpToDateDesc({required String version}) {
    return 'Du verwendest $version. Es gibt derzeit keine neuere Version.';
  }

  @override
  String updateAvailable({required String version}) {
    return '$version ist verfügbar';
  }

  @override
  String updateAvailableDesc({required String current, required String latest}) {
    return 'Du verwendest $current. Aktualisiere auf $latest, wenn du möchtest – es wird nichts automatisch geladen.';
  }

  @override
  String get updateNotesTitle => 'Was sich geändert hat';

  @override
  String get updateNoNotes => 'Diesmal wurden keine Versionshinweise geschrieben.';

  @override
  String updateDownload({required String version}) {
    return '$version herunterladen';
  }

  @override
  String get updateOpenRelease => 'Release-Seite öffnen';

  @override
  String get updateCheckFailed => 'Update-Prüfung fehlgeschlagen';

  @override
  String get updateCheckFailedNetwork => 'Server nicht erreichbar. Bitte Netzwerk prüfen und erneut versuchen.';

  @override
  String get updateCheckFailedMalformed => 'Die Serverantwort war unlesbar. Bitte später erneut versuchen.';

  @override
  String updateNeverInstalled({required String version}) {
    return 'Kein Installationspaket gefunden: $version ist veröffentlicht, aber es wurde keine APK gefunden.';
  }

  @override
  String updateReleasedOn({required String date}) {
    return 'Veröffentlicht $date';
  }
}
