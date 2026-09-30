#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Godot Script Exporter
Ferramenta para consolidar e exportar scripts do Godot Engine (.gd) 
em arquivos consolidados para documentação, backups ou análise.
"""

import os
import sys
from pathlib import Path
from datetime import datetime

class GodotScriptExporter:
    def __init__(self):
        self.scripts = []
        self.total_linhas = 0
        self.arquivos_encontrados = 0
        
    def coletar_scripts(self, diretorio_base):
        """Coleta todos os arquivos .gd recursivamente no diretório alvo"""
        print(f"🔍 Escaneando diretório: {diretorio_base}")
        self.scripts = []
        self.arquivos_encontrados = 0
        
        for root, dirs, files in os.walk(diretorio_base):
            # Ignora diretórios comuns de build e versionamento
            for pasta_ignorar in ['.git', '__pycache__', 'venv', 'build', '.godot', 'addons']:
                if pasta_ignorar in dirs:
                    dirs.remove(pasta_ignorar)
            
            for file in files:
                if file.endswith('.gd'):
                    caminho_completo = os.path.join(root, file)
                    self.scripts.append({
                        'caminho': caminho_completo,
                        'nome': file,
                        'pasta': os.path.basename(root),
                        'caminho_relativo': os.path.relpath(caminho_completo, diretorio_base)
                    })
                    self.arquivos_encontrados += 1
        
        self.scripts.sort(key=lambda x: x['nome'])
        print(f"✅ Encontrados {self.arquivos_encontrados} scripts .gd")
        return self.scripts
    
    def ler_conteudo(self, caminho_script):
        """Lê o conteúdo textual de um script com codificação UTF-8"""
        try:
            with open(caminho_script, 'r', encoding='utf-8') as f:
                conteudo = f.read()
                linhas = conteudo.count('\n') + 1
                return conteudo, linhas
        except Exception as e:
            print(f"⚠️ Erro ao ler {caminho_script}: {e}")
            return f"# ERRO AO LER ARQUIVO: {e}", 0
    
    def exportar_para_txt(self, diretorio_base, diretorio_saida, nome_arquivo="scripts_consolidados.txt"):
        """Exporta os scripts em formato TXT estruturado simples"""
        self.coletar_scripts(diretorio_base)
        if not self.scripts:
            print("❌ Nenhum script encontrado para exportação!")
            return False
        
        caminho_saida = os.path.join(diretorio_saida, nome_arquivo)
        
        with open(caminho_saida, 'w', encoding='utf-8') as f:
            f.write("=" * 80 + "\n")
            f.write("📁 CONSOLIDAÇÃO DE SCRIPTS GODOT\n")
            f.write("=" * 80 + "\n")
            f.write(f"📅 Data: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}\n")
            f.write(f"📄 Total de scripts: {self.arquivos_encontrados}\n")
            f.write("=" * 80 + "\n\n")
            
            f.write("📋 ÍNDICE\n")
            f.write("-" * 80 + "\n")
            for i, script in enumerate(self.scripts, 1):
                f.write(f"{i:3}. {script['nome']} -> {script['caminho_relativo']}\n")
            f.write("\n" + "=" * 80 + "\n\n")
            
            self.total_linhas = 0
            for i, script in enumerate(self.scripts, 1):
                conteudo, linhas = self.ler_conteudo(script['caminho'])
                self.total_linhas += linhas
                
                f.write(f"\n{'=' * 80}\n")
                f.write(f"📄 SCRIPT #{i}: {script['nome']}\n")
                f.write(f"📁 Caminho Relativo: {script['caminho_relativo']}\n")
                f.write(f"📊 Linhas: {linhas}\n")
                f.write(f"{'=' * 80}\n\n")
                f.write(conteudo)
                f.write(f"\n\n# FIM: {script['nome']}\n")
                f.write(f"{'#' * 80}\n\n")
                
        print(f"✅ Exportação simples concluída com sucesso em: {caminho_saida}")
        return True
    
    def exportar_com_marcadores(self, diretorio_base, diretorio_saida, nome_arquivo="scripts_marcadores.txt"):
        """Exporta os scripts com marcadores visuais para blocos de código"""
        self.coletar_scripts(diretorio_base)
        if not self.scripts:
            return False
        
        caminho_saida = os.path.join(diretorio_saida, nome_arquivo)
        
        with open(caminho_saida, 'w', encoding='utf-8') as f:
            f.write("╔" + "═" * 78 + "╗\n")
            f.write("║" + "📦 EXPORTAÇÃO DE SCRIPTS GODOT (BLOCO)".center(78) + "║\n")
            f.write("╚" + "═" * 78 + "╝\n\n")
            f.write(f"📅 Data: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}\n")
            f.write(f"📄 Total de scripts: {self.arquivos_encontrados}\n")
            f.write("─" * 80 + "\n\n")
            
            self.total_linhas = 0
            for i, script in enumerate(self.scripts, 1):
                conteudo, linhas = self.ler_conteudo(script['caminho'])
                self.total_linhas += linhas
                
                f.write(f"\n{'█' * 80}\n")
                f.write(f"█ 📄 {script['nome']}\n")
                f.write(f"█ 📁 {script['caminho_relativo']}\n")
                f.write(f"█ 📊 {linhas} linhas\n")
                f.write(f"█ 🏷️  ID: script_{i:03d}\n")
                f.write(f"{'█' * 80}\n\n")
                f.write(conteudo)
                f.write(f"\n{'─' * 80}\n")
                f.write(f"# FIM - script_{i:03d}\n")
                f.write(f"{'─' * 80}\n\n")
                
        print(f"✅ Exportação com marcadores concluída com sucesso em: {caminho_saida}")
        return True

    def exportar_zip(self, diretorio_base, diretorio_saida, nome_zip="backup_scripts"):
        """Compacta todos os scripts .gd encontrados em uma estrutura ZIP"""
        try:
            import zipfile
            self.coletar_scripts(diretorio_base)
            if not self.scripts:
                return False
            
            caminho_zip = os.path.join(diretorio_saida, f"{nome_zip}.zip")
            with zipfile.ZipFile(caminho_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
                for script in self.scripts:
                    zipf.write(script['caminho'], script['caminho_relativo'])
            print(f"✅ Arquivo compactado gerado com sucesso em: {caminho_zip}")
            return True
        except ImportError:
            print("⚠️ Erro: Módulo 'zipfile' necessário não está disponível no sistema.")
            return False

def criar_atalho_windows(script_name):
    """Gera um arquivo batch (.bat) para execução automatizada no Windows"""
    bat_content = f'''@echo off
echo ╔══════════════════════════════════════════════════════════════╗
echo ║          📦 GODOT SCRIPT EXPORTER MULTITOOL                  ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
python "{script_name}" %*
pause
'''
    with open("executar_exportador.bat", 'w', encoding='utf-8') as f:
        f.write(bat_content)
    print("✅ Utilitário de automação gerado: executar_exportador.bat")

if __name__ == "__main__":
    # Define diretório de leitura (Argumento via terminal ou pasta local padrão)
    diretorio_leitura = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    
    # Define o diretório de destino padrão (Pasta de Downloads do Usuário ativo)
    diretorio_salvamento = str(Path.home() / "Downloads")
    
    print(f"📂 Diretório Alvo (Origem): {diretorio_leitura}")
    print(f"📥 Pasta de Destino (Saída): {diretorio_salvamento}\n")
    
    exporter = GodotScriptExporter()
    
    print("📋 Selecione o formato de saída:")
    print("  1. TXT Estruturado Simples")
    print("  2. TXT com Marcadores Visuais (Editor Friendly)")
    print("  3. Pacote Compactado (.ZIP)")
    print("  4. Executar todas as opções")
    print()
    
    opcao = input("Opção desejada (1-4): ").strip()
    print("-" * 80)
    
    if opcao == "1" or opcao == "4":
        exporter.exportar_para_txt(diretorio_leitura, diretorio_salvamento)
    if opcao == "2" or opcao == "4":
        exporter.exportar_com_marcadores(diretorio_leitura, diretorio_salvamento)
    if opcao == "3" or opcao == "4":
        exporter.exportar_zip(diretorio_leitura, diretorio_salvamento)
        
    if not os.path.exists("executar_exportador.bat"):
        criar_atalho_windows(os.path.basename(__file__))
        
    print("\n✅ Tarefa concluída.")