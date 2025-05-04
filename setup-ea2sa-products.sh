 #!/bin/bash
# setup-ea2sa-products.sh

SERVICE_NAME="ea2sa-products"

echo "🧱 Bootstrapping $SERVICE_NAME..."

mkdir -p $SERVICE_NAME/{app,tests,k8s}
cd $SERVICE_NAME

# Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install fastapi uvicorn sqlalchemy psycopg2-binary python-dotenv pytest
pip freeze > requirements.txt

# Main FastAPI app
cat <<EOF > app/main.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}
EOF

# Dockerfile
cat <<EOF > Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# K8s Deployment
cat <<EOF > k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ea2sa-products
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ea2sa-products
  template:
    metadata:
      labels:
        app: ea2sa-products
    spec:
      containers:
        - name: ea2sa-products
          image: ea2sa-products:latest
          ports:
            - containerPort: 8000
EOF

# K8s Service
cat <<EOF > k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: ea2sa-products
spec:
  selector:
    app: ea2sa-products
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
EOF

# Pytest test
cat <<EOF > tests/test_health.py
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
EOF

# .gitignore
cat <<EOF > .gitignore
__pycache__/
*.pyc
venv/
.env
EOF

# README
cat <<EOF > README.md
# ea2sa-products
Microservice for managing products using FastAPI and PostgreSQL.
EOF

echo "✅ Microservice $SERVICE_NAME is ready."
