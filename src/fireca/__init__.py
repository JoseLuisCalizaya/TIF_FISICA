"""fireca: simulación de incendios forestales con autómatas celulares.

Trabajo de Investigación Formativa del curso de Física Computacional.
Escuela Profesional de Ciencia de la Computación, UNSA.
"""

from __future__ import annotations

__version__ = "0.1.0"

from .ca import (
    BURNED,
    BURNING,
    UNBURNABLE,
    UNBURNED,
    DeterministicCA,
    FireCA,
    MinimumTravelTime,
    SimulationResult,
    StochasticCA,
    run_ensemble,
)
from .fuels import STANDARD_FUELS, FuelModel, base_rate_of_spread, directional_rates
from .terrain import Terrain, binary_forest, generate_terrain, ignition_mask

__all__ = [
    "BURNED",
    "BURNING",
    "UNBURNED",
    "UNBURNABLE",
    "DeterministicCA",
    "FireCA",
    "MinimumTravelTime",
    "SimulationResult",
    "StochasticCA",
    "STANDARD_FUELS",
    "FuelModel",
    "Terrain",
    "base_rate_of_spread",
    "binary_forest",
    "directional_rates",
    "generate_terrain",
    "ignition_mask",
    "run_ensemble",
]
