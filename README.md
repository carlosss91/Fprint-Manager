# Fprint-Manager

Gestor biométrico moderno para escritorio Linux y **elementary OS**, desarrollado en **Flutter** y conectado de forma universal mediante **D-Bus (`net.reactivated.Fprint`)** a `fprintd` y `libfprint`.

## Características principales

- **Compatibilidad universal**: Descubre automáticamente lectores ópticos, capacitivos, de deslizamiento (`swipe`) o `match-on-chip` expuestos por `fprintd`, soportando múltiples lectores y número dinámico de etapas de registro.
- **Animaciones fluidas (60/120 fps)**: Escáner dibujado con `CustomPainter` + `RepaintBoundary` (ondas radar, arco luminoso giratorio, haz de escaneo, anillo segmentado de etapas, rebote elástico al verificar y sacudida ante fallos), respetando `prefers-reduced-motion`.
- **Gestión completa de huellas**:
  - Registro guiado adaptado a sensores táctiles (`press`) y de deslizamiento (`swipe`).
  - Verificación automática (`-f any`) o dirigida a un dedo concreto (`-f <finger-code>`).
  - Apodos personalizados guardados conforme a `XDG_CONFIG_HOME` (`fprint-manager/finger_aliases.json`).
  - Historial de verificaciones de la sesión con marcas de tiempo tabulares.
- **Diagnóstico y mantenimiento del entorno**:
  - Verificación en vivo de `fprintd`, `libfprint`, dispositivos USB en `/sys/bus/usb/devices`, reglas Polkit e integración PAM (`pam_fprintd.so`).
  - Detección automática del modo **Flatpak Sandbox** vs **Linux nativo**.

## Requisitos del sistema

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

## Compilación para Linux Desktop (Release)

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

## Empaquetado Flatpak para elementary OS AppCenter

Los archivos de empaquetado incluidos son:
- `flatpak/io.github.carlosss91.fprintmanager.yml` (Manifiesto Flatpak sobre `io.elementary.Platform` / `io.elementary.Sdk` `8.2`)
- `data/io.github.carlosss91.fprintmanager.desktop`
- `data/io.github.carlosss91.fprintmanager.metainfo.xml`
- `data/icons/io.github.carlosss91.fprintmanager.svg`

### Validar metadatos y construir Flatpak en local

```bash
# 1. Validar .desktop y AppStream MetaInfo
desktop-file-validate data/io.github.carlosss91.fprintmanager.desktop
appstreamcli validate --no-net --pedantic data/io.github.carlosss91.fprintmanager.metainfo.xml

# 2. Instalar el SDK de elementary si aún no está instalado
flatpak install --system appcenter io.elementary.Sdk//8.2 io.elementary.Platform//8.2

# 3. Construir e instalar localmente desde el bundle release
flatpak-builder --user --install --force-clean build-flatpak flatpak/io.github.carlosss91.fprintmanager.yml

# 4. Probar dentro del sandbox Flatpak
flatpak run io.github.carlosss91.fprintmanager
```

> Nota para envío a AppCenter: añade la captura real de la ventana ejecutándose bajo elementary OS en `data/screenshots/main-window.png` antes de enviar el repositorio al proceso de revisión.

## Monetización y configuración personal (Flathub + PayPal + EthicalAds)

Toda la configuración comercial vive centralizada en [`lib/config/monetization_config.dart`](lib/config/monetization_config.dart):

1. **Donaciones voluntarias (`donationUrl`)**:
   - Configura tu enlace de **Ko-fi** (0 % comisión de plataforma en propinas, conectado directo a tu **PayPal**) o tu `https://paypal.me/...`.
   - También aparece como botón oficial **Donar** en Flathub gracias a `<url type="donation">` en el archivo AppStream.
2. **Banner publicitario automático (`ethicalAdsPublisherId`)**:
   - Solicita alta como editor en [EthicalAds](https://www.ethicalads.io/) y pega tu *publisher slug* en `ethicalAdsPublisherId`.
   - La app consulta la Decision API (`text-v1`), reporta la impresión (`view_url`) al renderizar el banner y abre los enlaces externos con `xdg-open`. Si no hay ID configurado o el usuario está sin red, se muestra un aviso propio discreto.
3. **Quitar anuncios por 1,99 € (`licenseProvider`, `removeAdsCheckoutUrl`, `gumroadProductId` / `polarOrganizationId`)**:
   - **Gumroad (predeterminado por soporte nativo de PayPal)**: actúa como *Merchant of Record* (gestiona IVA/impuestos internacionales), acepta pagos y retiros a **PayPal**, y genera claves automáticamente (`10 % + $0.50` por venta). Crea el producto y pega su `product_id` en `gumroadProductId`.
   - **Polar.sh (menor comisión MoR)**: cobra `5 % + $0.50` por venta y gestiona IVA global (cobros por banco/Stripe en la UE). Si prefieres Polar, cambia `licenseProvider` a `LicenseProvider.polar` y rellena `polarOrganizationId`.
   - *Nota sobre micropagos*: en compras de **0,99 €**, el componente fijo (`$0.50`) reduce mucho el margen neto (~35–45 % en comisiones); subir el precio a **1,99 €–2,99 €** mejora notablemente el beneficio por venta.

## Licencia

Distribuido bajo licencia **GPL-3.0-or-later** (ver archivo [`LICENSE`](LICENSE)).
