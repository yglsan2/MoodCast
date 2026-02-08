import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';

/// Mentions légales, exonération de responsabilité, RGPD, RGAA et droits des utilisateurs.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: '📜 Mentions légales & droits',
        gradient: AppColors.gradientSecondary,
      ),
      body: Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            _Section(
              title: 'Exonération de responsabilité',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _P(
                    'L\'application MoodCast & WorldFlow et son créateur (DesertYGL) ne peuvent en aucun cas être tenus pour responsables, '
                    'ni l\'un ni l\'autre, de quelque dommage, préjudice, perte ou conséquence que ce soit '
                    '(direct ou indirect, matériel, moral, physique ou psychologique) résultant de l\'utilisation '
                    'ou de l\'impossibilité d\'utiliser l\'application, y compris mais sans s\'y limiter : '
                    'décisions prises sur la base des contenus affichés (horoscope, humeur, statistiques, etc.), '
                    'défaillance ou retard des fonctionnalités d\'alerte (MoodSafe, alerte proche), '
                    'absence de géolocalisation ou de transmission de données, ou toute autre utilisation du service.',
                  ),
                  _P(
                    'L\'utilisation de l\'application est entièrement sous votre responsabilité. '
                    'Le créateur décline toute responsabilité à l\'égard des tiers et des utilisateurs.',
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Nature de l\'application',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _P(
                    'MoodCast & WorldFlow est une application à vocation à la fois ludique et de bien-être, '
                    'qui propose notamment des outils pouvant renforcer votre sentiment de sécurité au quotidien '
                    '(par exemple : alerte à un proche, message d\'alerte avec position, fonctionnalités MoodSafe). '
                    'Ces dispositifs sont conçus comme un complément pratique et ne constituent en aucun cas '
                    'une garantie de sécurité ni un service de secours ou d\'assistance professionnelle.',
                  ),
                  _P(
                    'En aucun cas cette application ne peut se substituer à une personne qualifiée pour assurer '
                    'votre sécurité : autorités compétentes (police, gendarmerie, pompiers, SAMU), professionnels '
                    'de santé, associations d\'aide aux victimes ou tout organisme habilité. '
                    'En situation de danger ou d\'urgence, contactez sans délai les services d\'urgence adaptés '
                    '(ex. 17, 18, 15, 112) et, le cas échéant, des personnes de confiance ou des professionnels.',
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Protection des données (RGPD)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _P(
                    'Les données que vous saisissez ou que l\'application enregistre (MoodCasts, humeurs, date de naissance, '
                    'contacts d\'alerte, préférences, etc.) sont, par défaut, stockées localement sur votre appareil. '
                    'Aucune donnée personnelle n\'est envoyée à un serveur sans votre action explicite (ex. partage WorldFlow, '
                    'envoi de SMS) ou sans configuration optionnelle (backend d\'analyse de voix si vous y avez accès).',
                  ),
                  _P(
                    'Finalités : fourniture des fonctionnalités (journal, stats, horoscope, alertes, rituels, etc.), '
                    'amélioration de votre expérience et, le cas échéant, services optionnels auxquels vous souscrivez.',
                  ),
                  _P(
                    'Vous disposez des droits prévus par le Règlement général sur la protection des données (RGPD) : '
                    'droit d\'accès, de rectification, d\'effacement, à la portabilité, d\'opposition et de limitation du traitement. '
                    'Pour les exercer ou pour toute question relative à vos données, contactez le responsable du traitement '
                    '(DesertYGL) via les coordonnées indiquées dans l\'application ou sur son site.',
                  ),
                  _P(
                    'Les données stockées localement restent sur votre appareil ; leur suppression définitive peut être obtenue '
                    'en désinstallant l\'application ou en effaçant les données de l\'app. Aucun transfert de données '
                    'personnelles hors Union européenne n\'est effectué par défaut.',
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Accessibilité (RGAA)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _P(
                    'DesertYGL (créateur de MoodCast & WorldFlow) s\'engage à améliorer l\'accessibilité de l\'application '
                    'pour les personnes en situation de handicap, dans le cadre d\'une conformité progressive au référentiel '
                    'RGAA (Référentiel général d\'amélioration de l\'accessibilité) et aux bonnes pratiques en vigueur.',
                  ),
                  _P(
                    'Si vous rencontrez un problème d\'accessibilité ou souhaitez signaler un défaut, vous pouvez '
                    'contacter DesertYGL via les moyens indiqués (contact, formulaire ou adresse fournie).',
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Éditeur et modèle d\'utilisation',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _P(
                    'L\'application MoodCast & WorldFlow est créée et éditée par DesertYGL.',
                  ),
                  _P(
                    'L\'application est proposée gratuitement, avec affichage de publicités. Une option payante peut permettre '
                    'notamment de désactiver les publicités ou d\'accéder à des fonctionnalités supplémentaires. '
                    'Les droits sur l\'œuvre (code, design, contenus) sont réservés à DesertYGL, sauf mention contraire (licences tierces). '
                    'Les conditions de licence et d\'utilisation sont susceptibles d\'évoluer ; consultez les mises à jour dans l\'application.',
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Propriété intellectuelle',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _P(
                    'L\'application, son code, son design, ses textes et contenus (à l\'exception des contenus fournis '
                    'par l\'utilisateur ou par des tiers sous licence) sont protégés par le droit d\'auteur et appartiennent '
                    'à DesertYGL. Toute reproduction, représentation ou exploitation non autorisée peut constituer '
                    'une contrefaçon.',
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Droit applicable et litiges',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _P(
                    'Les présentes mentions et les conditions d\'utilisation de l\'application sont régies par le droit français. '
                    'En cas de litige, les tribunaux français seront compétents, sous réserve des dispositions impératives '
                    'applicables à l\'utilisateur consommateur.',
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Modifications',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _P(
                    'DesertYGL se réserve le droit de modifier les présentes mentions légales, les conditions d\'utilisation '
                    'et les fonctionnalités de l\'application. Les utilisateurs sont invités à les consulter régulièrement. '
                    'L\'utilisation continue de l\'application après modification vaut acceptation des nouvelles dispositions.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FeelGoodCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _P extends StatelessWidget {
  const _P(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.55,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
