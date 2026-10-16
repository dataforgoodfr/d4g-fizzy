# syntax=docker/dockerfile:1.7
# check=error=true
#
# Fizzy pour Data For Good : Fizzy amont à un commit épinglé, plus la gem
# fizzy-oidc (SSO Keycloak, membres créés avant leur premier login).
#
# C'est le Dockerfile de production de Fizzy, avec une seule différence : la
# source vient d'un `ADD` du dépôt amont, et la gem est ajoutée au Gemfile avant
# le `bundle install`. Rien d'autre n'est modifié.
#
# Les deux épingles vont ensemble. fizzy-oidc remplace cinq contrôleurs de
# Fizzy et vise un commit précis (son AGENTS.md) : monter FIZZY_REF sans relire
# cette liste, c'est un login qui casse en silence.

ARG RUBY_VERSION=3.4.8
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 libssl-dev && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Le commit de Fizzy que fizzy-oidc a relu (AGENTS.md de fizzy-oidc).
ARG FIZZY_REF=3068c2a74da2e6d1cba38e7cf15b0dc158dbf2fe
ADD --keep-git-dir=false https://github.com/basecamp/fizzy.git#${FIZZY_REF} /rails

# Un commit de pagbrl/fizzy-oidc, jamais une branche : la même image se
# reconstruit à l'identique.
ARG FIZZY_OIDC_REF=4a20c120e5116a74bf362f8f21b7dc9ed84d81a0
RUN echo "gem \"fizzy-oidc\", github: \"pagbrl/fizzy-oidc\", ref: \"${FIZZY_OIDC_REF}\"" >> Gemfile && \
    BUNDLE_DEPLOYMENT=0 BUNDLE_FROZEN=0 bundle lock && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile && \
    bundle exec bootsnap precompile -j 1 app/ lib/

# La gem lit sa configuration OIDC au démarrage de Rails, précompilation
# comprise : des valeurs factices ici, les vraies viennent du Deployment.
RUN SECRET_KEY_BASE_DUMMY=1 \
    FIZZY_OIDC_ISSUER=https://build.invalid FIZZY_OIDC_CLIENT_ID=build FIZZY_OIDC_CLIENT_SECRET=build \
    ./bin/rails assets:precompile

FROM base

LABEL org.opencontainers.image.source="https://github.com/dataforgoodfr/d4g-fizzy"
LABEL org.opencontainers.image.description="Fizzy avec la gem fizzy-oidc, pour Data For Good"
LABEL org.opencontainers.image.licenses="O'Saasy"

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

# Celui de Fizzy : `db:prepare` au démarrage du serveur, migrations de la gem
# comprises (son engine les ajoute au chemin des migrations).
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
