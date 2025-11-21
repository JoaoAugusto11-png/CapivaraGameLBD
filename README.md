# 🎮 Capivara Game - Dominó

Sistema de jogo de dominó desenvolvido para o trabalho prático da disciplina de Laboratório de Banco de Dados (LBD).

## 📋 Descrição

O Capivara Game é um sistema completo de jogo de dominó que implementa:
- Sistema de usuários
- Criação e gerenciamento de jogos (2, 3 ou 4 jogadores)
- Partidas com regras completas do dominó
- Sistema de pontuação e rankings
- Banco de dados PostgreSQL com triggers, procedures e views
- Interface via linha de comando

## 🔧 Pré-requisitos

- **PostgreSQL 12+** instalado e rodando
- **Python 3.8+**
- **pip** (gerenciador de pacotes do Python)

## 🚀 Instalação RÁPIDA (VS Code)

### ⚡ Opção 1: Configuração Automática (RECOMENDADO)
Execute este comando no terminal do VS Code:
```bash
python setup_auto.py
```
Este script irá:
- Encontrar sua instalação do PostgreSQL automaticamente
- Configurar o encoding para UTF-8
- Criar o banco `capivara_game`
- Instalar dependências Python
- Testar a conexão

### ⚡ Opção 2: Configuração Manual
Se preferir fazer passo a passo:

1. **Instale as dependências Python**:
   ```bash
   pip install psycopg2-binary
   ```

2. **Configure o PostgreSQL** (no terminal do VS Code):
   ```bash
   # Encontre onde está o PostgreSQL instalado
   # Exemplo comum: C:\Program Files\PostgreSQL\15\bin\psql.exe
   
   # Execute o script de configuração
   "C:\Program Files\PostgreSQL\15\bin\psql.exe" -U postgres -f setup_temp.sql
   ```

## ▶️ Execução

Para iniciar o sistema:
```bash
python capivara_lbd_final.py
```

## 📖 Como usar

1. **Configurar PostgreSQL**: Na primeira execução, configure a conexão
2. **Gerenciar Usuários**: Cadastre usuários no sistema
3. **Simular Partidas**: Use a funcionalidade completa de simulação
4. **Relatórios**: Visualize estatísticas e histórico completo
4. **Rankings**: Veja estatísticas dos jogadores em "Ver Rankings"

## 🗂️ Estrutura do Projeto

```
TrabLBD/
├── src/
│   ├── capivara_game.py    # Aplicação principal
│   └── config.py           # Configurações
├── sql/
│   ├── 00_setup_complete.sql    # Setup completo (recomendado)
│   ├── 01_create_database.sql   # Criação do banco
│   ├── 02_create_tables.sql     # Estrutura das tabelas
│   ├── 03_create_functions.sql  # Funções PL/pgSQL
│   ├── 04_create_procedures.sql # Procedimentos armazenados
│   ├── 05_create_triggers.sql   # Triggers
│   ├── 06_create_views.sql      # Views
│   └── 07_populate_data.sql     # Dados iniciais
├── docs/
│   ├── relatorio_tecnico.md     # Relatório técnico
│   └── diagrama_er.md           # Diagrama ER
├── requirements.txt             # Dependências Python
└── README.md                   # Este arquivo
```

## 🎯 Funcionalidades Implementadas

### Regras de Negócio no Banco
- ✅ **Triggers**: Cálculo automático de pontos
- ✅ **Procedures**: Validação de jogadas, compra de peças
- ✅ **Functions**: Verificação de jogadas possíveis, detecção de jogo trancado
- ✅ **Views**: Rankings, histórico de partidas, estado das mesas

### Sistema Completo
- ✅ Cadastro e gerenciamento de usuários
- ✅ Criação de jogos (2, 3 ou 4 jogadores)
- ✅ Sistema de duplas (jogos de 4 pessoas)
- ✅ Distribuição automática de peças
- ✅ Histórico completo de movimentações
- ✅ Sistema de pontuação (meta de 50 pontos)
- ✅ Rankings e relatórios detalhados

## 🔍 Solução de Problemas

### Erro de conexão com PostgreSQL
- Verifique se o PostgreSQL está rodando
- Confirme as credenciais no arquivo `config.py`
- Teste a conexão: `psql -U postgres -d capivara_game`

### Erro "psycopg2 not found"
```bash
pip install psycopg2-binary
```

### Banco não existe
Execute o script de criação:
```bash
psql -U postgres -f sql/01_create_database.sql
```

## 👥 Equipe

**[Nome dos integrantes]**
- Integrante 1 - RGA: [RGA] - [email]
- Integrante 2 - RGA: [RGA] - [email] 
- Integrante 3 - RGA: [RGA] - [email]

**Curso**: [Nome do curso]  
**Disciplina**: Laboratório de Banco de Dados  
**Professor**: Prof. Márcio Inácio  
**Data**: Novembro/2025

---

## 📄 Licença

Este projeto foi desenvolvido para fins acadêmicos como parte do trabalho prático da disciplina LBD.