-- ============================================
-- PROCEDIMENTOS ARMAZENADOS - CAPIVARA GAME
-- ============================================

-- Procedimento para comprar peça do monte
CREATE OR REPLACE FUNCTION comprar_peca_monte(
    p_id_partida INTEGER,
    p_id_usuario INTEGER
) RETURNS TABLE (
    sucesso BOOLEAN,
    id_peca_comprada INTEGER,
    mensagem TEXT
) AS $$
DECLARE
    v_peca_disponivel INTEGER;
    v_pecas_monte INTEGER;
BEGIN
    -- Verificar se há peças no monte
    SELECT COUNT(*) INTO v_pecas_monte
    FROM pecas_partida pp
    WHERE pp.id_partida = p_id_partida 
    AND pp.status = 'no_monte';
    
    IF v_pecas_monte = 0 THEN
        RETURN QUERY SELECT FALSE, NULL::INTEGER, 'Monte vazio'::TEXT;
        RETURN;
    END IF;
    
    -- Pegar uma peça aleatória do monte
    SELECT id_peca INTO v_peca_disponivel
    FROM pecas_partida pp
    WHERE pp.id_partida = p_id_partida 
    AND pp.status = 'no_monte'
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Transferir a peça para o jogador
    UPDATE pecas_partida 
    SET id_usuario = p_id_usuario, 
        status = 'na_mao',
        posicao_mao = (
            SELECT COALESCE(MAX(posicao_mao), 0) + 1
            FROM pecas_partida 
            WHERE id_partida = p_id_partida 
            AND id_usuario = p_id_usuario 
            AND status = 'na_mao'
        )
    WHERE id_partida = p_id_partida 
    AND id_peca = v_peca_disponivel 
    AND status = 'no_monte';
    
    -- Atualizar contador do monte
    UPDATE monte_partida 
    SET pecas_restantes = pecas_restantes - 1
    WHERE id_partida = p_id_partida;
    
    RETURN QUERY SELECT TRUE, v_peca_disponivel, 'Peça comprada com sucesso'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Procedimento para validar e executar jogada
CREATE OR REPLACE FUNCTION executar_jogada(
    p_id_partida INTEGER,
    p_id_usuario INTEGER,
    p_id_peca INTEGER,
    p_lado_conectado VARCHAR(10) -- 'esquerda', 'direita'
) RETURNS TABLE (
    sucesso BOOLEAN,
    mensagem TEXT,
    nova_extremidade_a INTEGER,
    nova_extremidade_b INTEGER
) AS $$
DECLARE
    v_pode_jogar BOOLEAN;
    v_lado_a INTEGER;
    v_lado_b INTEGER;
    v_extremidade_esq INTEGER;
    v_extremidade_dir INTEGER;
    v_nova_extremidade_a INTEGER;
    v_nova_extremidade_b INTEGER;
    v_ordem_jogada INTEGER;
    v_valor_conectar INTEGER;
    v_valor_livre INTEGER;
BEGIN
    -- Verificar se a jogada é possível
    SELECT verificar_jogada_possivel(p_id_partida, p_id_usuario, p_id_peca) INTO v_pode_jogar;
    
    IF NOT v_pode_jogar THEN
        RETURN QUERY SELECT FALSE, 'Jogada não é possível'::TEXT, NULL::INTEGER, NULL::INTEGER;
        RETURN;
    END IF;
    
    -- Obter dados da peça
    SELECT lado_a, lado_b INTO v_lado_a, v_lado_b
    FROM pecas_domino WHERE id_peca = p_id_peca;
    
    -- Obter extremidades atuais
    SELECT extremidade_a, extremidade_b INTO v_extremidade_esq, v_extremidade_dir
    FROM mesa_jogo 
    WHERE id_partida = p_id_partida 
    ORDER BY ordem_jogada DESC 
    LIMIT 1;
    
    -- Obter próxima ordem de jogada
    SELECT COALESCE(MAX(ordem_jogada), 0) + 1 INTO v_ordem_jogada
    FROM mesa_jogo WHERE id_partida = p_id_partida;
    
    -- Se é a primeira peça
    IF v_extremidade_esq IS NULL THEN
        v_nova_extremidade_a := v_lado_a;
        v_nova_extremidade_b := v_lado_b;
        p_lado_conectado := 'inicial';
    ELSE
        -- Calcular novas extremidades baseado no lado de conexão
        IF p_lado_conectado = 'esquerda' THEN
            -- Conectar na extremidade esquerda
            IF v_lado_a = v_extremidade_esq THEN
                v_nova_extremidade_a := v_lado_b;
            ELSE
                v_nova_extremidade_a := v_lado_a;
            END IF;
            v_nova_extremidade_b := v_extremidade_dir;
        ELSE
            -- Conectar na extremidade direita
            v_nova_extremidade_a := v_extremidade_esq;
            IF v_lado_a = v_extremidade_dir THEN
                v_nova_extremidade_b := v_lado_b;
            ELSE
                v_nova_extremidade_b := v_lado_a;
            END IF;
        END IF;
    END IF;
    
    -- Inserir na mesa
    INSERT INTO mesa_jogo (
        id_partida, id_peca, id_usuario, ordem_jogada, 
        lado_conectado, extremidade_a, extremidade_b
    ) VALUES (
        p_id_partida, p_id_peca, p_id_usuario, v_ordem_jogada,
        p_lado_conectado, v_nova_extremidade_a, v_nova_extremidade_b
    );
    
    -- Remover peça da mão do jogador
    UPDATE pecas_partida 
    SET status = 'jogada'
    WHERE id_partida = p_id_partida 
    AND id_usuario = p_id_usuario 
    AND id_peca = p_id_peca;
    
    -- Registrar jogada
    INSERT INTO jogadas (id_partida, id_usuario, ordem_turno, tipo_jogada, id_peca)
    VALUES (p_id_partida, p_id_usuario, 
            (SELECT COALESCE(MAX(ordem_turno), 0) + 1 FROM jogadas WHERE id_partida = p_id_partida),
            'jogou_peca', p_id_peca);
    
    RETURN QUERY SELECT TRUE, 'Jogada executada com sucesso'::TEXT, 
                       v_nova_extremidade_a, v_nova_extremidade_b;
END;
$$ LANGUAGE plpgsql;

-- Procedimento para iniciar nova partida
CREATE OR REPLACE FUNCTION iniciar_partida(p_id_jogo INTEGER, p_numero_partida INTEGER)
RETURNS TABLE (
    sucesso BOOLEAN,
    id_partida_criada INTEGER,
    primeiro_jogador INTEGER,
    mensagem TEXT
) AS $$
DECLARE
    v_id_partida INTEGER;
    v_numero_jogadores INTEGER;
    v_primeiro_jogador INTEGER;
    v_usuario RECORD;
    v_peca RECORD;
    v_contador INTEGER := 0;
    v_tem_66 BOOLEAN := FALSE;
BEGIN
    -- Obter número de jogadores
    SELECT numero_jogadores INTO v_numero_jogadores
    FROM jogos WHERE id_jogo = p_id_jogo;
    
    -- Criar nova partida
    INSERT INTO partidas (id_jogo, numero_partida, primeiro_jogador)
    VALUES (p_id_jogo, p_numero_partida, 1) -- Temporário, será atualizado
    RETURNING id_partida INTO v_id_partida;
    
    -- Distribuir peças para cada jogador (7 peças cada)
    FOR v_usuario IN (
        SELECT id_usuario FROM participantes_jogo 
        WHERE id_jogo = p_id_jogo 
        ORDER BY posicao_mesa
    ) LOOP
        v_contador := 0;
        FOR v_peca IN (
            SELECT id_peca FROM pecas_domino 
            ORDER BY RANDOM() 
            LIMIT 7 OFFSET (SELECT COUNT(*) FROM pecas_partida WHERE id_partida = v_id_partida)
        ) LOOP
            v_contador := v_contador + 1;
            INSERT INTO pecas_partida (id_partida, id_peca, id_usuario, posicao_mao, status)
            VALUES (v_id_partida, v_peca.id_peca, v_usuario.id_usuario, v_contador, 'na_mao');
            
            -- Verificar se é a peça 6-6 para definir primeiro jogador
            IF EXISTS(SELECT 1 FROM pecas_domino WHERE id_peca = v_peca.id_peca AND lado_a = 6 AND lado_b = 6) THEN
                v_primeiro_jogador := v_usuario.id_usuario;
                v_tem_66 := TRUE;
            END IF;
        END LOOP;
    END LOOP;
    
    -- Se não tiver 6-6, escolher aleatoriamente
    IF NOT v_tem_66 THEN
        SELECT id_usuario INTO v_primeiro_jogador
        FROM participantes_jogo 
        WHERE id_jogo = p_id_jogo 
        ORDER BY RANDOM() 
        LIMIT 1;
    END IF;
    
    -- Atualizar primeiro jogador
    UPDATE partidas SET primeiro_jogador = v_primeiro_jogador WHERE id_partida = v_id_partida;
    
    -- Colocar peças restantes no monte (para jogos de 2-3 jogadores)
    IF v_numero_jogadores < 4 THEN
        INSERT INTO pecas_partida (id_partida, id_peca, status)
        SELECT v_id_partida, pd.id_peca, 'no_monte'
        FROM pecas_domino pd
        WHERE pd.id_peca NOT IN (
            SELECT id_peca FROM pecas_partida WHERE id_partida = v_id_partida
        );
        
        -- Criar registro do monte
        INSERT INTO monte_partida (id_partida, pecas_restantes)
        VALUES (v_id_partida, (SELECT COUNT(*) FROM pecas_partida WHERE id_partida = v_id_partida AND status = 'no_monte'));
    END IF;
    
    RETURN QUERY SELECT TRUE, v_id_partida, v_primeiro_jogador, 'Partida iniciada com sucesso'::TEXT;
END;
$$ LANGUAGE plpgsql;