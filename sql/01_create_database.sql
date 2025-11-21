-- ============================================
-- TRABALHO PRÁTICO - LABORATÓRIO DE BASE DE DADOS
-- SISTEMA: CAPIVARA GAME - DOMINÓ
-- SGBD: PostgreSQL 12+
-- ============================================

-- Criação do banco de dados
CREATE DATABASE capivara_game;

-- Conectar ao banco
\c capivara_game;

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";