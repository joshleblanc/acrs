# ACRS - Automated Competitive Ranking System

## Overview

A user-facing application for managing competitive league play with automated group assignments, round-robin scheduling, and live match coordination.

---

## Authentication System

**Status: Complete**

### Components
- [x] `SessionsController` - Sign in/out
- [x] `RegistrationsController` - Sign up with email + username + password
- [x] `PasswordsController` - Password reset flow
- [x] Bulma-styled auth pages
- [x] Rate limiting on auth endpoints
- [x] User model with `has_secure_password`

### Database Schema
```
users
├── id
├── username (unique, required)
├── email_address (unique, normalized)
├── password_digest
├── created_at
└── updated_at

sessions
├── id
├── user_id (FK)
├── user_agent
├── ip_address
├── created_at
└── updated_at
```

---

## League Management

**Status: Complete**

### Features
- [x] Admin access via Madmin
- [x] League model with slug, description, status, match_day
- [x] Invite link generation with tokens, expiration, max_signups
- [x] League signup flow with display name

### Database Schema
```ruby
# Complete
leagues
├── id
├── game_id (FK)
├── name
├── slug (unique)
├── description
├── match_day (enum: sunday..saturday)
├── season_start
├── season_end
├── status (draft, accepting_signups, active, completed)
├── created_at
└── updated_at

invites
├── id
├── league_id (FK)
├── token (unique)
├── expires_at
├── max_signups
├── created_at
└── updated_at

players
├── id
├── league_id (FK)
├── user_id (FK, optional)
├── name
├── elo (float)
├── created_at
└── updated_at
```

---

## Group Assignment

**Status: Complete**

### Features
- [x] Groups model with name, tier
- [x] GroupAssignment join table
- [x] Automatic initial assignment when league activates
- [x] Group names: S, A, B, C, D... (8 groups max)
- [x] Players per group: 4-6 (default 4)
- [x] Random assignment on activation
- [ ] Manual group assignment via Madmin
- [ ] Promotion/relegation logic

### Database Schema
```ruby
# Complete
groups
├── id
├── league_id (FK)
├── name (S, A, B, C, D)
├── tier (integer, lower = higher skill)
├── min_players
├── max_players
└── created_at

group_assignments
├── id
├── group_id (FK)
├── player_id (FK)
├── created_at
└── updated_at
```

### Promotion/Relegation Rules
- After round robin completes:
  - Top player from each group → promoted to next tier up
  - Bottom player from each group → relegated to next tier down
  - S tier has no promotion (top)
  - Bottom tier has no relegation

---

## Match Scheduling

**Status: Complete**

### Features
- [x] Match model with status tracking
- [x] RoundRobinScheduler service (circle method algorithm)
- [ ] One match per week per user
- [ ] Match day configuration per league
- [ ] Bye weeks if odd number of players

### Database Schema
```ruby
# Complete
matches
├── id
├── league_id (FK)
├── status (pending, lobby, races_picking, races_revealed, map_picking, in_progress, completed)
├── scheduled_at
├── created_at
└── updated_at

match_players
├── id
├── match_id (FK)
├── player_id (FK)
├── race_id (FK to Race, nullable)
├── ready (boolean)
├── created_at
└── updated_at

match_games (MatchGame)
├── id
├── match_id (FK)
├── game_number
├── map_id (FK, optional)
├── winner_id (FK to Player, optional)
├── status (pending, races_selected, map_set, completed)
├── created_at
└── updated_at
```

---

## Match Flow

**Status: In Progress**

### Flow Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│                         MATCH LOBBY                              │
├─────────────────────────────────────────────────────────────────┤
│  1. Both players click "Ready"                                   │
│  2. When both ready → proceed to Race Selection                 │
│  3. If timeout (15 min) → forfeit to non-forfeiting player      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      RACE SELECTION                             │
├─────────────────────────────────────────────────────────────────┤
│  1. Both players pick a race simultaneously                    │
│  2. Both reveal races                                           │
│  3. Proceed to Map Picker (Game 1)                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                       MAP PICKER                                 │
├─────────────────────────────────────────────────────────────────┤
│  1. Default map shown as Game 1 (per week's config)             │
│  2. Players report winner                                       │
│  3. If match over (2-0) → End Match                            │
│  4. Loser of previous game picks map for next game              │
│  5. Repeat until 2 wins                                         │
└─────────────────────────────────────────────────────────────────┘
```

### Race Selection Rules
- Winner of previous game cannot pick same race for next game
- Player can pick any available race

### Map Banning (Future Enhancement)
- Each player bans 1 map before selection
- Remaining maps available for loser pick

---

## Match Interaction UI

**Status: Complete**

### Pages
- [x] `/leagues` - League listing
- [x] `/leagues/:slug` - League overview, signup CTA
- [x] `/invites/:token` - Invite link handling
- [x] `/leagues/:id/signup` - Signup form
- [x] `/dashboard` - User dashboard with player stats
- [x] `/matches` - List of user's upcoming/completed matches
- [x] `/matches/:id` - Match lobby and interaction

### Match Lobby States
| State | Player 1 | Player 2 | Action |
|-------|----------|----------|--------|
| pending/lobby | not ready | not ready | Both click "Ready" |
| lobby | ready | not ready | Player 2 clicks "Ready" |
| races_picking | picks race | picks race | Wait for both |
| races_revealed | sees race | sees race | Auto-proceed |
| map_picking | picks map | — | Loser picks |
| in_progress | reports result | reports result | Winner confirmation |
| completed | sees final score | sees final score | Return to matches |

---

## Services

**Status: Complete**

- [x] `RoundRobinScheduler` - Generates round-robin matchups using circle method
- [x] `PromotionService` - Handles group promotion/relegation after season end
- [x] `LeagueActivationService` - Creates groups, assigns players, schedules matches when league goes active

---

## Madmin Integration

**Status: Complete**

Admin manages via Madmin:
- [x] Games (CRUD)
- [x] Leagues (CRUD)
- [x] Players (CRUD, assign to leagues)
- [x] Invites (CRUD, generate links)
- [x] Maps (CRUD, manage pool)
- [x] Matches (view, override results)
- [x] Groups (CRUD, assign players)
- [x] Match Games (view)
- [x] Group Assignments (CRUD)

---

## Technical Stack

- **Framework**: Rails 8.1+
- **Database**: SQLite (dev) / PostgreSQL (prod)
- **Auth**: Custom session-based
- **Admin**: Madmin
- **Styling**: Bulma CSS + FontAwesome
- **Real-time**: ActionCable (planned)

---

## Project Status

| Feature | Status |
|---------|--------|
| Authentication | Complete |
| Bulma Theming | Complete |
| User Registration (with username) | Complete |
| League Model | Complete |
| Invite System | Complete |
| Group Model | Complete |
| Match Model | Complete |
| League UI (list, show, signup) | Complete |
| Dashboard UI | Complete |
| Match UI (all phases) | Complete |
| Round Robin Scheduling | Complete |
| Race Selection UI | Complete |
| Map Picking UI | Complete |
| League Activation (group creation) | Complete |
| Services (Scheduler, Promotion, Activation) | Complete |
| Real-time Updates | Pending |
| Promotion/Relegation | Complete |
| Map Banning | Pending |
| Leaderboards | Pending |
| Email notifications | Pending |
| Mobile optimization | Pending |
| Match Model Tests | Complete |

---

## Next Steps

### Priority 4: Polish
1. [ ] Map banning phase
2. [ ] Match history
3. [ ] Leaderboards
4. [ ] Email notifications
5. [ ] Mobile optimization

### Priority 5: Real-time
1. [ ] ActionCable for live match updates
2. [ ] Presence indicators
3. [ ] Real-time score updates
