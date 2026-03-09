# Guia de Desenvolvimento Flow

## Branches

Este repositório possui três branches principais:

- `main` — espelho exato do upstream [BerriAI/litellm](https://github.com/BerriAI/litellm). Nunca deve receber commits diretos; é sobrescrita automaticamente a cada sincronização.
- `develop-flow` — branch de ***desenvolvimento*** com as alterações específicas do *Flow*. Rebase sobre `main` após cada sincronização. Todo desenvolvimento novo deve partir desta branch.
- `production-flow` — branch de produção. Recebe merges de `develop-flow` após validação, representando o estado atual do ambiente produtivo da Flow.

### Principais orientações

- Nunca faça commits ou PRs diretamente na branch *main*.
- A branch que acumula todo o desenvolvimento é a *develop-flow*. As PRs devem ser criadas apontando para *develop-flow*.
- production-flow deve ser atualizada com o conteúdo de *develop-flow* após a validação das mudanças.
- Evite ao máximo modificar arquivos da *main* para diminuir as ocorrências de conflito. Procure sempre que possível criar novos arquivos.

---

## Workflow de Sincronização com Upstream (`sync-upstream.yml`)

Este workflow mantém o fork Flow sincronizado automaticamente com o repositório upstream [BerriAI/litellm](https://github.com/BerriAI/litellm).

### Gatilhos

- **Agendado**: Executa automaticamente toda **segunda-feira e quarta-feira à meia-noite UTC**
- **Manual**: Pode ser acionado a qualquer momento via `workflow_dispatch` na interface do GitHub Actions


#### Ação necessária

Um e-mail é enviado para notificar as partes interessadas sobre as atualizações. É necessário que um dos administradores aprove o fluxo da pipeline para sincronizar a branch *main* e atualizar a branch *develop-flow*.

---

### Jobs

#### 1. `check-upstream`

Verifica se o upstream possui novos commits que a nossa branch `main` ainda não tem.

1. Faz checkout do repositório com histórico completo (`fetch-depth: 0`)
2. Adiciona o remote `upstream` apontando para `https://github.com/BerriAI/litellm.git`
3. Busca `upstream/main`
4. Conta quantos commits `origin/main` está atrás de `upstream/main`
5. Expõe `behind_count` como saída para o próximo job

#### 2. `sync-upstream`

Executa somente se `behind_count > 0`. Requer aprovação manual pelo ambiente **`sync-approval`** antes de prosseguir.

1. Faz checkout do repositório com histórico completo
2. Adiciona o remote `upstream`
3. Busca `upstream/main`
4. Configura a identidade git como `github-actions[bot]`
5. **Force-push** de `upstream/main` diretamente sobre `origin/main` — nossa `main` é sempre um espelho exato do upstream
6. Busca e faz checkout de `develop-flow`, então **rebase sobre `origin/main` atualizada**, e faz force-push do resultado

---

### Modelo de Branches

```
upstream/main  ──────────────────────────────►  (fonte da verdade)
                  ↓ force-push
origin/main    ──────────────────────────────►  (espelho exato do upstream)
                  ↓ rebase
develop-flow   ──────────────────────────────►  (alterações da Flow por cima)
```

- `main` — nunca faça commits diretamente; ela é sobrescrita pelo upstream a cada sincronização
- `develop-flow` — branch de trabalho para todas as alterações específicas da Flow; sempre rebasada sobre `main`

---

### Sincronização Manual

Para acionar uma sincronização fora do agendamento:

1. Acesse **Actions → Sync Upstream LiteLLM > Flow**
2. Clique em **Run workflow**
3. Aprove a execução no ambiente **`sync-approval`** quando solicitado

---

### Resolução de Conflitos

Se o rebase de `develop-flow` sobre `main` falhar devido a conflitos, o workflow vai falhar na etapa `git rebase`. Para resolver localmente:

```bash
git fetch origin
git fetch upstream
git checkout develop-flow
git rebase origin/main
# resolva os conflitos e então:
git rebase --continue
git push origin develop-flow --force-with-lease
```
