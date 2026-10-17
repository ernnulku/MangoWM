Apps - 
App Launcher - Rofi
Terminal - Kitty
Wm - MangoWM
Bar - MangoBar
Text Editor - Lazy/Neovim
For Monitor Config - wlr-randr

mkdir -p ~/.local/share/applications && for app in avahi-discover bssh bvnc qv4l2 qvidcap foot foot-server footclient rofi rofi-theme-selector; do [ -f /usr/share/applications/"$app".desktop ] && cp /usr/share/applications/"$app".desktop ~/.local/share/applications/ && echo "NoDisplay=true" >> ~/.local/share/applications/"$app".desktop; done
               
For App Hiding ->


Yay Setup -> sudo pacman -S --needed base-devel git && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
