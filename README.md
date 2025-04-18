# Movie Hit Prediction Using Machine Learning

This project predicts whether a movie will be a Hit or Flop using machine learning techniques. It is designed to help filmmakers, producers, and analysts make data-driven decisions based on a movie's features.

## Project Overview

With the growing role of data analytics in the entertainment industry, this project leverages historical movie data to train a classification model. The goal is to determine the potential success of a movie before its release.

We use Random Forest with extensive feature engineering and hyperparameter tuning to build a high-performance model.

## Features

- Cleaned and preprocessed movie metadata
- Feature engineering on genres, production companies, and release dates
- Missing data handling using appropriate imputation techniques
- Hyperparameter tuning with RandomizedSearchCV
- Model evaluation using accuracy, confusion matrix, and classification report
- Feature importance visualization
- Accepts custom movie input and predicts whether it will be a hit or flop

## Dataset

The dataset includes thousands of movies with features such as:

- Budget
- Runtime
- Original Language
- Popularity
- Vote Average and Vote Count
- Release Year and Month
- Main Genre
- Main Production Company

Dataset Source: TMDB (The Movie Database)

## Machine Learning Model

- Model: Random Forest Classifier
- Tuning: RandomizedSearchCV with a defined parameter grid
- Evaluation Metrics: Accuracy, Confusion Matrix, Classification Report

## How to Use

1. Clone this repository.
2. Open the notebook file in Jupyter Notebook or any other environment.
3. Run the cells step-by-step to preprocess the data, train the model, and evaluate results.
4. Use the custom input section to manually test new movie data.

## Installation

Install the required packages using:

```bash
pip install pandas numpy scikit-learn matplotlib seaborn
