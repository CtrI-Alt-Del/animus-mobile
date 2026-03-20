.PHONY: dev build clean test release

dev:
	flutter run

prod:
	flutter run --release

format:
	dart format .

build:
	flutter build appbundle --dart-define=ENV_FILE=.env.production

test:
	flutter test

clean:
	flutter clean

VERSION := $(word 2,$(MAKECMDGOALS))

%:
	@:

release:
	@if [ -z "$(VERSION)" ]; then \
		echo "Uso: make release 1.2.3"; \
		exit 1; \
	fi

	@if git rev-parse "v$(VERSION)" >/dev/null 2>&1; then \
		echo "Tag v$(VERSION) ja existe"; \
		exit 1; \
	fi

	@echo "Atualizando versao no pubspec.yaml para $(VERSION)..."
	@sed -i.bak "s/^version: .*/version: $(VERSION)/" pubspec.yaml
	@rm -f pubspec.yaml.bak

	@echo "Fazendo commit da versao..."
	git add pubspec.yaml
	git commit -m "release: version $(VERSION)"

	@echo "Enviando codigo para Github..."
	git push origin

	@echo "Criando tag v$(VERSION)..."
	git tag v$(VERSION)

	@echo "Enviando tag para origin..."
	git push origin v$(VERSION)

	@echo "Release v$(VERSION) publicada com sucesso!"