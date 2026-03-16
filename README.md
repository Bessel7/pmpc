# MyPMPC — Post-traitement Mesure & Simulation d'Antennes

Application MATLAB pour la comparaison mesure/simulation d'antennes
développée à XLIM.

## Utilisation
1. Lancer `MyPMPC.m` sous MATLAB R2021b ou supérieur
2. Sélectionner le working directory contenant `mesure/` et `simulation/`
3. Cliquer sur "Post-traitement des mesures" puis "Post-traitement des simulations"

## Structure attendue du répertoire
```
working_dir/
├── mesure/
│   ├── Ehoriz/   (*.amp, *.pha)
│   ├── Evert/    (*.amp, *.pha)
│   └── *.s2p
└── simulation/
    ├── Farfield/ (*.ffs)
    ├── *.stl
    ├── s11.s1p
    └── Hi.png
```

## Auteur
Bessel Vestel Patient AÏNA — Etudiant en 5e année à l'ENSIL-ENSCI, Université de Limoges
```

**`.gitignore`** — pour ne pas versionner les données lourdes :
```
*.mat
*.ffs
*.stl
*.emf
figures/
data/
