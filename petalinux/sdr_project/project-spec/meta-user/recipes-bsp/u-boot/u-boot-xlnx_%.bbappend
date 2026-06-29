FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://platform-top.h file://bsp.cfg"
SRC_URI += "file://user_2024-09-23-11-58-00.cfg \
            file://user_2024-09-24-13-30-00.cfg \
            "

