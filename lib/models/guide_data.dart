import 'package:flutter/material.dart';

class GuideOption {
  final String text;
  final String? nextStepId;
  final String? summaryId;

  GuideOption({
    required this.text,
    this.nextStepId,
    this.summaryId,
  });
}

class GuideStep {
  final String id;
  final String title;
  final String question;
  final IconData icon;
  final List<GuideOption> options;

  GuideStep({
    required this.id,
    required this.title,
    required this.question,
    required this.icon,
    required this.options,
  });
}

class GuideSummary {
  final String id;
  final String title;
  final String text;
  final IconData icon;

  GuideSummary({
    required this.id,
    required this.title,
    required this.text,
    required this.icon,
  });
}

// Dati delle guide - tradotti dal file guideData.ts originale
class GuideData {
  static final Map<String, GuideStep> guideTree = {
    'start': GuideStep(
      id: 'start',
      title: 'Cosa fare se...',
      question: 'Seleziona una situazione per iniziare.',
      icon: Icons.help_outline,
      options: [
        GuideOption(
          text: 'Trovo un animale ferito',
          nextStepId: 'ferito_condizione',
        ),
        GuideOption(
          text: 'Trovo un nido di uccelli caduto',
          nextStepId: 'nido_condizione',
        ),
        GuideOption(
          text: 'Vedo un animale selvatico in città',
          nextStepId: 'selvatico_condizione',
        ),
      ],
    ),
    
    // Percorso "Animale Ferito"
    'ferito_condizione': GuideStep(
      id: 'ferito_condizione',
      title: 'Animale Ferito',
      question: 'Qual è la condizione apparente dell\'animale?',
      icon: Icons.medical_services_outlined,
      options: [
        GuideOption(
          text: 'È sanguinante o con fratture evidenti.',
          nextStepId: 'ferito_grave_azione',
        ),
        GuideOption(
          text: 'È immobile ma non sembra ferito gravemente.',
          nextStepId: 'ferito_immobile_azione',
        ),
        GuideOption(
          text: 'È un animale domestico (cane/gatto) chiaramente smarrito.',
          summaryId: 'summary_randagio',
        ),
      ],
    ),
    
    'ferito_grave_azione': GuideStep(
      id: 'ferito_grave_azione',
      title: 'Ferita Grave',
      question: 'L\'animale necessita di soccorso immediato. Qual è la tua priorità?',
      icon: Icons.monitor_heart_outlined,
      options: [
        GuideOption(
          text: 'Avvicinarmi con estrema cautela per coprirlo.',
          summaryId: 'summary_soccorso_urgente',
        ),
        GuideOption(
          text: 'Contattare immediatamente il 112 (Carabinieri/Polizia).',
          summaryId: 'summary_soccorso_urgente',
        ),
        GuideOption(
          text: 'Cercare di spostarlo.',
          summaryId: 'summary_non_spostare',
        ),
      ],
    ),
    
    'ferito_immobile_azione': GuideStep(
      id: 'ferito_immobile_azione',
      title: 'Animale Immobile',
      question: 'L\'animale potrebbe essere in stato di shock. Cosa fai?',
      icon: Icons.airline_seat_recline_extra,
      options: [
        GuideOption(
          text: 'Contattare l\'ASL Veterinaria o Polizia Locale.',
          summaryId: 'summary_contatto_asl',
        ),
        GuideOption(
          text: 'Provare a dargli acqua o cibo.',
          summaryId: 'summary_non_alimentare',
        ),
        GuideOption(
          text: 'Aspettare che si riprenda da solo.',
          summaryId: 'summary_contatto_asl',
        ),
      ],
    ),
    
    // Percorso "Nido Caduto"
    'nido_condizione': GuideStep(
      id: 'nido_condizione',
      title: 'Nido Caduto',
      question: 'In che condizioni sono i piccoli uccelli?',
      icon: Icons.eco_outlined,
      options: [
        GuideOption(
          text: 'Sono implumi (senza penne).',
          summaryId: 'summary_nido_implumi',
        ),
        GuideOption(
          text: 'Hanno già le penne e saltellano.',
          summaryId: 'summary_nido_pennuti',
        ),
        GuideOption(
          text: 'Sono chiaramente feriti.',
          summaryId: 'summary_crass',
        ),
      ],
    ),
    
    // Percorso "Selvatico in Città"
    'selvatico_condizione': GuideStep(
      id: 'selvatico_condizione',
      title: 'Selvatico in Città',
      question: 'L\'animale selvatico (es. volpe, cinghiale) sembra...',
      icon: Icons.forest_outlined,
      options: [
        GuideOption(
          text: '...in difficoltà o ferito.',
          summaryId: 'summary_selvatico_ferito',
        ),
        GuideOption(
          text: '...spaventato ma in salute (es. in un cortile).',
          summaryId: 'summary_selvatico_sano',
        ),
        GuideOption(
          text: '...aggressivo o crea pericolo.',
          summaryId: 'summary_selvatico_pericolo',
        ),
      ],
    ),
  };

  static final Map<String, GuideSummary> guideSummaries = {
    'summary_soccorso_urgente': GuideSummary(
      id: 'summary_soccorso_urgente',
      title: 'Azione Corretta',
      icon: Icons.verified_outlined,
      text: 'Contatta immediatamente il 112 (Numero Unico Emergenze) o la Polizia Locale. Descrivi la situazione e il luogo. Non toccare l\'animale se non sei sicuro. La tua sicurezza è la priorità.',
    ),
    
    'summary_non_spostare': GuideSummary(
      id: 'summary_non_spostare',
      title: 'Attenzione!',
      icon: Icons.warning_outlined,
      text: 'Non spostare un animale con traumi evidenti, potresti peggiorare le sue condizioni. Attendi i soccorsi qualificati che hai contattato.',
    ),
    
    'summary_contatto_asl': GuideSummary(
      id: 'summary_contatto_asl',
      title: 'Contatta le Autorità',
      icon: Icons.phone_outlined,
      text: 'Chiama la Polizia Locale del Comune o il servizio veterinario dell\'ASL. Sono obbligati per legge a intervenire per il recupero.',
    ),
    
    'summary_non_alimentare': GuideSummary(
      id: 'summary_non_alimentare',
      title: 'Non Intervenire!',
      icon: Icons.cancel_outlined,
      text: 'Non dare mai cibo o acqua a un animale in stato di shock o incosciente. Potrebbe soffocare. Attendi l\'arrivo dei soccorsi.',
    ),
    
    'summary_randagio': GuideSummary(
      id: 'summary_randagio',
      title: 'Animale Domestico',
      icon: Icons.pets_outlined,
      text: 'Se è un cane o gatto smarrito, avvicinati con cautela e controlla se ha una medaglietta. Chiama la Polizia Locale per la verifica del microchip.',
    ),
    
    'summary_nido_implumi': GuideSummary(
      id: 'summary_nido_implumi',
      title: 'Ricolloca il Nido',
      icon: Icons.keyboard_arrow_up_outlined,
      text: 'Se i piccoli sono senza penne, hanno bisogno dei genitori. Cerca di riposizionare il nido sull\'albero il più vicino possibile a dove l\'hai trovato. I genitori non li abbandoneranno per il tuo odore.',
    ),
    
    'summary_nido_pennuti': GuideSummary(
      id: 'summary_nido_pennuti',
      title: 'Lasciali Stare',
      icon: Icons.visibility_off_outlined,
      text: 'Se i piccoli hanno già le penne, è normale che siano a terra. Stanno imparando a volare e i genitori li seguono da vicino. Allontanati per non spaventarli.',
    ),
    
    'summary_crass': GuideSummary(
      id: 'summary_crass',
      title: 'Contatta un Centro',
      icon: Icons.local_hospital_outlined,
      text: 'Se gli uccellini sono feriti, contatta il CRAS (Centro Recupero Animali Selvatici) della tua provincia o la Polizia Provinciale.',
    ),
    
    'summary_selvatico_ferito': GuideSummary(
      id: 'summary_selvatico_ferito',
      title: 'Soccorso Selvatici',
      icon: Icons.medical_services_outlined,
      text: 'Contatta immediatamente la Polizia Provinciale o un CRAS (Centro Recupero Animali Selvatici). Sono gli enti preposti al recupero della fauna selvatica in difficoltà.',
    ),
    
    'summary_selvatico_sano': GuideSummary(
      id: 'summary_selvatico_sano',
      title: 'Non Intervenire',
      icon: Icons.directions_walk_outlined,
      text: 'Non avvicinarti e non dare cibo. Lascia all\'animale una via di fuga. Se è intrappolato (es. in un cortile), contatta la Polizia Provinciale per una gestione sicura.',
    ),
    
    'summary_selvatico_pericolo': GuideSummary(
      id: 'summary_selvatico_pericolo',
      title: 'Pericolo Imminente',
      icon: Icons.warning_outlined,
      text: 'Se l\'animale rappresenta un pericolo per le persone, mantieni la distanza di sicurezza e contatta immediatamente il 112 (Numero Unico Emergenze).',
    ),
  };
}