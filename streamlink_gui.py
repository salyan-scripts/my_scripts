#!/usr/bin/env python3
import tkinter as tk
from tkinter import ttk, messagebox
import subprocess
import json
import shutil

class StreamlinkGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Streamlink GUI")
        self.root.resizable(False, False)

        # --- URL ---
        ttk.Label(root, text="Link da live:").grid(row=0, column=0, sticky="w", padx=5, pady=5)
        

        self.url_entry = ttk.Entry(root, width=45)
        self.url_entry.grid(row=0, column=1, padx=5, pady=5, sticky="w")

        self.paste_btn = ttk.Button(root, text="Colar", command=self.paste_url)
        self.paste_btn.grid(row=0, column=2, padx=5, pady=5)

    def paste_url(self):
        try:
            text = self.root.clipboard_get()
            self.url_entry.delete(0, tk.END)
            self.url_entry.insert(0, text.strip())
        except tk.TclError:
            messagebox.showerror("Erro", "Área de transferência vazia ou inválida.")

        # --- Detect button ---
        self.detect_btn = ttk.Button(root, text="Detectar streams", command=self.detect_streams)
        self.detect_btn.grid(row=1, column=1, sticky="e", padx=5)

        # --- Quality ---
        ttk.Label(root, text="Qualidade:").grid(row=2, column=0, sticky="w", padx=5, pady=5)
        self.quality_box = ttk.Combobox(root, state="readonly", width=20)
        self.quality_box.grid(row=2, column=1, sticky="w", padx=5, pady=5)

        # --- Player ---
        ttk.Label(root, text="Player:").grid(row=3, column=0, sticky="w", padx=5, pady=5)
        self.player_box = ttk.Combobox(root, state="readonly", width=20)
        self.player_box.grid(row=3, column=1, sticky="w", padx=5, pady=5)

        # --- Play button ---
        self.play_btn = ttk.Button(root, text="▶ Assistir", command=self.play_stream)
        self.play_btn.grid(row=4, column=1, sticky="e", padx=5, pady=10)

        self.load_players()

    # -----------------------------
    def load_players(self):
        players = []
        for p in ["mpv", "vlc"]:
            if shutil.which(p):
                players.append(p)

        if not players:
            players.append("mpv")  # fallback

        self.player_box["values"] = players
        self.player_box.current(0)

    # -----------------------------
    def detect_streams(self):
        url = self.url_entry.get().strip()
        if not url:
            messagebox.showerror("Erro", "Cole o link da live.")
            return

        try:
            result = subprocess.run(
                ["streamlink", "--json", url],
                capture_output=True,
                text=True
            )

            if result.returncode != 0:
                raise Exception(result.stderr)

            data = json.loads(result.stdout)
            streams = list(data["streams"].keys())

            if not streams:
                raise Exception("Nenhuma stream encontrada.")

            streams.sort(key=self.sort_quality)

            self.quality_box["values"] = streams
            self.quality_box.set("")  # SEM padrão
        except Exception as e:
            messagebox.showerror("Erro", str(e))

    # -----------------------------
    def sort_quality(self, q):
        if q == "audio_only":
            return 0
        if q == "best":
            return 9999
        if q == "worst":
            return -1
        try:
            return int(q.replace("p", ""))
        except:
            return 500

    # -----------------------------
    def play_stream(self):
        url = self.url_entry.get().strip()
        quality = self.quality_box.get()
        player = self.player_box.get()

        if not url or not quality:
            messagebox.showerror("Erro", "Escolha o link e a qualidade.")
            return

        # Fecha a GUI
        self.root.destroy()

        # Executa streamlink e ESPERA terminar
        subprocess.run(
            ["streamlink", url, quality, "--player", player]
        )

# -----------------------------
if __name__ == "__main__":
    root = tk.Tk()
    app = StreamlinkGUI(root)
    root.mainloop()

