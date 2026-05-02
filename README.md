# SteamLinkOS

Projeto para criar uma distribuição Linux enxuta com foco em executar o **Steam Link** como experiência principal do sistema.

## Objetivo

Construir um sistema operacional baseado em Linux que:

- inicialize rápido;
- abra direto em uma interface de streaming local (Steam Link);
- tenha modo quiosque (kiosk) para TV/sala;
- permita manutenção remota e atualização OTA.

## Arquitetura proposta (MVP)

1. **Base Linux**
   - Debian minimal ou Arch minimal;
   - kernel com drivers de GPU, áudio e controle Bluetooth.

2. **Sessão gráfica mínima**
   - Wayland + compositor leve (ex.: sway/weston);
   - autologin do usuário `steamlink`.

3. **Inicialização automática do Steam Link**
   - serviço `systemd` inicia sessão e app;
   - watchdog para reiniciar app em caso de falha.

4. **Configuração e persistência**
   - `/etc/steamlinkos/config.env` para opções (resolução, áudio, rede);
   - armazenamento persistente para pareamento e cache.

5. **Atualizações**
   - estratégia A/B para rollback seguro;
   - canal `stable` e `beta`.

## Roadmap

### Fase 1 — Bootstrap
- [ ] escolher distro base;
- [ ] gerar imagem inicial bootável;
- [ ] configurar `systemd` e autologin.

### Fase 2 — Experiência Steam Link
- [ ] empacotar/instalar Steam Link;
- [ ] inicialização direta em fullscreen;
- [ ] fallback para shell de suporte.

### Fase 3 — Hardware e UX
- [ ] suporte completo a gamepads (USB/Bluetooth);
- [ ] áudio HDMI e P2;
- [ ] ajuste de resolução e overscan.

### Fase 4 — Entrega
- [ ] instalador/imagem release;
- [ ] atualizador OTA;
- [ ] documentação de troubleshooting.

## Próximos passos imediatos

1. Definir base: Debian minimal ou Arch minimal.
2. Criar script de provisionamento de pacote base.
3. Implementar unidade `systemd` para launch automático do Steam Link.
4. Testar em hardware alvo (x86_64 mini PC / Raspberry Pi compatível).

---

Se quiser, no próximo passo eu já monto a estrutura de diretórios (`build/`, `rootfs/`, `systemd/`, `scripts/`) e os primeiros scripts de build da imagem.
