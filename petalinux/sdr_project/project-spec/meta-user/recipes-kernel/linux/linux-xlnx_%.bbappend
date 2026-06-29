FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"
KERNEL_FEATURES:append = " bsp.cfg"
SRC_URI += "file://user_2024-09-23-12-05-00.cfg \
            file://user_2024-09-23-12-10-00.cfg \
            file://user_2026-05-14-13-23-00.cfg \
            file://user_2026-06-21-01-43-00.cfg \
            "

