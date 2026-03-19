# Guia de Desenvolvimento Flow

## Branches

Este repositório possui três branches principais:

- `main` — espelho exato do upstream [BerriAI/litellm](https://github.com/BerriAI/litellm). Nunca deve receber commits diretos; é sobrescrita automaticamente a cada sincronização. **Não é a branch default**.
- `develop-flow` — branch de ***desenvolvimento*** com as alterações específicas do *Flow*. Rebase sobre `main` após cada sincronização. Todo desenvolvimento novo deve partir desta branch.
- `production-flow` — [**default**] branch de produção. Recebe merges de `develop-flow` após validação, representando o estado atual do ambiente produtivo da Flow.

### Principais orientações

- Nunca faça commits ou PRs diretamente na branch *main*.
- A branch ***mãe*** a partir de onde deve-se criar uma nova branch para desenvolvimento é a ***develop-flow***. As PRs devem ser criadas apontando para ***develop-flow***.
- Antes de iniciar uma branch a partir de ***develop-flow*** faça a sincronização pelo script `dev-sync` *(Vide procedimento abaixo em 'sync da develop-flow' )*.
- *production-flow* deve ser atualizada com o conteúdo de *develop-flow* (merge) após a validação das mudanças.
- Evite ao máximo modificar arquivos da *main* para diminuir a ocorrência de conflitos. Procure sempre que possível criar novos arquivos.

---

## Desenvolvimento

### Sync da develop-flow

Para fazer a sincronização da branch local 'develop-flow' com a remota 'origin/develop-flow' antes de um novo desenvolvimento:

```sh
cd scrips/flow
make dev-sync
```

O script alertará se a branch possui alterações não salvas. **Não prossiga** com o sync caso existam pendências pois o processo irá **deletar permanentemente alterações não salvas**.

### Arquivo de configuração

O LiteLLM, no caso do Flow, utiliza o arquivo `config.yaml` localizado na raiz do projeto.
Abaixo segue um exemplo para criar a configuração necessária para o LiteLLM.

```yml
model_list:
  - model_name: gpt-4o-mini
    litellm_params:
      model: azure/gpt-4o-mini
      api_base: <BASE_URL>      
      api_key: <YOUR_API_KEY_HERE>
      api_version: "2024-12-01-preview"

  - model_name: gemini-2.5-flash
    litellm_params:
      model: vertex_ai/gemini-2.5-flash
      vertex_project: ciandt-flow-platform
      vertex_location: us-central1
      vertex_credentials: |
        {
          "type": "service_account",
          "project_id": "ciandt-flow-platform",
          "private_key_id": "<YOUR_API_KEY_ID_HERE>",
          "private_key": "<YOUR_API_KEY_HERE>",
          "client_email": "<VERTEX_PROJECT_EMAIL>",
          "client_id": "<se você tiver, opcional>",
          "token_uri": "https://oauth2.googleapis.com/token"
        }

  - model_name: claude-4.5-sonnet
    litellm_params:
      model: bedrock/us.anthropic.claude-sonnet-4-5-20250929-v1:0
      aws_access_key_id: <YOUR_API_KEY_ID_HERE>
      aws_secret_access_key: <YOUR_API_KEY_HERE>
      aws_region_name: us-east-1

general_settings:
  set_verbose: true
  pass_through_all_headers: true

litellm_settings:
    callbacks: ["prometheus"]
    prometheus_initialize_budget_metrics: true
```

### Rodando LiteLLM e monitoramento (Prometheus e Grafana)

Para rodar localmente siga os passos abaixo:

1) Inserir a linha abaixo no arquivo config.yaml

```yaml
litellm_settings:
    callbacks: ["prometheus"]
    prometheus_initialize_budget_metrics: true
```

2) Subir todos os três serviços, volumes e rede.

```sh
cd scripts/flow
make up
```

3) Acessar os links abaixo para validar os serviços.

- [LiteLLM Métricas](http://localhost:4000/metrics/)
- [Prometheus Server](http://localhost:9090/)
- [Grafana](http://localhost:3000/)

4) Configurar o Grafana

Rodar o scrips abaixo para encontrar o IP:

```sh
cd scripts/flow
make get-ip
```

- *Connections* > *Add new connection*
- Instalar a conexão chamada **Prometheus**
- No campo Connection inserir o IP retornado pelo comando acima + porta 9090 `http://<local-ip>:9090`
- Clicar no botão **Save & test**
- Baixar o JSON do dashboard LiteLLM no [Grafana Dashboards](https://grafana.com/grafana/dashboards/24965-litellm/) e importar o arquivo JSON no Grafana

Para derrubar as aplicações

```sh
cd scripts/flow
make down
```

### Testando manualmente a inferência

Após subir os serviços seguindo o procedimento acima teste as inferências enviando requisições para o endpoint correspondente.

*Testando modelos OpenAI*

```sh
curl http://localhost:4000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{
      "model": "gpt-4o-mini",
      "messages": [{"role": "user", "content": "Hello!"}]
    }'
```

*Testando modelos Gemini*

```sh
curl http://localhost:4000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{
      "model": "gemini-2.5-flash",
      "messages": [{"role": "user", "content": "Hello!"}]
    }'
```

*Testando modelos Bedrock*

```sh
curl http://localhost:4000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{
      "model": "claude-4.5-sonnet",
      "messages": [{"role": "user", "content": "Hello!"}]
    }'
```

### Rodando testes de latência e outros com JMeter (localmente)

**!! ATENÇÃO: OS TESTES SÃO FEITOS CONSUMINDO TOKENS DOS PROVIDERS. TENHA CAUTELA AO TESTAR !!**

Considerando que todos os serviços estão de pé na máquina local e que o Grafana foi corretamente configurado basta seguir os passos abaixo:

1) Verificar os parâmetros de teste no arquivo `scripts/flow/jmeter/latency-probe.jmx`. Segue um guia simplificado do XML.

```xml
latency-probe.jmx                                                                                                                                   
  ├── TestPlan "latency-probe"                                                                                                                    
  │   ├── serialize_threadgroups: true                                                                                                                
  │   ├── tearDown_on_shutdown: true
  │   └── user_defined_variables                                                                                                                      
  │       ├── LITELLM_HOST = localhost
  │       └── LITELLM_PORT = 4000
  │
  └── ThreadGroup "load"
      ├── threads: 2 | ramp: 10s | duration: 30s
      │
      ├── InterleaveControl "Interleave Payloads"
      │   │
      │   ├── /v1/chat/completions  model: azure/gpt-4o-mini
      │   ├── /v1/chat/completions  model: gemini-2.5-flash
      │   └── /v1/chat/completions  model: claude-4.5-sonnet
      │
      └── ResultCollector "View Results Tree"

  └── ResultCollector "Aggregate Report"
```

2) Rodar o script

```sh
cd scripts/flow
make performance-tests
```

3) Após o teste terminar consulte os resultados dentro da pasta `scripts/flow/jmeter/report/`.

4) *(OPCIONAL)* Acesse o Grafana em [http://localhost:3000](http://localhost:3000) para consultar os relatórios de utilização baseados nos dados de métricas coletados pelo *Prometheus*.

### Rodando pipes

#### Build e Push de imagem para AWS ECR (emulando localmente)

Para rodar localmente utilizando um emulador de execução de pipe

1) Instalar o emulador de execução de pipe `act` (*se ainda não instalado)*

```sh
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash
```

2) Rodar o comando act com parâmetros

```sh
./bin/act workflow_dispatch -j local-build --workflows .github/workflows/flow-build-and-push-ecr.yml --input local_test=true --network host
```

3) Verificar se o registro foi feito corretamente consultando a url abaixo:

```sh
curl http://localhost:5001/v2/litellm-dev/tags/list
```

#### Deploy no AWS EKS (emulando localmente)

Para rodar localmente utilizando um emulador de execução de pipe

1) Instalar o emulador de execução de pipe `act` (*se ainda não instalado)*

```sh
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash
```

2) Rodar o comando act com parâmetros

```sh
./bin/act workflow_dispatch \
  --workflows .github/workflows/flow-deploy-eks.yml \
  --input environment=development \
  --network host
```

Se tudo correr bem no final do procedimento um resumo será exibido para o usuário.

### Operação local do LiteLLM

Logo após a pipe acima ser rodada a imagem do **LiteLLM** deveria estar disponível.

#### Arquivo de configuração

Além da imagem é necessário o arquivo `config.yaml` com as chaves dos modelos. Consulte o arquivo de exemplo `dev_config.yaml`.

#### Rodando localmente

Após confirmar que o arquivo `config.yaml` existe e está corretamente preenchido podemos rodar a aplicação com o comando abaixo:

```sh
cd scripts/flow
make run-wf
```

O serviço deve estar acessivel na URL [http://localhost:4000](http://localhost:4000).

*Obs*: Os scripts específicos para as operações do Flow deverão ser colocados na pasta `scripts/flow`.

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

## Workflow de Deploy no AWS EKS (`flow-deploy-eks.yml`)

Realiza o deploy da imagem LiteLLM no Kubernetes via `kubectl apply`, usando o manifesto `deploy/kubernetes/flow-deploy-eks.yaml`. Suporta dois ambientes com estratégias distintas.

### Gatilhos

- **Manual**: Acionado via `workflow_dispatch` na interface do GitHub Actions

### Entradas

| Campo | Obrigatório | Padrão | Descrição |
|---|---|---|---|
| `environment` | Não | `production` | Ambiente alvo: `development` ou `production` |
| `image_tag` | Não | `latest` | Tag da imagem ECR a ser implantada |

---

### Fluxo — development

Executa **inteiramente local**, sem credenciais AWS reais. O ECR é emulado pelo **moto server** e o Kubernetes por um cluster **kind** criado dentro do próprio runner.

```
resolve-image
    └─► deploy-development
            ├─ Instala kubectl e AWS CLI
            ├─ Aguarda moto server (ECR emulado)
            ├─ Instala kind
            ├─ Cria repositório ECR no moto
            ├─ Registra a tag da imagem no moto ECR
            ├─ Verifica existência da imagem (moto ECR) → expõe IMAGE_URI
            ├─ Cria cluster kind
            ├─ Carrega nginx:alpine como IMAGE_URI no kind
            ├─ Cria namespace no kind
            ├─ Aplica flow-deploy-eks.yaml (imagePullPolicy: IfNotPresent)
            ├─ Aguarda rollout
            ├─ Resumo do deploy
            └─ Destroi cluster kind (always)
```

#### Rodando localmente com `act`

1. Instalar o `act` *(se ainda não instalado)*:

```sh
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash
```

2. Executar o workflow apontando para o ambiente de desenvolvimento:

```sh
./bin/act workflow_dispatch \
  --workflows .github/workflows/flow-deploy-eks.yml \
  --input environment=development \
  --network host
```

---

### Fluxo — production

Requer aprovação manual pelo ambiente **`production`** antes de qualquer etapa. Autentica na AWS via OIDC, verifica a imagem no ECR e aplica o manifesto no cluster EKS real.

```
resolve-image
    └─► deploy-production  (aguarda aprovação manual)
            ├─ Instala kubectl e AWS CLI
            ├─ Configura credenciais AWS (OIDC / role assumption)
            ├─ Login no Amazon ECR
            ├─ Configura kubectl para o cluster EKS
            ├─ Verifica existência da imagem no ECR
            ├─ Aplica flow-deploy-eks.yaml (imagePullPolicy: Always)
            ├─ Aguarda rollout
            └─ Resumo do deploy
```
