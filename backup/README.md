# Shell Script Backup

Script para automatizar tarefa de backup local e remoto...

## Features

* Monta partição
* Cria e compacta (prepara) arquivo
* Monitora andamento de processos  
* Faz backup local
* Faz backup remoto em Google Drive

## Dependências e instalação

__JQ__: Linha de comando para processar arquivo Json.

> __Instalação__:  
> Debian e derivados: `sudo apt  install jq`

__PV monitor__: Monitora progresso de comandos comuns ao Linux baseado na entrada e saída.

> __Instalação__:  
> Debian e derivados: `sudo apt  install pv`

__Rclone__: Linha de comando para gerenciamento de arquivos na nuvem.

> __Instalação__: Detalhes de instalação [aqui](https://rclone.org/install/)

## Como funciona

Basicamente o script espera três parâmetros para executar rotinas.

### Parâmetros:

1. Fonte (diretório alvo) o qual deseja realizar o backup.
2. Destino (diretório) o qual deseja realizar o **backup local**.
3. Destino (diretório) o qual deseja realizar o **backup remoto**. Ex. uma pasta no Google Drive.

### Executando script:

Ex: `./backup.sh /home /media/BACKUP BACKUP/LINUX`

> __Observação__: É necessario conceder permissão de execução em arquivo. Execute: `chmod +x arquivo`

### :stuck_out_tongue_winking_eye: That's all folks!
