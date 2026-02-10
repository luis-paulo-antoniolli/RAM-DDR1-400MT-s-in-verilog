# DDR1 Memory Controller & Hardware Model

Este projeto implementa um sistema de memória DDR1 completo, incluindo um **Memory Controller** síncrono e um **DDR1 Chip** com arquitetura estrutural seguindo padrões industriais de memória.

## 🚀 Visão Geral

O objetivo deste projeto foi evoluir um modelo comportamental de DDR1 para uma implementação que reflete os desafios reais de design de hardware, conformidade com normas JEDEC e a estrutura física de memórias dinâmicas.

### Destaques do Projeto:
- **Conformidade JEDEC**: Implementação da sequência de inicialização rigorosa e suporte a **MRS/EMRS** (Mode Register Set).
- **True Double Data Rate (DDR)**: Barramento de dados funcional que transfere informações em ambas as bordas do clock, dobrando a performance.
- **Sincronização via DLL**: Modelo comportamental de **Delay-Locked Loop** para alinhamento de fase entre clock e dados, exigindo 200 ciclos de lock.
- **Arquitetura Industrial**: Chip estruturado com decodificadores digitais, lógica de comando e interface SSTL-2 simplificada.

---

## 🏗️ Arquitetura do Sistema

### 1. DDR1 Controller (`ddr1_controller.v`)
Atua como o mestre do barramento, gerenciando o protocolo e o treinamento da memória.
- **JEDEC Init**: Sequência completa de `Precharge All -> EMRS -> MRS(Reset) -> Wait -> Refresh -> MRS(Setup)`.
- **FSM Robusta**: Estados para automação de `ACT`, `READ`, `WRITE` e `PRECHARGE`.
- **Handshake Síncrono Protocolado**: Interface host com `req_valid`/`req_ack`.

### 2. DDR1 Chip Structural Model (`ddr1_chip.v`)
Modelo de chip focado na integridade lógica e temporal do padrão DDR:
- **Prefetch 2 Architecture**: Lógica interna que prepara 32 bits de dados para transferir 16 bits por meio-ciclo.
- **Mode Registers**: Armazenamento real para configuração de CAS Latency (CL2, CL3) e Burst Length.
- **DDR I/O Path**: Lógica multiplexada para subida e descida de clock.

---

## 📁 Estrutura de Arquivos

| Arquivo | Descrição |
| :------- | :---------- |
| `ddr1_chip.v` | Top-level do Chip (Estrutura Industrial) |
| `ddr1_controller.v` | Controlador de Memória com Sequência JEDEC |
| `ddr1_robust_tb.sv` | Testbench robusto com Scoreboard e Testes Aleatórios |
| `ddr1_dimm.v` | Modelo de módulo DIMM (agregador de chips) |
| `walkthrough.md` | Explicação detalhada da arquitetura e formas de onda |

---

## 🛠️ Como Simular

O projeto recomenda o uso do **Icarus Verilog** (v11 ou superior) para suporte a SystemVerilog.

1. **Compilar o Teste Robusto:**
   ```bash
   iverilog -g2012 -o ddr1_robust ddr1_robust_tb.sv ddr1_controller.v ddr1_dimm.v ddr1_chip.v
   ```

2. **Executar a Simulação:**
   ```bash
   vvp ddr1_robust
   ```

3. **Verificar Resultados:**
   O testbench robusto executa cenários de acesso multi-banco e estresse aleatório, verificando os dados contra um modelo de referência (Scoreboard).

---

## 🛣️ Roadmap para Implementação Física

Para transformar este código em hardware real:
1. **Síntese Lógica**: Mapeamento do controlador e lógica do chip para uma biblioteca de células padrão.
2. **Integração de Memory Macros**: Substituição do array comportamental por IPs de memória reais do fornecedor de silício.
3. **Physical Design**: Posicionamento (Floorplanning) e roteamento de sinal/clock para garantir integridade elétrica.

---

Desenvolvido com foco em **Hardware Engineering** e rigor técnico em protocolos de memória.
