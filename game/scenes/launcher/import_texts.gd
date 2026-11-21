extends RefCounted
## Import and import-error texts in the launcher languages (Assets.LANGUAGES).
## Python importer messages live in tools/pocx/messages.py; the launcher passes --lang.

const TEXT := {
	"reimport": {
		"s": "Volver a importar", "e": "Reimport", "g": "Erneut importieren",
		"f": "Réimporter", "i": "Reimporta", "j": "再インポート"},
	"resources_tooltip": {
		"s": "Importa voces, mazos, repeticiones o una partida guardada.",
		"e": "Import voice packs, decks, replays, or a saved game.",
		"g": "Stimmen, Decks, Wiederholungen oder einen Spielstand importieren.",
		"f": "Importe des voix, decks, rediffusions ou une sauvegarde.",
		"i": "Importa voci, mazzi, replay o un salvataggio.",
		"j": "音声、デッキ、リプレイ、セーブデータをインポートします。"},
	"settings_failed": {
		"s": "Los recursos se prepararon, pero no se pudieron guardar los ajustes: ",
		"e": "Resources were prepared, but settings could not be saved: ",
		"g": "Die Ressourcen wurden vorbereitet, aber die Einstellungen konnten nicht gespeichert werden: ",
		"f": "Les ressources sont prêtes, mais les paramètres n’ont pas pu être enregistrés : ",
		"i": "Le risorse sono pronte, ma non è stato possibile salvare le impostazioni: ",
		"j": "リソースは準備できましたが、設定を保存できませんでした: "},
	"title_import_failed": {
		"s": "No se pudo importar", "e": "Import failed", "g": "Import fehlgeschlagen",
		"f": "Échec de l’importation", "i": "Importazione non riuscita", "j": "インポートできませんでした"},
	"process_failed": {
		"s": "El proceso no se pudo iniciar o terminó con código %s.",
		"e": "The process could not start or exited with code %s.",
		"g": "Der Vorgang konnte nicht starten oder endete mit Code %s.",
		"f": "Le processus n’a pas pu démarrer ou s’est terminé avec le code %s.",
		"i": "Il processo non è riuscito ad avviarsi o è terminato con codice %s.",
		"j": "処理を開始できなかったか、コード %s で終了しました。"},
	"source_label": {
		"s": "Archivo o carpeta: ", "e": "File or folder: ", "g": "Datei oder Ordner: ",
		"f": "Fichier ou dossier : ", "i": "File o cartella: ", "j": "ファイルまたはフォルダー: "},
	"details_label": {
		"s": "Detalle técnico:", "e": "Technical details:", "g": "Technische Details:",
		"f": "Détails techniques :", "i": "Dettagli tecnici:", "j": "技術的な詳細:"},
	"log_label": {
		"s": "Registro completo: ", "e": "Full log: ", "g": "Vollständiges Protokoll: ",
		"f": "Journal complet : ", "i": "Registro completo: ", "j": "完全なログ: "},
	"log_not_saved": {
		"s": "No se pudo guardar el registro. Puedes copiar estos detalles.",
		"e": "Could not save the log. You can copy these details.",
		"g": "Das Protokoll konnte nicht gespeichert werden. Du kannst diese Details kopieren.",
		"f": "Impossible d’enregistrer le journal. Tu peux copier ces détails.",
		"i": "Impossibile salvare il registro. Puoi copiare questi dettagli.",
		"j": "ログを保存できませんでした。この詳細をコピーできます。"},
	"close": {"s": "Cerrar", "e": "Close", "g": "Schließen", "f": "Fermer", "i": "Chiudi", "j": "閉じる"},
	"copy_details": {"s": "Copiar detalles", "e": "Copy details", "g": "Details kopieren", "f": "Copier les détails", "i": "Copia dettagli", "j": "詳細をコピー"},
	"open_log": {"s": "Abrir registro", "e": "Open log", "g": "Protokoll öffnen", "f": "Ouvrir le journal", "i": "Apri registro", "j": "ログを開く"},
	"view_error": {"s": "Ver error", "e": "View error", "g": "Fehler anzeigen", "f": "Voir l’erreur", "i": "Vedi errore", "j": "エラーを表示"},
	"stage_iso": {"s": "ISO / extracción", "e": "ISO / extraction", "g": "ISO / Entpacken", "f": "ISO / extraction", "i": "ISO / estrazione", "j": "ISO / 展開"},
	"stage_installation": {"s": "Archivos del juego", "e": "Game files", "g": "Spieldateien", "f": "Fichiers du jeu", "i": "File del gioco", "j": "ゲームファイル"},
	"stage_yugi_update": {"s": "Actualización de Yugi", "e": "Yugi update", "g": "Yugi-Update", "f": "Mise à jour de Yugi", "i": "Aggiornamento di Yugi", "j": "Yugi のアップデート"},
	"kaiba_update_iso": {"s": "Elegir ISO de Kaiba", "e": "Choose Kaiba ISO", "g": "Kaiba-ISO wählen", "f": "Choisir l’ISO de Kaiba", "i": "Scegli ISO di Kaiba", "j": "Kaiba の ISO を選択"},
	"kaiba_update_disc": {"s": "Elegir disco o carpeta de Kaiba", "e": "Choose Kaiba disc or folder", "g": "Kaiba-CD oder Ordner wählen", "f": "Choisir le disque ou dossier de Kaiba", "i": "Scegli disco o cartella di Kaiba", "j": "Kaiba のディスクまたはフォルダーを選択"},
	"stage_write": {"s": "Escritura de archivos", "e": "Writing files", "g": "Dateien schreiben", "f": "Écriture des fichiers", "i": "Scrittura dei file", "j": "ファイルの書き込み"},
	"stage_conversion": {"s": "Conversión", "e": "Conversion", "g": "Konvertierung", "f": "Conversion", "i": "Conversione", "j": "変換"},
	"stage_audio": {"s": "Conversión de audio", "e": "Audio conversion", "g": "Audiokonvertierung", "f": "Conversion audio", "i": "Conversione audio", "j": "音声の変換"},
	"stage_compact": {"s": "Compresión", "e": "Compression", "g": "Komprimierung", "f": "Compression", "i": "Compressione", "j": "圧縮"},
	"stage_voices": {"s": "Voces adicionales", "e": "Additional voices", "g": "Zusätzliche Stimmen", "f": "Voix supplémentaires", "i": "Voci aggiuntive", "j": "追加音声"},
	"stage_setup": {"s": "Preparación", "e": "Setup", "g": "Vorbereitung", "f": "Préparation", "i": "Preparazione", "j": "準備"},
	"stage_process": {"s": "Proceso", "e": "Process", "g": "Vorgang", "f": "Processus", "i": "Processo", "j": "処理"},
}



static func text(key: String, lang: String) -> String:
	var entry: Dictionary = TEXT[key]
	return str(entry.get(lang, entry["e"]))

