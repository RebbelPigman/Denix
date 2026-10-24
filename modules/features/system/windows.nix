{ ... }: {
  # VirtualBox host + a Windows 11 Pro VM definition.
  # Import on the host that should run it:
  #   self.nixosModules.windows
  #
  # Product key and guest password stay in /var/lib/denix-windows.
  # Never put either in this repo or in a Nix option.
  flake.nixosModules.windows = { config, lib, pkgs, ... }:
  let
    cfg = config.denix.windows;
    cfgFile = pkgs.writeText "denix-windows.json" (builtins.toJSON {
      vmName = "Windows11Pro";
      stateDir = "/var/lib/denix-windows";
      iso = cfg.iso;
      memoryMB = cfg.memoryMB;
      cpus = cfg.cpus;
      diskMB = cfg.diskMB;
      hostUser = cfg.user;
      guestUser = cfg.user;
      locale = "en_US";
      country = "ZA";
      timeZone = "South Africa Standard Time";
      hostname = "windows.local";
    });
    py = pkgs.writers.writePython3Bin "denix-windows-vm" { doCheck = false; } ''
      import getpass
      import json
      import os
      import re
      import secrets
      import string
      import subprocess
      import sys

      KEY_RE = re.compile(r"[A-Za-z0-9]{5}(?:-[A-Za-z0-9]{5}){4}")

      class VmError(Exception):
          pass

      def log(msg):
          print(msg, flush=True)

      def redact(text):
          return KEY_RE.sub("[redacted]", text or "")

      def load_cfg():
          path = os.environ.get("DENIX_WINDOWS_CONFIG")
          if not path:
              raise VmError("DENIX_WINDOWS_CONFIG is unset")
          with open(path) as fh:
              return json.load(fh)

      def vbox(args, check=True):
          try:
              proc = subprocess.run(
                  ["VBoxManage", "--nologo", *args],
                  text=True,
                  capture_output=True,
                  timeout=30,
              )
          except subprocess.TimeoutExpired:
              raise VmError("VBoxManage timed out. VM is probably running. Not printing args.")
          out = redact((proc.stdout or "") + (proc.stderr or ""))
          if check and proc.returncode != 0:
              sys.stderr.write(out)
              raise VmError("VBoxManage failed")
          return proc.returncode, out

      def require_host_user(cfg):
          if getpass.getuser() != cfg["hostUser"]:
              raise VmError("run as " + cfg["hostUser"] + ", not " + getpass.getuser())

      def paths(cfg):
          state = cfg["stateDir"]
          vm = cfg["vmName"]
          return {
              "state": state,
              "base": os.path.join(state, "vms"),
              "vm_dir": os.path.join(state, "vms", vm),
              "disk": os.path.join(state, "vms", vm, vm + ".vdi"),
              "key": os.path.join(state, "product-key"),
              "msdm": os.path.join(state, "MSDM.bin"),
              "password": os.path.join(state, "password"),
              "stamp": os.path.join(state, "install-started"),
          }

      def vboxdrv_ready():
          return os.path.exists("/dev/vboxdrv")

      def vm_registered(cfg):
          code, out = vbox(["list", "vms"], check=False)
          if code != 0:
              return False
          return '"' + cfg["vmName"] + '"' in out

      def vm_state(cfg):
          code, out = vbox(["showvminfo", cfg["vmName"], "--machinereadable"], check=False)
          if code != 0:
              return ""
          for line in out.splitlines():
              if line.startswith("VMState="):
                  return line.split("=", 1)[1].strip().strip('"')
          return ""

      def ensure_dirs(p):
          os.makedirs(p["base"], mode=0o700, exist_ok=True)
          os.chmod(p["state"], 0o700)
          os.chmod(p["base"], 0o700)

      def apply_firmware(cfg):
          vm = cfg["vmName"]
          if vm_state(cfg) not in ("", "poweroff", "aborted"):
              log("VM is " + vm_state(cfg) + "; not changing firmware")
              return
          vbox([
              "modifyvm", vm,
              "--ostype", "Windows11_64",
              "--memory", str(cfg["memoryMB"]),
              "--cpus", str(cfg["cpus"]),
              "--vram", "128",
              "--graphicscontroller", "vboxsvga",
              "--firmware", "efi64",
              "--chipset", "ich9",
              "--tpm-type", "2.0",
              "--ioapic", "on",
              "--acpi", "on",
              "--hwvirtex", "on",
              "--nested-hw-virt", "off",
              "--rtc-use-utc", "on",
              "--audio-enabled", "on",
              "--audio-driver", "pulse",
              "--audio-controller", "hda",
              "--audio-out", "on",
              "--nic1", "nat",
              "--nictype1", "82540EM",
              "--cableconnected1", "on",
              "--usb", "on",
              "--usbxhci", "on",
              "--mouse", "usbtablet",
              "--clipboard-mode", "bidirectional",
              "--boot1", "dvd",
              "--boot2", "disk",
              "--boot3", "none",
              "--boot4", "none",
              "--description", "Windows 11 Pro",
          ])
          vbox(["setextradata", vm, "VBoxInternal2/EfiSecureBoot", "1"])

      def enroll_secure_boot(cfg):
          vm = cfg["vmName"]
          vbox(["setextradata", vm, "VBoxInternal2/EfiSecureBoot", "1"])
          for step in (
              ["modifynvram", vm, "inituefivarstore"],
              ["modifynvram", vm, "enrollmssignatures"],
              ["modifynvram", vm, "enrollorclpk"],
          ):
              code, out = vbox(step, check=False)
              if code != 0:
                  log("nvram step failed, continuing: " + " ".join(step[1:]))
                  sys.stderr.write(out)

      def ensure_disk(cfg, p):
          code, info = vbox(["showvminfo", cfg["vmName"], "--machinereadable"], check=False)
          if code == 0 and p["disk"] in info:
              if os.path.isdir(p["vm_dir"]):
                  os.chmod(p["vm_dir"], 0o700)
              return
          if not os.path.exists(p["disk"]):
              os.makedirs(p["vm_dir"], mode=0o700, exist_ok=True)
              vbox([
                  "createmedium", "disk",
                  "--filename", p["disk"],
                  "--size", str(cfg["diskMB"]),
                  "--variant", "Standard",
              ])
          if code != 0 or "SATA" not in info:
              vbox([
                  "storagectl", cfg["vmName"],
                  "--name", "SATA",
                  "--add", "sata",
                  "--controller", "IntelAHCI",
                  "--portcount", "2",
                  "--bootable", "on",
              ])
          vbox([
              "storageattach", cfg["vmName"],
              "--storagectl", "SATA",
              "--port", "0",
              "--device", "0",
              "--type", "hdd",
              "--medium", p["disk"],
          ])
          if code != 0 or "IDE" not in info:
              vbox([
                  "storagectl", cfg["vmName"],
                  "--name", "IDE",
                  "--add", "ide",
              ])
          vbox([
              "storageattach", cfg["vmName"],
              "--storagectl", "IDE",
              "--port", "0",
              "--device", "0",
              "--type", "dvddrive",
              "--medium", "emptydrive",
          ], check=False)
          os.chmod(p["vm_dir"], 0o700)

      def ensure(cfg):
          require_host_user(cfg)
          p = paths(cfg)
          if not vboxdrv_ready():
              log("vboxdrv not loaded. VM not registered.")
              log("reboot after the generation that sets kvm.enable_virt_at_load=0.")
              return
          ensure_dirs(p)
          ready = os.path.join(p["state"], "vm-ready")
          if os.path.isfile(ready) and vm_registered(cfg):
              attach_msdm(cfg, p)
              log(cfg["vmName"] + " already prepared")
              return
          if not vm_registered(cfg):
              vbox([
                  "createvm",
                  "--name", cfg["vmName"],
                  "--ostype", "Windows11_64",
                  "--register",
                  "--basefolder", p["base"],
              ])
              log("registered " + cfg["vmName"])
          apply_firmware(cfg)
          if not os.path.isfile(p["stamp"]):
              enroll_secure_boot(cfg)
          ensure_disk(cfg, p)
          attach_msdm(cfg, p)
          fd = os.open(ready, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
          with os.fdopen(fd, "w") as fh:
              fh.write("ready\n")
          log("vm folder " + p["vm_dir"])

      def attach_msdm(cfg, p):
          blob = p["msdm"]
          if not os.path.isfile(blob) or os.path.getsize(blob) < 36:
              log("no host MSDM table. install still needs a key file.")
              return False
          if not vm_registered(cfg):
              return False
          if vm_state(cfg) not in ("", "poweroff", "aborted"):
              log("VM is running. MSDM not attached.")
              return False
          vbox([
              "setextradata", cfg["vmName"],
              "VBoxInternal/Devices/acpi/0/Config/CustomTable0",
              blob,
          ])
          log("attached host MSDM table. key not printed.")
          return True

      def normalize_key(raw):
          compact = re.sub(r"[^A-Za-z0-9]", "", raw).upper()
          if len(compact) != 25:
              raise VmError("product key file is not 25 letters/digits. not printing it.")
          return "-".join(compact[i:i + 5] for i in range(0, 25, 5))

      def read_key(p):
          if not os.path.isfile(p["key"]):
              raise VmError(
                  "missing product key file: " + p["key"]
                  + " (one line, mode 600; do not paste it in Discord)"
              )
          with open(p["key"]) as fh:
              return normalize_key(fh.read().strip())

      def ensure_password(p):
          if os.path.isfile(p["password"]) and os.path.getsize(p["password"]) > 0:
              return
          alphabet = string.ascii_letters + string.digits
          pw = ""
          while not (
              any(c.islower() for c in pw)
              and any(c.isupper() for c in pw)
              and any(c.isdigit() for c in pw)
          ):
              pw = "".join(secrets.choice(alphabet) for _ in range(24))
          fd = os.open(p["password"], os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
          with os.fdopen(fd, "w") as fh:
              fh.write(pw + "\n")
          log("wrote guest password to " + p["password"])

      def is_exact_pro(name):
          n = re.sub(r"\s+", " ", name).strip().lower()
          if n == "windows 11 pro":
              return 0
          if re.search(r"\b(n|education|workstations|single language|home)\b", n):
              return None
          if re.search(r"\bpro\b", n) and "windows 11" in n:
              return 1
          return None

      def pick_pro_index(iso):
          code, out = vbox(["unattended", "detect", "--iso=" + iso, "--machine-readable"], check=False)
          if code != 0:
              code, out = vbox(["unattended", "detect", "--iso=" + iso], check=False)
          if code != 0:
              sys.stderr.write(out)
              raise VmError("unattended detect failed")
          found = []
          for m in re.finditer(
              r'(?i)Image(\d+)="(\d+)"\s+Image\1Name="([^"]+)"',
              out,
          ):
              found.append((int(m.group(2)), m.group(3)))
          for line in out.splitlines():
              m = re.search(r'(?i)(?:image\s*)?#?\s*(\d+)\s*[:=]\s*"?([^"\n]+)"?', line)
              if m and "windows" in m.group(2).lower():
                  found.append((int(m.group(1)), m.group(2).strip()))
          ranked = []
          seen = set()
          for idx, name in found:
              key = (idx, name.lower())
              if key in seen:
                  continue
              seen.add(key)
              rank = is_exact_pro(name)
              if rank is not None:
                  ranked.append((rank, idx, name))
          if not ranked:
              sys.stderr.write(redact(out))
              raise VmError("no Windows 11 Pro image in detect output")
          ranked.sort()
          _rank, idx, name = ranked[0]
          log("image index " + str(idx) + " " + name)
          return idx

      def install(cfg):
          require_host_user(cfg)
          os.umask(0o077)
          p = paths(cfg)
          if not vboxdrv_ready():
              raise VmError("vboxdrv not loaded")
          if os.path.isfile(p["stamp"]):
              raise VmError("install already started. stamp: " + p["stamp"])
          if not os.path.isfile(cfg["iso"]):
              raise VmError("missing ISO: " + cfg["iso"] + " (official Windows 11 ISO; this module does not download it)")
          ensure(cfg)
          use_msdm = os.path.isfile(p["msdm"]) and os.path.getsize(p["msdm"]) >= 36
          key = None if use_msdm else read_key(p)
          ensure_password(p)
          index = pick_pro_index(cfg["iso"])
          start = "gui" if os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY") else "headless"
          if start == "headless":
              log("no display. starting headless. open VirtualBox to attach.")
          args = [
              "unattended", "install", cfg["vmName"],
              "--iso=" + cfg["iso"],
              "--user=" + cfg["guestUser"],
              "--password-file=" + p["password"],
              "--full-user-name=" + cfg["guestUser"],
          ]
          if key:
              args.append("--key=" + key)
          else:
              log("no --key. guest should read the host MSDM table.")
          args.extend([
              "--install-additions",
              "--locale=" + cfg["locale"],
              "--country=" + cfg["country"],
              "--time-zone=" + cfg["timeZone"],
              "--hostname=" + cfg["hostname"],
              "--image-index=" + str(index),
              "--start-vm=" + start,
              "--auxiliary-base-path=" + os.path.join(p["state"], "unattended-"),
          ])
          vbox(args)
          fd = os.open(p["stamp"], os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
          with os.fdopen(fd, "w") as fh:
              fh.write("started\n")
          log("install started. guest password file: " + p["password"])

      def status(cfg):
          p = paths(cfg)
          log("vm: " + cfg["vmName"])
          log("iso: " + ("present" if os.path.isfile(cfg["iso"]) else "missing " + cfg["iso"]))
          log("product-key: " + ("present" if os.path.isfile(p["key"]) else "missing " + p["key"]))
          log("password: " + ("present" if os.path.isfile(p["password"]) else "not written yet"))
          log("stamp: " + ("present" if os.path.isfile(p["stamp"]) else "absent"))
          log("vboxdrv: " + ("loaded" if vboxdrv_ready() else "not loaded"))
          if vboxdrv_ready() and vm_registered(cfg):
              _code, out = vbox(["showvminfo", cfg["vmName"], "--machinereadable"], check=False)
              for line in out.splitlines():
                  low = line.lower()
                  if low.startswith(("vmstate=", "memory=", "firmware=", "ostype=", "tpm")) or "secure" in low:
                      log(redact(line))

      def main():
          cfg = load_cfg()
          cmd = sys.argv[1] if len(sys.argv) > 1 else "ensure"
          soft = os.environ.get("DENIX_WINDOWS_SOFT") == "1" and cmd == "ensure"
          try:
              if cmd == "ensure":
                  ensure(cfg)
              elif cmd == "install":
                  install(cfg)
              elif cmd == "status":
                  status(cfg)
              else:
                  log("usage: denix-windows-vm ensure|install|status")
                  raise SystemExit(2)
          except VmError as err:
              log(redact(str(err)))
              if soft:
                  raise SystemExit(0)
              raise SystemExit(1)

      if __name__ == "__main__":
          main()
    '';
    runner = pkgs.writeShellScriptBin "denix-windows-vm" ''
      export DENIX_WINDOWS_CONFIG=${cfgFile}
      export PATH="/run/wrappers/bin:/run/current-system/sw/bin:$PATH"
      exec ${py}/bin/denix-windows-vm "$@"
    '';
  in {
    options.denix.windows = {
      user = lib.mkOption {
        type = lib.types.str;
        default = "rebb";
        description = "Host user added to vboxusers. Owns /var/lib/denix-windows.";
      };
      iso = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/denix-windows/Win11.iso";
        description = "Path to an official Windows 11 ISO. Not fetched. Not a store path.";
      };
      memoryMB = lib.mkOption {
        type = lib.types.int;
        default = 8192;
        description = "Guest RAM in MB. Windows 11 refuses below 4096.";
      };
      cpus = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Guest CPU count.";
      };
      diskMB = lib.mkOption {
        type = lib.types.int;
        default = 102400;
        description = "Dynamic VDI size in MB. 102400 is 100 GiB.";
      };
    };

    config = {
      assertions = [
        {
          assertion = cfg.memoryMB >= 4096;
          message = "denix.windows.memoryMB must be at least 4096 (Windows 11).";
        }
        {
          assertion = cfg.cpus >= 2;
          message = "denix.windows.cpus must be at least 2 (Windows 11).";
        }
        {
          assertion = cfg.diskMB >= 65536;
          message = "denix.windows.diskMB must be at least 65536 (Windows 11).";
        }
      ];

      # nixpkgs only sets this for kernels >= 6.12 and < 6.16.
      # 7.2 still defaults enable_virt_at_load=Y, which keeps VT-x and blocks VirtualBox.
      boot.kernelParams = [ "kvm.enable_virt_at_load=0" ];
      boot.extraModprobeConfig = ''
        options kvm enable_virt_at_load=0
      '';

      virtualisation.virtualbox.host.enable = true;
      # Oracle Extension Pack. PUEL, unfree. core already sets allowUnfree.
      # Needed for USB 2/3 passthrough. TPM and EFI stay in the base package.
      virtualisation.virtualbox.host.enableExtensionPack = true;

      users.users.${cfg.user}.extraGroups = [ "vboxusers" ];

      environment.systemPackages = [ runner ];

      systemd.tmpfiles.rules = [
        "d /var/lib/denix-windows 0700 ${cfg.user} vboxusers - -"
        "d /var/lib/denix-windows/vms 0700 ${cfg.user} vboxusers - -"
      ];

      systemd.services.denix-windows-msdm = {
        description = "Copy the host OEM MSDM ACPI table for the Windows VM";
        wantedBy = [ "multi-user.target" ];
        before = [ "denix-windows-vm.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          src=/sys/firmware/acpi/tables/MSDM
          dst=/var/lib/denix-windows/MSDM.bin
          install -d -m 0700 -o ${cfg.user} -g vboxusers /var/lib/denix-windows
          if [ -f "$src" ]; then
            install -m 0600 -o ${cfg.user} -g vboxusers "$src" "$dst"
          fi
        '';
      };

      systemd.services.denix-windows-vm = {
        description = "Register the Windows 11 Pro VirtualBox VM";
        after = [ "systemd-tmpfiles-setup.service" "systemd-modules-load.service" "denix-windows-msdm.service" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          DENIX_WINDOWS_SOFT = "1";
          HOME = "/home/${cfg.user}";
          USER = cfg.user;
          LOGNAME = cfg.user;
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = cfg.user;
          Group = "vboxusers";
          SupplementaryGroups = [ "vboxusers" ];
          ExecStart = "${runner}/bin/denix-windows-vm ensure";
        };
      };
    };
  };
}
