# Audit de faisabilite medecins / docteurs (G1)

Date: 24/03/2026
Auteur: Produit / Tech Planexa

## 1) Perimetre et hypothese

Objectif de cette phase: evaluer une entree marche "prise de rendez-vous medicale simple" sans stockage de donnees medicales sensibles ni dossier patient.

Definition du noyau cible:
- Prise de rendez-vous
- Gestion disponibilites
- Confirmations, rappels, annulations
- Informations praticien/cabinet visibles publiquement

Hors scope immediat:
- Dossier medical
- Messagerie clinique
- Teleconsultation avancee
- Prescription / parcours de soins

## 2) Segmentation cible

### 2.1 Generalistes
- Besoin principal: volume, fluidite, no-show control
- Fit produit actuel: eleve
- Ajustements necessaires: motifs de consultation, plages fines, tri urgence

### 2.2 Specialistes
- Besoin principal: motifs heterogenes, delais longs, parcours administratif
- Fit produit actuel: moyen
- Ajustements necessaires: categories de motifs, durees variables, regles planning plus strictes

### 2.3 Para-medical (kine, orthophoniste, podologue, etc.)
- Besoin principal: rebooking, recurrents, rappels
- Fit produit actuel: eleve
- Ajustements necessaires: sequences de RDV, motifs standardises

### 2.4 Dentistes
- Besoin principal: motifs et durees tres differents, urgences ponctuelles
- Fit produit actuel: moyen
- Ajustements necessaires: gestion motifs detaillee, capacite urgence, reallocation creneaux

### 2.5 Psychologues
- Besoin principal: relation de confiance, regularite des seances
- Fit produit actuel: eleve
- Ajustements necessaires: confidentialite UX, rebooking simple, rappels doux

### 2.6 Osteopathes
- Besoin principal: activite proche para-medical, logique locale
- Fit produit actuel: eleve
- Ajustements necessaires: motifs courts, SEO local, liste d'attente

## 3) Contraintes metier par segment

## 3.1 Contraintes transverses
- Informations publiques fiables (specialite, adresse, horaires, accessibilite)
- Politique d'annulation explicite
- Journalisation des actions sensibles (annulation, reassignment, acces admin)
- Pas de donnees de sante non necessaires

## 3.2 Contraintes de planification
- Motifs avec durees variables
- Slots urgence controlables
- Exceptions cabinet (fermetures ponctuelles)
- Limitation no-show (rappels, reconfirmation, acompte selon contexte)

## 3.3 Contraintes de confiance produit
- Copy rassurante en page publique
- Evidence operationnelle (disponibilites claires, confirmations nettes)
- Process d'escalade support sur annulations de derniere minute

## 4) Evaluation go / no-go par segment

- Generalistes: GO limite
  - Entree possible sur RDV simple sans dossier patient
  - Condition: renforcer disponibilites + page publique medicale

- Specialistes: GO progressif
  - Lancement par sous-segments simples
  - Condition: taxonomie motifs + regles planning avancees

- Para-medical: GO prioritaire
  - Meilleur ratio impact/risque
  - Condition: rebooking et relance inactifs robustes

- Dentistes: GO prudent
  - Potentiel eleve mais complexite planning superieure
  - Condition: capacite urgence + modelage motifs

- Psychologues: GO prioritaire
  - Besoin fort de regularite, bon fit rebooking/rappels
  - Condition: UX confidentialite et ton adapte

- Osteopathes: GO prioritaire
  - Segment proche de l'existant service/proximite
  - Condition: SEO local + no-show prevention

## 5) Recommendation strategique

Recommendation globale: GO cible, par vagues.

Ordre suggere de lancement:
1. Para-medical + osteopathes + psychologues
2. Generalistes
3. Specialistes et dentistes (vague 2, apres stabilisation planning)

Garde-fous:
- Ne pas collecter de donnees cliniques
- Auditer les permissions et logs avant extension segment 2
- Assurer KPI no-show et conversion par segment avant scale

## 6) Impacts backlog immediats

Tickets prealables critiques pour execution segment medical:
- G2: type de compte professionnel de sante
- G3: taxonomie specialites / motifs
- G4: disponibilites cabinet avancees
- G5: page publique medicale rassurante
- G6: securite et audit renforces

Definition de succes phase G1:
- Cadrage valide par produit + tech
- Priorisation des segments agreee
- Risques principaux identifies et relies a un plan d'implementation
