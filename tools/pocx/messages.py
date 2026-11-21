"""User-facing importer messages in the launcher languages.

The launcher passes its language with --lang (Assets.lang: s, e, g, f, i, j).
Spanish stays the default so command-line use and tests keep their wording.
Internal/technical errors are not listed here: the launcher shows a translated
summary for their stage and keeps the original text as technical details.
"""
from __future__ import annotations

LANGUAGES = ("s", "e", "g", "f", "i", "j")
LANGUAGE = "s"


class UserError(ValueError):
    """An error whose text is already translated for the launcher language."""


def set_language(value: str) -> None:
    global LANGUAGE
    LANGUAGE = value if value in LANGUAGES else "e"


def t(key: str, **values) -> str:
    entry = MESSAGES[key]
    return entry.get(LANGUAGE, entry["e"]).format(**values)


def error(key: str, **values) -> UserError:
    return UserError(t(key, **values))


MESSAGES: dict[str, dict[str, str]] = {
    # --- Game sources -------------------------------------------------------------
    "install_count": {
        "s": "{game}: se esperaba una instalación con Data.dat, Voice.dat, Region.dat y {exe}; encontradas: {count}",
        "e": "{game}: expected one installation with Data.dat, Voice.dat, Region.dat and {exe}; found: {count}",
        "g": "{game}: Erwartet wurde eine Installation mit Data.dat, Voice.dat, Region.dat und {exe}; gefunden: {count}",
        "f": "{game} : une installation avec Data.dat, Voice.dat, Region.dat et {exe} était attendue ; trouvées : {count}",
        "i": "{game}: era prevista un'installazione con Data.dat, Voice.dat, Region.dat e {exe}; trovate: {count}",
        "j": "{game}: Data.dat、Voice.dat、Region.dat、{exe} を含むインストールが 1 つ必要です。見つかった数: {count}",
    },
    "archive_empty": {
        "s": "{game}: {name} está vacío",
        "e": "{game}: {name} is empty",
        "g": "{game}: {name} ist leer",
        "f": "{game} : {name} est vide",
        "i": "{game}: {name} è vuoto",
        "j": "{game}: {name} が空です",
    },
    "archive_damaged": {
        "s": "{game}: {name} está dañado o no es un archivo de Power of Chaos. Usa una instalación o ISO completa.",
        "e": "{game}: {name} is damaged or is not a Power of Chaos file. Use a complete installation or ISO.",
        "g": "{game}: {name} ist beschädigt oder keine Power-of-Chaos-Datei. Verwende eine vollständige Installation oder ISO.",
        "f": "{game} : {name} est endommagé ou n’est pas un fichier de Power of Chaos. Utilise une installation ou une ISO complète.",
        "i": "{game}: {name} è danneggiato o non è un file di Power of Chaos. Usa un'installazione o una ISO completa.",
        "j": "{game}: {name} が壊れているか、Power of Chaos のファイルではありません。完全なインストールまたは ISO を使ってください。",
    },
    "foreign_owner": {
        "s": "{game}: el Data.dat de {folder} es de {found}, no de {title}. Si instalaste varios juegos en la misma carpeta, uno sobrescribió los datos del otro: selecciona la instalación o ISO propia de {title}.",
        "e": "{game}: the Data.dat in {folder} belongs to {found}, not {title}. If several games were installed in the same folder, one overwrote the other's data: select {title}'s own installation or ISO.",
        "g": "{game}: Die Data.dat in {folder} gehört zu {found}, nicht zu {title}. Wenn mehrere Spiele im selben Ordner installiert wurden, hat eines die Daten des anderen überschrieben: Wähle die eigene Installation oder ISO von {title}.",
        "f": "{game} : le Data.dat de {folder} appartient à {found}, pas à {title}. Si plusieurs jeux ont été installés dans le même dossier, l’un a écrasé les données de l’autre : sélectionne l’installation ou l’ISO propre à {title}.",
        "i": "{game}: il Data.dat in {folder} appartiene a {found}, non a {title}. Se hai installato più giochi nella stessa cartella, uno ha sovrascritto i dati dell'altro: seleziona l'installazione o la ISO di {title}.",
        "j": "{game}: {folder} の Data.dat は {title} ではなく {found} のものです。複数のゲームを同じフォルダーにインストールすると、データが上書きされます。{title} 専用のインストールまたは ISO を選んでください。",
    },
    "foreign_unknown": {
        "s": "{game}: el Data.dat de {folder} no corresponde a ninguna versión compatible de {title} (falta {missing}). Puede estar modificado por un mod o pack de cartas: usa una instalación o ISO original sin mods.",
        "e": "{game}: the Data.dat in {folder} does not match any compatible version of {title} ({missing} is missing). It may have been changed by a mod or card pack: use an original, unmodified installation or ISO.",
        "g": "{game}: Die Data.dat in {folder} passt zu keiner kompatiblen Version von {title} ({missing} fehlt). Sie wurde womöglich durch eine Mod oder ein Kartenpaket verändert: Verwende eine originale, unveränderte Installation oder ISO.",
        "f": "{game} : le Data.dat de {folder} ne correspond à aucune version compatible de {title} ({missing} manquant). Il a peut-être été modifié par un mod ou un pack de cartes : utilise une installation ou une ISO d’origine, sans mods.",
        "i": "{game}: il Data.dat in {folder} non corrisponde a nessuna versione compatibile di {title} (manca {missing}). Potrebbe essere stato modificato da una mod o da un pacchetto di carte: usa un'installazione o una ISO originale senza mod.",
        "j": "{game}: {folder} の Data.dat は {title} の対応バージョンと一致しません ({missing} がありません)。MOD やカードパックで変更されている可能性があります。MOD のない元のインストールまたは ISO を使ってください。",
    },
    "yugi_us_2003": {
        "s": "La edición estadounidense original de Yugi (165 cartas) necesita la actualización de diciembre de 2003. Selecciona el disco o la ISO estadounidense de Kaiba the Revenge para aplicarla durante la importación.",
        "e": "The original US edition of Yugi (165 cards) needs the December 2003 update. Select the US Kaiba the Revenge disc or ISO to apply it during import.",
        "g": "Die ursprüngliche US-Ausgabe von Yugi (165 Karten) benötigt das Update vom Dezember 2003. Wähle die US-CD oder ISO von Kaiba the Revenge, um es beim Import anzuwenden.",
        "f": "L’édition américaine d’origine de Yugi (165 cartes) nécessite la mise à jour de décembre 2003. Sélectionne le disque ou l’ISO américaine de Kaiba the Revenge pour l’appliquer à l’importation.",
        "i": "L’edizione statunitense originale di Yugi (165 carte) richiede l’aggiornamento di dicembre 2003. Seleziona il disco o l’ISO statunitense di Kaiba the Revenge per applicarlo durante l’importazione.",
        "j": "Yugi の米国版オリジナル（165 枚）には 2003 年 12 月のアップデートが必要です。インポート時に適用するには、Kaiba the Revenge の米国版ディスクまたは ISO を選んでください。",
    },
    "yugi_update_invalid": {
        "s": "No se pudo extraer la actualización de Yugi. Selecciona un disco o una ISO estadounidense de Kaiba the Revenge que incluya la actualización de diciembre de 2003.",
        "e": "The Yugi update could not be extracted. Select a US Kaiba the Revenge disc or ISO that includes the December 2003 update.",
        "g": "Das Yugi-Update konnte nicht extrahiert werden. Wähle eine US-CD oder ISO von Kaiba the Revenge mit dem Update vom Dezember 2003.",
        "f": "Impossible d’extraire la mise à jour de Yugi. Sélectionne un disque ou une ISO américaine de Kaiba the Revenge contenant la mise à jour de décembre 2003.",
        "i": "Impossibile estrarre l’aggiornamento di Yugi. Seleziona un disco o un’ISO statunitense di Kaiba the Revenge con l’aggiornamento di dicembre 2003.",
        "j": "Yugi のアップデートを抽出できませんでした。2003 年 12 月のアップデートを含む Kaiba the Revenge の米国版ディスクまたは ISO を選んでください。",
    },
    "yugi_update_applied": {
        "s": "Actualización oficial de Yugi extraída del disco de Kaiba.",
        "e": "Official Yugi update extracted from the Kaiba disc.",
        "g": "Das offizielle Yugi-Update wurde von der Kaiba-CD extrahiert.",
        "f": "Mise à jour officielle de Yugi extraite du disque de Kaiba.",
        "i": "Aggiornamento ufficiale di Yugi estratto dal disco di Kaiba.",
        "j": "Kaiba のディスクから Yugi の公式アップデートを抽出しました。",
    },
    "exe_incompatible": {
        "s": "{game}: {exe} no es una versión compatible de {title}. Puede estar modificado por un mod: usa el ejecutable de una instalación o ISO original.",
        "e": "{game}: {exe} is not a compatible version of {title}. It may have been changed by a mod: use the executable from an original installation or ISO.",
        "g": "{game}: {exe} ist keine kompatible Version von {title}. Sie wurde womöglich durch eine Mod verändert: Verwende die ausführbare Datei einer originalen Installation oder ISO.",
        "f": "{game} : {exe} n’est pas une version compatible de {title}. Il a peut-être été modifié par un mod : utilise l’exécutable d’une installation ou d’une ISO d’origine.",
        "i": "{game}: {exe} non è una versione compatibile di {title}. Potrebbe essere stato modificato da una mod: usa l'eseguibile di un'installazione o di una ISO originale.",
        "j": "{game}: {exe} は {title} の対応バージョンではありません。MOD で変更されている可能性があります。元のインストールまたは ISO の実行ファイルを使ってください。",
    },
    "no_7zip": {
        "s": "No se encuentra 7-Zip. Instálalo o selecciona una carpeta instalada.",
        "e": "7-Zip was not found. Install it or select an installed folder.",
        "g": "7-Zip wurde nicht gefunden. Installiere es oder wähle einen installierten Ordner.",
        "f": "7-Zip est introuvable. Installe-le ou sélectionne un dossier installé.",
        "i": "7-Zip non trovato. Installalo o seleziona una cartella installata.",
        "j": "7-Zip が見つかりません。インストールするか、インストール済みのフォルダーを選んでください。",
    },
    "select_media": {
        "s": "Selecciona una carpeta instalada o un archivo .iso",
        "e": "Select an installed folder or an .iso file",
        "g": "Wähle einen installierten Ordner oder eine .iso-Datei",
        "f": "Sélectionne un dossier installé ou un fichier .iso",
        "i": "Seleziona una cartella installata o un file .iso",
        "j": "インストール済みのフォルダーか .iso ファイルを選んでください",
    },
    "iso_truncated": {
        "s": "La ISO está incompleta o truncada. Selecciona una imagen completa o una carpeta instalada.",
        "e": "The ISO is incomplete or truncated. Select a complete image or an installed folder.",
        "g": "Die ISO ist unvollständig oder abgeschnitten. Wähle ein vollständiges Abbild oder einen installierten Ordner.",
        "f": "L’ISO est incomplète ou tronquée. Sélectionne une image complète ou un dossier installé.",
        "i": "La ISO è incompleta o troncata. Seleziona un'immagine completa o una cartella installata.",
        "j": "ISO が不完全か途中で切れています。完全なイメージかインストール済みのフォルダーを選んでください。",
    },
    "iso_failed": {
        "s": "7-Zip no pudo extraer la ISO (código {code}). Revisa el detalle técnico.",
        "e": "7-Zip could not extract the ISO (code {code}). See the technical details.",
        "g": "7-Zip konnte die ISO nicht entpacken (Code {code}). Siehe technische Details.",
        "f": "7-Zip n’a pas pu extraire l’ISO (code {code}). Consulte les détails techniques.",
        "i": "7-Zip non è riuscito a estrarre la ISO (codice {code}). Controlla i dettagli tecnici.",
        "j": "7-Zip で ISO を展開できませんでした (コード {code})。技術的な詳細を確認してください。",
    },
    "installer_needs_inno": {
        "s": "El medio contiene un instalador. Instala innoextract en PATH o selecciona el juego ya instalado.",
        "e": "The media contains an installer. Install innoextract on PATH or select the installed game.",
        "g": "Das Medium enthält ein Installationsprogramm. Installiere innoextract im PATH oder wähle das installierte Spiel.",
        "f": "Le support contient un programme d’installation. Installe innoextract dans le PATH ou sélectionne le jeu installé.",
        "i": "Il supporto contiene un programma di installazione. Installa innoextract nel PATH o seleziona il gioco installato.",
        "j": "メディアにインストーラーが含まれています。innoextract を PATH に入れるか、インストール済みのゲームを選んでください。",
    },
    "no_compatible_install": {
        "s": "{game}: no se encontró una instalación compatible en el medio",
        "e": "{game}: no compatible installation was found on the media",
        "g": "{game}: Auf dem Medium wurde keine kompatible Installation gefunden",
        "f": "{game} : aucune installation compatible n’a été trouvée sur le support",
        "i": "{game}: nessuna installazione compatibile trovata sul supporto",
        "j": "{game}: メディアに対応するインストールが見つかりませんでした",
    },
    # --- Library ------------------------------------------------------------------
    "dest_exists_kept": {
        "s": "La carpeta de destino ya existe; se conserva intacta. Selecciona un destino nuevo.",
        "e": "The destination folder already exists and was left untouched. Select a new destination.",
        "g": "Der Zielordner existiert bereits und bleibt unverändert. Wähle ein neues Ziel.",
        "f": "Le dossier de destination existe déjà et reste intact. Sélectionne une nouvelle destination.",
        "i": "La cartella di destinazione esiste già e non è stata toccata. Seleziona una nuova destinazione.",
        "j": "保存先フォルダーは既に存在するため、そのままにしました。新しい保存先を選んでください。",
    },
    "dest_not_library": {
        "s": "El destino no es una biblioteca de recursos compatible",
        "e": "The destination is not a compatible resource library",
        "g": "Das Ziel ist keine kompatible Ressourcenbibliothek",
        "f": "La destination n’est pas une bibliothèque de ressources compatible",
        "i": "La destinazione non è una libreria di risorse compatibile",
        "j": "保存先は対応するリソースライブラリではありません",
    },
    "select_one_game": {
        "s": "Selecciona al menos un juego compatible",
        "e": "Select at least one compatible game",
        "g": "Wähle mindestens ein kompatibles Spiel",
        "f": "Sélectionne au moins un jeu compatible",
        "i": "Seleziona almeno un gioco compatibile",
        "j": "対応するゲームを 1 つ以上選んでください",
    },
    "dest_inside_base": {
        "s": "El destino debe estar fuera de los datos existentes",
        "e": "The destination must be outside the existing data",
        "g": "Das Ziel muss außerhalb der vorhandenen Daten liegen",
        "f": "La destination doit se trouver en dehors des données existantes",
        "i": "La destinazione deve trovarsi fuori dai dati esistenti",
        "j": "保存先は既存のデータの外にする必要があります",
    },
    "game_already": {
        "s": "Ese juego ya está preparado",
        "e": "That game is already prepared",
        "g": "Dieses Spiel ist bereits vorbereitet",
        "f": "Ce jeu est déjà prêt",
        "i": "Quel gioco è già pronto",
        "j": "そのゲームは既に準備済みです",
    },
    "dest_exists": {
        "s": "El destino ya existe",
        "e": "The destination already exists",
        "g": "Das Ziel existiert bereits",
        "f": "La destination existe déjà",
        "i": "La destinazione esiste già",
        "j": "保存先は既に存在します",
    },
    # --- Voices -------------------------------------------------------------------
    "prepare_before_voices": {
        "s": "{game}: prepara el juego antes de añadir voces",
        "e": "{game}: prepare the game before adding voices",
        "g": "{game}: Bereite das Spiel vor, bevor du Stimmen hinzufügst",
        "f": "{game} : prépare le jeu avant d’ajouter des voix",
        "i": "{game}: prepara il gioco prima di aggiungere le voci",
        "j": "{game}: 音声を追加する前にゲームを準備してください",
    },
    "unknown_voice_game": {
        "s": "Juego no reconocido para voces: {game}",
        "e": "Unrecognized game for voices: {game}",
        "g": "Unbekanntes Spiel für Stimmen: {game}",
        "f": "Jeu non reconnu pour les voix : {game}",
        "i": "Gioco non riconosciuto per le voci: {game}",
        "j": "音声の対象として認識できないゲーム: {game}",
    },
    "voice_usage": {
        "s": "Usa --voice juego=ruta/Voice.dat",
        "e": "Use --voice game=path/Voice.dat",
        "g": "Verwende --voice spiel=pfad/Voice.dat",
        "f": "Utilise --voice jeu=chemin/Voice.dat",
        "i": "Usa --voice gioco=percorso/Voice.dat",
        "j": "--voice ゲーム=パス/Voice.dat の形式で指定してください",
    },
    "voice_path_bad": {
        "s": "{game}: ruta de voces no compatible: {name}",
        "e": "{game}: unsupported voice path: {name}",
        "g": "{game}: nicht unterstützter Stimmenpfad: {name}",
        "f": "{game} : chemin de voix non pris en charge : {name}",
        "i": "{game}: percorso delle voci non supportato: {name}",
        "j": "{game}: 対応していない音声パス: {name}",
    },
    "voice_duplicate": {
        "s": "{game}: dos paquetes distintos para el mismo idioma {language}; no se sobrescriben",
        "e": "{game}: two different packs for the same language {language}; neither is overwritten",
        "g": "{game}: zwei verschiedene Pakete für dieselbe Sprache {language}; keines wird überschrieben",
        "f": "{game} : deux packs différents pour la même langue {language} ; aucun n’est écrasé",
        "i": "{game}: due pacchetti diversi per la stessa lingua {language}; nessuno viene sovrascritto",
        "j": "{game}: 同じ言語 {language} に異なるパックが 2 つあります。上書きはしません",
    },
    "voice_empty": {
        "s": "{game}: el paquete de voces no contiene WAV compatibles",
        "e": "{game}: the voice pack contains no compatible WAV files",
        "g": "{game}: Das Stimmenpaket enthält keine kompatiblen WAV-Dateien",
        "f": "{game} : le pack de voix ne contient aucun fichier WAV compatible",
        "i": "{game}: il pacchetto di voci non contiene file WAV compatibili",
        "j": "{game}: 音声パックに対応する WAV がありません",
    },
    # --- Progress -----------------------------------------------------------------
    "validating": {
        "s": "Validando {game}…", "e": "Checking {game}…", "g": "{game} wird geprüft…",
        "f": "Vérification de {game}…", "i": "Verifica di {game}…", "j": "{game} を確認しています…",
    },
    "import_done": {
        "s": "Importación completa.", "e": "Import complete.", "g": "Import abgeschlossen.",
        "f": "Importation terminée.", "i": "Importazione completata.", "j": "インポートが完了しました。",
    },
    "cli_failed": {
        "s": "No se pudo importar: {error}", "e": "Could not import: {error}", "g": "Import fehlgeschlagen: {error}",
        "f": "Échec de l’importation : {error}", "i": "Importazione non riuscita: {error}", "j": "インポートできませんでした: {error}",
    },
    # --- Summary for internal errors, by stage (original text goes to details) --------
    "stage.iso": {
        "s": "No se pudo leer la ISO o el medio seleccionado. Revisa el detalle técnico.",
        "e": "The selected ISO or media could not be read. See the technical details.",
        "g": "Die gewählte ISO bzw. das Medium konnte nicht gelesen werden. Siehe technische Details.",
        "f": "Impossible de lire l’ISO ou le support sélectionné. Consulte les détails techniques.",
        "i": "Impossibile leggere la ISO o il supporto selezionato. Controlla i dettagli tecnici.",
        "j": "選んだ ISO またはメディアを読み込めませんでした。技術的な詳細を確認してください。",
    },
    "stage.installation": {
        "s": "Los archivos del juego no son compatibles o están dañados. Revisa el detalle técnico.",
        "e": "The game files are incompatible or damaged. See the technical details.",
        "g": "Die Spieldateien sind nicht kompatibel oder beschädigt. Siehe technische Details.",
        "f": "Les fichiers du jeu sont incompatibles ou endommagés. Consulte les détails techniques.",
        "i": "I file del gioco non sono compatibili o sono danneggiati. Controlla i dettagli tecnici.",
        "j": "ゲームファイルが対応していないか、壊れています。技術的な詳細を確認してください。",
    },
    "stage.write": {
        "s": "No se pudieron escribir los archivos. Comprueba el espacio libre y los permisos de la carpeta.",
        "e": "The files could not be written. Check free space and folder permissions.",
        "g": "Die Dateien konnten nicht geschrieben werden. Prüfe den freien Speicher und die Ordnerberechtigungen.",
        "f": "Impossible d’écrire les fichiers. Vérifie l’espace libre et les autorisations du dossier.",
        "i": "Impossibile scrivere i file. Controlla lo spazio libero e i permessi della cartella.",
        "j": "ファイルを書き込めませんでした。空き容量とフォルダーの権限を確認してください。",
    },
    "stage.conversion": {
        "s": "No se pudieron convertir los recursos del juego. Revisa el detalle técnico.",
        "e": "The game resources could not be converted. See the technical details.",
        "g": "Die Spielressourcen konnten nicht konvertiert werden. Siehe technische Details.",
        "f": "Impossible de convertir les ressources du jeu. Consulte les détails techniques.",
        "i": "Impossibile convertire le risorse del gioco. Controlla i dettagli tecnici.",
        "j": "ゲームのリソースを変換できませんでした。技術的な詳細を確認してください。",
    },
    "stage.audio": {
        "s": "No se pudo convertir el audio del juego. Revisa el detalle técnico.",
        "e": "The game audio could not be converted. See the technical details.",
        "g": "Der Spielton konnte nicht konvertiert werden. Siehe technische Details.",
        "f": "Impossible de convertir l’audio du jeu. Consulte les détails techniques.",
        "i": "Impossibile convertire l'audio del gioco. Controlla i dettagli tecnici.",
        "j": "ゲームの音声を変換できませんでした。技術的な詳細を確認してください。",
    },
    "stage.compact": {
        "s": "No se pudieron comprimir los recursos convertidos. Revisa el detalle técnico.",
        "e": "The converted resources could not be compressed. See the technical details.",
        "g": "Die konvertierten Ressourcen konnten nicht komprimiert werden. Siehe technische Details.",
        "f": "Impossible de compresser les ressources converties. Consulte les détails techniques.",
        "i": "Impossibile comprimere le risorse convertite. Controlla i dettagli tecnici.",
        "j": "変換したリソースを圧縮できませんでした。技術的な詳細を確認してください。",
    },
    "stage.voices": {
        "s": "No se pudieron añadir las voces adicionales. Revisa el detalle técnico.",
        "e": "The additional voices could not be added. See the technical details.",
        "g": "Die zusätzlichen Stimmen konnten nicht hinzugefügt werden. Siehe technische Details.",
        "f": "Impossible d’ajouter les voix supplémentaires. Consulte les détails techniques.",
        "i": "Impossibile aggiungere le voci aggiuntive. Controlla i dettagli tecnici.",
        "j": "追加音声を追加できませんでした。技術的な詳細を確認してください。",
    },
    "stage.setup": {
        "s": "No se pudo completar el proceso. Revisa el detalle técnico.",
        "e": "The process could not be completed. See the technical details.",
        "g": "Der Vorgang konnte nicht abgeschlossen werden. Siehe technische Details.",
        "f": "Le processus n’a pas pu aboutir. Consulte les détails techniques.",
        "i": "Impossibile completare il processo. Controlla i dettagli tecnici.",
        "j": "処理を完了できませんでした。技術的な詳細を確認してください。",
    },
}

