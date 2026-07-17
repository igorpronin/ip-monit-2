import Foundation
import Combine

enum L10nKey: String {
    case detecting, noInternet, refreshNow, copyIPv4, copyIPv6
    case floatingWindow, launchAtLogin, about, quit, hideWindow, language
    case aboutText, openProjectFolder, loginItemError
    case geoModeMenu, geoModeVirtual, geoModePhysical
    case compactWindow
    case alignMenu, alignLeft, alignRight
}

@MainActor
final class L10n: ObservableObject {
    static let shared = L10n()

    @Published var lang: String {
        didSet { UserDefaults.standard.set(lang, forKey: "AppLanguage") }
    }

    private init() {
        lang = UserDefaults.standard.string(forKey: "AppLanguage") ?? "en"
    }

    static let languages: [(code: String, name: String)] = [
        ("en", "English"),
        ("ru", "Русский"),
        ("es", "Español"),
        ("de", "Deutsch"),
        ("fr", "Français"),
        ("it", "Italiano"),
        ("pt", "Português"),
        ("zh", "中文"),
        ("ja", "日本語"),
        ("ko", "한국어"),
    ]

    func t(_ key: L10nKey) -> String {
        Self.tables[lang]?[key] ?? Self.tables["en"]![key]!
    }

    func countryName(_ cc: String?) -> String {
        guard let cc else { return "—" }
        return Locale(identifier: lang).localizedString(forRegionCode: cc) ?? cc
    }

    private static let tables: [String: [L10nKey: String]] = [
        "en": [
            .detecting: "Detecting…",
            .noInternet: "No internet connection",
            .refreshNow: "Refresh now",
            .copyIPv4: "Copy IPv4",
            .copyIPv6: "Copy IPv6",
            .floatingWindow: "Floating window on top",
            .launchAtLogin: "Launch at login",
            .about: "About…",
            .quit: "Quit",
            .hideWindow: "Hide window",
            .language: "Language",
            .openProjectFolder: "Open project folder",
            .loginItemError: "Failed to change login item",
            .aboutText: "Shows your external IP address and the country of your internet exit point (VPN), so you can always see where you access the internet from.",
            .geoModeMenu: "Shown country",
            .geoModeVirtual: "Virtual — MaxMind (as websites see it)",
            .geoModePhysical: "Physical — Cloudflare (actual server location)",
            .compactWindow: "Compact window",
            .alignMenu: "Alignment",
            .alignLeft: "Left",
            .alignRight: "Right",
        ],
        "ru": [
            .detecting: "Определяю…",
            .noInternet: "Нет доступа в интернет",
            .refreshNow: "Обновить сейчас",
            .copyIPv4: "Копировать IPv4",
            .copyIPv6: "Копировать IPv6",
            .floatingWindow: "Окошко поверх всех окон",
            .launchAtLogin: "Запускать при входе в систему",
            .about: "О программе…",
            .quit: "Выход",
            .hideWindow: "Скрыть окошко",
            .language: "Язык",
            .openProjectFolder: "Открыть папку проекта",
            .loginItemError: "Не удалось изменить автозапуск",
            .aboutText: "Показывает внешний IP-адрес и страну точки выхода в интернет (VPN), чтобы всегда было видно, откуда осуществляется доступ в сеть.",
            .geoModeMenu: "Отображаемая страна",
            .geoModeVirtual: "Виртуальная — MaxMind (как видят сайты)",
            .geoModePhysical: "Физическая — Cloudflare (реальное расположение сервера)",
            .compactWindow: "Компактное окошко",
            .alignMenu: "Выравнивание",
            .alignLeft: "Слева",
            .alignRight: "Справа",
        ],
        "es": [
            .detecting: "Detectando…",
            .noInternet: "Sin conexión a internet",
            .refreshNow: "Actualizar ahora",
            .copyIPv4: "Copiar IPv4",
            .copyIPv6: "Copiar IPv6",
            .floatingWindow: "Ventana siempre visible",
            .launchAtLogin: "Abrir al iniciar sesión",
            .about: "Acerca de…",
            .quit: "Salir",
            .hideWindow: "Ocultar ventana",
            .language: "Idioma",
            .openProjectFolder: "Abrir carpeta del proyecto",
            .loginItemError: "No se pudo cambiar el inicio automático",
            .aboutText: "Muestra la dirección IP externa y el país del punto de salida a internet (VPN), para que siempre veas desde dónde accedes a internet.",
            .geoModeMenu: "País mostrado",
            .geoModeVirtual: "Virtual — MaxMind (como lo ven los sitios web)",
            .geoModePhysical: "Físico — Cloudflare (ubicación real del servidor)",
            .compactWindow: "Ventana compacta",
            .alignMenu: "Alineación",
            .alignLeft: "Izquierda",
            .alignRight: "Derecha",
        ],
        "de": [
            .detecting: "Ermittle…",
            .noInternet: "Keine Internetverbindung",
            .refreshNow: "Jetzt aktualisieren",
            .copyIPv4: "IPv4 kopieren",
            .copyIPv6: "IPv6 kopieren",
            .floatingWindow: "Fenster immer im Vordergrund",
            .launchAtLogin: "Beim Anmelden starten",
            .about: "Über…",
            .quit: "Beenden",
            .hideWindow: "Fenster ausblenden",
            .language: "Sprache",
            .openProjectFolder: "Projektordner öffnen",
            .loginItemError: "Autostart konnte nicht geändert werden",
            .aboutText: "Zeigt die externe IP-Adresse und das Land des Internet-Austrittspunkts (VPN), damit immer sichtbar ist, von wo aus auf das Internet zugegriffen wird.",
            .geoModeMenu: "Angezeigtes Land",
            .geoModeVirtual: "Virtuell — MaxMind (wie Websites es sehen)",
            .geoModePhysical: "Physisch — Cloudflare (tatsächlicher Serverstandort)",
            .compactWindow: "Kompaktes Fenster",
            .alignMenu: "Ausrichtung",
            .alignLeft: "Links",
            .alignRight: "Rechts",
        ],
        "fr": [
            .detecting: "Détection…",
            .noInternet: "Pas de connexion internet",
            .refreshNow: "Actualiser maintenant",
            .copyIPv4: "Copier IPv4",
            .copyIPv6: "Copier IPv6",
            .floatingWindow: "Fenêtre toujours au premier plan",
            .launchAtLogin: "Lancer à l'ouverture de session",
            .about: "À propos…",
            .quit: "Quitter",
            .hideWindow: "Masquer la fenêtre",
            .language: "Langue",
            .openProjectFolder: "Ouvrir le dossier du projet",
            .loginItemError: "Impossible de modifier le démarrage automatique",
            .aboutText: "Affiche l'adresse IP externe et le pays du point de sortie internet (VPN), pour toujours voir d'où vous accédez à internet.",
            .geoModeMenu: "Pays affiché",
            .geoModeVirtual: "Virtuel — MaxMind (vu par les sites web)",
            .geoModePhysical: "Physique — Cloudflare (emplacement réel du serveur)",
            .compactWindow: "Fenêtre compacte",
            .alignMenu: "Alignement",
            .alignLeft: "Gauche",
            .alignRight: "Droite",
        ],
        "it": [
            .detecting: "Rilevamento…",
            .noInternet: "Nessuna connessione a internet",
            .refreshNow: "Aggiorna ora",
            .copyIPv4: "Copia IPv4",
            .copyIPv6: "Copia IPv6",
            .floatingWindow: "Finestra sempre in primo piano",
            .launchAtLogin: "Avvia all'accesso",
            .about: "Informazioni…",
            .quit: "Esci",
            .hideWindow: "Nascondi finestra",
            .language: "Lingua",
            .openProjectFolder: "Apri cartella del progetto",
            .loginItemError: "Impossibile modificare l'avvio automatico",
            .aboutText: "Mostra l'indirizzo IP esterno e il paese del punto di uscita internet (VPN), per vedere sempre da dove accedi a internet.",
            .geoModeMenu: "Paese mostrato",
            .geoModeVirtual: "Virtuale — MaxMind (come lo vedono i siti)",
            .geoModePhysical: "Fisico — Cloudflare (posizione reale del server)",
            .compactWindow: "Finestra compatta",
            .alignMenu: "Allineamento",
            .alignLeft: "Sinistra",
            .alignRight: "Destra",
        ],
        "pt": [
            .detecting: "Detectando…",
            .noInternet: "Sem conexão com a internet",
            .refreshNow: "Atualizar agora",
            .copyIPv4: "Copiar IPv4",
            .copyIPv6: "Copiar IPv6",
            .floatingWindow: "Janela sempre visível",
            .launchAtLogin: "Iniciar ao fazer login",
            .about: "Sobre…",
            .quit: "Sair",
            .hideWindow: "Ocultar janela",
            .language: "Idioma",
            .openProjectFolder: "Abrir pasta do projeto",
            .loginItemError: "Não foi possível alterar a inicialização automática",
            .aboutText: "Mostra o endereço IP externo e o país do ponto de saída da internet (VPN), para sempre ver de onde você acessa a internet.",
            .geoModeMenu: "País exibido",
            .geoModeVirtual: "Virtual — MaxMind (como os sites veem)",
            .geoModePhysical: "Físico — Cloudflare (localização real do servidor)",
            .compactWindow: "Janela compacta",
            .alignMenu: "Alinhamento",
            .alignLeft: "Esquerda",
            .alignRight: "Direita",
        ],
        "zh": [
            .detecting: "正在检测…",
            .noInternet: "无互联网连接",
            .refreshNow: "立即刷新",
            .copyIPv4: "复制 IPv4",
            .copyIPv6: "复制 IPv6",
            .floatingWindow: "窗口置顶显示",
            .launchAtLogin: "登录时启动",
            .about: "关于…",
            .quit: "退出",
            .hideWindow: "隐藏窗口",
            .language: "语言",
            .openProjectFolder: "打开项目文件夹",
            .loginItemError: "无法更改登录启动项",
            .aboutText: "显示外部 IP 地址和互联网出口（VPN）所在国家，让你随时了解自己从哪里访问互联网。",
            .geoModeMenu: "显示的国家",
            .geoModeVirtual: "虚拟 — MaxMind（网站所见）",
            .geoModePhysical: "物理 — Cloudflare（服务器实际位置）",
            .compactWindow: "紧凑窗口",
            .alignMenu: "对齐",
            .alignLeft: "左",
            .alignRight: "右",
        ],
        "ja": [
            .detecting: "検出中…",
            .noInternet: "インターネット接続なし",
            .refreshNow: "今すぐ更新",
            .copyIPv4: "IPv4 をコピー",
            .copyIPv6: "IPv6 をコピー",
            .floatingWindow: "ウィンドウを最前面に表示",
            .launchAtLogin: "ログイン時に起動",
            .about: "このアプリについて…",
            .quit: "終了",
            .hideWindow: "ウィンドウを隠す",
            .language: "言語",
            .openProjectFolder: "プロジェクトフォルダを開く",
            .loginItemError: "ログイン項目を変更できませんでした",
            .aboutText: "外部IPアドレスとインターネット出口（VPN）の国を表示し、どこからインターネットにアクセスしているかを常に確認できます。",
            .geoModeMenu: "表示する国",
            .geoModeVirtual: "仮想 — MaxMind（ウェブサイトから見た国）",
            .geoModePhysical: "物理 — Cloudflare（サーバーの実際の所在地）",
            .compactWindow: "コンパクト表示",
            .alignMenu: "配置",
            .alignLeft: "左",
            .alignRight: "右",
        ],
        "ko": [
            .detecting: "확인 중…",
            .noInternet: "인터넷 연결 없음",
            .refreshNow: "지금 새로고침",
            .copyIPv4: "IPv4 복사",
            .copyIPv6: "IPv6 복사",
            .floatingWindow: "창을 항상 위에 표시",
            .launchAtLogin: "로그인 시 시작",
            .about: "정보…",
            .quit: "종료",
            .hideWindow: "창 숨기기",
            .language: "언어",
            .openProjectFolder: "프로젝트 폴더 열기",
            .loginItemError: "로그인 항목을 변경할 수 없습니다",
            .aboutText: "외부 IP 주소와 인터넷 출구(VPN) 국가를 표시하여 어디에서 인터넷에 접속하는지 항상 확인할 수 있습니다.",
            .geoModeMenu: "표시 국가",
            .geoModeVirtual: "가상 — MaxMind (웹사이트에 보이는 국가)",
            .geoModePhysical: "실제 — Cloudflare (서버의 물리적 위치)",
            .compactWindow: "컴팩트 창",
            .alignMenu: "정렬",
            .alignLeft: "왼쪽",
            .alignRight: "오른쪽",
        ],
    ]
}

#if DEV_BUILD
// Dev-примечания для About: только в сборке с -dev, в публичный бинарник не попадают.
extension L10n {
    func devSuffix() -> String {
        lang == "ru"
            ? "Локальная dev-сборка этого компьютера.\nСобрано с помощью Claude Code.\n\nПапка проекта:\n{path}"
            : "Local dev build for this Mac.\nBuilt with Claude Code.\n\nProject folder:\n{path}"
    }
}
#endif
