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


## UI personalizada (estilo SteamOS)

Foi adicionada uma interface base inspirada no estilo visual do SteamOS em `ui/`:

- `ui/index.html`: estrutura da home (sidebar, hero e cards de status).
- `ui/steamos-like.css`: tema escuro com foco em uso com controle/TV.
- `scripts/open-ui-preview.sh`: imprime o caminho `file://` para abrir preview local.

Pré-visualizar:

```bash
./scripts/open-ui-preview.sh
```


## Build bootável (Debian minimal + usuário + autologin)

Script novo para gerar rootfs mais completo:

```bash
./scripts/bootstrap-rootfs.sh rootfs bookworm http://deb.debian.org/debian
```

Esse script faz:
- `debootstrap` do Debian minimal (minbase);
- instala `launch-steamlink.sh` e `steamlink.service` dentro do rootfs;
- cria automaticamente usuário `steamlink`;
- configura autologin no TTY1;
- habilita `steamlink.service` no systemd do rootfs.


## Gerar ISO de instalação (protótipo)

Depois de gerar o rootfs tarball, você já pode empacotar uma ISO:

```bash
./scripts/build-image.sh rootfs build
./scripts/build-iso.sh build/steamlinkos-rootfs.tar.gz rootfs/boot/vmlinuz rootfs/boot/initrd.img build/iso-staging build/steamlinkos-installer.iso
```

O que já entrega:
- arquivo `.iso` pronto para gravar em USB;
- estrutura `/live/rootfs.tar.gz` dentro da ISO;
- menu GRUB UEFI inicial (`SteamLinkOS Installer (Prototype)`).

Próximo passo (que posso implementar em seguida):
- adicionar kernel + initramfs live;
- iniciar um instalador automático que extrai `rootfs.tar.gz` para disco alvo.


## Kernel + initramfs live + instalador automático

Implementado no fluxo de ISO:
- `scripts/build-iso.sh` agora inclui kernel (`vmlinuz`) e initramfs (`initrd.img`) em `/live/` dentro da ISO.
- `scripts/auto-install.sh` é incluído na mídia como instalador automático de disco (particiona, extrai rootfs, instala GRUB).
- `iso/boot/grub/grub.cfg` agora inicia em modo live com kernel+initramfs.

Exemplo:

```bash
./scripts/build-iso.sh   build/steamlinkos-rootfs.tar.gz   rootfs/boot/vmlinuz   rootfs/boot/initrd.img   build/iso-staging   build/steamlinkos-installer.iso
```

Após boot da mídia live, rode o instalador automático:

```bash
sudo /run/live/medium/live/auto-install.sh /dev/sda /run/live/medium/live/rootfs.tar.gz
```


## Produção: Steam Link completo (Bookworm minimal)

Provisionar stack completa no rootfs:

```bash
./scripts/bootstrap-rootfs.sh rootfs bookworm http://deb.debian.org/debian
./scripts/install-steamlink.sh rootfs bookworm
```

Arquivos principais criados/configurados:
- `scripts/install-steamlink.sh`: ativa contrib/non-free, multiarch i386, instala dependências gráficas/áudio/input, VAAPI e Steam Link.
- `/etc/sway/steamlink-kiosk.conf`: sessão Wayland kiosk sem keybinds de saída comuns.
- `/etc/systemd/system/steamlink.service`: inicia sessão sway+Steam Link como usuário `steamlink`, com restart automático.
- `/etc/systemd/system/getty@tty1.service.d/override.conf`: autologin no TTY1.
- `/usr/local/bin/steamlink-kiosk-launch.sh`: valida VAAPI com `vainfo` e faz fallback de software quando necessário.


## Alternativa para VM: ISO híbrida (BIOS + UEFI)

Se a ISO UEFI falhar no VirtualBox, gere a versão híbrida:

```bash
./scripts/build-image.sh rootfs build
./scripts/build-iso-hybrid.sh build/steamlinkos-rootfs.tar.gz rootfs/boot/vmlinuz rootfs/boot/initrd.img build/iso-hybrid-staging build/steamlinkos-installer-hybrid.iso
```

Essa abordagem usa `grub-mkrescue` e normalmente é mais compatível com VMs em modo Legacy BIOS e UEFI.
