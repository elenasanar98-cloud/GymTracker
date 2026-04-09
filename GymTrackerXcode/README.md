# GymTracker – Guía completa sin Mac

## Qué necesitas
- Cuenta en **GitHub** (gratis) → https://github.com
- Cuenta en **Codemagic** (gratis) → https://codemagic.io
- **AltStore** en tu iPhone → https://altstore.io

---

## PASO 1 – Subir el proyecto a GitHub

1. Ve a https://github.com y regístrate (si no tienes cuenta)
2. Pulsa el botón verde **"New"** para crear un repositorio
3. Ponle nombre: `GymTracker`
4. Déjalo en **Public**
5. Pulsa **"Create repository"**
6. En la página siguiente, busca la sección **"uploading an existing file"** y haz clic ahí
7. Arrastra **TODA la carpeta `GymTrackerXcode`** al área de carga
8. Pulsa **"Commit changes"**

---

## PASO 2 – Conectar Codemagic

1. Ve a https://codemagic.io y regístrate **con tu cuenta de GitHub**
2. Pulsa **"Add application"**
3. Selecciona tu repositorio `GymTracker`
4. Cuando pregunte el tipo de proyecto, elige **"Xcode project"**
5. Codemagic detectará el `codemagic.yaml` automáticamente
6. Pulsa **"Start your first build"**

⏱️ La compilación tarda ~10-15 minutos en un Mac virtual gratuito.

---

## PASO 3 – Descargar el IPA

1. Cuando el build termine (icono verde ✓), ve a la pestaña **"Artifacts"**
2. Descarga el archivo `GymTracker.ipa`
3. Guárdalo en tu PC Windows

---

## PASO 4 – Instalar en tu iPhone con AltStore

### 4a. Instalar AltStore en Windows:
1. Ve a https://altstore.io → descarga **AltInstaller para Windows**
2. Instala AltInstaller en tu PC
3. Conecta tu iPhone con cable USB
4. Abre iTunes (descárgalo si no lo tienes) y confía en el PC desde el iPhone
5. Abre AltInstaller → elige tu iPhone → pulsa **Install AltStore**
6. En tu iPhone, ve a **Ajustes → General → VPN y gestión de dispositivos** → confía en tu Apple ID

### 4b. Instalar GymTracker:
1. Abre **AltStore** en tu iPhone
2. Ve a la pestaña **"My Apps"** → pulsa **"+"**
3. Selecciona el archivo `GymTracker.ipa` que descargaste
4. ¡Listo! La app aparecerá en tu pantalla de inicio

> ⚠️ **Nota:** Con Apple ID gratuito la app caduca cada 7 días y hay que reinstalarla.  
> Con Apple Developer ($99/año) dura 1 año y puedes publicarla en el App Store.

---

## Alternativa más fácil: usar la app como Web App

Si el proceso anterior te parece complicado, puedo crear una versión web
de la misma app que funcione en tu iPhone desde Safari y se instale
en la pantalla de inicio. Avísame si prefieres esta opción.
