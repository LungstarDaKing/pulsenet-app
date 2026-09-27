<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0B0B10,50:9F1239,100:E11D48&height=200&section=header&text=PulseNet&fontSize=70&fontColor=FFFFFF&animation=fadeIn&fontAlignY=38&desc=Personal%20safety%2C%20built%20for%20South%20Africa&descAlignY=58&descSize=18" width="100%"/>

<img src="assets/images/pulsenet_logo.png" width="96" alt="PulseNet logo"/>

<br/>

[![Typing animation](https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=20&duration=2600&pause=900&color=E11D48&center=true&vCenter=true&width=560&lines=Tap+once.+Alert+everyone.;Silent+SOS+for+real+emergencies.;Built+with+Flutter+%2B+love+%2B+paranoia.;Local-first.+Screenshot-blocked.+Yours.)](https://git.io/typing-svg)

<br/>

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-Add%20one-lightgrey?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active%20Development-F59E0B?style=for-the-badge)

<img src="https://user-images.githubusercontent.com/74038190/212284100-561aa473-3905-4a80-b561-0d28506553ee.gif" width="500">

</div>

<br/>

> ⚠️ **A couple of the badges/lines above are placeholders, not claims.** The License badge says "Add one" because this repo doesn't currently have a `LICENSE` file even though earlier docs mentioned MIT — pick a real license and swap that badge out. The screenshots below are marked `TODO` for the same reason: I haven't generated real ones, and a README with fake screenshots is worse than one with none.

---

## 📖 Table of contents

- [What is PulseNet](#-what-is-pulsenet)
- [Screenshots](#-screenshots)
- [Feature status](#-feature-status)
- [Safety principles](#-safety-principles)
- [Tech stack](#-tech-stack)
- [Project structure](#-project-structure)
- [Getting started](#-getting-started)
- [Permissions](#-permissions)
- [Localization](#-localization)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [Disclaimer](#-disclaimer)
- [License](#-license)

---

## 🚨 What is PulseNet

**PulseNet** is a Flutter personal-safety app built around South African emergency infrastructure — real numbers (10111, 10177, the GBV Command Centre), real SMS dispatch, and a safety-state machine (green / yellow / red, with a stealth mode) instead of a single panic button bolted onto a to-do app.

The core loop: tap the SOS button, a 5-second cancellable countdown runs, then a **real SMS** — not a push notification, not a toast that lies to you — goes out to your trusted contacts with your live location. Hold the button instead of tapping, and the same thing happens silently.

<div align="center">
<img src="https://user-images.githubusercontent.com/74038190/213844263-a8897a51-32f4-4b3b-b5c2-e1528b89f6f3.gif" width="100%">
</div>

---

## 📸 Screenshots

<!--
TODO: replace every cell below with a real screenshot or short screen-recording GIF
from a running build. Suggested path: docs/screenshots/<name>.png
-->

<div align="center">

| Dashboard | SOS countdown | Walk with me |
|:---:|:---:|:---:|
| `TODO: docs/screenshots/dashboard.png` | `TODO: docs/screenshots/sos.png` | `TODO: docs/screenshots/walk_with_me.png` |

| Safe places | Wearable | Danger snapshot |
|:---:|:---:|:---:|
| `TODO: docs/screenshots/safe_places.png` | `TODO: docs/screenshots/wearable.png` | `TODO: docs/screenshots/danger_snapshot.png` |

</div>

> Tip: record a 5–10s screen capture of the SOS countdown and convert it to a GIF (e.g. with `ffmpeg` or ScreenToGif) — an animated SOS flow sells this app far better than a static shot ever will.

---

## ✅ Feature status

Shipped means it's in `lib/` and wired into the app you'd actually install. Parked means the code exists in the repo but isn't compiled in — don't advertise these as working.

### Shipped

| Feature | What it actually does |
|---|---|
| 🆘 SOS + silent SOS | 5s cancellable countdown → real SMS with live location to trusted contacts |
| 🚦 Safety states | Green (normal) / Yellow (check-in) / Red (emergency), with a stealth mode |
| 🔑 Duress PIN | Looks like a normal unlock, silently triggers an alert |
| 🚶 Walk With Me | Timed companion mode; misses check-in → 60s grace → auto-SOS |
| 📍 Safe Places | Geofenced zones (home, work, etc.) with entry/exit awareness |
| 📞 Fake Call | Scheduled or instant fake call to exit a bad situation |
| 🩹 First Aid | Step-by-step offline emergency guidance |
| 👥 Trusted Contacts | Who receives alerts, managed on-device |
| 🎛️ Safety Profiles | Context presets — work, night out, travel |
| 🔒 App Lock | PIN/biometric lock, auto-relocks on background (never locks you out mid-emergency) |
| ⌚ Wearable heart rate | *(new)* Connects to any BLE Heart Rate Service device, live HR + battery |
| 📷 Danger Snapshot | *(new)* Native camera capture → instant SMS alert → share sheet to send the photo on |
| 🌍 Localization | Emergency phrases and first aid in English, Afrikaans, isiXhosa, isiZulu |
| 🕶️ Screenshot blocking | `FLAG_SECURE` on by default — your screen isn't in anyone's screenshot |

### Parked (in the repo, not compiled into the app)

| Feature | Why it's parked |
|---|---|
| 🚨 Danger Around Me | No verified crime/hazard data source wired in — currently a shell |
| 🚕 Taxi/ride safety | Not re-ported since the `parked/` split |
| 🏅 Safe Points (gamification) | Not re-ported; arguably doesn't belong in a crisis-first app anyway |
| 🫀 Camera-based pulse (finger on lens) | Works as a concept, not re-integrated |
| 🎙️ Distress-word listener, check-on-contact, journey share | Not re-ported since the `parked/` split |

There is **no CCTV/security-camera integration** in this app, shipped or parked — the closest thing historically was the finger-over-camera pulse reader above, which is unrelated to security cameras.

---

## 🧭 Safety principles

This project holds itself to explicit rules, not vibes:

1. **Correctness over speed** — accurate safety info beats a fast, wrong alert
2. **Privacy over data collection** — minimal data, local-first storage, explicit consent
3. **Fail-safe behavior** — default to the safe state under uncertainty
4. **Explicit consent** — all tracking/monitoring requires the user to opt in
5. **Verified information** — alerts come from verified sources where possible
6. **Security over shortcuts** — never trade security for convenience
7. **Transparency** — the app tells you plainly what it does and why

---

## 🛠️ Tech stack

![Provider](https://img.shields.io/badge/State-Provider-4285F4?style=flat-square)
![SharedPreferences](https://img.shields.io/badge/Storage-SharedPreferences%20%2B%20Secure%20Storage-6C6C6C?style=flat-square)
![Geolocator](https://img.shields.io/badge/Location-Geolocator-34A853?style=flat-square)
![Google Maps](https://img.shields.io/badge/Maps-Google%20Maps%20Flutter-4285F4?style=flat-square)
![flutter_blue_plus](https://img.shields.io/badge/Bluetooth-flutter__blue__plus-0082FC?style=flat-square)
![Speech to Text](https://img.shields.io/badge/Voice-speech__to__text-9C27B0?style=flat-square)

- **State management:** Provider — a small composition root in `main.dart`, no widget-tree magic
- **Storage:** `SharedPreferences` for settings, `flutter_secure_storage` for contacts/medical/PIN data
- **Emergency dispatch:** a native Android `MethodChannel` (`MainActivity.kt`) sending real SMS via `SmsManager` — not a plugin, not a mock
- **Bluetooth:** `flutter_blue_plus` talking to the standard BLE Heart Rate (0x180D) and Battery (0x180F) GATT services
- **Camera:** `image_picker` launches the native camera for the danger-snapshot flow; sharing goes through `share_plus`

---

## 🗂️ Project structure

```text
lib/
├── main.dart                     # composition root — providers, app lock, duress PIN wiring
├── safety_state.dart             # green/yellow/red state machine
├── theme.dart                    # dark theme, color tokens
├── data/
│   └── sa_helplines.dart
├── services/
│   ├── sos_service.dart          # SMS dispatch, follow-ups, all-clear
│   ├── native_bridge.dart        # Android MethodChannel: SMS, call, FLAG_SECURE
│   ├── storage_service.dart      # prefs + secure storage
│   ├── audit_log_service.dart    # tamper-evident local audit trail
│   ├── bluetooth_wearable_service.dart   # heart rate + battery over BLE
│   ├── danger_snapshot_service.dart      # capture, geotag, alert, share
│   └── ...
└── screens/
    ├── dashboard_screen.dart
    ├── sos_confirmation_screen.dart
    ├── walk_with_me_screen.dart
    ├── safe_places_screen.dart
    ├── wearable_screen.dart
    ├── danger_snapshot_screen.dart
    └── ...

parked/                           # not compiled — see Feature status above
```

---

## 🚀 Getting started

### Prerequisites

- Flutter SDK 3.0.0+
- Dart SDK (bundled with Flutter)
- Android Studio (device/emulator + SDK tooling)
- A Google Maps API key (Safe Places uses `google_maps_flutter`)

### Install

```bash
git clone https://github.com/YOUR_USERNAME/pulsenet.git
cd pulsenet
flutter pub get
```

Add your Maps key to `android/local.properties`:

```properties
MAPS_API_KEY=your_key_here
```

Run it:

```bash
flutter run
```

<div align="center">
<img src="https://user-images.githubusercontent.com/74038190/212257454-16e3712e-945a-4ca2-b238-408ad0bf87e6.gif" width="60">
</div>

---

## 🔐 Permissions

| Permission | Used for |
|---|---|
| `SEND_SMS`, `CALL_PHONE` | SOS dispatch and one-tap emergency calling |
| `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | Location in alerts, Safe Places, BLE scan on Android < 12 |
| `RECORD_AUDIO` | Distress-word listener (parked) |
| `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` | Wearable heart-rate pairing |
| `CAMERA` | Danger snapshot capture |
| `POST_NOTIFICATIONS`, `VIBRATE` | Local alerts and haptic feedback |

Every permission is requested at the point of use, never in bulk on first launch.

---

## 🌍 Localization

Emergency phrases and first-aid guidance ship in:

🇿🇦 English · Afrikaans · isiXhosa · isiZulu

(`assets/data/distress_phrases/`, `assets/data/first_aid/`)

---

## 🧩 Roadmap

- [ ] Pick and add a real `LICENSE` file
- [ ] Re-port Danger Around Me against a verified crime/hazard data source
- [ ] Decide whether abnormal wearable heart rate should trigger a check-in prompt
- [ ] Look into a published police tip-line (SAPS or provincial) to target from the danger-snapshot share sheet
- [ ] Real screenshots/GIFs in `docs/screenshots/`
- [ ] iOS build validation (native bridge is currently Android-only)

---

## 🤝 Contributing

Contributions are welcome if they hold the line on the safety principles above:

1. New features must have a clear safety rationale, not just a cool factor
2. Privacy implications get called out in the PR description
3. Anything touching SOS dispatch, location, or the safety-state machine needs a plain-English explanation of the failure modes
4. Test on a real device where possible — emulator SMS/Bluetooth behavior lies to you

---

## ⚠️ Disclaimer

PulseNet is designed to assist with personal safety. It is **not** a replacement for calling emergency services directly, and it should not be treated as the sole layer of protection in a dangerous situation.

---

## 📄 License

_No `LICENSE` file exists in this repo yet — add one (MIT is a reasonable default for an open-source safety tool) before calling this "open source."_

<br/>

<div align="center">
<img src="https://capsule-render.vercel.app/api?type=waving&color=0:E11D48,50:9F1239,100:0B0B10&height=120&section=footer" width="100%"/>
</div>
