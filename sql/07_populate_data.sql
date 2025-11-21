-- ============================================
-- POVOAMENTO INICIAL - CAPIVARA GAME
-- ============================================

-- Inserir todas as peças do dominó (0-0 até 6-6)
INSERT INTO pecas_domino (lado_a, lado_b) VALUES
    (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6),
    (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6),
    (2, 2), (2, 3), (2, 4), (2, 5), (2, 6),
    (3, 3), (3, 4), (3, 5), (3, 6),
    (4, 4), (4, 5), (4, 6),
    (5, 5), (5, 6),
    (6, 6);

-- Inserir usuários de exemplo
INSERT INTO usuarios (nome_usuario, nome_completo, email, senha_hash) VALUES
    ('player1', 'João Silva', 'joao.silva@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewGxPPkrjFrX9xOO'),
    ('player2', 'Maria Santos', 'maria.santos@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewGxPPkrjFrX9xOO'),
    ('player3', 'Pedro Oliveira', 'pedro.oliveira@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewGxPPkrjFrX9xOO'),
    ('player4', 'Ana Costa', 'ana.costa@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewGxPPkrjFrX9xOO'),
    ('player5', 'Carlos Pereira', 'carlos.pereira@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewGxPPkrjFrX9xOO'),
    ('player6', 'Luiza Ferreira', 'luiza.ferreira@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewGxPPkrjFrX9xOO');

-- Criar alguns jogos de exemplo

-- Jogo 1: 2 jogadores (João vs Maria)
INSERT INTO jogos (numero_jogadores, status) VALUES (2, 'em_andamento');

INSERT INTO participantes_jogo (id_jogo, id_usuario, posicao_mesa, pontuacao_total) VALUES
    (1, 1, 1, 0),  -- João
    (1, 2, 2, 0);  -- Maria

-- Jogo 2: 4 jogadores em duplas
INSERT INTO jogos (numero_jogadores, status) VALUES (4, 'em_andamento');

INSERT INTO participantes_jogo (id_jogo, id_usuario, posicao_mesa, dupla, pontuacao_total) VALUES
    (2, 3, 1, 1, 0),  -- Pedro (Dupla 1)
    (2, 4, 2, 2, 0),  -- Ana (Dupla 2)
    (2, 5, 3, 1, 0),  -- Carlos (Dupla 1)
    (2, 6, 4, 2, 0);  -- Luiza (Dupla 2)

-- Jogo 3: Jogo finalizado para demonstrar histórico
INSERT INTO jogos (numero_jogadores, status, data_inicio, data_fim, vencedor_jogo) VALUES 
    (2, 'finalizado', CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '1 hour', 1);

INSERT INTO participantes_jogo (id_jogo, id_usuario, posicao_mesa, pontuacao_total) VALUES
    (3, 1, 1, 52),  -- João (vencedor)
    (3, 3, 2, 34);  -- Pedro

-- Criar algumas partidas de exemplo no jogo finalizado
INSERT INTO partidas (id_jogo, numero_partida, primeiro_jogador, vencedor_partida, tipo_vitoria, pontos_vencedor, status, data_inicio, data_fim) VALUES
    (3, 1, 1, 1, 'batida', 18, 'finalizada', CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '110 minutes'),
    (3, 2, 3, 1, 'trancamento', 15, 'finalizada', CURRENT_TIMESTAMP - INTERVAL '105 minutes', CURRENT_TIMESTAMP - INTERVAL '90 minutes'),
    (3, 3, 1, 1, 'batida', 19, 'finalizada', CURRENT_TIMESTAMP - INTERVAL '85 minutes', CURRENT_TIMESTAMP - INTERVAL '65 minutes');

-- Verificar integridade dos dados inseridos
DO $$
DECLARE
    v_total_pecas INTEGER;
    v_total_usuarios INTEGER;
    v_total_jogos INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_total_pecas FROM pecas_domino;
    SELECT COUNT(*) INTO v_total_usuarios FROM usuarios WHERE ativo = TRUE;
    SELECT COUNT(*) INTO v_total_jogos FROM jogos;
    
    RAISE NOTICE 'Povoamento concluído:';
    RAISE NOTICE '- % peças de dominó inseridas', v_total_pecas;
    RAISE NOTICE '- % usuários cadastrados', v_total_usuarios;
    RAISE NOTICE '- % jogos criados', v_total_jogos;
    
    IF v_total_pecas != 28 THEN
        RAISE EXCEPTION 'Erro: Deveria ter exatamente 28 peças, encontrado %', v_total_pecas;
    END IF;
END $$;