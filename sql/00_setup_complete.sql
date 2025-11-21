-- ============================================
-- SCRIPT PRINCIPAL - CAPIVARA GAME
-- Execute este arquivo para criar todo o banco
-- ============================================

-- IMPORTANTE: Execute primeiro o arquivo 01_create_database.sql
-- para criar o banco, depois execute este arquivo
-- conectado ao banco capivara_game

\echo 'Iniciando criação das tabelas...'
\i 02_create_tables.sql

\echo 'Criando funções...'  
\i 03_create_functions.sql

\echo 'Criando procedimentos...'
\i 04_create_procedures.sql

\echo 'Criando triggers...'
\i 05_create_triggers.sql

\echo 'Criando views...'
\i 06_create_views.sql

\echo 'Povoando dados iniciais...'
\i 07_populate_data.sql

\echo 'Banco de dados Capivara Game criado com sucesso!'
\echo 'Execute o arquivo Python src/capivara_game.py para iniciar o jogo.'