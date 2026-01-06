# Xin Xing 新星 - Restaurant Manager

App per la gestione del ristorante Xin Xing di Imperia.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Supabase](https://img.shields.io/badge/Backend-Supabase-green)
![License](https://img.shields.io/badge/License-Private-red)

## Funzionalità

- 📋 **Ordini** - Gestione ordini tavolo e asporto con stati in tempo reale
- 🪑 **Tavoli** - Mappa personalizzabile drag-and-drop del ristorante
- 🍜 **Menu** - Gestione piatti con categorie e disponibilità
- 📦 **Magazzino** - Controllo scorte con avvisi automatici
- 🌍 **Multilingua** - Italiano, English, 中文

## Setup

### Prerequisiti

- Flutter SDK 3.x
- Account Supabase (gratuito)

### 1. Clona e installa dipendenze

```bash
cd restaurant_app
flutter pub get
```

### 2. Configura Supabase

1. Crea un progetto su [supabase.com](https://supabase.com)
2. Vai su **SQL Editor** ed esegui il contenuto di `supabase/migrations/001_initial_schema.sql`
3. Vai su **Authentication → Providers → Email** e disabilita "Confirm email" (opzionale)
4. Vai su **Settings → API** e copia URL e anon key

### 3. Configura environment

Crea il file `.env` nella root del progetto:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### 4. Avvia l'app

```bash
flutter run
```

## Struttura Progetto

```
lib/
├── core/
│   ├── config/      # Configurazione Supabase
│   ├── l10n/        # Localizzazione (IT/EN/ZH)
│   ├── router/      # Navigazione
│   └── theme/       # Tema app
├── features/
│   ├── auth/        # Login/Registrazione
│   ├── home/        # Shell navigazione
│   ├── inventory/   # Gestione magazzino
│   ├── menu/        # Gestione menu
│   ├── orders/      # Gestione ordini
│   └── tables/      # Gestione tavoli
├── services/        # Servizi Supabase
└── shared/          # Widget condivisi
```

## Uso

### Mappa Tavoli
1. Premi ✏️ per entrare in modalità modifica
2. Trascina i tavoli per posizionarli
3. Premi "Fatto" per salvare

### Ordini
- **Tavolo**: Seleziona tavolo + numero persone
- **Asporto**: Nessun tavolo richiesto

### Cambio Lingua
Tocca 🌐 nella barra superiore per cambiare tra IT/EN/中文

## Tech Stack

- **Frontend**: Flutter 3.x + Riverpod
- **Backend**: Supabase (PostgreSQL + Auth + Realtime)
- **Routing**: GoRouter
- **State**: Riverpod

---

Made with ❤️ for Xin Xing, Imperia
