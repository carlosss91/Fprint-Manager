# Fprint-Manager

[English](#english) | [Español](#español)

---

## English

Modern biometric fingerprint manager for Linux desktop and **elementary OS**, built with **Flutter** and connected universally via **D-Bus (`net.reactivated.Fprint`)** to `fprintd` and `libfprint`.

### Key Features

- **Universal hardware compatibility**: Automatically discovers optical, capacitive, swipe, and match-on-chip readers exposed by `fprintd`, supporting multiple readers and dynamic enrollment stage counts.
- **Smooth animations (60/120 fps)**: Custom-drawn `CustomPainter` + `RepaintBoundary` scanner (radar ripples, rotating sweep arc, scan beam, segmented enrollment ring, match bounce, and error shake), respecting `prefers-reduced-motion`.
- **Full fingerprint management**:
  - Guided enrollment adapted to touch (`press`) and swipe (`swipe`) sensors.
  - Automatic verification (`-f any`) or targeted finger verification (`-f <finger-code>`), displaying the detected fingerprint name when reported by `fprintd`.
  - Custom local aliases stored following `XDG_CONFIG_HOME` (`fprint-manager/finger_aliases.json`).
  - Session verification audit log with tabular timestamps.
- **System diagnostics & maintenance**:
  - Live checks for `fprintd`, `libfprint`, USB devices in `/sys/bus/usb/devices`, Polkit rules, and PAM integration (`pam_fprintd.so`).
  - Automatic detection of **Flatpak Sandbox** vs **native Linux** mode.

### System Requirements

The application requires the system `fprintd` daemon and `libfprint` drivers:

- **elementary OS / Ubuntu / Debian**:
  ```bash
  sudo apt install fprintd libpam-fprintd libfprint-2-2
  ```
- **Fedora / RHEL**:
  ```bash
  sudo dnf install fprintd fprintd-pam
  ```
- **Arch Linux**:
  ```bash
  sudo pacman -S fprintd
  ```

### Building for Linux Desktop (Release)

```bash
flutter pub get
flutter analyze
flutter test
flutter build linux --release
```

The self-contained bundle is generated in `build/linux/x64/release/bundle/`:

```text
build/linux/x64/release/bundle/
├── fprint_manager              # Main ELF executable
├── lib/
│   ├── libapp.so               # AOT-compiled Dart code
│   └── libflutter_linux_gtk.so # Flutter Linux GTK engine
└── data/
    ├── icudtl.dat              # ICU/Unicode data
    └── flutter_assets/         # Bundled assets, fonts, and icons
```

Run it directly:

```bash
./build/linux/x64/release/bundle/fprint_manager
```

### Flatpak Packaging (Flathub)

Included packaging files:
- `flatpak/io.github.carlosss91.fprintmanager.yml` (Source-build Flatpak manifest on `org.freedesktop.Platform` `25.08` + `org.freedesktop.Sdk.Extension.llvm20`)
- `flatpak/pubspec-sources.json` (Offline `pub.dev` dependencies from `pubspec.lock`)
- `flatpak/io.github.carlosss91.fprintmanager.local.yml` (Fast local-bundle manifest for testing)
- `data/io.github.carlosss91.fprintmanager.desktop`
- `data/io.github.carlosss91.fprintmanager.metainfo.xml`
- `data/icons/io.github.carlosss91.fprintmanager.svg`

#### Validate metadata & build Flatpak locally

```bash
# 1. Validate .desktop and AppStream MetaInfo
desktop-file-validate data/io.github.carlosss91.fprintmanager.desktop
appstreamcli validate --no-net --pedantic data/io.github.carlosss91.fprintmanager.metainfo.xml

# 2. Build and install locally from the release bundle
flatpak-builder --user --install --force-clean build-flatpak flatpak/io.github.carlosss91.fprintmanager.local.yml

# 3. Run inside the Flatpak sandbox
flatpak run io.github.carlosss91.fprintmanager
```

### Support & Monetization Configuration

Commercial settings are centralized in [`lib/config/monetization_config.dart`](lib/config/monetization_config.dart):

1. **Voluntary donations (`donationUrl`)**: Configured for `https://paypal.me/chals911` (also listed as `<url type="donation">` in AppStream metadata).
2. **Optional sponsor banner (`ethicalAdsPublisherId`)**: Supports EthicalAds Decision API (`text-v1`) with an unobtrusive built-in supporter fallback when unconfigured or offline.
3. **Remove ads for 1,99 € (`licenseProvider`, `removeAdsCheckoutUrl`, `gumroadProductId`)**: Uses Gumroad license verification (`https://chals91.gumroad.com/l/Fprint-Manager`).

### License

Distributed under **GPL-3.0-or-later** (see [`LICENSE`](LICENSE)).

---

## Español

Gestor biométrico moderno para escritorio Linux y **elementary OS**, desarrollado en **Flutter** y conectado de forma universal mediante **D-Bus (`net.reactivated.Fprint`)** a `fprintd` y `libfprint`.

### Características principales

- **Compatibilidad universal**: Descubre automáticamente lectores ópticos, capacitivos, de deslizamiento (`swipe`) o `match-on-chip` expuestos por `fprintd`, soportando múltiples lectores y número dinámico de etapas de registro.
- **Animaciones fluidas (60/120 fps)**: Escáner dibujado con `CustomPainter` + `RepaintBoundary` (ondas radar, arco luminoso giratorio, haz de escaneo, anillo segmentado de etapas, rebote elástico al verificar y sacudida ante fallos), respetando `prefers-reduced-motion`.
- **Gestión completa de huellas**:
  - Registro guiado adaptado a sensores táctiles (`press`) y de deslizamiento (`swipe`).
  - Verificación automática (`-f any`) o dirigida a un dedo concreto (`-f <finger-code>`), mostrando el nombre de la huella detectada cuando `fprintd` lo informa.
  - Apodos personalizados guardados conforme a `XDG_CONFIG_HOME` (`fprint-manager/finger_aliases.json`).
  - Historial de verificaciones de la sesión con marcas de tiempo tabulares.
- **Diagnóstico y mantenimiento del entorno**:
  - Verificación en vivo de `fprintd`, `libfprint`, dispositivos USB en `/sys/bus/usb/devices`, reglas Polkit e integración PAM (`pam_fprintd.so`).
  - Detección automática del modo **Flatpak Sandbox** vs **Linux nativo**.

### Requisitos del sistema

La aplicación requiere el servicio del sistema `fprintd` y los drivers `libfprint`:

- **elementary OS / Ubuntu / Debian**:
  ```bash
  sudo apt install fprintd libpam-fprintd libfprint-2-2
  ```
- **Fedora / RHEL**:
  ```bash
  sudo dnf install fprintd fprintd-pam
  ```
- **Arch Linux**:
  ```bash
  sudo pacman -S fprintd
  ```

### Compilación para Linux Desktop (Release)

```bash
flutter pub get
flutter analyze
flutter test
flutter build linux --release
```

El ejecutable autocontenido se genera en `build/linux/x64/release/bundle/`:

```text
build/linux/x64/release/bundle/
├── fprint_manager              # Ejecutable ELF principal
├── lib/
│   ├── libapp.so               # Código Dart compilado AOT
│   └── libflutter_linux_gtk.so # Motor Flutter para Linux GTK
└── data/
    ├── icudtl.dat              # Datos Unicode/ICU
    └── flutter_assets/         # Recursos, fuentes e iconos empaquetados
```

Para ejecutarlo directamente:

```bash
./build/linux/x64/release/bundle/fprint_manager
```

### Empaquetado Flatpak (Flathub)

Los archivos de empaquetado incluidos son:
- `flatpak/io.github.carlosss91.fprintmanager.yml` (Manifiesto Flatpak desde fuentes sobre `org.freedesktop.Platform` `25.08` + `org.freedesktop.Sdk.Extension.llvm20`)
- `flatpak/pubspec-sources.json` (Dependencias `pub.dev` offline extraídas de `pubspec.lock`)
- `flatpak/io.github.carlosss91.fprintmanager.local.yml` (Manifiesto rápido para pruebas locales con el bundle)
- `data/io.github.carlosss91.fprintmanager.desktop`
- `data/io.github.carlosss91.fprintmanager.metainfo.xml`
- `data/icons/io.github.carlosss91.fprintmanager.svg`

#### Validar metadatos y construir Flatpak en local

```bash
# 1. Validar .desktop y AppStream MetaInfo
desktop-file-validate data/io.github.carlosss91.fprintmanager.desktop
appstreamcli validate --no-net --pedantic data/io.github.carlosss91.fprintmanager.metainfo.xml

# 2. Construir e instalar localmente desde el bundle release
flatpak-builder --user --install --force-clean build-flatpak flatpak/io.github.carlosss91.fprintmanager.local.yml

# 3. Probar dentro del sandbox Flatpak
flatpak run io.github.carlosss91.fprintmanager
```

### Monetización y configuración personal

Toda la configuración comercial vive centralizada en [`lib/config/monetization_config.dart`](lib/config/monetization_config.dart):

1. **Donaciones voluntarias (`donationUrl`)**: Configurado para `https://paypal.me/chals911` (también aparece como `<url type="donation">` en AppStream).
2. **Banner publicitario opcional (`ethicalAdsPublisherId`)**: Consulta la Decision API (`text-v1`) de EthicalAds y muestra un aviso propio discreto cuando no hay ID configurado o el usuario está sin red.
3. **Quitar anuncios por 1,99 € (`licenseProvider`, `removeAdsCheckoutUrl`, `gumroadProductId`)**: Validación de licencias con Gumroad (`https://chals91.gumroad.com/l/Fprint-Manager`).

### Licencia

Distribuido bajo licencia **GPL-3.0-or-later** (ver archivo [`LICENSE`](LICENSE)).
