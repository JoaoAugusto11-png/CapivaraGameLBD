-- ============================================
-- CRIAÇÃO DAS TABELAS - CAPIVARA GAME
-- ============================================

-- Tabela de usuários
CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nome_usuario VARCHAR(50) UNIQUE NOT NULL,
    nome_completo VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_ultimo_acesso TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE
);

-- Tabela de jogos (uma partida completa até 50 pontos)
CREATE TABLE jogos (
    id_jogo SERIAL PRIMARY KEY,
    data_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_fim TIMESTAMP,
    numero_jogadores INTEGER NOT NULL CHECK (numero_jogadores IN (2, 3, 4)),
    pontuacao_meta INTEGER DEFAULT 50,
    status VARCHAR(20) DEFAULT 'em_andamento' CHECK (status IN ('em_andamento', 'finalizado', 'cancelado')),
    vencedor_jogo INTEGER,
    FOREIGN KEY (vencedor_jogo) REFERENCES usuarios(id_usuario)
);

-- Tabela de participantes do jogo
CREATE TABLE participantes_jogo (
    id_participacao SERIAL PRIMARY KEY,
    id_jogo INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    posicao_mesa INTEGER NOT NULL CHECK (posicao_mesa BETWEEN 1 AND 4),
    dupla INTEGER CHECK (dupla IN (1, 2)), -- Para jogos de 4 pessoas
    pontuacao_total INTEGER DEFAULT 0,
    FOREIGN KEY (id_jogo) REFERENCES jogos(id_jogo) ON DELETE CASCADE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    UNIQUE(id_jogo, posicao_mesa),
    UNIQUE(id_jogo, id_usuario)
);

-- Tabela de partidas (rodadas dentro de um jogo)
CREATE TABLE partidas (
    id_partida SERIAL PRIMARY KEY,
    id_jogo INTEGER NOT NULL,
    numero_partida INTEGER NOT NULL,
    data_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_fim TIMESTAMP,
    primeiro_jogador INTEGER NOT NULL,
    vencedor_partida INTEGER,
    tipo_vitoria VARCHAR(20) CHECK (tipo_vitoria IN ('batida', 'trancamento')),
    pontos_vencedor INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'em_andamento' CHECK (status IN ('em_andamento', 'finalizada')),
    FOREIGN KEY (id_jogo) REFERENCES jogos(id_jogo) ON DELETE CASCADE,
    FOREIGN KEY (primeiro_jogador) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (vencedor_partida) REFERENCES usuarios(id_usuario),
    UNIQUE(id_jogo, numero_partida)
);

-- Tabela de peças do dominó
CREATE TABLE pecas_domino (
    id_peca SERIAL PRIMARY KEY,
    lado_a INTEGER NOT NULL CHECK (lado_a BETWEEN 0 AND 6),
    lado_b INTEGER NOT NULL CHECK (lado_b BETWEEN 0 AND 6),
    valor_total INTEGER GENERATED ALWAYS AS (lado_a + lado_b) STORED,
    UNIQUE(lado_a, lado_b),
    CHECK (lado_a <= lado_b) -- Garantir ordenação única (ex: 2-5, não 5-2)
);

-- Tabela de distribuição de peças para cada partida
CREATE TABLE pecas_partida (
    id_distribuicao SERIAL PRIMARY KEY,
    id_partida INTEGER NOT NULL,
    id_peca INTEGER NOT NULL,
    id_usuario INTEGER, -- NULL se estiver no monte
    posicao_mao INTEGER, -- posição na mão do jogador
    status VARCHAR(20) DEFAULT 'na_mao' CHECK (status IN ('na_mao', 'jogada', 'no_monte')),
    FOREIGN KEY (id_partida) REFERENCES partidas(id_partida) ON DELETE CASCADE,
    FOREIGN KEY (id_peca) REFERENCES pecas_domino(id_peca),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

-- Tabela de mesa (peças jogadas na mesa)
CREATE TABLE mesa_jogo (
    id_mesa SERIAL PRIMARY KEY,
    id_partida INTEGER NOT NULL,
    id_peca INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    ordem_jogada INTEGER NOT NULL,
    lado_conectado VARCHAR(10) CHECK (lado_conectado IN ('esquerda', 'direita', 'inicial')),
    extremidade_a INTEGER, -- valor da extremidade esquerda após a jogada
    extremidade_b INTEGER, -- valor da extremidade direita após a jogada
    timestamp_jogada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_partida) REFERENCES partidas(id_partida) ON DELETE CASCADE,
    FOREIGN KEY (id_peca) REFERENCES pecas_domino(id_peca),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    UNIQUE(id_partida, ordem_jogada)
);

-- Tabela de jogadas (inclui passes)
CREATE TABLE jogadas (
    id_jogada SERIAL PRIMARY KEY,
    id_partida INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    ordem_turno INTEGER NOT NULL,
    tipo_jogada VARCHAR(20) NOT NULL CHECK (tipo_jogada IN ('jogou_peca', 'passou', 'comprou_monte')),
    id_peca INTEGER, -- NULL em caso de passe
    pecas_compradas INTEGER DEFAULT 0,
    timestamp_jogada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_partida) REFERENCES partidas(id_partida) ON DELETE CASCADE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_peca) REFERENCES pecas_domino(id_peca),
    UNIQUE(id_partida, ordem_turno)
);

-- Tabela de monte (peças disponíveis para compra)
CREATE TABLE monte_partida (
    id_monte SERIAL PRIMARY KEY,
    id_partida INTEGER NOT NULL,
    pecas_restantes INTEGER DEFAULT 0,
    FOREIGN KEY (id_partida) REFERENCES partidas(id_partida) ON DELETE CASCADE,
    UNIQUE(id_partida)
);

-- Índices para otimização
CREATE INDEX idx_participantes_jogo_usuario ON participantes_jogo(id_usuario);
CREATE INDEX idx_partidas_jogo ON partidas(id_jogo);
CREATE INDEX idx_pecas_partida_usuario ON pecas_partida(id_usuario);
CREATE INDEX idx_mesa_jogo_partida ON mesa_jogo(id_partida);
CREATE INDEX idx_jogadas_partida ON jogadas(id_partida);
CREATE INDEX idx_jogadas_usuario ON jogadas(id_usuario);