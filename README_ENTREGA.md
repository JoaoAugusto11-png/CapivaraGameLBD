# 🎮 CAPIVARA GAME LBD
**Sistema de Gerenciamento de Jogos de Dominó - Laboratório de Banco de Dados**

---

## 📖 DESCRIÇÃO DO PROJETO

O Capivara Game é um sistema completo de gerenciamento de jogos de dominó desenvolvido para a disciplina de Laboratório de Banco de Dados. O sistema implementa:

- 🎯 **CRUD completo** para usuários e jogos
- 🎮 **Simulação de partidas** de dominó
- 📊 **Relatórios e estatísticas** detalhadas  
- 💾 **Sistema híbrido** PostgreSQL + JSON
- 📜 **Log completo** de operações SQL
- 🔧 **Interface interativa** via terminal

---

## 🛠️ REQUISITOS DO SISTEMA

### **Software Necessário:**
- **Python 3.8+** (testado em 3.13.5)
- **PostgreSQL 12+** (testado em versões 16 e 17)
- **Sistema Operacional:** Windows, Linux ou macOS

### **Dependências Python:**
```bash
# Instaladas automaticamente, mas se necessário:
pip install -r requirements.txt
```

---

## 🚀 INSTRUÇÕES DE INSTALAÇÃO E EXECUÇÃO

### **1. PREPARAÇÃO DO AMBIENTE**

#### **Windows:**
```powershell
# 1. Clone ou baixe o projeto
cd C:\Users\[SEU_USUARIO]\TrabLBD

# 2. Verifique se Python está instalado
python --version

# 3. Verifique se PostgreSQL está acessível
# Tente uma dessas portas: 5432, 5433
```

#### **Linux/macOS:**
```bash
# 1. Navegue até o diretório do projeto
cd /caminho/para/TrabLBD

# 2. Verifique Python
python3 --version

# 3. Verifique PostgreSQL
psql --version
```

### **2. CONFIGURAÇÃO DO BANCO DE DADOS**

#### **Opção A: Script Automático (Recomendado)**
```sql
-- 1. Conecte ao PostgreSQL como superusuário
psql -U postgres -h localhost -p 5433

-- 2. Execute o script completo
\i sql/SCRIPT_COMPLETO_CRIACAO_POVOAMENTO.sql

-- 3. Desconecte
\q
```

#### **Opção B: Configuração Manual**
```sql
-- 1. Criar banco
CREATE DATABASE capivara_game;

-- 2. Conectar ao banco
\c capivara_game;

-- 3. Executar scripts na ordem
\i sql/02_create_tables.sql
\i sql/03_create_functions.sql
\i sql/04_create_procedures.sql
\i sql/05_create_triggers.sql
\i sql/06_create_views.sql
\i sql/07_populate_data.sql
```

#### **Opção C: Sem PostgreSQL**
```
O sistema funciona 100% sem PostgreSQL usando JSON!
Apenas execute o Python diretamente.
```

### **3. EXECUÇÃO DO SISTEMA**

```bash
# Execute o sistema principal
python capivara_lbd_final.py
```

### **4. PRIMEIRA CONFIGURAÇÃO**

Ao executar pela primeira vez:

1. **Sistema detecta PostgreSQL automaticamente**
2. **Digite a senha quando solicitado** (geralmente: `senha` ou `postgres`)
3. **Escolha configurar PostgreSQL se disponível** (recomendado)
4. **Sistema cria estrutura automaticamente**

---

## 🎯 COMO USAR O SISTEMA

### **Menu Principal:**
```
1. 👤 Gerenciar Usuários    - CRUD de usuários
2. 🎯 Gerenciar Jogos      - CRUD de jogos e simulação
3. 📊 Relatórios SQL       - Consultas e estatísticas  
4. 💾 Backup               - Exportação de dados
5. 🔧 Configurações        - Status e configuração do banco
6. 📜 Ver Log SQL          - Auditoria de comandos
7. 🚪 Sair                 - Encerrar sistema
```

### **Funcionalidades Principais:**

#### **Gerenciar Usuários:**
- ➕ Criar novos usuários
- 📋 Listar usuários cadastrados
- 🔍 Buscar usuários
- 📈 Ver estatísticas

#### **Gerenciar Jogos:**
- 🎮 Criar jogos (2, 3 ou 4 jogadores)
- 📋 Listar jogos criados
- 🏆 **Simular partidas completas** (destaque!)
- 📊 Estatísticas de jogos

#### **Relatórios SQL:**
- 📊 Usuários ativos
- 🎯 Jogos por modalidade
- 🏆 Ranking de pontuação
- 📅 Histórico temporal

---

## 🗄️ ESTRUTURA DO BANCO DE DADOS

### **Tabelas Principais:**

#### **USUARIOS**
```sql
- id_usuario (PK, SERIAL)
- nome_usuario (VARCHAR, UNIQUE)  
- nome_completo (VARCHAR)
- email (VARCHAR, UNIQUE)
- senha_hash (VARCHAR)
- data_cadastro (TIMESTAMP)
- ativo (BOOLEAN)
```

#### **JOGOS**
```sql
- id_jogo (PK, SERIAL)
- numero_jogadores (INTEGER 2-4)
- data_inicio/data_fim (TIMESTAMP)
- status (VARCHAR: em_andamento/finalizado/cancelado)
- pontos_meta (INTEGER, default 50)
- vencedor_id (FK usuarios)
```

#### **PARTICIPANTES_JOGO**
```sql
- id_participante (PK, SERIAL)
- id_jogo (FK jogos)
- id_usuario (FK usuarios)  
- posicao_mesa (INTEGER 1-4)
- pontos_acumulados (INTEGER)
```

### **Funcionalidades Avançadas:**
- ✅ **Triggers** de validação automática
- ✅ **Functions** para cálculos estatísticos
- ✅ **Procedures** para operações complexas
- ✅ **Views** para consultas otimizadas
- ✅ **Índices** de performance
- ✅ **Log de auditoria** completo

---

## 📁 ESTRUTURA DE ARQUIVOS

```
TrabLBD/
├── 📄 README.md                                    # Este arquivo
├── 📄 RELATORIO_TECNICO_LBD.md                     # Relatório acadêmico
├── 📄 SCRIPT_APRESENTACAO_LBD.md                   # Script para vídeo
├── 📄 ENTREGA_PROFESSOR.md                         # Guia de entrega
├── 🐍 capivara_lbd_final.py                        # Sistema principal
├── 📄 requirements.txt                             # Dependências Python
├── 📁 sql/
│   ├── 📄 SCRIPT_COMPLETO_CRIACAO_POVOAMENTO.sql   # ⭐ SCRIPT PRINCIPAL
│   ├── 📄 02_create_tables.sql                     # Criação de tabelas
│   ├── 📄 03_create_functions.sql                  # Funções SQL
│   ├── 📄 04_create_procedures.sql                 # Procedimentos
│   ├── 📄 05_create_triggers.sql                   # Triggers
│   ├── 📄 06_create_views.sql                      # Views
│   └── 📄 07_populate_data.sql                     # Dados iniciais
├── 📁 data/
│   ├── 📄 usuarios.json                            # Dados de usuários
│   ├── 📄 jogos.json                               # Dados de jogos
│   └── 📄 sql_commands.sql                         # Log SQL
└── 📄 MODELO_ER_CAPIVARA.md                        # Documentação do modelo
```

---

## 🔧 CONFIGURAÇÕES TÉCNICAS

### **Configurações PostgreSQL:**
- **Host:** localhost
- **Porta padrão:** 5433 (fallback: 5432)
- **Usuário:** postgres
- **Senha:** será solicitada (normalmente: `senha`)
- **Banco:** capivara_game

### **Arquivos de Configuração:**
- **Dados JSON:** `data/` (backup automático)
- **Log SQL:** `data/sql_commands.sql`
- **Encoding:** UTF-8

---

## 🚨 SOLUÇÃO DE PROBLEMAS

### **Erro de Conexão PostgreSQL:**
```bash
# 1. Verifique se PostgreSQL está rodando
# Windows: Services → PostgreSQL
# Linux: sudo systemctl status postgresql

# 2. Teste conexão manual
psql -U postgres -h localhost -p 5433

# 3. Se não funcionar, sistema usa JSON automaticamente
```

### **Erro de Encoding:**
```bash
# No Windows, execute:
set PGCLIENTENCODING=LATIN1
python capivara_lbd_final.py
```

### **Permissões de Arquivo:**
```bash
# Se não conseguir criar arquivos:
chmod +w data/
```

### **Sistema Funciona Sem PostgreSQL:**
O sistema possui **fallback automático** para JSON. Todas as funcionalidades trabalham normalmente mesmo sem banco configurado.

---

## 📊 DEMONSTRAÇÃO RÁPIDA

### **Teste Completo em 5 Minutos:**

```bash
# 1. Execute o sistema
python capivara_lbd_final.py

# 2. Configure PostgreSQL (se disponível)
# Menu 5 → Reconfigurar PostgreSQL

# 3. Crie um usuário
# Menu 1 → 2 → Nome: teste / Email: teste@exemplo.com

# 4. Simule uma partida
# Menu 2 → 3 → 2 jogadores

# 5. Veja os relatórios
# Menu 3 (consultas SQL)

# 6. Verifique o log
# Menu 6 (comandos SQL executados)
```

---

## 📈 FUNCIONALIDADES ACADÊMICAS

### **Conceitos de LBD Implementados:**
- ✅ **Modelagem ER** completa e normalizada
- ✅ **DDL/DML** com constraints avançadas
- ✅ **Procedures e Functions** em PL/pgSQL
- ✅ **Triggers** de validação e auditoria
- ✅ **Views** para consultas complexas
- ✅ **Índices** para otimização
- ✅ **Transações** e controle de concorrência
- ✅ **Integridade referencial** rigorosa

### **Diferenciais do Projeto:**
- 🔥 **Sistema híbrido** PostgreSQL + JSON
- 🔥 **Detecção automática** de ambiente
- 🔥 **Interface interativa** completa
- 🔥 **Simulação realística** de jogos
- 🔥 **Log completo** de auditoria
- 🔥 **Documentação profissional**

---

## 🏆 CONCLUSÃO

O **Capivara Game** demonstra domínio completo dos conceitos de Laboratório de Banco de Dados, oferecendo:

- 📚 **Solução academicamente sólida**
- 💻 **Sistema production-ready**
- 🎮 **Interface funcional e intuitiva**  
- 📊 **Relatórios gerenciais completos**
- 🔧 **Arquitetura robusta e escalável**

**Status:** ✅ **PRONTO PARA ENTREGA E APRESENTAÇÃO**

---

## 📞 INFORMAÇÕES TÉCNICAS

- **Desenvolvido em:** Python 3.13.5
- **Banco de Dados:** PostgreSQL 17
- **Arquitetura:** Sistema híbrido com fallback
- **Paradigma:** Orientado a objetos com programação procedural
- **Padrão:** MVC simplificado para ambiente acadêmico

**Este sistema atende integralmente aos requisitos da disciplina LBD!** 🎯