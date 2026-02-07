# Plan de projet complet — AI Coaching App (Approche *Local‑Only*)

> **Stack technique choisi (MVP ultra‑simple)** : Flutter (Dart) + SQLite (Drift ou sqflite) pour stockage local + RevenueCat (SDK mobile) pour la monétisation + OpenRouter (proxy) → modèle LLM `openai/gpt-4o-mini`.

Ce document décrit un plan A→Z pour un MVP **sans backend**, où toutes les données utilisateur (coachs, conversations, préférences) restent sur le téléphone. Le système utilise OpenRouter pour accéder au modèle LLM et RevenueCat pour gérer abonnements. Le document contient : objectifs, design, fonctionnalités, architecture, schéma local, intégration RevenueCat, appels LLM, sécurité, roadmap, checklist de soumission Devpost et livrables.

---

## 1. Vision & objectifs

**Vision** : proposer une application mobile minimaliste et premium qui permet à un utilisateur de « parcourir, créer, personnaliser et converser » avec des AI coaches — **sans création de compte**, toutes les données restant sur l’appareil.

**Objectifs du MVP** :
- Chat fonctionnel avec des coachs (templates) alimentés par `gpt-4o-mini` via OpenRouter.  
- Création guidée de coachs personnalisés (Premium).  
- Stockage complet local (SQLite) ; aucun stockage cloud requis.  
- Intégration RevenueCat testable (sandbox) pour Free/Standard/Premium.  
- Build TestFlight & Google Internal Testing prêts pour soumission hackathon.

---

## 2. Public cible
- Productivité‑oriented creators, freelances, knowledge workers (25–45 ans)  
- Utilisateurs qui valorisent la confidentialité et l’immédiateté  

---

## 3. Proposition de valeur & modèle business

**Valeur** : coaching IA immédiat, simple, personnalisable, et privé (données locales).

**Business model** (RevenueCat) : 3 niveaux
- **Free** : accès limité (1–2 coachs, quotas d’interactions)  
- **Standard** — $9.99 / mois (catalogue complet)  
- **Premium** — $19.99 / mois (création de coachs, export, templates exclusifs)

Paywall intelligent : n’afficher le paywall que lors d’actions premium (création, export) pour maximiser conversion.

---

## 4. Fonctionnalités (MVP local‑only)

### Obligatoires pour soumission
- Browse coach templates (≥5)  
- Coach Detail + Chat (LLM)  
- Create Custom Coach (Premium gating)  
- Stockage local (SQLite) : coaches, conversations, settings  
- RevenueCat integration (Offerings / Entitlements)  
- Simple onboarding + Paywall UI  

### Optionnel mais recommandé
- Export JSON d’un coach (local file)  
- Import d’un coach via fichier  
- Backup manuel via export/import  

---

## 5. Architecture technique (local‑only)

```
Mobile App (Flutter)
 ├─ Local DB (SQLite / Drift)
 ├─ RevenueCat SDK (purchases_flutter)
 └─ OpenRouter HTTP calls -> OpenAI GPT-4o-mini
```

- Aucune base cloud n’est nécessaire.  
- Tous les objets persistants sont en SQLite.  
- Les appels LLM se font depuis l’app elle‑même (ou via proxy optionnel).  

---

## 6. Data model local (SQLite)

Tables proposées (Drift / sqflite) :

**coaches**
- id TEXT PRIMARY KEY
- title TEXT
- description TEXT
- system_prompt TEXT
- is_premium INTEGER (0/1)
- created_at INTEGER

**user_coachs** (coachs créés par user)
- id TEXT PRIMARY KEY
- base_template_id TEXT NULLABLE
- custom_prompt TEXT
- metadata JSON
- created_at INTEGER

**messages**
- id INTEGER PRIMARY KEY AUTOINCREMENT
- conversation_id TEXT
- role TEXT ('user'|'assistant'|'system')
- content TEXT
- timestamp INTEGER

**conversations**
- id TEXT PRIMARY KEY
- coach_id TEXT
- summary TEXT (optionnel)
- last_activity INTEGER

**settings**
- key TEXT PRIMARY KEY
- value TEXT

---

## 7. Flow principaux (local)

### Chat
1. Charger `coach.system_prompt` + user context (settings)  
2. Construire messages : system + user messages récents (limiter tokens)  
3. Envoyer à OpenRouter → recevoir réponse  
4. Sauvegarder message + réponse en SQLite  

### Création de coach
1. UI stepper (title → purpose → style → preview)  
2. Le client compose un `system_prompt` final basé sur champs  
3. Enregistrer en `user_coachs`  
4. (Optionnel) Générer exemples avec LLM pour enrichir description

---

## 8. Intégration OpenRouter (appelle le LLM)

### Choix : direct depuis app (MVP) vs proxy serveur (optionnel)
- **MVP** : requêtes directes depuis Flutter vers OpenRouter.
  - Avantage : simplicité, rapidité de dev.  
  - Inconvénient : clé API embarquée dans l’application (risque d’exposition).
- **Optionnel** : petite Cloud Function / serverless qui fait uniquement proxy.
  - Avantage : protège la clé, possibilité d’ajouter rate limit, modération.  
  - Inconvénient : nécessite déploiement et coût minimal.

**Recommandation pour hackathon** : direct depuis l’app (clé OpenRouter utilisée en sandbox/test). Pour production, migrer vers proxy.

### Exemple d’appel (Dart / http)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> callOpenRouter(String systemPrompt, String userMessage) async {
  final url = Uri.parse('https://openrouter.ai/v1/chat/completions');
  final apiKey = 'OPENROUTER_KEY_HERE'; // voir sécurité

  final body = {
    'model': 'openai/gpt-4o-mini',
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userMessage},
    ],
    'max_tokens': 800,
  };

  final res = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode(body),
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    // adapter selon le format OpenRouter
    return data['choices'][0]['message']['content'];
  } else {
    throw Exception('LLM error: \${res.statusCode}');
  }
}
```

---

## 9. Intégration RevenueCat (sans backend)

RevenueCat s’intègre côté client via SDK Flutter (`purchases_flutter`). Tu dois :
1. Créer les produits dans App Store Connect & Google Play Console (sandbox IDs).  
2. Créer un projet RevenueCat et mapper les Product IDs.  
3. Définir Offerings & Entitlements (`standard`, `premium`).  
4. Intégrer SDK et vérifier entitlements côté client pour débloquer features.

### Exemple d’initialisation (Dart)

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Purchases.setLogLevel(LogLevel.debug);
  await Purchases.configure(PurchasesConfiguration('REVENUECAT_API_KEY'));
  runApp(MyApp());
}
```

### Vérifier l’état d’abonnement

```dart
CustomerInfo info = await Purchases.getCustomerInfo();
bool isPremium = info.entitlements.active.containsKey('premium');
```

> Important : RevenueCat déclenche des webhooks en cas d’événements (renew, cancel). Pour MVP sans backend, tu n’as pas besoin de consommer les webhooks. Assure‑toi seulement que l’état d’entitlement est interrogé régulièrement et stocké localement.

---

## 10. Sécurité et clés API

### Clé OpenRouter
- **Risque** : exposée si embarquée dans l’app.
- **Mitigations MVP** :
  - Obfuscation du code (Flutter obfuscate lors du build)  
  - Restreindre la clé côté OpenRouter (si disponible) par domaine ou quota  
  - Utiliser une clé de test limitée pour hackathon

**Production recommended** : utiliser un proxy serveur pour garder la clé secrète.

### RevenueCat
- Clefs RevenueCat côté client (public SDK key) sont prévues pour être en app.
- Ne pas exposer tokens admin de RevenueCat dans l’app.

---

## 11. UI/UX Design recommandations

- Minimal, aéré, typographie lisible
- Mode sombre + clair
- Paywall non agressif : montrer bénéfices concrets
- Flow Create Coach en 3 étapes maximum
- Indicateur de coût tokens / temps de réponse pour transparence

---

## 12. Tests & QA (sans backend)

- Tests sandbox RevenueCat (achats, renouvellements)  
- Tests API LLM : latence, erreurs, timeout  
- Tests de persistance local (réinstallation, export/import)  
- Tests offline : comportement quand OpenRouter indisponible

---

## 13. Roadmap hackathon — 3 semaines (local only)

### Semaine 1 — MVP UI & stockage
- Scaffolding Flutter, intégration SQLite (Drift)  
- Créer 5 templates coachs seed  
- Home, CoachDetail, Chat screens

### Semaine 2 — LLM & Monétisation
- Intégrer OpenRouter calls & display responses  
- Intégrer RevenueCat & implémenter paywall gating  
- Implement Create Coach flow (UI + store local)

### Semaine 3 — Polish & builds
- Polish UI, animations, error handling  
- TestFlight / Google Internal builds  
- Préparer vidéo demo < 3 min et assets Devpost

---

## 14. Checklist Devpost / Shipyard
- App installable via TestFlight / Internal testing  
- Paywall visible et testable (RevenueCat)  
- Démo vidéo ≤3min montrant : browse, chat, création coach (bloqué si Free), achat et unlock  
- README + screenshot + description claire (anglais)

---

## 15. Livrables (à fournir)
- Repo Flutter (README, scripts build pour Windows/VSCode)  
- Seed data (5 coach templates)  
- Builds iOS / Android (internal test)  
- Vidéo demo  
- Instructions d’exploitation (comment tester purchases sandbox)

---

## 16. Commandes & tips pour dev sous Windows + VSCode

- Créer projet : `flutter create ai_coach_app`  
- Ajouter packages : `flutter pub add http purchases_flutter drift sqlite3`  
- Obfusquer build release (Android) :
  `flutter build apk --obfuscate --split-debug-info=./debug_info`  
- Pour iOS / TestFlight, build from macOS (requis) — tu peux utiliser CI pour builder si tu n’as pas Mac local.

---

## 17. Limitations & décisions à documenter
- Pas de sync multi‑appareils (limitation volontaire)  
- Clé OpenRouter dans l’app (acceptable pour MVP)  
- Pas de webhooks RevenueCat consommés (ok pour hackathon)

---

## 18. Prochaines étapes (immédiates)
1. Générer repo Flutter skeleton + DB helpers (je peux le faire maintenant)  
2. Configurer projet RevenueCat & créer Offerings  
3. Récupérer clé OpenRouter (test key) et intégrer appel LLM  
4. Seed 5 coach templates et tester chat local

---

> Si tu veux, je peux :
> - Générer le **repo skeleton** complet (avec Drift sqlite helper, chat service, revenuecat wrapper) ; ou
> - Générer la **Cloud Function proxy minimal** pour OpenRouter (si tu veux sécurité) ; ou
> - Écrire le **script exact** de la vidéo demo de 3 minutes.

Dis‑moi directement lequel de ces trois livrables tu veux que je créé maintenant et je m’y mets. Je te fournis le code prêt à coller dans VSCode (Windows) et des instructions pas‑à‑pas.

