# IPMonit

**English** | [Русский](README.ru.md)

<img src="docs/icon.png" width="96" align="right" alt="IPMonit icon">

A tiny macOS menu bar utility that always shows **which country you access the internet from** — your external IP address and the country flag of your internet exit point (e.g. your VPN server).

Made for one simple purpose: a permanent, glanceable reminder of where your traffic exits, so you never forget your VPN is off (or on, or connected to the wrong country).

## What it looks like

| Normal | Compact | Country mismatch — possible VPN leak | No internet |
|:---:|:---:|:---:|:---:|
| <img src="docs/screenshot-normal.png" width="258" alt="Floating window: flag, country, IPv4 and IPv6"> | <img src="docs/screenshot-compact.png" width="168" alt="Compact window: badge and flag inline, IPv6 shortened"> | <img src="docs/screenshot-mismatch.png" width="258" alt="Floating window: IPv6 exits from a different country, highlighted orange"> | <img src="docs/screenshot-offline.png" width="192" alt="Floating window: no internet connection"> |

The indicator — a glowing strip pinned to the top of the screen, color-coding the current exit country (here: a country with a green rule matched; it stays dim gray when no rule matches):

<img src="docs/screenshot-indicator.png" width="640" alt="Indicator strip glowing green for a matched country rule">

The semi-transparent floating window over a desktop; the same info lives in the menu bar dropdown. IP addresses on the screenshots are fake documentation addresses (RFC 5737 / RFC 3849) — screenshots are rendered by `scripts/make-screenshots.sh`, real data never leaves the machine.

## Features

- **Menu bar flag** — the flag of your current exit country lives in the menu bar. The dropdown shows full IPv4/IPv6 details.
- **Optional floating window** — a small semi-transparent pill that stays on top of all windows, on every desktop, even over fullscreen apps. Drag it anywhere; the position is remembered. Double-click it to open the app menu (handy when the menu bar icon is hidden by a crowded menu bar). "Show window" and "Always on top" are separate menu toggles: with "Always on top" off, the window and the indicator order like regular windows and can be covered by others.
- **Compact mode** — an even smaller window: the flag and source badge go inline with the country name, and IPv6 is shortened to its first and last characters. Toggle it in the menu ("Compact window").
- **Hide IP addresses** — the smallest possible window: a single line `MM {flag} {country} v4+v6` (two lines when IPv4 and IPv6 exit from different countries). Combine with compact mode for the tiniest footprint.
- **Left or right alignment** — with right alignment the flag column moves to the right, text aligns right, and the window keeps its right edge fixed, growing leftward when the content size changes. Handy when the window sits near the right screen edge.
- **Indicator** — an optional wide glowing strip pinned to the top center of the screen: an at-a-glance color code of where you are. Assign one of six colors to countries in the indicator settings ("Configure indicator…"); when the current exit country (in the selected MM/CF mode) matches a rule, the strip glows that color, otherwise it stays dim gray. E.g. France and Andorra → yellow, Portugal and Spain → green, USA → blue. The strip is draggable; a menu action resets it back to the top center.
- **Near-realtime** — endpoints are polled every 3 seconds, and network changes (VPN on/off, Wi-Fi switch) trigger an immediate refresh via `NWPathMonitor`.
- **IPv4 and IPv6 checked independently** — via Cloudflare (`1.1.1.1` and `2606:4700:4700::1111`), so you see exactly what dual-stack services see. A protocol that isn't available is simply hidden.
- **Virtual vs physical country** — a menu option ("Shown country") switches between the country as registered in geo databases (MaxMind — what websites see) and the physical server location (Cloudflare's estimate). The active source is shown as a small badge (MM = MaxMind / CF = Cloudflare) above the flag in the floating window. See [Virtual VPN locations](#virtual-vpn-locations-registered-vs-physical-country) below.
- **VPN leak hint** — if the IPv4 and IPv6 countries don't match (a classic sign of one protocol leaking outside your VPN tunnel), the IPv6 block is shown separately with its own flag, highlighted orange, and the menu bar flag gets a ⚠️.
- **Offline indicator** — when the internet is unreachable, the app says so instead of showing stale data.
- **Launch at login** — toggle in the menu (uses the system `SMAppService`).
- **10 languages** — English (default), Русский, Español, Deutsch, Français, Italiano, Português, 中文, 日本語, 한국어. Switchable from the menu; country names are localized too.

## Virtual VPN locations: registered vs physical country

The "country" of an IP address is a database record, not a physical fact — and for VPN exit IPs the records often disagree with geography. Many VPN locations (especially exotic ones like Afghanistan or Belarus) are **virtual**: the server physically sits in a datacenter in France or the Netherlands, while the provider registers the IP range to the advertised country in geo databases like MaxMind. Hosting real hardware in such countries is slow, risky, or legally complicated — so providers fake the location on paper, and major ones even mark these servers as "virtual" in their apps.

Which country you "are in" then depends on who is looking:

- **Websites and "what is my IP" services** mostly use MaxMind-family databases → they see the registered (virtual) country. This is why virtual locations work for geo-unblocking.
- **Measurement-based databases** (like Cloudflare's, built on routing and latency data) → they see where the server physically is.

IPMonit shows both views and lets you pick in the menu ("Shown country"):

- **Virtual — MaxMind** (default): the country websites will think you are in.
- **Physical — Cloudflare**: the country where the exit server actually lives.

If the two disagree for your VPN location, your provider is using a virtual location: your traffic really flows through another country, with the corresponding latency and jurisdiction.

## What the IPv6 line tells you

With a VPN connected, the IPv6 line is a diagnostic in itself — there are three possible states:

1. **v6 shown, same country as v4** — the VPN tunnels both protocols. Ideal.
2. **v6 shown as a separate orange block with a different country** — IPv6 is leaking outside the VPN tunnel: IPv6-capable websites see your real address and country.  Fix it by disabling IPv6 on the system or enabling IPv6 leak protection in the VPN client.
3. **v6 hidden even though your network normally has IPv6** — the VPN client blocks IPv6 entirely instead of tunneling it (leak protection). Safe, though you lose IPv6 connectivity while connected.

An unavailable protocol is always hidden, so if your network has no IPv6 at all, the v6 line simply never appears.

## Privacy

The app makes HTTPS requests to Cloudflare's public trace endpoints (`https://1.1.1.1/cdn-cgi/trace` and the IPv6 equivalent) to learn the external IPs, and to `https://ipwho.is/<ip>` (with `https://api.country.is/<ip>` as a fallback) to geolocate them — cached per IP, so it is only called when the address actually changes. Nothing else: no accounts, no API keys, no analytics, no data stored or sent anywhere.

## Install (prebuilt)

1. Download [`dist/IPMonit.zip`](dist/IPMonit.zip) and unzip it.
2. Move `IPMonit.app` to `/Applications`.
3. First launch: the app is not notarized, so macOS will block a normal double-click. Either **right-click the app → Open → Open**, or remove the quarantine flag in Terminal:

   ```sh
   xattr -dr com.apple.quarantine /Applications/IPMonit.app
   ```

4. Look for the flag in your menu bar (if you don't see it, your menu bar may be full — Cmd-drag other icons to make room). The floating window can be toggled from the menu.

Requires macOS 13 Ventura or later.

## Build from source

Requirements: macOS 13+, Xcode Command Line Tools (`xcode-select --install`). No Xcode project needed — it's a plain Swift Package.

```sh
git clone <this repo>
cd ip-monit-2
./build-app.sh
ditto build/IPMonit.app /Applications/IPMonit.app
```

`build-app.sh` compiles a release binary with SwiftPM, wraps it into an `.app` bundle with the icon (regenerated by `scripts/make-icon.sh` if missing), and ad-hoc signs it.

Dev variant with extra info in the About dialog: `./build-app.sh -dev`.

To preview the "country mismatch" layout with fake data:

```sh
open /Applications/IPMonit.app --args --mock-mismatch
```

## How it works

- Two endpoints are queried in parallel: `https://1.1.1.1/cdn-cgi/trace` (the IP literal forces IPv4) and `https://[2606:4700:4700::1111]/cdn-cgi/trace` (forces IPv6). Each returns the caller's IP. The registered country for each IP is then resolved via `ipwho.is` (falling back to `api.country.is`), with a per-IP cache; Cloudflare's `loc=` field serves as the physical-location view and the last-resort fallback.
- The window is a borderless, non-activating `NSPanel` at floating level hosting a SwiftUI view — clicking it never steals focus from your current app.
- Country codes become flag emoji via Unicode regional indicators; country names come from the system `Locale` in the selected UI language.
