= Anexos

== Anexo A: fragmentos de código

El código completo está en `src/fireca/`. Se incluyen aquí los fragmentos
centrales para que el documento sea autocontenido. El Anexo B describe cómo
reproducir todos los resultados.

=== Núcleo de Rothermel

#figure(
  ```python
  def rothermel_components(load, sav, depth, moisture, mx):
      load_i = load * KG_M2_TO_LB_FT2      # kg/m2 -> lb/ft2
      depth_i = depth * M_TO_FT            # m -> ft
      sigma_i = sav * M_INV_TO_FT_INV      # 1/m -> 1/ft
      valid = (load_i > 0) & (depth_i > 0) & (sigma_i > 0)
      depth_safe = np.where(depth_i > 0, depth_i, 1.0)
      sigma_safe = np.where(sigma_i > 0, sigma_i, 1.0)
      rho_b = np.where(valid, load_i / depth_safe, 0.0)
      beta = rho_b / PARTICLE_DENSITY_LB_FT3
      beta_op = 3.348 * sigma_safe ** -0.8189
      a = 133.0 * sigma_safe ** -0.7913
      gamma_max = sigma_safe ** 1.5 / (495.0 + 0.0594 * sigma_safe ** 1.5)
      ratio = np.where(beta_op > 0, beta / beta_op, 0.0)
      gamma = np.where(
          (ratio > 0) & valid,
          gamma_max * ratio ** a * np.exp(a * (1.0 - ratio)),
          0.0,
      )
      xi = np.exp((0.792 + 0.681 * np.sqrt(sigma_safe)) * (beta + 0.1)) / (
          192.0 + 0.2595 * sigma_safe
      )
      eps = np.exp(-138.0 / sigma_safe)
      q_ig = 250.0 + 1116.0 * moisture
      eta_m = moisture_damping(moisture, mx)
      eta_s = mineral_damping()
      i_r = gamma * load_i * (1 - 0.0555) * 8000.0 * eta_m * eta_s
      r0_ft_min = np.where(
          (rho_b > 0) & (eps > 0) & (q_ig > 0),
          i_r * xi / (rho_b * eps * q_ig),
          0.0,
      )
      return np.maximum(r0_ft_min, 0.0) * FT_MIN_TO_M_S
  ```
  ,
  caption: [Cálculo vectorizado de la velocidad base de Rothermel.],
) <lst:rothermel>

=== Acumulación de exposición y paso del AC

#figure(
  ```python
  def _accumulate_hazard(self, burning):
      hazard = np.zeros_like(self.hazard)
      for k, (dr, dc) in enumerate(MOORE_OFFSETS):
          contrib = self.rates.rates[k] * (self.dt / self.rates.distances[k])
          hazard += _shift_to_target(contrib * burning, dr, dc)
      return hazard

  def step(self):
      burning = self.burning
      contribution = self._accumulate_hazard(burning)
      self.hazard *= np.exp(-self.dt / self.cooling_time)
      self.hazard += contribution
      self.hazard[~self.unburned] = 0.0
      self._age_and_burnout()
      self._ignite_from_hazard()
      self.time += self.dt
  ```
  ,
  caption: [Paso sincrónico del autómata: acumulación de exposición, enfriamiento, envejecimiento e ignición.],
) <lst:paso>

=== Ignición estocástica

#figure(
  ```python
  def _ignite_from_hazard(self):
      candidates = self.unburned & self.valid & (self.hazard > 0.0)
      if not np.any(candidates):
          self.hazard.fill(0.0)
          return
      probability = 1.0 - np.exp(-self.hazard)
      draw = self.rng.random(self.state.shape)
      ignite = candidates & (draw < probability)
      if np.any(ignite):
          self.state[ignite] = BURNING
          self.arrival[ignite] = self.time + self.dt
          self.burn_age[ignite] = 0.0
      self.hazard.fill(0.0)   # intento memoryless
  ```
  ,
  caption: [Ignición de Bernoulli del AC probabilístico.],
) <lst:stoch>

=== Interfaz de línea de comandos

#figure(
  ```bash
  uv sync
  uv run pytest
  uv run python scripts/run_all.py
  uv run fireca run --size 256 --wind 6 --moisture 0.08 --seed 42
  uv run fireca sweep --variable wind --size 128 --members 20
  ```
  ,
  caption: [Comandos principales de instalación, pruebas, reproducción y uso de la CLI.],
) <lst:cli>

== Anexo B: reproducibilidad

La Tabla @tab:reproduce resume el flujo de trabajo. El entorno se crea con
`uv sync`, que instala las dependencias fijadas en `uv.lock` y el paquete en
modo editable. Las pruebas se ejecutan con `uv run pytest`; la campaña completa
con `uv run python scripts/run_all.py`; y las tablas Typst se regeneran con
`uv run python scripts/make_typst_tables.py`. El documento se compila con
`typst compile doc/main.typ`.

#figure(
  table(
    columns: (1.5fr, 2.8fr),
    align: (left, left),
    stroke: 0.4pt,
    inset: 4pt,
    table.header([Comando], [Propósito]),
    [`uv sync`], [Crear el entorno e instalar dependencias.],
    [`uv run pytest`], [Ejecutar las pruebas unitarias.],
    [`uv run python scripts/run_all.py`], [Regenerar tablas, datos y figuras.],
    [`uv run python scripts/make_typst_tables.py`], [Regenerar `doc/tablas.typ`.],
    [`uv run python scripts/check_dois.py`], [Verificar la resolución de los DOI.],
    [`typst compile doc/main.typ`], [Compilar el documento a PDF.],
  ),
  caption: [Comandos de reproducibilidad.],
) <tab:reproduce>

Las semillas utilizadas son: escenario base $42$; ensemble $7$ con miembros
$7000, 7001, dots$; percolación $123$ con realizaciones
$123 + 1000k$; barridos $0$; convergencia $0$; sensibilidad $11$. Los archivos
`results/data/*.npz` contienen los arreglos crudos y `results/tables/*.csv` las
tablas. La estructura del repositorio es:

#figure(
  ```text
  TIF/
    pyproject.toml
    uv.lock
    src/fireca/{fuels,terrain,ca,metrics,numerics,experiments,plotting,cli}.py
    tests/test_fireca.py
    scripts/{run_all,make_typst_tables}.py
    results/{tables,figures,data}/
    doc/{main.typ,lib.typ,refs.bib,tablas.typ,sections/}
  ```
  ,
  caption: [Estructura del repositorio.],
) <lst:estructura>

== Anexo C: símbolos

#figure(
  table(
    columns: (auto, 3.4fr),
    align: (center, left),
    stroke: 0.4pt,
    inset: 4pt,
    table.header([Símbolo], [Significado]),
    [$R$], [Velocidad de propagación (ROS) [m/s].],
    [$R_0$], [ROS base sin viento ni pendiente [m/s].],
    [$R_"max"$], [Cota de seguridad de la ROS [m/s].],
    [$M$], [Humedad del combustible [fracción].],
    [$M_x$], [Humedad de extinción [fracción].],
    [$w_0$], [Carga de combustible [kg/m²].],
    [$sigma$], [Relación superficie--volumen [1/m].],
    [$delta$], [Profundidad del lecho [m].],
    [$beta$], [Relación de empaquetamiento.],
    [$eta_M$], [Amortiguamiento por humedad.],
    [$phi_w, phi_s$], [Factores de viento y pendiente.],
    [$Delta x$], [Tamaño de celda [m].],
    [$Delta t$], [Paso temporal [s].],
    [$tau_"res"$], [Tiempo de residencia [s].],
    [$tau_c$], [Escala de enfriamiento [s].],
    [$H_i$], [Exposición térmica acumulada.],
    [$h_i$], [Tasa de exposición por paso.],
    [$p_c$], [Umbral de percolación.],
    [$D_f$], [Dimensión fractal.],
    [$L/A$], [Relación largo/ancho.],
    [$kappa$], [Número de condición.],
    [$epsilon$], [Épsilon de máquina.],
  ),
  caption: [Símbolos principales.],
) <tab:simbolos>

== Anexo D: unidades y conversiones de Rothermel

Rothermel formula su modelo en unidades imperiales: carga en lb/ft², relación
superficie--volumen en ft⁻¹, profundidad en ft, velocidad en ft/min y calor de
combustión en BTU/lb. Las conversiones utilizadas son:
$ 1 " kg/m"^2 = 0.204816 " lb/ft"^2, quad
  1 " m"^{-1} = 0.3048 " ft"^{-1}, $
$ 1 " ft/min" = 0.00508 " m/s", quad
  1 " BTU/lb" = 2326 " J/kg". $
La densidad de partícula se toma como $32$ lb/ft³ y el calor de combustión como
$8000$ BTU/lb. La humedad de extinción y la humedad del combustible se
introducen como fracciones adimensionales. El calor de preignición se calcula
en BTU/lb y la intensidad de reacción en BTU/ft²/min. La conversión final
multiplica por $0.00508$ para obtener m/s.

== Anexo E: tabla completa de percolación

La Tabla @tab:perc_full reproduce la probabilidad de percolación para todas las
ocupaciones simuladas. Se observa que la transición de von Neumann es más
abrupta que la de Moore, como corresponde a una vecindad con menos conexiones.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: center,
    stroke: 0.4pt,
    inset: 3.5pt,
    table.header([$p$], [4N], [8N], [$p$], [4N / 8N]),
    [0.250], [0.000], [0.000], [0.500], [0.000 / 1.000],
    [0.275], [0.000], [0.000], [0.525], [0.000 / 1.000],
    [0.300], [0.000], [0.000], [0.550], [0.013 / 1.000],
    [0.325], [0.000], [0.000], [0.575], [0.213 / 1.000],
    [0.350], [0.000], [0.000], [0.600], [0.700 / 1.000],
    [0.375], [0.000], [0.063], [0.625], [0.900 / 1.000],
    [0.400], [0.000], [0.350], [0.650], [1.000 / 1.000],
    [0.425], [0.000], [0.775], [0.675], [1.000 / 1.000],
    [0.450], [0.000], [0.975], [0.700], [1.000 / 1.000],
    [0.475], [0.000], [1.000], [0.725], [1.000 / 1.000],
  ),
  caption: [Probabilidad de percolación completa para las dos vecindades.],
) <tab:perc_full>
