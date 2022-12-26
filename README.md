# Scripts VPN para casos especiais em Linux

Este repositório serve para guardar scripts em shell Bash para uso com VPNs específicas, que não estão cobertas pelo uso com NetworkManager.

## Scripts

- `vpn-tokena3.sh`: conexão a uma VPN GlobalProtect usando um token USB com certificado A3. A configuração do token fica a cargo do utilizador.
- `ssl-vpnplus.sh`: conexão a uma VPN VMware SSL-VPNPlus usando o cliente Linux, que deve estar previamente instalado e configurado.
- `tailscale-vpn.sh`: conexão a um exit node [Tailscale](https://tailscale.com); Tailscale deve estar instalado e configurado.

## Utilização

Os três scripts seguem a mesma lógica de utilização: `-c` ou `--connect` conecta e `-d` ou `--disconnect` desconecta.

Atenção: `tailscale-vpn.sh` exige o IP do exit node como argumento de `-c` ou `--connect`.

## Resolução de nomes internos à VPN

Nas VPNs corporativas, os nomes internos à VPN são resolvidos pelos servidores DNS internos da empresa; no entanto, em sistemas baseados em systemd, sem o NetworkManger a configuração deve ser feita explicitamente. Mais informações (em inglẽs) [aqui](https://www.gabriel.urdhr.fr/2020/03/17/systemd-revolved-dns-configuration-for-vpn/).

Usamos a mesma técnica em `tailscale-vpn.sh` que, apesar de não ser uma VPN corporativa, pode ser usada para garantir segurança em redes inseguras ou hostis (p.ex. Wi-Fi públicos).
