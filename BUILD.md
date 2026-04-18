# Build & Install Guide — ig-normalizer (Windows)

## O que o build produz

```
dist\
  ig-normalizer.exe          ← binário da ferramenta (PyInstaller)

installer\output\
  ig-normalizer-setup-1.0.0.exe   ← INSTALADOR FINAL (Inno Setup)
```

O **instalador final** (`ig-normalizer-setup-1.0.0.exe`) é um `.exe` único que:

- Instala em `C:\Program Files\ig-normalizer\`
- Registra o menu de contexto no Explorer (clique direito em pasta)
- Adiciona o comando ao `PATH` do sistema
- Cria um **desinstalador** acessível em _Aplicativos e Recursos_ do Windows

---

## Pré-requisitos (instalar uma única vez)

| Software     | Link                              |
| ------------ | --------------------------------- |
| Python 3.8+  | https://python.org/downloads      |
| Inno Setup 6 | https://jrsoftware.org/isinfo.php |

---

## Build (Windows)

### Opção 1 — PowerShell (recomendado)

```powershell
cd C:\caminho\para\ig-normalizer
.\build.ps1
```

### Opção 2 — Prompt de Comando

```cmd
cd C:\caminho\para\ig-normalizer
build.bat
```

Ao final, o instalador estará em:

```
installer\output\ig-normalizer-setup-1.0.0.exe
```

---

## Uso após instalado

Clique com o botão direito em qualquer pasta no Explorer:

```
📁 Minha Pasta
  └─ [botão direito]
       └─ Normalize Accents (ig-normalizer)   ← aparece aqui
```

Também fica disponível no terminal:

```cmd
ig-normalizer C:\caminho\da\pasta --dry-run --verbose
ig-normalizer --test "Atlético MG / Goiás / São Paulo"
```

---

## Desinstalar

Via **Configurações → Aplicativos → ig-normalizer → Desinstalar**  
ou via **Painel de Controle → Programas → Desinstalar um programa**.

O desinstalador remove o executável, as entradas do menu de contexto e a entrada do PATH automaticamente.
