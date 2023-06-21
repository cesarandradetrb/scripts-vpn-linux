# Scripts VPN para casos especiais em Linux

Este repositório serve para guardar scripts em shell Bash para uso com VPNs específicas, que não estão cobertas pelo uso com NetworkManager.

## Scripts

- `vpn-tokena3.sh`: conexão a uma VPN GlobalProtect usando um token USB com certificado A3. A configuração do token fica a cargo do utilizador.
  - `vpn.env.modelo`: modelo de configuração do script. Deve ser copiado para `.vpn.env` no $HOME do usuário e alterado para as configurações da sua VPN *antes* de executar o script.
  - Um gerenciador de senha pode ser utilizado para guardar a senha de login da VPN e o PIN do token A3.
- `ssl-vpnplus.sh`: conexão a uma VPN VMware SSL-VPNPlus usando o cliente Linux, que deve estar previamente instalado e configurado.

## Utilização

Os dois scripts seguem a mesma lógica de utilização: `-c` ou `--connect` conecta e `-d` ou `--disconnect` desconecta.

## Resolução de nomes internos à VPN

Nas VPNs corporativas, os nomes internos à VPN são resolvidos pelos servidores DNS internos da empresa; no entanto, em sistemas baseados em systemd, sem o NetworkManger a configuração deve ser feita explicitamente. Mais informações (em inglẽs) [aqui](https://www.gabriel.urdhr.fr/2020/03/17/systemd-revolved-dns-configuration-for-vpn/).
