-- ============================================
-- TRIGGERS - CAPIVARA GAME
-- ============================================

-- Trigger para calcular pontos automaticamente ao finalizar partida
CREATE OR REPLACE FUNCTION calcular_pontos_partida()
RETURNS TRIGGER AS $$
DECLARE
    v_id_jogo INTEGER;
    v_numero_jogadores INTEGER;
    v_pontos_adversarios INTEGER := 0;
    v_pontos_dupla1 INTEGER := 0;
    v_pontos_dupla2 INTEGER := 0;
    v_dupla_vencedora INTEGER;
    v_usuario RECORD;
BEGIN
    -- Só executar quando status muda para 'finalizada'
    IF NEW.status = 'finalizada' AND OLD.status != 'finalizada' THEN
        
        SELECT id_jogo, numero_jogadores INTO v_id_jogo, v_numero_jogadores
        FROM partidas p JOIN jogos j ON p.id_jogo = j.id_jogo
        WHERE p.id_partida = NEW.id_partida;
        
        -- Para jogos de 2-3 jogadores
        IF v_numero_jogadores <= 3 THEN
            -- Calcular pontos dos adversários
            SELECT COALESCE(SUM(calcular_pontos_mao(NEW.id_partida, pj.id_usuario)), 0) 
            INTO v_pontos_adversarios
            FROM participantes_jogo pj
            WHERE pj.id_jogo = v_id_jogo 
            AND pj.id_usuario != NEW.vencedor_partida;
            
            -- Atualizar pontos do vencedor
            UPDATE NEW SET pontos_vencedor = v_pontos_adversarios;
            
            -- Atualizar pontuação total do jogador
            UPDATE participantes_jogo 
            SET pontuacao_total = pontuacao_total + v_pontos_adversarios
            WHERE id_jogo = v_id_jogo AND id_usuario = NEW.vencedor_partida;
            
        -- Para jogos de 4 jogadores (duplas)
        ELSE
            -- Calcular pontos de cada dupla
            SELECT COALESCE(SUM(calcular_pontos_mao(NEW.id_partida, pj.id_usuario)), 0) 
            INTO v_pontos_dupla1
            FROM participantes_jogo pj
            WHERE pj.id_jogo = v_id_jogo AND pj.dupla = 1;
            
            SELECT COALESCE(SUM(calcular_pontos_mao(NEW.id_partida, pj.id_usuario)), 0) 
            INTO v_pontos_dupla2
            FROM participantes_jogo pj
            WHERE pj.id_jogo = v_id_jogo AND pj.dupla = 2;
            
            -- Determinar dupla vencedora
            IF NEW.tipo_vitoria = 'batida' THEN
                -- Quem bateu leva todos os pontos dos adversários
                SELECT dupla INTO v_dupla_vencedora
                FROM participantes_jogo 
                WHERE id_jogo = v_id_jogo AND id_usuario = NEW.vencedor_partida;
                
                IF v_dupla_vencedora = 1 THEN
                    v_pontos_adversarios := v_pontos_dupla2;
                ELSE
                    v_pontos_adversarios := v_pontos_dupla1;
                END IF;
                
            ELSE -- trancamento
                -- Dupla com menos pontos ganha os pontos da outra dupla
                IF v_pontos_dupla1 < v_pontos_dupla2 THEN
                    v_dupla_vencedora := 1;
                    v_pontos_adversarios := v_pontos_dupla2;
                ELSIF v_pontos_dupla2 < v_pontos_dupla1 THEN
                    v_dupla_vencedora := 2;
                    v_pontos_adversarios := v_pontos_dupla1;
                ELSE
                    -- Empate: quem trancou perde
                    SELECT dupla INTO v_dupla_vencedora
                    FROM participantes_jogo 
                    WHERE id_jogo = v_id_jogo AND id_usuario != NEW.vencedor_partida
                    LIMIT 1;
                    
                    IF v_dupla_vencedora = 1 THEN
                        v_pontos_adversarios := v_pontos_dupla2;
                    ELSE
                        v_pontos_adversarios := v_pontos_dupla1;
                    END IF;
                END IF;
            END IF;
            
            -- Atualizar pontos dos vencedores
            UPDATE participantes_jogo 
            SET pontuacao_total = pontuacao_total + v_pontos_adversarios
            WHERE id_jogo = v_id_jogo AND dupla = v_dupla_vencedora;
            
            UPDATE NEW SET pontos_vencedor = v_pontos_adversarios;
        END IF;
        
        -- Verificar se o jogo chegou ao fim (50 pontos)
        IF EXISTS(
            SELECT 1 FROM participantes_jogo 
            WHERE id_jogo = v_id_jogo AND pontuacao_total >= 50
        ) THEN
            UPDATE jogos 
            SET status = 'finalizado', 
                data_fim = CURRENT_TIMESTAMP,
                vencedor_jogo = (
                    SELECT id_usuario FROM participantes_jogo 
                    WHERE id_jogo = v_id_jogo 
                    ORDER BY pontuacao_total DESC 
                    LIMIT 1
                )
            WHERE id_jogo = v_id_jogo;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calcular_pontos_partida
    BEFORE UPDATE ON partidas
    FOR EACH ROW
    EXECUTE FUNCTION calcular_pontos_partida();

-- Trigger para verificar vitória automaticamente
CREATE OR REPLACE FUNCTION verificar_vitoria_partida()
RETURNS TRIGGER AS $$
DECLARE
    v_pecas_restantes INTEGER;
    v_jogo_trancado BOOLEAN;
BEGIN
    IF NEW.tipo_jogada = 'jogou_peca' THEN
        -- Verificar se o jogador ficou sem peças (batida)
        SELECT COUNT(*) INTO v_pecas_restantes
        FROM pecas_partida 
        WHERE id_partida = NEW.id_partida 
        AND id_usuario = NEW.id_usuario 
        AND status = 'na_mao';
        
        IF v_pecas_restantes = 0 THEN
            -- Jogador bateu
            UPDATE partidas 
            SET status = 'finalizada',
                data_fim = CURRENT_TIMESTAMP,
                vencedor_partida = NEW.id_usuario,
                tipo_vitoria = 'batida'
            WHERE id_partida = NEW.id_partida;
        ELSE
            -- Verificar se o jogo está trancado
            SELECT detectar_jogo_trancado(NEW.id_partida) INTO v_jogo_trancado;
            
            IF v_jogo_trancado THEN
                UPDATE partidas 
                SET status = 'finalizada',
                    data_fim = CURRENT_TIMESTAMP,
                    vencedor_partida = NEW.id_usuario,
                    tipo_vitoria = 'trancamento'
                WHERE id_partida = NEW.id_partida;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verificar_vitoria
    AFTER INSERT ON jogadas
    FOR EACH ROW
    EXECUTE FUNCTION verificar_vitoria_partida();

-- Trigger para atualizar último acesso do usuário
CREATE OR REPLACE FUNCTION atualizar_ultimo_acesso()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE usuarios 
    SET data_ultimo_acesso = CURRENT_TIMESTAMP
    WHERE id_usuario = NEW.id_usuario;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ultimo_acesso_jogadas
    AFTER INSERT ON jogadas
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_ultimo_acesso();