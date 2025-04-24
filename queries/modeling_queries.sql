-- Training with BOOSTED TREE REGRESSOR
CREATE OR REPLACE MODEL `green-taxi-trips-analytics.ml_dataset.boosted_tree_model`
  OPTIONS (model_type="BOOSTED_TREE_REGRESSOR", enable_global_explain=TRUE, input_label_cols=["total_amount"])
AS 
SELECT * FROM `green-taxi-trips-analytics.ml_dataset.preprocessed_train_data` ;


SELECT COUNT(*) FROM `green-taxi-trips-analytics.ml_dataset.preprocessed_test_data`;


-- Evaluate the trained model with the test data
SELECT * FROM 
ML.EVALUATE(MODEL `green-taxi-trips-analytics.ml_dataset.boosted_tree_model`, 
(SELECT * FROM `green-taxi-trips-analytics.ml_dataset.preprocessed_test_data`));


-- Example for making predictions from the model
SELECT * FROM
ML.PREDICT (MODEL `green-taxi-trips-analytics.ml_dataset.boosted_tree_model`, 
(SELECT * FROM `green-taxi-trips-analytics.ml_dataset.preprocessed_test_data` ));


-- Query the model's global explanations
SELECT * FROM ML.GLOBAL_EXPLAIN(MODEL `green-taxi-trips-analytics.ml_dataset.green_trips_model`);





-- Training with RANDOM FOREST REGRESSOR
CREATE OR REPLACE MODEL `green-taxi-trips-analytics.ml_dataset.green_trips_rf`
  OPTIONS (model_type="RANDOM_FOREST_REGRESSOR", enable_global_explain=TRUE, input_label_cols=["total_amount"])
AS 
SELECT * FROM `green-taxi-trips-analytics.ml_dataset.preprocessed_train_data` ;


SELECT * FROM 
ML.EVALUATE(MODEL `green-taxi-trips-analytics.ml_dataset.green_trips_rf`, 
(SELECT * FROM `green-taxi-trips-analytics.ml_dataset.preprocessed_test_data`));








-- Training with DNN REGRESSOR
CREATE OR REPLACE MODEL `green-taxi-trips-analytics.ml_dataset.green_trips_dnn`
  OPTIONS (model_type="DNN_REGRESSOR", enable_global_explain=TRUE, input_label_cols=["total_amount"])
AS 
SELECT * FROM `green-taxi-trips-analytics.ml_dataset.preprocessed_train_data`;


-- Training with AUTOML REGRESSOR
CREATE OR REPLACE MODEL `green-taxi-trips-analytics.ml_dataset.green_trips_automl`
  OPTIONS (model_type="AUTOML_REGRESSOR", enable_global_explain=TRUE, input_label_cols=["total_amount"])
AS 
SELECT * FROM `green-taxi-trips-analytics.ml_dataset.preprocessed_train_data`;


