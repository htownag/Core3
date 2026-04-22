# Local dev loop — Ryan's workflow

*On the `ultrareview-extraction` branch of `htownag/Core3`. Committed alongside `MOD_NOTES.md` during Phase 1 Deliverable 0.*

Prerequisites: Phase 0 complete. Server at `~/workspace/Core3/` runs cleanly inside WSL2 Debian 12. SWGEmu client at `C:\SWGemu Vanilla\` connects, admin commands work (see [Phase 0 retrospective](https://github.com/htownag/ExtractionMod-SWGEmu/blob/main/logbook/2026-W17-phase-0-complete.md) in the project repo for setup notes — the six self-host gotchas).

## Fast iteration loop — Lua / content changes

1. Edit a Lua file in VS Code on Windows (`C:\Users\atlee\Projects\ExtractionMod-SWGEmu\mod-overlay\...`).
2. In WSL2 terminal:
   ```bash
   /mnt/c/Users/atlee/Projects/ExtractionMod-SWGEmu/scripts/sync-mod.sh
   ```
3. The rsync runs, then `luac -p` syntax-checks every `.lua` in the destination. If any file fails, fix and re-run.
4. At the Core3 server console: type `exit`, wait for shutdown.
5. Re-launch:
   ```bash
   cd ~/workspace/Core3/MMOCoreORB/bin && ./core3
   ```
6. In SWG client, log in on admin character, test the change.

## C++ / IDL changes (Patches A, B, C, D)

The ~190 LOC C++ patch set is applied directly inside `~/workspace/Core3/MMOCoreORB/src/` on this branch.

1. Edit the `.cpp` / `.h` / `.idl` file.
2. In WSL2:
   ```bash
   cd ~/workspace/Core3/MMOCoreORB
   make idl            # regenerates Zone.{h,cpp}, etc. from .idl files
   make build-ninja-debug    # 5–20 min incremental build
   ```
3. If build fails, read the bottom of the output — the first-scrollback error is almost always a cascade effect of a later root error.
4. On success, continue with step 4 of the Lua flow.

## Config changes — `config-local.lua`, `ZonesEnabled`, etc.

Same as Lua: restart server. No build step.

**Gotcha:** per Phase 0 retro gotcha #3, `~/.env` is the real source of truth for some fields (notably `GALAXY_ADDRESS`, `ADMIN_PASS`). Editing `config-local.lua` for those specific values has zero effect.

## When things go sideways

- **Build fails after `make idl`:** the generated `.h`/`.cpp` pair for the IDL'd class may have stale references. Try `make clean && make idl && make build-ninja-debug`.
- **Server boots but custom_scripts content doesn't load:** confirm the include-shell files exist at `bin/scripts/custom_scripts/{screenplays,mobile,object,loot}/*.lua`. The vanilla loaders include them by literal path — missing files produce parse errors.
- **Client shows stale world state:** ODB persistence keeps objects across restarts. To reset, stop server, delete `bin/databases/*` — destructive, verify before running.
- **Client refuses to connect after server restart:** check `~/.env` → `GALAXY_ADDRESS` matches your current WSL2 IP. IPs can shift on WSL2 reboots.

## Reference

- Project: [ExtractionMod-SWGEmu](https://github.com/htownag/ExtractionMod-SWGEmu) — docs, workplans, mod-overlay content, logbook.
- Phase 1 workplan: [`workplans/phase-1.md`](../../workplans/phase-1.md) in the project repo.
- Ultraplan: [`docs/ultraplan.md`](../../docs/ultraplan.md) including the 2026-04-22 revision for the revised patch plan.
