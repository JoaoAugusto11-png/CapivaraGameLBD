-- ============================================
-- FUNÇÕES DO SISTEMA CAPIVARA GAME
-- ============================================

-- Função para verificar se uma jogada é possível
CREATE OR REPLACE FUNCTION verificar_jogada_possivel(
    p_id_partida INTEGER,
    p_id_usuario INTEGER,
    p_id_peca INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_lado_a INTEGER;
    v_lado_b INTEGER;
    v_extremidade_esq INTEGER;
    v_extremidade_dir INTEGER;
    v_tem_peca BOOLEAN;
BEGIN
    -- Verificar se o usuário possui a peça
    SELECT EXISTS(
        SELECT 1 FROM pecas_partida pp
        WHERE pp.id_partida = p_id_partida 
        AND pp.id_usuario = p_id_usuario 
        AND pp.id_peca = p_id_peca 
        AND pp.status = 'na_mao'
    ) INTO v_tem_peca;
    
    IF NOT v_tem_peca THEN
        RETURN FALSE;
    END IF;
    
    -- Obter valores da peça
    SELECT lado_a, lado_b INTO v_lado_a, v_lado_b
    FROM pecas_domino WHERE id_peca = p_id_peca;
    
    -- Obter extremidades atuais da mesa
    SELECT extremidade_a, extremidade_b INTO v_extremidade_esq, v_extremidade_dir
    FROM mesa_jogo 
    WHERE id_partida = p_id_partida 
    ORDER BY ordem_jogada DESC 
    LIMIT 1;
    
    -- Se não há peças na mesa, qualquer peça pode ser jogada
    IF v_extremidade_esq IS NULL THEN
        RETURN TRUE;
    END IF;
    
    -- Verificar se a peça encaixa em alguma extremidade
    RETURN (v_lado_a = v_extremidade_esq OR v_lado_b = v_extremidade_esq OR
            v_lado_a = v_extremidade_dir OR v_lado_b = v_extremidade_dir);
END;
$$ LANGUAGE plpgsql;

-- Função para detectar jogo trancado
CREATE OR REPLACE FUNCTION detectar_jogo_trancado(p_id_partida INTEGER) 
RETURNS BOOLEAN AS $$
DECLARE
    v_usuario RECORD;
    v_tem_jogada_possivel BOOLEAN := FALSE;
BEGIN
    -- Para cada usuário na partida
    FOR v_usuario IN (
        SELECT DISTINCT pp.id_usuario
        FROM pecas_partida pp
        WHERE pp.id_partida = p_id_partida 
        AND pp.status = 'na_mao'
    ) LOOP
        -- Verificar se tem alguma peça jogável
        SELECT EXISTS(
            SELECT 1 FROM pecas_partida pp
            JOIN pecas_domino pd ON pp.id_peca = pd.id_peca
            WHERE pp.id_partida = p_id_partida
            AND pp.id_usuario = v_usuario.id_usuario
            AND pp.status = 'na_mao'
            AND verificar_jogada_possivel(p_id_partida, v_usuario.id_usuario, pp.id_peca)
        ) INTO v_tem_jogada_possivel;
        
        IF v_tem_jogada_possivel THEN
            RETURN FALSE;
        END IF;
    END LOOP;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Função para obter jogadas possíveis de um usuário
CREATE OR REPLACE FUNCTION obter_jogadas_possiveis(
    p_id_partida INTEGER,
    p_id_usuario INTEGER
) RETURNS TABLE (
    id_peca INTEGER,
    lado_a INTEGER,
    lado_b INTEGER,
    pode_jogar_esq BOOLEAN,
    pode_jogar_dir BOOLEAN
) AS $$
DECLARE
    v_extremidade_esq INTEGER;
    v_extremidade_dir INTEGER;
BEGIN
    -- Obter extremidades atuais da mesa
    SELECT extremidade_a, extremidade_b INTO v_extremidade_esq, v_extremidade_dir
    FROM mesa_jogo 
    WHERE id_partida = p_id_partida 
    ORDER BY ordem_jogada DESC 
    LIMIT 1;
    
    RETURN QUERY
    SELECT 
        pp.id_peca,
        pd.lado_a,
        pd.lado_b,
        CASE 
            WHEN v_extremidade_esq IS NULL THEN TRUE
            ELSE (pd.lado_a = v_extremidade_esq OR pd.lado_b = v_extremidade_esq)
        END as pode_jogar_esq,
        CASE 
            WHEN v_extremidade_dir IS NULL THEN TRUE
            ELSE (pd.lado_a = v_extremidade_dir OR pd.lado_b = v_extremidade_dir)
        END as pode_jogar_dir
    FROM pecas_partida pp
    JOIN pecas_domino pd ON pp.id_peca = pd.id_peca
    WHERE pp.id_partida = p_id_partida
    AND pp.id_usuario = p_id_usuario
    AND pp.status = 'na_mao'
    AND (v_extremidade_esq IS NULL OR 
         pd.lado_a = v_extremidade_esq OR pd.lado_b = v_extremidade_esq OR
         pd.lado_a = v_extremidade_dir OR pd.lado_b = v_extremidade_dir);
END;
$$ LANGUAGE plpgsql;

-- Função para calcular pontos na mão de um jogador
CREATE OR REPLACE FUNCTION calcular_pontos_mao(
    p_id_partida INTEGER,
    p_id_usuario INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_total_pontos INTEGER;
BEGIN
    SELECT COALESCE(SUM(pd.valor_total), 0) INTO v_total_pontos
    FROM pecas_partida pp
    JOIN pecas_domino pd ON pp.id_peca = pd.id_peca
    WHERE pp.id_partida = p_id_partida
    AND pp.id_usuario = p_id_usuario
    AND pp.status = 'na_mao';
    
    RETURN v_total_pontos;
END;
$$ LANGUAGE plpgsql;

-- Função para obter próximo jogador
CREATE OR REPLACE FUNCTION obter_proximo_jogador(
    p_id_partida INTEGER,
    p_id_usuario_atual INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_id_jogo INTEGER;
    v_posicao_atual INTEGER;
    v_proxima_posicao INTEGER;
    v_numero_jogadores INTEGER;
    v_proximo_usuario INTEGER;
BEGIN
    -- Obter informações da partida
    SELECT id_jogo INTO v_id_jogo
    FROM partidas WHERE id_partida = p_id_partida;
    
    -- Obter posição do jogador atual
    SELECT posicao_mesa INTO v_posicao_atual
    FROM participantes_jogo 
    WHERE id_jogo = v_id_jogo AND id_usuario = p_id_usuario_atual;
    
    -- Obter número de jogadores
    SELECT numero_jogadores INTO v_numero_jogadores
    FROM jogos WHERE id_jogo = v_id_jogo;
    
    -- Calcular próxima posição (anti-horário)
    v_proxima_posicao := v_posicao_atual + 1;
    IF v_proxima_posicao > v_numero_jogadores THEN
        v_proxima_posicao := 1;
    END IF;
    
    -- Obter usuário da próxima posição
    SELECT id_usuario INTO v_proximo_usuario
    FROM participantes_jogo 
    WHERE id_jogo = v_id_jogo AND posicao_mesa = v_proxima_posicao;
    
    RETURN v_proximo_usuario;
END;
$$ LANGUAGE plpgsql;