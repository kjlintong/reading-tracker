import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Readnest';

  @override
  String get navShelf => 'Estantería';

  @override
  String get addBookSheetTitle => 'Añadir un libro';

  @override
  String get addBookManualTitle => 'Introducir manualmente';

  @override
  String get addBookManualDesc => 'Escribe tú el título y el autor: no hace falta ninguna cuenta ni archivo.';

  @override
  String get navStats => 'Estadísticas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get supportDev => 'Apoyar al desarrollador';

  @override
  String get supportDevDesc => 'Todas las funciones son gratuitas, sin anuncios ni compras dentro de la app. Si te sirve para tu lectura, puedes invitarme a un café — es totalmente opcional y nada cambia en ningún caso.';

  @override
  String get openTipPage => 'Invitarme a un café · Ko-fi';

  @override
  String get openTipDomestic => 'Apoyo · Afdian (China)';

  @override
  String get openTipForeign => 'Apoyo · Ko-fi (Internacional)';

  @override
  String get about => 'Acerca de';

  @override
  String get aboutDesc => 'Datos del desarrollador y enlaces relacionados.';

  @override
  String get appIntroPage => 'Sobre esta app';

  @override
  String get developerHomepage => 'Web del desarrollador';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get reportDeleteConfirm => '¿Eliminar este informe? No se puede deshacer.';

  @override
  String get reportDelete => 'Eliminar';

  @override
  String appVersionLabel({required String version}) {
    return 'Versión $version';
  }

  @override
  String get goodreadsImport => 'Importar CSV de Goodreads / biblioteca';

  @override
  String get goodreadsImportDesc => 'Importa un CSV de biblioteca exportado desde Goodreads y servicios similares (título, autor, valoración, estado en la estantería).';

  @override
  String get goodreadsImportEmpty => 'No se encontró la columna «Title» en el CSV';

  @override
  String get openLibraryImport => 'Buscar en Open Library / Google Books';

  @override
  String get openLibraryImportDesc => 'Busca en catálogos públicos por título o ISBN e importa con los metadatos completados (autor, editorial, portada).';

  @override
  String get catalogSearchTitle => 'Buscar en catálogos';

  @override
  String get catalogSearchHint => 'Introduce un título o ISBN';

  @override
  String get catalogSearchAction => 'Buscar';

  @override
  String get catalogSearchInitial => 'Busca en los catálogos públicos de Google Books y Open Library. Los libros seleccionados se añaden con autor, editorial, portada y número de páginas.';

  @override
  String get catalogNoResult => 'No se encontraron libros coincidentes: prueba con otra palabra clave.';

  @override
  String catalogSearchFailed({required Object e}) {
    return 'La búsqueda falló: $e';
  }

  @override
  String get imageUploadConsentTitle => '¿Enviar la captura de la estantería al servicio de IA?';

  @override
  String get imageUploadConsentBody => 'Para que la IA pueda leer tu captura completa de la estantería, la imagen se envía al servicio de IA que configuraste en Ajustes (un tercero). No contiene texto de notas, sí títulos de libros y portadas. ¿Permitir el envío?';

  @override
  String get allow => 'Permitir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get s_178329ba => 'No se ha configurado la API key de WeRead';

  @override
  String get s_dd204792 => '[\\s·・\\-—_:：,，。.·（）()\\[\\]【】]';

  @override
  String get s_ad86a5ca => 'No se ha configurado la API key del LLM';

  @override
  String get s_8a853cbe => 'Introdúcela en Ajustes → LLM';

  @override
  String get s_7d704c88 => 'No hay ningún modelo seleccionado';

  @override
  String get s_4508cedd => 'Pulsa «Obtener modelos» para elegir uno de la lista disponible en tu cuenta';

  @override
  String get s_1b5140db => 'Devuelve solo JSON válido: sin texto explicativo ni bloques de código markdown.';

  @override
  String s_c94c96fc({required Object apiError}) {
    return 'El servicio del modelo devolvió un error: $apiError';
  }

  @override
  String s_3b43c7c4({required Object head}) {
    return 'Respuesta original: $head\nComprueba la dirección y el nombre del modelo en Ajustes → LLM con «Obtener modelos». También aparece aquí si la cuenta no tiene saldo o el modelo no está habilitado.';
  }

  @override
  String get s_231cf54a => 'No se pudo interpretar la respuesta del modelo';

  @override
  String s_90747d4c({required Object head}) {
    return 'Respuesta original: $head\nLa pasarela devolvió una estructura no estándar. Prueba con otro modelo o protocolo; enviarnos este texto original también nos ayuda a darle soporte.';
  }

  @override
  String get s_9d9714af => 'El mensaje está vacío y no se puede enviar';

  @override
  String get s_f44ff25c => 'El modelo rechazó esta solicitud';

  @override
  String get s_cad5bf6e => 'El contenido se marcó como inapropiado. Reformúlalo o prueba con otro modelo.';

  @override
  String get s_0f7b54a1 => 'No se ha configurado la API key';

  @override
  String get s_345e9547 => 'Introduce la key antes de obtener los modelos';

  @override
  String get s_3a5d4cca => 'El servicio devolvió una lista de modelos vacía';

  @override
  String s_cea80527({required Object apiError}) {
    return 'No se pudieron obtener los modelos: $apiError';
  }

  @override
  String get s_4674d953 => 'Puedes escribir el nombre del modelo a mano';

  @override
  String s_749fc40e({required Object raw}) {
    return 'Respuesta original: $raw';
  }

  @override
  String get s_8add575d => 'Este servicio no ofrece endpoint de lista de modelos (404)';

  @override
  String get s_53fb436d => 'Escribe el nombre del modelo, por ejemplo deepseek-chat / claude-sonnet-5';

  @override
  String get s_438a5695 => 'No has introducido ningún nombre de modelo';

  @override
  String get s_1da90e20 => 'Pulsa «Obtener modelos» o escribe uno';

  @override
  String get s_2abb6b8a => 'Responde con dos caracteres: OK';

  @override
  String get s_ad736a74 => 'Eres un asistente de catalogación bibliográfica. Devuelve solo JSON, sin explicaciones.';

  @override
  String s_4304f539({required Object author, required Object title, required Object vocab}) {
    return 'Título conocido «$title»$author.\nCompleta lo siguiente:\n- categoryPrimary: debe ser uno de estos: $vocab\n- description: un resumen neutral de 80–150 caracteres sobre el contenido del libro, con hechos y sin valoraciones\n- tags: de 3 a 5 etiquetas de palabras clave\n- authors: un array si se puede determinar el autor; en caso contrario, un array vacío\nFormato de salida: {\"categoryPrimary\":\"\",\"description\":\"\",\"tags\":[],\"authors\":[]}';
  }

  @override
  String get s_cbe8aa6b => 'Eres un analista del perfil de lectura. Devuelve solo JSON, sin explicaciones.';

  @override
  String s_3864d3b4({required Object summary}) {
    return 'Aquí tienes mis datos de lectura (JSON):\n$summary\n\nDame 10 etiquetas de personalidad, de 2 a 6 palabras cada una, como los apodos que un club de lectura le pone a la gente.\nRequisitos:\n1. Cada etiqueta debe estar respaldada por los datos de arriba: no inventes nada\n2. Referencia de estilo: El aprendizaje es mi gozo / En sintonía con la naturaleza / La belleza ante todo / Erudito a través de los tiempos / El sabio solitario\n3. No uses palabras vacías como «lector», «aficionado» o «entusiasta»\n4. Sin explicaciones ni bloques de código markdown\nFormato de salida: {\"tags\":[\"etiqueta1\",\"etiqueta2\"]}';
  }

  @override
  String get s_99acf9a4 => 'Eres un asesor personal de lectura. Analiza los datos de forma objetiva, evita los elogios vagos y señala los problemas estructurales que se están pasando por alto.';

  @override
  String s_46e5ebef({required Object host}) {
    return 'Tiempo de espera agotado: no se pudo conectar con $host en 20 segundos';
  }

  @override
  String get s_3c836870 => 'Revisa la red o la URL base; algunos servicios en el extranjero necesitan un proxy desde China continental';

  @override
  String get s_84264711 => 'Tiempo de espera agotado al enviar';

  @override
  String get s_225ed2e1 => 'La conexión con el servidor es inestable; inténtalo más tarde';

  @override
  String get s_b265cf86 => 'Tiempo de espera agotado: el modelo no respondió en 180 segundos';

  @override
  String get s_cc12eea3 => 'Prueba con un modelo más rápido o acorta el periodo del informe y reinténtalo';

  @override
  String get s_d711b259 => 'Falló la validación del certificado HTTPS';

  @override
  String get s_4722b0f8 => 'Si usas un servicio propio o de intranet, cambia a un certificado de confianza';

  @override
  String get s_07a2b144 => 'Solicitud cancelada';

  @override
  String s_8ae0b0e4({required Object host}) {
    return 'Red inaccesible: no se puede conectar con $host';
  }

  @override
  String get s_0a9425b8 => '① Revisa la red del móvil; ② comprueba que la URL base esté completa (incluido /v1); ③ verifica si el servicio necesita un proxy; ④ un servicio local (Ollama) no se puede alcanzar desde el móvil a través del localhost del ordenador';

  @override
  String get s_554d5235 => 'La conexión se interrumpió';

  @override
  String get s_020fe21a => 'Suele deberse a un permiso de red bloqueado, a que un proxy o un cortafuegos corta la conexión, o a que no se admite HTTP sin cifrar. Inténtalo más tarde o cambia de red.';

  @override
  String get s_dfde23b1 => 'La solicitud de red falló';

  @override
  String get s_2ae4f5fe => 'Revisa la URL base, la configuración del proxy y la red';

  @override
  String s_d6ac5952({required Object detail}) {
    return 'Solicitud rechazada (400)$detail';
  }

  @override
  String get s_cb980461 => 'Lo más probable es que el nombre del modelo sea incorrecto o que ese modelo no admita los parámetros actuales';

  @override
  String s_d9775d22({required Object detail}) {
    return 'Error de autenticación (401)$detail';
  }

  @override
  String get s_c4198142 => 'La API key no es válida o ha caducado: copia una nueva';

  @override
  String get s_e06ab1cc => 'Saldo insuficiente en la cuenta (402)';

  @override
  String s_05b3ec8b({required Object detail}) {
    return 'Sin permiso (403)$detail';
  }

  @override
  String get s_f00f6ff2 => 'La key no tiene permiso para llamar a este modelo, o la cuenta no está verificada o habilitada';

  @override
  String s_016f7576({required Object detail}) {
    return 'Endpoint o modelo no encontrado (404)$detail';
  }

  @override
  String get s_a8aa2c59 => 'Comprueba que la URL base esté completa hasta /v1; usa «Obtener modelos» para saber el nombre del modelo';

  @override
  String s_9688a257({required Object detail}) {
    return 'Parámetros no válidos (422)$detail';
  }

  @override
  String get s_1b3daaa3 => 'Límite de peticiones alcanzado (429)';

  @override
  String get s_2a564df1 => 'Inténtalo en un momento o mejora tu plan';

  @override
  String s_6627221e({required int? code}) {
    return 'Error del servidor ($code)';
  }

  @override
  String get s_2fe391dd => 'Un problema en el lado remoto; inténtalo más tarde';

  @override
  String s_679e6c2e({required Object code, required Object detail}) {
    return 'La solicitud falló$code$detail';
  }

  @override
  String get s_0cf0a499 => '(cuerpo de respuesta vacío)';

  @override
  String get s_9ed7e745 => 'La solicitud de red falló. Revisa la red del móvil y la URL base en Ajustes → LLM.';

  @override
  String get s_2ad3b6ba => 'Compatible con OpenAI';

  @override
  String get s_e2213e87 => 'Introduce la URL base hasta /v1, por ejemplo https://api.deepseek.com/v1';

  @override
  String get s_17a4ba0f => 'La URL base suele ser https://api.anthropic.com (sin /v1)';

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
  String get s_c800478c => 'Ollama (local)';

  @override
  String get s_0babfa89 => 'Cualquier cadena no vacía';

  @override
  String get s_e74f752c => 'Los días de lectura son los días que has registrado como lectura manualmente';

  @override
  String s_9ea3cbae({required Object year}) {
    return 'El tiempo y los días de lectura proceden de las estadísticas anuales de WeRead para $year (base de año completo)';
  }

  @override
  String get s_f676228c => 'WeRead solo ofrece cifras anuales, así que no se pueden dar con precisión los días de lectura de este intervalo; el tiempo se agrega a nivel de mes';

  @override
  String get s_06225788 => 'Sin valorar';

  @override
  String s_89cfaca8({required Object i}) {
    return '$i estrellas';
  }

  @override
  String get s_e7a2db51 => 'Todo el historial';

  @override
  String s_a87cfcc9({required Object y}) {
    return '$y';
  }

  @override
  String s_62654321({required Object n}) {
    return 'Últimos $n meses';
  }

  @override
  String get s_41f3af95 => 'El tiempo y los días de lectura se agregan a nivel de mes/año';

  @override
  String get s_e8a43314 => 'Empieza el siguiente libro y esta lista madden su primer número.';

  @override
  String get s_af03278c => 'La estantería sigue vacía: toda historia de lectura empieza aquí.';

  @override
  String s_f53eead8({required Object streak}) {
    return '$streak días seguidos de lectura: el ritmo ya se ha instalado.';
  }

  @override
  String s_ff1565a3({required Object streak}) {
    return 'Una racha de $streak días: no la rompas hoy.';
  }

  @override
  String s_1736f17e({required Object streak}) {
    return '$streak días seguidos: un hábito que vale más que cualquier lista de lectura.';
  }

  @override
  String s_9a3fb5e5({required Object finished}) {
    return '$finished libros terminados: cambia la velocidad por ritmo y llegarás más lejos.';
  }

  @override
  String s_9d430ad3({required Object finished}) {
    return '$finished libros terminados. Mira de vez en atrás cuáles te dejaron huella de verdad.';
  }

  @override
  String s_597f7c05({required Object finished}) {
    return '$finished libros terminados en este tramo: todos cuentan.';
  }

  @override
  String s_1c87153f({required Object finished}) {
    return '$finished libros terminados. Para el siguiente, elige uno que ya hayas empezado.';
  }

  @override
  String s_41db17b9({required Object minutes}) {
    return '$minutes minutos de lectura en este tramo: si conviertes media hora en un hábito diario, son 180 horas al año.';
  }

  @override
  String s_6a57c553({required Object minutes}) {
    return 'Ya llevas $minutes minutos registrados. ¿Añades un poco más hoy?';
  }

  @override
  String get s_152a88d7 => 'Tu estantería está lista: empieza los diez minutos de hoy con un relato corto.';

  @override
  String get s_795806c0 => 'Elige un libro que ya hayas empezado: diez minutos cuentan como victoria.';

  @override
  String get s_aa51bf46 => 'No hace falta leer mucho de una vez: abrir cualquier libro hoy ya cuenta.';

  @override
  String get s_363c6a0c => 'Sin categoría';

  @override
  String get s_420a7ac1 => 'El aprendizaje es mi gozo';

  @override
  String get s_bcd278a6 => 'Crecimiento personal';

  @override
  String s_3702d226({required Object cat, required Object pct}) {
    return '$cat libros de crecimiento personal · $pct';
  }

  @override
  String get s_6672b3fa => 'Romántico y poético';

  @override
  String get s_d422d33c => 'Literatura';

  @override
  String s_40ba4ecb({required Object cat, required Object pct}) {
    return '$cat libros de literatura · $pct';
  }

  @override
  String get s_ea2eaec4 => 'El sabio solitario';

  @override
  String get s_5da32671 => 'Filosofía';

  @override
  String s_0f80a135({required Object cat, required Object pct}) {
    return '$cat libros de filosofía · $pct';
  }

  @override
  String get s_111ec0f6 => 'Lecciones de la historia';

  @override
  String get s_07f288e9 => 'Historia';

  @override
  String s_abeb8e3d({required Object cat, required Object pct}) {
    return '$cat libros de historia · $pct';
  }

  @override
  String get s_5e336507 => 'Mirar hacia dentro';

  @override
  String get s_4307c7a8 => 'Psicología';

  @override
  String s_cfce6d52({required Object cat, required Object pct}) {
    return '$cat libros de psicología · $pct';
  }

  @override
  String get s_d5e26f37 => 'Élite tecnológica';

  @override
  String get s_8612fa7f => 'Informática';

  @override
  String s_d6bdf44e({required Object cat, required Object pct}) {
    return '$cat libros de informática · $pct';
  }

  @override
  String get s_00dcb308 => 'La belleza ante todo';

  @override
  String get s_b31e932c => 'Arte';

  @override
  String s_aee18737({required Object cat, required Object pct}) {
    return '$cat libros de arte · $pct';
  }

  @override
  String get s_2ddd554c => 'Racional y práctico';

  @override
  String get s_56734d39 => 'Economía';

  @override
  String get s_5974bf24 => 'Negocios';

  @override
  String s_066faf9c({required Object cat, required Object toStringAsFixed}) {
    return '$cat libros de economía y negocios · $toStringAsFixed%';
  }

  @override
  String get s_d574ffeb => 'Sabedor de la vida';

  @override
  String get s_086ac5bf => 'Ciencias sociales';

  @override
  String s_5a276724({required Object cat, required Object pct}) {
    return '$cat libros de ciencias sociales · $pct';
  }

  @override
  String get s_d81bab36 => 'Curiosidad insaciable';

  @override
  String get s_41fa5c70 => 'Divulgación científica';

  @override
  String get s_fcc3102d => 'Tecnología';

  @override
  String s_76c118d0({required Object n}) {
    return '$n libros de divulgación y tecnología';
  }

  @override
  String get s_2b65326c => 'Aprende de los demás';

  @override
  String get s_f85fa7d4 => 'Biografía';

  @override
  String s_b2e9db16({required Object cat, required Object pct}) {
    return '$cat biografías · $pct';
  }

  @override
  String get s_9e49409c => 'Vivir con salud';

  @override
  String get s_c21b69a8 => 'Medicina';

  @override
  String s_1dd31356({required Object cat}) {
    return '$cat libros de medicina y salud';
  }

  @override
  String get s_77e32253 => 'Práctico y pragmático';

  @override
  String get s_0323f1bb => 'Derecho';

  @override
  String s_82364cc8({required Object cat}) {
    return '$cat libros de derecho';
  }

  @override
  String get s_ea038731 => 'Que se divierte solo';

  @override
  String get s_dbb1c112 => 'Cómic';

  @override
  String get s_6398a679 => 'Libros infantiles';

  @override
  String s_a1b1d26a({required Object cat}) {
    return '$cat cómics y libros infantiles';
  }

  @override
  String get s_94f8d7c2 => 'En sintonía con la naturaleza';

  @override
  String get s_30412ad5 => 'Religión';

  @override
  String s_d00fbfe6({required Object cat}) {
    return '$cat libros de religión';
  }

  @override
  String get s_52c36d65 => 'Sabe vivir';

  @override
  String get s_06e23c48 => 'Otros';

  @override
  String s_e3a3f18e({required Object cat, required Object pct}) {
    return '$cat libros de estilo de vida · $pct';
  }

  @override
  String get s_dc2e94c1 => 'Maestro por vocación';

  @override
  String get s_235af603 => 'Educación';

  @override
  String s_be73b4a0({required Object cat, required Object pct}) {
    return '$cat libros de educación · $pct';
  }

  @override
  String get s_7ea6e8a9 => 'Erudito a través de los tiempos';

  @override
  String s_938fd6ec({required Object categoryKinds}) {
    return 'Tu biblioteca abarca $categoryKinds categorías: un poco de todo';
  }

  @override
  String get s_41a09d04 => 'Concentrado a fondo';

  @override
  String s_c61130ac({required Object categoryKinds, required Object total}) {
    return '$total libros se reparten entre solo $categoryKinds categorías';
  }

  @override
  String get s_431dc47d => 'Termina lo que empieza';

  @override
  String s_a7b097f6({required Object finished, required Object toStringAsFixed, required Object total}) {
    return 'Tasa de terminados $toStringAsFixed% ($finished/$total)';
  }

  @override
  String get s_6b51050c => 'Acumulador de libros';

  @override
  String s_55413cd8({required Object finished, required Object wish}) {
    return '$wish en lista de deseos, pero solo $finished terminados';
  }

  @override
  String get s_e60e931c => 'Corta rápido';

  @override
  String s_b3549d21({required Object abandoned, required Object toStringAsFixed}) {
    return '$abandoned abandonados · $toStringAsFixed%: sueltas lo que no te atrapa';
  }

  @override
  String get s_4be15f8c => 'Empezador de proyectos';

  @override
  String s_b0a853cf({required Object stalled}) {
    return '$stalled libros en curso pero por debajo del 15%';
  }

  @override
  String get s_10b9bddd => 'Trato amable';

  @override
  String s_6a469e36({required Object ratedCount, required Object toStringAsFixed}) {
    return 'Tus $ratedCount libros valorados alcanzan una media de $toStringAsFixed';
  }

  @override
  String get s_e67694db => 'Crítico sin pelos en la lengua';

  @override
  String s_30c4cecf({required Object ratedCount, required Object toStringAsFixed}) {
    return 'Tus $ratedCount libros valorados solo llegan a $toStringAsFixed de media';
  }

  @override
  String get s_fe4567e4 => 'Opiniones firmes';

  @override
  String s_b1d69175({required Object toStringAsFixed}) {
    return 'Desviación típica de las valoraciones $toStringAsFixed: lo bueno y lo malo están muy separados';
  }

  @override
  String get s_fbad19d5 => 'Relee y renueva';

  @override
  String s_8d62979c({required Object reread}) {
    return '$reread libros leídos dos veces o más';
  }

  @override
  String get s_54302bb2 => 'Lector inmersivo';

  @override
  String s_bc9dbced({required Object round}) {
    return '$round minutos de media por día activo';
  }

  @override
  String get s_e9eddf51 => 'Nativo digital';

  @override
  String s_df5bbdba({required Object toStringAsFixed, required Object weread}) {
    return '$weread de WeRead · $toStringAsFixed%';
  }

  @override
  String get s_ce6517f9 => 'Papel y digital';

  @override
  String s_75c2fd5a({required Object libraryCount, required Object paper}) {
    return 'más $libraryCount prestados y $paper en papel';
  }

  @override
  String get s_8cac22b7 => 'Lee con los oídos';

  @override
  String s_72b826e9({required Object audio}) {
    return '$audio audiolibros';
  }

  @override
  String get s_7caeab27 => 'Lector visual';

  @override
  String s_a5a44a39({required Object comic}) {
    return '$comic cómics';
  }

  @override
  String s_0e59d960({required Object m, required Object y}) {
    return '$m/$y';
  }

  @override
  String s_1a2e873e({required Object month}) {
    return 'Mes $month';
  }

  @override
  String s_5583162a({required Object e}) {
    return 'Falló el preprocesado de la imagen; se usa la original: $e';
  }

  @override
  String s_628c2132({required Object e}) {
    return 'No se pudo convertir a JPEG: $e';
  }

  @override
  String get s_ebf4bdfb => 'Analizando la estructura de la maquetación…';

  @override
  String get s_ba1038b1 => 'Limpiando los resultados del reconocimiento con el LLM…';

  @override
  String get s_6292a274 => 'Verificando los títulos…';

  @override
  String get s_427e1f0d => '[\\s《》「」『』…⋯.\\-—_:：]';

  @override
  String get s_af041a1b => 'Título completado';

  @override
  String s_988dd5cb({required Object reason}) {
    return '$reason, título completado';
  }

  @override
  String get s_a746d189 => '[、,，;/]';

  @override
  String s_a4ec75fd({required Object e, required Object title}) {
    return '«$title»: $e';
  }

  @override
  String get s_d2bbf7ce => 'Reconocimiento multimodal';

  @override
  String get s_381ca835 => 'Esta es una captura de una estantería o de una lista de lectura';

  @override
  String get s_fce28e56 => 'Esta es una captura de la portada o de la página de detalles de un solo libro';

  @override
  String s_ba5425c5({required Object n, required Object scene}) {
    return '$scene.\n\nDevuelve solo un array JSON, con cada elemento así:\n{\"title\":\"título\",\"author\":\"autor\",\"progress\":un número del 0 al 100 o null,\"status\":\"uno de unread/reading/finished o null\",\"confidence\":un número del 0 al 1}\n\nRequisitos:\n1. Devuelve solo los libros que están **realmente visibles** en la imagen; no añadas libros que supongas que deberían estar ahí;\n2. Ignora el texto de la interfaz (filtros, búsqueda, orden, «Todos», «Estantería», «N libros», etc.);\n3. Copia los títulos tal y como aparecen, incluidos los cortados por puntos suspensivos: no los completes por tu cuenta;\n4. Deja el autor como cadena vacía si no se puede leer; no lo adivines;\n5. Rellena el autor solo cuando aparece realmente escrito en la imagen.\n$n';
  }

  @override
  String get s_951042c3 => 'Extraes información de capturas de estanterías. Devuelve solo un array JSON, sin texto explicativo.';

  @override
  String get s_29dbdb32 => 'Limpieza con LLM';

  @override
  String get s_9cd6567e => 'Una foto de la portada o del lomo de un libro';

  @override
  String get s_a6db1cf4 => 'Una captura de la estantería de una app de libros electrónicos';

  @override
  String s_43fca769({required Object ocrText, required Object scene}) {
    return 'Estas son las líneas de texto que el OCR leyó de $scene, en orden de arriba abajo.\n\nExtrae los **títulos reales** de libros, ignorando todo el texto de la interfaz (barra de búsqueda, filtros, categorías, barra de estado, números de página, encabezados de capítulo, botones, estadísticas).\n\nReglas:\n1. Devuelve solo los libros que aparecen realmente en la imagen. No añadas libros que supongas que deberían estar ahí.\n2. Si la interfaz corta un título con puntos suspensivos (por ejemplo, «Pro-fund…»), complétalo con el título entero.\n3. progress es un porcentaje entero del 0 al 100; déjalo como cadena vacía si no se puede leer. Ojo: «0.8%» es 0.8, no 80.\n4. status debe ser uno de «unread / reading / finished / dropped»; déjalo como cadena vacía si no se puede leer.\n5. Rellena el autor solo si aparece con claridad en la imagen; si no, déjalo en blanco. No lo adivines.\n6. Omite las líneas de las que no estés seguro. Mejor dejar fuera un libro que añadir uno falso.\n\nDevuelve solo un array JSON, con elementos así:\n[{\"title\":\"\",\"author\":\"\",\"progress\":\"\",\"status\":\"\",\"confidence\":0.0}]\n\nLíneas de texto del OCR:\n\"\"\"\n$ocrText\n\"\"\"';
  }

  @override
  String get s_cbb756f7 => '[\\s《》「」『』]';

  @override
  String get s_95222176 => 'Sin leer';

  @override
  String get s_5a833930 => 'Quiero leer';

  @override
  String get s_b9bf9b53 => 'Leyendo';

  @override
  String get s_be5492a5 => 'Leyendo actualmente';

  @override
  String get s_44c14529 => 'Lectura terminada';

  @override
  String get s_0872b5b7 => 'Terminado';

  @override
  String get s_300a32bd => 'Terminado';

  @override
  String get s_0f4d9c68 => 'Abandonado (fusionado con «Apartado»)';

  @override
  String get s_7675d229 => '\\s*(著|编著|译|著译)\$';

  @override
  String get s_285bb37e => '[，。；、？！：）」』]\$';

  @override
  String get s_8f936d11 => '(著|编著|译|著译)\$';

  @override
  String get s_d0c345ec => '[（《·“]\$';

  @override
  String get s_2d3c83a7 => '[）》」』”]\$';

  @override
  String get s_0686f279 => 'Texto más grande de la portada';

  @override
  String get s_5514105a => 'Texto secundario de la portada';

  @override
  String get s_174faffb => 'Contiene chino';

  @override
  String get s_b13a1237 => 'Tiene progreso o estado';

  @override
  String get s_24745e9d => 'Tiene autor';

  @override
  String get s_0cedc3f4 => 'Longitud razonable';

  @override
  String get s_5bdfa6ae => 'Demasiado corto';

  @override
  String get s_58171266 => 'Demasiado largo';

  @override
  String get s_1e8c236b => 'Columnas alineadas a la izquierda';

  @override
  String get s_89ac54fb => 'Rotulación de portada';

  @override
  String get s_132a750b => 'Inglés demasiado corto';

  @override
  String get s_6af25a96 => '[，。；、？！]\$';

  @override
  String get s_a335b25f => 'Puntuación de final de frase';

  @override
  String get s_885dd894 => '％';

  @override
  String get s_620b459e => '《';

  @override
  String get s_150c7508 => '》';

  @override
  String get s_67df3afd => 'Tiene comillas de título';

  @override
  String get s_5a09ed37 => 'Chino';

  @override
  String get s_6b631636 => 'Parecen una palabra de interfaz en inglés';

  @override
  String get s_1dd3f274 => 'Línea adyacente';

  @override
  String get s_f547232b => ', línea unida';

  @override
  String get s_fc39b00e => 'Prestado';

  @override
  String get s_eba88d83 => 'Apartado';

  @override
  String get s_b6fe7962 => 'Libro electrónico';

  @override
  String get s_c7673d27 => 'Papel';

  @override
  String get s_02a1a8ed => 'Audiolibro';

  @override
  String get s_fe152225 => 'WeRead';

  @override
  String get s_2032cbd7 => 'iReader Select';

  @override
  String get s_12ed007e => 'JD Read';

  @override
  String get s_570bb7c8 => 'BOOX';

  @override
  String get s_36bfef2d => 'Biblioteca';

  @override
  String get s_4139f3b5 => 'Manual';

  @override
  String get s_88cdd7e4 => 'Subrayado';

  @override
  String get s_6abc44a8 => 'Idea';

  @override
  String get s_67585b8a => 'Reseña';

  @override
  String get s_96009a7e => 'Informe de lectura';

  @override
  String s_4343b7b3({required Object join}) {
    return 'Generando en segundo plano: $join';
  }

  @override
  String s_a6c57a43({required Object ok}) {
    return 'Se han generado automáticamente $ok informes';
  }

  @override
  String s_f71dea06({required Object failed, required Object ok}) {
    return 'Generados $ok, fallidos $failed (puedes reintentarlos a mano)';
  }

  @override
  String s_e93308dd({required Object latencyMs, required Object model}) {
    return 'Conectado · $model · $latencyMs ms';
  }

  @override
  String get s_d2a3748e => 'El modelo devolvió contenido vacío';

  @override
  String get s_3abdc334 => 'Puede que el modelo no admita los parámetros actuales o que se haya activado el filtro de contenido. Prueba con otro modelo.';

  @override
  String get s_cc72f973 => 'No hay ninguna API key de LLM configurada. Introdúcela en Ajustes → LLM y prueba primero la conexión';

  @override
  String get s_9e51ce93 => 'No hay modelo seleccionado. Ve a Ajustes → LLM y usa «Obtener modelos» para elegir uno';

  @override
  String get s_c6e18e89 => 'No hay libros que coincidan en este periodo; prueba con otro';

  @override
  String get s_8bb45b34 => 'Periodo del informe';

  @override
  String get s_8bd59fb2 => 'Elige un informe anual o mensual';

  @override
  String get s_53bea04d => 'Archivado por año o mes natural; una vez generado puedes volver a abrirlo cuando quieras. El informe del mes actual solo se genera el mes siguiente.';

  @override
  String get s_1f048ed9 => 'Probando…';

  @override
  String get s_38fb1115 => 'Probar conexión';

  @override
  String get s_a14e36dc => 'Generando… (los textos largos tardan alrededor de un minuto)';

  @override
  String get s_b36c173d => 'Generar informe';

  @override
  String get s_c94ade95 => 'Envía la lista de libros del periodo (título / autor / categoría / valoración) y estadísticas agregadas para que el informe pueda nombrar libros concretos; el texto de las notas y los subrayados no se suben.';

  @override
  String get s_5e05e92a => 'Incluido';

  @override
  String s_be9a1551({required Object total}) {
    return '$total libros';
  }

  @override
  String s_ce115766({required Object finished}) {
    return '$finished libros';
  }

  @override
  String s_8b46a11f({required Object reading}) {
    return '$reading libros';
  }

  @override
  String s_81e94993({required Object wish}) {
    return '$wish libros';
  }

  @override
  String get s_09b589b4 => 'Valoración media';

  @override
  String s_0825e123({required Object label}) {
    return 'Contenido del informe · $label';
  }

  @override
  String get s_049eca89 => 'Copiar todo';

  @override
  String get s_50bf9961 => 'Informe copiado al portapapeles';

  @override
  String get s_772cbfcf => 'Generar automáticamente';

  @override
  String get s_01955ddf => 'Al activarlo, al abrir esta página se generan automáticamente los informes anuales que falten y el informe mensual del mes pasado.';

  @override
  String get s_b2a52a3d => 'Generar los que falten';

  @override
  String get s_b233138e => 'Anual';

  @override
  String get s_877b864d => 'Mensual';

  @override
  String get s_a3dfa2a6 => 'Informes anteriores';

  @override
  String get s_66772db6 => 'Exportar los datos de lectura';

  @override
  String get s_6b198f0b => 'Exportación cancelada';

  @override
  String s_a101fbdd({required Object counts, required Object saved}) {
    return 'Exportado a: $saved\n\n$counts';
  }

  @override
  String s_6ec2d38e({required Object e}) {
    return 'Falló la exportación: $e';
  }

  @override
  String get s_c699263b => 'Elige un archivo de copia de seguridad';

  @override
  String s_e34bdbcb({required Object e}) {
    return 'No se pudo leer este archivo: $e';
  }

  @override
  String get s_1dedeaa2 => 'Esto no es una copia de seguridad exportada por esta app (falta la marca de formato, o es más reciente que la app actual)';

  @override
  String get s_103c5811 => 'Este archivo no contiene datos restaurables';

  @override
  String get s_674a7957 => '¿Restaurar ahora?';

  @override
  String s_94094e0d({required Object length}) {
    return 'Esto sobrescribirá los datos de este dispositivo con la copia de seguridad:\n\n$length\n\nLos registros con el mismo nombre se sobrescriben por completo: restaurar significa «volver al momento de la copia de seguridad», sin fusionar campo a campo. Los libros añadidos después de la copia no se borrarán.';
  }

  @override
  String get s_a0451c97 => 'Cancelar';

  @override
  String get s_ec7085ab => 'Restaurar';

  @override
  String s_2296b134({required Object counts, required Object first}) {
    return 'Restauración completada$first\n\n$counts';
  }

  @override
  String s_e669bac1({required Object e}) {
    return 'Falló la restauración: $e';
  }

  @override
  String s_7c0be1cd({required int? books}) {
    return '$books libros';
  }

  @override
  String s_dd2321ce({required int? notes}) {
    return '$notes notas';
  }

  @override
  String s_d48aa751({required int? reading_logs}) {
    return '$reading_logs registros de lectura';
  }

  @override
  String s_d044717e({required int? llm_reports}) {
    return '$llm_reports informes de IA';
  }

  @override
  String s_f4d248a7({required int? settings}) {
    return '$settings ajustes';
  }

  @override
  String get s_8719bf89 => 'Exportación y restauración de datos';

  @override
  String get s_8fe27f12 => 'Qué se exporta';

  @override
  String get s_5d9af0a7 => 'Una instantánea JSON completa: libros, notas, registros de lectura, informes de IA y ajustes. Se guarda en un solo archivo; úsalo para restaurar en otro dispositivo.';

  @override
  String get s_582f4cb6 => 'Exportar como archivo JSON';

  @override
  String get s_091ad5f4 => 'Restaurar desde una copia';

  @override
  String get s_3a36f742 => 'Elige un archivo .json exportado antes. Los registros con el mismo nombre se sobrescriben enteros, no se fusionan campo a campo: esto significa «volver al momento de la copia», no «hacer una unión».';

  @override
  String get s_6f9ab88c => 'Elige una copia y restáurala';

  @override
  String get s_f24f63da => '¿Eliminar esta nota?';

  @override
  String get s_ecbd7449 => 'Eliminar';

  @override
  String get s_f98a79dc => 'Añadir nota';

  @override
  String get s_05712ea1 => 'Editar nota';

  @override
  String get s_e3fdcb7e => 'Una cita, una idea o una reseña…';

  @override
  String get s_c8d8fada => 'Capítulo / página';

  @override
  String get s_f80f4749 => 'Opcional';

  @override
  String get s_abfe9512 => 'Guardar';

  @override
  String get s_a647c2e0 => 'Este libro no existe o se ha eliminado';

  @override
  String s_154ada37({required Object join}) {
    return 'Autor: $join';
  }

  @override
  String s_904feb6c({required Object join}) {
    return 'Traducción: $join';
  }

  @override
  String s_1e4c61f8({required Object publisher}) {
    return 'Editorial: $publisher';
  }

  @override
  String s_bf93bf6d({required Object first}) {
    return 'Publicado: $first';
  }

  @override
  String s_def61e8c({required Object categoryPrimary}) {
    return 'Categoría: $categoryPrimary';
  }

  @override
  String get s_d9bdf56b => 'Estado de lectura';

  @override
  String s_94b27e86({required Object toStringAsFixed}) {
    return 'Progreso $toStringAsFixed%';
  }

  @override
  String get s_8331377a => 'Valoración';

  @override
  String get s_205eb716 => 'Resumen';

  @override
  String get s_b5e2aa8a => 'Anota de qué trata este libro';

  @override
  String get s_3ec1ca86 => 'Reseña';

  @override
  String get s_aa5a5d3e => 'Tus opiniones y reflexiones';

  @override
  String s_fb47d52b({required Object length}) {
    return 'Notas · $length';
  }

  @override
  String get s_18dd30c5 => 'Todavía no hay notas. Apunta algo cuando algo te llame la atención: será material para tu revisión anual.';

  @override
  String get s_4b7d48f2 => 'Descripción';

  @override
  String s_5e52b06a({required String? dueAt}) {
    return 'Devolución: $dueAt';
  }

  @override
  String get s_ad207008 => 'Editar';

  @override
  String get s_f5d99c16 => '、';

  @override
  String get s_65983593 => 'El título no puede estar vacío';

  @override
  String get s_1f0939bc => '[,，、;；]';

  @override
  String get s_6c7a6cc5 => 'Editar libro';

  @override
  String get s_31e2aa97 => 'Añadir un libro a mano';

  @override
  String get s_eda73905 => 'Guardar cambios';

  @override
  String get s_71b10e99 => 'Añadir a la estantería';

  @override
  String get s_2dae8ba5 => 'Elige una portada local';

  @override
  String get s_5be7901d => 'Definir portada';

  @override
  String get s_a59912dd => 'Quitar portada';

  @override
  String get s_e2b6c0de => 'Título *';

  @override
  String get s_22760472 => 'Autor';

  @override
  String get s_5f70e9dd => 'Separa varios autores con comas';

  @override
  String get s_759fb403 => 'Estado';

  @override
  String get s_da1c08d9 => 'Formato';

  @override
  String get s_5ce4e16d => 'Limpiar';

  @override
  String get s_b0d7b0de => 'Descripción / resumen';

  @override
  String get s_d0dd45ac => 'Las categorías se normalizan a un vocabulario controlado: escribir «Negocios y motivación» también se fusiona con «Negocios», así las estadísticas no se parten en dos grupos.';

  @override
  String get s_b32f0afe => 'Categoría';

  @override
  String get s_87635298 => 'Opcional';

  @override
  String get s_5aa23087 => 'Ninguno';

  @override
  String s_573b6694({required Object e}) {
    return 'Algo ha salido mal: $e';
  }

  @override
  String get s_28690759 => 'Mejorando la imagen…';

  @override
  String get s_d5155b2d => 'No se reconoció ningún título; prueba con otra imagen';

  @override
  String get s_e20dac78 => 'Leyendo la imagen con un modelo multimodal…';

  @override
  String get s_5fea0487 => 'El modelo multimodal no pudo leer ningún título de esta imagen. Comprueba que el modelo seleccionado admita imágenes (los modelos solo de texto lo rechazan de inmediato) o vuelve a poner Ajustes → Reconocimiento de capturas → Modo de reconocimiento en «Automático» para recurrir al OCR del dispositivo.';

  @override
  String get s_cdda9381 => 'El modelo multimodal no devolvió nada; se recurre al OCR del dispositivo…';

  @override
  String get s_b85e4cbc => 'No se permite subir la imagen; se recurre al OCR del dispositivo…';

  @override
  String get s_a9698571 => 'Reconociendo texto…';

  @override
  String get s_7ef6b42d => 'No se encontró texto en esta imagen. Prueba desde otro ángulo, con el texto más nítido, o haz directamente una captura de pantalla (las capturas se leen mejor que las fotos).';

  @override
  String get s_319b9488 => 'No se encontró texto que parezca un título. Si es una página interior, el título normalmente no aparece: prueba con «Importar captura de la estantería» o fotografía la portada.';

  @override
  String get s_37588c9c => 'No se pudo leer ningún título de esta imagen. Prueba a recortar la interfaz sobrante y reinténtalo.';

  @override
  String get s_04a1b347 => 'Título';

  @override
  String get s_a9fe3793 => 'No se encontró la columna «Title» en el CSV';

  @override
  String get s_3db59388 => 'Progreso';

  @override
  String get s_9e160a69 => 'Editorial';

  @override
  String s_d4b7c3c7({required Object length}) {
    return 'Se han analizado $length libros. ¿Importarlos?';
  }

  @override
  String get s_649320a3 => 'Leyendo tu estantería de WeRead…';

  @override
  String get s_e53774ba => 'La estantería está vacía o la API no ha devuelto datos';

  @override
  String s_8151aa42({required Object length}) {
    return 'Tu estantería de WeRead tiene $length libros. ¿Importarlos?';
  }

  @override
  String get s_9b37038a => 'Completando los metadatos y guardando…';

  @override
  String s_c4f36bd6({required Object added, required Object duplicated, required Object failed}) {
    return 'Importación completada: $added añadidos, $duplicated actualizados$failed';
  }

  @override
  String get s_28ab46d9 => 'Todavía no hay libros de WeRead en este dispositivo: sincroniza primero la estantería';

  @override
  String get s_6d61442b => 'Sincronizando el progreso de lectura…';

  @override
  String s_a26c53db({required Object length, required Object updated}) {
    return 'Progreso de lectura actualizado en $updated de $length libros';
  }

  @override
  String get s_3a0cf870 => 'La conexión se ha interrumpido. Revisa la red y reinténtalo.';

  @override
  String get s_1cbe2507 => 'Confirmar';

  @override
  String get s_1df9fbd5 => 'Importar';

  @override
  String get s_874053cb => 'API key de WeRead';

  @override
  String get s_58652b51 => 'Escanea con WeChat el código QR para abrir weread.qq.com/r/weread-skills,\ny luego copia la key que aparece en la página (empieza por «wrk-»). La key se guarda solo en este dispositivo.';

  @override
  String get s_cb2558f7 => 'Importar la estantería desde una captura';

  @override
  String get s_24b715f3 => 'Elige una captura de tu estantería y lee el título y el progreso de cada celda. El resultado puede ser impreciso: compruébalo antes de guardar.';

  @override
  String get s_4f062f79 => 'Importar la estantería con una foto';

  @override
  String get s_6e464c0e => 'Haz una foto de una portada, un lomo o una página: se detecta el título y se completa el resto de los metadatos. El resultado puede ser impreciso: compruébalo antes de guardar.';

  @override
  String get s_a5452d46 => 'Sincronizar la estantería desde los canales';

  @override
  String get s_d40e2a14 => 'Lee tu estantería y tu estado de lectura mediante la API oficial de los canales que hayas configurado: sin capturas. Hoy se admite WeRead; más canales están en camino.';

  @override
  String get s_af94a367 => 'Sincronizar el progreso de lectura';

  @override
  String get s_59d2efab => 'Obtiene el porcentaje leído y el tiempo acumulado de cada libro. Algunos canales no devuelven el progreso en la estantería, así que hay que hacer una petición por libro.';

  @override
  String get s_fa52186c => 'Importar desde CSV / Notion';

  @override
  String get s_2c78f2b8 => 'Migración con un clic desde un CSV exportado de Notion: los nombres de columna se detectan solos y los campos personalizados se conservan.';

  @override
  String get s_238b14fc => 'Procesando…';

  @override
  String s_ed4b0551({required Object length}) {
    return 'No se pudieron importar $length libros';
  }

  @override
  String s_ec50ebde({required Object length}) {
    return '…y $length más';
  }

  @override
  String get s_18307d56 => 'Añadir a mano';

  @override
  String s_cc0eef03({required Object length}) {
    return '$length libros reconocidos';
  }

  @override
  String get s_0f466d7a => 'Seleccionar todo';

  @override
  String get s_42b2fafa => 'Deseleccionar todo';

  @override
  String s_7feb7674({required Object keptLines, required Object repairedTitles, required Object totalLines, required Object usedLlm}) {
    return 'Se leyeron $totalLines líneas de texto y se conservaron $keptLines libros$usedLlm$repairedTitles';
  }

  @override
  String get s_4d52323f => 'Los elementos marcados como «completado» o «inferido» no son literales de la imagen: compruébalos antes de importar. Puedes pulsar cualquier título o autor para editarlo.';

  @override
  String get s_0f40975c => 'Añadir uno a mano (el OCR no lo leyó)';

  @override
  String s_fdc0acd1({required Object length}) {
    return 'Importar los $length seleccionados';
  }

  @override
  String get s_4443bd2c => 'La imagen original estaba recortada';

  @override
  String s_7af46a28({required Object progressPercent}) {
    return 'Progreso $progressPercent%';
  }

  @override
  String s_4737de25({required Object toStringAsFixed}) {
    return 'Confianza $toStringAsFixed%';
  }

  @override
  String s_2df91ffc({required Object rawText}) {
    return 'Imagen original: $rawText';
  }

  @override
  String get s_7bbe0f10 => 'Autor (opcional)';

  @override
  String get s_bd13cf0b => 'Eliminar este';

  @override
  String get s_c048f107 => 'Intervalo de estadísticas';

  @override
  String get s_89c61e4a => 'Total de libros';

  @override
  String get s_9da15a74 => 'Distribución por estado';

  @override
  String get s_130a42ae => 'Distribución por categoría';

  @override
  String get s_98f42577 => 'Distribución por origen';

  @override
  String get s_5e8ebbe6 => 'Distribución por formato';

  @override
  String get s_5182e58a => 'Valoración media';

  @override
  String get s_50bcc778 => 'Libros valorados';

  @override
  String get s_59c5e73a => 'Tiempo de lectura (minutos)';

  @override
  String get s_48529b9f => 'Días con actividad de lectura';

  @override
  String get s_7be1388c => 'No hay ninguna API key de LLM configurada. Introdúcela en Ajustes → LLM para poder generar.';

  @override
  String get s_992d7786 => 'El modelo no devolvió etiquetas utilizables; prueba con otro modelo';

  @override
  String get s_eead3bcd => '¿Sustituir por este conjunto?';

  @override
  String s_b9da6464({required Object length, required Object length_1}) {
    return 'Tus $length etiquetas actuales se sustituirán por estas $length_1. Después aún podrás editarlas o borrarlas una a una.';
  }

  @override
  String get s_89829921 => 'Sustituir';

  @override
  String get s_0f8acec9 => 'Sustituidas por las etiquetas principales';

  @override
  String get s_93aebfd1 => 'Esa etiqueta ya aparece arriba';

  @override
  String get s_bca518fd => 'Añadida a las etiquetas principales';

  @override
  String s_284dfaab({required Object text}) {
    return 'Se ha quitado «$text»';
  }

  @override
  String get s_8eb8d18d => 'Editar etiqueta';

  @override
  String get s_35c48d07 => 'Esta etiqueta la escribiste tú; no tiene ninguna base automática.';

  @override
  String get s_724386f0 => 'Añadir etiqueta';

  @override
  String get s_fdd8c684 => 'Las etiquetas que escribas tú no se validan ni se sobrescriben al recalcular.';

  @override
  String get s_7b328e58 => '¿Restablecer las etiquetas por defecto?';

  @override
  String get s_b9a4d4ef => 'Se borrarán tus cambios manuales y las etiquetas se deducirán de nuevo a partir de tu biblioteca actual.';

  @override
  String get s_0fcef2c8 => 'Restablecidas a las etiquetas deducidas de tu biblioteca';

  @override
  String get s_e97565e5 => 'Mi perfil de lectura';

  @override
  String s_783e43af({required Object e}) {
    return 'No se pudo generar la imagen para compartir: $e';
  }

  @override
  String get s_14f92b04 => 'Generar imagen para compartir';

  @override
  String get s_a17c4e02 => 'Guardada en tus fotos';

  @override
  String s_3f81d5b6({required Object e}) {
    return 'No se pudo guardar: $e';
  }

  @override
  String get s_c6d1e7a3 => 'Imagen lista';

  @override
  String get s_b8e4c9a1 => 'Guardar la imagen en este dispositivo';

  @override
  String get s_51ebc0d1 => 'Recalcular';

  @override
  String get s_6c64acc5 => 'Mis etiquetas de personalidad lectora';

  @override
  String s_03bf36af({required Object length}) {
    return 'Deducidas de $length libros';
  }

  @override
  String get s_a789d74f => 'Se han borrado todas las etiquetas. Pulsa «Añadir» abajo para escribir las tuyas, o restablece las de por defecto y deja que la app las deduzca de nuevo.';

  @override
  String get s_a1d885c1 => 'Añadir';

  @override
  String get s_64bff158 => 'Pulsa una etiqueta para renombrarla o borrarla. En las deducidas por reglas, los números que hay detrás se ven en el diálogo de edición.';

  @override
  String get s_84bf2c49 => 'Generando…';

  @override
  String get s_5a251fee => 'Generar otro conjunto con IA';

  @override
  String get s_18be3bbe => 'Restablecer por defecto';

  @override
  String get s_7ae84af3 => 'Preferencias de lectura';

  @override
  String s_aeed65e7({required Object length}) {
    return '$length categorías';
  }

  @override
  String get s_f2a9e2a4 => 'El área del círculo es proporcional al número de libros (por eso el radio es la raíz cuadrada de la cantidad: usar la cantidad directamente como radio exageraría las diferencias y engañaría).';

  @override
  String s_abd0dab0({required Object stamp}) {
    return 'Generado por IA · $stamp';
  }

  @override
  String get s_7ea8e671 => 'Sustituir las etiquetas principales';

  @override
  String get s_d1a58b2f => 'Pulsa una etiqueta concreta para añadirla a las principales, o sustituye el conjunto entero. Este conjunto lo genera el modelo a partir de estadísticas agregadas, así que su base es menos explícita que el de las reglas.';

  @override
  String get s_a38881a0 => 'Todavía no hay libros en este intervalo';

  @override
  String get s_20fde694 => 'Prueba con otro intervalo o importa primero algunos libros';

  @override
  String get s_9fe34cff => 'Todavía no hay datos de categorías';

  @override
  String s_d9579b73({required Object bookCount, required Object rangeLabel}) {
    return '$rangeLabel · $bookCount libros';
  }

  @override
  String get s_bfc50de8 => 'Etiquetas de personalidad';

  @override
  String get s_ab5cc063 => 'Preferencias de lectura';

  @override
  String get s_9de44e0f => 'Gestor de lectura · Mi estantería';

  @override
  String get s_20a63774 => 'Elige el intervalo de estadísticas';

  @override
  String get s_d507abff => 'Aceptar';

  @override
  String get s_ff31410d => 'Personalizado…';

  @override
  String get s_72cca1f6 => 'Configuración guardada localmente';

  @override
  String s_b6477017({required Object name}) {
    return 'Has rellenado $name; todavía hace falta la API key';
  }

  @override
  String get s_533f5118 => 'Obteniendo la lista de modelos…';

  @override
  String s_648219b9({required Object id}) {
    return 'Modelo seleccionado: $id';
  }

  @override
  String s_baf95794({required Object length}) {
    return '$length modelos disponibles (ninguno seleccionado)';
  }

  @override
  String get s_e37cab47 => 'Probando la conexión…';

  @override
  String s_c17c1a05({required Object latencyMs, required Object model, required Object reply}) {
    return 'Conectado · $model\nHa tardado $latencyMs ms; el modelo ha respondido «$reply»';
  }

  @override
  String get s_5df0d12b => 'Verificando la key de WeRead…';

  @override
  String s_bd245b07({required Object n}) {
    return 'La key es válida; la estantería tiene ahora $n libros';
  }

  @override
  String s_73f89115({required Object host}) {
    return 'No se puede conectar con $host\nRevisa la red, que la URL base esté completa (incluido /v1) y si el servicio necesita un proxy';
  }

  @override
  String get s_9038e16e => 'El endpoint ha agotado el tiempo de espera (180 segundos)';

  @override
  String s_e0710bf5({required Object e, required int? statusCode}) {
    return 'El servicio ha devuelto $statusCode: $e';
  }

  @override
  String s_24d6c7ae({required Object name}) {
    return 'La solicitud falló: $name';
  }

  @override
  String get s_4d3eb2b3 => 'Buscar modelos';

  @override
  String s_17d94005({required Object length}) {
    return '$length en total';
  }

  @override
  String get s_a48ae43a => 'Al pulsar una sugerencia se escribe el nombre del modelo';

  @override
  String get s_b5c7b82d => 'Ajustes';

  @override
  String get s_bc90fa59 => 'Se usa para sincronizar la estantería y el progreso de lectura. Escanea el código QR para abrir weread.qq.com/r/weread-skills y conseguir una.';

  @override
  String get s_e44e9f26 => 'Verificar la key';

  @override
  String get s_75bf6943 => 'LLM';

  @override
  String get s_9e8f6691 => 'Se usa para completar metadatos cuando faltan, limpiar el reconocimiento de capturas y generar informes de lectura.';

  @override
  String get s_cc3c9556 => 'Proveedores predefinidos';

  @override
  String get s_9021b9f9 => 'Al elegir uno se rellenan la dirección y el modelo';

  @override
  String get s_1fd51aaa => 'Nombre del modelo';

  @override
  String get s_209e1f28 => 'Te recomendamos pulsar «Obtener modelos» y elegir de la lista que tu cuenta tiene disponible de verdad';

  @override
  String get s_ab135d7c => 'Obtener modelos';

  @override
  String get s_a46a5664 => 'Probar conexión';

  @override
  String get s_e4f7e107 => 'Mostrar la key';

  @override
  String get s_b13be56e => 'Ocultar la key';

  @override
  String get s_9ac01f6b => 'Probar y obtener modelos guardan antes lo que hayas escrito.';

  @override
  String get s_0001747c => 'Reconocimiento de capturas';

  @override
  String get s_3f5cbdbf => 'Determina cómo de bien se reconocen las importaciones por foto y por captura.';

  @override
  String get s_9130a4ed => 'Preprocesado de mejora de la imagen';

  @override
  String get s_b79fc99c => 'Amplía y afila primero la imagen, así los títulos pequeños se reconocen mejor.';

  @override
  String get s_9695a603 => 'Usar el LLM para limpiar los resultados';

  @override
  String get s_267118b5 => 'Deja que el LLM limpie los títulos reconocidos. Necesita una API key de LLM y consume tokens.';

  @override
  String get s_6d7e1f9f => 'Modo de reconocimiento';

  @override
  String get s_ed144a76 => 'Automático (multimodal primero, con respaldo en el dispositivo)';

  @override
  String get s_c7bab837 => 'Un LLM multimodal lee la imagen directamente';

  @override
  String get s_d8f3da2a => 'OCR en el dispositivo (sin conexión, gratis)';

  @override
  String get s_f22e4cd2 => 'El OCR del dispositivo funciona sin conexión pero puede saltarse títulos; el modelo multimodal entiende la maquetación pero necesita red y puede inventarse un título. «Automático» usa ambos.';

  @override
  String get s_67677b3d => 'Datos';

  @override
  String get s_d596ba9b => 'Exporta toda la base de datos en JSON para llevarla a otro dispositivo. Una instalación nueva empieza con la estantería vacía; añade libros desde la pestaña Importar para empezar.';

  @override
  String get s_39239742 => 'Exportar / restaurar con un toque';

  @override
  String get s_3c21597a => 'Todos los cambios se guardan automáticamente en la base de datos de este dispositivo: no hace falta guardar a mano.';

  @override
  String get s_68885a92 => 'Las keys se guardan solo en la base de datos de este dispositivo; nunca se incluyen en la app ni se suben.';

  @override
  String get s_9b3c95d4 => 'Actualizados recientemente';

  @override
  String get s_97428491 => 'Terminados recientemente';

  @override
  String get s_8f38c041 => 'Mejor puntuados';

  @override
  String get s_50a7317f => 'Más avanzados';

  @override
  String get s_b5538557 => 'Título A–Z';

  @override
  String s_e3cd14ba({required Object title}) {
    return 'Se ha añadido «$title»';
  }

  @override
  String get s_296fc9b4 => 'Estantería';

  @override
  String get s_a444b428 => 'Ordenar';

  @override
  String get s_fa0a5cdd => 'Cambiar a lista';

  @override
  String get s_cb4a4231 => 'Cambiar a cuadrícula de portadas';

  @override
  String get s_78966c42 => 'Buscar por título / autor / editorial';

  @override
  String get s_8ed41c6c => 'Ningún libro coincide con estos filtros';

  @override
  String get s_bd33274a => 'Todavía no hay libros: añade alguno desde la pestaña Importar';

  @override
  String s_0cd6d0f8({required Object length}) {
    return '$length libros';
  }

  @override
  String s_ff7e02df({required Object finished, required Object reading}) {
    return '$reading en lectura · $finished leídos';
  }

  @override
  String get s_68022ee7 => 'Todos';

  @override
  String get s_542b67cc => 'Más filtros';

  @override
  String get s_ec977df0 => 'Origen';

  @override
  String get s_50d471b2 => 'Restablecer';

  @override
  String get s_37361909 => 'Visibilidad de los gráficos';

  @override
  String get s_b1288e4a => 'Mostrar todos';

  @override
  String get s_6b2b7015 => 'Ocultar todos';

  @override
  String get s_e91a9228 => 'Muestra solo los gráficos que te interesen y oculta el resto.';

  @override
  String get s_fe93ef35 => 'Aplicar';

  @override
  String get s_0d65fca2 => '[《》「」]';

  @override
  String s_9380d869({required int? daysUntilDue}) {
    return 'Devolución en $daysUntilDue días';
  }

  @override
  String get s_0e13c16f => 'Estadísticas';

  @override
  String get s_3ad4c4c8 => 'Perfil de lectura';

  @override
  String s_7c6c253b({required Object label}) {
    return 'Este periodo · $label';
  }

  @override
  String get s_88c0b751 => 'Atribuidos según la fecha de finalización o de actividad de cada libro';

  @override
  String get s_50ba5fd5 => 'libros';

  @override
  String get s_cc4556af => 'Libros añadidos';

  @override
  String get s_3509a9f8 => 'días';

  @override
  String get s_a7e9ff0f => 'pts';

  @override
  String get s_58d90b89 => 'Estantería actual';

  @override
  String get s_c3bb899b => 'Cifras de instantánea, no afectadas por el filtro de tiempo de arriba';

  @override
  String get s_563edd9d => 'Total de libros';

  @override
  String get s_0d8d3eb3 => 'Racha de lectura';

  @override
  String get s_4ab30c5b => 'Empezados pero estancados';

  @override
  String s_b563f985({required Object label}) {
    return 'Estructura · $label';
  }

  @override
  String s_a7e09561({required Object length}) {
    return '$length libros incluidos';
  }

  @override
  String get s_c6cc650b => 'Distribución por estado de lectura';

  @override
  String get s_8137585d => '8 categorías principales';

  @override
  String s_f92480e2({required Object length}) {
    return '$length categorías';
  }

  @override
  String get s_50feb68a => 'Lectura por mes';

  @override
  String get s_750a3b1c => 'Todavía no hay actividad de lectura en este intervalo';

  @override
  String get s_4d7dd157 => 'Tiempo de lectura mensual';

  @override
  String get s_5a78dc03 => 'Se muestra tras importar las estadísticas anuales de WeRead';

  @override
  String get s_5b37ad6b => 'Distribución de valoraciones';

  @override
  String s_3c0e984b({required Object toStringAsFixed, required Object unratedCount}) {
    return 'Media $toStringAsFixed · $unratedCount sin valorar';
  }

  @override
  String get s_3c1cb8ee => 'Todavía no hay valoraciones';

  @override
  String get s_01d886c7 => 'Distribución del progreso';

  @override
  String s_ecf53f5a({required Object readingInRange}) {
    return '$readingInRange en curso';
  }

  @override
  String get s_faf98ba4 => 'No hay libros en curso en este intervalo';

  @override
  String s_77030fdc({required Object length}) {
    return '$length plataformas';
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
    return '$scope · $toStringAsFixed h en total';
  }

  @override
  String s_e7b115df({required Object join}) {
    return 'Las estadísticas anuales de WeRead solo cubren $join, así que este gráfico se dibuja por año natural; el gráfico de libros terminados de arriba usa los últimos 12 meses.';
  }

  @override
  String s_9ef861db({required Object name, required Object toInt}) {
    return '$name\n$toInt libros';
  }

  @override
  String s_2cf3ef4e({required Object i, required Object toInt}) {
    return '$i · $toInt libros';
  }

  @override
  String s_e241a8ef({required Object i, required Object toStringAsFixed}) {
    return '$i · $toStringAsFixed h';
  }

  @override
  String get s_1597bc27 => 'Informe de lectura con IA';

  @override
  String s_5024726e({required Object reportCount}) {
    return '$reportCount archivados · por año / mes, puedes volver a verlos cuando quieras';
  }

  @override
  String get s_73f01b82 => 'Genera un resumen de lectura anual o mensual; ábrelo para crearlo';

  @override
  String get s_530f5951 => 'Ver';

  @override
  String get s_d51cd7ae => 'Generar';

  @override
  String get s_f8525cf2 => 'Todavía no hay datos';

  @override
  String s_854a34ca({required Object author}) {
    return ', de $author';
  }

  @override
  String s_edf331af({required Object detail}) {
    return ': $detail';
  }

  @override
  String s_50018e2c({required Object hint}) {
    return '\nContexto adicional: $hint\n';
  }

  @override
  String s_a537d6ac({required Object first}) {
    return '(copiado el $first)';
  }

  @override
  String s_acd7a061({required Object failed}) {
    return ', $failed fallidos';
  }

  @override
  String get s_da4d4d27 => ' · limpiado con el LLM';

  @override
  String s_af735e5a({required Object repairedTitles}) {
    return ' · $repairedTitles títulos truncados completados';
  }

  @override
  String get navNotes => 'Registros';

  @override
  String get notesViewByTime => 'Por tiempo';

  @override
  String get notesViewByBook => 'Por libro';

  @override
  String get notesFilterByBook => 'Filtrar por libro';

  @override
  String get notesAllBooks => 'Todos los libros';

  @override
  String get notesBookMissing => 'Libro eliminado';

  @override
  String notesOverview({required int count, required int books}) {
    return '$count notas · en $books libros';
  }

  @override
  String notesMoreCount({required int count}) {
    return '$count más';
  }

  @override
  String get notesEmptyTitle => 'Todavía no hay notas';

  @override
  String get notesEmptyDesc => 'Abre cualquier libro y añade un subrayado o una idea al final de su página de detalles: se recogerán aquí.';

  @override
  String get notesEmptyFilteredTitle => 'Este libro aún no tiene notas';

  @override
  String get notesEmptyFilteredDesc => 'Elige otro libro o quita el filtro para ver el resto.';

  @override
  String get notesClearFilter => 'Quitar filtro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageDesc => 'Elige el idioma de la app. Por defecto sigue el del sistema.';

  @override
  String get settingsLanguageSystem => 'Idioma del sistema';

  @override
  String get settingsCategoryPick => 'Elegir una categoría';

  @override
  String get settingsCategoryEmpty => 'No quedan categorías: añade una o restaura las predeterminadas.';

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
  String get settingsAppearance => 'Aspecto';

  @override
  String get settingsAppearanceDesc => 'Elige un tema y el modo claro u oscuro.';

  @override
  String get statusWishHint => 'Aún no lo has empezado.';

  @override
  String get statusReadingHint => 'Lo estás leyendo. Cuando el progreso llegue al 100% pasará a Terminado automáticamente.';

  @override
  String get statusFinishedHint => 'Libro terminado. Arrastra el progreso al 100% y se marcará solo.';

  @override
  String get statusShelvedHint => 'Empezado pero sin intención de continuar ahora. Vuelve a «Leyendo» para retomarlo.';

  @override
  String get borrowTitle => 'Prestado';

  @override
  String get borrowDesc => 'Marca el libro como prestado, indicando de quién lo tomaste y la fecha de devolución.';

  @override
  String get borrowFlag => 'Este libro es prestado';

  @override
  String get borrowFrom => 'Prestado por';

  @override
  String get borrowFromHint => 'p. ej. la Biblioteca Municipal, un compañero';

  @override
  String get borrowDue => 'Fecha de devolución';

  @override
  String get borrowDueUnset => 'Sin fijar';

  @override
  String borrowDueIn({required int days}) {
    return 'Quedan $days días para la devolución';
  }

  @override
  String borrowOverdue({required int days}) {
    return 'Atrasado $days días';
  }

  @override
  String get borrowClearDue => 'Borrar la fecha';

  @override
  String get borrowReturn => 'Marcar como devuelto';

  @override
  String get borrowReturnDesc => 'Al devolverlo se borran la marca de préstamo, la persona y la fecha, y se cancela el recordatorio.';

  @override
  String get borrowReturned => 'Marcado como devuelto';

  @override
  String get statusSectionTitle => 'Estado de lectura';

  @override
  String get planSectionTitle => 'Planes de lectura';

  @override
  String get planSectionDesc => 'Fija una meta que puedas cumplir de verdad. Los planes se quedan en este dispositivo.';

  @override
  String get planEmpty => 'Todavía no hay planes. Empieza por algo pequeño: 20 minutos al día.';

  @override
  String get planAdd => 'Nuevo plan';

  @override
  String get planEdit => 'Editar plan';

  @override
  String get planKindDaily => 'Leer todos los días';

  @override
  String get planKindFinishBook => 'Terminar un libro';

  @override
  String get planKindDailyDesc => 'Fija un tiempo de lectura diario; se evalúa con tu media diaria.';

  @override
  String get planKindFinishBookDesc => 'Elige un libro y una fecha límite; llegar al 100% lo completa.';

  @override
  String get planDailyTarget => 'Meta diaria';

  @override
  String planMinutesUnit({required int n}) {
    return '$n min';
  }

  @override
  String get planPickBook => 'Elige un libro';

  @override
  String get planDueLabel => 'Fecha límite';

  @override
  String get planDueUnset => 'Sin fijar';

  @override
  String get planRemind => 'Avisarme antes de la fecha límite';

  @override
  String get planRemindOff => 'Al activarlo se pedirá permiso para notificaciones. El recordatorio se cancela solo cuando el plan se completa.';

  @override
  String get planTitleLabel => 'Nombre del plan (opcional)';

  @override
  String get planTitleHint => 'Déjalo vacío para usar el nombre por defecto';

  @override
  String get planSave => 'Guardar';

  @override
  String get planDelete => 'Eliminar plan';

  @override
  String get planDeleteConfirm => '¿Eliminar este plan? Tus registros de lectura no se ven afectados.';

  @override
  String get planMarkDone => 'Marcar como hecho';

  @override
  String get planAchieved => 'Conseguido';

  @override
  String get planMarkToday => 'Hoy he leído';

  @override
  String get planDoneToday => 'Completado por hoy';

  @override
  String get planDailyCycleHint => 'Cada día es una vuelta a empezar: marcarlo solo cuenta para hoy, y el recordatorio vuelve mañana.';

  @override
  String get planReminderUnavailable => 'El sistema no ha podido programar el recordatorio (quizá el ahorro de energía lo ha bloqueado). El plan se ha guardado igualmente.';

  @override
  String planProgressDaily({required String current, required String target}) {
    return 'Media diaria $current / $target min';
  }

  @override
  String planProgressBook({required int current}) {
    return 'Progreso $current% · objetivo 100%';
  }

  @override
  String planDaysLeft({required int days}) {
    return 'Quedan $days días';
  }

  @override
  String planOverdue({required int days}) {
    return 'Atrasado $days días';
  }

  @override
  String planStreak({required int n}) {
    return 'Racha de $n días con marcar';
  }

  @override
  String get planDueToday => 'Vence hoy';

  @override
  String get planBookGone => 'El libro objetivo ya no está en tu estantería';

  @override
  String get planDoneSection => 'Terminados';

  @override
  String get planReminderDenied => 'Se ha denegado el permiso de notificaciones, así que no se pueden entregar los recordatorios. Actívalo en los ajustes del sistema.';

  @override
  String get planReminderDailyTitle => 'Todavía no has cumplido la meta de hoy';

  @override
  String planReminderDailyBody({required int minutes}) {
    return 'Tu meta es de $minutes minutos: todavía tienes tiempo.';
  }

  @override
  String get planReminderBookTitle => 'Se acerca una fecha límite de lectura';

  @override
  String planReminderBookBody({required int days}) {
    return 'Tu plan vence en $days días. Buen momento para terminarlo.';
  }

  @override
  String get settingsPlanReminder => 'Recordatorios de lectura';

  @override
  String get reportSettings => 'Ajustes del informe';

  @override
  String get reportBackfill => 'Generar los informes que falten';

  @override
  String get reportNothingToBackfill => 'Ya están todos los informes que deberían existir.';

  @override
  String get reportHistoryEmpty => 'Todavía no hay informes. Elige un periodo y genera el primero abajo.';

  @override
  String get reportNoKey => 'No hay ningún modelo configurado, así que no se pueden generar informes. Añade antes una key en Ajustes.';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsBrightness => 'Claro u oscuro';

  @override
  String get brightnessSystem => 'Seguir al sistema';

  @override
  String get brightnessLight => 'Claro';

  @override
  String get brightnessDark => 'Oscuro';

  @override
  String get themeGreen => 'Verde';

  @override
  String get themeInk => 'Tinta';

  @override
  String get themeBlue => 'Montaña';

  @override
  String get themePlum => 'Ciruela';

  @override
  String get themeLagoon => 'Laguna';

  @override
  String get themeBerry => 'Baya';

  @override
  String get settingsChannels => 'Servicios conectados';

  @override
  String get settingsChannelsDesc => 'Sincroniza tu estantería y tu progreso desde otras plataformas de lectura. Hoy se admite WeRead; se añadirán más cuando abran sus API.';

  @override
  String get settingsChannelsHint => 'Las keys se guardan solo en el llavero del sistema de este dispositivo y nunca se suben.';

  @override
  String get settingsChannelAddHint => 'Más servicios están en camino.';

  @override
  String get importAccuracyTitle => 'El resultado puede ser impreciso';

  @override
  String get importAccuracyDesc => 'Los títulos y los autores los infieren el OCR y los modelos de IA, así que pueden leer mal una palabra o elegir el libro equivocado. Revísalos antes de guardar.';

  @override
  String get importFromImageTitle => 'Importar desde una captura';

  @override
  String get importFromImageDesc => 'Elige una captura de tu estantería y detecta los libros que hay en ella.';

  @override
  String get importFromCameraTitle => 'Importar con la cámara';

  @override
  String get importFromCameraDesc => 'Haz una foto de tu estantería y detecta los libros que hay en ella.';

  @override
  String get insights => 'Archivo del lector';

  @override
  String get insightsDesc => 'Tu perfil de lectura a largo plazo, más los informes por mes y por año.';

  @override
  String get chronology => 'Cronología';

  @override
  String get chronologyDesc => 'Tu lectura mes a mes. Pulsa una tarjeta para abrir el libro.';

  @override
  String get chronologyEmpty => 'Este año aún no has terminado nada ni tienes algo en curso.';

  @override
  String get chronologyFinished => 'Terminados';

  @override
  String get chronologyReading => 'Leyendo';

  @override
  String get chronologyShelved => 'Apartados';

  @override
  String get chronologyWish => 'Quiero leer';

  @override
  String chronologyMore({required int n}) {
    return '$n más: ver el mes entero';
  }

  @override
  String get reportStyle => 'Estilo del informe';

  @override
  String get reportStyleDesc => 'Elige el tono y la estructura de los informes generados, o escribe tu propio prompt.';

  @override
  String get reportStyleRational => 'Hechos y datos';

  @override
  String get reportStyleRationalDesc => 'Expone los datos de forma objetiva: sin elogios, sin incitar a compartir ni a marcar días, con los puntos bien listados.';

  @override
  String get reportStyleWarm => 'Ánimo cálido';

  @override
  String get reportStyleWarmDesc => 'Reconoce tu constancia y te da consejo con suavidad.';

  @override
  String get reportStyleDirect => 'Franco y directo';

  @override
  String get reportStyleDirectDesc => 'Nombra los problemas sin suavizarlos, para quien prefiere las cosas claras.';

  @override
  String get reportStyleConcise => 'Breve';

  @override
  String get reportStyleConciseDesc => 'Solo conclusiones, tan escuetas como sea posible.';

  @override
  String get reportStyleCustom => 'Personalizado';

  @override
  String get reportStyleCustomDesc => 'Escribe el prompt tú mismo y controla exactamente cómo se leen los informes.';

  @override
  String get reportStyleCustomHint => 'p. ej. Háblame en segunda persona, como un amigo comentando mi lectura.';

  @override
  String get reportReadMore => 'Leer el informe completo';

  @override
  String get reportNoContent => '(este informe no tiene cuerpo de texto)';

  @override
  String get s_9f2c1d4e => 'Panorama';

  @override
  String get s_0f2b6c1a => 'Lectura de este periodo';

  @override
  String get s_7d1a4e35 => 'Estructura de la estantería';

  @override
  String get s_3c58b0d2 => 'Hábitos de lectura';

  @override
  String get s_4b7e2a19 => 'Libros que merecen mención';

  @override
  String get s_6e39f7c4 => 'Perfil del lector';

  @override
  String get s_1a8d53f6 => 'Qué leer a continuación';

  @override
  String get s_2f9d1a4b => 'Etiquetas';

  @override
  String get s_5c7e3d81 => 'Aún no hay etiquetas';

  @override
  String s_3e8f5b26({required Object title}) {
    return '¿Eliminar «$title»?';
  }

  @override
  String get s_7d4c2e91 => 'Sus registros de lectura y planes se eliminan con él. Tus notas se conservan: siguen en la pestaña Notas. Esta acción no se puede deshacer.';

  @override
  String s_1f6a8d37({required Object title}) {
    return '«$title» eliminado';
  }

  @override
  String get s_4b2c9e58 => 'Categorías';

  @override
  String get s_8d3f6a12 => 'Añade, renombra o elimina categorías. Los libros de una categoría eliminada pasan a «Sin clasificar».';

  @override
  String get s_2c8b5d09 => 'Nombre de la categoría';

  @override
  String get s_9f4e7a35 => 'El nombre de la categoría no puede estar vacío';

  @override
  String get s_7a2d6c81 => 'Esa categoría ya existe';

  @override
  String s_5e9c1b47({required Object name}) {
    return '«$name» añadida';
  }

  @override
  String s_3b7f2d64({required Object name}) {
    return '«$name» eliminada';
  }

  @override
  String s_8c4a1e92({required Object name}) {
    return '¿Eliminar la categoría «$name»?';
  }

  @override
  String s_1d7b3f08({required Object count}) {
    return 'Los $count libros que contiene pasarán a «Sin clasificar».';
  }

  @override
  String get s_6a9e4c27 => 'Renombrar';

  @override
  String get s_2f5d8b13 => 'Restaurar las categorías predeterminadas';

  @override
  String get s_4e1c7a69 => 'Categorías predeterminadas restauradas';

  @override
  String get s_9c3f5d21 => 'Personalizada';

  @override
  String s_9d2e7f13({required Object name, required Object count}) {
    return 'Renombrada a «$name»; $count libros actualizados';
  }

  @override
  String get themeBgStarfield => 'Cielo estrellado';

  @override
  String get themeBgMist => 'Niebla de montaña';

  @override
  String get themeBgMoss => 'Jardín de musgo';

  @override
  String get themeBgDusk => 'Luz de atardecer';

  @override
  String get themeBgCat => 'Siesta felina';

  @override
  String get themeBgDog => 'Parque canino';

  @override
  String get s_2f8a1c47 => 'Con textura';

  @override
  String get checkUpdate => 'Buscar actualizaciones';

  @override
  String get checkUpdateDesc => 'Comprueba si hay una versión más reciente. Si la hay, indicará qué cambió.';

  @override
  String get checkingForUpdate => 'Comprobando…';

  @override
  String get updateUpToDate => 'Ya tienes la última versión';

  @override
  String updateUpToDateDesc({required String version}) {
    return 'Estás en la versión $version. Aún no hay una versión más reciente.';
  }

  @override
  String updateAvailable({required String version}) {
    return 'La versión $version está disponible';
  }

  @override
  String updateAvailableDesc({required String current, required String latest}) {
    return 'Estás en $current. Actualiza a $latest cuando quieras: no se descarga nada automáticamente.';
  }

  @override
  String get updateNotesTitle => 'Qué ha cambiado';

  @override
  String get updateNoNotes => 'El publicador no escribió notas de esta versión.';

  @override
  String updateDownload({required String version}) {
    return 'Descargar $version';
  }

  @override
  String get updateOpenRelease => 'Abrir la página de la versión';

  @override
  String get updateCheckFailed => 'No se pudo buscar actualizaciones';

  @override
  String get updateCheckFailedNetwork => 'No se pudo contactar con el servidor. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get updateCheckFailedMalformed => 'El servidor devolvió algo ilegible. Inténtalo más tarde.';

  @override
  String updateNeverInstalled({required String version}) {
    return 'No se encontró instalador: $version está publicado, pero no se encontró ningún APK.';
  }

  @override
  String updateReleasedOn({required String date}) {
    return 'Publicado el $date';
  }
}
