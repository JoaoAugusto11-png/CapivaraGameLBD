-- ============================================
-- VIEWS - CAPIVARA GAME
-- ============================================

-- View: Ranking de pontuação por usuário
CREATE OR REPLACE VIEW ranking_usuarios AS
SELECT 
    u.id_usuario,
    u.nome_usuario,
    u.nome_completo,
    COUNT(DISTINCT j.id_jogo) as total_jogos_participados,
    COUNT(DISTINCT CASE WHEN j.vencedor_jogo = u.id_usuario THEN j.id_jogo END) as jogos_vencidos,
    COUNT(DISTINCT CASE WHEN p.vencedor_partida = u.id_usuario THEN p.id_partida END) as partidas_vencidas,
    COALESCE(SUM(pj.pontuacao_total), 0) as pontos_totais_acumulados,
    ROUND(
        CASE WHEN COUNT(DISTINCT j.id_jogo) > 0 
        THEN COUNT(DISTINCT CASE WHEN j.vencedor_jogo = u.id_usuario THEN j.id_jogo END)::DECIMAL / COUNT(DISTINCT j.id_jogo) * 100 
        ELSE 0 END, 2
    ) as percentual_vitorias_jogos,
    ROUND(
        CASE WHEN COUNT(DISTINCT p.id_partida) > 0 
        THEN COUNT(DISTINCT CASE WHEN p.vencedor_partida = u.id_usuario THEN p.id_partida END)::DECIMAL / COUNT(DISTINCT p.id_partida) * 100 
        ELSE 0 END, 2
    ) as percentual_vitorias_partidas,
    u.data_ultimo_acesso
FROM usuarios u
LEFT JOIN participantes_jogo pj ON u.id_usuario = pj.id_usuario
LEFT JOIN jogos j ON pj.id_jogo = j.id_jogo
LEFT JOIN partidas p ON j.id_jogo = p.id_jogo
WHERE u.ativo = TRUE
GROUP BY u.id_usuario, u.nome_usuario, u.nome_completo, u.data_ultimo_acesso
ORDER BY jogos_vencidos DESC, pontos_totais_acumulados DESC;

-- View: Listagem de jogos e vencedores
CREATE OR REPLACE VIEW listagem_jogos AS
SELECT 
    j.id_jogo,
    j.data_inicio,
    j.data_fim,
    j.numero_jogadores,
    j.pontuacao_meta,
    j.status,
    u_vencedor.nome_usuario as vencedor,
    u_vencedor.nome_completo as nome_completo_vencedor,
    COUNT(p.id_partida) as total_partidas,
    CASE 
        WHEN j.numero_jogadores = 4 THEN 'Duplas'
        ELSE 'Individual'
    END as tipo_jogo,
    CASE 
        WHEN j.status = 'finalizado' THEN 
            EXTRACT(EPOCH FROM (j.data_fim - j.data_inicio)) / 60
        ELSE 
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - j.data_inicio)) / 60
    END as duracao_minutos,
    STRING_AGG(DISTINCT u_participante.nome_usuario, ', ' ORDER BY u_participante.nome_usuario) as participantes
FROM jogos j
LEFT JOIN usuarios u_vencedor ON j.vencedor_jogo = u_vencedor.id_usuario
LEFT JOIN partidas p ON j.id_jogo = p.id_jogo
LEFT JOIN participantes_jogo pj ON j.id_jogo = pj.id_jogo
LEFT JOIN usuarios u_participante ON pj.id_usuario = u_participante.id_usuario
GROUP BY j.id_jogo, j.data_inicio, j.data_fim, j.numero_jogadores, 
         j.pontuacao_meta, j.status, u_vencedor.nome_usuario, u_vencedor.nome_completo
ORDER BY j.data_inicio DESC;

-- View: Histórico detalhado de partidas
CREATE OR REPLACE VIEW historico_partidas AS
SELECT 
    p.id_partida,
    j.id_jogo,
    p.numero_partida,
    p.data_inicio,
    p.data_fim,
    u_primeiro.nome_usuario as primeiro_jogador,
    u_vencedor.nome_usuario as vencedor,
    p.tipo_vitoria,
    p.pontos_vencedor,
    p.status,
    COUNT(jog.id_jogada) as total_jogadas,
    CASE 
        WHEN p.status = 'finalizada' THEN 
            EXTRACT(EPOCH FROM (p.data_fim - p.data_inicio)) / 60
        ELSE 
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.data_inicio)) / 60
    END as duracao_minutos
FROM partidas p
JOIN jogos j ON p.id_jogo = j.id_jogo
LEFT JOIN usuarios u_primeiro ON p.primeiro_jogador = u_primeiro.id_usuario
LEFT JOIN usuarios u_vencedor ON p.vencedor_partida = u_vencedor.id_usuario
LEFT JOIN jogadas jog ON p.id_partida = jog.id_partida
GROUP BY p.id_partida, j.id_jogo, p.numero_partida, p.data_inicio, p.data_fim,
         u_primeiro.nome_usuario, u_vencedor.nome_usuario, p.tipo_vitoria, 
         p.pontos_vencedor, p.status
ORDER BY p.data_inicio DESC;

-- View: Estado atual da mesa de jogo
CREATE OR REPLACE VIEW estado_mesa_atual AS
SELECT 
    p.id_partida,
    j.id_jogo,
    p.numero_partida,
    p.status as status_partida,
    mj.extremidade_a as extremidade_esquerda,
    mj.extremidade_b as extremidade_direita,
    COUNT(mj.id_mesa) as pecas_jogadas_mesa,
    mj_ultima.id_usuario as ultimo_jogador,
    u_ultimo.nome_usuario as nome_ultimo_jogador,
    pd_ultima.lado_a as ultimo_lado_a,
    pd_ultima.lado_b as ultimo_lado_b,
    mj_ultima.timestamp_jogada as timestamp_ultima_jogada
FROM partidas p
JOIN jogos j ON p.id_jogo = j.id_jogo
LEFT JOIN mesa_jogo mj ON p.id_partida = mj.id_partida
LEFT JOIN mesa_jogo mj_ultima ON p.id_partida = mj_ultima.id_partida 
    AND mj_ultima.ordem_jogada = (
        SELECT MAX(ordem_jogada) FROM mesa_jogo WHERE id_partida = p.id_partida
    )
LEFT JOIN usuarios u_ultimo ON mj_ultima.id_usuario = u_ultimo.id_usuario
LEFT JOIN pecas_domino pd_ultima ON mj_ultima.id_peca = pd_ultima.id_peca
WHERE p.status = 'em_andamento'
GROUP BY p.id_partida, j.id_jogo, p.numero_partida, p.status,
         mj.extremidade_a, mj.extremidade_b, mj_ultima.id_usuario,
         u_ultimo.nome_usuario, pd_ultima.lado_a, pd_ultima.lado_b,
         mj_ultima.timestamp_jogada
ORDER BY p.data_inicio DESC;

-- View: Estatísticas de jogadores por partida
CREATE OR REPLACE VIEW estatisticas_jogadores_partida AS
SELECT 
    p.id_partida,
    p.numero_partida,
    pj.id_usuario,
    u.nome_usuario,
    COUNT(pp.id_peca) as pecas_na_mao,
    COALESCE(SUM(pd.valor_total), 0) as pontos_na_mao,
    COUNT(jog.id_jogada) as total_jogadas_feitas,
    COUNT(CASE WHEN jog.tipo_jogada = 'passou' THEN 1 END) as vezes_passou,
    COUNT(CASE WHEN jog.tipo_jogada = 'comprou_monte' THEN 1 END) as vezes_comprou_monte,
    COALESCE(SUM(jog.pecas_compradas), 0) as total_pecas_compradas
FROM partidas p
JOIN participantes_jogo pj ON p.id_jogo = pj.id_jogo
JOIN usuarios u ON pj.id_usuario = u.id_usuario
LEFT JOIN pecas_partida pp ON p.id_partida = pp.id_partida 
    AND pj.id_usuario = pp.id_usuario AND pp.status = 'na_mao'
LEFT JOIN pecas_domino pd ON pp.id_peca = pd.id_peca
LEFT JOIN jogadas jog ON p.id_partida = jog.id_partida 
    AND pj.id_usuario = jog.id_usuario
GROUP BY p.id_partida, p.numero_partida, pj.id_usuario, u.nome_usuario
ORDER BY p.id_partida, pj.posicao_mesa;