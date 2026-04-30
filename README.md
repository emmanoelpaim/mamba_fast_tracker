# Mamba Fast Tracker

Aplicativo mobile para acompanhamento de jejum intermitente, metas e registro de refeições/calorias.

## Como rodar o projeto

### Pré-requisitos
- Flutter SDK 3.10.8+
- Dart SDK compatível com o Flutter
- Android Studio ou VS Code com plugins Flutter/Dart
- Emulador Android ou dispositivo físico
- Projeto Firebase configurado para Android

### Passos
```bash
flutter pub get
flutter run
```

### Build Android
```bash
flutter build apk --release
```

## Stack escolhida

- Flutter + Dart
- Firebase (Auth, Firestore, Analytics, Crashlytics, Remote Config)
- Gerenciamento de estado com Bloc/Cubit
- Injeção de dependência com GetIt
- Navegação com GoRouter
- Persistência local com SharedPreferences

## Arquitetura utilizada

- Clean Architecture orientada por features
- Separação em camadas: Presentation, Domain e Data
- MVVM no fluxo de apresentação com Bloc como camada de estado
- Repositórios para abstração entre fontes remotas e locais
- Módulos de DI para composição e desacoplamento dos componentes

## Decisões técnicas

- Uso de Firebase para acelerar autenticação, persistência cloud e observabilidade
- Bloc para previsibilidade de estados, testabilidade e manutenção
- Estratégia offline-first com fallback/local cache e fila de sincronização persistente
- Remote Config para habilitar ajustes sem necessidade de nova publicação
- Notificações locais para eventos de jejum em background

## Funcionalidades e UX recentes

- **Splash:** logo do app (`assets/images/logo.webp`), atraso de 3 segundos antes de iniciar o fluxo de autenticação/flags
- **Login e cadastro:** campos de senha com alternância de visibilidade (ícone de olho); no cadastro, regras de senha (mínimo 8 caracteres, maiúscula, caractere especial), medidor de força e validação antes de enviar; política em `lib/features/auth/domain/password_policy.dart` com testes em `test/features/auth/domain/password_policy_test.dart`
- **Recuperação de senha:** layout alinhado ao restante do fluxo de auth
- **Launcher (Android/iOS):** geração de ícones a partir de `assets/images/icon.png` via `flutter_launcher_icons` no `pubspec.yaml` (executar `dart run flutter_launcher_icons` após trocar a imagem)
- **Navegação principal (Home):** aba **Histórico** na primeira posição e **Config.** na última; rótulo curto da configuração para evitar truncamento no menu inferior
- **Títulos no corpo das abas:** **Histórico**, **Refeições** e **Configuração** aparecem como cabeçalho dentro da página; AppBar sem título nas abas correspondentes para ganhar espaço visual
- **Calorias:** teto de **30.000 kcal** para meta diária e por refeição (`lib/core/constants/input_limits.dart`); alerta ao tentar salvar acima do limite; `GoalsCubit` limita persistência ao mesmo teto

## Bibliotecas utilizadas

- `flutter_bloc` e `bloc`
- `equatable`
- `go_router`
- `get_it`
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_analytics`
- `firebase_crashlytics`
- `firebase_remote_config`
- `shared_preferences`
- `flutter_local_notifications`
- `timezone`
- `flutter_timezone`
- `fl_chart`
- Testes: `flutter_test`, `integration_test`, `bloc_test`, `mocktail`
- Dev (ícones): `flutter_launcher_icons`

## Trade-offs considerados

- SharedPreferences simplifica o armazenamento local, mas limita consultas mais complexas em comparação a SQLite/Hive
- Firebase reduz tempo de desenvolvimento, mas aumenta acoplamento com o ecossistema Google
- Bloc traz organização e previsibilidade, porém exige mais boilerplate
- Foco no MVP priorizou robustez funcional sobre refinamentos visuais avançados

## O que melhoraria com mais tempo

- Aumentar cobertura de testes de integração e cenários offline/online
- Evoluir persistência local para banco estruturado com estratégia de migração
- Melhorar telemetria com dashboards de produto e funil de eventos
- Refinar UX/UI com mais microinterações e estados de carregamento/erro
- Expandir feature flags para rollout progressivo de funcionalidades

## Tempo gasto no desafio

- Aproximadamente 3 a 4 dias corridos

## Link para executar o projeto

- Repositório: `https://github.com/emmanoelpaim/mamba_fast_tracker`
- APK/AAB (release): `https://github.com/emmanoelpaim/mamba_fast_tracker/releases`
