# Data Science Standards

This document covers Python standards for data science projects using Jupyter, pandas, NumPy, scikit-learn, and related tools.

## Project Structure

### Data Science Project Layout

```
project/
├── data/
│   ├── raw/              # Original, immutable data
│   ├── processed/        # Cleaned, transformed data
│   ├── external/         # Third-party data
│   └── interim/          # Intermediate transformations
├── notebooks/
│   ├── exploratory/      # Exploratory analysis
│   │   └── 01_initial_exploration.ipynb
│   ├── analysis/         # Final analysis notebooks
│   │   └── customer_segmentation.ipynb
│   └── archive/          # Old/deprecated notebooks
├── src/
│   ├── data/             # Data loading, cleaning
│   │   └── make_dataset.py
│   ├── features/         # Feature engineering
│   │   └── build_features.py
│   ├── models/           # Model training, prediction
│   │   ├── train_model.py
│   │   └── predict_model.py
│   └── visualization/    # Plotting functions
│       └── visualize.py
├── models/               # Trained model artifacts
│   └── model_v1.pkl
├── reports/              # Generated analysis
│   └── figures/          # Graphics for reports
├── tests/                # Unit tests for src/
├── requirements.txt
├── environment.yml       # Conda environment
└── README.md
```

## Pandas Best Practices

### Vectorization Over Iteration

```python
import pandas as pd
import numpy as np

# Bad - iterating over DataFrame (SLOW)
for idx, row in df.iterrows():
    df.at[idx, 'total'] = row['price'] * row['quantity']

# Bad - using apply with lambda (slower)
df['total'] = df.apply(lambda row: row['price'] * row['quantity'], axis=1)

# Good - vectorized operations (FAST)
df['total'] = df['price'] * df['quantity']

# Good - vectorized conditional logic
df['category'] = np.where(df['price'] > 100, 'expensive', 'affordable')

# Good - multiple conditions with np.select
conditions = [
    df['price'] < 50,
    df['price'] < 100,
    df['price'] >= 100
]
choices = ['cheap', 'moderate', 'expensive']
df['category'] = np.select(conditions, choices, default='unknown')
```

### Efficient Data Loading

```python
# Bad - loading entire file at once
df = pd.read_csv('large_file.csv')

# Good - specify dtypes to reduce memory
df = pd.read_csv('large_file.csv', dtype={
    'id': 'int32',
    'category': 'category',  # Categorical for repeated strings
    'value': 'float32'
})

# Good - load only needed columns
df = pd.read_csv('large_file.csv', usecols=['id', 'value', 'date'])

# Good - process in chunks for very large files
chunks = []
for chunk in pd.read_csv('huge_file.csv', chunksize=10000):
    processed = process_chunk(chunk)
    chunks.append(processed)
df = pd.concat(chunks, ignore_index=True)
```

### Method Chaining

```python
# Good - readable method chaining
result = (
    df
    .query('age > 18')
    .assign(
        age_group=lambda x: pd.cut(x['age'], bins=[18, 30, 50, 100]),
        total_spent=lambda x: x['price'] * x['quantity']
    )
    .groupby('age_group')['total_spent']
    .agg(['mean', 'sum', 'count'])
    .reset_index()
)

# Use .pipe() for custom functions
def add_features(df):
    return df.assign(
        feature1=df['col1'] * 2,
        feature2=df['col2'] + 10
    )

result = (
    df
    .pipe(add_features)
    .query('feature1 > 0')
)
```

### Avoiding Common Pitfalls

```python
# Bad - SettingWithCopyWarning
subset = df[df['age'] > 18]
subset['new_col'] = 1  # May or may not modify original df!

# Good - explicit copy
subset = df[df['age'] > 18].copy()
subset['new_col'] = 1

# Good - use .loc for assignment
df.loc[df['age'] > 18, 'new_col'] = 1

# Bad - iterating to filter
result = []
for idx, row in df.iterrows():
    if row['value'] > 10:
        result.append(row)
result_df = pd.DataFrame(result)

# Good - boolean indexing
result_df = df[df['value'] > 10]

# Good - query for complex conditions
result_df = df.query('value > 10 and category == "A"')
```

## NumPy Best Practices

### Array Operations

```python
import numpy as np

# Good - vectorized operations
arr = np.array([1, 2, 3, 4, 5])
result = arr * 2 + 10  # Vectorized

# Bad - Python loop
result = []
for x in arr:
    result.append(x * 2 + 10)

# Good - use broadcasting
matrix = np.random.rand(100, 50)
row_means = matrix.mean(axis=1, keepdims=True)
centered = matrix - row_means  # Broadcasting

# Good - use einsum for complex operations
# Matrix multiplication: C = A @ B
A = np.random.rand(100, 50)
B = np.random.rand(50, 30)
C = np.einsum('ik,kj->ij', A, B)
```

### Memory Efficiency

```python
# Good - specify dtype for memory efficiency
large_array = np.zeros((10000, 10000), dtype=np.float32)  # 400 MB
# vs np.float64 (default) which would use 800 MB

# Good - use views instead of copies when possible
arr = np.arange(1000000)
subset = arr[::2]  # View, not copy
subset_copy = arr[::2].copy()  # Explicit copy when needed

# Good - use np.memmap for very large arrays
large_data = np.memmap('large_file.dat', dtype='float32', mode='r', shape=(10000000, 100))
```

## Jupyter Notebook Standards

### Notebook Organization

```python
# Cell 1: Imports and setup
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

%matplotlib inline
%load_ext autoreload
%autoreload 2

# Configure display options
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', 100)
plt.style.use('seaborn-v0_8-darkgrid')

# Set random seed for reproducibility
np.random.seed(42)
```

```python
# Cell 2: Load data
df = pd.read_csv('../data/raw/dataset.csv')
print(f"Dataset shape: {df.shape}")
df.head()
```

```python
# Cell 3: Data exploration
df.info()
df.describe()
```

### Markdown Documentation

Use markdown cells to document analysis:

```markdown
# Customer Segmentation Analysis

## Objective
Identify distinct customer segments based on purchasing behavior.

## Data Overview
- **Source**: CRM database export
- **Date range**: 2023-01-01 to 2024-01-01
- **Records**: 50,000 customers

## Methodology
1. Feature engineering (RFM analysis)
2. K-means clustering
3. Segment profiling
```

### Code Organization in Notebooks

```python
# Good - extract complex logic to functions
def clean_data(df):
    """Clean and prepare dataset."""
    return (
        df
        .dropna(subset=['customer_id', 'purchase_date'])
        .assign(
            purchase_date=lambda x: pd.to_datetime(x['purchase_date']),
            total=lambda x: x['quantity'] * x['price']
        )
        .query('total > 0')
    )

def calculate_rfm(df):
    """Calculate RFM (Recency, Frequency, Monetary) metrics."""
    reference_date = df['purchase_date'].max()

    return (
        df.groupby('customer_id')
        .agg({
            'purchase_date': lambda x: (reference_date - x.max()).days,
            'order_id': 'count',
            'total': 'sum'
        })
        .rename(columns={
            'purchase_date': 'recency',
            'order_id': 'frequency',
            'total': 'monetary'
        })
    )

# Use functions in cells
df_clean = clean_data(df)
rfm = calculate_rfm(df_clean)
```

### Moving Code to Modules

When code is mature, move to `.py` files:

```python
# src/data/preprocessing.py
def clean_data(df):
    """Clean and prepare dataset."""
    # ... implementation ...

# In notebook
from src.data.preprocessing import clean_data
df_clean = clean_data(df)
```

## Machine Learning Pipeline

### Reproducible ML Workflow

```python
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report
import joblib

# Set random seed for reproducibility
RANDOM_STATE = 42
np.random.seed(RANDOM_STATE)

# Prepare data
X = df[feature_columns]
y = df['target']

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=RANDOM_STATE, stratify=y
)

# Preprocessing pipeline
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Train model
model = RandomForestClassifier(
    n_estimators=100,
    max_depth=10,
    random_state=RANDOM_STATE,
    n_jobs=-1
)
model.fit(X_train_scaled, y_train)

# Evaluate
y_pred = model.predict(X_test_scaled)
print(classification_report(y_test, y_pred))

# Save model artifacts
joblib.dump(model, '../models/rf_model.pkl')
joblib.dump(scaler, '../models/scaler.pkl')
joblib.dump(feature_columns, '../models/feature_columns.pkl')
```

### Using scikit-learn Pipelines

```python
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder

# Good - use pipelines for reproducibility
numeric_features = ['age', 'income', 'tenure']
categorical_features = ['gender', 'product_type']

preprocessor = ColumnTransformer(
    transformers=[
        ('num', StandardScaler(), numeric_features),
        ('cat', OneHotEncoder(drop='first', sparse=False), categorical_features)
    ]
)

pipeline = Pipeline([
    ('preprocessor', preprocessor),
    ('classifier', RandomForestClassifier(random_state=RANDOM_STATE))
])

# Train entire pipeline
pipeline.fit(X_train, y_train)

# Predict (preprocessing automatic)
y_pred = pipeline.predict(X_test)

# Save single artifact
joblib.dump(pipeline, '../models/pipeline.pkl')
```

## Visualization

### Matplotlib Best Practices

```python
import matplotlib.pyplot as plt
import seaborn as sns

# Good - clear, labeled plots
fig, ax = plt.subplots(figsize=(10, 6))

ax.scatter(df['age'], df['income'], alpha=0.5)
ax.set_xlabel('Age (years)', fontsize=12)
ax.set_ylabel('Income ($)', fontsize=12)
ax.set_title('Income vs Age Distribution', fontsize=14, fontweight='bold')
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('../reports/figures/income_vs_age.png', dpi=300)
plt.show()

# Good - reusable plotting functions
def plot_feature_importance(model, feature_names, top_n=20):
    """Plot top N feature importances."""
    importances = model.feature_importances_
    indices = np.argsort(importances)[-top_n:]

    plt.figure(figsize=(10, 8))
    plt.barh(range(len(indices)), importances[indices])
    plt.yticks(range(len(indices)), [feature_names[i] for i in indices])
    plt.xlabel('Importance')
    plt.title(f'Top {top_n} Feature Importances')
    plt.tight_layout()
```

### Seaborn for Statistical Plots

```python
# Good - use seaborn for statistical visualizations
sns.set_style("whitegrid")

# Distribution plot
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

sns.histplot(data=df, x='age', kde=True, ax=axes[0])
axes[0].set_title('Age Distribution')

sns.boxplot(data=df, x='segment', y='income', ax=axes[1])
axes[1].set_title('Income by Segment')

plt.tight_layout()
plt.savefig('../reports/figures/distributions.png', dpi=300)
```

## Data Science Security

### Pickle Safety

```python
import pickle
import json

# Bad - pickle is unsafe for untrusted data
with open('untrusted_data.pkl', 'rb') as f:
    data = pickle.load(f)  # Can execute arbitrary code!

# Good - use JSON for data serialization
with open('data.json', 'w') as f:
    json.dump(data, f)

with open('data.json', 'r') as f:
    data = json.load(f)

# Acceptable - pickle for trusted model artifacts only
joblib.dump(trained_model, 'model.pkl')  # OK for your own models
model = joblib.load('model.pkl')
```

### Data Privacy

```python
# Good - anonymize sensitive data
df['customer_id_hash'] = df['customer_id'].apply(
    lambda x: hashlib.sha256(str(x).encode()).hexdigest()
)
df = df.drop('customer_id', axis=1)

# Good - remove PII before saving
df_clean = df.drop(['email', 'phone', 'address'], axis=1)
df_clean.to_csv('../data/processed/anonymized_data.csv', index=False)

# Good - use aggregation to protect privacy
summary = df.groupby('zip_code').agg({
    'income': 'mean',
    'age': 'mean'
}).query('count >= 10')  # Suppress small groups
```

## Testing Data Science Code

### Unit Tests for Data Processing

```python
# tests/test_preprocessing.py
import pytest
import pandas as pd
import numpy as np
from src.data.preprocessing import clean_data, calculate_rfm

def test_clean_data_removes_nulls():
    """Test that clean_data removes null values."""
    df = pd.DataFrame({
        'customer_id': [1, 2, None, 4],
        'value': [10, 20, 30, 40]
    })
    result = clean_data(df)
    assert result['customer_id'].isna().sum() == 0
    assert len(result) == 3

def test_calculate_rfm_correct_metrics():
    """Test RFM calculation returns correct shape."""
    df = pd.DataFrame({
        'customer_id': [1, 1, 2, 2],
        'purchase_date': pd.to_datetime(['2024-01-01', '2024-01-15', '2024-01-10', '2024-01-20']),
        'order_id': [1, 2, 3, 4],
        'total': [100, 150, 200, 250]
    })
    rfm = calculate_rfm(df)
    assert rfm.shape == (2, 3)
    assert list(rfm.columns) == ['recency', 'frequency', 'monetary']
```

### Testing Model Predictions

```python
def test_model_prediction_shape():
    """Test model output shape matches input."""
    X_test = np.random.rand(10, 5)
    predictions = model.predict(X_test)
    assert predictions.shape == (10,)

def test_model_prediction_range():
    """Test predictions are in expected range."""
    X_test = np.random.rand(100, 5)
    predictions = model.predict_proba(X_test)
    assert np.all(predictions >= 0)
    assert np.all(predictions <= 1)
    assert np.allclose(predictions.sum(axis=1), 1)
```

## Documentation Standards

### Docstring Format

```python
def train_model(X_train, y_train, hyperparameters=None):
    """
    Train classification model with given data.

    Parameters
    ----------
    X_train : np.ndarray or pd.DataFrame
        Training features of shape (n_samples, n_features)
    y_train : np.ndarray or pd.Series
        Training labels of shape (n_samples,)
    hyperparameters : dict, optional
        Model hyperparameters. If None, uses defaults.

    Returns
    -------
    model : sklearn estimator
        Trained model instance

    Examples
    --------
    >>> X_train = np.random.rand(100, 5)
    >>> y_train = np.random.randint(0, 2, 100)
    >>> model = train_model(X_train, y_train)
    """
    if hyperparameters is None:
        hyperparameters = {'max_depth': 10, 'n_estimators': 100}

    model = RandomForestClassifier(**hyperparameters)
    model.fit(X_train, y_train)
    return model
```

## Version Control for Notebooks

```bash
# .gitignore
# Don't commit notebook outputs
*.ipynb_checkpoints/

# Use nbstripout to remove outputs before commit
pip install nbstripout
nbstripout --install

# Or configure Git filter
git config filter.nbstrip_full.clean "nbstripout"
git config filter.nbstrip_full.smudge cat
git config filter.nbstrip_full.required true
```

## References

- [Pandas Documentation](https://pandas.pydata.org/docs/)
- [NumPy Documentation](https://numpy.org/doc/)
- [Scikit-learn Best Practices](https://scikit-learn.org/stable/developers/contributing.html#best-practices)
- [Cookiecutter Data Science](https://drivendata.github.io/cookiecutter-data-science/)
