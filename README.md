## **Pipeline ELT complet pour l'ingestion, la transformation et l'analyse des données des taxis verts de NYC, avec modélisation ML dans BigQuery.**


Ce projet s'est inspiré du cours de Mr Josué AFOUDA sur Udemy **Google Cloud Platform pour Data Engineers : Projet pratique**


Le pipeline utilise les fichiers parquet des **taxis verts** de New York City à partir du site _https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page_. Ces taxis se concentrent en principe sur les villes en dehors de Manhattan.

Du 01/01/2020 au  31/01/2025 il y a plus de 5 millions de lignes de données pour les taxis verts. .


## **1. STRUCTURE DU PROJET**

```bash
gcp_data_engineering_elt_pipeline_nyc_green_taxis/
├── README.md                      # Documentation principale
├── requirements.txt               # Dépendances Python
├── download_taxi_data.py          # Télécharge les données depuis NYC TLC
├── load_raw_trips_data.py         # Charge les données brutes dans BigQuery
├── exploratory_data_analysis.py   # Analyse exploratoire
├── create_data_sets.py            # Crée les datasets intermédiaires
├── transform_trips_data.py        # Nettoie et transforme les données
├── create_ml_dataset_table.py     # Prépare les données pour le ML
├── data/
│   └── taxi_zone_lookup.csv       # Codification des zones/arrondissements
├── notebooks/
│   ├── Custom Model.ipynb         # Entraîne des modèles (Random Forest, Boosted Tree)
│   ├── Report 2.ipynb             # Split train/test/val + évaluation
│   └── Report Notebook.ipynb      # Analyses temporelles et saisonnières
├── queries/
    ├── modeling_queries.sql       # Crée les modèles ML dans BigQuery
    ├── MarketDemand_and_CustomerBehavior.sql  # Vues de demande client
    ├── Financial_and_Pricing.sql  # Vues de coûts et tarification
    └── CompetitiveInsights.sql    # Vues de volumes et fréquences



```
## **2. PREREQUIS POUR INSTALLER**

## 🔧 Prérequis
- **Compte GCP** avec accès à :
  - BigQuery, Cloud Storage, Cloud composer Airflow
  - BigQuery ML
- **Python 3.8+** :
  ```bash
  pip install -r requirements.txt



## 3. APERCU DU PIPELINE ELT

![Animation](https://github.com/user-attachments/assets/e5481b26-cc99-4526-b8fb-c5c238ab3936)



## 4. EXECUTION DES SCRIPTS

### 4.1 Créer les datasets
```bash
python3 create_datasets.py
```


### 4.2 Télécharger les fichiers parquet dans GCS
```bash
python3 download_taxi_data.py
```

![image](https://github.com/user-attachments/assets/84da8229-5614-49ce-8ecf-0edb3569a4fa)


### 4.3 Analyse exploratoire des fichiers
```bash
python3 exploratory_data_analysis.py
```

### 4.4 Charger les données brutes dans BigQuery
```bash
python3 load_raw_trips_data.py
```
![image](https://github.com/user-attachments/assets/5f0f8462-cacc-4295-93ef-824f0421aed9)



### 4.5 Vérifier si le nombre de lignes dans les fichiers parquet correspond au nombre de lignes chargé dans la table green-taxi-trips-analytics.raw_greentrips.trips
```bash
python3 verification.py
```
### 4.6 Transformer les données via une requête SQL 
```bash
python3 load_raw_trips_data.py
```
Les données sont chargées dans la table green-taxi-trips-analytics.transformed_data.cleaned_and_filtered


### 4.7 Créer le DAG ELT après avoir créé un compte de service et configuré le DAG dans Apache Airflow
```bash
python3 elt_dag_pipeline.py
```
4.7.1 Compte de service

![image](https://github.com/user-attachments/assets/698d71c6-bee6-44db-9eea-fd73aa69f0ae)


4.7.2 Apache Airflow

![image](https://github.com/user-attachments/assets/278c207e-c887-4a00-9082-3fc7077bcf75)


![image](https://github.com/user-attachments/assets/de895ca2-b395-4d82-845d-78f39816a11a)

![image](https://github.com/user-attachments/assets/5b232f7f-8322-4e25-89e3-c50539514941)



### 4.8 Créer le dataset de machine learning
```bash
python3 create_ml_dataset_table.py
```

![image](https://github.com/user-attachments/assets/1377b828-9f00-40b3-91a5-96a86ed0feb9)

### 4.9 Créer les vues nécessaires à travers les requêtes dans les fichiers SQL
```bash
modeling_queries.sql
MarketDemand_and_CustomerBehavior.sql
Financial_and_Pricing.sql
CompetitiveInsights.sql
```


### 4.10 Créer les notebook nécessaires (voir fichier README.md)

![image](https://github.com/user-attachments/assets/31dc1346-d749-4348-ad77-3059a5acb337)


Dans le Notebook Report par exemple, nous avons les éléments suivants:


**4.10.1 Setup**


```bash
from google.cloud import bigquery
from google.colab import data_table
import bigframes.pandas as bpd

project = 'green-taxi-trips-analytics' # Project ID inserted based on the query results selected to explore
location = 'US' # Location inserted based on the query results selected to explore
client = bigquery.Client(project=project, location=location)
data_table.enable_dataframe_formatter()


# Query the BigQuery View
query_demand_over_time = """
SELECT *
FROM `green-taxi-trips-analytics.views_fordashboard.demand_over_time`

"""

# Run the query and store the result in a DataFrame
demand_over_time_df = client.query(query_demand_over_time).to_dataframe()
demand_over_time_df

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime

# Convert trip_date to datetime format
demand_over_time_df['trip_date'] = pd.to_datetime(demand_over_time_df['trip_date'])
demand_over_time_df.info()


# Filter rows where the year is between 2020 and the current year (inclusive)
filtered_demand_over_time_df = demand_over_time_df[(demand_over_time_df['year'] >= 2020) & (demand_over_time_df['year'] <= current_year)]
filtered_demand_over_time_df.year.value_counts(normalize=True)

# 1. Daily Demand Trend
fig_daily = px.line(
    filtered_demand_over_time_df,
    x='trip_date',
    y='total_trips',
    title='Daily Taxi Demand Over Time',
    labels={'trip_date': 'Date', 'total_trips': 'Number of Trips'},
    template='plotly_dark'
)
fig_daily.show()


```

**4.10.2 Le graphique de la demande journalière des taxis verts est le suivant** 
![image](https://github.com/user-attachments/assets/5da218b0-2f50-4c2a-a328-55231976855f)


### 4.11 Les prédictions du modèle boosted tree  parmi tant d'autres

**4.11.1 Les requêtes qui ont permis de créer le modèle**

(voir le fichier modeling_queries.sql) 
```bash
--- Pour rappel c'est la requête suivante qui a permis de créer la table sous-jacente pour le ML : green-taxi-trips-analytics.ml_dataset.trips_ml_data
CREATE OR REPLACE TABLE `green-taxi-trips-analytics.ml_dataset.trips_ml_data` AS
SELECT *
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered`
WHERE lpep_pickup_datetime >= TIMESTAMP('2023-01-01') 
AND EXTRACT(YEAR FROM lpep_pickup_datetime) BETWEEN 2023 AND EXTRACT(YEAR FROM CURRENT_DATE())
AND payment_type IN (1, 2)
and trip_type >=1;


-- Training with BOOSTED TREE REGRESSOR
CREATE OR REPLACE MODEL `green-taxi-trips-analytics.ml_dataset.boosted_tree_model`
  OPTIONS (model_type="BOOSTED_TREE_REGRESSOR", enable_global_explain=TRUE, input_label_cols=["total_amount"])
AS 
SELECT * FROM `green-taxi-trips-analytics.ml_dataset.preprocessed_train_data` ;

-- Evaluate the trained model with the test data
SELECT * FROM 
ML.EVALUATE(MODEL `green-taxi-trips-analytics.ml_dataset.boosted_tree_model`, 
(SELECT * FROM `green-taxi-trips-analytics.ml_dataset.preprocessed_test_data`));


-- Example for making predictions from the model
SELECT * FROM
ML.PREDICT (MODEL `green-taxi-trips-analytics.ml_dataset.boosted_tree_model`, 
(SELECT * FROM `green-taxi-trips-analytics.ml_dataset.preprocessed_test_data` ));


```

Les caractéristiques les plus importantes qui influencent le modèle (prédiction du coût du trajet) sont les suivantes :
![image](https://github.com/user-attachments/assets/34ffc8f0-b5e3-43e9-a9a5-a741e56a3a7d)


Ainsi : 
- trip_distance (7,277) - La distance du trajet est de loin le facteur le plus influent dans les prédictions du modèle boosted tree
- pickup_year (3,258) - L'année de prise en charge a une importance significative
- trip_duration (2,437) - La durée du trajet est également un facteur important
- is_credit_card (1,534) - Le mode de paiement (carte de crédit) a une influence modérée
- DOLocationID (0,536) - La zone de destination a une influence faible mais notable

Les autres caractéristiques (pickup_hour, PULocationID, etc.) ont une influence très faible sur les prédictions du modèle.

**4.11.2. La prédiction du prix du voyage total_amount.**

La prédiction est juste (moyenne d'erreur de **2,52**) pour certaines des observations comme l'indique le tableau ci-dessous : 

![image](https://github.com/user-attachments/assets/1255d442-1a28-4037-8a25-7d0ab35a4e7a)




![image](https://github.com/user-attachments/assets/4ed8ca7b-79a4-43c0-bfd0-eb1529102c3c)


