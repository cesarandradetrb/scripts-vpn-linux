#!/bin/bash
#
# Script de conexão e desconexão à Tailscale VPN
#
#

prog_name=$(basename $0)

# 
# Definimos as variáveis que utilizaremos em caso de conexão
# TODAS as modificações de personalização do script são feitas aqui
#
# Modifique os DNS para os servidores que você deseja utilizar
# 
DNS1="0.0.0.0"
DNS2="0.0.0.0"
#
# O padrão é rotear todo o tráfego pela VPN Tailscale
#
DOMAIN1="~."

#
# Ajuda
#
function help {
	echo "Uso: $prog_name [-c] [-d]"
	echo
	echo "Opções"
	echo "    -c, --connect <endereço_ip>  Conecta na VPN usando o endereço_ip do exit node."
	echo "    -d, --disconnect             Desconecta da VPN."
	echo
}

#
# Testamos um IPv4 para ver se é válido
# Precisamos checar porque o IPv4 do exit node é fornecido como argumento de conexão
#
# Retirado de https://www.linuxjournal.com/content/validating-ip-address-bash-script
#
function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function connect {
	#
	# Conectando
	# Este script não garante que o exit node esteja corretamente configurado
	# Isto deve ser feito ANTES de rodar este script
	#
	# Derrubamos e levantamos o Tailscale usando o exit node desejado
	#
	sudo tailscale down
	sudo tailscale up --exit-node=$exitip
	#
	# Apontamos os DNS e os resolvers de domínios de busca que queremos para a conexão da VPN (tailscale0)
	#
	# Dica retirada de https://www.gabriel.urdhr.fr/2020/03/17/systemd-revolved-dns-configuration-for-vpn/
	#
	sudo resolvectl dns tailscale0 $DNS1 $DNS2
	sudo resolvectl domain tailscale0 $DOMAIN1 
}

function disconnect {
	#
	# Desconectando
	# Derrubando a Tailscale e levantando sem exit node
	#
	sudo tailscale down
	sudo tailscale up --exit-node=""
}

#
# Laço principal
#
subcommand=$1


#
# Limpa a tela e apresenta um banner
#
clear
echo "     SCRIPT DE CONTROLE DE CONEXÃO À TAILSCALE VPN"
echo

#
# Executa os subcomandos ou devolve com erro ou ajuda
#
case $subcommand in
	"" | "-h" | "--help")
	help
	;;
	"-c" | "--connect")
	exitip=$2
	if valid_ip $exitip
	then
		connect
	else
		echo "Não foi fornecido o endereço IP do exit node!"
		echo "O endereço IP do exit node pode ser consultado a partir do dispositivo configurado"
		echo "ou consultando https://login.tailscale.com/admin/machines"
		echo
		echo "Saindo..."
		echo
		help
		exit 1
	fi
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
