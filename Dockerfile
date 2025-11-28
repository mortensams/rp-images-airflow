# Airflow 3.x container image with SQL Server, PostgreSQL, dbt, S3/MinIO, and OpenMetadata lineage support
# Based on: https://airflow.apache.org/docs/docker-stack/build.html

FROM apache/airflow:3.1.3-python3.12

# Switch to root to install system dependencies
USER root

# Install system dependencies for SQL Server (ODBC), git, and general build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential \
    gcc \
    g++ \
    # Git for git sync functionality
    git \
    openssh-client \
    # SQL Server ODBC driver dependencies
    curl \
    gnupg2 \
    apt-transport-https \
    unixodbc \
    unixodbc-dev \
    # PostgreSQL client libraries
    libpq-dev \
    postgresql-client \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# Install Microsoft ODBC Driver 18 for SQL Server
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && curl -fsSL https://packages.microsoft.com/config/debian/12/prod.list | tee /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 \
    && rm -rf /var/lib/apt/lists/*

# Switch back to airflow user for pip installs
USER airflow

# Copy requirements first for better layer caching
COPY --chown=airflow:root requirements.txt /opt/airflow/requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir -r /opt/airflow/requirements.txt

# Set working directory
WORKDIR /opt/airflow
