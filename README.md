# Mamba Fast Tracker Challenge

## 🎯 Objetivo
Avaliar sua habilidade de:
- Construir um app do zero
- Definir uma arquitetura limpa e escalável
- Gerenciar estado e persistência corretamente
- Implementar timers e notificações
- Criar uma boa experiência de usuário
- Entregar um build pronto para distribuição

## 📱 Desafio
Você deverá desenvolver o aplicativo:

**Mamba Fast Tracker**

Um app de controle de jejum intermitente + registro de calorias, semelhante a um produto real disponível na App Store.
O foco é funcionalidade, arquitetura e qualidade, não design complexo.

## ✅ Funcionalidades obrigatórias (MVP)

### 1) Autenticação
- Login simples (email/senha local OU Firebase Auth)
- Persistir sessão do usuário

### 2) Protocolos de jejum
Usuário deve poder:
- Selecionar protocolos pré-definidos:
  - 12:12
  - 16:8
  - 18:6
- Ou criar protocolo customizado

### 3) Timer de jejum (core feature)
- Iniciar jejum
- Pausar/encerrar
- Mostrar tempo restante e decorrido
- Continuar funcionando em background
- Manter estado correto ao fechar/reabrir o app

👉 Essa é a parte mais importante do desafio

### 4) Notificações
Notificação quando:
- jejum iniciar
- jejum terminar

Pode ser:
- local notification (aceito)
- ou Firebase

### 5) Registro de refeições
Usuário pode:
- Adicionar refeição
- Informar:
  - nome
  - calorias
  - horário automático
- Editar/excluir

### 6) Cálculo diário
Exibir:
- total de calorias do dia
- tempo total de jejum
- status (dentro/fora da meta)

### 7) Histórico
- Lista de dias anteriores
- Visualizar resumo de cada dia

### 8) Gráfico simples
Evolução semanal de:
- calorias OU
- tempo de jejum

(pode usar qualquer lib de chart)

### 9) Persistência local
Dados devem ser salvos localmente.

Pode usar:
- SQLite
- Hive
- AsyncStorage
- Realm
- similar

### 🔟 Build Android
Entregar APK ou AAB funcional.

## ⭐ Diferenciais (bônus)
Itens que aumentam sua avaliação:
- Clean Architecture / MVVM / Bloc / Redux / similar
- Testes unitários
- CI/CD
- Firebase Analytics / Crashlytics
- Dark mode
- Offline-first bem implementado
- Feature flags
- Publicação em Play Store (internal test)
- UI bem polida

## 🛠 Stack permitida
Você pode escolher.

## 📦 Entregáveis
Enviar:
- Link do repositório (GitHub/GitLab)
- APK/AAB funcional
- README contendo:
  - Como rodar o projeto
  - Stack escolhida
  - Arquitetura utilizada
  - Decisões técnicas
  - Bibliotecas utilizadas
  - Trade-offs considerados
  - O que melhoraria com mais tempo
  - Tempo gasto no desafio
  - Link para executar o projeto

## ⏱ Prazo
3 a 4 dias corridos após o recebimento.

## 🧠 Critérios de avaliação
Avaliaremos principalmente:
- App funcional e estável
- Código limpo e organizado
- Arquitetura escalável
- Gestão correta de estado e persistência
- Timer funcionando corretamente em background
- UX clara
- Qualidade do README
- Autonomia técnica

## ❌ Evite
- Código desorganizado
- Lógica frágil do timer
- Dados perdidos ao fechar o app
- README vazio
- "Funciona só na minha máquina"

## 💬 Mentalidade esperada
Pense:

"Se esse app fosse publicado amanhã para 10.000 usuários, eu teria orgulho dessa entrega?"

Estamos buscando alguém que construa produtos reais, não apenas features isoladas.
