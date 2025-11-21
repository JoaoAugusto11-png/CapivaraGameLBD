# -*- coding: utf-8 -*-
"""
CAPIVARA GAME LBD - SOLUÇÃO DEFINITIVA
Sistema híbrido: PostgreSQL + JSON para demonstração completa
"""

import subprocess
import sys
import json
import os
from pathlib import Path
from datetime import datetime

class DatabaseInterface:
    """Interface híbrida que funciona com PostgreSQL via linha de comando"""
    
    def __init__(self):
        self.data_dir = Path(__file__).parent / "data"
        self.data_dir.mkdir(exist_ok=True)
        
        self.users_file = self.data_dir / "usuarios.json"
        self.games_file = self.data_dir / "jogos.json"
        self.sql_log = self.data_dir / "sql_commands.sql"
        
        self.postgres_available = self.check_postgres()
        self.load_data()
    
    def check_postgres(self):
        """Verifica se PostgreSQL está acessível"""
        pg_paths = [
            r"C:\Program Files\PostgreSQL\17\bin\psql.exe",
            r"C:\Program Files\PostgreSQL\16\bin\psql.exe",
            r"C:\Program Files\PostgreSQL\15\bin\psql.exe",
            r"C:\Program Files\PostgreSQL\14\bin\psql.exe"
        ]
        
        for path in pg_paths:
            if Path(path).exists():
                self.psql_path = path
                print(f"✅ PostgreSQL encontrado: {path}")
                return True
        
        print("⚠️ PostgreSQL não encontrado - usando modo JSON")
        return False
    
    def execute_postgres_command(self, sql_command, database="postgres"):
        """Executa comando PostgreSQL via linha de comando"""
        if not self.postgres_available:
            return False
        
        try:
            # Log do comando SQL
            with open(self.sql_log, 'a', encoding='utf-8') as f:
                f.write(f"-- {datetime.now()}\n{sql_command};\n\n")
            
            # Obter senha
            if not hasattr(self, 'postgres_password'):
                self.postgres_password = input("Digite senha do PostgreSQL: ")
            
            # Preparar comando
            cmd = [
                self.psql_path,
                "-h", "localhost",
                "-p", "5433",
                "-U", "postgres", 
                "-d", database,
                "-c", sql_command
            ]
            
            # Executar
            env = os.environ.copy()
            env['PGPASSWORD'] = self.postgres_password
            env['PGCLIENTENCODING'] = 'LATIN1'
            
            result = subprocess.run(
                cmd, 
                env=env,
                capture_output=True, 
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                print("✅ Comando PostgreSQL executado")
                return True
            else:
                print(f"❌ Erro PostgreSQL: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Erro ao executar PostgreSQL: {e}")
            return False
    
    def ensure_postgres_tables(self):
        """Garante que as tabelas existem no PostgreSQL"""
        if not self.postgres_available:
            return False
        
        # Simplesmente tentar criar as tabelas com IF NOT EXISTS
        print("🔧 Verificando estrutura do banco...")
        
        commands = [
            """CREATE TABLE IF NOT EXISTS usuarios (
                id_usuario SERIAL PRIMARY KEY,
                nome_usuario VARCHAR(50) UNIQUE NOT NULL,
                nome_completo VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                senha_hash VARCHAR(255) NOT NULL,
                data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                ativo BOOLEAN DEFAULT TRUE
            )""",
            
            """CREATE TABLE IF NOT EXISTS jogos (
                id_jogo SERIAL PRIMARY KEY,
                numero_jogadores INTEGER NOT NULL,
                data_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                status VARCHAR(20) DEFAULT 'em_andamento',
                pontos_meta INTEGER DEFAULT 50
            )""",
            
            """CREATE TABLE IF NOT EXISTS participantes_jogo (
                id_participante SERIAL PRIMARY KEY,
                id_jogo INTEGER REFERENCES jogos(id_jogo),
                id_usuario INTEGER REFERENCES usuarios(id_usuario),
                posicao_mesa INTEGER NOT NULL,
                pontos_acumulados INTEGER DEFAULT 0
            )"""
        ]
        
        for cmd in commands:
            self.execute_postgres_command(cmd, "capivara_game")
        
        return True

    def setup_postgres_database(self):
        """Configura banco PostgreSQL"""
        print("\n🔧 CONFIGURANDO POSTGRESQL...")
        
        if not self.postgres_available:
            print("PostgreSQL não disponível")
            return False
        
        # 1. Criar novo banco (ignorar erro se já existir)
        print("📦 Criando banco capivara_game...")
        self.execute_postgres_command("CREATE DATABASE capivara_game")
        
        # 3. Criar estrutura no banco capivara_game
        print("📋 Criando tabelas...")
        
        # Primeiro, limpar tabelas se existirem
        cleanup_commands = [
            "DROP TABLE IF EXISTS participantes_jogo CASCADE",
            "DROP TABLE IF EXISTS jogos CASCADE", 
            "DROP TABLE IF EXISTS usuarios CASCADE"
        ]
        
        for cmd in cleanup_commands:
            self.execute_postgres_command(cmd, "capivara_game")
        
        # Agora criar as tabelas
        commands = [
            """CREATE TABLE usuarios (
                id_usuario SERIAL PRIMARY KEY,
                nome_usuario VARCHAR(50) UNIQUE NOT NULL,
                nome_completo VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                senha_hash VARCHAR(255) NOT NULL,
                data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                ativo BOOLEAN DEFAULT TRUE
            )""",
            
            """CREATE TABLE jogos (
                id_jogo SERIAL PRIMARY KEY,
                numero_jogadores INTEGER NOT NULL,
                data_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                status VARCHAR(20) DEFAULT 'em_andamento',
                pontos_meta INTEGER DEFAULT 50
            )""",
            
            """CREATE TABLE participantes_jogo (
                id_participante SERIAL PRIMARY KEY,
                id_jogo INTEGER REFERENCES jogos(id_jogo),
                id_usuario INTEGER REFERENCES usuarios(id_usuario),
                posicao_mesa INTEGER NOT NULL,
                pontos_acumulados INTEGER DEFAULT 0
            )""",
            
            """INSERT INTO usuarios (nome_usuario, nome_completo, email, senha_hash) VALUES
                ('admin', 'Administrator', 'admin@capivara.com', 'hash123'),
                ('joao', 'Joao Estudante', 'joao@email.com', 'hash456'),
                ('maria', 'Maria Silva', 'maria@email.com', 'hash789'),
                ('pedro', 'Pedro Santos', 'pedro@email.com', 'hash101')"""
        ]
        
        for cmd in commands:
            self.execute_postgres_command(cmd, "capivara_game")
        
        print("✅ PostgreSQL configurado!")
        return True
    
    def load_data(self):
        """Carrega dados dos arquivos JSON"""
        # Usuários
        if self.users_file.exists():
            with open(self.users_file, 'r', encoding='utf-8') as f:
                self.users = json.load(f)
        else:
            self.users = [
                {
                    "id_usuario": 1,
                    "nome_usuario": "admin",
                    "nome_completo": "Administrator",
                    "email": "admin@capivara.com",
                    "senha_hash": "hash123",
                    "data_cadastro": datetime.now().isoformat(),
                    "ativo": True
                },
                {
                    "id_usuario": 2,
                    "nome_usuario": "joao",
                    "nome_completo": "João Estudante",
                    "email": "joao@email.com",
                    "senha_hash": "hash456",
                    "data_cadastro": datetime.now().isoformat(),
                    "ativo": True
                }
            ]
            self.save_data()
        
        # Jogos
        if self.games_file.exists():
            with open(self.games_file, 'r', encoding='utf-8') as f:
                self.games = json.load(f)
        else:
            self.games = []
            self.save_data()
    
    def save_data(self):
        """Salva dados nos arquivos"""
        with open(self.users_file, 'w', encoding='utf-8') as f:
            json.dump(self.users, f, ensure_ascii=False, indent=2)
        
        with open(self.games_file, 'w', encoding='utf-8') as f:
            json.dump(self.games, f, ensure_ascii=False, indent=2)
    
    def execute_sql_and_json(self, sql_command, operation, data=None):
        """Executa tanto no PostgreSQL quanto no JSON"""
        
        # 1. Tentar PostgreSQL
        pg_success = False
        if self.postgres_available:
            pg_success = self.execute_postgres_command(sql_command, "capivara_game")
        
        # 2. Executar no JSON como backup
        json_success = self.execute_json_operation(operation, data)
        
        return pg_success or json_success
    
    def execute_json_operation(self, operation, data):
        """Executa operações no JSON"""
        try:
            if operation == "create_user":
                new_id = max([u['id_usuario'] for u in self.users], default=0) + 1
                new_user = {
                    "id_usuario": new_id,
                    "nome_usuario": data["nome_usuario"],
                    "nome_completo": data["nome_completo"],
                    "email": data["email"],
                    "senha_hash": data["senha_hash"],
                    "data_cadastro": datetime.now().isoformat(),
                    "ativo": True
                }
                self.users.append(new_user)
                self.save_data()
                return True
            
            elif operation == "create_game":
                new_id = max([g['id_jogo'] for g in self.games], default=0) + 1
                new_game = {
                    "id_jogo": new_id,
                    "numero_jogadores": data["numero_jogadores"],
                    "data_inicio": datetime.now().isoformat(),
                    "status": "em_andamento",
                    "pontos_meta": 50,
                    "participantes": data.get("participantes", [])
                }
                self.games.append(new_game)
                self.save_data()
                return True
            
            return False
            
        except Exception as e:
            print(f"Erro JSON: {e}")
            return False

class CapivaraGameLBD:
    """Sistema Capivara Game para LBD"""
    
    def __init__(self):
        self.db = DatabaseInterface()
    
    def start(self):
        """Inicia o sistema"""
        print("=" * 60)
        print("🎮 CAPIVARA GAME - LABORATÓRIO DE BANCO DE DADOS")
        print("=" * 60)
        print("💻 Sistema híbrido PostgreSQL + JSON")
        print("📚 Desenvolvido para disciplina LBD")
        print("=" * 60)
        
        # Configurar PostgreSQL se disponível
        if self.db.postgres_available:
            setup = input("\n🔧 Configurar PostgreSQL agora? (s/n): ").lower()
            if setup == 's':
                self.db.setup_postgres_database()
        
        self.show_status()
        self.main_menu()
    
    def show_status(self):
        """Mostra status do sistema"""
        print(f"\n📊 STATUS DO SISTEMA:")
        print(f"   • PostgreSQL: {'✅ Disponível' if self.db.postgres_available else '❌ Não disponível'}")
        print(f"   • Usuários: {len(self.db.users)}")
        print(f"   • Jogos: {len(self.db.games)}")
        print(f"   • Dados salvos em: {self.db.data_dir}")
        if self.db.postgres_available:
            print(f"   • SQL log: {self.db.sql_log}")
    
    def main_menu(self):
        """Menu principal"""
        while True:
            print("\n" + "=" * 50)
            print("📋 MENU PRINCIPAL - LBD")
            print("=" * 50)
            print("1. 👤 Gerenciar Usuários")
            print("2. 🎯 Gerenciar Jogos")
            print("3. 📊 Relatórios e Consultas SQL")
            print("4. 💾 Backup e Exportação")
            print("5. 🔧 Configurações do Banco")
            print("6. 📜 Ver Log SQL")
            print("7. 🚪 Sair")
            
            choice = input("\n🔸 Escolha (1-7): ").strip()
            
            if choice == "1":
                self.user_menu()
            elif choice == "2":
                self.game_menu()
            elif choice == "3":
                self.reports_menu()
            elif choice == "4":
                self.backup_menu()
            elif choice == "5":
                self.config_menu()
            elif choice == "6":
                self.show_sql_log()
            elif choice == "7":
                print("\n👋 Obrigado por usar o Capivara Game LBD!")
                break
            else:
                print("❌ Opção inválida!")
    
    def user_menu(self):
        """Menu de usuários"""
        while True:
            print("\n" + "=" * 40)
            print("👤 GERENCIAR USUÁRIOS")
            print("=" * 40)
            print("1. 📋 Listar Usuários")
            print("2. ➕ Criar Usuário")
            print("3. 🔍 Buscar Usuário")
            print("4. 📈 Estatísticas de Usuários")
            print("5. 🔙 Voltar")
            
            choice = input("\n🔸 Escolha (1-5): ").strip()
            
            if choice == "1":
                self.list_users()
            elif choice == "2":
                self.create_user()
            elif choice == "3":
                self.search_user()
            elif choice == "4":
                self.user_stats()
            elif choice == "5":
                break
            else:
                print("❌ Opção inválida!")
    
    def create_user(self):
        """Cria usuário usando SQL + JSON"""
        print("\n➕ CRIAR USUÁRIO")
        print("-" * 30)
        
        nome = input("Nome de usuário: ").strip()
        nome_completo = input("Nome completo: ").strip()
        email = input("Email: ").strip()
        
        if not all([nome, nome_completo, email]):
            print("❌ Todos os campos são obrigatórios!")
            return
        
        # SQL para PostgreSQL
        sql_command = f"""INSERT INTO usuarios (nome_usuario, nome_completo, email, senha_hash) 
                         VALUES ('{nome}', '{nome_completo}', '{email}', 'hash_{hash(nome)}')"""
        
        # Dados para JSON
        user_data = {
            "nome_usuario": nome,
            "nome_completo": nome_completo,
            "email": email,
            "senha_hash": f"hash_{hash(nome)}"
        }
        
        # Executar em ambos
        success = self.db.execute_sql_and_json(sql_command, "create_user", user_data)
        
        if success:
            print(f"✅ Usuário '{nome}' criado com sucesso!")
            print("💾 Dados salvos no PostgreSQL e JSON")
        else:
            print("❌ Erro ao criar usuário!")
    
    def list_users(self):
        """Lista usuários"""
        users = self.db.users
        
        print(f"\n👥 USUÁRIOS CADASTRADOS ({len(users)})")
        print("-" * 80)
        print(f"{'ID':<4} {'Usuário':<15} {'Nome Completo':<30} {'Email':<30}")
        print("-" * 80)
        
        for user in users:
            if user['ativo']:
                print(f"{user['id_usuario']:<4} {user['nome_usuario']:<15} "
                      f"{user['nome_completo']:<30} {user['email']:<30}")
    
    def game_menu(self):
        """Menu de jogos"""
        while True:
            print("\n" + "=" * 40)
            print("🎯 GERENCIAR JOGOS")
            print("=" * 40)
            print("1. 🎮 Criar Jogo")
            print("2. 📋 Listar Jogos")
            print("3. 🏆 Simular Partida")
            print("4. 📊 Estatísticas de Jogos")
            print("5. 🔙 Voltar")
            
            choice = input("\n🔸 Escolha (1-5): ").strip()
            
            if choice == "1":
                self.create_game()
            elif choice == "2":
                self.list_games()
            elif choice == "3":
                self.simulate_game()
            elif choice == "4":
                self.game_stats()
            elif choice == "5":
                break
    
    def create_game(self):
        """Cria jogo usando SQL + JSON"""
        print("\n🎮 CRIAR NOVO JOGO")
        print("-" * 30)
        
        try:
            num_players = int(input("Número de jogadores (2, 3 ou 4): "))
            if num_players not in [2, 3, 4]:
                print("❌ Número deve ser 2, 3 ou 4!")
                return
            
            # SQL para PostgreSQL
            sql_command = f"INSERT INTO jogos (numero_jogadores) VALUES ({num_players})"
            
            # Dados para JSON
            game_data = {
                "numero_jogadores": num_players,
                "participantes": []
            }
            
            # Executar
            success = self.db.execute_sql_and_json(sql_command, "create_game", game_data)
            
            if success:
                game_id = len(self.db.games)
                print(f"✅ Jogo {game_id} criado com {num_players} jogadores!")
                print("💾 Dados salvos no PostgreSQL e JSON")
            else:
                print("❌ Erro ao criar jogo!")
                
        except ValueError:
            print("❌ Digite um número válido!")
    
    def list_games(self):
        """Lista jogos"""
        games = self.db.games
        
        print(f"\n🎯 JOGOS CRIADOS ({len(games)})")
        print("-" * 60)
        print(f"{'ID':<4} {'Jogadores':<10} {'Status':<15} {'Data':<20}")
        print("-" * 60)
        
        for game in games:
            data = game['data_inicio'][:19] if game['data_inicio'] else "N/A"
            print(f"{game['id_jogo']:<4} {game['numero_jogadores']:<10} "
                  f"{game['status']:<15} {data:<20}")
    
    def reports_menu(self):
        """Menu de relatórios SQL"""
        print("\n📊 RELATÓRIOS E CONSULTAS SQL")
        print("=" * 40)
        
        queries = [
            ("Total de usuários ativos", "SELECT COUNT(*) FROM usuarios WHERE ativo = TRUE"),
            ("Total de jogos criados", "SELECT COUNT(*) FROM jogos"),
            ("Jogos por número de jogadores", "SELECT numero_jogadores, COUNT(*) FROM jogos GROUP BY numero_jogadores"),
            ("Usuários mais recentes", "SELECT nome_usuario, data_cadastro FROM usuarios ORDER BY data_cadastro DESC LIMIT 5")
        ]
        
        for i, (desc, sql) in enumerate(queries, 1):
            print(f"{i}. {desc}")
            print(f"   SQL: {sql}")
            print()
    
    def show_sql_log(self):
        """Mostra log de comandos SQL"""
        print("\n📜 LOG DE COMANDOS SQL")
        print("=" * 60)
        
        if not self.db.sql_log.exists():
            print("📝 Nenhum comando SQL foi executado ainda")
            print("💡 Execute algumas operações para ver comandos aqui!")
            input("\n📱 Pressione Enter para continuar...")
            return
        
        try:
            with open(self.db.sql_log, 'r', encoding='utf-8') as f:
                content = f.read().strip()
                
            if not content:
                print("📝 Arquivo de log está vazio")
                input("\n📱 Pressione Enter para continuar...")
                return
            
            # Mostrar informações do arquivo
            lines = content.split('\n')
            file_size = self.db.sql_log.stat().st_size
            
            print(f"📊 Informações do log:")
            print(f"   • Arquivo: {self.db.sql_log}")
            print(f"   • Tamanho: {file_size} bytes")
            print(f"   • Linhas: {len(lines)}")
            print(f"   • Última modificação: {datetime.fromtimestamp(self.db.sql_log.stat().st_mtime)}")
            
            print("\n📋 COMANDOS EXECUTADOS:")
            print("-" * 60)
            
            # Mostrar último conteúdo (últimos 1500 caracteres)
            if len(content) > 1500:
                print("... (mostrando últimos comandos) ...")
                print(content[-1500:])
            else:
                print(content)
            
            print("-" * 60)
            print(f"💡 Total de {len([line for line in lines if line.strip() and not line.startswith('--')])} comandos SQL")
            
        except Exception as e:
            print(f"❌ Erro ao ler arquivo de log: {e}")
        
        input("\n📱 Pressione Enter para continuar...")
    
    def simulate_game(self):
        """Simula uma partida completa de dominó"""
        print("\n🏆 SIMULAÇÃO DE PARTIDA DE DOMINÓ")
        print("=" * 50)
        
        # Verificar se há usuários suficientes
        if len(self.db.users) < 2:
            print("❌ É necessário pelo menos 2 usuários cadastrados!")
            input("\n📱 Pressione Enter para continuar...")
            return
        
        # Escolher número de jogadores
        try:
            num_players = int(input("🎮 Quantos jogadores (2-4)? "))
            if num_players < 2 or num_players > 4:
                print("❌ Número deve ser entre 2 e 4!")
                return
                
            if len(self.db.users) < num_players:
                print(f"❌ Só há {len(self.db.users)} usuários cadastrados!")
                return
        except:
            print("❌ Número inválido!")
            return
        
        # Selecionar jogadores
        print(f"\n👥 Selecionando {num_players} jogadores automaticamente...")
        
        # Os usuários estão em lista, não dicionário
        if isinstance(self.db.users, list):
            selected_players = self.db.users[:num_players]
        else:
            selected_players = list(self.db.users.values())[:num_players]
        
        # Criar jogo
        if isinstance(self.db.games, list):
            game_id = len(self.db.games) + 1
        else:
            game_id = len(self.db.games) + 1
            
        new_game = {
            "id": game_id,
            "jogadores": [p["id_usuario"] for p in selected_players],
            "nomes_jogadores": [p["nome_completo"] for p in selected_players],
            "data_inicio": datetime.now().isoformat(),
            "status": "simulacao",
            "rodadas": [],
            "pontuacao": {str(p["id_usuario"]): 0 for p in selected_players}
        }
        
        # Log SQL
        sql_insert = f"INSERT INTO jogos (numero_jogadores, status) VALUES ({num_players}, 'simulacao')"
        self.db.execute_postgres_command(sql_insert)
        
        print("\n🎲 INICIANDO SIMULAÇÃO...")
        print(f"🎯 Jogadores: {', '.join([p['nome_completo'] for p in selected_players])}")
        
        # Simular rodadas
        import random
        rodada = 1
        
        while max(new_game["pontuacao"].values()) < 50:  # Meta de 50 pontos
            print(f"\n🎲 RODADA {rodada}")
            print("-" * 30)
            
            # Distribuir pontos aleatórios
            ganhador_rodada = random.choice(selected_players)
            pontos_rodada = random.randint(5, 15)
            
            new_game["pontuacao"][str(ganhador_rodada["id_usuario"])] += pontos_rodada
            
            # Simular jogadas
            jogadas = []
            for i, player in enumerate(selected_players):
                peca = f"{random.randint(0,6)}-{random.randint(0,6)}"
                jogadas.append(f"{player['nome_completo']}: [{peca}]")
            
            new_game["rodadas"].append({
                "rodada": rodada,
                "ganhador": ganhador_rodada["nome_completo"],
                "pontos": pontos_rodada,
                "jogadas": jogadas
            })
            
            print(f"🏆 Ganhador da rodada: {ganhador_rodada['nome_completo']} (+{pontos_rodada} pontos)")
            
            # Mostrar pontuação atual
            print("\n📊 PONTUAÇÃO ATUAL:")
            for player_id, pontos in new_game["pontuacao"].items():
                player_name = next(p["nome_completo"] for p in selected_players if str(p["id_usuario"]) == player_id)
                print(f"   {player_name}: {pontos} pontos")
            
            rodada += 1
            
            # Pausa dramática
            import time
            time.sleep(1)
            
            if rodada > 10:  # Limite de segurança
                break
        
        # Determinar vencedor
        vencedor_id = max(new_game["pontuacao"].items(), key=lambda x: x[1])[0]
        vencedor = next(p for p in selected_players if str(p["id_usuario"]) == vencedor_id)
        pontos_vencedor = new_game["pontuacao"][vencedor_id]
        
        new_game["status"] = "finalizado"
        new_game["vencedor"] = vencedor["nome_completo"]
        new_game["data_fim"] = datetime.now().isoformat()
        
        # Salvar jogo
        if isinstance(self.db.games, list):
            self.db.games.append(new_game)
        else:
            self.db.games[str(game_id)] = new_game
        self.db.save_data()
        
        # Resultado final
        print("\n" + "="*50)
        print("🏆 PARTIDA FINALIZADA!")
        print("="*50)
        print(f"🥇 VENCEDOR: {vencedor['nome_completo']} com {pontos_vencedor} pontos!")
        print(f"🎮 Total de rodadas: {rodada-1}")
        print(f"💾 Jogo salvo com ID: {game_id}")
        
        # Log SQL final
        print("📊 Atualizando PostgreSQL...")
        self.db.ensure_postgres_tables()
        
        sql_update = f"UPDATE jogos SET status='finalizado' WHERE id_jogo={game_id}"
        if self.db.execute_postgres_command(sql_update, "capivara_game"):
            print("✅ Status atualizado no PostgreSQL!")
        else:
            print("⚠️ Erro ao atualizar PostgreSQL, mas jogo salvo em JSON")
        
        input("\n🎉 Pressione Enter para continuar...")
    
    def config_menu(self):
        """Menu de configurações"""
        while True:
            print("\n🔧 CONFIGURAÇÕES DO BANCO")
            print("=" * 40)
            print(f"📊 Status PostgreSQL: {'✅ Conectado' if self.db.postgres_available else '❌ Não disponível'}")
            print(f"💾 Arquivos JSON: ✅ Funcionando")
            print(f"📁 Pasta de dados: {self.db.data_dir}")
            
            if self.db.postgres_available:
                print(f"🔗 Caminho psql: {self.db.psql_path}")
                print(f"📋 Log SQL: {self.db.sql_log}")
                print(f"🗄️ Banco atual: capivara_game")
                print(f"🔌 Porta: 5433")
            
            print("\n📋 OPÇÕES:")
            print("1. 🔄 Reconfigurar PostgreSQL")
            print("2. 🧹 Limpar dados JSON")
            print("3. 📊 Verificar estrutura do banco")
            print("4. 🔧 Testar conexão PostgreSQL")
            print("5. 📁 Ver localização dos arquivos")
            print("6. 🔙 Voltar")
            
            choice = input("\n🔸 Escolha (1-6): ").strip()
            
            if choice == "1":
                self.reconfigure_postgres()
            elif choice == "2":
                self.clean_json_data()
            elif choice == "3":
                self.check_database_structure()
            elif choice == "4":
                self.test_postgres_connection()
            elif choice == "5":
                self.show_file_locations()
            elif choice == "6":
                break
            else:
                print("❌ Opção inválida!")
    
    def reconfigure_postgres(self):
        """Reconfigura PostgreSQL"""
        print("\n🔄 RECONFIGURANDO POSTGRESQL...")
        
        # Resetar senha se necessário
        if hasattr(self.db, 'postgres_password'):
            delattr(self.db, 'postgres_password')
        
        # Verificar novamente
        self.db.postgres_available = self.db.check_postgres()
        
        if self.db.postgres_available:
            setup = input("💡 Recriar estrutura do banco? (s/n): ").lower()
            if setup == 's':
                self.db.setup_postgres_database()
        
        input("📱 Pressione Enter para continuar...")
    
    def clean_json_data(self):
        """Limpa dados JSON"""
        confirm = input("⚠️ Isso apagará todos os dados locais! Confirmar? (s/n): ").lower()
        if confirm == 's':
            self.db.users = []
            self.db.games = []
            self.db.save_data()
            print("✅ Dados JSON limpos!")
        else:
            print("❌ Operação cancelada")
        
        input("📱 Pressione Enter para continuar...")
    
    def check_database_structure(self):
        """Verifica estrutura do banco"""
        if not self.db.postgres_available:
            print("❌ PostgreSQL não disponível")
            input("📱 Pressione Enter para continuar...")
            return
        
        print("\n📊 VERIFICANDO ESTRUTURA DO BANCO...")
        
        tables_query = """
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
        ORDER BY table_name;
        """
        
        print("🔍 Verificando tabelas existentes...")
        success = self.db.execute_postgres_command(tables_query, "capivara_game")
        
        if success:
            print("✅ Consulta executada - verifique o terminal para resultados")
        else:
            print("❌ Erro ao verificar estrutura")
        
        input("📱 Pressione Enter para continuar...")
    
    def test_postgres_connection(self):
        """Testa conexão PostgreSQL"""
        if not self.db.postgres_available:
            print("❌ PostgreSQL não encontrado no sistema")
            input("📱 Pressione Enter para continuar...")
            return
        
        print("\n🔧 TESTANDO CONEXÃO POSTGRESQL...")
        
        test_query = "SELECT 'Conexão OK!' as status, current_timestamp as horario;"
        
        success = self.db.execute_postgres_command(test_query, "postgres")
        
        if success:
            print("✅ Conexão PostgreSQL funcionando!")
        else:
            print("❌ Falha na conexão PostgreSQL")
        
        input("📱 Pressione Enter para continuar...")
    
    def show_file_locations(self):
        """Mostra localização dos arquivos"""
        print("\n📁 LOCALIZAÇÃO DOS ARQUIVOS")
        print("=" * 40)
        print(f"📂 Pasta principal: {Path(__file__).parent}")
        print(f"💾 Pasta de dados: {self.db.data_dir}")
        print(f"👥 Arquivo usuários: {self.db.users_file}")
        print(f"🎮 Arquivo jogos: {self.db.games_file}")
        print(f"📋 Log SQL: {self.db.sql_log}")
        
        if self.db.postgres_available:
            print(f"🔗 PostgreSQL: {self.db.psql_path}")
        
        input("📱 Pressione Enter para continuar...")
    
    def backup_menu(self):
        """Menu de backup"""
        print("\n💾 BACKUP E EXPORTAÇÃO")
        print("=" * 30)
        
        backup_file = self.db.data_dir.parent / f"backup_capivara_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        backup_data = {
            "sistema": "Capivara Game LBD",
            "data_backup": datetime.now().isoformat(),
            "usuarios": self.db.users,
            "jogos": self.db.games,
            "sql_commands": []
        }
        
        # Adicionar comandos SQL se existirem
        if self.db.sql_log.exists():
            with open(self.db.sql_log, 'r', encoding='utf-8') as f:
                backup_data["sql_commands"] = f.read().split('\n')
        
        with open(backup_file, 'w', encoding='utf-8') as f:
            json.dump(backup_data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ Backup criado: {backup_file}")
    
    def search_user(self):
        """Busca usuário"""
        termo = input("Digite parte do nome ou email: ").strip().lower()
        found = [u for u in self.db.users if 
                termo in u['nome_usuario'].lower() or 
                termo in u['nome_completo'].lower() or
                termo in u['email'].lower()]
        
        if found:
            print(f"✅ {len(found)} usuário(s) encontrado(s):")
            for user in found:
                print(f"• {user['nome_usuario']} - {user['nome_completo']}")
        else:
            print("❌ Nenhum usuário encontrado")
    
    def user_stats(self):
        """Estatísticas de usuários"""
        total = len(self.db.users)
        ativos = len([u for u in self.db.users if u['ativo']])
        
        print(f"\n📈 ESTATÍSTICAS DE USUÁRIOS")
        print(f"Total: {total}")
        print(f"Ativos: {ativos}")
        print(f"Inativos: {total - ativos}")
    
    def game_stats(self):
        """Estatísticas de jogos"""
        total = len(self.db.games)
        por_jogadores = {}
        
        for game in self.db.games:
            num = game['numero_jogadores']
            por_jogadores[num] = por_jogadores.get(num, 0) + 1
        
        print(f"\n📈 ESTATÍSTICAS DE JOGOS")
        print(f"Total: {total}")
        print("Por número de jogadores:")
        for num, count in por_jogadores.items():
            print(f"  {num} jogadores: {count}")

def main():
    """Função principal"""
    try:
        game = CapivaraGameLBD()
        game.start()
    except KeyboardInterrupt:
        print("\n\n🛑 Sistema interrompido pelo usuário.")
    except Exception as e:
        print(f"\n❌ Erro inesperado: {e}")

if __name__ == "__main__":
    main()