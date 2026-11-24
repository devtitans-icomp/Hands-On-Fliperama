# Hands-On-Fliperama

Repositório de customização do **AOSP 14 (Raspberry Vanilla / KonstaKANG)** para **Raspberry Pi 4** no projeto **Hands-On Fliperama**.

---

## 1. Como o repositório funciona (Mapa Geral)

O AOSP completo possui mais de **1.280 repositórios Git independentes** gerenciados pela ferramenta `repo` e ocupa mais de 100 GB (somente `prebuilts/` tem ~58 GB). Por isso, **não versionamos a raiz do AOSP**.

Em vez disso, este repositório vive isolado dentro de:

```text
<AOSP_ROOT>/device/Hands-On-Fliperama/
```

Ele atua em **duas camadas**:

1. **Camada própria do produto (`aosp_rpi4_fliperama`)**:
   - Herda a configuração base da Raspberry Pi 4 (`device/brcm/rpi4/aosp_rpi4.mk`) mantendo `PRODUCT_DEVICE := rpi4`, o que reaproveita integralmente `BoardConfig.mk`, kernel/firmwares e o script `./rpi4-mkimg.sh`.
   - Concentra debloat (remoção de APKs via `overrides`), propriedades customizadas (`props.mk`), overlays de recursos do Android (`RRO`) e eventuais novos apps/serviços do grupo.
2. **Camada de patches (`patches/`)**:
   - Quando for necessário alterar arquivos diretamente em repositórios nativos do AOSP (ex.: `frameworks/base`, `packages/apps/Settings`, `device/brcm/rpi4`, `external/minigbm`, `system/core`), o script `scripts/export_patches.sh` captura apenas o diff desses repositórios via `repo` e salva em `patches/`.
   - Os demais colaboradores aplicam tudo automaticamente rodando `scripts/apply_patches.sh`.

```text
Base comum (todos sincronizam igual via `repo`)
  AOSP android-14.0.0_r67 + Raspberry Vanilla (android-14.0)
            │
            ├── device/Hands-On-Fliperama/   <-- ESTE REPO NO GITHUB
            │     ├── Produto derivado (aosp_rpi4_fliperama)
            │     ├── Debloat (overrides de APKs)
            │     ├── Overlays (RRO) e Propriedades (props.mk)
            │     ├── Manifests de referência (manifests/)
            │     └── Patches para repos nativos do AOSP (patches/)
            │
            └── Saída de compilação (out/ - nunca vai para o Git)
                  ├── out/target/product/rpi4/   -> Raspberry Pi 4 (arm64)
                  └── out/target/product/emu64x/ -> Emulador (x86_64)
```

---

## 2. Requisitos

### Hardware e Sistema
- **SO:** Ubuntu 22.04 LTS (64-bit)
- **RAM:** 16 GB ou mais (se tiver 15–16 GB, configure swap e compile com `-j8`)
- **Disco livre:** mínimo recomendado de **250 GB** (AOSP + build da RPi 4; ~300 GB se compilar também o emulador)

### Pacotes do sistema (rodar com `sudo`)
Além dos [requisitos padrão do AOSP](https://source.android.com/docs/setup/start/requirements) (`git`, `repo`, `curl`, etc.), instale as dependências do Raspberry Vanilla:

```bash
sudo apt-get update
sudo apt-get install -y bc coreutils dosfstools e2fsprogs fdisk kpartx mtools ninja-build pkg-config python3-pip rsync
sudo pip3 install meson mako jinja2 ply pyyaml dataclasses
```

> **Importante:** o `meson` deve ser instalado via `pip3` (e não via `apt`), pois o `external/mesa3d` exige `meson >= 1.1.0` e o Ubuntu 22.04 distribui `0.61.2`.

### Base AOSP obrigatória
- **Tag AOSP:** `android-14.0.0_r67` (`BUILD_ID=AP2A.240905.003`)
- **Local manifests:** arquivos em `manifests/` (`manifest_brcm_rpi.xml` e `remove_projects.xml` do branch `android-14.0` do `raspberry-vanilla/android_local_manifest`)

---

## 3. Setup inicial (para cada colaborador)

### Passo 1 — Inicializar o AOSP base
Na pasta do seu AOSP (se já tiver um AOSP 14 anterior, pode rodar o `repo init` por cima para reaproveitar o download):

```bash
mkdir -p ~/aosp && cd ~/aosp
repo init -u https://android.googlesource.com/platform/manifest -b android-14.0.0_r67 --depth=1
```

### Passo 2 — Clonar este repositório em `device/Hands-On-Fliperama`
```bash
git clone https://github.com/devtitans-icomp/Hands-On-Fliperama.git device/Hands-On-Fliperama
```

### Passo 3 — Configurar os manifests da Raspberry Pi 4 e sincronizar
```bash
./device/Hands-On-Fliperama/scripts/setup_manifests.sh
repo sync -c --no-tags --no-clone-bundle --force-sync -j8
```

### Passo 4 — Aplicar os patches do projeto no AOSP
```bash
./device/Hands-On-Fliperama/scripts/apply_patches.sh
```

---

## 4. Como compilar

### Para a Raspberry Pi 4 (produto do Fliperama)
```bash
cd ~/aosp
source build/envsetup.sh
lunch aosp_rpi4_fliperama-ap2a-userdebug
make bootimage systemimage vendorimage -j8
```

Para gerar o arquivo `.img` gravável no cartão microSD (exige `sudo`):
```bash
./rpi4-mkimg.sh
```
Saída: `out/target/product/rpi4/RaspberryVanillaAOSP14-<DATA>-rpi4_fliperama.img`.

> Para gravar apenas uma partição atualizada direto no cartão SD já formatado: `./rpi4-wrimg.sh [boot|system|vendor|wipe]`.

### Para o Emulador (testes locais no PC / `adb shell`)
Graças ao patch `patches/external__minigbm.patch`, o emulador `x86_64` coexiste na mesma árvore:
```bash
cd ~/aosp
source build/envsetup.sh
lunch sdk_phone64_x86_64-ap2a-userdebug
m -j8
emulator
```

---

## 5. Como registrar modificações no repositório

Use sempre **branches e Pull Requests** para coordenar os 6 colaboradores.

### A) Remover APKs / Debloat
1. Descubra o nome do módulo APK (em `Android.bp`/`Android.mk` do app ou em `out/target/product/rpi4/installed-files.txt`).
2. Adicione o nome do módulo na lista `overrides: [...]` em `packages/FliperamaDebloat/Android.bp`.
3. Faça `git commit` e `git push` normalmente dentro de `device/Hands-On-Fliperama`.

### B) Alterar configurações internas do Android (sem editar `frameworks/base`)
- **Recursos XML do framework (`config.xml`):** edite `overlay/FliperamaFrameworkOverlay/res/values/config.xml` (ou crie novos RROs em `overlay/` para `Settings`, `SystemUI`, `SettingsProvider`, etc., registrando-os em `aosp_rpi4_fliperama.mk`).
- **Propriedades (`ro.*`, `persist.*`):** adicione em `props.mk`.

### C) Adicionar novos apps, serviços ou arquivos de init/SELinux
- Crie o módulo dentro de `device/Hands-On-Fliperama/packages/` (ou subpasta própria) e adicione o nome do módulo em `PRODUCT_PACKAGES` no arquivo `aosp_rpi4_fliperama.mk`.

### D) Modificar arquivos diretamente em pastas nativas do AOSP
*(Ex.: `frameworks/base`, `packages/apps/Settings`, `device/brcm/rpi4`, `system/core`, etc.)*
1. Edite normalmente os arquivos na pasta desejada do AOSP.
2. Se você **criou um arquivo novo** dentro de uma pasta nativa do AOSP, marque-o para o diff antes de exportar:
   ```bash
   git -C <caminho_do_repo_aosp> add -N <caminho_do_arquivo_novo>
   ```
3. Exporte todas as mudanças automaticamente para `patches/`:
   ```bash
   ./device/Hands-On-Fliperama/scripts/export_patches.sh
   ```
4. Commit e push dentro de `device/Hands-On-Fliperama/`:
   ```bash
   cd device/Hands-On-Fliperama
   git status -u
   git add patches/
   git commit -m "descreva sua alteracao"
   git push origin <sua-branch>
   ```

### E) Atualizar sua máquina com mudanças dos colegas
```bash
cd ~/aosp/device/Hands-On-Fliperama
git pull origin main
./scripts/apply_patches.sh
```

---

## 6. Explicação de cada arquivo e pasta do repositório

| Caminho | Para que serve |
| --- | --- |
| `.gitignore` | Evita que arquivos temporários, logs, imagens `.img` e diretórios de editor/build entrem no Git. |
| `README.md` | Documentação principal: arquitetura, requisitos, setup, compilação e guia de contribuição. |
| `Android.bp` | Declara `soong_namespace {}` para isolar os módulos Soong deste projeto sem conflitar com outros alvos do AOSP. |
| `AndroidProducts.mk` | Registra o produto `aosp_rpi4_fliperama.mk` no sistema de build para que `aosp_rpi4_fliperama-ap2a-userdebug` apareça no `lunch`. |
| `aosp_rpi4_fliperama.mk` | Definição principal do produto: herda `device/brcm/rpi4/aosp_rpi4.mk`, ativa o namespace deste repo, inclui overlays, `debloat.mk` e `props.mk`, e define o nome do produto mantendo `PRODUCT_DEVICE := rpi4`. |
| `debloat.mk` | Centraliza as regras de debloat incluídas no produto (como o pacote `FliperamaDebloat`). |
| `props.mk` | Define propriedades customizadas (`PRODUCT_VENDOR_PROPERTIES`) aplicadas na partição `/vendor` do Fliperama. |
| `overlay/FliperamaFrameworkOverlay/Android.bp` | Declara o pacote RRO (`runtime_resource_overlay`) instalado em `/vendor/overlay` para sobrescrever recursos do framework Android. |
| `overlay/FliperamaFrameworkOverlay/AndroidManifest.xml` | Configura o overlay como estático (`isStatic="true"`) com `targetPackage="android"` e `priority="10"` (acima do `AndroidRpiOverlay`, que tem `priority="0"`). |
| `overlay/FliperamaFrameworkOverlay/res/values/config.xml` | Arquivo onde ficam as chaves XML sobrescritas de `frameworks/base/core/res/res/values/config.xml`. |
| `packages/FliperamaDebloat/Android.bp` | Módulo `android_app` sem código cuja lista `overrides: [...]` remove APKs padrão do AOSP da imagem final sem apagar código da árvore base. |
| `packages/FliperamaDebloat/AndroidManifest.xml` | Manifesto mínimo (`hasCode="false"`) exigido pelo Soong para empacotar `FliperamaDebloat`. |
| `manifests/manifest_brcm_rpi.xml` | Cópia do manifest do Raspberry Vanilla (`android-14.0`) que adiciona os repositórios de hardware/kernel/GPU/Wi-Fi da Raspberry Pi 4 e 5. |
| `manifests/remove_projects.xml` | Cópia do manifest que remove projetos desnecessários (Pixels, Qualcomm, macOS) para economizar espaço e tempo de sync. |
| `patches/external__minigbm.patch` | Patch em `external/minigbm/gbm_mesa_driver/Android.mk` que condiciona `libgbm_mesa_wrapper` a `BOARD_MESA3D_BUILD_LIBGBM=true`, permitindo compilar tanto RPi 4 quanto o emulador `sdk_phone64_x86_64` na mesma árvore. |
| `scripts/setup_manifests.sh` | Copia os XMLs de `manifests/` para `<AOSP_ROOT>/.repo/local_manifests/`. |
| `scripts/export_patches.sh` | Varre todos os repositórios listados em `.repo/project.list` e gera arquivos `.patch` em `patches/` para qualquer pasta nativa do AOSP modificada. |
| `scripts/apply_patches.sh` | Aplica todos os arquivos `.patch` de `patches/` nos respectivos repositórios do AOSP (de forma idempotente: pula os que já estiverem aplicados). |
