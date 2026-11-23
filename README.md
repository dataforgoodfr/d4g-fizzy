# d4g-fizzy

L'image Fizzy de Data For Good : [Fizzy](https://github.com/basecamp/fizzy) à un
commit épinglé, avec la gem [fizzy-oidc](https://source.dataforgood.fr/dataforgoodfr/fizzy-oidc)
— connexion par Keycloak seulement, et des membres que le community-manager crée
avant leur premier login.

- Source : `source.dataforgood.fr/dataforgoodfr/d4g-fizzy` (Forgejo) ; GitHub
  n'en est qu'un miroir, qui refuse les push directs (DCM2-189).
- Image : `registry.infra.dataforgood.fr/dataforgoodfr/d4g-fizzy:sha-<commit>`
  (zot), construite par Woodpecker (ci.dataforgood.fr, `.woodpecker.yaml`) à
  chaque push sur `main`. Les anciens tags `ghcr.io/dataforgoodfr/d4g-fizzy`
  restent lisibles pour un rollback.
- Déploiement : `d4g-gitops`, `base/fizzy` et `overlays/staging/fizzy`. La
  configuration de la gem (`fizzy_oidc.yml`, le groupe admin) est là-bas, pas
  dans l'image.
- Client OIDC `fizzy` : `d4g-keycloak`, `terraform/modules/realm/clients-apps.tf`.
- Un nouveau board n'est visible que de son créateur (Fizzy amont l'ouvre à tout
  le compte) : un initializer écrit par le `Dockerfile`
  (`config/initializers/d4g_private_boards.rb`) surcharge
  `BoardsController#board_params` à la création. Un `all_access` explicite
  (l'API, le community-manager) passe tel quel.

## Monter une version

`FIZZY_REF` et `FIZZY_OIDC_REF` vont ensemble : fizzy-oidc remplace cinq
contrôleurs de Fizzy et vise un commit précis. Monter Fizzy, c'est d'abord
monter l'épingle de fizzy-oidc (sa liste de contrôle est dans son `AGENTS.md`),
puis reporter les deux commits ici. Vérifier au passage que
`BoardsController#board_params` existe toujours en amont : l'initializer des
boards privés le surcharge, et s'il disparaît la surcharge ne fait plus rien.

## Construire à la main

```
docker build -t d4g-fizzy .
```
