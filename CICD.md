# CI/CD-Demo · Schulungsmaterial

Dieses Repo enthält eine **Lern-Pipeline** für GitHub Actions mit zwei
Workflows und drei Umgebungen. Die YAML-Dateien laufen nicht
zwangsläufig grün — sie sind so geschrieben, dass die Mechanik
sauber lesbar ist.

> **Beispiel-Stack:** nur `node/` ist abgedeckt. PHP, Python und
> .NET würden nach demselben Muster funktionieren — Matrix-Builds
> oder zusätzliche Jobs.

---

## Begriffe in einem Absatz

- **CI** (Continuous Integration) prüft jeden Codestand auf
  Korrektheit (Build + Tests). Sie schützt den Hauptbranch vor
  kaputten Commits.
- **CD** (Continuous Deployment) nimmt geprüften Code und bringt
  ihn auf eine echte Umgebung. Sie automatisiert das Ausrollen.
- **Stage / Environment**: eine Zielumgebung mit eigener URL,
  eigenen Secrets und eigenen Daten. Hier: `dev`, `demo`, `live`.

---

## Die drei Stages

| Stage | Zweck | Wer benutzt sie? | Datenstand |
|-------|-------|------------------|------------|
| **dev**  | Spielwiese für Entwickler. Hier darf etwas brechen. | Entwicklungsteam | Wegwerfbar, häufig zurückgesetzt |
| **demo** | Stakeholder-Bühne: Vertrieb, UAT, Präsentationen. | Product Owner, Kunden | Stabil, anonymisierte Beispieldaten |
| **live** | Produktion. Was hier ausfällt, kostet Geld. | Endnutzer | Echte Daten, Backups, Monitoring |

Faustregel: Je näher an `live`, desto mehr Schutz, desto seltener
Releases, desto strikter die Freigabe.

---

## Trigger-Modell (branch-basiert)

```
Feature-Branch ──PR──► main ────────────► dev   (automatisch)
                        │
                        └─ Merge ──► demo ────► demo  (automatisch)
                                       │
                                       └─ Tag v* ─► live  (manuell)
```

| Aktion im Repo                | Was passiert                                        |
|-------------------------------|-----------------------------------------------------|
| Push auf Feature-Branch       | CI läuft (Test + Probebau).                         |
| PR gegen `main`               | CI läuft — Branch Protection blockt roten Merge.    |
| Merge in `main`               | CD → Image bauen, pushen, auf **dev** ausrollen.    |
| Push auf Branch `demo`        | CD → auf **demo** ausrollen.                        |
| Push eines Tags `v1.2.3`      | CD → auf **live** ausrollen, **wartet auf Approve**. |

---

## Die Pipelines

### `.github/workflows/ci.yml` — das Sicherheitsnetz

Läuft auf jedem Push (außer `main`/`demo`/`v*`) und auf jedem PR
gegen `main`. Zwei Jobs:

1. **test-node** — `npm install && npm test` im Node-Stack.
2. **build-image** — baut das Docker-Image, **pusht aber nicht**.
   Fängt ein kaputtes Dockerfile schon im PR ab.

Warum schließen wir `main`/`demo`/`v*` aus? Weil die CD-Pipeline
auf genau diesen Refs ohnehin testet, bevor sie deployt — sonst
liefen Tests doppelt und die UI würde unnötig vollgemüllt.

### `.github/workflows/cd.yml` — das Ausrollen

Drei Phasen:

1. **resolve-stage** — bestimmt aus dem Ref (`main` / `demo` /
   `refs/tags/v*`) die Stage. So liegt diese Logik an genau einer
   Stelle.
2. **build-and-push** — Tests laufen erneut (Defense in Depth),
   dann wird das Image gebaut und nach **GHCR** (GitHub Container
   Registry, `ghcr.io/<owner>/<repo>/node`) gepusht. Es bekommt
   zwei Tags:
   - eindeutig: `dev-a1b2c3d` / `v1.2.0` — für Rollback und
     Nachvollziehbarkeit
   - rollend: `dev` / `demo` / `live` — für "immer das Neueste"
3. **deploy-{dev,demo,live}** — drei Jobs, jeder mit eigenem
   `if:` und eigenem `environment:`. Aktuell ein `echo` —
   Platzhalter für den echten Deploy-Befehl.

---

## Einmaliges Setup in GitHub

Damit der branch-basierte Workflow vollständig funktioniert:

1. **Branch `demo` anlegen**
   ```bash
   git checkout -b demo main
   git push -u origin demo
   ```

2. **Environments anlegen** unter *Settings → Environments*:
   - `dev` — keine Schutzregeln, soll schnell sein.
   - `demo` — optional ein Reviewer.
   - `live` — **Required reviewers: ≥ 1 Person**,
     **Deployment branches and tags: nur Tags `v*`**.
     Das ist das technische Vier-Augen-Prinzip.

3. **Branch Protection für `main`** unter *Settings → Branches*:
   - Require pull request before merging
   - Require status checks: `Node.js · Test`, `Docker · Probebau`
   - So kann nichts in `main` wandern, was die CI nicht überlebt.

4. **GHCR-Sichtbarkeit**: Pakete unter
   *github.com/\<owner\>/\<repo\>/pkgs/container/...* nach dem
   ersten Push prüfen. Standardmäßig privat — bei Bedarf umstellen.

---

## Wie deploye ich…?

| Aufgabe                         | Befehl                                          |
|---------------------------------|-------------------------------------------------|
| …ein Feature nach dev           | PR mergen, Rest läuft automatisch.              |
| …den aktuellen Stand nach demo  | `git push origin main:demo`                     |
| …Version 1.2.0 nach live        | `git tag v1.2.0 && git push --tags`, dann in der GitHub-UI auf "Approve" klicken. |
| …live zurückrollen              | Auf den vorherigen Tag deployen — entweder neuen Tag setzen oder das Image-Tag direkt auf der Zielinfrastruktur austauschen. |

---

## Wo der Code "in echt" deployt würde

Der `echo`-Schritt in jedem `deploy-*`-Job ist der Platzhalter.
Drei realistische Varianten:

```yaml
# SSH + Docker Compose (klassisch)
- run: |
    ssh deploy@${{ vars.HOST }} \
      "cd /srv/app && docker compose pull && docker compose up -d"

# Kubernetes
- run: |
    kubectl set image deployment/api \
      api=$IMAGE_NAME:${{ needs.resolve-stage.outputs.tag }}

# Fly.io
- run: flyctl deploy --image $IMAGE_NAME:${{ needs.resolve-stage.outputs.tag }}
```

Was hier passt, hängt von der Zielinfrastruktur ab — die
Pipeline-Struktur darüber bleibt unverändert.

---

## Was die Demo bewusst weglässt

- **Andere Stacks** (php, python, dotnet, vue) — selbe Mechanik.
- **Migrations / Datenbank-Änderungen** — gehören in einen
  eigenen Job vor dem Deploy, oft mit Backup-Schritt.
- **Smoke-Tests nach dem Deploy** — ein kurzer `curl` gegen
  `/health` im jeweiligen Environment ist die billigste
  Versicherung gegen "deploy war grün, App ist trotzdem tot".
- **Rollback-Automatik** — manuell über erneuten Deploy mit
  altem Tag. Automatisches Rollback braucht ein Health-Check-
  Konzept.
- **Secret-Management** — Beispiele oben nutzen `secrets.*` /
  `vars.*` aus dem Environment. Für ernsthafte Setups
  zusätzlich Rotation und Audit überlegen.
