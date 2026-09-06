# D-109 host-remediation inventory

## Scope and privacy

Read-only inventory collected after the invalid/incomplete Wi-Fi qualification attempts.
Serial number, SSID, BSSID, MAC, IP and gateway are omitted. No BIOS, driver, power-plan,
device or operating-system setting was changed.

## Local inventory

- System: ASUS TUF Gaming F15, model `FX506LHB`
- BIOS: `FX506LHB.311`, release date 2022-02-09
- Wi-Fi: MediaTek Wi-Fi 6 MT7921, driver `3.0.1.1314`, driver date 2023-10-12
- Wi-Fi parent: Intel PCI Express Root Port #14 (`VEN_8086`, `DEV_06B5`), driver `10.1.31.2`
- Active AC PCIe Link State Power Management: Off
- Active DC PCIe Link State Power Management: Maximum power savings

## Official-source comparison

ASUS lists MediaTek WLAN `V3.00.01.1314` for the MT7921 device and Intel Chipset Software
`V10.1.31.2` for this model family. These match the installed versions. The ASUS BIOS page
visible during review lists version `310`, while the system has `311`; downgrade is not an
approved remediation.

Sources checked 2026-09-06:

- https://www.asus.com/supportonly/fx506lhb/helpdesk/
- https://www.asus.com/supportonly/fx506lh/helpdesk_download/
- https://www.asus.com/us/supportonly/fx506lh/helpdesk_bios/

## Evidence and disposition

The same Wi-Fi PCIe parent produced two post-run WHEA-Logger Event 17 clusters: 307 events
after `ob-host-network-portability-wifi-001` and 12 after
`ob-host-network-portability-wifi-002`. Both qualification attempts remain consumed and
invalid/incomplete for independent telemetry-close tooling failures. Current official ASUS
driver comparison exposes no newer WLAN or chipset package, and no supported BIOS upgrade was
identified.

Further long Wi-Fi qualification, scientific normal or fault runtime is blocked on this exact
adapter/driver/host path until ASUS support or qualified service identifies a remediation and a
new clean-boot, prospective host qualification is approved. Disabling WHEA reporting, relaxing
the `0/0/0` gate, changing PCIe power policy, installing third-party drivers or downgrading BIOS
is not authorized.
