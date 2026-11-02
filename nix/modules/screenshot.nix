# Clipboard screenshots: `screenshot region|window|output`.
#
# Replaces hyprshot. Wayland capture regions are logical coordinates, so on a
# fractional scale (workstation: 1.2) `grim -g` lands between physical pixels
# and resamples, smearing text. Instead the whole output is captured at native
# resolution and cropped on the physical pixel grid.
{ config, pkgs, ... }:

let
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [
      config.programs.hyprland.package
      grim
      slurp
      jq
      imagemagick
      wl-clipboard
      libnotify
    ];
    text = ''
      mode="''${1:-region}"
      monitors=$(hyprctl monitors -j)

      case "$mode" in
        output)
          name=$(slurp -o -r -f '%o')
          grim -o "$name" - | wl-copy --type image/png
          notify-send -t 3000 "Screenshot" "Output $name copied"
          exit 0
          ;;
        region)
          geom=$(slurp -d -f '%x %y %w %h')
          ;;
        window)
          ws=$(jq -r '[.[] | .activeWorkspace.id, .specialWorkspace.id] | map(tostring) | join(",")' <<<"$monitors")
          geom=$(hyprctl clients -j \
            | jq -r --arg ws "$ws" '($ws | split(",") | map(tonumber)) as $ids
                | .[] | select(.mapped and (.hidden | not) and (.workspace.id as $w | $ids | index($w)))
                | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' \
            | slurp -r -f '%x %y %w %h')
          ;;
        *)
          echo "usage: screenshot [region|window|output]" >&2
          exit 2
          ;;
      esac

      read -r x y w h <<<"$geom"

      # Monitor holding the region's top-left; the crop is clamped to it.
      read -r name crop < <(jq -r --argjson x "$x" --argjson y "$y" --argjson w "$w" --argjson h "$h" '
        map(. + {lw: ((if .transform % 2 == 1 then .height else .width end) / .scale),
                 lh: ((if .transform % 2 == 1 then .width else .height end) / .scale)})
        | map(select($x >= .x and $x < .x + .lw and $y >= .y and $y < .y + .lh)) | first
        | .scale as $s
        | [(($x - .x) * $s | round), (($y - .y) * $s | round),
           ([$x + $w - .x, .lw] | min | . * $s | round),
           ([$y + $h - .y, .lh] | min | . * $s | round)] as [$x0, $y0, $x1, $y1]
        | "\(.name) \($x1 - $x0)x\($y1 - $y0)+\($x0)+\($y0)"' <<<"$monitors")

      grim -o "$name" - | magick png:- -crop "$crop" +repage png:- | wl-copy --type image/png
      notify-send -t 3000 "Screenshot" "''${w}x''${h} region copied"
    '';
  };
in
{
  environment.systemPackages = [ screenshot ];
}
