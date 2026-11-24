# SPDX-License-Identifier: Apache-2.0
#
# Controle de debloat do produto aosp_rpi4_fliperama.
# Inclui o módulo FliperamaDebloat, que utiliza `overrides: [...]` em
# packages/FliperamaDebloat/Android.bp para impedir que APKs indesejados
# entrem na imagem final sem apagar arquivos do AOSP base.

PRODUCT_PACKAGES += \
    FliperamaDebloat
