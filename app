import FreeSimpleGUI as sg
import matplotlib.pyplot as plt
import numpy as np
import projeto as c


# --- (do teu código) ---
def extraiFilaMedia(t):
    res = []
    for _, fila_media in t:
        res.append(fila_media)
    return res


def grafEsperaVsLambda(repeticoes=20):
    """
    Gráfico: relação entre λ (doentes/hora) e tempo médio de espera (min).
    Usa c.simula() e altera temporariamente c.TAXA_CHEGADA.
    """
    resultados = []
    taxa_original = c.TAXA_CHEGADA

    for lam in range(10, 31):  # 10..30 doentes/hora
        c.TAXA_CHEGADA = lam / 60.0

        esperas = []
        for _ in range(repeticoes):
            res = c.simula()
            esperas.append(res["tempo_medio_espera"])  # <-- tempo médio de espera

        resultados.append((lam, float(np.mean(esperas))))

    c.TAXA_CHEGADA = taxa_original

    x = list(range(10, 31))
    y = extraiFilaMedia(resultados)

    plt.figure()
    plt.plot(x, y, label="Tempo médio de espera")
    plt.title("Relação entre λ e o tempo médio de espera")
    plt.xlabel("Taxa de chegada λ (doentes/hora)")
    plt.ylabel("Tempo médio de espera (min)")
    plt.legend()
    plt.grid(True)
    plt.show()


def grafico_esperas_por_atendimento(resultados):
    esperas = resultados["tempos_espera"]
    x = list(range(len(esperas)))

    plt.figure()
    plt.plot(x, esperas)
    plt.xlabel("Ordem dos atendimentos")
    plt.ylabel("Tempo de espera (min)")
    plt.title("Evolução do tempo de espera (por doente atendido)")
    plt.grid(True)
    plt.show()


def main():
    sg.theme("SystemDefault")

    layout = [
        [sg.Text("App Simulação Clínica", font=("Arial", 16, "bold"))],

        [sg.Frame("Ações", [
            [sg.Button("Correr simulação", key="-RUN-", size=(18, 1)),
             sg.Button("Gráfico: esperas", key="-PLOT_ESP-", size=(18, 1), disabled=True),
             sg.Button("Gráfico: λ vs espera", key="-PLOT_LAM-", size=(18, 1)),
             sg.Button("Sair", key="-EXIT-", size=(10, 1))]
        ])],

        [sg.Frame("Parâmetros do gráfico λ vs espera", [
            [sg.Text("Repetições por λ:", size=(16, 1)),
             sg.Input("20", key="-REP-", size=(10, 1))]
        ])],

        [sg.Frame("Resultados (última simulação)", [
            [sg.Text("Doentes atendidos:", size=(26, 1)), sg.Text("-", key="-DOENTES-")],
            [sg.Text("Tempo médio de espera (min):", size=(26, 1)), sg.Text("-", key="-ESPERA-")],
            [sg.Text("Tempo médio de consulta (min):", size=(26, 1)), sg.Text("-", key="-CONSULTA-")],
            [sg.Text("Tempo médio no sistema (min):", size=(26, 1)), sg.Text("-", key="-SISTEMA-")],
            [sg.Text("Tamanho médio da fila:", size=(26, 1)), sg.Text("-", key="-FILA_MEDIA-")],
            [sg.Text("Tamanho máximo da fila:", size=(26, 1)), sg.Text("-", key="-FILA_MAX-")],
            [sg.Text("Ocupação média:", size=(26, 1)), sg.Text("-", key="-OCUP_MEDIA-")],
        ])],

        [sg.Frame("Ocupação por médico (%)", [
            [sg.Multiline("", key="-OCUP_MED-", size=(48, 6), disabled=True)]
        ])],

        [sg.StatusBar("Pronto.", key="-STATUS-")]
    ]

    window = sg.Window("Simulação Clínica", layout, finalize=True)
    resultados = None

    while True:
        event, values = window.read()
        if event in (sg.WINDOW_CLOSED, "-EXIT-"):
            break

        if event == "-RUN-":
            window["-STATUS-"].update("A correr simulação...")
            try:
                resultados = c.simula()

                window["-DOENTES-"].update(str(resultados["doentes_atendidos"]))
                window["-ESPERA-"].update(f'{resultados["tempo_medio_espera"]:.2f}')
                window["-CONSULTA-"].update(f'{resultados["tempo_medio_consulta"]:.2f}')
                window["-SISTEMA-"].update(f'{resultados["tempo_medio_sistema"]:.2f}')
                window["-FILA_MEDIA-"].update(f'{resultados["tamanho_medio_fila"]:.2f}')
                window["-FILA_MAX-"].update(str(resultados["tamanho_max_fila"]))
                window["-OCUP_MEDIA-"].update(f'{resultados["ocupacao_media"]:.3f}')

                linhas = []
                for mid, v in resultados["ocupacao_por_medico"].items():
                    linhas.append(f"{mid}: {v*100:.2f}%")
                window["-OCUP_MED-"].update("\n".join(linhas))

                window["-PLOT_ESP-"].update(disabled=False)
                window["-STATUS-"].update("Simulação concluída.")
            except FileNotFoundError:
                window["-STATUS-"].update("Erro: pessoas.json não encontrado.")
                sg.popup_error("Não encontrei pessoas.json.\nConfirma que está na mesma pasta.")
            except Exception as e:
                window["-STATUS-"].update("Erro ao correr a simulação.")
                sg.popup_error(f"Erro: {e}")

        if event == "-PLOT_ESP-":
            if resultados is not None:
                grafico_esperas_por_atendimento(resultados)

        if event == "-PLOT_LAM-":
            # lê repetições
            try:
                rep = int(values["-REP-"])
                if rep <= 0:
                    raise ValueError
            except Exception:
                sg.popup_error("Repetições inválidas. Mete um inteiro > 0.")
                continue

            window["-STATUS-"].update(f"A gerar gráfico λ vs espera (repetições={rep})...")
            try:
                grafEsperaVsLambda(repeticoes=rep)
                window["-STATUS-"].update("Gráfico gerado.")
            except Exception as e:
                window["-STATUS-"].update("Erro ao gerar gráfico.")
                sg.popup_error(f"Erro: {e}")

    window.close()


if __name__ == "__main__":
    main()
