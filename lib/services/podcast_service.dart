import '../models/analysis_result.dart';
import '../models/emotions.dart';

/// Textes de podcast très précis par humeur et par style.
class PodcastService {
  PodcastService._();

  static PodcastResult fallbackPodcast(String emotion, String style) {
    final normalized = Emotions.normalize(emotion);
    final text = _podcasts[style]?[normalized] ??
        _podcasts[style]?['motivation'] ??
        "Votre humeur est unique. Prenez soin de vous aujourd'hui.";
    return PodcastResult(text: text, style: style);
  }

  static const Map<String, Map<String, String>> _podcasts = {
    'motivation': {
      'joie': "Votre joie est une force. Utilisez-la pour inspirer ceux qui vous entourent et pour avancer vers vos objectifs. Ce que vous rayonnez aujourd'hui peut changer la journée de quelqu'un d'autre.",
      'sérénité': "Votre calme intérieur est une ressource précieuse. Dans un monde agité, vous gardez l'équilibre. Continuez à ancrer vos décisions dans cette sérénité.",
      'enthousiasme': "Votre énergie est contagieuse. C'est le moment idéal pour lancer des projets ou entraîner les autres. Canalisez cet enthousiasme dans des actions concrètes.",
      'gratitude': "La gratitude que vous ressentez renforce votre bien-être. Exprimez-la autour de vous : un simple merci peut illuminer la journée de quelqu'un et la vôtre.",
      'stress': "Le stress que vous ressentez est un signal, pas une fatalité. Prenez une pause, respirez, et rappelez-vous : vous avez déjà surmonté des difficultés. Une étape à la fois.",
      'anxiété': "L'anxiété peut nous paralyser, mais vous avez le pouvoir d'agir malgré elle. Concentrez-vous sur la prochaine petite action réalisable. Vous êtes plus fort que vous ne le pensez.",
      'fatigue': "Votre corps vous envoie un message. Accordez-lui du repos sans culpabilité. Demain sera un nouveau jour ; vous serez plus efficace après avoir récupéré.",
      'motivation': "Votre motivation est là. Saisissez-la pour poser des actes concrets aujourd'hui. Même un petit pas compte et renforce votre élan.",
      'tristesse': "La tristesse fait partie de la vie. Permettez-vous de la ressentir sans vous juger. Des jours plus légers reviendront ; vous n'êtes pas seul.",
      'mélancolie': "La mélancolie peut être créative. Utilisez ce moment pour réfléchir, écrire ou créer. Cette sensibilité est une forme de richesse.",
      'colere': "Votre colère contient une information : quelque chose compte pour vous. Transformez-la en énergie pour défendre vos limites ou changer ce qui ne va pas.",
      'irritation': "Les petites irritations s'accumulent parfois. Identifiez la cause réelle, accordez-vous une pause, puis agissez sur ce que vous pouvez contrôler.",
      'doute': "Le doute peut nous protéger de l'impulsivité. Utilisez-le pour affiner vos choix, puis osez un premier pas. L'action réduit souvent le doute.",
      'espoir': "Votre espoir est une lumière. Nourrissez-le avec des actions qui vous rapprochent de ce que vous voulez. Les choses peuvent s'améliorer.",
      'amour': "L'amour que vous portez (à vous ou aux autres) est une force. Exprimez-le par des gestes concrets. Il renforce les liens et le bien-être.",
    },
    'humour': {
      'joie': "Vous êtes en forme ! On dirait que vous avez avalé un rayon de soleil. Gardez cette énergie, elle est précieuse (et un peu contagieuse).",
      'sérénité': "Zen mode activé. Même le chaos autour peut attendre : vous, vous restez calme. Les autres vont vous envier.",
      'enthousiasme': "Vous débordez d'énergie. Attention à ne pas faire trembler les murs en marchant. Utilisez cette puissance à bon escient !",
      'gratitude': "La vie vous envoie des petits cadeaux et vous les voyez. C'est déjà une super compétence. Continuez à compter les bonnes choses.",
      'stress': "Le stress, c'est le colocataire qu'on n'a pas invité. Vous pouvez lui montrer la porte : une respiration, une priorité, un pas après l'autre.",
      'anxiété': "Votre cerveau fait du scénario-catastrophe ? Rappelez-lui que la plupart du temps, ça se passe mieux que prévu. Et si ça ne va pas, vous gérerez.",
      'fatigue': "Votre corps réclame une trêve. Écoutez-le. Même les machines ont besoin de recharge. Vous reviendrez plus performant.",
      'motivation': "Vous êtes chaud comme une brioche à la sortie du four. C'est le moment de foncer. Allez-y !",
      'tristesse': "Les jours gris passent. Pensez à l'arc-en-ciel après la pluie. En attendant, un thé et une couverture, c'est déjà ça.",
      'mélancolie': "Mélancolie = sensibilité en mode poétique. Rien de grave. Un bon film ou un bon livre peuvent accompagner ça.",
      'colere': "La colère, c'est du carburant. Utilisez-la pour changer ce qui doit l'être, pas pour exploser. Vous êtes le patron de cette énergie.",
      'irritation': "Tout vous agace ? Normal après une mauvaise nuit ou une journée chargée. Isolez-vous cinq minutes, respirez, puis choisissez une seule chose à régler.",
      'doute': "Le doute, c'est le cerveau qui fait des sauvegardes. Écoutez-le un peu, puis prenez une décision. Parfois 'bien' suffit, pas besoin de 'parfait'.",
      'espoir': "Vous croyez que ça peut aller mieux. C'est déjà une force. Gardez cette flamme et ajoutez-y un petit geste concret.",
      'amour': "L'amour (de soi ou des autres) rend tout un peu plus doux. Exprimez-le ; le monde en a besoin (et vous aussi).",
    },
    'zen': {
      'joie': "Votre joie est comme une fleur qui s'épanouit. Respirez, savourez ce moment. Laissez cette douceur vous accompagner.",
      'sérénité': "Vous êtes ancré dans le calme. Les pensées peuvent passer comme des nuages ; vous restez présent et tranquille.",
      'enthousiasme': "Votre enthousiasme est une flamme. Nourrissez-la sans vous brûler. L'équilibre entre élan et paix intérieure est possible.",
      'gratitude': "La gratitude ouvre le cœur. En la ressentant, vous vous connectez à ce qui est déjà là, ici et maintenant.",
      'stress': "Le stress est une vague : il monte, puis redescend. Observez-le sans vous y noyer. Vous êtes plus grand que la vague.",
      'anxiété': "L'anxiété vit dans le futur imaginaire. Revenez à l'instant présent : vos pieds sur le sol, votre souffle. Ici, maintenant, vous allez bien.",
      'fatigue': "La fatigue est une invitation au repos. Accordez-vous le silence et la récupération. Vous méritez de vous recharger.",
      'motivation': "Votre motivation est une flamme intérieure. Chaque pas compte. Restez présent à ce que vous faites, sans vous disperser.",
      'tristesse': "La tristesse mérite d'être accueillie. Respirez avec elle, sans la repousser. Elle finira par s'alléger.",
      'mélancolie': "La mélancolie a sa beauté. C'est un moment d'introspection. Laissez les émotions circuler sans vous identifier à elles.",
      'colere': "La colère est une énergie. Observez-la, respirez, puis choisissez comment l'utiliser avec sagesse plutôt qu'en réaction.",
      'irritation': "L'irritation naît souvent de la tension accumulée. Une pause, un souffle long, et vous retrouvez de l'espace intérieur.",
      'doute': "Le doute fait partie du chemin. Vous n'avez pas besoin de certitude pour avancer ; un pas à la fois suffit.",
      'espoir': "L'espoir est une forme de présence au possible. Restez ouvert, sans forcer. Les choses peuvent évoluer.",
      'amour': "L'amour (pour vous ou pour d'autres) est une présence. Laissez-le être là, simple et bienveillant.",
    },
    'poesie': {
      'joie': "Dans le jardin de votre cœur, la joie fleurit. Chaque pétale est un instant de grâce. Laissez cette lumière vous envelopper.",
      'sérénité': "Le calme est une rivière en vous. Elle coule doucement. Laissez le monde s'agiter ; vous restez au bord de cette eau tranquille.",
      'enthousiasme': "Votre élan est une étoile qui brille. Suivez sa lumière sans vous perdre ; elle vous mène vers ce qui vous appelle.",
      'gratitude': "La gratitude est une mélodie. Elle transforme ce qui est ordinaire en cadeau. Écoutez-la résonner en vous.",
      'stress': "Le stress est un nuage qui passe. Le vent de la respiration le déplace. Le ciel en vous reste vaste.",
      'anxiété': "L'anxiété dessine des ombres. Mais vous n'êtes pas l'ombre ; vous êtes celui qui regarde. Revenez au souffle, à l'ici.",
      'fatigue': "La fatigue est une rivière lente. Laissez-vous porter. Le repos est une forme de sagesse.",
      'motivation': "Votre motivation est une étoile. Elle ne s'éteint pas ; elle attend que vous leviez les yeux. Marchez vers elle.",
      'tristesse': "La tristesse est une mélodie douce. Écoutez-la, honorez-la. Elle se transformera en chant d'espoir.",
      'mélancolie': "La mélancolie est une brume qui enveloppe. Elle peut devenir créativité, rêverie. Accueillez-la sans vous y perdre.",
      'colere': "La colère est un feu. Transformez ses flammes en lumière : celle qui éclaire ce qui doit changer.",
      'irritation': "Les petites épines du jour. Un souffle, un pas de côté, et vous retrouvez la douceur du chemin.",
      'doute': "Le doute est un passage, pas une prison. Vous pouvez avancer même sans voir tout le chemin.",
      'espoir': "L'espoir est une graine. Il grandit dans l'obscurité avant de voir le jour. Gardez-le vivant.",
      'amour': "L'amour est une rivière qui ne tarit pas. Elle coule en vous et vers les autres. Laissez-la faire.",
    },
    'energie': {
      'joie': "Votre joie, c'est du carburant positif. Utilisez-la pour bouger, partager, créer. Le monde a besoin de cette énergie !",
      'sérénité': "Votre calme n'est pas de la passivité. C'est une force. Vous restez stable alors que tout peut trembler.",
      'enthousiasme': "BOOM ! Votre enthousiasme est au max. C'est le moment de lancer des projets et d'entraîner les autres. Allez-y !",
      'gratitude': "La gratitude, c'est de la puissance. Elle attire le meilleur. Exprimez-la et regardez les choses s'aligner.",
      'stress': "Le stress ? Transformez-le en carburant. Vous êtes plus fort que vous ne le pensez. Une action à la fois.",
      'anxiété': "L'anxiété peut vous paralyser ou vous pousser à agir. Choisissez l'action : un petit pas réduit souvent l'angoisse.",
      'fatigue': "La fatigue, c'est un signal. Rechargez vos batteries, puis repartez. Vous avez encore tant à accomplir.",
      'motivation': "Rien ne peut vous arrêter quand la motivation est là. Saisissez ce moment et avancez.",
      'tristesse': "La tristesse peut être transformée en force. Relevez-vous, secouez-vous. Vous avez des ressources insoupçonnées.",
      'mélancolie': "Mélancolie aujourd'hui, énergie demain. Laissez passer la vague, puis reprenez le mouvement.",
      'colere': "Votre colère, c'est de la puissance. Utilisez-la pour changer ce qui ne va pas. Vous en êtes capable.",
      'irritation': "L'irritation, c'est de l'énergie non utilisée. Dépensez-la dans une action utile, puis respirez.",
      'doute': "Le doute ne doit pas vous figer. Agissez malgré lui. L'action donne des réponses.",
      'espoir': "L'espoir + action = changement. Vous croyez que ça peut aller mieux ; prouvez-le par un geste concret.",
      'amour': "L'amour donne des ailes. Utilisez cette énergie pour vous et pour les autres. Elle est inépuisable.",
    },
  };
}
