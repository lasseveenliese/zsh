# ~/.zshrc.d/05-colors.zsh
# Terminal.app Palette aus tmp/terminal-palette/for_colors.terminal
# - Farbwerte aus dem exportierten Profil: Rot/Grün/Gelb/Blau/Magenta + Bright-Varianten
# - Fehlende Paletteinträge (Cyan/Greys) aus vorhandenen Werten abgeleitet, damit die 16er-ANSI-Palette konsistent bleibt.

typeset -gA TERMINAL_COLORS=(
  [0]="#000f1d"  # black (aus Hintergrund)
  [1]="#a50000"  # red
  [2]="#12b800"  # green
  [3]="#a2a400"  # yellow
  [4]="#1551cd"  # blue
  [5]="#b200b2"  # magenta
  [6]="#138466"  # cyan (abgeleitet aus grün+blau)
  [7]="#ffffff"  # white (aus Text)
  [8]="#7f878e"  # bright black (Mittelwert aus bg+fg)
  [9]="#df0005"  # bright red
  [10]="#19ff00" # bright green (aufgehellt aus grün)
  [11]="#c2c500" # bright yellow (aufgehellt aus gelb)
  [12]="#4d88ff" # bright blue
  [13]="#cd29cd" # bright magenta
  [14]="#33c37f" # bright cyan (abgeleitet)
  [15]="#ffffff" # bright white (Text/Bold)
)

# Einzelne Export-Variablen (praktisch für Tools ohne assoziatives Array)
for idx color in ${(kv)TERMINAL_COLORS}; do
  export "TERMINAL_COLOR_${idx}=${color}"
done

# Zusätzliche Komfort-Variablen
export TERMINAL_BACKGROUND="${TERMINAL_COLORS[0]}"
export TERMINAL_FOREGROUND="${TERMINAL_COLORS[7]}"
