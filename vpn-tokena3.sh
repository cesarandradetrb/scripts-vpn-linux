#!/bin/bash
#
# Script de conexão e desconexão à VPN com token A3 e VPN GlobalProtect
#
# 

prog_name=$(basename $0)

# 
# Local do pidfile
#
PID=/run/vpn.pid

#
# Ajuda
#
function help {
	echo "Uso: $prog_name [-c] [-d]"
	echo
	echo "Opções"
	echo "    -c, --connect              Conecta na VPN. Precisa ter o token A3 plugado na porta USB"
	echo "    -d, --disconnect           Desconecta a VPN caso esteja rodando"
	echo
}

function connect {
	#
	# Testa se o token está plugado na USB
	# Se o token não estiver plugado na USB, avisa e sai sem conectar
	#
	echo
	echo "Checando se o token está plugado em uma porta USB..."
	TEM_TOKEN=$(p11tool --list-tokens | grep "Token" | wc -l)
	if [[ $TEM_TOKEN -eq 1 ]]
	then
		echo "Não consegui encontrar um token!"
		exit 1
	fi

	#
	# Carrega o arquivo $HOME/.vpn.env ou sai com um aviso
	#
	if [ ! -f $HOME/.vpn.env ]
	then
		echo "Crie o arquivo .vpn.env no diretório do usuário a partir do modelo em vpn.env.modelo!"
		exit 1
	else
		source $HOME/.vpn.env
	fi

	#
	# Com .vpn.env carregado, vamos ver se as variáveis obrigatórias existem
	#
	if [[ -z "$USERCERT" || -z "$SERVERCERT" || -z "$CAFILE" || -z "$PORTAL" || -z "$GATEWAY" || -z "$USUARIO" || -z "$DNS1" || -z "$DOMAIN1" ]]
	then
		echo "Por favor, preencha as variáveis obrigatórias em .vpn.env!"
		exit 1
	fi
	
	#
	# ATENÇÃO:
	# Os exemplos abaixo estão preparados para o Bitwarden, modifique caso você use um gerenciador de senhas diferente!
	#
	# Abrindo o chaveiro do Bitwarden.
	# Se você usar um nome diferente de "Senha LDAP" para guardar a senha do LDAP, mude o nome.
	# O mesmo aviso é válido caso seu PIN do token não esteja usando o nome "PIN Token A3"
	# Se não tiver instalado o cliente console do Bitwarden, veja https://bitwarden.com/help/cli/
	#
	# Caso não tenha nenhum gerenciador de senhas instalado, pode deixar como está que o bash vai passar sem executar o login
	#

	if [ -z `which bw` ]
	then
		echo "*** ATENÇÃO ***"
		echo "É necessário desbloquear o chaveiro do Bitwarden para se logar à VPN!"
		BW_SESSION=$(bw unlock --raw)
	fi

	#
	# Caso as variáveis não-obrigatórias tenham sido definidas no .vpn.env, vamos utilizá-las
	# Se não existirem, vamos no chaveiro do Bitwarden
	#
	# Usamos uma entrada chamada "Infos VPN" com usuário e senha preenchidos e três campos personalizados com, respectivamente,
	# o certificado do usuário (USERCERT), o certificado do servidor (SERVERCERT) e o PIN do token (PIN_TOKEN).
	#
	# Caso você use uma entrada ou uma estrutura diferente, modifique.
	#
	# Modifique para seu gerenciador de senhas
	#
	[[ -z "$USERCERT" ]] && USERCERT=$(bw get item "Infos VPN" --session $BW_SESSION | jq -r '.fields[0] .value')
	[[ -z "$SERVERCERT" ]] && SERVERCERT=$(bw get item "Infos VPN" --session $BW_SESSION | jq -r '.fields[1] .value')
	[[ -z "$USUARIO" ]] && USUARIO=$(bw get username "Infos VPN" --session $BW_SESSION --raw)
	[[ -z "$PASSWD" ]] && PASSWD=$(bw get password "Infos VPN" --session $BW_SESSION --raw)
	[[ -z "$PIN_TOKEN" ]] && PIN_TOKEN=$(bw get notes "Infos VPN" --session $BW_SESSION)

	#
	# Estando tudo bem, avisamos ao utilizador que vamos nos conectar
	#
	echo
	echo "Conectando à VPN, por favor aguarde..."

	#
	# Conecta com o Openconnect
	#
	echo $PASSWD | sudo openconnect --authgroup=$GATEWAY --certificate=$USERCERT --servercert=$SERVERCERT --protocol=gp --cafile=$CAFILE --disable-ipv6 --syslog --pid-file=$PID --background $PORTAL --user=$USUARIO --passwd-on-stdin --key-password=$PIN_TOKEN

    #
    # Já que a saída está toda no syslog, precisamos checar se *realmente* estamos conectados.
    # Para isso, precisamos esperar a VPN estabilizar (ou não)
    #
    echo "Esperando a VPN estabilizar... Aguarde!"
    sleep 30 
    ENDIP=$(ip a show dev tun0 2>/dev/null | grep -w "inet" | cut -d " " -f 6 | cut -d "/" -f 1)
    if [[ -z $ENDIP ]]
    then
            echo "Não consegui identificar um endereço IP! Verifique se estamos logados na VPN."
            exit 1
    else
            echo "Estamos conectados à VPN com o IP "$ENDIP
    fi

	#
	# Pelo menos no Ubuntu 20.04+, o openconnect não está configurando automaticamente os DNS e os domínios de search para a conexão da VPN
	# Por isso, as linhas abaixo são necessárias
	#
	# Dica retirada de https://www.gabriel.urdhr.fr/2020/03/17/systemd-revolved-dns-configuration-for-vpn/
	#
	sudo resolvectl dns tun0 $DNS1 $DNS2
	sudo resolvectl domain tun0 $DOMAIN1 $DOMAIN2
}

function disconnect {
	#
	# Checando para saber se a VPN está rodando pelo arquivo PID
	#
	echo
	echo "Checando se a VPN está realmente conectada..."
	if [[ ! -f $PID ]]
	then
		echo "Não encontrei o arquivo de PID da VPN. A VPN está ligada?"
		exit 1
	fi
	#
	# Se estiver rodando, fecha a conexão com um SIGINT para o processo
	# Usamos o sudo para matar o processo, já que a VPN rodou como root via sudo.
	#
	echo
	echo "Encerrando a VPN"
	PIDNUM=$(cat $PID)
	sudo kill -SIGINT $PIDNUM
	sleep 10
	echo "Desconectados!"
}

#
# Laço principal
#
subcommand=$1

#
# Limpa a tela e apresenta um banner
#
clear
echo "     SCRIPT DE CONTROLE DE CONEXÃO À VPN USANDO TOKEN A3"
echo

#
# Executa os subcomandos ou devolve com erro ou ajuda
#
case $subcommand in
	"" | "-h" | "--help")
	help
	;;
	"-c" | "--connect")
	connect
	;;
	"-d" | "--disconnect")
	disconnect
	;;
	*)
	echo "Erro: '$subcommand' não é um subcomando conhecido." >&2
	echo "       Execute '$prog_name --help' para ajuda dos subcomandos." >&2
	exit 1
	;;
esac
