#!/bin/bash
#
# Script de conexão e desconexão à VPN com token A3 e VPN GlobalProtect
#
# 

prog_name=$(basename $0)

# 
# Definimos as variáveis que utilizaremos em caso de conexão
# TODAS as modificações de personalização do script são feitas aqui
#
USERCERT="certificado-do-usuario"
SERVERCERT="certificado-do-servidor"
CAFILE="/local/da/cadeia/do/token/a3.pem"
PORTAL="portal.vpn.com.br"
USUARIO="usuario@servidor.com.br"
# Descomente a variável GATEWAY para o authgroup desejado
#GATEWAY="GW_EXT_DCSP_A3"
GATEWAY="GW_EXT_DCDF_A3"
# Estas variáveis não são necessárias caso a conexão VPN sete automaticamente os DNS
DNS1=0.0.0.0
DNS2=0.0.0.0
DOMAIN1="~interno"
DOMAIN2="~interno.com.br"

#
# Variáveis que não serão modificadas
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

function check_root {
	#
	# Checando se estamos rodando como root
	#
	echo "Checando se estamos rodando como root..."
	if [[ $(id -u) -ne 0 ]]
	then
  		echo "Este script precisa rodar como root!"
 		echo "Use o comando \"sudo\" para executar este script."
 		exit 1
	fi
}

function connect {
	check_root
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
	# Se o token estiver plugado, conecta com o Openconnect
	# O utilizador é alertado que precisa do PIN do token *e* da senha LDAP 
	#
	echo "*** ATENÇÃO ***"
	echo "Entre com o PIN do token e a senha de login."
	openconnect --authgroup $GATEWAY --certificate $USERCERT --servercert $SERVERCERT --protocol=gp --cafile=$CAFILE --disable-ipv6 --syslog --pid-file=$PID --background $PORTAL --user $USUARIO

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
	# Apontamos os DNS e os resolvers de domínios de busca que queremos para a conexão da VPN (tun0)
	#
	# Dica retirada de https://www.gabriel.urdhr.fr/2020/03/17/systemd-revolved-dns-configuration-for-vpn/
	#
	resolvectl dns tun0 $DNS1 $DNS2
	resolvectl domain tun0 $DOMAIN1 $DOMAIN2
}

function disconnect {
	check_root
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
	#
	echo
	echo "Encerrando a VPN"
	PIDNUM=$(cat $PID)
	kill -SIGINT $PIDNUM
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
