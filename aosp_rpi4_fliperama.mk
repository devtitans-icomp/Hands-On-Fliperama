# SPDX-License-Identifier: Apache-2.0

# Herda a configuração base da Raspberry Pi 4 (Raspberry Vanilla AOSP 14)
$(call inherit-product, device/brcm/rpi4/aosp_rpi4.mk)

# Namespace Soong para os módulos deste repositório (overlays, debloat, apps, serviços)
PRODUCT_SOONG_NAMESPACES += device/Hands-On-Fliperama

# Overlays customizados do Fliperama
PRODUCT_PACKAGES += \
    FliperamaFrameworkOverlay

# Debloat (remoção de APKs/pacotes) e propriedades customizadas
$(call inherit-product, device/Hands-On-Fliperama/debloat.mk)
$(call inherit-product, device/Hands-On-Fliperama/props.mk)

# Identificação do produto (mantém PRODUCT_DEVICE := rpi4 para reaproveitar BoardConfig.mk e rpi4-mkimg.sh)
PRODUCT_DEVICE := rpi4
PRODUCT_NAME := aosp_rpi4_fliperama
PRODUCT_BRAND := Raspberry
PRODUCT_MODEL := Pi 4 Fliperama
PRODUCT_MANUFACTURER := Raspberry
