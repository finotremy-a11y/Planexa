# Checklist Mise en Production — PlanifyPro

> Tout ce qui est marqué **[AUTO]** a été corrigé automatiquement par l'IA dans ce projet.  
> Tout ce qui est marqué **[MANUEL]** nécessite une action humaine (Render dashboard, Stripe, etc.)

---

## 🔴 Bloquants (à corriger avant tout déploiement)

### 1. [AUTO] Active Storage → Cloudinary
**Problème :** `production.rb` utilise `:local` → les fichiers uploadés sont perdus à chaque redéploiement sur Render (filesystem éphémère).  
**Fichier :** `config/environments/production.rb`  
**Correction :** `config.active_storage.service = :cloudinary`  
**Variable d'environnement requise :** `CLOUDINARY_URL=cloudinary://api_key:api_secret@cloud_name`

### 2. [AUTO] Active Job → Sidekiq (suppression solid_queue)
**Problème :** `production.rb` active `solid_queue` comme backend de jobs, mais l'infrastructure Render utilise Sidekiq (`render.yaml` + `Procfile`). Les jobs ne sont pas traités.  
**Fichier :** `config/environments/production.rb`  
**Correction :**  
- `config.active_job.queue_adapter = :sidekiq`  
- Supprimer la ligne `config.solid_queue.connects_to = ...`

### 3. [AUTO] Scheduling — Réconciliation recurring.yml vs schedule.rb
**Problème :** Deux mécanismes de scheduling en conflit :
- `config/schedule.rb` (gem `whenever`) → génère du cron système. Ne fonctionne **pas** sur Render (pas d'accès cron système).
- `config/recurring.yml` (Solid Queue recurring) → inutile si Sidekiq est le backend.

**Solution retenue :** Utiliser les **Render Cron Jobs** (déclarés dans `render.yaml`) + supprimer `solid_queue` recurring tasks.  
**Fichier :** `config/recurring.yml` → vidé/commenté  
**Fichier :** `render.yaml` → ajouter 3 cron job services  

### 4. [AUTO] Paramètres sensibles manquants dans les logs
**Problème :** `filter_parameter_logging.rb` ne filtre pas `:phone`, `:address`, `:first_name`, `:last_name`, `:stripe`, `:authorization`, `:iban`.  
**Fichier :** `config/initializers/filter_parameter_logging.rb`

---

## 🟠 Importants (nécessaire au bon fonctionnement)

### 5. [MANUEL] Variables d'environnement Render
Dans le dashboard Render → Service web → **Environment**, renseigner :

| Variable | Valeur / Source |
|---|---|
| `DATABASE_URL` | URL Supabase Pooler (Transaction mode, port 6543) avec pwd URL-encodé |
| `REDIS_URL` | Fournie automatiquement par Render si service Redis lié |
| `APP_HOST` | `planifypro.fr` (ou votre domaine de prod) |
| `SECRET_KEY_BASE` | `bundle exec rails secret` |
| `RAILS_MASTER_KEY` | Contenu de `config/master.key` |
| `RESEND_API_KEY` | Dashboard Resend |
| `CLOUDINARY_URL` | Dashboard Cloudinary → Account Details |
| `STRIPE_SECRET_KEY` | Dashboard Stripe → Live keys (commence par `sk_live_`) |
| `STRIPE_PUBLISHABLE_KEY` | Dashboard Stripe → Live keys (commence par `pk_live_`) |
| `STRIPE_WEBHOOK_SECRET` | `whsec_...` (voir étape 6) |
| `STRIPE_PRICE_ID_MONTHLY` | ID du prix mensuel dans Stripe live |
| `SENTRY_DSN` | Dashboard Sentry → Settings → DSN |
| `ADMIN_EMAIL` | Email administrateur |
| `ADMIN_PASSWORD` | Mot de passe fort (min 20 chars) |
| `VAPID_PUBLIC_KEY` | Générer avec `bundle exec rails web_push:generate_keys` |
| `VAPID_PRIVATE_KEY` | Idem |

### 6. [MANUEL] Stripe — Configuration Webhooks Live
1. Aller dans **Stripe Dashboard → Developers → Webhooks → Add endpoint**
2. URL : `https://planifypro.fr/webhooks/stripe`
3. Événements à écouter :
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
   - `checkout.session.completed`
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
4. Copier le **Signing secret** (`whsec_...`) dans `STRIPE_WEBHOOK_SECRET` sur Render
5. Tester avec **"Send test event"** depuis Stripe

### 7. [MANUEL] Resend — Validation Domaine
1. Aller dans **Resend Dashboard → Domains → Add domain** → `planifypro.fr`
2. Ajouter les enregistrements DNS SPF, DKIM, et DMARC chez votre registrar
3. Cliquer **Verify** une fois les DNS propagés
4. Tester l'envoi depuis `Resend Dashboard → API Keys → Send test email`

---

## 🟡 Recommandés (qualité / observabilité)

### 8. [MANUEL] Sentry — Validation
1. Vérifier que `SENTRY_DSN` est bien renseigné sur Render
2. Déclencher une erreur test : `bundle exec rails runner "raise 'Test Sentry'" --environment=production`
3. Confirmer l'apparition dans le dashboard Sentry

### 9. [MANUEL] Render — Health Check
- Le endpoint `/up` est configuré dans `render.yaml` — vérifier qu'il retourne `200` après déploiement
- Render envoie automatiquement des alertes email si le health check échoue

### 10. [MANUEL] Domaine personnalisé
1. Dans **Render Dashboard → Custom Domains** → ajouter `planifypro.fr` et `www.planifypro.fr`
2. Chez votre registrar, pointer le DNS vers Render (CNAME ou A record)
3. Render provisionne le certificat SSL automatiquement (Let's Encrypt)

---

## ✅ Smoke Test pré-prod (à faire manuellement)

Valider ces 10 parcours critiques sur l'URL de production avant d'ouvrir au public :

| # | Parcours | Attendu |
|---|---|---|
| 1 | Inscription entreprise | Email de confirmation reçu via Resend |
| 2 | Onboarding checklist | Toutes les étapes s'affichent et se complètent |
| 3 | Création d'une prestation | Templates sectoriels affichés selon catégorie pro |
| 4 | Page publique d'une fiche | Affichage correct, schema.org présent dans le HTML |
| 5 | Réservation client (sans compte) | Créneau sélectionnable, confirmation email reçue |
| 6 | Réservation avec acompte | Redirection Stripe, paiement Stripe live, confirmation |
| 7 | Annulation client | Notification email envoyée, créneau libéré |
| 8 | Abonnement Pro via `/tarifs` | Checkout Stripe → subscription active → accès débloqué |
| 9 | Dashboard statistiques | Funnel analytics s'affiche avec données réelles |
| 10 | Email hebdomadaire performance | Déclencher `WeeklyCompanyPerformanceEmailJob` manuellement et vérifier réception |

---

## 📋 Ordre d'exécution conseillé

```
1. Appliquer les corrections automatiques (production.rb, recurring.yml, filter_params) ← déjà fait
2. Générer les clés manquantes (SECRET_KEY_BASE, VAPID)
3. Renseigner toutes les variables sur Render
4. Configurer le webhook Stripe Live
5. Valider le domaine Resend
6. Premier déploiement → vérifier le health check
7. Smoke test complet (10 parcours ci-dessus)
8. Configurer Sentry alerts
9. Configurer le domaine custom + SSL
10. Ouvrir au public 🚀
```
