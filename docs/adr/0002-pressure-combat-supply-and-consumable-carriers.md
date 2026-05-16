# ADR 0002: Pressure Combat, Supply, and Consumable Carriers

## Status

Accepted

## Context

The equipment carrier catalog gives Dream Coastline a durable item layer, but it
should not pull the game toward a generic attack, defense, gold shop, and potion
loop. The story is about names, glyphs, memory, public infrastructure,
observability, and civilization repair.

The runtime already has authored combat, small scene resources
(`ink`, `focus`, `stability`), and flag-driven equipment grants. The missing
supporting systems should prove that carriers matter under pressure while
keeping the economy deterministic and story-owned.

## Decision

Introduce the smallest support layer in three parts:

- Pressure combat: combat may read carrier effects such as
  `combat_modifiers.lose_name_every_delta`. This extends the "keep the name
  stable" window instead of adding attack or defense stats.
- Supply channels: do not add a currency shop yet. Supply is granted by story
  flags through `data/supply_catalog.json`, representing book rooms, workshops,
  archives, and labs authorizing resources.
- Consumable carriers: supply grants small one-use carriers such as ink
  reserves, focus slips, or stability seals. These restore `1-2` points of the
  existing scene resources and are saved as session state.

The first runtime slice adds a `use_supply` action group. Supply offers are
deterministic, one-time grants from `acquisition.source_flags`; no buy/sell UI,
prices, rarity, random drops, or upgrade materials are introduced.

## Consequences

- Equipment gains combat meaning without changing the existing authored
  encounter model.
- "Shop" becomes authorization and supply, which fits the world better than a
  gold economy.
- Consumables support longer scenes and pressure checks while keeping numbers
  small.
- Future UI can present supply channels as book-room, workshop, archive, or lab
  panels without changing the session save contract.

## Current Vertical Slice

- `data/supply_catalog.json` defines the first consumable carriers.
- `GameSession` and `RustGameSession` grant supply from story flags, save
  `supply_inventory` and `claimed_supply_offers`, expose `supply_count`, and add
  a `use_supply` action.
- `stat_value` and existing stat clamps remain the authority for resource caps.
- Equipment `combat_modifiers.lose_name_every_delta` is read by attack logic.

## Non-goals

- No currency, prices, buyback, or vendors.
- No random loot or repeatable farming.
- No direct attack or defense stats.
- No dedicated inventory screen in this slice.
- No visual map or TileMap changes in this ADR.
