# d4g-fizzy

L'image Fizzy de Data For Good : [Fizzy](https://github.com/basecamp/fizzy) à un
commit épinglé, avec la gem [fizzy-oidc](https://github.com/pagbrl/fizzy-oidc)
— connexion par Keycloak seulement, et des membres que le community-manager crée
avant leur premier login.

- Image : `ghcr.io/dataforgoodfr/d4g-fizzy:sha-<commit>`, construite à chaque
  push sur `main` qui touche le `Dockerfile` (`.github/workflows/image.yml`).
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
