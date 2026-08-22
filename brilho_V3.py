#!/usr/bin/env python3
import gi
import subprocess
import re

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib

class BrilhoMonitorEstavel(Gtk.Window):
    def __init__(self):
        super().__init__(title="Brilho")
        self.set_border_width(12)
        self.set_default_size(260, 100)
        self.set_resizable(False)
        self.set_position(Gtk.WindowPosition.MOUSE)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        self.add(vbox)

        self.label = Gtk.Label(label="Buscando brilho...")
        vbox.pack_start(self.label, True, True, 0)

        self.adj = Gtk.Adjustment(value=50, lower=0, upper=100, step_increment=5)
        self.slider = Gtk.Scale(orientation=Gtk.Orientation.HORIZONTAL, adjustment=self.adj)
        self.slider.set_digits(0)
        
        self.slider.connect("button-release-event", self.on_slider_release)
        self.slider.connect("key-release-event", self.on_slider_release)
        
        vbox.pack_start(self.slider, True, True, 0)

        # Layout horizontal para os botões de atalho
        hbox_preset = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        hbox_preset.set_homogeneous(True) # Faz todos os botões terem a mesma largura

        # Criação dos botões de preset
        for pct in [20, 30, 50]:
            btn = Gtk.Button(label=f"{pct}%")
            # Usa o valor numérico `pct` no clique do botão
            btn.connect("clicked", self.definir_brilho_preset, pct)
            hbox_preset.pack_start(btn, True, True, 0)

        vbox.pack_start(hbox_preset, True, True, 0)

        GLib.idle_add(self.carregar_brilho_atual)

    def carregar_brilho_atual(self):
        try:
            resultado = subprocess.check_output(
                "ddcutil getvcp 10", 
                shell=True, 
                stderr=subprocess.DEVNULL
            ).decode()

            match = re.search(r"current value\s*=\s*(\d+)", resultado)
            if match:
                valor = int(match.group(1))
                self.adj.set_value(valor)
                self.label.set_text("Monitor Detectado")
                return
            self.label.set_text("Erro ao ler brilho")
        except Exception:
            self.label.set_text("Monitor não encontrado")

    def aplicar_brilho(self, valor):
        """Atualiza a interface e dispara o ddcutil"""
        self.adj.set_value(valor)
        self.label.set_text(f"Definindo: {valor}%...")
        subprocess.Popen(f"ddcutil setvcp 10 {valor} &", shell=True)
        GLib.timeout_add_seconds(1, lambda: self.label.set_text("Monitor Detectado"))

    def on_slider_release(self, widget, event):
        valor = int(self.slider.get_value())
        self.aplicar_brilho(valor)

    def definir_brilho_preset(self, widget, valor):
        self.aplicar_brilho(valor)

if __name__ == "__main__":
    app = BrilhoMonitorEstavel()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()
