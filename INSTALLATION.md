# Installation af Airflow container-image

> **ADVARSEL:** Det medfølgende image er **ikke godkendt til produktionsbrug**.
> Det har ikke været igennem en hardeningproces mod eventuelle sårbarheder.
> Brug udelukkende til test, udvikling eller proof-of-concept formål.

Denne vejledning beskriver, hvordan du indlæser image-filen fra et USB-stik og gør det tilgængeligt i et container-registry til brug med Kubernetes.

## Indhold på USB-stikket

| Fil | Beskrivelse |
|-----|-------------|
| `rp-images-airflow-sha-ab4233d.tar.gz` | Airflow-image (742 MB) |
| `postgresql-15.tar.gz` | PostgreSQL metadata-database image (117 MB) |
| `values-minimal.yaml` | Klar Helm values-fil til Airflow |
| `INSTALLATION.md` | Denne vejledning |

> **OBS:** Begge images skal indlæses og pushes til registryet for at opnå en fuldt air-gapped installation. Mangler PostgreSQL-imaget, vil Kubernetes forsøge at hente det fra Docker Hub.

## Forudsætninger

- Docker installeret og kørende på maskinen
- Netværksadgang til dit container-registry
- Adgang til registry med brugernavn og adgangskode/PAT

---

## Trin 1 — Indlæs images fra fil

Begge images skal indlæses:

```bash
docker load < rp-images-airflow-sha-ab4233d.tar.gz
docker load < postgresql-15.tar.gz
```

Efter indlæsning bekræftes image-navnene:

```bash
docker images | grep -E "rp-images-airflow|postgresql"
```

Images er nu tilgængelige lokalt med taggene:
```
registry.admin.dt-poc.projects.systematic-synergy.io/rp/rp-images-airflow@sha256:019c11faf08d8f9b86c0ab5253f077f0fddcb799e7d57f3fe6033a94f13d3423
registry.admin.dt-poc.projects.systematic-synergy.io/rp/postgresql:15
```

---

## Trin 2 — Log ind på dit registry

```bash
docker login <dit-registry>
```

Eksempel:

```bash
docker login registry.admin.dt-poc.projects.systematic-synergy.io
```

Angiv brugernavn og adgangskode/PAT når du bliver bedt om det.

---

## Trin 3 — Omtag images (valgfrit)

Hvis du ønsker at bruge et andet registry eller tagnavn, kan du omtagge begge images:

```bash
docker tag registry.admin.dt-poc.projects.systematic-synergy.io/rp/rp-images-airflow:sha-ab4233d \
  <dit-registry>/<dit-projekt>/rp-images-airflow:<dit-tag>

docker tag registry.admin.dt-poc.projects.systematic-synergy.io/rp/postgresql:15 \
  <dit-registry>/<dit-projekt>/postgresql:<dit-tag>
```

---

## Trin 4 — Push images til registry

Push begge images:

```bash
docker push registry.admin.dt-poc.projects.systematic-synergy.io/rp/rp-images-airflow:sha-ab4233d
docker push registry.admin.dt-poc.projects.systematic-synergy.io/rp/postgresql:15
```

Eller med egne tags fra trin 3:

```bash
docker push <dit-registry>/<dit-projekt>/rp-images-airflow:<dit-tag>
docker push <dit-registry>/<dit-projekt>/postgresql:<dit-tag>
```

---

## Trin 5 — Konfigurer Kubernetes (Helm)

En klar `values-minimal.yaml` er inkluderet på USB-stikket og peger allerede på de korrekte images i registryet. Brug den direkte.

Tilføj først Helm-repositoriet (kræver internetadgang — eller brug et lokalt chart-mirror):

```bash
helm repo add apache-airflow https://airflow.apache.org
helm repo update
```

Hvis dit registry kræver autentificering, skal du oprette en pull-hemmelighed i Kubernetes:

```bash
kubectl create secret docker-registry regcred \
  --docker-server=registry.admin.dt-poc.projects.systematic-synergy.io \
  --docker-username=<brugernavn> \
  --docker-password=<adgangskode-eller-PAT> \
  --namespace=airflow
```

Installér Airflow med den medfølgende values-fil:

```bash
helm upgrade --install airflow apache-airflow/airflow \
  --version 1.19.0 \
  --namespace airflow \
  --create-namespace \
  -f values-minimal.yaml \
  --timeout 10m \
  --wait
```

---

## Fejlfinding

**Image kan ikke indlæses**
Kontrollér at filerne ikke er blevet beskadiget under overførslen:
```bash
gzip -t rp-images-airflow-sha-ab4233d.tar.gz && echo "Airflow OK"
gzip -t postgresql-15.tar.gz && echo "PostgreSQL OK"
```

**Push afvises af registry**
Kontrollér at du er logget ind (`docker login`) og at du har skriveadgang til det pågældende projekt i registryet.

**Kubernetes kan ikke hente image**
Kontrollér at `imagePullSecrets` er konfigureret korrekt, og at hemmeligheden er oprettet i det rigtige namespace.
