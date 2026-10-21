"""Génère deux jeux de données FICTIFS (mer du Nord / Méditerranée) de structures différentes."""
import csv, random
random.seed(42)

def line(lon, lat, n, dlon, dlat):
    pts = [(lon, lat)]
    for _ in range(n):
        lon += random.uniform(0.2, 0.6) * dlon
        lat += random.uniform(-0.25, 0.25) * dlat
        pts.append((round(lon, 4), round(lat, 4)))
    return "LINESTRING(" + ", ".join(f"{x} {y}" for x, y in pts) + ")"

# Projet A : pipelines (colonnes en anglais majuscules, statut en français)
statuts = ["en service", "en service", "en service", "projet", "abandonné"]
with open("data/projet_a_pipelines.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["PIPE_ID", "PIPE_NAME", "STATUS_FR", "DIAM_MM", "OPERATOR", "WKT"])
    for i in range(1, 41):
        w.writerow([f"PA-{i:03d}", f"Pipeline Nord {i}", random.choice(statuts),
                    random.choice([200, 300, 400, 600, 900]),
                    random.choice(["Opérateur X", "Opérateur Y", "Opérateur Z"]),
                    line(random.uniform(0, 3), random.uniform(52, 57), random.randint(3, 8), 1.2, 1.0)])
    # anomalies volontaires pour les contrôles qualité
    w.writerow(["PA-005", "Doublon PA-005", "en service", 300, "Opérateur X", line(1, 54, 3, 1, 1)])   # doublon d'identifiant
    w.writerow(["PA-099", "Géométrie dégénérée", "projet", 400, "Opérateur Y", "LINESTRING(2 55, 2 55)"])  # invalide
    w.writerow(["PA-100", "Hors zone", "en service", 400, "Opérateur Z", "LINESTRING(150 -30, 151 -31)"])  # hors emprise

# Projet B : câbles (autre nomenclature, états en anglais, année)
etats = ["ACTIVE", "ACTIVE", "PLANNED", "DECOMMISSIONED"]
with open("data/projet_b_cables.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["cable_ref", "nom", "etat", "proprietaire", "annee_pose", "geom_wkt"])
    for i in range(1, 31):
        w.writerow([f"CB{i:02d}", f"Câble Med {i}", random.choice(etats),
                    random.choice(["Société A", "Société B"]), random.randint(1998, 2026),
                    line(random.uniform(2, 8), random.uniform(37, 42), random.randint(3, 7), 1.5, 1.0)])
