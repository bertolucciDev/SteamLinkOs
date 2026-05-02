# SteamLinkOS

Distribuição Linux minimalista baseada em **Debian minimal** para inicializar direto em uma experiência Steam Link (modo quiosque).

## Estrutura inicial do projeto

- `scripts/provision-base.sh`: prepara configuração base no rootfs.
- `scripts/build-image.sh`: empacota o rootfs em tarball.
- `scripts/launch-steamlink.sh`: launcher do Steam Link usado pelo `systemd`.
- `systemd/steamlink.service`: unidade para iniciar/reiniciar Steam Link automaticamente.
- `rootfs/etc/steamlinkos/config.env`: configuração padrão de runtime.

## Como começar (MVP)

1. Preparar arquivos base:
   ```bash
   ./scripts/provision-base.sh rootfs
   ```
2. Instalar launcher no rootfs final em `/usr/local/bin/launch-steamlink.sh`.
3. Instalar a unit `systemd/steamlink.service` em `/etc/systemd/system/`.
4. Gerar pacote do rootfs:
   ```bash
   ./scripts/build-image.sh rootfs build
   ```

## Próximos passos

- Integrar debootstrap para gerar rootfs Debian minimal automaticamente.
- Adicionar usuário `steamlink` e autologin no display manager.
- Trocar placeholder `/usr/bin/steamlink` por pacote/binário definitivo.
- Criar pipeline de imagem bootável (ISO/IMG).
