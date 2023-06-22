#!/bin/bash
#
# Script de conexão e desconexão à VPN usando SSL-VPN Plus
#
# 

prog_name=$(basename $0)

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
	# Carrega $HOME/.vpnplus.env ou sai com um aviso
	#
	if [ ! -f $HOME/.vpnplus.env ]
	then
		echo "Crie o arquivo .vpnplus.env no diretório do usuário a partir do modelo em vpn.env.modelo!"
		exit 1
	else
		source $HOME/.vpn.env
	fi

	#
	# Com .vpnplus.env carregado, vamos ver se as variáveis obrigatórias existem
	#
	if [[ -z "$DNS1" || -z "$DOMAIN1" ]]
	then
		echo "Por favor, preencha as variáveis obrigatórias em .vpnplus.env!"
		exit 1
	fi

	#
	# ATENÇÃO:
	# Os exemplos abaixo estão preparados para o Bitwarden, modifique caso você use um gerenciador de senhas diferente!
	#
	# Abrindo o chaveiro do Bitwarden.
	# Se você usar um nome diferente de "SSL-VPNPlus" para guardar as informações da VPN, mude o nome.
	# Além disso, criamos um campo customizado para guardar o perfil; mude isso caso você use outro método.
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
	# Caso PERFIL, USUARIO e PASSWD estejam definidos no .vpnplus.env, usamos os valores contidos
	#
	# Como sempre, modifique para seu gerenciador de senhas.
	#
	[[ -z "$PERFIL" ]] && PERFIL=$(bw get item "SSL-VPNPlus" --session $BW_SESSION | jq -r '.fields[0] .value'))
	[[ -z "$USUARIO" ]] && USUARIO=$(bw get username "SSL-VPNPlus" --session $BW_SESSION --raw)
	[[ -z "$PASSWD" ]] && PASSWD=$(bw get password "SSL-VPNPlus" --session $BW_SESSION --raw)

	#
	# Conecta na VPN
	#
	echo "*** ATENÇÃO ***"
	naclient login -profile $PERFIL -user $USUARIO -password $PASSWD

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
