# Storage tiers for lab
#   /mnt/storage        — 2x2TB SSD btrfs raid1 (redundant + fast): *arr configs,
#                         k3s app data, future nextcloud (irreplaceable → mirrored)
#   /mnt/storage/media  — 4TB HDD btrfs single (bulk, re-downloadable media).
#                         Becomes raid5 later once the 2x8TB HDDs are added.
{ ... }:

{
  boot.supportedFilesystems = [ "btrfs" ];

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-label/storage";
    fsType = "btrfs";
    options = [ "compress=zstd" "noatime" ];
  };

  # Nested under /mnt/storage; systemd orders it after the parent mount.
  fileSystems."/mnt/storage/media" = {
    device = "/dev/disk/by-label/media";
    fsType = "btrfs";
    options = [ "compress=zstd" "noatime" ];
  };

  # Weekly scrub surfaces/repairs bitrot — the redundant tier self-heals,
  # the media tier at least reports corruption early.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/mnt/storage" "/mnt/storage/media" ];
  };
}
