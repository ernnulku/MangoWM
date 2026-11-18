echo "starting setup"

echo 3
delay 1
echo 2
delay 1
echo 1

sudo pacman -S waybar mako wlr-randr hypridle swaybg wireplumber brightnessctl rofi-wayland kitty grim slurp hyprlock && cd MangoWM && mv ~/config/fastfetch ~/.config/fastfetch/ && mv ~/config/kitty ~/.config/kitty/ && mv ~/config/mango ~/.config/mango/ && mv ~/config/rofi ~/.config/rofi/ && mv ~/config/waybar ~/.config/waybar/
