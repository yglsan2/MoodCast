# MoodCast & WorldFlow (Flutter)

Version Flutter/Dart de MoodCast & WorldFlow — transcription fidèle de l’app React Native.

## Prérequis

- Flutter SDK (stable)
- Backend optionnel : même API que la version RN (`../moodcast-worldflow/backend`)

## Installation

```bash
cd moodcast_worldflow_flutter
# Générer les dossiers plateformes si besoin :
flutter create . --platforms=android,ios,web
flutter pub get
```

## Lancer l’app

```bash
flutter run
# Web :
flutter run -d chrome
```

## Configuration

- **API** : `lib/config/app_config.dart` — `apiBaseUrl` (ex. `http://192.168.1.x:3000` pour téléphone sur le même réseau).
- Le backend Node (moodcast-worldflow/backend) est inchangé et compatible.

## Contenu transcrit

- **MoodCast** : enregistrement audio, analyse d’humeur (API ou simulation), génération de podcast (5 styles), TTS pour écouter, sauvegarde locale, envoi WorldFlow.
- **WorldFlow** : carte (OpenStreetMap), régions avec émotion dominante, filtre jour/semaine/mois.
- **Journal** : liste des MoodCasts, détail du podcast, suppression.
- **Statistiques** : total, 7j/30j, émotion dominante, moyennes, répartition.
- **Plus** : Horoscope, Soutien, Urgence, Paramètres (écrans placeholder pour l’instant).
