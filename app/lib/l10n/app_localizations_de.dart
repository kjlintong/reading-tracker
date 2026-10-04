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
  String get s_01955ddf => 'Wenn diese Option aktiviert ist, generiert das Öffnen dieser Seite automatisch alle fehlenden Jahresberichte und den Monatsbericht des letzten Monats.';

  @override
  String get s_b2a52a3d => 'Automatische Generierung fehlt';

  @override
  String get s_b233138e => 'Jährlich';

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
  String get s_5aa23087 => 'None';

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
  String get s_6e464c0e => 'Photograph a cover, spine or page; the title is detected and the rest of the metadata filled in. Results can be off — check before saving.';

  @override
  String get s_a5452d46 => 'Sync shelf from channels';

  @override
  String get s_d40e2a14 => 'Reads your shelf and reading status through the official API of your configured channels — no screenshots needed. WeRead is supported today; more channels are on the way.';

  @override
  String get s_af94a367 => 'Sync reading progress';

  @override
  String get s_59d2efab => 'Fetches each book\'s reading percentage and accumulated time. Some channel shelf endpoints omit progress, so it needs a separate request per book.';

  @override
  String get s_fa52186c => 'CSV / Notion import';

  @override
  String get s_2c78f2b8 => 'One-click migration from a Notion CSV export: column names are detected automatically and custom fields are preserved.';

  @override
  String get s_238b14fc => 'Processing…';

  @override
  String s_ed4b0551({required Object length}) {
    return '$length books couldn\'t be imported';
  }

  @override
  String s_ec50ebde({required Object length}) {
    return '…and $length more';
  }

  @override
  String get s_18307d56 => 'Add manually';

  @override
  String s_cc0eef03({required Object length}) {
    return '$length books recognized';
  }

  @override
  String get s_0f466d7a => 'Select all';

  @override
  String get s_42b2fafa => 'Deselect all';

  @override
  String s_7feb7674({required Object keptLines, required Object repairedTitles, required Object totalLines, required Object usedLlm}) {
    return 'Read $totalLines lines of text, kept $keptLines books$usedLlm$repairedTitles';
  }

  @override
  String get s_4d52323f => 'Items marked \"completed\" or \"inferred\" are not verbatim from the image — please check them before importing. You can tap any title or author to edit it.';

  @override
  String get s_0f40975c => 'Add one manually (missed by OCR)';

  @override
  String s_fdc0acd1({required Object length}) {
    return 'Import the $length selected';
  }

  @override
  String get s_4443bd2c => 'The original image was truncated';

  @override
  String s_7af46a28({required Object progressPercent}) {
    return 'Progress $progressPercent%';
  }

  @override
  String s_4737de25({required Object toStringAsFixed}) {
    return 'Confidence $toStringAsFixed%';
  }

  @override
  String s_2df91ffc({required Object rawText}) {
    return 'Original image: $rawText';
  }

  @override
  String get s_7bbe0f10 => 'Author (optional)';

  @override
  String get s_bd13cf0b => 'Delete this one';

  @override
  String get s_c048f107 => 'Statistics range';

  @override
  String get s_89c61e4a => 'Total books';

  @override
  String get s_9da15a74 => 'Status breakdown';

  @override
  String get s_130a42ae => 'Category breakdown';

  @override
  String get s_98f42577 => 'Source breakdown';

  @override
  String get s_5e8ebbe6 => 'Format breakdown';

  @override
  String get s_5182e58a => 'Average rating';

  @override
  String get s_50bcc778 => 'Books rated';

  @override
  String get s_59c5e73a => 'Reading time (minutes)';

  @override
  String get s_48529b9f => 'Days with reading activity';

  @override
  String get s_7be1388c => 'No LLM key configured. Fill one in under Settings → LLM to generate.';

  @override
  String get s_992d7786 => 'The model returned no usable tags; try another model';

  @override
  String get s_eead3bcd => 'Replace with this set?';

  @override
  String s_b9da6464({required Object length, required Object length_1}) {
    return 'Your current $length tags will be replaced with these $length_1. You can still edit or delete them one by one afterwards.';
  }

  @override
  String get s_89829921 => 'Replace';

  @override
  String get s_0f8acec9 => 'Replaced with the main tags';

  @override
  String get s_93aebfd1 => 'That tag is already listed above';

  @override
  String get s_bca518fd => 'Added to the main tags';

  @override
  String s_284dfaab({required Object text}) {
    return 'Removed \"$text\"';
  }

  @override
  String get s_8eb8d18d => 'Edit tag';

  @override
  String get s_35c48d07 => 'This is a tag you wrote yourself; there\'s no automatic basis for it.';

  @override
  String get s_724386f0 => 'Add tag';

  @override
  String get s_fdd8c684 => 'Tags you write yourself aren\'t validated and won\'t be overwritten by recomputation.';

  @override
  String get s_7b328e58 => 'Reset tags to default?';

  @override
  String get s_b9a4d4ef => 'Your manual edits will be cleared and the tags will be inferred again from your current library.';

  @override
  String get s_0fcef2c8 => 'Restored to tags inferred from your library';

  @override
  String get s_e97565e5 => 'My reading profile';

  @override
  String s_783e43af({required Object e}) {
    return 'Couldn\'t generate the share image: $e';
  }

  @override
  String get s_14f92b04 => 'Generate share image';

  @override
  String get s_a17c4e02 => 'Saved to your photos';

  @override
  String s_3f81d5b6({required Object e}) {
    return 'Couldn\'t save: $e';
  }

  @override
  String get s_c6d1e7a3 => 'Image ready';

  @override
  String get s_b8e4c9a1 => 'Save image to this device';

  @override
  String get s_51ebc0d1 => 'Recompute';

  @override
  String get s_6c64acc5 => 'My reading personality tags';

  @override
  String s_03bf36af({required Object length}) {
    return 'Inferred from $length books';
  }

  @override
  String get s_a789d74f => 'All the tags have been deleted. Tap \"Add\" below to write your own, or reset to default and let the app infer them again.';

  @override
  String get s_a1d885c1 => 'Add';

  @override
  String get s_64bff158 => 'Tap a tag to rename or delete it. For rule-inferred tags, the numbers behind them are visible in the edit dialog.';

  @override
  String get s_84bf2c49 => 'Generating…';

  @override
  String get s_5a251fee => 'Generate another set with AI';

  @override
  String get s_18be3bbe => 'Reset to default';

  @override
  String get s_7ae84af3 => 'Reading preferences';

  @override
  String s_aeed65e7({required Object length}) {
    return '$length categories';
  }

  @override
  String get s_f2a9e2a4 => 'The circle\'s area is proportional to the number of books (so the radius is the square root of the count — using the count directly as the radius would exaggerate differences and mislead).';

  @override
  String s_abd0dab0({required Object stamp}) {
    return 'AI generated · $stamp';
  }

  @override
  String get s_7ea8e671 => 'Replace main tags';

  @override
  String get s_d1a58b2f => 'Tap a single tag to add it to the main tags, or replace the whole set. This set is generated by the model from aggregate statistics, so its basis is less explicit than the rule-based one.';

  @override
  String get s_a38881a0 => 'No books in this range yet';

  @override
  String get s_20fde694 => 'Try another time range, or import some books first';

  @override
  String get s_9fe34cff => 'No category data yet';

  @override
  String s_d9579b73({required Object bookCount, required Object rangeLabel}) {
    return '$rangeLabel · $bookCount books';
  }

  @override
  String get s_bfc50de8 => 'Personality tags';

  @override
  String get s_ab5cc063 => 'Reading preferences';

  @override
  String get s_9de44e0f => 'Reading tracker · My shelf';

  @override
  String get s_20a63774 => 'Choose statistics range';

  @override
  String get s_d507abff => 'OK';

  @override
  String get s_ff31410d => 'Custom…';

  @override
  String get s_72cca1f6 => 'Configuration saved locally';

  @override
  String s_b6477017({required Object name}) {
    return 'Filled in $name; the API key is still needed';
  }

  @override
  String get s_533f5118 => 'Fetching model list…';

  @override
  String s_648219b9({required Object id}) {
    return 'Selected model: $id';
  }

  @override
  String s_baf95794({required Object length}) {
    return '$length models available (none selected)';
  }

  @override
  String get s_e37cab47 => 'Testing the connection…';

  @override
  String s_c17c1a05({required Object latencyMs, required Object model, required Object reply}) {
    return 'Connected · $model\nTook $latencyMs ms; the model replied \"$reply\"';
  }

  @override
  String get s_5df0d12b => 'Verifying WeRead key…';

  @override
  String s_bd245b07({required Object n}) {
    return 'Key is valid; the shelf currently has $n books';
  }

  @override
  String s_73f89115({required Object host}) {
    return 'Can\'t reach $host\nCheck your network, whether the base URL is complete (including /v1), and whether the service needs a proxy';
  }

  @override
  String get s_9038e16e => 'The endpoint timed out (180 seconds)';

  @override
  String s_e0710bf5({required Object e, required int? statusCode}) {
    return 'Service returned $statusCode: $e';
  }

  @override
  String s_24d6c7ae({required Object name}) {
    return 'Request failed: $name';
  }

  @override
  String get s_4d3eb2b3 => 'Search models';

  @override
  String s_17d94005({required Object length}) {
    return '$length in total';
  }

  @override
  String get s_a48ae43a => 'Clicking a suggestion writes the model name in';

  @override
  String get s_b5c7b82d => 'Settings';

  @override
  String get s_bc90fa59 => 'Used to sync your shelf and reading progress. Scan the QR code to open weread.qq.com/r/weread-skills to get one.';

  @override
  String get s_e44e9f26 => 'Verify key';

  @override
  String get s_75bf6943 => 'LLM';

  @override
  String get s_9e8f6691 => 'Used for metadata fallback, screenshot recognition cleanup and reading reports.';

  @override
  String get s_cc3c9556 => 'Provider presets';

  @override
  String get s_9021b9f9 => 'Selecting one fills in the address and model';

  @override
  String get s_1fd51aaa => 'Model name';

  @override
  String get s_209e1f28 => 'Use \"Fetch models\" to pick from the list your account actually has';

  @override
  String get s_ab135d7c => 'Fetch models';

  @override
  String get s_a46a5664 => 'Test connection';

  @override
  String get s_e4f7e107 => 'Show key';

  @override
  String get s_b13be56e => 'Hide key';

  @override
  String get s_9ac01f6b => 'Test and Fetch both save your entries first.';

  @override
  String get s_0001747c => 'Screenshot recognition';

  @override
  String get s_3f5cbdbf => 'Determines how well photo and screenshot imports are recognized.';

  @override
  String get s_9130a4ed => 'Image enhancement preprocessing';

  @override
  String get s_b79fc99c => 'Enlarges and sharpens the image first, so small titles are recognized better.';

  @override
  String get s_9695a603 => 'Use the LLM to clean up recognition results';

  @override
  String get s_267118b5 => 'Let the LLM clean up the recognized titles. Needs an LLM key and uses tokens.';

  @override
  String get s_6d7e1f9f => 'Recognition mode';

  @override
  String get s_ed144a76 => 'Auto (multimodal first, falls back to on-device)';

  @override
  String get s_c7bab837 => 'Multimodal LLM reads the image directly';

  @override
  String get s_d8f3da2a => 'On-device OCR (offline, free)';

  @override
  String get s_f22e4cd2 => 'On-device OCR works offline but may miss titles; the multimodal model reads the layout but needs a network and may invent one. \"Auto\" uses both.';

  @override
  String get s_67677b3d => 'Data';

  @override
  String get s_d596ba9b => 'Export the whole database as JSON to move to another device. A fresh install starts with an empty shelf; add books from the Import tab to get going.';

  @override
  String get s_39239742 => 'One-tap export / restore';

  @override
  String get s_3c21597a => 'All changes are saved to this device\'s database automatically — no manual save needed.';

  @override
  String get s_68885a92 => 'Keys are stored only in this device\'s database; they are never bundled with the app or uploaded.';

  @override
  String get s_9b3c95d4 => 'Recently updated';

  @override
  String get s_97428491 => 'Recently finished';

  @override
  String get s_8f38c041 => 'Highest rated';

  @override
  String get s_50a7317f => 'Most progress';

  @override
  String get s_b5538557 => 'Title A–Z';

  @override
  String s_e3cd14ba({required Object title}) {
    return 'Added \"$title\"';
  }

  @override
  String get s_296fc9b4 => 'Shelf';

  @override
  String get s_a444b428 => 'Sort';

  @override
  String get s_fa0a5cdd => 'Switch to list';

  @override
  String get s_cb4a4231 => 'Switch to cover grid';

  @override
  String get s_78966c42 => 'Search title / author / publisher';

  @override
  String get s_8ed41c6c => 'No books match these filters';

  @override
  String get s_bd33274a => 'No books yet — add some from the Import tab';

  @override
  String s_0cd6d0f8({required Object length}) {
    return '$length books';
  }

  @override
  String s_ff7e02df({required Object finished, required Object reading}) {
    return '$reading reading · $finished read';
  }

  @override
  String get s_68022ee7 => 'All';

  @override
  String get s_542b67cc => 'More filters';

  @override
  String get s_ec977df0 => 'Source';

  @override
  String get s_50d471b2 => 'Reset';

  @override
  String get s_37361909 => 'Chart visibility';

  @override
  String get s_b1288e4a => 'Show all';

  @override
  String get s_6b2b7015 => 'Hide all';

  @override
  String get s_e91a9228 => 'Show only the charts you care about; hide the rest.';

  @override
  String get s_fe93ef35 => 'Apply';

  @override
  String get s_0d65fca2 => '[《》「」]';

  @override
  String s_9380d869({required int? daysUntilDue}) {
    return 'Due in $daysUntilDue days';
  }

  @override
  String get s_0e13c16f => 'Statistics';

  @override
  String get s_3ad4c4c8 => 'Reading profile';

  @override
  String s_7c6c253b({required Object label}) {
    return 'This period · $label';
  }

  @override
  String get s_88c0b751 => 'Attributed by each book\'s completion or activity date';

  @override
  String get s_50ba5fd5 => 'books';

  @override
  String get s_cc4556af => 'Books added';

  @override
  String get s_3509a9f8 => 'days';

  @override
  String get s_a7e9ff0f => 'pts';

  @override
  String get s_58d90b89 => 'Current shelf';

  @override
  String get s_c3bb899b => 'Snapshot figures, unaffected by the time filter above';

  @override
  String get s_563edd9d => 'Total books';

  @override
  String get s_0d8d3eb3 => 'Reading streak';

  @override
  String get s_4ab30c5b => 'Started but stalled';

  @override
  String s_b563f985({required Object label}) {
    return 'Structure · $label';
  }

  @override
  String s_a7e09561({required Object length}) {
    return '$length books included';
  }

  @override
  String get s_c6cc650b => 'Status breakdown';

  @override
  String get s_8137585d => 'Top 8 categories';

  @override
  String s_f92480e2({required Object length}) {
    return '$length categories';
  }

  @override
  String get s_50feb68a => 'Reading per month';

  @override
  String get s_750a3b1c => 'No reading activity in this range yet';

  @override
  String get s_4d7dd157 => 'Monthly reading time';

  @override
  String get s_5a78dc03 => 'Shown after importing WeRead yearly statistics';

  @override
  String get s_5b37ad6b => 'Rating distribution';

  @override
  String s_3c0e984b({required Object toStringAsFixed, required Object unratedCount}) {
    return 'Average $toStringAsFixed · $unratedCount unrated';
  }

  @override
  String get s_3c1cb8ee => 'No ratings yet';

  @override
  String get s_01d886c7 => 'In-progress distribution';

  @override
  String s_ecf53f5a({required Object readingInRange}) {
    return '$readingInRange in progress';
  }

  @override
  String get s_faf98ba4 => 'No books in progress in this range';

  @override
  String s_77030fdc({required Object length}) {
    return '$length platforms';
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
    return '$scope · $toStringAsFixed h total';
  }

  @override
  String s_e7b115df({required Object join}) {
    return 'WeRead yearly statistics only cover $join, so this chart is drawn by calendar year; the finished-books chart above uses the most recent 12 months.';
  }

  @override
  String s_9ef861db({required Object name, required Object toInt}) {
    return '$name\n$toInt books';
  }

  @override
  String s_2cf3ef4e({required Object i, required Object toInt}) {
    return '$i · $toInt books';
  }

  @override
  String s_e241a8ef({required Object i, required Object toStringAsFixed}) {
    return '$i · $toStringAsFixed h';
  }

  @override
  String get s_1597bc27 => 'AI reading report';

  @override
  String s_5024726e({required Object reportCount}) {
    return '$reportCount archived · filed by year / month, revisit anytime';
  }

  @override
  String get s_73f01b82 => 'Generate a yearly / monthly reading summary; open one to create it';

  @override
  String get s_530f5951 => 'View';

  @override
  String get s_d51cd7ae => 'Generate';

  @override
  String get s_f8525cf2 => 'No data yet';

  @override
  String s_854a34ca({required Object author}) {
    return ', by $author';
  }

  @override
  String s_edf331af({required Object detail}) {
    return ': $detail';
  }

  @override
  String s_50018e2c({required Object hint}) {
    return '\nAdditional context: $hint\n';
  }

  @override
  String s_a537d6ac({required Object first}) {
    return '(backed up on $first)';
  }

  @override
  String s_acd7a061({required Object failed}) {
    return ', $failed failed';
  }

  @override
  String get s_da4d4d27 => ' · cleaned up with the LLM';

  @override
  String s_af735e5a({required Object repairedTitles}) {
    return ' · completed $repairedTitles truncated titles';
  }

  @override
  String get navNotes => 'Records';

  @override
  String get notesViewByTime => 'By time';

  @override
  String get notesViewByBook => 'By book';

  @override
  String get notesFilterByBook => 'Filter by book';

  @override
  String get notesAllBooks => 'All books';

  @override
  String get notesBookMissing => 'Book removed';

  @override
  String notesOverview({required int count, required int books}) {
    return '$count notes · across $books books';
  }

  @override
  String notesMoreCount({required int count}) {
    return '$count more';
  }

  @override
  String get notesEmptyTitle => 'No notes yet';

  @override
  String get notesEmptyDesc => 'Open any book and add a highlight or thought at the bottom of its detail page — they will collect here.';

  @override
  String get notesEmptyFilteredTitle => 'No notes for this book yet';

  @override
  String get notesEmptyFilteredDesc => 'Pick another book, or clear the filter to see the rest.';

  @override
  String get notesClearFilter => 'Clear filter';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageDesc => 'Choose the language used by the app. Defaults to your system setting.';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get langZh => '简体中文';

  @override
  String get langEn => 'English';

  @override
  String get langDe => 'Deutsch';

  @override
  String get langFr => 'Français';

  @override
  String get langEs => 'Español';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceDesc => 'Pick a theme and a light or dark mode.';

  @override
  String get statusWishHint => 'Not started yet.';

  @override
  String get statusReadingHint => 'Currently reading. Reaches 100% progress it becomes Finished automatically.';

  @override
  String get statusFinishedHint => 'Finished. Slide progress to 100% and it is marked automatically.';

  @override
  String get statusShelvedHint => 'Started but not planning to continue for now. Switch back to Reading to pick it up again.';

  @override
  String get borrowTitle => 'Borrowed';

  @override
  String get borrowDesc => 'Mark the book as borrowed, with a lender and a due date.';

  @override
  String get borrowFlag => 'This book is borrowed';

  @override
  String get borrowFrom => 'Borrowed from';

  @override
  String get borrowFromHint => 'e.g. City Library, a colleague';

  @override
  String get borrowDue => 'Due date';

  @override
  String get borrowDueUnset => 'Not set';

  @override
  String borrowDueIn({required int days}) {
    return '$days days until due';
  }

  @override
  String borrowOverdue({required int days}) {
    return 'Overdue by $days days';
  }

  @override
  String get borrowClearDue => 'Clear date';

  @override
  String get borrowReturn => 'Mark as returned';

  @override
  String get borrowReturnDesc => 'This clears the loan flag, the lender and the due date, and cancels the return reminder.';

  @override
  String get borrowReturned => 'Marked as returned';

  @override
  String get statusSectionTitle => 'Reading status';

  @override
  String get planSectionTitle => 'Reading plans';

  @override
  String get planSectionDesc => 'Set a goal you can actually keep. Plans stay on this device.';

  @override
  String get planEmpty => 'No plans yet. Start small — 20 minutes a day.';

  @override
  String get planAdd => 'New plan';

  @override
  String get planEdit => 'Edit plan';

  @override
  String get planKindDaily => 'Read every day';

  @override
  String get planKindFinishBook => 'Finish a book';

  @override
  String get planKindDailyDesc => 'Set a daily reading time; judged on your daily average.';

  @override
  String get planKindFinishBookDesc => 'Pick a book and a deadline. Reaching 100% completes it.';

  @override
  String get planDailyTarget => 'Daily target';

  @override
  String planMinutesUnit({required int n}) {
    return '$n min';
  }

  @override
  String get planPickBook => 'Pick a book';

  @override
  String get planDueLabel => 'Deadline';

  @override
  String get planDueUnset => 'Not set';

  @override
  String get planRemind => 'Remind me before the deadline';

  @override
  String get planRemindOff => 'Turning this on asks for notification permission. The reminder cancels itself once the plan is done.';

  @override
  String get planTitleLabel => 'Plan name (optional)';

  @override
  String get planTitleHint => 'Leave empty to use the default name';

  @override
  String get planSave => 'Save';

  @override
  String get planDelete => 'Delete plan';

  @override
  String get planDeleteConfirm => 'Delete this plan? Your reading records are not affected.';

  @override
  String get planMarkDone => 'Mark as done';

  @override
  String get planAchieved => 'Achieved';

  @override
  String get planMarkToday => 'Read today';

  @override
  String get planDoneToday => 'Done for today';

  @override
  String get planDailyCycleHint => 'Every day is a fresh start — ticking it only counts for today, and the reminder comes back tomorrow.';

  @override
  String get planReminderUnavailable => 'The system couldn\'t schedule the reminder (power-saving may have blocked it). Your plan was still saved.';

  @override
  String planProgressDaily({required String current, required String target}) {
    return 'Daily average $current / $target min';
  }

  @override
  String planProgressBook({required int current}) {
    return 'Progress $current% · target 100%';
  }

  @override
  String planDaysLeft({required int days}) {
    return '$days days left';
  }

  @override
  String planOverdue({required int days}) {
    return 'Overdue by $days days';
  }

  @override
  String planStreak({required int n}) {
    return '$n-day check-in streak';
  }

  @override
  String get planDueToday => 'Due today';

  @override
  String get planBookGone => 'The target book is no longer on your shelf';

  @override
  String get planDoneSection => 'Finished';

  @override
  String get planReminderDenied => 'Notification permission was denied, so reminders cannot be delivered. Enable it in system settings.';

  @override
  String get planReminderDailyTitle => 'Today\'s reading goal is not done yet';

  @override
  String planReminderDailyBody({required int minutes}) {
    return 'Your goal is $minutes minutes — there is still time.';
  }

  @override
  String get planReminderBookTitle => 'A reading deadline is coming up';

  @override
  String planReminderBookBody({required int days}) {
    return 'Your plan is due in $days days. A good time to finish it.';
  }

  @override
  String get settingsPlanReminder => 'Reading reminders';

  @override
  String get reportSettings => 'Report settings';

  @override
  String get reportBackfill => 'Generate missing reports';

  @override
  String get reportNothingToBackfill => 'Every report that should exist is already here.';

  @override
  String get reportHistoryEmpty => 'No reports yet. Pick a period and generate your first one below.';

  @override
  String get reportNoKey => 'No model configured, so reports cannot be generated. Add a key in Settings first.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsBrightness => 'Light or dark';

  @override
  String get brightnessSystem => 'Follow system';

  @override
  String get brightnessLight => 'Light';

  @override
  String get brightnessDark => 'Dark';

  @override
  String get themeGreen => 'Green';

  @override
  String get themeInk => 'Ink';

  @override
  String get themeAmber => 'Amber';

  @override
  String get themeBlue => 'Blue';

  @override
  String get themeRose => 'Rose';

  @override
  String get settingsChannels => 'Connected services';

  @override
  String get settingsChannelsDesc => 'Sync your shelf and progress from other reading platforms. WeRead is supported today; more platforms will be added as they open their APIs.';

  @override
  String get settingsChannelsHint => 'Keys are stored only in this device\'s system keychain and are never uploaded.';

  @override
  String get settingsChannelAddHint => 'More services are on the way.';

  @override
  String get importAccuracyTitle => 'Results may be inaccurate';

  @override
  String get importAccuracyDesc => 'Titles and authors are inferred by OCR and AI models, so they can misread a word or pick the wrong book. Please review before saving.';

  @override
  String get importFromImageTitle => 'Import from screenshot';

  @override
  String get importFromImageDesc => 'Pick a screenshot of your shelf and detect the books on it.';

  @override
  String get importFromCameraTitle => 'Import by camera';

  @override
  String get importFromCameraDesc => 'Take a photo of your shelf and detect the books on it.';

  @override
  String get insights => 'Insights';

  @override
  String get insightsDesc => 'Your long-term reading profile, plus reports by month and year.';

  @override
  String get chronology => 'Timeline';

  @override
  String get chronologyDesc => 'Your reading month by month. Tap a card to open the book.';

  @override
  String get chronologyEmpty => 'Nothing finished or in progress this year yet.';

  @override
  String get chronologyFinished => 'Finished';

  @override
  String get chronologyReading => 'Reading';

  @override
  String get chronologyShelved => 'Shelved';

  @override
  String get chronologyWish => 'Want to read';

  @override
  String chronologyMore({required int n}) {
    return '$n more — see the whole month';
  }

  @override
  String get reportStyle => 'Report style';

  @override
  String get reportStyleDesc => 'Choose the tone and structure of generated reports, or write your own prompt.';

  @override
  String get reportStyleRational => 'Plain facts';

  @override
  String get reportStyleRationalDesc => 'States the data objectively: no praise, no prodding, clearly itemised.';

  @override
  String get reportStyleWarm => 'Warm encouragement';

  @override
  String get reportStyleWarmDesc => 'Acknowledges your consistency and offers advice gently.';

  @override
  String get reportStyleDirect => 'Straight talk';

  @override
  String get reportStyleDirectDesc => 'Names the problems without softening, for readers who want it plain.';

  @override
  String get reportStyleConcise => 'Brief';

  @override
  String get reportStyleConciseDesc => 'Conclusions only, as short as possible.';

  @override
  String get reportStyleCustom => 'Custom';

  @override
  String get reportStyleCustomDesc => 'Write the prompt yourself and control exactly how reports read.';

  @override
  String get reportStyleCustomHint => 'e.g. Talk to me in second person, like a friend commenting on my reading.';

  @override
  String get reportReadMore => 'Read full report';

  @override
  String get reportNoContent => '(this report has no body text)';

  @override
  String get s_9f2c1d4e => 'Overview';

  @override
  String get s_0f2b6c1a => 'Reading this period';

  @override
  String get s_7d1a4e35 => 'Shelf structure';

  @override
  String get s_3c58b0d2 => 'Reading habits';

  @override
  String get s_4b7e2a19 => 'Books worth naming';

  @override
  String get s_6e39f7c4 => 'Reader profile';

  @override
  String get s_1a8d53f6 => 'What to read next';
}
