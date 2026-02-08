# Lancer l'app sur Linux (Arch)

## 1. Activer le support Linux desktop (une seule fois)

Flutter peut avoir le desktop Linux désactivé. Active-le avec :

```bash
flutter config --enable-linux-desktop
```

## 2. Vérifier les appareils

```bash
flutter devices
```

Tu dois voir une ligne du type : `Linux (desktop) • linux • linux-x64`.

## 3. Lancer l'app

```bash
cd ~/moodcast_worldflow_flutter
flutter run -d linux
```

Ou simplement :

```bash
flutter run
```

(une fois Linux activé, il sera choisi s’il est le seul appareil.)

---

## Dépendances de build (Arch Linux)

Pour compiler le runner Linux, il faut :

```bash
sudo pacman -S clang cmake ninja pkgconfig gtk3
```

(ou les paquets équivalents déjà installés sur ton système.)
