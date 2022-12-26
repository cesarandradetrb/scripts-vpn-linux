#!/bin/bash
#
# Script de conexão e desconexão à VPN usando SSL-VPN Plus
#
# 

prog_name=$(basename $0)

# 
# Definimos as variáveis que utilizaremos em caso de conexão
# TODAS as modificações de personalização do script são feitas aqui
#
PERFIL="perfil"
USUARIO="usuario"
# Estas variáveis não são necessárias caso a conexão VPN sete automaticamente os DNS
DNS1=0.0.0.0
DOMAIN1="~interno"

#
# Ajuda
#
function help {
	echo "Uso: $prog_name [-c] [-d]"
	echo
	echo "Opções"
	echo "    -c, --connect              Conecta na VPN."
	echo "    -d, --disconnect           Desconecta da VPN."
	echo
}

function connect {
	#
	# Conecta na VPN
	# O utilizador é alertado de que precisa da senha do SSL-VPN Plus
	#
	echo "*** ATENÇÃO ***"
	echo "Entre com a senha do SSL-VPN Plus quando solicitado"
	naclient login -profile $PERFIL -user $USUARIO

    #
    # Já que a saída está toda no syslog, precisamos checar se *realmente* estamos conectados.
    # Para isso, precisamos esperar a VPN estabilizar (ou não)
    #
    ENDIP=$(ip a show dev tap0 2>/dev/null | grep -w "inet" | cut -d " " -f 6 | cut -d "/" -f 1)
    if [[ -z $ENDIP ]]
    then
        echo "Não consegui identificar um endereço IP! Verifique se estamos logados na VPN."
        exit 1
    else
        echo "Estamos conectados à VPN com o IP "$ENDIP
    fi

	#
	# Apontamos os DNS e os resolvers de domínios de busca que queremos para a conexão da VPN (tap0)
	#
	# Dica retirada de https://www.gabriel.urdhr.fr/2020/03/17/systemd-revolved-dns-configuration-for-vpn/
	#
	sudo resolvectl dns tap0 $DNS1
	sudo resolvectl domain tap0 $DOMAIN1
}

function disconnect {
	#
	# Se estiver rodando, fecha a conexão com um logout normal
	#
    ENDIP=$(ip a show dev tap0 2>/dev/null | grep -w "inet" | cut -d " " -f 6 | cut -d "/" -f 1)
    if [[ -z $ENDIP ]]
    then
        echo "Não consegui identificar um endereço IP! Verifique se estamos logados na VPN."
        exit 1
    else
	    echo "Desligando a VPN..."
	    naclient logout -profile $PERFIL
	fi
}

#
# Laço principal
#
subcommand=$1


#
# Limpa a tela e apresenta um banner
#
clear
echo "     SCRIPT DE CONTROLE DE CONEXÃO À VPN USANDO SSL-VPNPLUS"
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
